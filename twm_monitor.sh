#!/bin/bash
# twm_monitor.sh — Live account log monitor
#
# Refresh strategy (matches macro cadence):
#   - Renders immediately when log grows (battles: rapid; idle: ~60s natural pause)
#   - Forces a status check every 60s even when log is quiet
#   - Follow mode: tail -f live stream, Ctrl+C returns to monitor

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
  printf '\033[1;36m'
  printf '─%.0s' $(seq 1 "$TERM_COLS")
  printf '\033[0m\n'
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
  for i in $(seq 1 "$account_count"); do
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
  local id="${account_ids[$current_index]}"
  local alias="${account_aliases[$current_index]}"
  local info; info=$(get_status "$id")
  local state; state="${info%%|*}"
  local pid;   pid="${info#*|}"; pid="${pid%|*}"
  local mode;  mode="${info##*|}"
  local sfmt;  sfmt=$(state_fmt "$state")
  local log_file="${ACCOUNTS_DIR}/${id}/logs/twm.log"

  # Show age of last log entry (when was the macro last active?)
  local last_ts=""
  if [ -f "$log_file" ]; then
    last_ts=$(tail -1 "$log_file" 2>/dev/null | grep -oE '^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}')
    [ -n "$last_ts" ] && last_ts=" | last: \033[0;37m${last_ts}\033[0m"
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

  if [ -f "$log_file" ]; then
    tail -"$log_lines" "$log_file"
  else
    printf '\033[0;33m  Waiting for log file: %s\033[0m\n' "$log_file"
  fi
}

render() {
  update_term_size
  printf '\033[H\033[J'   # cursor home + clear screen
  draw_top_bar
  draw_account_header
  draw_log
}

# ── follow mode (live tail -f) ────────────────────────────────────────────────
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
  printf "   \033[0;36mCtrl+C → return to monitor\033[0m\n"
  hline

  # Override INT: Ctrl+C returns to monitor instead of full exit
  trap '_restore_raw_mode; return' INT

  if [ -f "$log_file" ]; then
    tail -f "$log_file" 2>/dev/null
  else
    printf '\033[0;33m  Waiting for log file to appear...\033[0m\n'
    until [ -f "$log_file" ]; do sleep 1; done
    tail -f "$log_file" 2>/dev/null
  fi

  # Reached only if tail exits without Ctrl+C (e.g. log deleted)
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
  for i in $(seq 1 "$account_count"); do
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

  stty -icanon -echo min 0 time 0 2>/dev/null
  printf '\033[?25l'
  force_render=1

  if [ -n "$cmd" ]; then
    printf '%s\n' "$cmd" > "$cmd_file"
    printf '\033[1;32m  Queued: %s\033[0m\n' "$cmd"
    sleep 1
  fi
}


interactive_monitor() {
  load_accounts
  [ "$account_count" -gt 0 ] || fatal "No active accounts found in $INDEX_FILE"

  tty_state=$(stty -g 2>/dev/null)
  trap '_exit_monitor' EXIT INT TERM
  trap 'update_term_size; force_render=1' WINCH   # handle terminal resize

  stty -icanon -echo min 0 time 0 2>/dev/null
  printf '\033[?25l'

  local last_log_lines=-1
  local last_status_time=0

  while true; do
    local id="${account_ids[$current_index]}"
    local log_file="${ACCOUNTS_DIR}/${id}/logs/twm.log"
    local now; now=$(date +%s 2>/dev/null || echo 0)
    local age=$((now - last_status_time))

    # Count log lines — fast heuristic for change detection
    local cur_lines=0
    [ -f "$log_file" ] && cur_lines=$(wc -l < "$log_file" 2>/dev/null || echo 0)

    # Re-render when: log grew, forced, or 60s status interval
    if [ "$cur_lines" -ne "$last_log_lines" ] || [ "$force_render" -eq 1 ] || [ "$age" -ge 60 ]; then
      render
      last_log_lines="$cur_lines"
      last_status_time="$now"
      force_render=0
    fi

    # Poll for 1 second — immediately picks up log changes on next iteration
    if read -t 1 -r -n 1 key 2>/dev/null; then
      case "$key" in
        n|N)
          current_index=$((current_index % account_count + 1))
          last_log_lines=-1; force_render=1
          ;;
        p|P)
          current_index=$(( (current_index - 2 + account_count) % account_count + 1 ))
          last_log_lines=-1; force_render=1
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
            last_log_lines=-1; force_render=1
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
  printf ' %s\n' "$(printf '─%.0s' $(seq 1 55))"
  while IFS=$'\t' read -r id alias; do
    IFS='|' read -r state pid mode <<< "$(get_status "$id")"
    local sfmt; sfmt=$(state_fmt "$state")
    printf " %b  %-6s %-8s %-8s %s\n" "$sfmt" "$id" "$mode" "$pid" "$alias"
  done < <(jq -r '.accounts[] | select((.active // true) == true) | [.id, (.alias // .id)] | @tsv' "$INDEX_FILE")
  printf '\n'
}

usage() {
  cat <<'EOF'

  Usage: ./twm_monitor.sh [command]

  Commands:
    (no args)   Interactive monitor
    status      Status table (non-interactive)
    help        This message

  Keys in monitor:
    N / P       Next / Previous account
    F           Follow live (tail -f)  ← Ctrl+C to return
    L           Account list (select by number)
    C           Send command to macro (runs on next idle cycle)
    R           Force refresh
    Q           Quit
    1-9         Jump directly to account by number

  Refresh behaviour:
    Renders immediately when the log file grows (active battle = fast updates,
    idle = naturally quiet). Forces a status re-check every 60 seconds.

EOF
}

# ── entry ─────────────────────────────────────────────────────────────────────
case "${1:-}" in
  help|--help|-h) usage;       exit 0 ;;
  status)         show_status; exit 0 ;;
  *)              interactive_monitor ;;
esac
