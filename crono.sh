# shellcheck disable=SC2154
# shellcheck disable=SC2317
func_crono() {
    # Use bash printf builtin for time — no date/sed subprocess forks
    local h m
    printf -v h '%(%H)T' -1
    printf -v m '%(%M)T' -1
    # Set global HOUR/MIN as plain integers (no leading zeros) for func_sleep arithmetic
    HOUR=$((10#$h))
    MIN=$((10#$m))
    printf " \033[02m%s ⏰ %s:%s\033[0m\n" "$URL" "$h" "$m"
}

# Global flag to track if we've already shown idle status (reduce spam)
declare -g _last_i=-1

func_cat() {
    # Idle loop handler. Waits for user commands or events.
    #
    # Two modes:
    #  - INTERACTIVE (play.sh A1): stdin is a real terminal, user types commands
    #  - BACKGROUND (multi_runner.sh): stdin is /dev/null, commands via twm_monitor.sh [C]
    #
    # Available commands: config (change config), requer_func (reconfigure), stop|exit|parar|q|x (quit)
    #
    # Important: This function only executes during IDLE time. When a game event
    # is running (arena, cave, coliseum, etc), you cannot send commands until
    # the event completes and returns to idle.
    #
    # Signal handler for graceful interrupt of sleep/read
    _interrupt_func_cat() {
        printf "\033[01;31m\n$(translate "Stopping macro")...\033[0m\n"
        exit 0
    }
    trap '_interrupt_func_cat' INT TERM

    func_crono

    # Reset all attributes before content — ensures dim mode from func_crono doesn't bleed
    printf "\033[0m"

    # Only clear screen if in fully interactive mode (connected to real terminal on both stdin and stdout)
    # If running in background (stdout redirected to log), don't clear to preserve monitor header
    if [ -t 1 ]; then
        # stdout is terminal → interactive play.sh, safe to clear
        printf "\033[2J\033[H"
    fi

    # Read file without forking cat — bash $(<file) reads directly, no subprocess
    [[ -s "$TMP/msg_file" ]] && printf '%s\n' "$(<"$TMP/msg_file")"
    printf "\033[0m"

    local cmd_file="${ACCOUNT_ROOT:-$HOME/twm}/cmd_file"

    # Guard: ensure $i is a positive integer — prevents infinite CPU spin if unset
    [[ "$i" =~ ^[0-9]+$ ]] && [ "$i" -gt 0 ] || i=60

    # Detect interactive vs background mode
    # [ -t 0 ] = true if fd 0 (stdin) is connected to a terminal
    local _interactive=0
    [ -t 0 ] && _interactive=1

    # Track last time check to detect event transitions during idle
    local _last_time_check="${HOUR}:${MIN}"

    # Flag to exit when hour/minute changes (schedule time reached)
    local _schedule_changed=0

    while true; do

        # If schedule changed (hour/minute), exit func_cat to return to main loop
        if [ $_schedule_changed -eq 1 ]; then
            break
        fi

        # Check for a queued command written by the monitor
        if [ -s "$cmd_file" ]; then
            cmd=$(cat "$cmd_file")
            : > "$cmd_file"
            echo_t "Running command: $cmd" "${GRAY_BLACK}" "${COLOR_RESET}"
        else
            # Show prompts once per wait interval (not every second)
            if [ "$i" != "$_last_i" ]; then
                echo_t " No battles now, waiting ${i}s" "${GRAY_BLACK}" "${COLOR_RESET}"
                if [ "$_interactive" -eq 1 ]; then
                    # Interactive mode: user can type directly
                    echo_t "Type commands start, config, stop Then press ENTER"
                else
                    # Background mode: use monitor to send commands
                    echo_t " Use [C] to send: start, config\n"
                fi
                _last_i="$i"
            fi

            # Two paths:
            # - Interactive terminal (stdin is real): read blocks waiting for user
            # - Background mode (stdin=/dev/null): check cmd_file frequently instead of long sleep
            if [ "$_interactive" -eq 1 ]; then
                # Interactive: user can type commands, returns immediately on Enter
                read -r -t "$i" cmd || cmd=""
            else
                # Background mode: sleep in short intervals and check cmd_file frequently
                # This allows commands sent by monitor to execute within ~1 second instead of up to 60s
                # CRITICAL: Also watch for time changes (hour/minute) to detect scheduled events!
                local _sleep_count=0
                while [ $_sleep_count -lt "$i" ]; do
                    # Check if a command was queued
                    if [ -s "$cmd_file" ]; then
                        cmd=$(cat "$cmd_file")
                        : > "$cmd_file"
                        break
                    fi

                    # Check if time changed (new event may be due) — set flag to exit func_cat
                    printf -v _current_time '%(%H:%M)T' -1
                    if [ "$_current_time" != "$_last_time_check" ]; then
                        cmd=""
                        _schedule_changed=1  # Signal to exit main while loop when we break here
                        break
                    fi

                    # Sleep 1 second, then loop to check again
                    sleep 1s
                    _sleep_count=$((++_sleep_count))
                done

                # If loop completed without break, cmd is already empty
                [ -z "$cmd" ] && cmd=""
            fi
        fi

        # Handle stop/exit commands (any mode)
        case "$cmd" in
            stop|exit|parar|q|x)
                printf_t "Stopping macro...\n" "${RED_BLACK}" "${COLOR_RESET}"
                exit 99  # Exit code 99 signals intentional stop (not a crash/restart)
                ;;
            " ")
                # Single space = exit func_cat (existing behavior)
                break
                ;;
            "")
                # Empty command (timeout in interactive, or normal idle after sleep in background)
                # If schedule changed, break outer while loop
                if [ $_schedule_changed -eq 1 ]; then
                    break  # CRITICAL: Exit func_cat when schedule time is reached
                fi
                # Don't execute anything, just continue waiting
                continue
                ;;
        esac

        printf "\n"

        # Execute user command — with error checking
        commands_no_break=("config" "requer_func")

        # Only execute if cmd is not empty
        if [ -n "$cmd" ]; then
            # Try to execute the command; show error if it fails
            if ! $cmd 2>/tmp/cmd_error.txt; then
                # Command failed — show error message
                if [ -s /tmp/cmd_error.txt ]; then
                    printf "\033[01;31mError executing '${cmd}': $(cat /tmp/cmd_error.txt | head -1)\033[0m\n"
                else
                    printf "\033[01;31mCommand not found or failed: ${cmd}\033[0m\n"
                    printf "\033[02mAvailable: config, requer_func, stop\033[0m\n"
                fi
                rm -f /tmp/cmd_error.txt
            fi
        fi

        # Check if command should continue loop or break
        # shellcheck disable=SC2076
        # shellcheck disable=SC2199
        if [[ " ${commands_no_break[@]} " =~ " ${cmd} " ]]; then
            # Pausa breve antes de continuar o loop
            sleep 0.5s
            continue
        else
            break  # Exit func_cat for other commands
        fi
    done
}

func_sleep() {
    # Update time using bash printf builtin — no date subprocess fork
    # (HOUR and MIN may already be set by twm_play's case; refresh them here)
    local _d
    printf -v _d '%(%d)T' -1
    # Check if it's the first day of the month
    if [ "$((10#$_d))" -eq 1 ]; then
        # Check if the current hour is between 0 and 8 (inclusive)
        if [ "$HOUR" -lt 9 ]; then  # This covers hours 00 to 08
            coliseum_start  # Start coliseum activities
            [ -t 1 ] && clear  # Clear screen only if interactive (not background/monitor)
            i=60  # Set wait time to 60 seconds
            func_cat  # Call func_cat to display information
            return
        fi
    fi

    # Check if the current minute is between 29 and 30 (near event time)
    if [ "$MIN" -ge 29 ] && [ "$MIN" -le 30 ]; then
        [ -t 1 ] && clear  # Clear screen only if interactive (not background/monitor)
        i=15  # Shorter wait time (15s) when approaching event
        func_cat
    else
        # Normal idle mode: minimal re-rendering to save CPU/memory
        i=60
        # Don't clear screen during idle — just show status once and wait
        func_cat
    fi
}

start() {
    load_config              # Load configuration file

    pause_missions_weekend   # Pause or reactivate mission collection on weekends

    arena_duel               # Start arena duel function
    career_func              # Call career-related function
    cave_routine             # Execute cave routine function 
    func_trade               # Call trading function 
    campaign_func            # Start campaign function 
    clanDungeon              # Execute clan dungeon function 
    clan_statue              # Check the clan statue
    check_missions           # Check for missions 
    check_rewards            # Check for rewards

    if [ "${FUNC_auto_events:-y}" = "y" ]; then
        specialEvent
    fi

    if [ "${FUNC_clan_missions:-y}" = "y" ]; then
        clanQuests
    fi

    messages_info            # Display messages information 
    func_crono               # Display current time again 
    func_sleep               # Call sleep function to manage timing 
}