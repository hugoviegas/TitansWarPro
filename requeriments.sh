#!/bin/sh

set_account_paths() {
    suffix="$1"
    base="$HOME/twm"
    if [ -n "$ACCOUNT_ID" ]; then
        ACCOUNT_ROOT="$base/accounts/$ACCOUNT_ID"
        mkdir -p "$ACCOUNT_ROOT"
    else
        ACCOUNT_ROOT="$base"
    fi
    ACCOUNT_CONFIG="$ACCOUNT_ROOT/config.cfg"
    ACCOUNT_TMP_DIR="$ACCOUNT_ROOT/tmp"
    ACCOUNT_LOGS="$ACCOUNT_ROOT/logs"
    ACCOUNT_W3M_DIR="$ACCOUNT_ROOT/w3m"
    ACCOUNT_RUN_FILE="$ACCOUNT_ROOT/runmode_file"
    ACCOUNT_ADS_FILE="$ACCOUNT_ROOT/ads_file"
    ACCOUNT_TRANSLATIONS="$ACCOUNT_ROOT/translations.po"
    ACCOUNT_USER_AGENT_STORE="$ACCOUNT_ROOT/userAgent.txt"
    ACCOUNT_USER_AGENT_MODE="$ACCOUNT_ROOT/fileAgent.txt"

    mkdir -p "$ACCOUNT_TMP_DIR" "$ACCOUNT_LOGS" "$ACCOUNT_W3M_DIR"

    if [ -n "$suffix" ]; then
        TMP="$ACCOUNT_TMP_DIR/$suffix"
    else
        TMP="$ACCOUNT_TMP_DIR"
    fi
    mkdir -p "$TMP"

    ACCOUNT_TMP="$TMP"
    UR_FILE_PATH="$ACCOUNT_ROOT/ur_file"
    CONFIG_FILE="$ACCOUNT_CONFIG"
    W3M_HOME="$ACCOUNT_W3M_DIR"

    if [ ! -f "$ACCOUNT_RUN_FILE" ]; then
        echo "-boot" > "$ACCOUNT_RUN_FILE"
    fi

    export ACCOUNT_ROOT ACCOUNT_TMP ACCOUNT_LOGS ACCOUNT_CONFIG UR_FILE_PATH CONFIG_FILE
    export ACCOUNT_TMP_DIR ACCOUNT_W3M_DIR ACCOUNT_RUN_FILE ACCOUNT_ADS_FILE ACCOUNT_TRANSLATIONS
    export ACCOUNT_USER_AGENT_STORE ACCOUNT_USER_AGENT_MODE W3M_HOME
    unset suffix base
}


requer_func() {
    if [ -z "$UR_FILE_PATH" ]; then
        if [ -n "$ACCOUNT_ID" ]; then
            UR_FILE_PATH="$HOME/twm/accounts/$ACCOUNT_ID/ur_file"
        else
            UR_FILE_PATH="$HOME/twm/ur_file"
        fi
        export UR_FILE_PATH
    fi
    ALLIAS="_WORK"
    export ALLIAS
	# Função para exibir o menu de seleção de servidores
	display_menu() {
			clear
			printf_t "Select a server: " "${BLACK_CYAN}" "\n"
			echo "1) Brazil, Português: Furia de Titãs"
			echo "2) Deutsch: Krieg der Titanen"
			echo "3) Español: Guerra de Titanes"
			echo "4) Français: Combat des Titans"
			echo "5) Indian, English: Titan's War India"
			echo "6) Indonesian: Titan's War Indonesia"
			echo "7) Italiano: Guerra di Titani"
			echo "8) Polski: Wojna Tytanów"
			echo "9) Română: Războiul Titanilor"
			echo "10) Русский: Битва Титанов"
        if [ -f "$TMP/userAgent.txt" ]; then
            cp "$TMP/userAgent.txt" "$agent_store/userAgent.txt"
        fi
			echo "11) Srpski: Rat Titana"
			echo "12) 中文, Chinese: 泰坦之战"
			echo "13) English, Global: Titan's War"
			printf_t "C) Cancel" "${BLACK_YELLOW}" "${COLOR_RESET}" 
	}

	# Função para processar a entrada do usuário
    process_input() {
            input="$1"

            case "$input" in
                    [1-9]|10|11|12|13)
                            echo "$input" > "$UR_FILE_PATH"
							echo_t "Selected server: $input"
							return 0  # Saída para parar o loop
							;;
					'c'|'C')
							terminate_script
							;;
					*)
							echo_t "Invalid option: $input"
							sleep 0.5
							return 1  # Continua o loop
							;;
			esac
    }

	# Função para encerrar o script
	terminate_script() {
            echo_t "Terminating script..."
            pidf=$(pgrep -f "sh.*twm/play.sh")
			while [ -n "$pidf" ]; do
					kill -9 "$pidf" 2>/dev/null
					pidf=$(pgrep -f "sh.*twm/play.sh")
					sleep 1
			done
			kill -9 $$ 2>/dev/null
	}

	# Função principal do menu
	menu_loop() {
			while true; do
					display_menu
					printf "Select server number (1-13) or C to cancel: "
					read -r input
					process_input "$input" && break  # Sai do loop se a entrada for válida
			done
	}

	# Verifica se o arquivo ur_file existe e é válido
    if [ -f "$UR_FILE_PATH" ] && [ -s "$UR_FILE_PATH" ]; then
        UR=$(cat "$UR_FILE_PATH")
			echo_t "Using existing selection: $UR"
	else
			menu_loop
        UR=$(cat "$UR_FILE_PATH")  # Atualiza UR após o menu
	fi

	# Estrutura case para associar a seleção do usuário com os idiomas e configurações
	menu_language(){
	case $UR in
    (1|bra|pt)
        set_account_paths ".1"
        URL=$(echo "ZnVyaWFkZXRpdGFzLm5ldA==" | base64 -d)
        echo "1" > "$UR_FILE_PATH"
    export TZ="America/Bahia"
        set_config "LANGUAGE" "pt"
        ;;
    (2|ger|de)
        set_account_paths ".2"
        URL=$(echo "dGl0YW5lbi5tb2Jp" | base64 -d)
        echo "2" > "$UR_FILE_PATH"
    export TZ="Europe/Berlin"
        set_config "LANGUAGE" "de"
        ;;
    (3|esp|es)
        set_account_paths ".3"
        URL=$(echo "Z3VlcnJhZGV0aXRhbmVzLm5ldA==" | base64 -d)
        echo "3" > "$UR_FILE_PATH"
    export TZ="America/Cancun"
        set_config "LANGUAGE" "es"
        ;;
    (4|fran|fr)
        set_account_paths ".4"
        URL=$(echo "dGl3YXIuZnI=" | base64 -d)
        echo "4" > "$UR_FILE_PATH"
    export TZ="Europe/Paris"
        set_config "LANGUAGE" "fr"
        ;;
    (5|indi|hi)
        set_account_paths ".5"
        URL=$(echo "aW4udGl3YXIubmV0" | base64 -d)
        echo "5" > "$UR_FILE_PATH"
    export TZ="Asia/Kolkata"
        set_config "LANGUAGE" "hi"
        ;;
    (6|indo|id)
        set_account_paths ".6"
        URL=$(echo "dGl3YXItaWQubmV0" | base64 -d)
        echo "6" > "$UR_FILE_PATH"
    export TZ="Asia/Jakarta"
        set_config "LANGUAGE" "id"
        ;;
    (7|ital|it)
        set_account_paths ".7"
        URL=$(echo "Z3VlcnJhZGl0aXRhbmkubmV0" | base64 -d)
        echo "7" > "$UR_FILE_PATH"
    export TZ="Europe/Rome"
        set_config "LANGUAGE" "it"
        ;;
    (8|pol|pl)
        set_account_paths ".8"
        URL=$(echo "dGl3YXIucGw=" | base64 -d)
        echo "8" > "$UR_FILE_PATH"
    export TZ="Europe/Warsaw"
        set_config "LANGUAGE" "pl"
        ;;
    (9|rom|ro)
        set_account_paths ".9"
        URL=$(echo "dGl3YXIucm8=" | base64 -d)
        echo "9" > "$UR_FILE_PATH"
    export TZ="Europe/Bucharest"
        set_config "LANGUAGE" "ro"
        ;;
    (10|rus|ru)
        set_account_paths ".10"
        URL=$(echo "dGl3YXIucnU=" | base64 -d)
        echo "10" > "$UR_FILE_PATH"
    export TZ="Europe/Moscow"
        set_config "LANGUAGE" "ru"
        ;;
    (11|ser|sr)
        set_account_paths ".11"
        URL=$(echo "cnMudGl3YXIubmV0" | base64 -d)
        echo "11" > "$UR_FILE_PATH"
    export TZ="Europe/Belgrade"
        set_config "LANGUAGE" "sr"
        ;;
    (12|chi|zh)
        set_account_paths ".12"
        URL=$(echo "Y24udGl3YXIubmV0" | base64 -d)
        echo "12" > "$UR_FILE_PATH"
    export TZ="Asia/Shanghai"
        set_config "LANGUAGE" "zh"
        ;;
    (13|eng|en)
        set_account_paths ".13"
        URL=$(echo "dGl3YXIubmV0" | base64 -d)
        echo "13" > "$UR_FILE_PATH"
    export TZ="Europe/London"
        set_config "LANGUAGE" "en"
        ;;
    (*)
        clear
        LANGUAGE=$(get_config "LANGUAGE")
        if [ -n "$UR" ]; then
            echo_t "\n Invalid option: ${UR}"
            kill -9 $$
        else
            echo_t " Time exceeded!"
        fi
        ;;
	esac

	clear
	}
	menu_language
	# Check if URL is set; if not, exit the script
	if [ -z "$URL" ]; then
		exit 1
	fi

	# Create the temporary directory if it doesn't exist
	mkdir -p "$TMP"

	# Change to the temporary directory
	cd "$TMP" || exit 1

	# Reset and clear the terminal screen
	reset
	clear

random_ua() {
 total_agents=$(wc -l < "$TMP/userAgent.txt")
 random_agent=$(awk -v min=1 -v max="$total_agents" 'BEGIN{srand(); print int(min+rand()*(max-min+1))}')
 vUserAgent=$(sed -n "${random_agent}p" "$TMP/userAgent.txt")
export vUserAgent
}

user_agent() {
    cd "$TMP" || exit 1
    clear

    # Exibe opções de configuração de User-Agent
    echo_t "Simulate your real or random device."
    echo_t "1) Manual"
    echo_t "2) Automatic"

    agent_store="${ACCOUNT_ROOT:-$HOME/twm}"
    agent_mode_file="${ACCOUNT_USER_AGENT_MODE:-$agent_store/fileAgent.txt}"
    agent_library="${ACCOUNT_USER_AGENT_STORE:-$agent_store/userAgent.txt}"
    fallback_library="$HOME/twm/userAgent.txt"

    # Verifica se o arquivo de User-Agent já existe e tem conteúdo
    if [ -f "$agent_mode_file" ] && [ -s "$agent_mode_file" ]; then
        UA=$(cat "$agent_mode_file")
    else
        echo_t "Set up User-Agent [1 to 2]:"
        read -r UA
    fi

    case $UA in
        0)
            clear
            echo "0" > "$agent_mode_file"

            if [ ! -e "$TMP/userAgent.txt" ] || [ -z "$UA" ]; then
                if [ -f "$agent_library" ] && [ -s "$agent_library" ]; then
                    cat "$agent_library" > "$TMP/userAgent.txt"
                else
                    cat "$fallback_library" > "$TMP/userAgent.txt"
                fi
            else
                random_ua
            fi
            ;;

        1)
            clear
            xdg-open "$(echo "aHR0cHM6Ly93d3cud2hhdHNteXVhLmluZm8=" | base64 -d)" >/dev/null 2>&1
            echo "0" > "$agent_mode_file"
            read -r UA
            echo "$UA" > "$TMP/userAgent.txt"

            if [ ! -e "$TMP/userAgent.txt" ] || [ -z "$UA" ]; then
                echo_t " ..."
                if [ -f "$agent_library" ] && [ -s "$agent_library" ]; then
                    cat "$agent_library" > "$TMP/userAgent.txt"
                else
                    cat "$fallback_library" > "$TMP/userAgent.txt"
                fi
            else
                random_ua
            fi
            ;;

        2)
            echo_t " ..."
            if [ -f "$agent_library" ] && [ -s "$agent_library" ]; then
                cat "$agent_library" > "$TMP/userAgent.txt"
            else
                cat "$fallback_library" > "$TMP/userAgent.txt"
            fi
            echo "0" > "$agent_mode_file"

            if [ -e "$TMP/userAgent.txt" ]; then
                random_ua
            fi

            echo_t "Automatic User Agent selected."
            sleep 2s
            ;;

        *)
            clear
            echo_t "Invalid option: $UA"
            if [ -n "$UA" ]; then
                echo_t "Invalid option: $UA"
                kill -9 $$
            else
                echo_t "Time exceeded!"
            fi
            ;;
    esac

    if [ -f "$TMP/userAgent.txt" ]; then
        cp "$TMP/userAgent.txt" "$agent_library"
    fi

    unset UA agent_store agent_library agent_mode_file fallback_library
}

size=0
if [ -e "$TMP/userAgent.txt" ]; then
    size=$(wc -c < "$TMP/userAgent.txt")
fi

if [ ! -e "$TMP/userAgent.txt" ] || [ "$size" -lt 10 ] || [ "$size" -gt 65 ]; then
    # Prompt for user agent when the current file is missing or has an invalid size.
    user_agent
else
    # Display a random user agent from the existing list.
    echo_t "User-Agent: $(shuf -n 1 "$TMP"/userAgent.txt)" "${BLACK_PINK}" "${COLOR_RESET}"
fi

sed -i 's/^M$//g' "$TMP/userAgent.txt" >/dev/null 2>&1 # Remove carriage return characters (DOS)
sed -i 's/\x0D$//g' "$TMP/userAgent.txt" >/dev/null 2>&1 # Another method to ensure line endings are clean
unset size
}