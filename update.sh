#!/bin/sh

# Clear the terminal screen
clear

# Define color codes for output formatting
BLACK_CYAN='\033[01;36m\033[01;07m'
BLACK_GREEN='\033[00;32m\033[01;07m'
BLACK_YELLOW='\033[00;33m\033[01;07m'
GOLD_BLACK='\033[33m'
CYAN_BLACK='\033[36m'
COLOR_RESET='\033[00m'

# Debugging function to print messages
debug() {
    echo "DEBUG: $1"
}

# Check if a version number is provided as an argument
if [ $# -eq 1 ]; then
    debug "Argument provided: $1"
    case $1 in
        1)
            VERSION="Master"
            debug "Version set to Master"
            ;;
        2)
            VERSION="Beta"
            debug "Version set to Beta"
            ;;
        3)
            VERSION="Old"
            debug "Version set to Old"
            ;;
        *)
            echo "Invalid selection. Please use 1 for Master, 2 for Beta, or 3 for Old."
            exit 1  # Exit if an invalid option is selected
            ;;
    esac
else
    # Display version options to the user
    printf "Versions\n 1- Master\n 2- Beta\n 3- Old\n"
    printf "${CYAN_BLACK}Select the version:${COLOR_RESET} \n"

    # User input handling
    stty raw  # Set terminal to raw mode to read single character input
    VERSION=$(dd bs=1 count=1 2>/dev/null)  # Read one byte from input
    stty -raw  # Reset terminal to normal mode

    debug "User input received: $VERSION"

    # Determine the version based on user input
    case $VERSION in
        1)
            VERSION="Master"
            debug "Version set to Master"
            ;;
        2)
            VERSION="Beta"
            debug "Version set to Beta"
            ;;
        3)
            VERSION="Old"
            debug "Version set to Old"
            ;;
        *)
            echo "Invalid selection. Exiting."
            exit 1  # Exit if an invalid option is selected
            ;;
    esac
fi

# Normalize the version string to lowercase for use in URLs
version=$(echo "$VERSION" | sed 's/[ \t]//g' | tr "[[:upper:]]" "[[:lower:]]")
debug "Normalized version for URL: $version"

# Inform the user about the preparation of the repository source
printf "\n${CYAN_BLACK}🔧 Preparing${COLOR_RESET} ${GOLD_BLACK}$VERSION${COLOR_RESET} ${CYAN_BLACK}repository source...${COLOR_RESET}\n"

# Create the twm directory if it doesn't exist and change into it
mkdir -p ~/twm
cd ~/twm || exit

# Define scripts to download
SCRIPTS="easyinstall.sh info.sh"

# Remove any existing scripts in both home and current directories
debug "Removing existing scripts..."
rm -rf "$HOME/$SCRIPTS" "$SCRIPTS" 2>/dev/null

# Define the server URL based on selected version
SERVER="https://raw.githubusercontent.com/hugoviegas/TitansWarPro/${version}/"
debug "Server URL: $SERVER"

# Count the number of scripts to download
NUM_SCRIPTS=$(echo "$SCRIPTS" | wc -w)
LEN=0

# Loop through each script and handle downloading/updating
for script in $SCRIPTS; do
    LEN=$((LEN + 1))
    printf "Checking $LEN/$NUM_SCRIPTS $script\n"

    # Get the size of the remote script
    remote_count=$(curl "${SERVER}${script}" -s -L | wc -c)
    debug "Remote count for $script: $remote_count"

    # Get the size of the local script if it exists, otherwise set to 1 (to indicate it does not exist)
    if [ -e ~/twm/"$script" ]; then
        local_count=$(wc -c <"$script")
        debug "Local count for $script: $local_count"
    else
        local_count=1
        debug "$script does not exist locally."
    fi

    # Compare remote and local script sizes to determine action
    if [ -e ~/twm/"$script" ] && [ "$remote_count" -eq "$local_count" ]; then
        printf "✅ ${BLACK_CYAN}Updated $script${COLOR_RESET}\n"
    elif [ -e ~/twm/"$script" ] && [ "$remote_count" -ne "$local_count" ]; then
        printf "🔁 ${BLACK_GREEN}Updating $script${COLOR_RESET}\n"
        curl "${SERVER}${script}" -s -L >"$script"  # Update existing script with new content
    else
        printf "🔽 ${BLACK_YELLOW}Downloading $script${COLOR_RESET}\n"
        curl "${SERVER}${script}" -s -L -O  # Download new script if it doesn't exist locally
    fi

    chmod +x "$script"  # Make the script executable
    cp "$script" "$HOME/$script" 2>/dev/null  # Copy script to user's home directory (if applicable)
    
    sleep 0.1s  # Brief pause between downloads for stability
done

# Inform user that repository source has been updated and start easyinstall.sh with selected version
printf "\n${BLACK_GREEN}✅ Updated repository source${COLOR_RESET}\n\n${BLACK_CYAN}Starting ./easyinstall.sh $version ...${COLOR_RESET}\n"
sleep 2s  # Pause before starting installation script

./easyinstall.sh "$version"  # Execute the installation script with selected version as argument