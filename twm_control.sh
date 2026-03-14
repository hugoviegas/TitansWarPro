#!/bin/bash
# Main control panel for TWM multi-account system

BASE_DIR="${HOME}/twm"
ACCOUNTS_DIR="${BASE_DIR}/accounts"
INDEX_FILE="${ACCOUNTS_DIR}/index.json"

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

display_menu() {
    colors
    clear

    printf "${BLACK_CYAN}"
    printf "╔════════════════════════════════════════════════════╗\n"
    printf "║                                                    ║\n"
    printf "║          🐉 TITANS WAR - MULTI-RUNNER CONTROL 🐉   ║\n"
    printf "║                                                    ║\n"
    printf "╚════════════════════════════════════════════════════╝\n"
    printf "${COLOR_RESET}\n"

    printf "${GREENb_BLACK}ACCOUNT MANAGEMENT${COLOR_RESET}\n"
    printf "  1) Start all active accounts\n"
    printf "  2) Stop all accounts\n"
    printf "  3) Restart all accounts\n"
    printf "  4) View account status\n\n"

    printf "${GREENb_BLACK}MONITORING${COLOR_RESET}\n"
    printf "  5) Interactive monitor (switch between accounts)\n"
    printf "  6) View specific account logs\n"
    printf "  7) View all accounts status table\n\n"

    printf "${GREENb_BLACK}SETUP & CONFIG${COLOR_RESET}\n"
    printf "  8) Add new account\n"
    printf "  9) Edit existing account\n"
    printf "  R) Remove account\n\n"

    printf "${GREENb_BLACK}HELP & INFO${COLOR_RESET}\n"
    printf "  H) Show monitoring guide\n"
    printf "  0) Exit\n\n"

    printf "${GOLD_BLACK}Select option:${COLOR_RESET} "
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

main() {
    while true; do
        display_menu
        read -r option

        case "$option" in
            1)
                clear
                printf "${BLACK_CYAN}Starting all active accounts...${COLOR_RESET}\n\n"
                cd "$BASE_DIR" && ./multi_runner.sh start
                read -rp "Press Enter to continue..."
                ;;
            2)
                clear
                printf "${BLACK_CYAN}Stopping all accounts...${COLOR_RESET}\n\n"
                cd "$BASE_DIR" && ./multi_runner.sh stop
                read -rp "Press Enter to continue..."
                ;;
            3)
                clear
                printf "${BLACK_CYAN}Restarting all accounts...${COLOR_RESET}\n\n"
                cd "$BASE_DIR" && ./multi_runner.sh restart
                read -rp "Press Enter to continue..."
                ;;
            4)
                clear
                printf "${BLACK_CYAN}Account Status:${COLOR_RESET}\n\n"
                cd "$BASE_DIR" && ./multi_runner.sh status
                read -rp "Press Enter to continue..."
                ;;
            5)
                cd "$BASE_DIR" && ./twm_monitor.sh
                ;;
            6)
                cd "$BASE_DIR" && ./twm_view.sh
                ;;
            7)
                clear
                printf "${BLACK_CYAN}All Accounts Status:${COLOR_RESET}\n\n"
                cd "$BASE_DIR" && ./twm_monitor.sh status
                read -rp "Press Enter to continue..."
                ;;
            8)
                add_account_interactive
                ;;
            9)
                edit_account_interactive
                ;;
            r|R)
                remove_account_interactive
                ;;
            h|H)
                show_guide
                ;;
            0)
                clear
                printf "${GREENb_BLACK}Goodbye!${COLOR_RESET}\n"
                exit 0
                ;;
            *)
                printf "${RED_BLACK}Invalid option. Try again.${COLOR_RESET}\n"
                read -rp "Press Enter..."
                ;;
        esac
    done
}

main "$@"
