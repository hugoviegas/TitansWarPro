#!/bin/bash
# Main control panel for TWM multi-account system

BASE_DIR="${HOME}/twm"
ACCOUNTS_DIR="${BASE_DIR}/accounts"
INDEX_FILE="${ACCOUNTS_DIR}/index.json"
CONTROL_CFG="${BASE_DIR}/control.cfg"

# Load saved language preference (overrides env default)
[ -f "$CONTROL_CFG" ] && . "$CONTROL_CFG" 2>/dev/null
LANGUAGE="${LANGUAGE:-en}"

colors() {
    BLACK_BLACK='\033[00;30m'
    BLACK_CYAN='\033[01;36m\033[01;07m'
    BLACK_YELLOW='\033[00;33m\033[01;07m'
    BLUE_BLACK='\033[0;34m'
    COLOR_RESET='\033[00m'
    GOLD_BLACK='\033[0;33m'
    GREEN_BLACK='\033[32m'
    GREENb_BLACK='\033[1;32m'
    RED_BLACK='\033[0;31m'
    WHITE_BLACK='\033[37m'
}

# Simple translation function (key-based)
translate() {
    local key="$1"

    case "$LANGUAGE" in
        pt)
            case "$key" in
                "menu_title") echo "🐉 TITANS WAR - CONTROLE MULTI-CONTA 🐉" ;;
                "account_mgmt") echo "GERENCIAMENTO DE CONTAS" ;;
                "monitoring") echo "MONITORAMENTO" ;;
                "setup_config") echo "CONFIGURAÇÃO & SETUP" ;;
                "help_info") echo "AJUDA & INFO" ;;
                "start_all") echo "Iniciar todas as contas ativas" ;;
                "stop_all") echo "Parar todas as contas" ;;
                "restart_all") echo "Reiniciar todas as contas" ;;
                "view_status") echo "Visualizar status das contas" ;;
                "start_single") echo "Iniciar uma conta específica" ;;
                "stop_single") echo "Parar uma conta específica" ;;
                "interactive_monitor") echo "Monitor interativo (alternar entre contas)" ;;
                "view_account_logs") echo "Visualizar logs de uma conta" ;;
                "add_account") echo "Adicionar nova conta" ;;
                "edit_account") echo "Editar conta existente" ;;
                "remove_account") echo "Remover conta" ;;
                "show_guide") echo "Mostrar guia de monitoramento" ;;
                "exit") echo "Sair" ;;
                "select_option") echo "Selecione uma opção" ;;
                "invalid_option") echo "Opção inválida. Tente novamente." ;;
                "starting_accounts") echo "Iniciando todas as contas ativas..." ;;
                "stopping_accounts") echo "Parando todas as contas..." ;;
                "restarting_accounts") echo "Reiniciando todas as contas..." ;;
                "account_status") echo "Status das Contas:" ;;
                "select_account") echo "Selecione uma conta:" ;;
                "which_account_stop") echo "Qual conta deseja parar?" ;;
                "goodbye") echo "Até logo!" ;;
                "change_language") echo "Alterar idioma (atual: PT)" ;;
                "language_saved") echo "Idioma salvo:" ;;
                *) echo "$key" ;;
            esac
            ;;
        *)  # English default
            case "$key" in
                "menu_title") echo "🐉 TITANS WAR - MULTI-RUNNER CONTROL 🐉" ;;
                "account_mgmt") echo "ACCOUNT MANAGEMENT" ;;
                "monitoring") echo "MONITORING" ;;
                "setup_config") echo "SETUP & CONFIG" ;;
                "help_info") echo "HELP & INFO" ;;
                "start_all") echo "Start all active accounts" ;;
                "stop_all") echo "Stop all accounts" ;;
                "restart_all") echo "Restart all accounts" ;;
                "view_status") echo "View account status" ;;
                "start_single") echo "Start a specific account" ;;
                "stop_single") echo "Stop a specific account" ;;
                "interactive_monitor") echo "Interactive monitor (switch between accounts)" ;;
                "view_account_logs") echo "View specific account logs" ;;
                "add_account") echo "Add new account" ;;
                "edit_account") echo "Edit existing account" ;;
                "remove_account") echo "Remove account" ;;
                "show_guide") echo "Show monitoring guide" ;;
                "exit") echo "Exit" ;;
                "select_option") echo "Select option" ;;
                "invalid_option") echo "Invalid option. Try again." ;;
                "starting_accounts") echo "Starting all active accounts..." ;;
                "stopping_accounts") echo "Stopping all accounts..." ;;
                "restarting_accounts") echo "Restarting all accounts..." ;;
                "account_status") echo "Account Status:" ;;
                "select_account") echo "Select an account:" ;;
                "which_account_stop") echo "Which account to stop?" ;;
                "goodbye") echo "Goodbye!" ;;
                "change_language") echo "Change language (current: EN)" ;;
                "language_saved") echo "Language saved:" ;;
                *) echo "$key" ;;
            esac
            ;;
    esac
}

# Get list of active accounts
get_accounts() {
    if [ -f "$INDEX_FILE" ]; then
        jq -r '.accounts[] | select((.active // true) == true) | .id' "$INDEX_FILE" 2>/dev/null
    fi
}

# Interactive account selection
select_account() {
    local prompt="$1"
    local accounts
    accounts=$(get_accounts)

    if [ -z "$accounts" ]; then
        printf "${RED_BLACK}No active accounts found.${COLOR_RESET}\n"
        return 1
    fi

    local count=0
    declare -a account_ids

    printf "\n${GREENb_BLACK}$(translate "$prompt")${COLOR_RESET}\n"

    while IFS= read -r id; do
        count=$((count + 1))
        account_ids[$count]="$id"
        printf "  %d) %s\n" "$count" "$id"
    done <<< "$accounts"

    printf "\n${GOLD_BLACK}Choose [1-$count]:${COLOR_RESET} "
    read -r selection

    if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt "$count" ]; then
        printf "${RED_BLACK}Invalid selection.${COLOR_RESET}\n"
        return 1
    fi

    echo "${account_ids[$selection]}"
}

# First-time setup: ask language once and save to control.cfg
first_run_setup() {
    [ -f "$CONTROL_CFG" ] && return   # Already configured, skip
    colors
    clear
    printf "${BLACK_CYAN}╔═══════════════════════════════════════════╗${COLOR_RESET}\n"
    printf "${BLACK_CYAN}║   🐉 TITANS WAR PRO — PRIMEIRO ACESSO    ║${COLOR_RESET}\n"
    printf "${BLACK_CYAN}╚═══════════════════════════════════════════╝${COLOR_RESET}\n\n"
    printf "Escolha o idioma / Choose language:\n\n"
    printf "  1) Português  (padrão / default)\n"
    printf "  2) English\n\n"
    printf "Selecione [1-2]: "
    read -r _lang_sel
    case "$_lang_sel" in
        2) LANGUAGE="en" ;;
        *) LANGUAGE="pt" ;;
    esac
    printf 'LANGUAGE=%s\n' "$LANGUAGE" > "$CONTROL_CFG"
    printf "\n${GREENb_BLACK}✅  Idioma salvo / Language saved: ${GOLD_BLACK}%s${COLOR_RESET}\n\n" "$LANGUAGE"
    sleep 1
}

# Launch interactive monitor directly
launch_monitor() {
    exec "$BASE_DIR/twm_monitor.sh"
}

display_menu() {
    colors
    clear

    printf "${BLACK_CYAN}"
    printf "╔════════════════════════════════════════════════════╗\n"
    printf "║                                                    ║\n"
    printf "║          $(translate "menu_title")\n"
    printf "║                                                    ║\n"
    printf "╚════════════════════════════════════════════════════╝\n"
    printf "${COLOR_RESET}\n"

    printf "${GREENb_BLACK}$(translate "account_mgmt")${COLOR_RESET}\n"
    printf "  1) $(translate "start_all")\n"
    printf "  2) $(translate "start_single")\n"
    printf "  3) $(translate "stop_all")\n"
    printf "  4) $(translate "stop_single")\n"
    printf "  5) $(translate "restart_all")\n"
    printf "  6) $(translate "view_status")\n\n"

    printf "${GREENb_BLACK}$(translate "monitoring")${COLOR_RESET}\n"
    printf "  7) $(translate "interactive_monitor")\n"
    printf "  8) $(translate "view_account_logs")\n\n"

    printf "${GREENb_BLACK}$(translate "setup_config")${COLOR_RESET}\n"
    printf "  9) $(translate "add_account")\n"
    printf "  A) $(translate "edit_account")\n"
    printf "  R) $(translate "remove_account")\n"
    printf "  G) $(translate "change_language")\n\n"

    printf "${GREENb_BLACK}$(translate "help_info")${COLOR_RESET}\n"
    printf "  H) $(translate "show_guide")\n"
    printf "  0) $(translate "exit")\n\n"

    printf "${GOLD_BLACK}$(translate "select_option"):${COLOR_RESET} "
}

show_guide() {
    clear
    printf "${BLACK_CYAN}"
    printf "╔═══════════════════════════════════════════════════════════════╗\n"
    printf "║  📖 MONITORING GUIDE                                          ║\n"
    printf "╚═══════════════════════════════════════════════════════════════╝\n"
    printf "${COLOR_RESET}\n"

    less -R <<'EOF'
VIEWING LOGS:

1. Interactive Monitor (Recommended):
   ./twm_monitor.sh
   - Navigate with [N]ext, [P]revious, [L]ist
   - Select account by number in list view
   - Real-time status and logs

2. Simple Log Viewer:
   ./twm_view.sh
   - Interactive menu or specific account ID
   - Continuous log streaming

3. Status Tables:
   ./multi_runner.sh status
   ./twm_monitor.sh status

RUNNING MULTIPLE ACCOUNTS:

1. Configure accounts/index.json with multiple entries
2. Run: ./multi_runner.sh start
3. Monitor with: ./twm_monitor.sh

Each account gets isolated:
- Cookies: ~/twm/accounts/<ID>/w3m/
- Temp files: ~/twm/accounts/<ID>/tmp/
- Logs: ~/twm/accounts/<ID>/logs/

QUICK COMMANDS:

  ./multi_runner.sh start             # Start all active accounts
  ./multi_runner.sh stop A1 A2        # Stop specific accounts
  ./multi_runner.sh status            # Show status table
  ./twm_monitor.sh                    # Interactive monitor
  ./twm_view.sh A1                    # View logs for A1
  tail -f ~/twm/accounts/A1/logs/twm.log  # Direct log access

Press 'q' to exit this help.
EOF
}

add_account_interactive() {
    cd "$BASE_DIR" && ./twm_setup.sh || {
        printf "${RED_BLACK}Setup wizard failed or was cancelled.${COLOR_RESET}\n"
        read -rp "Press Enter..."
    }
}

edit_account_interactive() {
    cd "$BASE_DIR" && ./twm_setup.sh edit || {
        printf "${RED_BLACK}Edit wizard failed or was cancelled.${COLOR_RESET}\n"
        read -rp "Press Enter..."
    }
}

remove_account_interactive() {
    cd "$BASE_DIR" && ./twm_setup.sh remove || {
        printf "${RED_BLACK}Remove failed or was cancelled.${COLOR_RESET}\n"
        read -rp "Press Enter..."
    }
}

change_language_interactive() {
    clear
    printf "${GREENb_BLACK}Language / Idioma${COLOR_RESET}\n\n"
    printf "  1) English (en)\n"
    printf "  2) Português (pt)\n\n"
    printf "${GOLD_BLACK}Select [1-2]:${COLOR_RESET} "
    read -r sel
    local new_lang=""
    case "$sel" in
        1) new_lang="en" ;;
        2) new_lang="pt" ;;
        *) printf "${RED_BLACK}Invalid selection.${COLOR_RESET}\n"
           read -rp "Press Enter..."
           return ;;
    esac
    # Save to control.cfg so it persists across sessions
    printf 'LANGUAGE=%s\n' "$new_lang" > "$CONTROL_CFG"
    LANGUAGE="$new_lang"
    printf "${GREENb_BLACK}$(translate "language_saved") %s${COLOR_RESET}\n" "$new_lang"
    sleep 1
}

main() {
    colors

    # CLI shortcut arguments — allows twmstart / twmstop / twmview shortcuts
    case "${1:-}" in
        start)
            first_run_setup
            clear
            printf "${BLACK_CYAN}$(translate "starting_accounts")${COLOR_RESET}\n\n"
            cd "$BASE_DIR" && ./multi_runner.sh start
            sleep 2
            launch_monitor
            ;;
        stop)
            clear
            printf "${BLACK_CYAN}$(translate "stopping_accounts")${COLOR_RESET}\n\n"
            cd "$BASE_DIR" && ./multi_runner.sh stop
            printf "\n${GREENb_BLACK}All accounts stopped.${COLOR_RESET}\n"
            exit 0
            ;;
        view)
            launch_monitor
            ;;
        *)
            # Interactive menu mode — show first-run language prompt if needed
            first_run_setup
            ;;
    esac

    while true; do
        display_menu
        read -r option

        case "$option" in
            1)
                clear
                printf "${BLACK_CYAN}$(translate "starting_accounts")${COLOR_RESET}\n\n"
                cd "$BASE_DIR" && ./multi_runner.sh start
                sleep 2
                # Auto-switch to live monitor after launching all accounts
                launch_monitor
                ;;
            2)
                account=$(select_account "select_account") || continue
                clear
                printf "${BLACK_CYAN}Starting account $account...${COLOR_RESET}\n\n"
                cd "$BASE_DIR" && ./multi_runner.sh start "$account"
                read -rp "Press Enter to continue..."
                ;;
            3)
                clear
                printf "${BLACK_CYAN}$(translate "stopping_accounts")${COLOR_RESET}\n\n"
                cd "$BASE_DIR" && ./multi_runner.sh stop
                read -rp "Press Enter to continue..."
                ;;
            4)
                account=$(select_account "which_account_stop") || continue
                clear
                printf "${BLACK_CYAN}Stopping account $account...${COLOR_RESET}\n\n"
                cd "$BASE_DIR" && ./multi_runner.sh stop "$account"
                read -rp "Press Enter to continue..."
                ;;
            5)
                clear
                printf "${BLACK_CYAN}$(translate "restarting_accounts")${COLOR_RESET}\n\n"
                cd "$BASE_DIR" && ./multi_runner.sh restart
                read -rp "Press Enter to continue..."
                ;;
            6)
                clear
                printf "${BLACK_CYAN}$(translate "account_status")${COLOR_RESET}\n\n"
                cd "$BASE_DIR" && ./multi_runner.sh status
                read -rp "Press Enter to continue..."
                ;;
            7)
                cd "$BASE_DIR" && ./twm_monitor.sh
                ;;
            8)
                cd "$BASE_DIR" && ./twm_view.sh
                ;;
            9)
                add_account_interactive
                ;;
            a|A)
                edit_account_interactive
                ;;
            r|R)
                remove_account_interactive
                ;;
            g|G)
                change_language_interactive
                ;;
            h|H)
                show_guide
                ;;
            0)
                clear
                printf "${GREENb_BLACK}$(translate "goodbye")${COLOR_RESET}\n"
                exit 0
                ;;
            *)
                printf "${RED_BLACK}$(translate "invalid_option")${COLOR_RESET}\n"
                read -rp "Press Enter..."
                ;;
        esac
    done
}

main "$@"

