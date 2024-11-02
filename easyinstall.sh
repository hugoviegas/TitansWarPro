#!/bin/bash
# shellcheck disable=all
# Define installation paths
INSTALL_DIR="/usr/games"
SHARE_DIR="/usr/share/twm-library"
SERVER="https://raw.githubusercontent.com/hugoviegas/TitansWarPro"

# Create necessary directories if they do not exist
sudo mkdir -p "$INSTALL_DIR" "$SHARE_DIR"

# Determine version: default to "master" if no argument is provided
version="${1:-master}"

# Function to download and set up a script
download_script() {
  local _download_script_url="$1"
  local _download_script_target="$2"

  if ! curl -s -L "${_download_script_url}" -o "${_download_script_target}"; then
    printf "❌ Error downloading ${_download_script_url}\n"
    exit 1
  fi
  sudo chmod +x "$_download_script_target"
}

# Download and set up info.sh if it does not exist in the INSTALL_DIR
if [ ! -e "$INSTALL_DIR/info.sh" ]; then
  download_script "$SERVER/$version/info.sh" "$INSTALL_DIR/info.sh"
  sleep 0.5s
fi

# Source info.sh to access functions like colors and script_slogan
# shellcheck disable=SC1091
. "$INSTALL_DIR/info.sh"
colors
script_slogan

# Display message for the start of the installation
printf "${BLACK_CYAN}Installing TWM...\n⌛ Please wait...⌛${COLOR_RESET}\n"

# Function to check and update easyinstall.sh
check_update_easyinstall() {
  local remote_count local_count
  remote_count=$(curl -s -L "${SERVER}/${version}/easyinstall.sh" | wc -c)
  local_count=1

  if [ -e "$INSTALL_DIR/easyinstall.sh" ]; then
    local_count=$(wc -c <"$INSTALL_DIR/easyinstall.sh")
  fi

  if [ "$remote_count" -ne "$local_count" ]; then
    printf "🔁 Updating easyinstall.sh...\n"
    download_script "${SERVER}/${version}/easyinstall.sh" "$INSTALL_DIR/easyinstall.sh"
  fi
}

#check_update_easyinstall

# Run the updated easyinstall.sh script
printf "\n${BLACK_GREEN}✅ Repository source updated successfully${COLOR_RESET}\n\n"
printf "${BLACK_CYAN}Starting download with version $version...${COLOR_RESET}\n"
sleep 2s  # Brief pause before starting the installation script
#"$INSTALL_DIR/easyinstall.sh" "$version"

# Function to install Termux packages
install_termux_packages() {
  REQUIRED_PKGS="w3m jq coreutils ncurses-utils termux-api procps"
  for pkg in $REQUIRED_PKGS; do
    if ! command -v "$pkg" >/dev/null 2>&1; then
      pkg install "$pkg" -y
    fi
  done
}

# Check if Termux environment is detected
if [ -d /data/data/com.termux/files/usr/share/doc ]; then
  termux-wake-lock
  # Configure DNS if necessary
  for dns in "114.114.114.114" "8.8.8.8"; do
    if ! grep -q "nameserver $dns" "$PREFIX/etc/resolv.conf"; then
      echo "nameserver $dns" | sudo tee -a "$PREFIX/etc/resolv.conf" > /dev/null
    fi
  done

  # Set up Termux boot script to run play.sh on boot
  BOOT_DIR="$HOME/.termux/boot"
  mkdir -p "$BOOT_DIR"

  # Create the play.sh script using a here document without trailing characters
  cat <<- EOF > "$BOOT_DIR/play.sh"
#!/bin/sh
bash ${SHARE_DIR}/play.sh -b
EOF

  chmod +x "$BOOT_DIR/play.sh"

  # Install required Termux packages
  install_termux_packages
fi

# Function to install Cygwin packages
install_cygwin_packages() {
  DOC_DIR="/usr/share/doc"

  if ! command -v apt-cyg >/dev/null 2>&1; then
    download_script "$SERVER/beta/apt-cyg" "/usr/bin/apt-cyg"
  fi

  REQUIRED_PKGS="w3m ncurses-term coreutils procps jq"
  for pkg in $REQUIRED_PKGS; do
    if [ ! -e "${DOC_DIR}/${pkg}" ]; then
      apt-cyg install "$pkg" -y &
    fi
  done
}

# Check if the script is running in a Cygwin environment
if uname | grep -iq "cygwin"; then
  install_cygwin_packages
fi

# Handle iPhone (iSH) and UserLAnd Terminal package installations
APPISH=$(uname -a | grep -o "\-ish")
if [ "$SHELL" = "/bin/ash" ] && [ "$APPISH" = '-ish' ]; then
  printf "${BLACK_CYAN}Install the necessary packages for Alpine on app iSH (iPhone):${COLOR_RESET}\n"
  printf "apk update\napk add curl\napk add w3m\napk add coreutils\napk add --no-cache tzdata\n\n"
  sleep 5s
elif [ "$SHELL" != "/bin/ash" ] && [ "$APPISH" != '-ish' ] && uname -m | grep -q -E '(aarch64|armhf|armv7|mips64)' && [ ! -d /data/data/com.termux/files/usr/share/doc ]; then
  printf "${BLACK_CYAN}Install the necessary packages for Alpine on app UserLAnd (Android):${COLOR_RESET}\n"
  printf "apk update\nsudo apk add curl\nsudo apk add w3m\nsudo apk add coreutils\nsudo apk add --no-cache tzdata\n\n"
  sleep 5s
elif [ "$SHELL" != "/bin/ash" ] && [ "$APPISH" != '-ish' ] && uname -m | grep -q -E "(ppc64le|riscv64|s390x|x86|x86_64)" && [ ! -d /data/data/com.termux/files/usr/share/doc ]; then
  printf "${BLACK_CYAN}Install required packages for Linux or Windows WSL:${COLOR_RESET}\n"
  printf "sudo apt update\nsudo apt install curl coreutils ncurses-term procps w3m jq -y\n"
  sleep 5s
fi

# Starting the download process...
cd "${SHARE_DIR}" || exit
printf "${BLACK_CYAN}\n⌛ Waiting to download scripts...${COLOR_RESET}\n"

sync_func() {
  SCRIPTS="allies.sh altars.sh arena.sh campaign.sh career.sh cave.sh check.sh \
           clancoliseum.sh clanfight.sh clanid.sh coliseum.sh crono.sh \
           flagfight.sh function.sh king.sh language.sh league.sh \
           loginlogoff.sh play.sh requeriments.sh run.sh svproxy.sh \
           specialevent.sh trade.sh twm.sh undying.sh update_check.sh"

  NUM_SCRIPTS=$(echo "$SCRIPTS" | wc -w)
  LEN=0

  for script in $SCRIPTS; do
    LEN=$((LEN + 1))
    printf "Checking $LEN/$NUM_SCRIPTS: $script\n"

    # Fetch the size of the remote script
    remote_count=$(curl -s -L "${SERVER}/${version}/${script}" | wc -c)
    
    # Check if the local script exists and get its size
    if [ -e "${SHARE_DIR}/$script" ]; then
      local_count=$(wc -c <"${SHARE_DIR}/$script")
    else
      local_count=0  # Set local_count to 0 if the file does not exist
    fi

    # Compare remote and local file sizes
    if [ "$remote_count" -eq "$local_count" ]; then
      printf "✅ ${BLACK_CYAN}Updated $script${COLOR_RESET}\n"
    else
      if [ "$local_count" -gt 0 ]; then
        printf "🔁 ${BLACK_GREEN}Updating $script${COLOR_RESET}\n"
      else
        printf "🔽 ${BLACK_YELLOW}Downloading $script${COLOR_RESET}\n"
      fi
      curl -s -L "${SERVER}/${version}/${script}" -o "${SHARE_DIR}/$script"
    fi

    sleep 0.1s  # Brief pause for stability
  done

  # Convert DOS line endings to Unix format
  find "${SHARE_DIR}" -type f -name '*.sh' -print0 | xargs -0 sed -i 's/\r$//' 2>/dev/null
  chmod +x "${SHARE_DIR}"/*.sh  # Make all scripts executable
}

# Start the sync process
sync_func

# Merge function handling
sync_func_other() {
  SCRIPTS="requeriments.sh svproxy.sh loginlogoff.sh crono.sh check.sh run.sh clanid.sh allies.sh altars.sh arena.sh campaign.sh career.sh cave.sh clancoliseum.sh clandungeon.sh clanfight.sh coliseum.sh flagfight.sh function.sh king.sh language.sh league.sh specialevent.sh trade.sh undying.sh update_check.sh"

  # Download the main scripts
  curl -s -L "${SERVER}/${version}/play.sh" -o "${SHARE_DIR}/play.sh"
  curl -s -L "${SERVER}/${version}/info.sh" -o "${SHARE_DIR}/info.sh"
  curl -s -L "${SERVER}/${version}/twm.sh" -o "${SHARE_DIR}/twm.sh"

  for script in $SCRIPTS; do
    printf "🔁 ${BLACK_GREEN}Updating $script${COLOR_RESET}\n"
    curl -s -L "${SERVER}/${version}/${script}" >> "${SHARE_DIR}/twm.sh"
    printf "\n#\n" >> "${SHARE_DIR}/twm.sh"
    sleep 0.1s
  done

  # Convert DOS line endings to Unix format
  find "${SHARE_DIR}" -type f -name '*.sh' -print0 | xargs -0 sed -i 's/\r$//' 2>/dev/null
}

#/merge
#if echo "$@" | grep -q 'merge'; then
#  sync_func_other
#else
  sync_func
#fi

echo 'play-twm() { /usr/share/twm-library/play.sh "$@" ; }' >> ~/.bashrc
echo 'export -f play-twm' >> ~/.bashrc  # Para garantir que a função esteja disponível em subshells

# Carrega as novas configurações
source ~/.bashrc

# Check if running in iSH environment and modify script shebang accordingly
APPISH=$(uname -a | grep -o "\-ish")
if [ "$SHELL" = "/bin/ash" ] && [ "$APPISH" = '-ish' ]; then
  sed -i 's,#!/bin/bash,#!/bin/sh,g' "${SHARE_DIR}"/*.sh
fi

script_slogan
printf "✅ ${BLACK_CYAN}Updated scripts!${COLOR_RESET}\n To execute run command: ${GOLD_BLACK}."${SHARE_DIR}"/play.sh${COLOR_RESET}\n       For coliseum run: ${GOLD_BLACK}."${SHARE_DIR}"/play.sh -cl${COLOR_RESET}\n           For cave run: ${GOLD_BLACK}."${SHARE_DIR}"/play.sh -cv${COLOR_RESET}\n"

# Terminate existing instances of play.sh
tipidf=$(ps ax -o pid=,args= | grep "sh.*${SHARE_DIR}/play.sh" | grep -v 'grep' | head -n 1 | grep -o -E '([0-9]{3,5})')
until [ -z "$tipidf" ]; do
  kill -9 "$tipidf" 2>/dev/null
  tipidf=$(ps ax -o pid=,args= | grep "sh.*${SHARE_DIR}/play.sh" | grep -v 'grep' | head -n 1 | grep -o -E '([0-9]{3,5})')
  sleep 1s
done

tipidf=$(ps ax -o pid=,args= | grep "sh.*${SHARE_DIR}/twm.sh" | grep -v 'grep' | head -n 1 | grep -o -E '([0-9]{3,5})')
until [ -z "$tipidf" ]; do
  kill -9 "$tipidf" 2>/dev/null
  tipidf=$(ps ax -o pid=,args= | grep "sh.*${SHARE_DIR}/twm.sh" | grep -v 'grep' | head -n 1 | grep -o -E '([0-9]{3,5})')
  sleep 1s
done

# Restart play.sh based on the run mode specified in the runmode_file
if [ -f "${SHARE_DIR}"/runmode_file ]; then
  case "$(cat ${SHARE_DIR}/runmode_file)" in
    "-cl")
      printf "${BLACK_GREEN}Automatically restarting in 3s after update...${COLOR_RESET}\n"
      sleep 3s
      "${SHARE_DIR}"/play.sh -cl
      ;;
    "-cv")
      printf "${BLACK_GREEN}Automatically restarting in 3s after update...${COLOR_RESET}\n"
      sleep 3s
      "${SHARE_DIR}"/play.sh -cv
      ;;
    *)
      printf "${BLACK_GREEN}Automatically restarting in 3s after update...${COLOR_RESET}\n"
      sleep 3s
      "${SHARE_DIR}"/play.sh -boot
      ;;
  esac
fi
