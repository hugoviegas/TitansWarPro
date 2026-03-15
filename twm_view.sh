#!/bin/bash
# View real-time logs from a specific account runner
# Usage: ./twm_view.sh [account_id]

BASE_DIR="${HOME}/twm"
ACCOUNTS_DIR="${BASE_DIR}/accounts"
INDEX_FILE="${ACCOUNTS_DIR}/index.json"

usage() {
  cat <<'EOF'
Usage: ./twm_view.sh [account_id]

Attach to a running account session for full interactive access.
If tmux is installed and the account is running, attaches to its tmux session.
Otherwise falls back to a live log tail.

Examples:
  ./twm_view.sh A1          # View/attach to account A1
  ./twm_view.sh             # Interactive menu to select account
  Ctrl+B D                  # Detach from session (tmux mode)
  Ctrl+C                    # Exit log viewer (fallback mode)
EOF
}

fatal() {
  echo "twm_view: $*" >&2
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

interactive_select() {
  local choices=""
  local count=0
  declare -a ids
  declare -a aliases

  echo "Available accounts:"
  echo ""

  while IFS=$'\t' read -r id alias; do
    count=$((count + 1))
    ids[$count]="$id"
    aliases[$count]="$alias"
    printf "  %d) %s (%s)\n" "$count" "$alias" "$id"
  done <<EOF
$(list_accounts)
EOF

  if [ $count -eq 0 ]; then
    fatal "No active accounts found"
  fi

  echo ""
  read -p "Select account [1-$count]: " selection

  if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt $count ]; then
    fatal "Invalid selection"
  fi

  echo "${ids[$selection]}"
}

view_logs() {
  local account_id="$1"
  local account_root="${ACCOUNTS_DIR}/${account_id}"
  local log_file="${account_root}/logs/twm.log"
  local sname="twm_${account_id}"

  if [ ! -d "$account_root" ]; then
    fatal "Account '$account_id' not found"
  fi

  # Get account alias for display
  require_jq
  local alias
  alias=$(jq -r ".accounts[] | select(.id == \"$account_id\") | (.alias // .id)" "$INDEX_FILE" 2>/dev/null || echo "$account_id")

  if command -v tmux >/dev/null 2>&1 && tmux has-session -t "$sname" 2>/dev/null; then
    # Show navigation instructions before attaching
    clear
    local sep="──────────────────────────────────────────────────────"
    printf " \033[1;36m%s\033[0m\n" "$sep"
    printf " Conectando em / Attaching to: \033[1;33m%s\033[0m  \033[0;37m(%s)\033[0m\n" "$alias" "$sname"
    printf " \033[1;36m%s\033[0m\n" "$sep"
    printf " \033[1;32mCtrl+B d\033[0m  Desanexar / Detach  →  voltar ao terminal / return\n"
    printf " \033[1;32mCtrl+B s\033[0m  Listar sessões / Session list  (↑↓ + Enter p/ trocar/switch)\n"
    printf " \033[1;32mCtrl+B (\033[0m  Sessão anterior / Previous session\n"
    printf " \033[1;32mCtrl+B )\033[0m  Próxima sessão / Next session\n"
    printf " \033[1;36m%s\033[0m\n" "$sep"

    # List all active twm sessions
    local sessions
    sessions=$(tmux list-sessions -F '  #{session_name}' 2>/dev/null | grep '  twm_' | tr '\n' '   ' || true)
    [ -n "$sessions" ] && printf " Sessões ativas / Active sessions: \033[0;36m%s\033[0m\n" "$sessions"
    printf " \033[1;36m%s\033[0m\n" "$sep"
    printf " \033[0;37m[qualquer tecla / any key para continuar, auto 2s]\033[0m "
    read -r -n 1 -s -t 2 </dev/tty 2>/dev/null || true
    printf "\n\n"

    # Attach to the live tmux session — full interactive access
    tmux attach-session -t "$sname"
  else
    # Fallback: tail log file
    if [ ! -f "$log_file" ]; then
      echo "Creating log file: $log_file"
      touch "$log_file"
    fi

    clear
    printf "\033[1;36m╔══════════════════════════════════════╗\033[0m\n"
    printf "\033[1;36m║  TWM Log Viewer - Account: \033[1;33m%-18s\033[1;36m║\033[0m\n" "$alias"
    printf "\033[1;36m║  (Press Ctrl+C to exit)              \033[0m║\033[0m\n"
    printf "\033[1;36m╚══════════════════════════════════════╝\033[0m\n"
    echo ""
    tail -f "$log_file"
  fi
}

main() {
  if [ $# -eq 0 ]; then
    account_id=$(interactive_select)
  else
    account_id="$1"
  fi

  view_logs "$account_id"
}

case "${1:-}" in
  help|--help|-h)
    usage
    exit 0
    ;;
  *)
    main "$@"
    ;;
esac
