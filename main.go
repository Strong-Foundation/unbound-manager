package main

import (
	"fmt"
	"io"
	"log"
	"net"
	"net/http"
	"net/url"
	"os"
	"regexp"
	"sync"
)

var (
	// Adware
	stevenBlackAdsURL = "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
	lightSwitchAdsURL = "https://raw.githubusercontent.com/lightswitch05/hosts/master/docs/lists/ads-and-tracking-extended.txt"
	// Malware
	noTrackingAdsURL = "https://raw.githubusercontent.com/notracking/hosts-blocklists/master/unbound/unbound.blacklist.conf"
	// Privacy
	lightSwitchTrackingURL = "https://raw.githubusercontent.com/lightswitch05/hosts/lists/tracking-aggressive-extended.txt"
	lightSwitchFacebookURL = "https://raw.githubusercontent.com/lightswitch05/hosts/lists/facebook-extended.txt"
	lightSwitchJunkURL     = "https://raw.githubusercontent.com/lightswitch05/hosts/lists/hate-and-junk-extended.txt"
)

const (
	localAdwareConfig    = "configs/adware"
	localMalwareConfig   = "configs/malware"
	localPrivacyConfig   = "configs/privacy"
	localExclusionConfig = "configs/exclusion"
)

func init() {
	// Adware
	if fileExists(localAdwareConfig) {
		os.Remove(localAdwareConfig)
	}
	// Malware
	if fileExists(localMalwareConfig) {
		os.Remove(localMalwareConfig)
	}
	// Privacy
	if fileExists(localPrivacyConfig) {
		os.Remove(localPrivacyConfig)
	}
	// Read Exclusion
	_, err := os.ReadFile(localExclusionConfig)
	handleErrors(err)
}

func main() {
	var waitGroup sync.WaitGroup
	waitGroup.Add(1)
	// Adware
	go func() {
		if validURL(stevenBlackAdsURL) {
			validateAndSave(stevenBlackAdsURL, localAdwareConfig)
			waitGroup.Done()
		}
	}()
	go func() {
		if validURL(lightSwitchAdsURL) {
			validateAndSave(lightSwitchAdsURL, localAdwareConfig)
			waitGroup.Done()
		}
	}()
	// Malware
	go func() {
		if validURL(noTrackingAdsURL) {
			validateAndSave(noTrackingAdsURL, localAdwareConfig)
			waitGroup.Done()
		}
	}()
	// Privacy
	go func() {
		if validURL(lightSwitchTrackingURL) {
			validateAndSave(lightSwitchTrackingURL, localAdwareConfig)
			waitGroup.Done()
		}
	}()
	go func() {
		if validURL(lightSwitchFacebookURL) {
			validateAndSave(lightSwitchFacebookURL, localAdwareConfig)
			waitGroup.Done()
		}
	}()
	go func() {
		if validURL(lightSwitchJunkURL) {
			validateAndSave(lightSwitchJunkURL, localAdwareConfig)
			waitGroup.Done()
		}
	}()
	waitGroup.Wait()
}

func validateAndSave(url, path string) {
	// Send a request to acquire all the information you need.
	response, err := http.Get(url)
	handleErrors(err)
	defer response.Body.Close()
	body, err := io.ReadAll(response.Body)
	handleErrors(err)
	// locate all domains
	regex := regexp.MustCompile(`(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z0-9][a-z0-9-]{0,61}[a-z0-9]`)
	domains := regex.FindAllString(string(body), -1)
	// Make each domain one-of-a-kind.
	uniqueDomains := makeUnique(domains)
	for i := 0; i < len(uniqueDomains); i++ {
		if validateDomain(uniqueDomains[i]) {
			// a file including all of the domains
			filePath, err := os.OpenFile(path, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
			handleErrors(err)
			defer filePath.Close()
			fileContent := fmt.Sprint(uniqueDomains[i], "\n")
			_, err = filePath.WriteString(fileContent)
			handleErrors(err)
		}
	}
}

// Take a list of domains and make them one-of-a-kind
func makeUnique(randomStrings []string) []string {
	flag := make(map[string]bool)
	var uniqueString []string
	for _, randomString := range randomStrings {
		if !flag[randomString] {
			flag[randomString] = true
			uniqueString = append(uniqueString, randomString)
		}
	}
	return uniqueString
}

// Validate a website's domain
func validateDomain(domain string) bool {
	ns, _ := net.LookupNS(domain)
	return len(ns) >= 1
}

// Validate the URI
func validURL(uri string) bool {
	validUri, err := url.ParseRequestURI(uri)
	if err != nil {
		return false
	}
	_ = validUri
	return true
}

// Make a decision about how to handle errors.
func handleErrors(err error) {
	if err != nil {
		log.Println(err)
	}
}

func fileExists(filename string) bool {
	info, err := os.Stat(filename)
	if os.IsNotExist(err) {
		return false
	}
	return !info.IsDir()
}

urls := []typeURL{
	"https://raw.githubusercontent.com/ivolo/disposable-email-domains/master/index.json",
	"https://raw.githubusercontent.com/ivolo/disposable-email-domains/master/wildcard.json",
}
