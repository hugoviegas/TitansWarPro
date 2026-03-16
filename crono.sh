# shellcheck disable=SC2154
# shellcheck disable=SC2317
func_crono() {
    # Use bash printf builtin for time — no date/sed subprocess forks
    local h m _time_str
    printf -v h '%(%H)T' -1
    printf -v m '%(%M)T' -1
    # Set global HOUR/MIN as plain integers (no leading zeros) for func_sleep arithmetic
    HOUR=$((10#$h))
    MIN=$((10#$m))

    # Only update display when the minute actually changes.
    # This prevents the clock from printing a NEW LINE every ~61s cycle.
    _time_str="${h}:${m}"
    [ "$_time_str" = "$_last_displayed_min" ] && return
    _last_displayed_min="$_time_str"

    # Background mode (multi_runner / log file): do not print to stdout.
    # Log files should stay clean; scheduling is handled by the inner sleep loop.
    [ -t 1 ] || return

    if [ "$_display_initialized" -eq 1 ]; then
        # Idle screen is set up: update the clock line in-place.
        # \0337 = save cursor | \033[1;1H = row 1 col 1 | \033[2K = erase line
        # \0338 = restore cursor — user stays at original position (no scroll/jump)
        printf "\0337\033[1;1H\033[2K \033[02m%s ⏰ %s:%s\033[0m\0338" \
            "$URL" "$h" "$m"
    else
        # Initial display (screen was just cleared, cursor is at top-left).
        # Print normally so the clock occupies line 1.
        printf " \033[02m%s ⏰ %s:%s\033[0m\n" "$URL" "$h" "$m"
    fi
}

# Global flag to track if we've already shown idle status (reduce spam)
declare -g _last_i=-1
# Global cache for msg_file display deduplication
declare -g _last_msg_hash=""
declare -g _last_display_epoch=0
# Global clock in-place update state
declare -g _last_displayed_min=""   # last HH:MM printed — skip if unchanged
declare -g _display_initialized=0   # 1 = idle layout active, clock is on line 1

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
    # shellcheck disable=SC2329
    _interrupt_func_cat() {
        printf_t "Stopping macro..." "${RED_BLACK}" "${COLOR_RESET}\n"
        exit 0
    }
    # Save current trap before overriding so we can restore it when func_cat exits.
    # Without this, twm_global_cleanup (which kills background w3m jobs) would never
    # run because func_cat permanently replaces the INT/TERM handler for the session.
    local _prev_trap
    _prev_trap=$(trap -p INT | sed "s/trap -- '//;s/' INT//")
    trap '_interrupt_func_cat' INT TERM

    # Compute msg_file hash to detect content changes (avoids unconditional reprints)
    local _now_epoch _msg_hash
    printf -v _now_epoch '%(%s)T' -1
    if [[ -s "$TMP/msg_file" ]]; then
        _msg_hash=$(sha256sum "$TMP/msg_file" 2>/dev/null | awk '{print $1}')
    else
        _msg_hash=""
    fi

    if [ "$_msg_hash" != "$_last_msg_hash" ] || [ "$(( _now_epoch - _last_display_epoch ))" -ge 300 ]; then
        # Content changed or 5+ minutes elapsed: full screen repaint.
        if [ -t 1 ]; then
            printf "\033[2J\033[H"  # clear entire screen, cursor to top-left
            _display_initialized=0  # force func_crono to print normally (not ANSI-update)
        fi
        _last_displayed_min=""       # force clock reprint even if minute is same
        func_crono                   # print clock on line 1 (initial layout)
        printf "\033[0m"
        # Print player info below the clock line
        [[ -s "$TMP/msg_file" ]] && printf '%s\n' "$(<"$TMP/msg_file")"
        printf "\033[0m"
        _last_msg_hash="$_msg_hash"
        _last_display_epoch="$_now_epoch"
        _display_initialized=1       # idle layout established: clock on line 1, content below
    else
        # Content unchanged: only update the clock line if the minute changed.
        # func_crono handles the ANSI in-place update of line 1 internally.
        func_crono
        printf "\033[0m"
    fi

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
                # Interactive: user can type commands, but also check for time changes every second
                # This ensures scheduled events don't get missed if the minute changes during idle wait
                local _read_count=0
                cmd=""
                while [ $_read_count -lt "$i" ]; do
                    # Check if time changed (hour/minute) — set flag to exit func_cat
                    printf -v _current_time '%(%H:%M)T' -1
                    if [ "$_current_time" != "$_last_time_check" ]; then
                        _schedule_changed=1  # Signal to exit main while loop
                        break
                    fi

                    # Try to read with 1-second timeout (fast response to user input)
                    if read -r -t 1 cmd 2>/dev/null; then
                        # User entered a command — break to process it
                        break
                    fi
                    cmd=""  # Clear cmd on timeout
                    _read_count=$((++_read_count))
                done
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
            # Use per-account error file to avoid race condition in multi-account mode
            local _cmd_err="${TMP:-/tmp}/cmd_error.txt"
            # Try to execute the command; show error if it fails
            if ! $cmd 2>"$_cmd_err"; then
                # Command failed — show error message
                if [ -s "$_cmd_err" ]; then
                    printf "\033[01;31mError executing '${cmd}': $(head -1 "$_cmd_err")\033[0m\n"
                else
                    printf "\033[01;31mCommand not found or failed: ${cmd}\033[0m\n"
                    printf "\033[02mAvailable: config, requer_func, stop\033[0m\n"
                fi
                rm -f "$_cmd_err"
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

    # Restore original trap so twm_global_cleanup remains active for the rest of the session.
    # This ensures background w3m jobs get killed properly when signals are received.
    if [ -n "$_prev_trap" ]; then
        trap "$_prev_trap" INT TERM
    else
        trap - INT TERM
    fi
}

func_sleep() {
    # Always refresh HOUR/MIN here — they may be stale if a long event (battle, altars, etc.)
    # ran between the last twm_play call and this func_sleep call
    local _h _m _d
    printf -v _h '%(%H)T' -1
    printf -v _m '%(%M)T' -1
    printf -v _d '%(%d)T' -1
    HOUR=$((10#$_h))
    MIN=$((10#$_m))
    # Check if it's the first day of the month
    if [ "$((10#$_d))" -eq 1 ]; then
        # Check if the current hour is between 0 and 8 (inclusive)
        if [ "$HOUR" -lt 9 ]; then  # This covers hours 00 to 08
            coliseum_start  # Start coliseum activities
            i=60  # Set wait time to 60 seconds
            func_cat  # Call func_cat to display information
            return
        fi
    fi

    # Check if the current minute is between 29 and 30 (near event time)
    if [ "$MIN" -ge 29 ] && [ "$MIN" -le 30 ]; then
        i=15  # Shorter wait time (15s) when approaching event
        func_cat
    else
        # Normal idle mode: minimal re-rendering to save CPU/memory
        i=60
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
    #check_missions           # Check for missions
    check_rewards            # Check for rewards
    do_missions              # Execute available missions

    if [ "${FUNC_auto_events:-y}" = "y" ]; then
        specialEvent
    fi

    if [ "${FUNC_clan_missions:-y}" = "y" ]; then
        clanQuests
    fi

    messages_info            # Display messages information
    func_sleep               # Call sleep function to manage timing
}