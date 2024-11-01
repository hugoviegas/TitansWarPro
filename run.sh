twm_play() {
    echo "$RUN" > "$HOME/twm/runmode_file"  # Save the run mode to a file
    # Function to restart the twm script if it is running
    restart_script() {
        # shellcheck disable=SC2317
        if [ "$RUN" != '-boot' ]; then
            # Get the PID of the running twm script
            pidf=$(ps ax -o pid=,args= | grep "sh.*twm/twm.sh" | grep -v 'grep' | head -n 1 | grep -o -E '([0-9]{3,5})')
            
            # Loop until there are no more PIDs found
            until [ -z "$pidf" ]; do
                kill -9 $pidf 2> /dev/null  # Forcefully kill the process
                pidf=$(ps ax -o pid=,args= | grep "sh.*twm/twm.sh" | grep -v 'grep' | head -n 1 | grep -o -E '([0-9]{3,5})')
                sleep 1s  # Wait for a second before checking again
            done
        fi
    }

    # Check if the CLD file exists; if not, call clan_id function
    if [ ! -s "$TMP/CLD" ]; then
        clan_id
    fi

    # Determine game time actions based on current time
    case $(date +%H:%M) in
        # No events time with coliseum (00:55 to 03:55)
        (00:[0-5]5|01:[0-5]5|02:[0-5]5|03:[0-5]5)
            coliseum_fight
            ;;
        # Scheduled events every half hour during the day
        (00:00|00:30|01:00|01:30|02:00|02:30|03:00|03:30|04:00|04:30|05:00|05:30|06:01|06:30|07:00|07:30|08:00|08:30|09:00|09:30|11:30|12:00|13:00|13:30|14:30|15:30|17:00|17:30|18:00|18:30|19:30|20:00|20:30|23:00|23:30)
            start
            ;;
        
        # Valley of the Immortals (09:55, 15:55, 21:55)
        (09:5[5-9]|15:5[5-9]|21:5[5-9])
            undying_start
            start
            ;;
        
        # Flag Fight (10:15 to 16:15)
        (10:1[0-4]|16:1[0-4])
            flagfight_start            
            ;;
        
        # Clan coliseum (10:28 to 15:58)
        (10:2[8-9]|14:5[8-9])
            if [ -n "$CLD" ]; then
                clancoliseum_start
            fi
            start
            ;;
        
        # Clan tournament (11 to 19)
        (10:5[5-9]|18:5[5-9])
            if [ -n "$CLD" ]; then
                clanfight_start
            fi
            start
            ;;
        
        # King of the Immortals (12:30, 16:30, 22:30)
        (12:2[5-9]|16:2[5-9]|22:2[5-9])
            king_start
            start
            ;;
        
        # Ancient Altars (13 to 21)
        (13:5[5-9]|20:5[5-9])
            if [ -n "$CLD" ]; then
                altars_start
            fi
            start
            ;;
        
        # Clan damage event at 21:30; additional logic can be added here if needed.
        (21:30)
            # _clandmgfight  # Uncomment if needed for clan damage fight logic.
            start
            ;;
        
        (*)
            # If running in coliseum mode, execute relevant functions.
            if echo "$RUN" | grep -q -E '[-]cl'; then
                echo -e "Running in coliseum mode: $RUN\n"
                sleep 5s  # Pause before executing arena duel.
                arena_duel
                coliseum_start
                messages_info  # Call to gather message information.
            fi
            
            func_sleep   # Call sleep function.
            func_crono   # Call cron function.
            ;;
    esac

}
