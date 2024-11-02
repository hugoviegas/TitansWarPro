#!/bin/sh

# Clear the terminal screen
clear
# Defina o diretório de instalação para /usr/games (onde os scripts vão agora)
INSTALL_DIR="/usr/games"

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
            VERSION="Main"
            ;;
        *)
            echo "Invalid selection. Please use 1 for Master, 2 for Beta, or 3 for Other Macro ."
            exit 1  # Exit if an invalid option is selected
            ;;
    esac
else
    # Display version options to the user
    printf "Versions\n 1- Master\n 2- Beta\n 3- Other Macro (delete all)\n"
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
            VERSION="Main"
            #SOURCE_CODE="sharesourcecode/TitansWarMacro"
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

# Verifique se as variáveis estão definidas para evitar comportamento inesperado
INSTALL_DIR="${INSTALL_DIR:?Diretório de instalação não definido}"
SCRIPTS="${SCRIPTS:?Lista de scripts não definida}"

# Remove any existing scripts in both home and current directories
#rm -rf "${HOME}*/$SCRIPTS" "$SCRIPTS" 2>/dev/null
rm -rf "${INSTALL_DIR:?}/${SCRIPTS}" "${SCRIPTS}" 2>/dev/null

# Define the server URL based on selected version
SERVER="https://raw.githubusercontent.com/hugoviegas/TitansWarPro/${version}/"

# Get the total number of scripts
NUM_SCRIPTS=$(echo "$SCRIPTS" | wc -w)
CURRENT_INDEX=0

# Loop through each script to check, download, or update
for script in $SCRIPTS; do
    CURRENT_INDEX=$((CURRENT_INDEX + 1))
    printf "Checking %d/%d: %s\n" "$CURRENT_INDEX" "$NUM_SCRIPTS" "$script"

    # Get the size of the remote script
    remote_size=$(curl -s -L "${SERVER}${script}" | wc -c)

    # Check if the local script exists, otherwise set size to 1 (indicating it doesn't exist)
    if [ -e "$INSTALL_DIR/$script" ]; then
        local_size=$(wc -c <"$script")
    else
        local_size=1
    fi

    # Determine if an update or download is needed
    if [ -e "$INSTALL_DIR/$script" ] && [ "$remote_size" -eq "$local_size" ]; then
        printf "✅ ${BLACK_CYAN}Already up to date: $script${COLOR_RESET}\n"
    elif [ -e "$INSTALL_DIR/$script" ] && [ "$remote_size" -ne "$local_size" ]; then
        printf "🔁 ${BLACK_GREEN}Updating: $script${COLOR_RESET}\n"
        curl -s -L "${SERVER}${script}" > "$script"  # Download updated content
    else
        printf "🔽 ${BLACK_YELLOW}Downloading: $script${COLOR_RESET}\n"
        curl -s -L -O "${SERVER}${script}"  # Download if not present locally
    fi

    # Make the script executable and copy it to the installation directory
    chmod +x "$script"
    sudo cp "$script" "$INSTALL_DIR/" 2>/dev/null
    
    sleep 0.1s  # Brief pause for download stability
done

# Inform user that repository source has been updated and start easyinstall.sh with selected version
printf "\n${BLACK_GREEN}✅ Updated repository source${COLOR_RESET}\n\n${BLACK_CYAN}Starting ./easyinstall.sh $version ...${COLOR_RESET}\n"
sleep 2s  # Pause before starting installation script

./easyinstall.sh "$version"  # Execute the installation script with selected version as argument