# Global variable to control loop exits
EXIT_CONFIG="n"

update_config() {
    local key="$1"      # Name of the configuration to be changed
    local value="$2"    # New value for the configuration

    # Check if the key exists in the config.cfg file
    if grep -q "^${key}=" "$CONFIG_FILE"; then
        # Update the value in config.cfg using sed for substitution
        sed -i "s/^${key}=.*/${key}=${value}/" "$CONFIG_FILE"
        echo_t "Configuration $key updated to $value."
    else
        echo_t "Configuration $key not found in the config.cfg file."
        return 1  # Return an error to indicate failure
    fi
}

# Function to request key and value, and call update_config with validation
request_update() {
    local key value success=1  # Initialize success with 1 (failure)

    while [ "$success" -ne 0 ]; do
        # Instructions for the user
        echo_t "  Macro settings, list of changes to modify type the command number" "${BLACK_GREEN}" "${COLOR_RESET}" "before" "⚙️"
        echo_t "1- Collect relics. | Current value: " "" "$FUNC_check_rewards"
        echo_t "2- Use elixir. | Current value: " "" "$FUNC_use_elixir"
        echo_t "3- Auto update. | Current value: " "" "$FUNC_AUTO_UPDATE"
        echo_t "Press *ENTER* to exit configuration update mode." "" "" "after" "↩️"
        read -r key

        case $key in
            (1|relics)
                echo_t "Do you want to collect the relics (y or n):"
                key="FUNC_check_rewards"
                ;;
            (2|elixir)
                echo_t "Do you want to use elixir before all valleys? (y or n):"
                key="FUNC_elixir"
                ;;
            (3|auto-update)
                echo_t "Do you want to update the script automatically? (y or n):"
                key="FUNC_AUTO_UPDATE"
                ;;
            (exit|*)
                echo_t "Exiting configuration update mode."
                EXIT_CONFIG="y"  # Signal to exit both loops
                break
                ;;
        esac

        # If a valid key was chosen, validate input for value
        if [[ $key != "FUNC_check_rewards" && $key != "FUNC_elixir" && $key != "FUNC_AUTO_UPDATE" ]]; then
            continue
        fi

        while true; do
            read -r -n 1 value
            echo  # To break the line after input
            if [[ $value =~ ^[yYnN]$ ]]; then
                break
            else
                echo_t "Invalid input. Please enter 'y' or 'n':"  "" "" "before" "❌"
            fi
        done

        # Call the configuration update function and capture the status
        update_config "$key" "$value"
        success=$?

        # Check if there was a failure and notify the user
        if [ "$success" -ne 0 ]; then
            echo_t "Invalid key. Please try again." "" "" "before" "❌"
            rm -f "$CONFIG_FILE"  # Remove the config file to reset the configuration
            load_config  # Reload the configuration after the reset
        else
            echo_t "Configuration updated successfully!"   "" "" "before" "✅"
            config
            break
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
        
        # Define default values
        FUNC_check_rewards="n"
        FUNC_use_elixir="n"
        FUNC_coliseum="y"
        FUNC_AUTO_UPDATE="n"
        SCRIPT_PAUSED="n"

        # Write the config.cfg file with default values
        {
            echo "FUNC_check_rewards=$FUNC_check_rewards"
            echo "FUNC_use_elixir=$FUNC_use_elixir"
            echo "FUNC_coliseum=$FUNC_coliseum"
            echo "FUNC_AUTO_UPDATE=$FUNC_AUTO_UPDATE"
            echo "SCRIPT_PAUSED=$SCRIPT_PAUSED"
        } > "$CONFIG_FILE"
    fi
}

config() {
    load_config
    SCRIPT_PAUSED="y"

    # Main script loop
    while true; do
        # Check if the script is paused or signaled to exit
        if [ "$SCRIPT_PAUSED" = "y" ] || [ "$EXIT_CONFIG" = "y" ]; then
            echo_t "Script paused. Waiting for reactivation..."
            sleep 2
            load_config  # Reload the configuration after the interval

            # If EXIT_CONFIG is "s", exit the main loop
            if [ "$EXIT_CONFIG" = "y" ]; then
                echo_t "Exiting configuration mode..."
                EXIT_CONFIG="n"  # Reset the exit signal for next use
                break
            fi

            # Prompt to change configurations during execution
            echo_t "Do you want to change any configuration? (y/n)"
            read -r change
        fi

        if [ "$change" = "y" ]; then
            # Call the function to request update with key verification
            request_update

            # If EXIT_CONFIG is "s", exit the main loop
            if [ "$EXIT_CONFIG" = "y" ]; then
                echo_t "Exiting configuration mode..."
                EXIT_CONFIG="n"  # Reset the exit signal for next use
                break
            fi

            # Reload the configurations after the update
            load_config
        else
            SCRIPT_PAUSED="n"
            break
        fi

        # Interval before restarting the loop
        sleep 30
    done
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
