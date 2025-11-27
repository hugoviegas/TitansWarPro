# Global variable to control loop exits
EXIT_CONFIG="n"

update_config() {
    local key="$1"      # Name of the configuration to be changed
    local value="$2"    # New value for the configuration

    # If CONFIG_FILE does not exist, create it (safer behavior)
    if [ ! -f "$CONFIG_FILE" ]; then
        echo_t "Configuration file not found. Creating new..."
        touch "$CONFIG_FILE"
    fi

    # If the key exists in the config file, update it.
    # Otherwise add it to the end (keeps compatibility with older configs).
    if grep -q "^${key}=" "$CONFIG_FILE"; then
        # Update the value in config.cfg using sed for substitution
        sed -i "s/^${key}=.*/${key}=${value}/" "$CONFIG_FILE"
        echo_t "Configuration $key updated to $value."
    else
        # Add new key if it didn't exist
        echo "${key}=${value}" >> "$CONFIG_FILE"
        echo_t "Added new configuration key $key with value $value."
    fi
}

# Function to request key and value, and call update_config with validation
request_update() {
    local key value success=1

    while [ "$success" -ne 0 ]; do
        echo_t "  Macro settings, list of options to modify, type the command number" "${BLACK_GREEN}" "${COLOR_RESET}" "before" "⚙️"
        echo " "
        # NOTE: menu lines are prefixed with __FUNC__ so translate.sh preserves prefixes for function.sh text
        echo_t "__FUNC__ 1- Collect relics. Current value: " "" "$FUNC_check_rewards"
        echo_t "__FUNC__ 2- Use elixir. Current value: " "" "$FUNC_use_elixir"
        echo_t "__FUNC__ 3- Auto update. Current value: " "" "$FUNC_AUTO_UPDATE"
        echo_t "__FUNC__ 4- Get to top in league. Current value: " "" "$FUNC_play_league"
        echo_t "__FUNC__ 5- Change language. Current value: " "" "$LANGUAGE"
        echo_t "__FUNC__ 6- Change allies. Current value: " "" "$ALLIES"
        echo_t "__FUNC__ 7- Collect mission rewards. Current value: " "" "$FUNC_collect_mission_rewards"
        echo_t "__FUNC__ 8- Pause mission rewards on weekends. Current value: " "" "$FUNC_pause_weekends"
        echo_t "__FUNC__ 9- Complete events. Current value: " "" "$FUNC_auto_events"
        echo_t "__FUNC__ A- Complete clan missions. Current value: " "" "$FUNC_clan_missions"
        echo_t "__FUNC__ B- Enable clan statue automatically. Current value: " "" "$FUNC_clan_statue"
        echo_t "Press *'ENTER'* to exit configuration update mode." "" "" "after" "↩️"

        read -r -n 1 key

        case $key in
            (1|relics)
                echo_t "Do you want to collect the relics (y or n):"
                key="FUNC_check_rewards"
                ;;
            (2|elixir)
                echo_t "Do you want to use elixir before all valleys? (y or n):"
                key="FUNC_use_elixir"
                ;;
            (3|auto-update)
                echo_t "Do you want to update the script automatically? (y or n):"
                key="FUNC_AUTO_UPDATE"
                ;;
            (4|league)
                echo_t "Do you want to get to top in league?:"
                echo_t "Type the number of the league you want to reach the top. Example: 1 or 50" "" "" "after" " 🏆"
                # while loop to validate the input for only numbers between 1 and 999 (3 digits)
                while true; do
                    read -r value
                    if [[ $value =~ ^[0-9]{1,3}$ ]]; then
                        set_config "FUNC_play_league" "$value"
                        break
                    else
                        echo_t "Invalid input. Enter a number between 1 and 999:" "" "" "after" "❌"
                    fi
                done
                key="FUNC_play_league"
                ;;
            (5|language)
                echo_t "Do you want to change the language? (y or n):"
                menu_loop
                menu_language
                key="LANGUAGE"
                continue
                ;;
            (6|allies)
                echo_t "Do you want to change your allies for battle? (y or n):"
                while true; do
                    read -r -n 1 value
                    echo
                    [[ $value =~ ^[yYnN]$ ]] && break
                    echo_t "Invalid input. Enter 'y' or 'n':" "" "" "before" "❌"
                done
                if [ "$value" = "n" ]; then
                    continue
                else
                    set_config "ALLIES" ""
                    key="ALLIES"
                    : > "$TMP/allies.txt"
                    : > "$TMP/callies.txt"
                    conf_allies
                fi
                break
                ;;
            (7|mission-rewards)
                echo_t "Do you want to collect mission rewards automatically? (y or n):"
                key="FUNC_collect_mission_rewards"
                ;;
            (8|pause-weekends)
                echo_t "Do you want to automatically pause mission rewards on weekends? (y or n):"
                key="FUNC_pause_weekends"
                ;;
            (9|auto-events)
                echo_t "Do you want to run special events? (y or n):"
                key="FUNC_auto_events"
                ;;
            (A|auto-clanquests)
                echo_t "Do you want to complete the clan missions? (y or n):"
                key="FUNC_clan_missions"
                ;;
            (B|auto-clan-statue)
                echo_t "Do you want to enable clan statue automatically? (y or n):"
                key="FUNC_clan_statue"
                ;;
            (exit|*)
                echo_t "Exiting configuration update mode."
                EXIT_CONFIG="y"  # Signal to exit both loops
                return
                ;;
        esac

        # If a valid key was chosen and it's a FUNC_ flag, validate input for y/n
        if [[ $key == FUNC_* ]]; then
            while true; do
                read -r -n 1 value
                echo  # break line after input
                if [[ $value =~ ^[yYnN]$ ]]; then
                    break
                else
                    echo_t "Invalid input. Please enter 'y' or 'n':"  "" "" "before" "❌"
                fi
            done

            # Update the configuration (will add key if missing)
            update_config "$key" "$value"
            success=$?
            if [ "$success" -ne 0 ]; then
                echo_t "Invalid key. Please try again." "" "" "before" "❌"
            else
                echo_t "Configuration updated successfully!"   "" "" "before" "✅"
                config
                break
            fi
        fi
    done
}

# Function to load configurations from the config.cfg file
load_config() {
    # Load the initial configuration
    CONFIG_FILE="$TMP/config.cfg"
    if [ -f "$CONFIG_FILE" ]; then
        # shellcheck source=/path/to/config.cfg
        # shellcheck disable=SC1091
        . "$CONFIG_FILE"  # Load the configuration file
    else
        echo_t "Configuration file not found. Creating config.cfg with default values."
        
        # Write the config.cfg file with default values
        default_config() {
            # Define default values
            FUNC_check_rewards="y"
            FUNC_use_elixir="n"
            FUNC_coliseum="y"
            FUNC_AUTO_UPDATE="y"
            FUNC_play_league=999
            FUNC_clan_figth="y"
            FUNC_collect_mission_rewards="y"
            FUNC_pause_weekends="n"
            FUNC_auto_events="y"
            FUNC_clan_missions="y"
            FUNC_clan_statue="y"
            LANGUAGE="en"
            ALLIES=""
            SCRIPT_PAUSED="n"

            {
            echo "FUNC_check_rewards=$FUNC_check_rewards"
            echo "FUNC_use_elixir=$FUNC_use_elixir"
            echo "FUNC_coliseum=$FUNC_coliseum"
            echo "FUNC_AUTO_UPDATE=$FUNC_AUTO_UPDATE"
            echo "FUNC_play_league=$FUNC_play_league"
            echo "FUNC_clan_figth=$FUNC_clan_figth"
            echo "FUNC_collect_mission_rewards=$FUNC_collect_mission_rewards"
            echo "FUNC_pause_weekends=$FUNC_pause_weekends"
            echo "FUNC_auto_events=$FUNC_auto_events"
            echo "FUNC_clan_missions=$FUNC_clan_missions"
            echo "FUNC_clan_statue=$FUNC_clan_statue"
            echo "SCRIPT_PAUSED=$SCRIPT_PAUSED"
            echo "LANGUAGE=$LANGUAGE"
            echo "ALLIES="
            } > "$CONFIG_FILE"
        } 
        default_config 
    fi
}

# Function to get the configuration from file and return the value
get_config() {
    local key="$1"  # Name of the configuration to get
    load_config  # Load the configuration file
    echo "${!key}"  # Return the value of the configuration
}

# Function to change or create the configuration from file and return the value
set_config() {
    local key="$1"    # Name of the configuration to set
    local value="$2"  # New value for the configuration
    load_config  # Load the configuration file

    # Remove any existing entry for the key
    grep -v "^${key}=" "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" 2>/dev/null || true
    mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"

    # Add the new configuration
    echo "${key}=${value}" >> "$CONFIG_FILE"

    # Return the value (optional)
    return "$value"
}

config() {
    load_config # Load the configuration file
    EXIT_CONFIG="n"

    # Main script loop
    while true; do
        # Check if the script is paused or signaled to exit
        if [ "$EXIT_CONFIG" = "n" ]; then
            echo_t "Script paused. Waiting for reactivation..." "${BLACK_RED}" "${COLOR_RESET}\n" "before" "⏸️"
            sleep 1s
            # Call the function to request update with key verification
            request_update
    
            # If EXIT_CONFIG is "s", exit the main loop
        else
            echo_t "Exiting configuration update mode..." "${BLACK_RED}" "${COLOR_RESET}\n" "before" "🛑"
            EXIT_CONFIG="n"  # Reset the exit signal for next use
            sleep 1s # Interval before restarting the loop
            break
        fi          
    done
}

# Automatically pause or resume mission rewards based on day of the week
pause_missions_weekend() {
    if [ "$FUNC_pause_weekends" = "n" ]; then
        return
    fi

    local current_day current_hour
    current_day=$(date +%u)   # 1=Mon ... 7=Sun
    current_hour=$(date +%H)

    CONFIG_FILE="$TMP/config.cfg"
    [ -f "$CONFIG_FILE" ] || return

    # Disable mission rewards during weekend
    if [ "$current_day" -eq 6 ] || [ "$current_day" -eq 7 ]; then
        sed -i "s/^FUNC_collect_mission_rewards=.*/FUNC_collect_mission_rewards=n/" "$CONFIG_FILE"
        echo_t "Mission rewards collection paused for the weekend." "${BLACK_RED}" "${COLOR_RESET}" "after" "⏸️"
        return
    fi

    # Re-enable mission rewards Monday at 00:00
    if [ "$current_day" -eq 1 ] && [ "$current_hour" -eq 0 ]; then
        sed -i "s/^FUNC_collect_mission_rewards=.*/FUNC_collect_mission_rewards=y/" "$CONFIG_FILE"
        echo_t "Mission rewards collection reactivated automatically." "${BLACK_GREEN}" "${COLOR_RESET}" "after" "✅"
        return
    fi
}

testColour() {
   echo -e "${BLACK_BLACK}BLACK_BLACK${COLOR_RESET}\n"
   echo -e "${BLACK_CYAN}BLACK_CYAN${COLOR_RESET}\n"
   echo -e "${BLACK_GREEN}BLACK_GREEN${COLOR_RESET}\n"
   echo -e "${BLACK_GRAY}BLACK_GRAY${COLOR_RESET}\n"
   echo -e "${BLACK_PINK}BLACK_PINK${COLOR_RESET}\n"
   echo -e "${BLACK_RED}BLACK_RED${COLOR_RESET}\n"
   echo -e "${CYAN_BLACK}CYAN_BLACK${COLOR_RESET}\n"
   echo -e "${BLACK_YELLOW}BLACK_YELLOW${COLOR_RESET}\n"
   echo -e "${CYAN_CYAN}CYAN_CYAN${COLOR_RESET}\n"
   echo -e "${GOLD_BLACK}GOLD_BLACK${COLOR_RESET}\n"
   echo -e "${GREEN_BLACK}GREEN_BLACK${COLOR_RESET}\n"
   echo -e "${PURPLEi_BLACK}PURPLEi_BLACK${COLOR_RESET}\n"
   echo -e "${PURPLEis_BLACK}PURPLEis_BLACK${COLOR_RESET}\n"
   echo -e "${WHITE_BLACK}WHITE_BLACK${COLOR_RESET}\n"
   echo -e "${WHITEb_BLACK}WHITEb_BLACK${COLOR_RESET}\n"
   echo -e "${RED_BLACK}RED_BLACK${COLOR_RESET}\n"
   echo -e "${BLUE_BLACK}BLUE_BLACK${COLOR_RESET}\n"
   sleep 30s
}