func_crono() {
    # Get the current hour and minute
    HOUR=$(date +%H)
    MIN=$(date +%M)

    # Normalize hour and minute values to integers
    HOUR=${HOUR#0}  # Remove leading zero from hour
    MIN=${MIN#0}    # Remove leading zero from minute

    # Display the current URL and time
    echo -e " \033[02m$URL ⏰ $(date +%H):$(date +%M)${COLOR_RESET}"
}

func_cat() {
    func_crono  # Call func_crono to display the current time

    # Set color based on the time of day
    if [ "$HOUR" -lt 6 ] || [ "$HOUR" -ge 18 ]; then
        printf "${BLUE_BLACK}"  # Night mode
    else
        printf "${GOLD_BLACK}"   # Day mode
    fi

    cat "$TMP/msg_file"  # Display the contents of msg_file
    printf "${WHITE_BLACK}"

    list() {
        printf "\n"
        # List functions defined in scripts
        grep -o -E '[[:alpha:]]+?[_]?[[:alpha:]]+?[ ]?\() \{' ~/twm/*.sh | awk -F\: '{ print $2 }' | awk -F\( '{ print $1 }'
        read -t 5  # Wait for user input for 5 seconds
    }

    while true; do
        printf " \033[02mNo battles now, waiting ${i}s${COLOR_RESET}\n${WHITEb_BLACK}Enter a command or type 'list':${COLOR_RESET} \n"
        read -t "$i" cmd  # Read user command with a timeout

        if [ "$cmd" = " " ]; then
            break  # Exit loop if only space is entered
        fi

        printf "\n"
        $cmd  # Execute the command entered by the user
        sleep 0.5s  # Brief pause before next iteration
        break  # Exit after executing the command once
    done
}

func_sleep() {
    # Check if it's the first day of the month
    if [ "$(date +%d)" -eq 01 ]; then
        # Check if the current hour is between 0 and 8 (inclusive)
        if [ "$(date +%H)" -lt 9 ]; then  # This covers hours 00 to 08
            arena_duel  # Start arena duel
            coliseum_start  # Start coliseum activities
            reset; clear  # Clear the terminal screen
            i=60  # Set wait time to 60 seconds
            func_cat  # Call func_cat to display information
        fi
    fi

    # Check if the current minute is between 25 and 29 inclusive
    if [ "$(date +%M)" -ge 25 ] && [ "$(date +%M)" -le 29 ]; then
        reset; clear  # Clear the terminal screen
        i=10  # Set wait time to 10 seconds
        func_cat  # Call func_cat to display information
    else
        reset; clear  # Clear the terminal screen for any other minute value
        i=45  # Set wait time to 45 seconds
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
    messages_info    # Display messages information 
    func_crono       # Display current time again 
    func_sleep       # Call sleep function to manage timing 
}
