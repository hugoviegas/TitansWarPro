#!/bin/bash
# First-time setup wizard for adding/configuring a new account
# This script walks through interactive setup instead of having twm.sh ask questions later

BASE_DIR="${HOME}/twm"
ACCOUNTS_DIR="${BASE_DIR}/accounts"
INDEX_FILE="${ACCOUNTS_DIR}/index.json"

colors() {
    BLACK_CYAN='\033[01;36m\033[01;07m'
    GOLD_BLACK='\033[0;33m'
    GREEN_BLACK='\033[32m'
    GREENb_BLACK='\033[1;32m'
    RED_BLACK='\033[0;31m'
    COLOR_RESET='\033[00m'
}

require_jq() {
  if ! command -v jq >/dev/null 2>&1; then
    echo "jq is required to manage accounts/index.json" >&2
    exit 1
  fi
}

fatal() {
  echo "twm_setup: $*" >&2
  exit 1
}

show_header() {
  colors
  clear
  printf "${BLACK_CYAN}"
  printf "╔════════════════════════════════════════════════════╗\n"
  printf "║          🐉 TITANS WAR - ACCOUNT SETUP 🐉          ║\n"
  printf "╚════════════════════════════════════════════════════╝\n"
  printf "${COLOR_RESET}\n"
}

create_account_config() {
  local account_root="$1"
  local language="$2"
  local allies="$3"

  mkdir -p "$account_root"

  cat > "$account_root/config.cfg" <<EOF
FUNC_check_rewards=y
FUNC_use_elixir=n
FUNC_coliseum=y
FUNC_AUTO_UPDATE=y
FUNC_play_league=999
FUNC_clan_figth=y
SCRIPT_PAUSED=n
LANGUAGE=$language
ALLIES=$allies
UPDATE_CHANNEL=master
EOF

  chmod 600 "$account_root/config.cfg"
  echo "✅ Config created: $account_root/config.cfg"
}

setup_account() {
  show_header

  printf "${GREENb_BLACK}Step 1: Account Information${COLOR_RESET}\n\n"

  printf "Account ID (e.g., A1, A2, MyAccount): "
  read -r account_id
  [ -z "$account_id" ] && { printf "Cancelled.\n"; exit 0; }

  printf "Account Alias/Display Name (e.g., Player1): "
  read -r alias
  [ -z "$alias" ] && alias="$account_id"

  printf "\n${GREENb_BLACK}Step 2: Game Server${COLOR_RESET}\n\n"
  printf "Available servers:\n"
  printf "  1) Brasil (furiadetigas.net)\n"
  printf "  2) Germany (titanen.mobi)\n"
  printf "  3) Spain (guerradetibitanes.net)\n"
  printf "  4) France (tiwar.fr)\n"
  printf "  5) India (in.tiwar.net)\n"
  printf "  6) Indonesia (tiwar-id.net)\n"
  printf "  7) Italy (guerraditiani.net)\n"
  printf "  8) Poland (Wojna Tytanów)\n"
  printf "  9) Romania (Războiul Titanilor)\n"
  printf " 10) Russia (Битва Титанов)\n"
  printf " 11) Serbia (Rat Titana)\n"
  printf " 12) China (泰坦之战)\n"
  printf " 13) English/Global (titans-war.com)\n"

  printf "\nSelect server (1-13): "
  read -r server_num
  [ -z "$server_num" ] && server_num=13

  printf "\n${GREENb_BLACK}Step 3: Language${COLOR_RESET}\n\n"
  printf "Select language:\n"
  printf "  en) English\n"
  printf "  pt) Portuguese\n"
  printf "  de) German\n"
  printf "  es) Spanish\n"
  printf "  fr) French\n"

  printf "Language (default: en): "
  read -r language
  [ -z "$language" ] && language="en"

  printf "\n${GREENb_BLACK}Step 4: Game Allies${COLOR_RESET}\n\n"
  printf "Which allies to use in battles?\n"
  printf "  1) All battles (Heroes + Clan)\n"
  printf "  2) Heroes only (Coliseum/King of Immortals)\n"
  printf "  3) Clan only (Altars/Clan events)\n"
  printf "  4) No allies\n"

  printf "Select (1-4, default: 1): "
  read -r allies_choice
  [ -z "$allies_choice" ] && allies_choice="1"

  printf "\n${GREENb_BLACK}Step 5: Auto-Update${COLOR_RESET}\n\n"
  printf "Auto-update scripts? (y/n, default: y): "
  read -r auto_update
  [ -z "$auto_update" ] && auto_update="y"

  # Create directories
  mkdir -p "$ACCOUNTS_DIR/$account_id/tmp"
  mkdir -p "$ACCOUNTS_DIR/$account_id/logs"
  mkdir -p "$ACCOUNTS_DIR/$account_id/w3m"

  # Create config
  create_account_config "$ACCOUNTS_DIR/$account_id" "$language" "$allies_choice"

  # Set ur_file (server selection)
  echo "$server_num" > "$ACCOUNTS_DIR/$account_id/ur_file"
  echo "-boot" > "$ACCOUNTS_DIR/$account_id/runmode_file"

  # Update or create index.json
  if [ -f "$INDEX_FILE" ]; then
    require_jq
    # Add new account to existing index
    jq --arg id "$account_id" \
       --arg alias "$alias" \
       --arg ur "$server_num" \
       '.accounts += [{
         "id": $id,
         "alias": $alias,
         "ur": $ur,
         "language": "'$language'",
         "runMode": "-boot",
         "active": true,
         "autoRestart": true
       }]' "$INDEX_FILE" > "${INDEX_FILE}.tmp"
    mv "${INDEX_FILE}.tmp" "$INDEX_FILE"
  else
    require_jq
    # Create new index.json
    jq -n \
       --arg id "$account_id" \
       --arg alias "$alias" \
       --arg ur "$server_num" \
       '{
         "version": 1,
         "defaultAccount": $id,
         "accounts": [{
           "id": $id,
           "alias": $alias,
           "ur": $ur,
           "language": "'$language'",
           "runMode": "-boot",
           "active": true,
           "autoRestart": true
         }]
       }' > "$INDEX_FILE"
  fi

  show_header
  printf "${GREENb_BLACK}✅ Account Created Successfully!${COLOR_RESET}\n\n"
  printf "Account ID:     ${GOLD_BLACK}$account_id${COLOR_RESET}\n"
  printf "Alias:          ${GOLD_BLACK}$alias${COLOR_RESET}\n"
  printf "Server:         ${GOLD_BLACK}$server_num${COLOR_RESET}\n"
  printf "Language:       ${GOLD_BLACK}$language${COLOR_RESET}\n"
  printf "Allies:         ${GOLD_BLACK}$allies_choice${COLOR_RESET}\n\n"

  printf "Next steps:\n"
  printf "1. You'll need to login on first run\n"
  printf "2. Enter your game username and password when prompted\n"
  printf "3. Select which allies to use (if not already set)\n\n"

  printf "To run this account:\n"
  printf "  ${GOLD_BLACK}./multi_runner.sh start${COLOR_RESET}           # Run all accounts\n"
  printf "  ${GOLD_BLACK}./twm_control.sh${COLOR_RESET}                  # Management menu\n"
  printf "  ${GOLD_BLACK}./twm_monitor.sh${COLOR_RESET}                  # Monitor logs\n\n"

  read -p "Press Enter to exit..."
}

list_accounts() {
  show_header

  require_jq
  if [ ! -f "$INDEX_FILE" ]; then
    printf "No accounts configured yet.\n"
    return
  fi

  printf "${GREENb_BLACK}Existing Accounts:${COLOR_RESET}\n\n"
  jq -r '.accounts[] | "\(.id) - \(.alias) (Server: \(.ur))"' "$INDEX_FILE"
  printf "\n"
}

main() {
  case "${1:-}" in
    list)
      list_accounts
      ;;
    *)
      setup_account
      ;;
  esac
}

main "$@"
