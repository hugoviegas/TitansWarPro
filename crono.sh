
# shellcheck disable=SC2154
func_crono () {
    HOUR="$(date +%H)"
    if [ "$HOUR" = 00 ]; then HOUR=0; fi
    if [ "$HOUR" = 01 ]; then HOUR=1; fi
    if [ "$HOUR" = 02 ]; then HOUR=2; fi
    if [ "$HOUR" = 03 ]; then HOUR=3; fi
    if [ "$HOUR" = 04 ]; then HOUR=4; fi
    if [ "$HOUR" = 05 ]; then HOUR=5; fi
    if [ "$HOUR" = 06 ]; then HOUR=6; fi
    if [ "$HOUR" = 07 ]; then HOUR=7; fi
    if [ "$HOUR" = 08 ]; then HOUR=8; fi
    if [ "$HOUR" = 09 ]; then HOUR=9; fi
    MIN="$(date +%M)"
    if [ "$MIN" = 00 ]; then MIN=0; fi
    if [ "$MIN" = 01 ]; then MIN=1; fi
    if [ "$MIN" = 02 ]; then MIN=2; fi
    if [ "$MIN" = 03 ]; then MIN=3; fi
    if [ "$MIN" = 04 ]; then MIN=4; fi
    if [ "$MIN" = 05 ]; then MIN=5; fi
    if [ "$MIN" = 06 ]; then MIN=6; fi
    if [ "$MIN" = 07 ]; then MIN=7; fi
    if [ "$MIN" = 08 ]; then MIN=8; fi
    if [ "$MIN" = 09 ]; then MIN=9; fi
    printf " \033[02m$URL ⏰$HOUR:$MIN${COLOR_RESET}\n"
}

func_cat () {
    func_crono

    if [ "$HOUR" -lt 6 ] || [ "$HOUR" -ge 18 ]; then
    printf "${GOLD_BLACK}"
    else
    printf "${CYAN_BLACK}"
    fi

    cat $TMP/msg_file
    printf "${WHITE_BLACK}"

    list() {
        printf "\n"
        # List functions defined in scripts
        grep -o -E '[[:alpha:]]+?[_]?[[:alpha:]]+?[ ]?\() \{' ~/twm/*.sh | awk -F\: '{ print $2 }' | awk -F \( '{ print $1 }'
        read -r -t 30  # Wait for user input for 5 seconds
    }
    
    while true; do
       
        echo -e "\033[02m$(translate_and_cache "$LANGUAGE" "No battles now, waiting ${i}s")${COLOR_RESET}"
        echo -e "${WHITEb_BLACK}$(translate_and_cache "$LANGUAGE" "Enter a command or for more info enter:") list${COLOR_RESET}"

        read -t "$i" cmd  # Read user command with a timeout

        if [ "$cmd" = " " ]; then
            break  # Exit loop if only space is entered
        fi

        printf "\n"
        
        # Lista de comandos que não interrompem o loop
        commands_no_break=("config" "requer_func")
        
        # Executa o comando
        $cmd

        # Checa se o comando está na lista de comandos que não requerem break
        if [[ " ${commands_no_break[*]} " =~  ${cmd}  ]]; then
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
            arena_duel  # Start arena duel
            coliseum_start  # Start coliseum activities
            reset; clear  # Clear the terminal screen
            i=60  # Set wait time to 60 seconds
            func_cat  # Call func_cat to display information
        fi
    fi

    # Check if the current minute is between 25 and 29 inclusive
    if [ "$MIN" -ge 25 ] && [ "$MIN" -le 29 ]; then
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
    specialEvent     # Check the current Event
    #clanQuests       # Check the clan missions opened
    messages_info    # Display messages information 
    func_crono       # Display current time again 
    func_sleep       # Call sleep function to manage timing 
}
