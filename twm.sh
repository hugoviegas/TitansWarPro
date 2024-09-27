#!/bin/bash
. "$HOME"/twm/info.sh
colors
RUN=$(cat "$HOME"/twm/runmode_file)
cd "$HOME"/twm || exit

script_ads() {
  if [ "$RUN" != '-boot' ] && [ -f "$HOME/twm/ads_file" ] && [ -s "$HOME/twm/ads_file" ] && [ "$(cat "$HOME"/twm/ads_file)" != "$(date +%d)" ]; then
    if [ "$(cat "$HOME"/twm/ads_file 2>/dev/null)" != "$(date +%d)" ]; then
      xdg-open "https://apps.disroot.org/search?q=Shell+Script&category_general=on&language=pt-BR&time_range=&safesearch=1&theme=beetroot"
      date +%d >"$HOME"/twm/ads_file
    fi
  else
    date +%d >"$HOME"/twm/ads_file
  fi
}
script_ads

printf "${BLACK_CYAN}\n Starting...\n👉 Please wait...☕👴${COLOR_RESET}\n"
#. ~/twm/info.sh
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
. requeriments.sh
. loginlogoff.sh
. flagfight.sh
. clanid.sh
. crono.sh
. clanquest.sh
. arena.sh
. coliseum.sh
. campaign.sh
. run.sh
. altars.sh
. clanfight.sh
. clancoliseum.sh
. king.sh
. undying.sh
. clandungeon.sh
. trade.sh
. career.sh
. cave.sh
. allies.sh
. svproxy.sh
. check.sh
. league.sh
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

#Access any page link
fetch_page() {
    local page_path=$1  # The specific part of the URL you want to fetch (e.g., "/quest/")
    
    # Fetch the page with the specified path
    (
        w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}${page_path}" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" > "$TMP/SRC"
    ) </dev/null &>/dev/null &  # Run in background and suppress output

    time_exit 20  # Wait for the process to finish
}


# Check if the user settings file exists and is not empty
if [ -f "$HOME/twm/ur_file" ] && [ -s "$HOME/twm/ur_file" ]; then
    printf "${GREEN_BLACK} Starting with last settings used.${COLOR_RESET}\n"
    
    num=6  # Number of seconds to wait before reconfiguration prompt

    # Countdown loop for reconfiguration prompt
    for i in $(seq 3 -1 1); do
        i=$((i - 1))
        if read -t 1; then
            # Clear relevant files if Enter is pressed
            >"$HOME/twm/al_file"
            >"$HOME/twm/ur_file"
            >"$HOME/twm/fileAgent.txt"
            unset UR UA AL  # Unset user-related variables
            break &>/dev/null  # Exit the loop quietly if Enter is pressed
        fi
        
        printf " Hit${GOLD_BLACK} [Enter]${COLOR_RESET} to${GOLD_BLACK} reconfigure${GREEN_BLACK} ${i}s${COLOR_RESET}\n"
    done
fi

# Call necessary functions to set up the environment
requer_func
func_proxy
login_logoff

# If allies are defined and not in cave mode, configure allies and clear screen
if [ -n "$ALLIES" ] && [ "$RUN" != "-cv" ]; then
    conf_allies  # Configure allies if applicable
    clear  # Clear the terminal screen for better visibility
fi

# Call function to display category information (if applicable)
func_cat

# Display messages information (e.g., notifications or updates)
messages_info

# Main loop to continuously start the game based on current mode
while true; do
    sleep 1s  # Wait for one second between iterations
    twm_start  # Call the twm_start function to determine next action
done