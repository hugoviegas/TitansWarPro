#!/bin/bash
# Account setup wizard: add, edit, or remove accounts for the multi-account system.

BASE_DIR="${HOME}/twm"
ACCOUNTS_DIR="${BASE_DIR}/accounts"
INDEX_FILE="${ACCOUNTS_DIR}/index.json"
LANGUAGE="${LANGUAGE:-en}"

colors() {
    BLACK_CYAN='\033[01;36m\033[01;07m'
    GOLD_BLACK='\033[0;33m'
    GREEN_BLACK='\033[32m'
    GREENb_BLACK='\033[1;32m'
    RED_BLACK='\033[0;31m'
    BLACK_RED='\033[01;31m\033[01;07m'
    BLACK_YELLOW='\033[00;33m\033[01;07m'
    COLOR_RESET='\033[00m'
}

# Translation function for setup messages
translate() {
    local key="$1"
    case "$LANGUAGE" in
        pt)
            case "$key" in
                "setup_title") echo "🐉 TITANS WAR - CONFIGURAR CONTA 🐉" ;;
                "add_or_edit") echo "Adicionar ou editar conta?" ;;
                "step") echo "Passo" ;;
                "account_id") echo "ID da Conta" ;;
                "account_alias") echo "Apelido da Conta" ;;
                "select_server") echo "Selecione um servidor (1-13):" ;;
                "language") echo "Idioma" ;;
                "allies") echo "Aliados" ;;
                "auto_update") echo "Atualização automática (s/n)" ;;
                "username") echo "Usuário" ;;
                "password") echo "Senha" ;;
                "success") echo "✓ Conta criada/editada com sucesso!" ;;
                "error") echo "✗ Erro ao processar conta" ;;
                "cancel") echo "Cancelado" ;;
                "remove_confirm") echo "Deseja remover a conta?" ;;
                *) echo "$key" ;;
            esac
            ;;
        *)  # Default English
            case "$key" in
                "setup_title") echo "🐉 TITANS WAR - ACCOUNT SETUP 🐉" ;;
                "add_or_edit") echo "Add or edit account?" ;;
                "step") echo "Step" ;;
                "account_id") echo "Account ID" ;;
                "account_alias") echo "Account Alias" ;;
                "select_server") echo "Select a server (1-13):" ;;
                "language") echo "Language" ;;
                "allies") echo "Allies" ;;
                "auto_update") echo "Auto-update (y/n)" ;;
                "username") echo "Username" ;;
                "password") echo "Password" ;;
                "success") echo "✓ Account created/edited successfully!" ;;
                "error") echo "✗ Error processing account" ;;
                "cancel") echo "Cancelled" ;;
                "remove_confirm") echo "Confirm removal of account?" ;;
                *) echo "$key" ;;
            esac
            ;;
    esac
}

require_jq() {
    if ! command -v jq >/dev/null 2>&1; then
        printf "jq is required to manage accounts/index.json\n" >&2
        exit 1
    fi
}

show_header() {
    colors
    clear
    printf "${BLACK_CYAN}"
    printf "╔════════════════════════════════════════════════════╗\n"
    printf "║          $(translate "setup_title")\n"
    printf "╚════════════════════════════════════════════════════╝\n"
    printf "${COLOR_RESET}\n"
}

# Collect a password with * masking into $password
collect_password() {
    password=""
    printf "Password: "
    read -rs password
    printf "\n"
}

create_account_config() {
    local account_root="$1"
    local language="$2"
    # Use provided config values, or defaults
    local check_rewards="${3:-y}"
    local use_elixir="${4:-y}"
    local coliseum="${5:-y}"
    local auto_update="${6:-n}"
    local play_league="${7:-999}"
    local clan_fight="${8:-y}"
    local collect_mission_rewards="${9:-y}"
    local pause_weekends="${10:-y}"
    local auto_events="${11:-y}"
    local clan_missions="${12:-y}"
    local clan_statue="${13:-n}"
    local cave_boost="${14:-n}"

    mkdir -p "$account_root"

    cat > "$account_root/config.cfg" <<EOF
FUNC_check_rewards=$check_rewards
FUNC_use_elixir=$use_elixir
FUNC_coliseum=$coliseum
FUNC_AUTO_UPDATE=$auto_update
FUNC_play_league=$play_league
FUNC_clan_figth=$clan_fight
FUNC_collect_mission_rewards=$collect_mission_rewards
FUNC_pause_weekends=$pause_weekends
FUNC_auto_events=$auto_events
FUNC_clan_missions=$clan_missions
FUNC_clan_statue=$clan_statue
FUNC_cave_boost=$cave_boost
SCRIPT_PAUSED=n
LANGUAGE=$language
ALLIES=4
UPDATE_CHANNEL=master
EOF

    chmod 600 "$account_root/config.cfg"
}

save_credentials() {
    local account_dir="$1"
    local server_num="$2"
    local username="$3"
    local password="$4"
    local tmp_path="$account_dir/tmp/.$server_num"
    mkdir -p "$tmp_path"
    printf "login=%s&pass=%s" "$username" "$password" | base64 -w 0 > "$tmp_path/cript_file"
    chmod 600 "$tmp_path/cript_file"
}

update_index() {
    local account_id="$1" alias="$2" server_num="$3" language="$4"
    require_jq
    if [ -f "$INDEX_FILE" ]; then
        jq --arg id "$account_id" \
           --arg alias "$alias" \
           --arg ur "$server_num" \
           --arg lang "$language" \
           '.accounts += [{"id":$id,"alias":$alias,"ur":$ur,"language":$lang,"runMode":"-boot","active":true,"autoRestart":true}]' \
           "$INDEX_FILE" > "${INDEX_FILE}.tmp" && mv "${INDEX_FILE}.tmp" "$INDEX_FILE"
    else
        jq -n \
           --arg id "$account_id" \
           --arg alias "$alias" \
           --arg ur "$server_num" \
           --arg lang "$language" \
           '{"version":1,"defaultAccount":$id,"accounts":[{"id":$id,"alias":$alias,"ur":$ur,"language":$lang,"runMode":"-boot","active":true,"autoRestart":true}]}' \
           > "$INDEX_FILE"
    fi
}

# Configuration menu for custom setup (similar to function.sh)
config_account() {
    local account_id="$1"
    local language="$2"
    local config_file="$ACCOUNTS_DIR/$account_id/config.cfg"

    # Initialize with defaults
    local check_rewards="y"
    local use_elixir="y"
    local coliseum="y"
    local auto_update="n"
    local play_league="999"
    local clan_fight="y"
    local collect_mission_rewards="y"
    local pause_weekends="y"
    local auto_events="y"
    local clan_missions="y"
    local clan_statue="n"
    local cave_boost="n"

    local cmd choice
    while true; do
        clear
        printf "${BLACK_CYAN}"
        printf "╔════════════════════════════════════════════════════╗\n"
        printf "║         Configure Macro Settings\n"
        printf "╚════════════════════════════════════════════════════╝\n"
        printf "${COLOR_RESET}\n"

        printf " 1- Collect relics               [${check_rewards}]\n"
        printf " 2- Use elixir                   [${use_elixir}]\n"
        printf " 3- Coliseum                     [${coliseum}]\n"
        printf " 4- Get to top in league         [${play_league}]\n"
        printf " 5- Collect mission rewards      [${collect_mission_rewards}]\n"
        printf " 6- Pause rewards on weekends    [${pause_weekends}]\n"
        printf " 7- Complete events              [${auto_events}]\n"
        printf " 8- Complete clan missions       [${clan_missions}]\n"
        printf " 9- Enable clan statue           [${clan_statue}]\n"
        printf "10- Use gold for cave boost      [${cave_boost}]\n"
        printf "\nOption (1-10, or Enter to save): "
        read -r -n 2 choice

        case "$choice" in
            1)
                printf "\nEnable collect relics? (y/n): "
                read -r -n 1 check_rewards
                printf "\n"
                ;;
            2)
                printf "\nEnable use elixir? (y/n): "
                read -r -n 1 use_elixir
                printf "\n"
                ;;
            3)
                printf "\nEnable coliseum? (y/n): "
                read -r -n 1 coliseum
                printf "\n"
                ;;
            4)
                printf "\nLeague rank to reach (1-999): "
                read -r play_league
                [ -n "$play_league" ] || play_league="999"
                printf "\n"
                ;;
            5)
                printf "\nEnable mission rewards? (y/n): "
                read -r -n 1 collect_mission_rewards
                printf "\n"
                ;;
            6)
                printf "\nPause rewards on weekends? (y/n): "
                read -r -n 1 pause_weekends
                printf "\n"
                ;;
            7)
                printf "\nEnable events? (y/n): "
                read -r -n 1 auto_events
                printf "\n"
                ;;
            8)
                printf "\nEnable clan missions? (y/n): "
                read -r -n 1 clan_missions
                printf "\n"
                ;;
            9)
                printf "\nEnable clan statue? (y/n): "
                read -r -n 1 clan_statue
                printf "\n"
                ;;
            10)
                printf "\nEnable cave boost? (y/n): "
                read -r -n 1 cave_boost
                printf "\n"
                ;;
            '')
                # Save config and exit
                create_account_config "$ACCOUNTS_DIR/$account_id" "$language" \
                    "$check_rewards" "$use_elixir" "$coliseum" "$auto_update" \
                    "$play_league" "$clan_fight" "$collect_mission_rewards" \
                    "$pause_weekends" "$auto_events" "$clan_missions" \
                    "$clan_statue" "$cave_boost"
                printf "✅ Config saved (custom settings)\n"
                sleep 1s
                return
                ;;
            *)
                printf "\nInvalid option\n"
                ;;
        esac
    done
}

setup_account() {
    show_header

    printf "${GREENb_BLACK}Step 1/5 — Account Information${COLOR_RESET}\n\n"
    printf "Account ID (e.g., A1, A2): "
    read -r account_id
    [ -z "$account_id" ] && { printf "Cancelled.\n"; exit 0; }

    printf "Account Alias/Display Name (e.g., Player1): "
    read -r alias
    [ -z "$alias" ] && alias="$account_id"

    show_header
    printf "${GREENb_BLACK}Step 2/5 — Game Server${COLOR_RESET}\n\n"
    printf "  1)  Brasil         — furiadetigas.net\n"
    printf "  2)  Germany        — titanen.mobi\n"
    printf "  3)  Spain          — guerradetibitanes.net\n"
    printf "  4)  France         — tiwar.fr\n"
    printf "  5)  India          — in.tiwar.net\n"
    printf "  6)  Indonesia      — tiwar-id.net\n"
    printf "  7)  Italy          — guerraditiani.net\n"
    printf "  8)  Poland         — tiwar.pl\n"
    printf "  9)  Romania        — tiwar.ro\n"
    printf " 10)  Russia         — tiwar.ru\n"
    printf " 11)  Serbia         — rs.tiwar.net\n"
    printf " 12)  China          — cn.tiwar.net\n"
    printf " 13)  English/Global — titans-war.com\n"
    printf "\nSelect server (1-13, default: 1): "
    read -r server_num
    [ -z "$server_num" ] && server_num=1

    show_header
    printf "${GREENb_BLACK}Step 3/5 — Language${COLOR_RESET}\n\n"
    printf "  en) English  pt) Portuguese  de) German\n"
    printf "  es) Spanish  fr) French\n\n"
    printf "Language (default: pt): "
    read -r language
    [ -z "$language" ] && language="pt"

    show_header
    printf "${GREENb_BLACK}Step 4/5 — Game Credentials${COLOR_RESET}\n\n"
    printf "Enter your game username and password.\n"
    printf "These are stored locally (base64 encoded) and used to auto-login.\n\n"
    printf "Username: "
    read -r username
    collect_password

    # Show default configs and ask user preference
    show_header
    printf "${GREENb_BLACK}Step 5/5 — Macro Configuration${COLOR_RESET}\n\n"
    printf "Choose configuration mode:\n\n"
    printf "  ${GREENb_BLACK}1) Use Default Settings${COLOR_RESET}\n"
    printf "     ✓ Collect relics       ✓ Use elixir\n"
    printf "     ✓ Coliseum             ✓ Mission rewards\n"
    printf "     ✓ Events               ✓ Clan missions\n"
    printf "     ✗ Clan statue          ✗ Cave boost\n\n"
    printf "  ${GREENb_BLACK}2) Custom Configuration${COLOR_RESET}\n"
    printf "     Configure each feature individually\n\n"
    printf "Select (1-2, default: 1): "
    read -r config_choice
    [ -z "$config_choice" ] && config_choice="1"

    # Create directories
    mkdir -p "$ACCOUNTS_DIR/$account_id/tmp"
    mkdir -p "$ACCOUNTS_DIR/$account_id/logs"
    mkdir -p "$ACCOUNTS_DIR/$account_id/w3m"

    # If custom config, show menu
    if [ "$config_choice" = "2" ]; then
        show_header
        config_account "$account_id" "$language"
    else
        # Use default config
        create_account_config "$ACCOUNTS_DIR/$account_id" "$language"
        printf "✅ Config created (default settings)\n"
    fi

    # Write server selection
    printf "%s\n" "$server_num" > "$ACCOUNTS_DIR/$account_id/ur_file"
    printf -- "-boot\n" > "$ACCOUNTS_DIR/$account_id/runmode_file"

    # Write credentials to cript_file (so first run auto-logs in)
    if [ -n "$username" ] && [ -n "$password" ]; then
        save_credentials "$ACCOUNTS_DIR/$account_id" "$server_num" "$username" "$password"
        printf "✅ Credentials saved\n"
    fi

    # Update index.json
    update_index "$account_id" "$alias" "$server_num" "$language"
    printf "✅ index.json updated\n"

    show_header
    printf "${GREENb_BLACK}✅  Account created successfully!${COLOR_RESET}\n\n"
    printf "  Account ID : ${GOLD_BLACK}%s${COLOR_RESET}\n" "$account_id"
    printf "  Alias      : ${GOLD_BLACK}%s${COLOR_RESET}\n" "$alias"
    printf "  Server     : ${GOLD_BLACK}%s${COLOR_RESET}\n" "$server_num"
    printf "  Language   : ${GOLD_BLACK}%s${COLOR_RESET}\n\n" "$language"
    printf "Run:\n"
    printf "  ${GOLD_BLACK}./multi_runner.sh start${COLOR_RESET}   — launch all accounts\n"
    printf "  ${GOLD_BLACK}./play.sh A1${COLOR_RESET}              — launch this account\n"
    printf "  ${GOLD_BLACK}./twm_monitor.sh${COLOR_RESET}          — monitor logs\n\n"
    read -rp "Press Enter to exit..."
}

list_accounts() {
    require_jq
    if [ ! -f "$INDEX_FILE" ]; then
        printf "No accounts configured yet.\n"
        return 1
    fi
    jq -r '.accounts[] | "  \(.id)  \(.alias)  (server: \(.ur))"' "$INDEX_FILE"
    return 0
}

remove_account() {
    show_header
    printf "${GREENb_BLACK}Remove Account${COLOR_RESET}\n\n"
    if ! list_accounts; then
        read -rp "Press Enter..."
        return
    fi

    printf "\nAccount ID to remove (or Enter to cancel): "
    read -r target_id
    [ -z "$target_id" ] && { printf "Cancelled.\n"; return; }

    printf "\n${BLACK_RED}WARNING: All data for account '%s' will be deleted.${COLOR_RESET}\n" "$target_id"
    printf "Type ${GOLD_BLACK}yes${COLOR_RESET} to confirm: "
    read -r confirm
    [ "$confirm" != "yes" ] && { printf "Cancelled.\n"; read -rp "Press Enter..."; return; }

    require_jq
    jq --arg id "$target_id" 'del(.accounts[] | select(.id == $id))' \
        "$INDEX_FILE" > "${INDEX_FILE}.tmp" && mv "${INDEX_FILE}.tmp" "$INDEX_FILE"
    printf "✅ Removed from index.json\n"

    if [ -d "$ACCOUNTS_DIR/$target_id" ]; then
        rm -rf "$ACCOUNTS_DIR/$target_id"
        printf "✅ Deleted %s\n" "$ACCOUNTS_DIR/$target_id"
    fi

    printf "\n${GREENb_BLACK}Account '%s' removed.${COLOR_RESET}\n" "$target_id"
    read -rp "Press Enter..."
}

edit_account() {
    show_header
    printf "${GREENb_BLACK}Edit Account${COLOR_RESET}\n\n"
    if ! list_accounts; then
        read -rp "Press Enter..."
        return
    fi

    printf "\nAccount ID to edit (or Enter to cancel): "
    read -r target_id
    [ -z "$target_id" ] && { printf "Cancelled.\n"; return; }

    account_dir="$ACCOUNTS_DIR/$target_id"
    config_file="$account_dir/config.cfg"

    if [ ! -d "$account_dir" ]; then
        printf "${BLACK_RED}Account directory not found: %s${COLOR_RESET}\n" "$account_dir"
        read -rp "Press Enter..."
        return
    fi

    while true; do
        show_header
        printf "${GREENb_BLACK}Editing: ${GOLD_BLACK}%s${COLOR_RESET}\n\n" "$target_id"

        # Show current values
        server_num=$(cat "$account_dir/ur_file" 2>/dev/null || printf "?")
        lang=$(grep '^LANGUAGE=' "$config_file" 2>/dev/null | cut -d= -f2)
        allies=$(grep '^ALLIES=' "$config_file" 2>/dev/null | cut -d= -f2)
        au=$(grep '^FUNC_AUTO_UPDATE=' "$config_file" 2>/dev/null | cut -d= -f2)

        printf "  Current: server=${GOLD_BLACK}%s${COLOR_RESET}  lang=${GOLD_BLACK}%s${COLOR_RESET}  allies=${GOLD_BLACK}%s${COLOR_RESET}  auto-update=${GOLD_BLACK}%s${COLOR_RESET}\n\n" \
            "$server_num" "$lang" "$allies" "$au"

        printf "  1) Change username/password\n"
        printf "  2) Change server\n"
        printf "  3) Change language\n"
        printf "  4) Change allies (1-4)\n"
        printf "  5) Toggle auto-update (y/n)\n"
        printf "  6) Configure macro functions (relics, events, etc)\n"
        printf "  0) Back\n\n"
        printf "Select (0-6): "
        read -r edit_opt

        case "$edit_opt" in
            1)
                printf "New username: "
                read -r new_user
                collect_password
                new_pass="$password"
                if [ -n "$new_user" ] && [ -n "$new_pass" ]; then
                    save_credentials "$account_dir" "$server_num" "$new_user" "$new_pass"
                    printf "✅ Credentials updated.\n"
                else
                    printf "❌ Skipped (empty input).\n"
                fi
                read -rp "Press Enter..."
                ;;
            2)
                printf "New server (1-13): "
                read -r new_server
                if [ -n "$new_server" ]; then
                    printf "%s\n" "$new_server" > "$account_dir/ur_file"
                    # Update index.json server field
                    require_jq
                    jq --arg id "$target_id" --arg ur "$new_server" \
                        '(.accounts[] | select(.id == $id)).ur = $ur' \
                        "$INDEX_FILE" > "${INDEX_FILE}.tmp" && mv "${INDEX_FILE}.tmp" "$INDEX_FILE"
                    printf "✅ Server updated to %s.\n" "$new_server"
                fi
                read -rp "Press Enter..."
                ;;
            3)
                printf "New language (en/pt/de/es/fr): "
                read -r new_lang
                if [ -n "$new_lang" ]; then
                    sed -i "s/^LANGUAGE=.*/LANGUAGE=$new_lang/" "$config_file"
                    printf "✅ Language updated to %s.\n" "$new_lang"
                fi
                read -rp "Press Enter..."
                ;;
            4)
                printf "New allies (1-4): "
                read -r new_allies
                if [ -n "$new_allies" ]; then
                    sed -i "s/^ALLIES=.*/ALLIES=$new_allies/" "$config_file"
                    # Also clear allies files so they are re-computed on next run
                    rm -f "$account_dir/tmp/."*"/allies.txt" "$account_dir/tmp/."*"/callies.txt" 2>/dev/null
                    printf "✅ Allies updated to %s.\n" "$new_allies"
                fi
                read -rp "Press Enter..."
                ;;
            5)
                printf "Auto-update (y/n): "
                read -r new_au
                if [ -n "$new_au" ]; then
                    sed -i "s/^FUNC_AUTO_UPDATE=.*/FUNC_AUTO_UPDATE=$new_au/" "$config_file"
                    printf "✅ Auto-update set to %s.\n" "$new_au"
                fi
                read -rp "Press Enter..."
                ;;
            6)
                # Show config menu for macro functions
                config_account "$target_id" "$(grep '^LANGUAGE=' "$config_file" 2>/dev/null | cut -d= -f2 || echo 'pt')"
                read -rp "Press Enter..."
                ;;
            0) return ;;
            *) printf "Invalid option.\n"; read -rp "Press Enter..." ;;
        esac
    done
}

main() {
    case "${1:-}" in
        remove) remove_account ;;
        edit)   edit_account ;;
        list)   list_accounts ;;
        *)      setup_account ;;
    esac
}

main "$@"
