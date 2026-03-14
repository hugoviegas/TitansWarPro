#!/bin/bash
# twm_monitor.sh — Live account log monitor
#
# Refresh strategy (matches macro cadence):
#   - Renders immediately when log grows (battles: rapid; idle: ~60s natural pause)
#   - Forces a status check every 60s even when log is quiet
#   - Follow mode: tail -f live stream, Ctrl+C returns to monitor
shopt -s extglob

BASE_DIR="${HOME}/twm"
ACCOUNTS_DIR="${BASE_DIR}/accounts"
INDEX_FILE="${ACCOUNTS_DIR}/index.json"
PID_DIR="${ACCOUNTS_DIR}/.pids"

# ── global state ──────────────────────────────────────────────────────────────
account_ids=()
account_aliases=()
account_count=0
tty_state=""
current_index=1
force_render=1
TERM_COLS=80
TERM_LINES=24
_hline_cache=""
_hline_cols=0

# ── helpers ───────────────────────────────────────────────────────────────────
fatal()   { printf "twm_monitor: %s\n" "$*" >&2; exit 1; }
require_jq() { command -v jq >/dev/null 2>&1 || fatal "jq is required"; }

load_accounts() {
  require_jq
  [ -f "$INDEX_FILE" ] || fatal "No accounts found — run twm_setup.sh first"
  account_ids=(); account_aliases=(); account_count=0
  while IFS=$'\t' read -r id alias; do
    account_count=$((account_count + 1))
    account_ids[$account_count]="$id"
    account_aliases[$account_count]="$alias"
  done < <(jq -r '.accounts[] | select((.active // true) == true) | [.id, (.alias // .id)] | @tsv' "$INDEX_FILE")
}

get_status() {
  local id="$1"
  local pid_file="${PID_DIR}/${id}.pid"
  local run_file="${ACCOUNTS_DIR}/${id}/runmode_file"
  local state="STOPPED" pid="-" mode="-"
  if [ -f "$run_file" ]; then
    mode=$(tr -d '\r\n' < "$run_file" 2>/dev/null)
    [ -n "$mode" ] || mode="-"
  fi
  if [ -f "$pid_file" ]; then
    pid=$(cat "$pid_file" 2>/dev/null || echo "-")
    kill -0 "$pid" 2>/dev/null && state="RUNNING" || state="DEAD"
  fi
  printf '%s|%s|%s' "$state" "$pid" "$mode"
}

update_term_size() {
  TERM_COLS=$(tput cols 2>/dev/null || echo 80)
  TERM_LINES=$(tput lines 2>/dev/null || echo 24)
}

hline() {
  # Rebuild cache only when terminal width changes (no seq subprocess)
  if [ "$TERM_COLS" != "$_hline_cols" ]; then
    local i=0 line=""
    for ((i=0; i<TERM_COLS; i++)); do line+="─"; done
    _hline_cache=$'\033[1;36m'"${line}"$'\033[0m'
    _hline_cols="$TERM_COLS"
  fi
  printf '%s\n' "$_hline_cache"
}

state_fmt() {   # usage: state_fmt RUNNING  → outputs color+dot+state+reset
  local s="$1"
  case "$s" in
    RUNNING) printf '\033[1;32m● %s\033[0m' "$s" ;;
    DEAD)    printf '\033[1;33m◉ %s\033[0m' "$s" ;;
    *)       printf '\033[1;31m○ %s\033[0m' "$s" ;;
  esac
}

# ── terminal mode helpers ─────────────────────────────────────────────────────
_exit_monitor() {
  stty "$tty_state" 2>/dev/null
  printf '\033[?25h'   # show cursor
  clear
  exit 0
}

_restore_raw_mode() {
  stty -icanon -echo min 0 time 0 2>/dev/null
  printf '\033[?25l'   # hide cursor
  trap '_exit_monitor' EXIT INT TERM
  force_render=1
}

# ── drawing ───────────────────────────────────────────────────────────────────
draw_top_bar() {
  printf '\033[H'   # cursor to top-left (no erase — done by render's \033[J)
  hline
  printf ' '
  local i
  for ((i=1; i<=account_count; i++)); do
    local id="${account_ids[$i]}"
    local alias="${account_aliases[$i]}"
    local info; info=$(get_status "$id")
    local state; state="${info%%|*}"
    local mode;  mode="${info##*|}"

    case "$state" in
      RUNNING) dot='\033[1;32m●\033[0m' ;;
      DEAD)    dot='\033[1;33m◉\033[0m' ;;
      *)       dot='\033[1;31m○\033[0m' ;;
    esac

    # Highlight the currently selected account
    if [ "$i" -eq "$current_index" ]; then
      printf "%b \033[1;37m%-5s\033[0m \033[0;37m%-10s %-6s\033[0m  " \
        "$dot" "$id" "$alias" "$mode"
    else
      printf "%b \033[0;37m%-5s %-10s %-6s\033[0m  " \
        "$dot" "$id" "$alias" "$mode"
    fi
  done
  printf '\n'
  hline
}

draw_account_header() {
  local passed_tail="${1:-}"   # cur_tail already read in main loop — no extra tail fork
  local id="${account_ids[$current_index]}"
  local alias="${account_aliases[$current_index]}"
  local info; info=$(get_status "$id")
  local state; state="${info%%|*}"
  local pid;   pid="${info#*|}"; pid="${pid%|*}"
  local mode;  mode="${info##*|}"
  local sfmt;  sfmt=$(state_fmt "$state")

  # Extract timestamp from the already-read tail line (no extra subprocess)
  local last_ts=""
  if [ -n "$passed_tail" ] && [[ "$passed_tail" =~ ^([0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2}) ]]; then
    last_ts=" | last: \033[0;37m${BASH_REMATCH[1]}\033[0m"
  fi

  printf " \033[1;33m▶ %s\033[0m \033[0;37m(%s)\033[0m  %b  pid:\033[1;33m%s\033[0m  mode:\033[1;33m%s\033[0m%b  \033[0;36m[%d/%d]\033[0m\n" \
    "$alias" "$id" "$sfmt" "$pid" "$mode" "$last_ts" "$current_index" "$account_count"
  printf " \033[0;36m [N]ext [P]rev [F]ollow [L]ist [C]md [R]efresh [Q]uit  [1-9] jump\033[0m\n"
  hline
}

draw_log() {
  local id="${account_ids[$current_index]}"
  local log_file="${ACCOUNTS_DIR}/${id}/logs/twm.log"
  # Header: 3 lines (top bar) + 3 lines (account header) = 6 fixed lines
  local log_lines=$((TERM_LINES - 6))
  [ "$log_lines" -lt 4 ] && log_lines=4

  # Ensure we don't overflow terminal height - leave space for potential prompts
  log_lines=$((log_lines - 1))

  if [ -f "$log_file" ]; then
    tail -n "$log_lines" "$log_file" 2>/dev/null | cat
  else
    printf '\033[0;33m  Waiting for log file: %s\033[0m\n' "$log_file"
  fi
}

render() {
  local cur_tail="${1:-}"
  update_term_size
  clear  # Explicit clear to prevent terminal pollution
  printf '\033[2J\033[H'   # clear entire screen THEN cursor home (correct order)
  draw_top_bar
  draw_account_header "$cur_tail"
  # Use 'cat' instead of 'tail' to avoid substring re-reading when scrolling
  # This reduces visual updates and flickering
  draw_log
}

# ── follow mode (live tail -f with command input) ────────────────────────────────────────────────
follow_mode() {
  local id="${account_ids[$current_index]}"
  local alias="${account_aliases[$current_index]}"
  local log_file="${ACCOUNTS_DIR}/${id}/logs/twm.log"

  # Restore normal terminal for readable streaming output
  stty "$tty_state" 2>/dev/null
  printf '\033[?25h'

  update_term_size
  clear
  hline
  printf " \033[1;33mFOLLOWING LIVE: %s (%s)\033[0m" "$alias" "$id"
  printf "   \033[0;36m[C]=Send Cmd  Ctrl+C=Return\033[0m\n"
  hline

  # Wait for log file to appear
  if [ ! -f "$log_file" ]; then
    printf '\033[0;33m  Waiting for log file to appear...\033[0m\n'
    until [ -f "$log_file" ]; do sleep 1; done
  fi

  # Tail output continuously with more history (50 lines), while checking for [C] input
  tail -n 50 -f "$log_file" 2>/dev/null &
  local tail_pid=$!

  # Override INT to kill tail and return
  trap '
    kill '"$tail_pid"' 2>/dev/null
    _restore_raw_mode
    return
  ' INT

  # Check for [C] input during tail
  while kill -0 "$tail_pid" 2>/dev/null; do
    # Non-blocking input check: timeout after 0.5s
    if read -r -t 0.5 input_char 2>/dev/null; then
      case "$input_char" in
        c|C)
          # User pressed [C] — kill tail and send command
          kill "$tail_pid" 2>/dev/null
          wait "$tail_pid" 2>/dev/null || true
          _restore_raw_mode
          send_command
          return
          ;;
      esac
    fi
  done

  # Tail process died naturally
  _restore_raw_mode
}

# ── list / select account ─────────────────────────────────────────────────────
list_select() {
  stty "$tty_state" 2>/dev/null
  printf '\033[?25h'

  update_term_size
  printf '\033[H\033[J'
  hline
  printf " \033[1;36mSelect Account\033[0m — type number then Enter, or Enter to cancel\n"
  hline

  local i
  for ((i=1; i<=account_count; i++)); do
    local id="${account_ids[$i]}"
    local alias="${account_aliases[$i]}"
    local info; info=$(get_status "$id")
    local state; state="${info%%|*}"
    local pid;   pid="${info#*|}"; pid="${pid%|*}"
    local mode;  mode="${info##*|}"
    local log_file="${ACCOUNTS_DIR}/${id}/logs/twm.log"
    local sfmt;  sfmt=$(state_fmt "$state")
    # Last log line as context
    local last=""
    [ -f "$log_file" ] && last=$(tail -1 "$log_file" 2>/dev/null | cut -c1-"$((TERM_COLS - 5))")

    printf " \033[1;33m%d)\033[0m %-10s %-8s %b  pid:%-8s mode:%s\n" \
      "$i" "$alias" "$id" "$sfmt" "$pid" "$mode"
    [ -n "$last" ] && printf "    \033[0;37m└ %s\033[0m\n" "$last"
  done
  hline
  printf ' Account number (Enter to cancel): '

  local sel=""
  read -r sel

  stty -icanon -echo min 0 time 0 2>/dev/null
  printf '\033[?25l'
  force_render=1

  if [[ "$sel" =~ ^[1-9][0-9]*$ ]] && [ "$sel" -ge 1 ] && [ "$sel" -le "$account_count" ]; then
    current_index="$sel"
  fi
}

# ── send command to account macro ─────────────────────────────────────────────
send_command() {
  stty "$tty_state" 2>/dev/null
  printf '\033[?25h'

  local id="${account_ids[$current_index]}"
  local alias="${account_aliases[$current_index]}"
  local cmd_file="${ACCOUNTS_DIR}/${id}/cmd_file"

  update_term_size
  printf '\033[H\033[J'
  hline
  printf " \033[1;36mSend Command to: \033[1;33m%s \033[0;37m(%s)\033[0m\n" "$alias" "$id"
  printf " \033[0;37mThe command runs on the macro's next idle cycle.\033[0m\n"
  hline
  printf ' Command (Enter to cancel): '

  local cmd=""
  read -r cmd

  if [ -n "$cmd" ]; then
    printf '%s\n' "$cmd" > "$cmd_file"
    printf '\033[1;32m  ✓ Queued: %s\033[0m\n' "$cmd"
    sleep 0.5
  else
    printf '\033[0;33m  Cancelled\033[0m\n'
    sleep 0.5
  fi

  stty -icanon -echo min 0 time 0 2>/dev/null
  printf '\033[?25l'
  force_render=1
}


interactive_monitor() {
  load_accounts
  [ "$account_count" -gt 0 ] || fatal "No active accounts found in $INDEX_FILE"

  tty_state=$(stty -g 2>/dev/null)
  trap '_exit_monitor' EXIT INT TERM
  trap 'update_term_size; force_render=1' WINCH   # handle terminal resize

  stty -icanon -echo min 0 time 0 2>/dev/null
  printf '\033[?25l'

  local last_log_tail=""
  local render_cooldown=0
  local poll_timeout=2    # Wait 2 seconds for keyboard input before checking again
  local idle_iters=0      # Iteration counter (replaces date +%s — no subprocess)
  local status_interval   # Approx 60s: recalculated when poll_timeout changes

  while true; do
    local id="${account_ids[$current_index]}"
    local log_file="${ACCOUNTS_DIR}/${id}/logs/twm.log"

    # Reset state when exiting interactive functions (follow_mode, list_select, send_command)
    # or when first run (force_render already set to 1 at startup)
    if [ "$force_render" -eq 1 ]; then
      last_log_tail=""
      render_cooldown=0
      poll_timeout=0   # Render immediately on force
    fi

    # On normal idle, increase poll timeout to reduce unnecessary cycles
    if [ "$render_cooldown" -gt 0 ] && [ "$poll_timeout" -lt 5 ]; then
      poll_timeout=5   # Longer wait during cooldown
    elif [ "$render_cooldown" -eq 0 ]; then
      poll_timeout=2   # Normal polling speed
    fi

    # Status interval: approx 60s (30 iters × 2s  or  12 iters × 5s)
    status_interval=$(( 60 / (poll_timeout > 0 ? poll_timeout : 1) ))

    # Increment idle counter; force render every ~60s without spawning date
    idle_iters=$((idle_iters + 1))
    if [ "$idle_iters" -ge "$status_interval" ]; then
      idle_iters=0
      force_render=1
    fi

    # Get last line of log — detects meaningful changes (new action/event)
    # Trim trailing whitespace using bash extglob — no sed subprocess
    local cur_tail=""
    if [ -f "$log_file" ]; then
      cur_tail=$(tail -1 "$log_file" 2>/dev/null)
      cur_tail="${cur_tail%%+([[:space:]])}"
    fi

    # Re-render when: last line changed, forced, or status interval
    # Add cooldown to prevent excessive renders even if logs change frequently
    if [ "$render_cooldown" -eq 0 ] && ([ "$cur_tail" != "$last_log_tail" ] || [ "$force_render" -eq 1 ]); then
      render "$cur_tail"
      last_log_tail="$cur_tail"
      idle_iters=0
      force_render=0
      render_cooldown=3   # cooldown: 3 seconds before next allowed render
    fi

    # Decrement cooldown
    [ "$render_cooldown" -gt 0 ] && render_cooldown=$((render_cooldown - 1))

    # Poll with variable timeout — longer waits during cooldown (less CPU, less visual spam)
    if read -t "$poll_timeout" -r -n 1 key 2>/dev/null; then
      case "$key" in
        n|N)
          current_index=$((current_index % account_count + 1))
          force_render=1
          ;;
        p|P)
          current_index=$(( (current_index - 2 + account_count) % account_count + 1 ))
          force_render=1
          ;;
        f|F)
          follow_mode
          ;;
        l|L)
          list_select
          ;;
        c|C)
          send_command
          ;;
        r|R)
          force_render=1
          ;;
        q|Q)
          _exit_monitor
          ;;
        [1-9])
          if [ "$key" -le "$account_count" ]; then
            current_index="$key"
            force_render=1
          fi
          ;;
      esac
    fi
  done
}

# ── status table (non-interactive) ───────────────────────────────────────────
show_status() {
  require_jq
  [ -f "$INDEX_FILE" ] || fatal "missing $INDEX_FILE"
  printf '\n %-6s %-12s %-8s %-8s %s\n' "ID" "Status" "Mode" "PID" "Alias"
  local sep; sep=$(printf '%55s' '' | tr ' ' '─')
  printf ' %s\n' "$sep"
  while IFS=$'\t' read -r id alias; do
    IFS='|' read -r state pid mode <<< "$(get_status "$id")"
    local sfmt; sfmt=$(state_fmt "$state")
    printf " %b  %-6s %-8s %-8s %s\n" "$sfmt" "$id" "$mode" "$pid" "$alias"
  done < <(jq -r '.accounts[] | select((.active // true) == true) | [.id, (.alias // .id)] | @tsv' "$INDEX_FILE")
  printf '\n'
}

usage() {
  printf '\n'
  printf '  Usage: ./twm_monitor.sh [command]\n\n'
  printf '  Commands:\n'
  printf '    (no args)   Interactive monitor\n'
  printf '    status      Status table (non-interactive)\n'
  printf '    help        This message\n\n'
  printf '  Keys in monitor:\n'
  printf '    N / P       Next / Previous account\n'
  printf '    F           Follow live (tail -f)  ← Ctrl+C to return\n'
  printf '    L           Account list (select by number)\n'
  printf '    C           Send command to macro (runs on next idle cycle)\n'
  printf '    R           Force refresh\n'
  printf '    Q           Quit\n'
  printf '    1-9         Jump directly to account by number\n\n'
  printf '  Refresh behaviour:\n'
  printf '    Renders immediately when the log file grows (active battle = fast updates,\n'
  printf '    idle = naturally quiet). Forces a status re-check every 60 seconds.\n\n'
}

# ── entry ─────────────────────────────────────────────────────────────────────
case "${1:-}" in
  help|--help|-h) usage;       exit 0 ;;
  status)         show_status; exit 0 ;;
  *)              interactive_monitor ;;
esac
