#!/bin/bash
# Interactive monitor for viewing multiple account runners
# Navigate between accounts with arrow keys or number selection

BASE_DIR="${HOME}/twm"
ACCOUNTS_DIR="${BASE_DIR}/accounts"
INDEX_FILE="${ACCOUNTS_DIR}/index.json"
PID_DIR="${ACCOUNTS_DIR}/.pids"

fatal() {
  echo "twm_monitor: $*" >&2
  exit 1
}

require_jq() {
  if ! command -v jq >/dev/null 2>&1; then
    fatal "jq is required"
  fi
}

list_accounts() {
  require_jq
  if [ ! -f "$INDEX_FILE" ]; then
    fatal "missing $INDEX_FILE"
  fi
  jq -r '.accounts[] | select((.active // true) == true) | [.id, (.alias // .id)] | @tsv' "$INDEX_FILE"
}

is_running() {
  local pid="$1"
  if [ -z "$pid" ]; then
    return 1
  fi
  if kill -0 "$pid" 2>/dev/null; then
    return 0
  fi
  return 1
}

get_account_status() {
  local account_id="$1"
  local pid_file="${PID_DIR}/${account_id}.pid"
  local run_file="${ACCOUNTS_DIR}/${account_id}/runmode_file"

  local state="STOPPED"
  local pid="-"
  local runmode="-"

  if [ -f "$run_file" ]; then
    runmode=$(cat "$run_file" 2>/dev/null | tr -d '\r')
    [ -n "$runmode" ] || runmode="-"
  fi

  if [ -f "$pid_file" ]; then
    pid=$(cat "$pid_file" 2>/dev/null)
    if is_running "$pid"; then
      state="RUNNING"
    else
      state="DEAD"
    fi
  fi

  echo "$state|$pid|$runmode"
}

display_account_detail() {
  local account_id="$1"
  local alias="$2"
  local account_root="${ACCOUNTS_DIR}/${account_id}"
  local log_file="${account_root}/logs/twm.log"

  IFS='|' read -r state pid runmode <<< "$(get_account_status "$account_id")"

  clear

  # Header
  printf "\033[1;36m╔════════════════════════════════════════════════════╗\033[0m\n"
  printf "\033[1;36m║  TWM Monitor - Account: \033[1;33m%-26s\033[1;36m║\033[0m\n" "$alias"
  printf "\033[1;36m╠════════════════════════════════════════════════════╣\033[0m\n"

  # Status line
  if [ "$state" = "RUNNING" ]; then
    printf "\033[1;36m║\033[0m  Status: \033[1;32m$state\033[0m  PID: \033[1;33m$pid\033[0m  Mode: \033[1;33m$runmode\033[0m\n"
  elif [ "$state" = "STOPPED" ]; then
    printf "\033[1;36m║\033[0m  Status: \033[1;31m$state\033[0m  (not running)\n"
  else
    printf "\033[1;36m║\033[0m  Status: \033[1;31m$state\033[0m\n"
  fi

  printf "\033[1;36m║\033[0m  Log: $log_file\n"
  printf "\033[1;36m╠════════════════════════════════════════════════════╣\033[0m\n"
  printf "\033[1;36m║\033[0m  Commands: [N]ext  [P]rev  [L]ist  [R]efresh  [Q]uit\n"
  printf "\033[1;36m╠════════════════════════════════════════════════════╣\033[0m\n"

  # Log tail
  if [ -f "$log_file" ]; then
    tail -20 "$log_file" | sed 's/^/║ /'
  else
    printf "\033[1;36m║\033[0m  (no logs yet)\n"
  fi

  printf "\033[1;36m╚════════════════════════════════════════════════════╝\033[0m\n"
}

display_list() {
  clear

  printf "\033[1;36m╔════════════════════════════════════════════════════╗\033[0m\n"
  printf "\033[1;36m║  TWM Monitor - Account List              \033[0m      ║\033[0m\n"
  printf "\033[1;36m╠════════════════════════════════════════════════════╣\033[0m\n"

  local count=0
  declare -a ids
  declare -a aliases

  while IFS=$'\t' read -r id alias; do
    count=$((count + 1))
    ids[$count]="$id"
    aliases[$count]="$alias"

    IFS='|' read -r state pid runmode <<< "$(get_account_status "$id")"

    if [ "$state" = "RUNNING" ]; then
      state_color="\033[1;32m"  # Green
    elif [ "$state" = "STOPPED" ]; then
      state_color="\033[1;31m"  # Red
    else
      state_color="\033[1;33m"  # Yellow
    fi

    printf "\033[1;36m║\033[0m  %d) %-8s %s%-8s\033[0m PID: %-6s Mode: %s\n" \
      "$count" "$alias" "$state_color" "$state" "$pid" "$runmode"
  done <<EOF
$(list_accounts)
EOF

  printf "\033[1;36m╠════════════════════════════════════════════════════╣\033[0m\n"
  printf "\033[1;36m║\033[0m  Select account by number or [Q]uit\n"
  printf "\033[1;36m╚════════════════════════════════════════════════════╝\033[0m\n"
}

interactive_monitor() {
  declare -a account_ids
  declare -a account_aliases
  local account_count=0
  local current_index=0

  # Load all accounts
  while IFS=$'\t' read -r id alias; do
    account_count=$((account_count + 1))
    account_ids[$account_count]="$id"
    account_aliases[$account_count]="$alias"
  done <<EOF
$(list_accounts)
EOF

  if [ $account_count -eq 0 ]; then
    fatal "No active accounts found"
  fi

  # Set terminal to raw mode for immediate key input
  local tty_state=$(stty -g)
  trap "stty $tty_state; exit 0" EXIT INT TERM

  while true; do
    current_index=$((current_index % account_count + 1))
    current_id="${account_ids[$current_index]}"
    current_alias="${account_aliases[$current_index]}"

    display_account_detail "$current_id" "$current_alias"

    # Check for input (non-blocking with timeout)
    if read -t 0.5 -r -n 1 key 2>/dev/null; then
      case "$key" in
        n|N)
          current_index=$((current_index % account_count + 1))
          ;;
        p|P)
          current_index=$(((current_index - 2 + account_count) % account_count + 1))
          ;;
        l|L)
          display_list
          read -t 30 -r -n 1 selection
          if [[ "$selection" =~ ^[0-9]+$ ]]; then
            if [ "$selection" -ge 1 ] && [ "$selection" -le "$account_count" ]; then
              current_index="$selection"
            fi
          fi
          ;;
        r|R)
          # Just refresh on next loop
          ;;
        q|Q)
          exit 0
          ;;
        [0-9])
          if [ "$key" -ge 1 ] && [ "$key" -le "$account_count" ]; then
            current_index="$key"
          fi
          ;;
      esac
    fi
  done
}

usage() {
  cat <<'EOF'
Usage: ./twm_monitor.sh [command]

Interactive monitor for viewing account runners with navigation.

Commands:
  (no args)    Start interactive monitor
  status       Show current status of all accounts
  help         Show this message

Navigation (in monitor):
  [N]ext       - Move to next account
  [P]rev       - Move to previous account
  [L]ist       - Show account list and select by number
  [R]efresh    - Refresh display
  [Q]uit       - Exit monitor
  [1-9]        - Jump to account by number (when in list view)
EOF
}

case "${1:-}" in
  help|--help|-h)
    usage
    exit 0
    ;;
  status)
    require_jq
    printf "%-8s %-12s %-8s %s\n" "ID" "Status" "PID" "Alias"
    while IFS=$'\t' read -r id alias; do
      IFS='|' read -r state pid runmode <<< "$(get_account_status "$id")"
      printf "%-8s %-12s %-8s %s\n" "$id" "$state" "$pid" "$alias"
    done <<EOF
$(list_accounts)
EOF
    exit 0
    ;;
  *)
    interactive_monitor
    ;;
esac
