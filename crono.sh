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
    func_crono

    # Reset all attributes before content — ensures dim mode from func_crono doesn't bleed
    printf "\033[0m"

    # Read file without forking cat — bash $(<file) reads directly, no subprocess
    [[ -s "$TMP/msg_file" ]] && printf '%s\n' "$(<"$TMP/msg_file")"
    printf "\033[0m"

    info() {
        printf "\n"
        # List functions defined in scripts
        grep -o -E '[[:alpha:]]+?[_]?[[:alpha:]]+?[ ]?\() \{' ~/twm/*.sh | awk -F\: '{ print $2 }' | awk -F \( '{ print $1 }'
        read -r -t 30  # Wait for user input for 5 seconds
    }

    local cmd_file="${ACCOUNT_ROOT:-$HOME/twm}/cmd_file"

    # Guard: ensure $i is a positive integer — prevents infinite CPU spin if unset
    [[ "$i" =~ ^[0-9]+$ ]] && [ "$i" -gt 0 ] || i=60

    while true; do

        # Check for a queued command written by the monitor
        if [ -s "$cmd_file" ]; then
            cmd=$(cat "$cmd_file")
            : > "$cmd_file"
            echo_t "Running command: $cmd" "\033[02m" "${COLOR_RESET}"
        else
            # Show prompts once per wait interval (not every second)
            if [ "$i" != "$_last_i" ]; then
                echo_t "No battles now, waiting ${i}s" "\033[02m" "${COLOR_RESET}"
                echo_t "Enter a command or for more info enter:" "${WHITE_BLACK}" "info or config${COLOR_RESET}"
                _last_i="$i"
            fi

            # Always use read with timeout:
            # - Interactive terminal: returns immediately when user types + presses Enter
            # - Background (stdin=/dev/null): times out quickly, then checks cmd_file
            # No busy-wait because outer loop in twm.sh has `sleep 1s` floor
            read -r -t "$i" cmd || cmd=""
        fi

        if [ "$cmd" = " " ]; then
            break  # Exit loop if only space is entered
        fi

        printf "\n"

        # Lista de comandos que não interrompem o loop
        commands_no_break=("config" "requer_func")

        # Executa o comando
        $cmd

        # Checa se o comando está na lista de comandos que não requerem break
        # shellcheck disable=SC2076
        # shellcheck disable=SC2199
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
    # Update time using bash printf builtin — no date subprocess fork
    # (HOUR and MIN may already be set by twm_play's case; refresh them here)
    local _d
    printf -v _d '%(%d)T' -1
    # Check if it's the first day of the month
    if [ "$((10#$_d))" -eq 1 ]; then
        # Check if the current hour is between 0 and 8 (inclusive)
        if [ "$HOUR" -lt 9 ]; then  # This covers hours 00 to 08
            coliseum_start  # Start coliseum activities
            clear  # Clear screen for coliseum
            i=60  # Set wait time to 60 seconds
            func_cat  # Call func_cat to display information
            return
        fi
    fi

    # Check if the current minute is between 29 and 30 (near event time)
    if [ "$MIN" -ge 29 ] && [ "$MIN" -le 30 ]; then
        clear  # Clear screen before event
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