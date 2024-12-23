
# shellcheck disable=SC2154
func_crono() {
    # Get current hour and minute, removing leading zeros
    HOUR=$(date +%H | sed 's/^0//')
    MIN=$(date +%M | sed 's/^0//')

    # Format and print the time
    echo -e " \033[02m$URL ⏰ $(date +%H):$(date +%M)${COLOR_RESET}"
}

func_cat() {
    func_crono

    # Set color based on time of day
    if (( HOUR < 6 || HOUR >= 18 )); then
        printf "${BLUE_BLACK}"
    else
        printf "${GOLD_BLACK} "
    fi

    cat "$TMP/msg_file"
    printf "${WHITE_BLACK}"
 
    info() {
        printf "\n"
        # List functions defined in scripts
        grep -o -E '[[:alpha:]]+?[_]?[[:alpha:]]+?[ ]?\() \{' ~/twm/*.sh | awk -F\: '{ print $2 }' | awk -F \( '{ print $1 }'
        read -r -t 30  # Wait for user input for 5 seconds
    }
    
    while true; do
       
        echo_t "No battles now, waiting ${i}s" "\033[02m" "${COLOR_RESET}"
        echo_t "Enter a command or for more info enter:" "${WHITEb_BLACK}" "info${COLOR_RESET}"

        read -r -t "$i" cmd  # Read user command with a timeout

        if [ "$cmd" = " " ]; then
            break  # Exit loop if only space is entered
        fi

        printf "\n"
        
        # Lista de comandos que não interrompem o loop
        commands_no_break=("config" "requer_func")
        
        # Executa o comando
        $cmd

        # Checa se o comando está na lista de comandos que não requerem break
        if [[ " ${commands_no_break[@]} " =~ " ${cmd} " ]]; then
            # Pausa breve antes de continuar o loop
            sleep 0.5s
            continue
        else
            break  # Sai do loop para comandos que não estão na lista
        fi
    done
}

func_sleep() {
    # Check if it's the first day of the month
    if [ "$(date +%d)" -eq 01 ]; then
        # Check if the current hour is between 0 and 8 (inclusive)
        if [ "$HOUR" -lt 9 ]; then  # This covers hours 00 to 08
            #arena_duel  # Start arena duel
            coliseum_start  # Start coliseum activities
            reset; clear  # Clear the terminal screen
            i=60  # Set wait time to 60 seconds
            func_cat  # Call func_cat to display information
        fi
    fi

    # Check if the current minute is between 25 and 29 inclusive
    if [ "$MIN" -ge 29 ] && [ "$MIN" -le 30 ]; then
        reset; clear  # Clear the terminal screen
        i=15  # Set wait time to 15 seconds
        func_cat  # Call func_cat to display information
    else
        reset; clear  # Clear the terminal screen for any other minute value
        i=60  # Set wait time to 60 seconds
        func_cat  # Call func_cat to display information
    fi
}

start() {
    arena_duel       # Start arena duel function
    career_func      # Call career-related function
    cave_routine     # Execute cave routine function 
    func_trade       # Call trading function 
    campaign_func    # Start campaign function 
    clanDungeon      # Execute clan dungeon function 
    clan_statue      # Check the clan statue
    check_missions   # Check for missions 
    check_rewards    # Check for rewards
    specialEvent     # Check the current Event
    clanQuests       # Check the clan missions opened
    messages_info    # Display messages information 
    func_crono       # Display current time again 
    func_sleep       # Call sleep function to manage timing 
}
