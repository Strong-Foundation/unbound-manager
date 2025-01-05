#!/bin/bash

# Contributing:
# - Contributions to the script are welcome. Please follow the contributing guidelines in the repository.

# Contact Information:
# - For support, feature requests, or bug reports, please open an issue on the GitHub repository.

# License: MIT License

# Note: This script is provided 'as is', without warranty of any kind. The user is responsible for understanding the operations and risks involved.

# Check if the script is running as root
function check_root() {
  if [ "$(id -u)" -ne 0 ]; then
    echo "Error: This script must be run as root."
    exit
  fi
}

# Call the function to check root privileges
check_root

# Function to gather current system details
function system-information() {
  # This function fetches the ID, version, and major version of the current system
  if [ -f /etc/os-release ]; then
    # If /etc/os-release file is present, source it to obtain system details
    # shellcheck source=/dev/null
    source /etc/os-release
    CURRENT_DISTRO=${ID}                 # CURRENT_DISTRO holds the system's ID
    CURRENT_DISTRO_VERSION=${VERSION_ID} # CURRENT_DISTRO_VERSION holds the system's VERSION_ID
  fi
}

# Invoke the system-information function
system-information

# Function to install system requirements if missing
function installing_system_requirements() {
  # Check if the current distribution is supported
  if [[ "${DISTRO}" == "ubuntu" || "${DISTRO}" == "debian" || "${DISTRO}" == "raspbian" || "${DISTRO}" == "pop" || "${DISTRO}" == "kali" || "${DISTRO}" == "linuxmint" || "${DISTRO}" == "fedora" || "${DISTRO}" == "centos" || "${DISTRO}" == "rhel" || "${DISTRO}" == "arch" || "${DISTRO}" == "manjaro" || "${DISTRO}" == "alpine" || "${DISTRO}" == "freebsd" ]]; then
    # Check if curl and cron are installed, if not install them
    if { [ ! -x "$(command -v curl)" ] || [ ! -x "$(command -v cron)" ]; }; then
      echo "Required packages curl and cron not found. Installing them now..."
      # Install curl and cron depending on the distribution using if/elif/fi
      if [[ "${DISTRO}" == "ubuntu" || "${DISTRO}" == "debian" || "${DISTRO}" == "raspbian" || "${DISTRO}" == "pop" || "${DISTRO}" == "kali" || "${DISTRO}" == "linuxmint" ]]; then
        apt-get update && apt-get install -y curl cron
      elif [[ "${DISTRO}" == "fedora" || "${DISTRO}" == "centos" || "${DISTRO}" == "rhel" ]]; then
        yum update -y && yum install -y curl cron
      elif [[ "${DISTRO}" == "arch" || "${DISTRO}" == "manjaro" ]]; then
        pacman -Syu --noconfirm && pacman -S --noconfirm curl cronie
      elif [[ "${DISTRO}" == "alpine" ]]; then
        apk update && apk add curl cron
      elif [[ "${DISTRO}" == "freebsd" ]]; then
        pkg update && pkg install -y curl cron
      else
        # This line shouldn't be hit if the distro check is correct
        echo "Error: Unsupported distribution: ${DISTRO}. Exiting."
        exit 1
      fi
    else
      echo "curl and cron are already installed."
    fi
  else
    # Unsupported distribution
    echo "Error: The distribution ${DISTRO} is not supported by this script."
    exit 1
  fi
}

# Run the function to check and install requirements
installing_system_requirements

# Global variables
RESOLV_CONFIG="/etc/resolv.conf"                                                                                                                     # Path to the system's DNS resolver configuration file
RESOLV_CONFIG_OLD="${RESOLV_CONFIG}.old"                                                                                                             # Path to the backup of the DNS resolver configuration file
UNBOUND_ROOT="/etc/unbound"                                                                                                                          # Directory where Unbound DNS configuration and data are stored
UNBOUND_CONFIG="${UNBOUND_ROOT}/unbound.conf"                                                                                                        # Path to the Unbound main configuration file
UNBOUND_ROOT_HINTS="${UNBOUND_ROOT}/root.hints"                                                                                                      # Path to the root DNS hints file for Unbound
UNBOUND_ANCHOR="/var/lib/unbound/root.key"                                                                                                           # Path to the DNS root key for DNSSEC validation
UNBOUND_CONFIG_HOST="${UNBOUND_ROOT}/unbound.conf.d/host.conf"                                                                                       # Path to the Unbound configuration file for DNS blocking via host
UNBOUND_MANAGER_UPDATE_URL="https://raw.githubusercontent.com/Strong-Foundation/unbound-manager/refs/heads/main/unbound-manager.sh"                  # URL to the latest Unbound manager script
UNBOUND_CONFIG_REMOTE_URL="https://raw.githubusercontent.com/Strong-Foundation/unbound-manager/refs/heads/main/assets/unbound.conf"                  # URL to the remote-based Unbound configuration
UNBOUND_CONFIG_ROOT_NAME_SERVERS_REMOTE_URL="https://raw.githubusercontent.com/Strong-Foundation/unbound-manager/refs/heads/main/assets/named.cache" # URL to the remote-based root name servers configuration
UNBOUND_CONFIG_HOST_URL="https://raw.githubusercontent.com/Strong-Foundation/unbound-manager/main/configs/host"                                      # URL to the host-based DNS block list configuration
UNBOUND_MANAGER="${UNBOUND_ROOT}/unbound-manager"                                                                                                    # Directory for Unbound manager script

# The following function checks if the current init system is one of the allowed options.
function check-current-init-system() {
  # Get the current init system by checking the process name of PID 1.
  CURRENT_INIT_SYSTEM=$(ps -p 1 -o comm= | awk -F'/' '{print $NF}') # Extract only the command name without the full path.
  # Convert to lowercase to make the comparison case-insensitive.
  CURRENT_INIT_SYSTEM=$(echo "$CURRENT_INIT_SYSTEM" | tr '[:upper:]' '[:lower:]')
  # Log the detected init system (optional for debugging purposes).
  echo "Detected init system: ${CURRENT_INIT_SYSTEM}"
  # Define a list of allowed init systems (case-insensitive).
  ALLOWED_INIT_SYSTEMS=("systemd" "sysvinit" "init" "upstart" "bash" "sh")
  # Check if the current init system is in the list of allowed init systems
  if [[ ! "${ALLOWED_INIT_SYSTEMS[*]}" =~ ${CURRENT_INIT_SYSTEM} ]]; then
    # If the init system is not allowed, display an error message and exit with an error code.
    echo "Error: The '${CURRENT_INIT_SYSTEM}' initialization system is not supported. Please stay tuned for future updates."
    exit 1 # Exit the script with an error code.
  fi
}

# The check-current-init-system function is being called.
check-current-init-system

if [ ! -f "${UNBOUND_MANAGER}" ]; then

  # Function to install unbound
  function install-unbound() {
    # Check if unbound is not installed by verifying if the unbound command is not available
    if [ ! -x "$(command -v unbound)" ]; then
      echo "Unbound is not installed. Installing..." # Print a message indicating that Unbound is not installed
      # Install Unbound based on the detected distribution
      # The script checks which distribution is being used and installs the appropriate package
      if [ "${DISTRO}" == "ubuntu" ] || [ "${DISTRO}" == "debian" ] || [ "${DISTRO}" == "raspbian" ] || [ "${DISTRO}" == "pop" ] || [ "${DISTRO}" == "kali" ] || [ "${DISTRO}" == "linuxmint" ]; then
        apt-get install unbound unbound-host unbound-anchor e2fsprogs -y
      elif [ "${DISTRO}" == "centos" ] || [ "${DISTRO}" == "rhel" ]; then
        yum install unbound unbound-libs -y # Install Unbound and necessary dependencies for Red Hat-based systems
      elif [ "${DISTRO}" == "fedora" ]; then
        dnf install unbound -y # Install Unbound for Fedora-based systems
      elif [ "${DISTRO}" == "arch" ] || [ "${DISTRO}" == "archarm" ] || [ "${DISTRO}" == "manjaro" ]; then
        pacman -Syu --noconfirm unbound # Install Unbound for Arch-based systems
      elif [ "${DISTRO}" == "alpine" ]; then
        apk add unbound # Install Unbound for Alpine-based systems
      elif [ "${DISTRO}" == "freebsd" ]; then
        pkg install unbound # Install Unbound for FreeBSD systems
      fi
      # Clean up old files if they exist before proceeding
      # Remove the old anchor file, configuration file, and root hints if they are present
      if [ -f "${UNBOUND_ANCHOR}" ]; then
        rm -f "${UNBOUND_ANCHOR}" # Remove old anchor file
      fi
      if [ -f "${UNBOUND_CONFIG}" ]; then
        rm -f "${UNBOUND_CONFIG}" # Remove old Unbound configuration file
      fi
      if [ -f "${UNBOUND_ROOT_HINTS}" ]; then
        rm -f "${UNBOUND_ROOT_HINTS}" # Remove old root hints file
      fi
      # Configure Unbound if the UNBOUND_ROOT directory exists
      # Fetch the latest anchor file, root hints, and configuration from the specified URLs
      if [ -d "${UNBOUND_ROOT}" ]; then
        unbound-anchor -a "${UNBOUND_ANCHOR}"                                  # Initialize the root key for DNSSEC validation
        curl -s "${UNBOUND_ROOT_SERVER_CONFIG_URL}" -o "${UNBOUND_ROOT_HINTS}" # Download root hints for Unbound
        curl -s "${UNBOUND_CONFIG_REMOTE_URL}" -o "${UNBOUND_CONFIG}"          # Download the Unbound configuration file
      fi
      # Backup and configure resolv.conf
      # If resolv.conf exists, make it mutable, back it up, and configure it to use Unbound
      if [ -f "${RESOLV_CONFIG}" ]; then
        chattr -i "${RESOLV_CONFIG}"                 # Remove immutability if it's set
        mv "${RESOLV_CONFIG}" "${RESOLV_CONFIG_OLD}" # Back up the current resolv.conf file
      fi
      # Update the resolv.conf file to use Unbound as the nameserver
      echo "nameserver 127.0.0.1" >"${RESOLV_CONFIG}" # Set localhost as the nameserver
      echo "nameserver ::1" >>"${RESOLV_CONFIG}"      # Set localhost's IPv6 address as the nameserver
      chattr +i "${RESOLV_CONFIG}"                    # Make resolv.conf immutable again to prevent changes
      # Update Unbound manager status
      echo "Unbound: true" >>"${UNBOUND_MANAGER}" # Mark Unbound as installed and running
      # Restart Unbound service based on the init system
      # The script checks the current init system and restarts the Unbound service accordingly
      if [ "${CURRENT_INIT_SYSTEM}" == "systemd" ]; then
        systemctl reenable unbound # Re-enable the Unbound service if using systemd
        systemctl restart unbound  # Restart Unbound service
      elif [ "${CURRENT_INIT_SYSTEM}" == "init" ] || [ "${CURRENT_INIT_SYSTEM}" == "upstart" ]; then
        service unbound restart # Restart the Unbound service for init or upstart systems
      else
        echo "Error: Unsupported init system (${CURRENT_INIT_SYSTEM}). Unbound service could not be restarted." # Error message for unsupported init systems
        exit 1                                                                                                  # Exit the script if an unsupported init system is detected
      fi
      echo "Unbound installation and configuration completed successfully." # Success message
    else
      # If Unbound is already installed, notify the user
      echo "Unbound is already installed." # Print a message indicating that Unbound is already installed
    fi
  }

  # Run the installation function
  install-unbound # Execute the install-unbound function to start the installation process

  # Install unbound Ad Blocker Config
  function ad-block-config-unbound() {
    # Download the ad blocker config file from the provided URL and save it to the specified host file
    curl "${UNBOUND_CONFIG_HOST_URL}" | awk '{print "local-zone: \""$1"\" always_refuse"}' >${UNBOUND_CONFIG_HOST}
    # This makes the unbound configuration aware of the newly downloaded blocklist
    echo "include: ${UNBOUND_CONFIG_HOST}" >>"${UNBOUND_CONFIG}"
    # Print a success message indicating the ad blocker config has been applied
    echo "Ad blocker config has been applied successfully."
  }

  # Run the function to apply the ad blocker config
  ad-block-config-unbound

  # Function to enable automatic updates with real-time configuration options
  function enable-automatic-updates() {
    # Ensure the script path is valid and executable
    script_path="$(realpath "$0")"
    if [ ! -x "$script_path" ]; then
      echo "Error: The script '$script_path' is not executable or the path is invalid."
      return 1
    fi
    # Define the cron job for daily updates at midnight
    cron_job="0 0 * * * $script_path --update"
    # Check if the cron job is already added
    if ! crontab -l | grep -F "$cron_job" >/dev/null; then
      # Add the cron job if not present
      (
        crontab -l 2>/dev/null
        echo "$cron_job"
      ) | crontab -
      if [ $? -ne 0 ]; then
        echo "Error: Failed to add the cron job."
        return 1
      fi
      echo "Cron job for daily updates has been added."
    else
      echo "Cron job for daily updates already exists."
    fi

    # Enable and start the cron service based on the init system
    if [ "$CURRENT_INIT_SYSTEM" == "systemd" ]; then
      echo "Enabling and starting cron using systemd..."
      if ! systemctl enable cron || ! systemctl start cron; then
        echo "Error: Failed to enable/start cron service using systemd."
        return 1
      fi
    elif [ "$CURRENT_INIT_SYSTEM" == "init" ]; then
      echo "Enabling and starting cron using init system..."
      if ! service cron enable || ! service cron start; then
        echo "Error: Failed to enable/start cron service using init system."
        return 1
      fi
    else
      echo "Error: Unknown init system '$CURRENT_INIT_SYSTEM'. Cron may not be enabled."
      return 1
    fi
    # Confirm that automatic updates have been successfully enabled
    echo "Automatic updates have been successfully enabled."
  }

  # Run the function to enable automatic updates
  enable-automatic-updates

  # Function to install the Unbound manager file
  function install-unbound-manager-file() {
    # Check if the Unbound root directory exists
    if [ -d "${UNBOUND_ROOT}" ]; then
      # Check if the Unbound manager file does not already exist
      if [ ! -f "${UNBOUND_MANAGER}" ]; then
        # If the file does not exist, create it and add a line indicating that the Unbound Manager is true
        echo "Unbound Manager: true" >>"${UNBOUND_MANAGER}"
        echo "Unbound Manager file has been created at ${UNBOUND_MANAGER}"
      else
        # If the file exists, notify the user
        echo "Unbound Manager file already exists at ${UNBOUND_MANAGER}. No changes made."
      fi
    else
      # If the Unbound root directory does not exist, notify the user
      echo "Error: Unbound root directory (${UNBOUND_ROOT}) not found. The Unbound Manager file could not be created."
      exit 1
    fi
  }

  # Call the function to install the Unbound manager file
  install-unbound-manager-file

else

  # Function to start unbound
  function start-unbound() {
    # Manage the service based on the init system
    if [[ "${CURRENT_INIT_SYSTEM}" == "systemd" ]]; then
      systemctl start unbound
    elif [[ "${CURRENT_INIT_SYSTEM}" == "sysvinit" ]] || [[ "${CURRENT_INIT_SYSTEM}" == "init" ]] || [[ "${CURRENT_INIT_SYSTEM}" == "upstart" ]]; then
      service unbound start
    fi
  }

  # Function to stop unbound
  function stop-unbound() {
    # Manage the service based on the init system
    if [[ "${CURRENT_INIT_SYSTEM}" == "systemd" ]]; then
      systemctl stop unbound
    elif [[ "${CURRENT_INIT_SYSTEM}" == "sysvinit" ]] || [[ "${CURRENT_INIT_SYSTEM}" == "init" ]] || [[ "${CURRENT_INIT_SYSTEM}" == "upstart" ]]; then
      service unbound stop
    fi
  }

  # Function to restart unbound
  function restart-unbound() {
    # Manage the service based on the init system
    if [[ "${CURRENT_INIT_SYSTEM}" == "systemd" ]]; then
      systemctl restart unbound
    elif [[ "${CURRENT_INIT_SYSTEM}" == "sysvinit" ]] || [[ "${CURRENT_INIT_SYSTEM}" == "init" ]] || [[ "${CURRENT_INIT_SYSTEM}" == "upstart" ]]; then
      service unbound restart
    fi
  }

  # Function to Uninstall Unbound
  function uninstall-unbound() {
    if [ -x "$(command -v unbound)" ]; then
      if [ -f "${UNBOUND_MANAGER}" ]; then
        if pgrep systemd-journal; then
          systemctl disable unbound
          systemctl stop unbound
        else
          service unbound disable
          service unbound stop
        fi
        if [ -f "${RESOLV_CONFIG_OLD}" ]; then
          rm -f ${RESOLV_CONFIG}
          mv ${RESOLV_CONFIG_OLD} ${RESOLV_CONFIG}
        fi
        if { [ "${DISTRO}" == "centos" ] || [ "${DISTRO}" == "rhel" ]; }; then
          yum remove unbound unbound-host -y
        elif { [ "${DISTRO}" == "debian" ] || [ "${DISTRO}" == "pop" ] || [ "${DISTRO}" == "ubuntu" ] || [ "${DISTRO}" == "raspbian" ] || [ "${DISTRO}" == "kali" ] || [ "${DISTRO}" == "linuxmint" ]; }; then
          apt-get remove --purge unbound unbound-host -y
        elif { [ "${DISTRO}" == "arch" ] || [ "${DISTRO}" == "manjaro" ]; }; then
          pacman -Rs unbound unbound-host -y
        elif [ "${DISTRO}" == "fedora" ]; then
          dnf remove unbound -y
        elif [ "${DISTRO}" == "alpine" ]; then
          apk del unbound
        elif [ "${DISTRO}" == "freebsd" ]; then
          pkg delete unbound
        fi
        if [ -f "${UNBOUND_MANAGER}" ]; then
          rm -f ${UNBOUND_MANAGER}
        fi
        if [ -f "${UNBOUND_CONFIG}" ]; then
          rm -f ${UNBOUND_CONFIG}
        fi
        if [ -f "${UNBOUND_ANCHOR}" ]; then
          rm -f ${UNBOUND_ANCHOR}
        fi
        if [ -f "${UNBOUND_ROOT_HINTS}" ]; then
          rm -f ${UNBOUND_ROOT_HINTS}
        fi
        if [ -f "${UNBOUND_ROOT}" ]; then
          rm -f ${UNBOUND_ROOT}
        fi
      fi
    fi
  }

  # Function to update Unbound
  function update-unbound() {
    # Update script
    CURRENT_FILE_PATH="$(realpath "$0")"
    if [ -f "${CURRENT_FILE_PATH}" ]; then
      curl -o "${CURRENT_FILE_PATH}" ${UNBOUND_MANAGER_UPDATE_URL}
      chmod +x "${CURRENT_FILE_PATH}" || exit
    fi
    # Update root hints
    if [ -f "${UNBOUND_ROOT_HINTS}" ]; then
      curl "${UNBOUND_ROOT_SERVER_CONFIG_URL}" -o ${UNBOUND_ROOT_HINTS}
    fi
    # Update Host List
    if [ -f "${UNBOUND_CONFIG_HOST}" ]; then
      rm -f ${UNBOUND_CONFIG_HOST}
      curl "${UNBOUND_CONFIG_HOST_URL}" | awk '{print "local-zone: \""$1"\" always_refuse"}' >${UNBOUND_CONFIG_HOST}
    fi
  }

  # take user input
  function take-user-input() {
    echo "What do you want to do?"
    echo " 1) Start Unbound"
    echo " 2) Stop Unbound"
    echo " 3) Restart Unbound"
    echo " 4) Uninstall Unbound"
    echo " 5) Update Unbound"
    until [[ "$USER_OPTIONS" =~ ^[0-9]+$ ]] && [ "$USER_OPTIONS" -ge 1 ] && [ "$USER_OPTIONS" -le 5 ]; do
      read -rp "Select an Option [1-5]: " -e -i 1 USER_OPTIONS
    done
    case $USER_OPTIONS in
    1)
      start-unbound
      ;;
    2)
      stop-unbound
      ;;
    3)
      restart-unbound
      ;;
    4)
      uninstall-unbound
      ;;
    5)
      update-unbound
      ;;
    esac
  }

  # run the function
  take-user-input

fi
