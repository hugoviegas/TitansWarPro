#!/bin/bash
# shellcheck disable=SC1091,SC2034
. "$HOME"/twm/info.sh
# if config.cfg exist load it
if [ -f "$HOME"/twm/config.cfg ]; then
  . "$HOME"/twm/config.cfg
fi

colors
cd "$HOME"/twm || exit

script_ads() {
  ads_file="${ACCOUNT_ADS_FILE:-$HOME/twm/ads_file}"
  if [ "$RUN" != '-boot' ] && [ -f "$ads_file" ] && [ -s "$ads_file" ] && [ "$(cat "$ads_file")" != "$(date +%d)" ]; then
    if [ "$(cat "$ads_file" 2>/dev/null)" != "$(date +%d)" ]; then
      xdg-open "https://apps.disroot.org/search?q=Shell+Script&category_general=on&language=pt-BR&time_range=&safesearch=1&theme=beetroot"
      date +%d >"$ads_file"
    fi
  else
    date +%d >"$ads_file"
  fi
}

#echo_t "Starting the macro wait a few seconds..." "$BLACK_CYAN" "$COLOR_RESET" "after" "☕"
#sleep 3s

script_slogan
sleep 1s
#/termux
if [ -d /data/data/com.termux/files/usr/share/doc ]; then
  termux-wake-lock
  LS='/data/data/com.termux/files/usr/share/doc'
else
  LS='/usr/share/doc'
fi

#/sources
cd ~/twm || exit
#/twm.sh before sources <<
#. clandmgfight.sh
. language.sh
. requeriments.sh
. loginlogoff.sh
. flagfight.sh
. clanid.sh
. crono.sh
. arena.sh
. coliseum.sh
. campaign.sh
. run.sh
. altars.sh
. clandmg.sh
. clanfight.sh
. clancoliseum.sh
. king.sh
. undying.sh
. trade.sh
. career.sh
. cave.sh
. allies.sh
. svproxy.sh
. check.sh
. league.sh
. specialevent.sh
. function.sh
. update_check.sh
#/twm.sh after sources >>
#/functions
twm_start() {
    # Determine which action to start based on the RUN variable
    if echo "$RUN" | grep -q -E '[-]cv'; then
        cave_start  # Start the cave function if in cave mode
    elif echo "$RUN" | grep -q -E '[-]cl'; then
        twm_play  # Start the main game loop if in clan mode
    elif echo "$RUN" | grep -q -E '[-]boot'; then
        twm_play  # Start the main game loop if in boot mode
    else
        twm_play  # Default action is to start the main game loop
    fi
}

func_unset() {
    # Unset various game-related variables to clear state
    unset HP1 HP2 YOU USER CLAN ENTER ENTER ATK ATKRND DODGE HEAL GRASS STONE BEXIT OUTGATE LEAVEFIGHT WDRED CAVE BREAK NEWCAVE
}

# Initialize account-specific paths before accessing cached selections
set_account_paths
language_setup

if [ -f "$ACCOUNT_RUN_FILE" ]; then
  RUN=$(cat "$ACCOUNT_RUN_FILE")
else
  RUN="-boot"
fi

script_ads

# Check if the user settings file exists and is not empty
if [ -f "$UR_FILE_PATH" ] && [ -s "$UR_FILE_PATH" ]; then
    echo_t "Starting with last settings used." "${GREEN_BLACK}" "${COLOR_RESET}\n"
    # Countdown loop for reconfiguration prompt
    for i in $(seq 4 -1 1); do
        i=$((i - 1))
        if read -r -t 1; then
            # Clear relevant files if Enter is pressed
            set_config "ALLIES" "" # Clear allies configuration
            : >"$TMP/allies.txt"
      : >"$UR_FILE_PATH"
      : >"${ACCOUNT_USER_AGENT_MODE:-$ACCOUNT_ROOT/fileAgent.txt}"
      rm -f "${ACCOUNT_USER_AGENT_STORE:-$ACCOUNT_ROOT/userAgent.txt}" 2>/dev/null
            unset UR UA AL  # Unset user-related variables
            break &>/dev/null  # Exit the loop quietly if Enter is pressed
        fi
        
        echo_t "To reconfigure please press the button" "\033[F" "${GOLD_BLACK} ENTER ${i}s ...${COLOR_RESET}"

    done
fi

# Call necessary functions to set up the environment
load_config
requer_func
func_proxy
login_logoff

# If allies are defined in config.cfg file and not in cave mode, configure allies and clear screen
if [ "$(get_config "ALLIES")" = "" ] && [ "$RUN" != "-cv" ]; then
    conf_allies  # Configure allies if applicable
    clear  # Clear the terminal screen for better visibility
fi

# Call function to display category information (if applicable)
func_cat

# Display messages information (e.g., notifications or updates)
messages_info

# Main loop to continuously start the game based on current mode
while true; do
    #sleep 1s  # Wait for one second between iterations
    twm_start  # Call the twm_start function to determine next action
done