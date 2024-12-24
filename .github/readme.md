# Unbound Manager

**Unbound Manager** is a flexible and powerful script designed to help you easily install, configure, and manage your own DNS resolver and server. With support for DNSSEC validation, DNS-based blocking, and acting as a DNS proxy, this tool is perfect for users who want to control their DNS infrastructure for enhanced security, privacy, and performance. Additionally, it can block ads and other unwanted content using a customizable hosts file.

---

## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Variants](#variants)
- [Configuration](#configuration)
- [Author](#author)
- [Credits](#credits)
- [License](#license)

---

## Features

- **DNS Server Management**: Install and configure your own DNS resolver with full control.
- **DNSSEC Validation**: Automatically validate DNSSEC records to ensure security and trustworthiness of DNS queries.
- **DNS Proxy**: Use as a DNS proxy to forward queries to upstream servers for better security and caching.
- **Content Blocking (Ads, DNS, and More)**: Block unwanted content like ads, malware domains, and other undesirable sites based on DNS filtering. The hosts file used by this tool is regularly updated to provide effective blocking.
- **Easy Installation**: Simple installation process via `curl` with minimal dependencies required.
- **Compatibility**: Works seamlessly on most Linux-based systems (Ubuntu, Debian, etc.).
- **Custom Configurations**: Modify configuration files to meet your specific needs.
- **Log Management**: Control and review logs for better troubleshooting and security auditing.

---

## Installation

### Prerequisites

- A Linux-based system (Ubuntu, Debian, etc.).
- `curl` installed for downloading the script.
- Sudo or root privileges to install the script and set permissions.

### 1. Download the Script

Use `curl` to download the latest version of the script directly from the GitHub repository:

```bash
curl https://raw.githubusercontent.com/complexorganizations/unbound-manager/main/unbound-manager.sh --create-dirs -o /usr/local/bin/unbound-manager.sh
```

This will download the script and save it in the `/usr/local/bin/` directory.

### 2. Make the Script Executable

Once the script is downloaded, set the execute permissions:

```bash
chmod +x /usr/local/bin/unbound-manager.sh
```

### 3. Run the Script

Execute the script to begin configuring your DNS server:

```bash
bash /usr/local/bin/unbound-manager.sh
```

The script will guide you through the configuration process and set up your DNS server according to the specified settings.

---

## Usage

Once installed and configured, you can manage your DNS server using the `unbound-manager.sh` script. Here are some of the common actions you can perform:

### Start the DNS Server

To start the Unbound DNS server:

```bash
sudo systemctl start unbound
```

### Stop the DNS Server

To stop the Unbound DNS server:

```bash
sudo systemctl stop unbound
```

### Restart the DNS Server

To restart the Unbound DNS server:

```bash
sudo systemctl restart unbound
```

### Check the DNS Server Status

To check the status of the Unbound DNS server:

```bash
sudo systemctl status unbound
```

---

## Variants

The script supports several configuration variants, allowing for quick setups based on your needs.

| Variant                                                                                                          | Description                                                                                                                                                                                                                                                |
| ---------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [Host Variant](https://raw.githubusercontent.com/Strong-Foundation/unbound-manager/refs/heads/main/assets/hosts) | A simple DNS-based ad blocker and content filter that blocks ads, malware domains, and other unwanted content using a regularly updated hosts file. Ideal for users looking for a straightforward solution to block undesirable websites at the DNS level. |

Feel free to explore and select the variant that suits your needs best.

---

## Configuration

You can customize the Unbound Manager by modifying its configuration files. The main configuration file is located at `/etc/unbound/unbound.conf`. The script also allows you to manage DNSSEC settings, forwarding rules, and content-blocking options. Below are some key settings you can adjust:

### DNSSEC Settings

Enable DNSSEC validation to ensure the authenticity of DNS queries.

```bash
dnssec-enable: yes
```

### Content Blocking (Ads, DNS, and Other Sites)

Block unwanted domains or websites by specifying a list of domains to block. The `hosts` file used by this script is regularly updated to block ads, malware domains, and other undesirable sites. Here's how to configure it:

```bash
local-zone: "example.com" static
```

For ad-blocking, the script uses a regularly updated list of known ad-serving domains to block unwanted advertisements at the DNS level.

### Forwarding Rules

Set up forwarding to external DNS servers for faster resolution and reliability.

```bash
forward-zone:
    name: "."
    forward-addr: 8.8.8.8
    forward-addr: 8.8.4.4
```

### Log Management

Enable logging to capture DNS query information for analysis or troubleshooting.

```bash
log-queries: yes
log-replies: yes
```

---

## Author

This project is developed and maintained by the **Complex Organizations** team, a group of enthusiasts focused on creating open-source software for better network management and security.

---

## Credits

This project is possible due to the contributions and ideas from the open-source community. Special thanks to:

- [Unbound](https://nlnetlabs.nl/projects/unbound/about/) for the Unbound DNS server.
- [Google Public DNS](https://developers.google.com/speed/public-dns) for their fast and secure DNS service.
- [OpenDNS](https://www.opendns.com/) for their comprehensive DNS services and security features.
- [Cloudflare DNS](https://www.cloudflare.com/dns/) for providing fast and privacy-first DNS resolution.
- Contributors from various open-source projects that made this possible.

---

## License

This project is unlicensed. You are free to use, modify, and distribute it as you see fit, with no restrictions. Contributions are welcome!

---

## Contributions

Contributions to the **Unbound Manager** project are welcome! If you have suggestions, bug fixes, or new features, feel free to fork the repository, make changes, and submit a pull request. For any issues or questions, open an issue on the GitHub repository.
