#!/bin/bash
# View real-time logs from a specific account runner
# Usage: ./twm_view.sh [account_id]

BASE_DIR="${HOME}/twm"
ACCOUNTS_DIR="${BASE_DIR}/accounts"
INDEX_FILE="${ACCOUNTS_DIR}/index.json"

usage() {
  cat <<'EOF'
Usage: ./twm_view.sh [account_id]

View real-time logs from a specific account runner.

Examples:
  ./twm_view.sh A1          # View logs for account A1
  ./twm_view.sh             # Interactive menu to select account
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

  if [ ! -d "$account_root" ]; then
    fatal "Account '$account_id' not found"
  fi

  if [ ! -f "$log_file" ]; then
    echo "Creating log file: $log_file"
    touch "$log_file"
  fi

  # Get account alias for display
  require_jq
  local alias
  alias=$(jq -r ".accounts[] | select(.id == \"$account_id\") | (.alias // .id)" "$INDEX_FILE" 2>/dev/null || echo "$account_id")

  clear
  printf "\033[1;36m╔══════════════════════════════════════╗\033[0m\n"
  printf "\033[1;36m║  TWM Log Viewer - Account: \033[1;33m%-18s\033[1;36m║\033[0m\n" "$alias"
  printf "\033[1;36m║  (Press Ctrl+C to exit)              \033[0m║\033[0m\n"
  printf "\033[1;36m╚══════════════════════════════════════╝\033[0m\n"
  echo ""

  tail -f "$log_file"
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
