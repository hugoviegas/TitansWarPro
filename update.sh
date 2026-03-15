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

# Check if a version number is provided as an argument
if [ $# -eq 1 ]; then
    case $1 in
        1)
            VERSION="Master"
            ;;
        2)
            VERSION="Beta"
            ;;
        3)
            VERSION="Beta2"
            ;;
        4)
            VERSION="Main"
            ;;
        *)
            echo "Invalid selection. Please use 1 for Master, 2 for Beta, 3 for Beta2, or 4 for Other Macro ."
            exit 1  # Exit if an invalid option is selected
            ;;
    esac
else
    # Display version options to the user
    printf "Versions\n 1- Master\n 2- Beta\n 3- Beta2\n 4- Other Macro (delete all)\n"
    printf "${CYAN_BLACK}Select the version:${COLOR_RESET} \n"

    # User input handling
    stty raw  # Set terminal to raw mode to read single character input
    VERSION=$(dd bs=1 count=1 2>/dev/null)  # Read one byte from input
    stty -raw  # Reset terminal to normal mode
    #SOURCE_CODE=""
    # Determine the version based on user input
    case $VERSION in
        1)
            VERSION="Master"
            ;;
        2)
            VERSION="Beta"
            ;;
        3)
            VERSION="Beta2"
            ;;
        4)
            VERSION="Main"
            # Define the server URL based on selected version
            #SERVER="https://codeberg.org/ueliton/TitansWarMacro/src/branch/master/"
            rm -rf ~/twm
            ;;
        *)
            echo "Invalid selection. Exiting."
            exit 1  # Exit if an invalid option is selected
            ;;
    esac
fi

# Normalize the version string to lowercase for use in URLs
version=$(echo "$VERSION" | sed 's/[ \t]//g' | tr "[[:upper:]]" "[[:lower:]]")

# Inform the user about the preparation of the repository source
printf "\n${CYAN_BLACK}🔧 Preparing${COLOR_RESET} ${GOLD_BLACK}$VERSION${COLOR_RESET} ${CYAN_BLACK}repository source...${COLOR_RESET}\n"

# Create the twm directory if it doesn't exist and change into it
mkdir -p ~/twm
cd ~/twm || exit

# Define scripts to download
SCRIPTS="easyinstall.sh info.sh"

# Remove any existing scripts in both home and current directories
rm -rf "${HOME}*/$SCRIPTS" "$SCRIPTS" 2>/dev/null

# Define the server URL based on selected version
SERVER="https://raw.githubusercontent.com/hugoviegas/TitansWarPro/${version}/"

# Count the number of scripts to download
NUM_SCRIPTS=$(echo "$SCRIPTS" | wc -w)
LEN=0

# Loop through each script and handle downloading/updating
for script in $SCRIPTS; do
    LEN=$((LEN + 1))
    label=$(printf "[%02d/%02d]" "$LEN" "$NUM_SCRIPTS")
    local_file="$HOME/twm/$script"
    temp_file="$local_file.tmp.$$"

    if [ ! -e "$local_file" ]; then
        # New file — download unconditionally
        if curl "${SERVER}${script}" -s -L -o "$local_file" 2>/dev/null; then
            printf "  🆕 %s %-32s ${BLACK_YELLOW}new${COLOR_RESET}\n" "$label" "$script"
        else
            printf "  ⚠️  %s %-32s ${BLACK_YELLOW}skipped${COLOR_RESET}\n" "$label" "$script"
        fi
    else
        # File exists — download to temp and compare hashes
        if curl "${SERVER}${script}" -s -L -o "$temp_file" 2>/dev/null; then
            # Get hashes for comparison
            local_hash=$(sha256sum "$local_file" 2>/dev/null | awk '{print $1}')
            remote_hash=$(sha256sum "$temp_file" 2>/dev/null | awk '{print $1}')

            if [ "$remote_hash" = "$local_hash" ]; then
                # Content is identical — file is current
                rm -f "$temp_file"
                printf "  ✅ %s %-32s ${BLACK_CYAN}unchanged${COLOR_RESET}\n" "$label" "$script"
            else
                # Content differs — replace with new version
                mv "$temp_file" "$local_file"
                printf "  🔽 %s %-32s ${BLACK_GREEN}updated${COLOR_RESET}\n" "$label" "$script"
            fi
        else
            # Download failed
            rm -f "$temp_file"
            printf "  ⚠️  %s %-32s ${BLACK_YELLOW}skipped${COLOR_RESET}\n" "$label" "$script"
        fi
    fi

    chmod +x "$local_file"  # Make the script executable
    cp "$local_file" "$HOME/$script" 2>/dev/null  # Copy script to user's home directory (if applicable)

    sleep 0.1s  # Brief pause between downloads for stability
done

# Inform user that repository source has been updated and start easyinstall.sh with selected version
printf "\n${BLACK_GREEN}✅ Updated repository source${COLOR_RESET}\n\n${BLACK_CYAN}Starting ./easyinstall.sh $version ...${COLOR_RESET}\n"
sleep 2s  # Pause before starting installation script

./easyinstall.sh "$version"  # Execute the installation script with selected version as argument
