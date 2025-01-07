#!/bin/sh

requer_func() {
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
			echo "11) Srpski: Rat Titana"
			echo "12) 中文, Chinese: 泰坦之战"
			echo "13) English, Global: Titan's War"
			printf_t "C) Cancel" "${BLACK_YELLOW}" "${COLOR_RESET}" 
	}

	# Função para processar a entrada do usuário
	process_input() {
			local input="$1"

			case "$input" in
					[1-9]|10|11|12|13)
							echo "$input" > "$HOME/twm/ur_file"
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
			local pidf
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
	if [ -f "$HOME/twm/ur_file" ] && [ -s "$HOME/twm/ur_file" ]; then
			UR=$(cat "$HOME/twm/ur_file")
			echo_t "Using existing selection: $UR"
	else
			menu_loop
			UR=$(cat "$HOME/twm/ur_file")  # Atualiza UR após o menu
	fi

	# Estrutura case para associar a seleção do usuário com os idiomas e configurações
	echo "You have selectet $UR"
	case $UR in
    (1|bra|pt)
        URL=$(echo "ZnVyaWFkZXRpdGFzLm5ldA==" | base64 -d)
        echo "1" > "$HOME/twm/ur_file"
        TMP="$HOME/twm/.1"
        export TZ="America/Bahia"; ALLIAS="_WORK"
        set_config "LANGUAGE" "pt"
        ;;
    (2|ger|de)
        URL=$(echo "dGl0YW5lbi5tb2Jp" | base64 -d)
        echo "2" > "$HOME/twm/ur_file"
        TMP="$HOME/twm/.2"
        export TZ="Europe/Berlin"; ALLIAS="_WORK"
        set_config "LANGUAGE" "de"
        ;;
    (3|esp|es)
        URL=$(echo "Z3VlcnJhZGV0aXRhbmVzLm5ldA==" | base64 -d)
        echo "3" > "$HOME/twm/ur_file"
        TMP="$HOME/twm/.3"
        export TZ="America/Cancun"; ALLIAS="_WORK"
        set_config "LANGUAGE" "es"
        ;;
    (4|fran|fr)
        URL=$(echo "dGl3YXIuZnI=" | base64 -d)
        echo "4" > "$HOME/twm/ur_file"
        TMP="$HOME/twm/.4"
        export TZ="Europe/Paris"; ALLIAS="_WORK"
        set_config "LANGUAGE" "fr"
        ;;
    (5|indi|hi)
        URL=$(echo "aW4udGl3YXIubmV0" | base64 -d)
        echo "5" > "$HOME/twm/ur_file"
        TMP="$HOME/twm/.5"
        export TZ="Asia/Kolkata"; ALLIAS="_WORK"
        set_config "LANGUAGE" "hi"
        ;;
    (6|indo|id)
        URL=$(echo "dGl3YXItaWQubmV0" | base64 -d)
        echo "6" > "$HOME/twm/ur_file"
        TMP="$HOME/twm/.6"
        export TZ="Asia/Jakarta"; ALLIAS="_WORK"
        set_config "LANGUAGE" "id"
        ;;
    (7|ital|it)
        URL=$(echo "Z3VlcnJhZGl0aXRhbmkubmV0" | base64 -d)
        echo "7" > "$HOME/twm/ur_file"
        TMP="$HOME/twm/.7"
        export TZ="Europe/Rome"; ALLIAS="_WORK"
        set_config "LANGUAGE" "it"
        ;;
    (8|pol|pl)
        URL=$(echo "dGl3YXIucGw=" | base64 -d)
        echo "8" > "$HOME/twm/ur_file"
        TMP="$HOME/twm/.8"
        export TZ="Europe/Warsaw"; ALLIAS="_WORK"
        set_config "LANGUAGE" "pl"
        ;;
    (9|rom|ro)
        URL=$(echo "dGl3YXIucm8=" | base64 -d)
        echo "9" > "$HOME/twm/ur_file"
        TMP="$HOME/twm/.9"
        export TZ="Europe/Bucharest"; ALLIAS="_WORK"
        set_config "LANGUAGE" "ro"
        ;;
    (10|rus|ru)
        URL=$(echo "dGl3YXIucnU=" | base64 -d)
        echo "10" > "$HOME/twm/ur_file"
        TMP="$HOME/twm/.10"
        export TZ="Europe/Moscow"; ALLIAS="_WORK"
        set_config "LANGUAGE" "ru"
        ;;
    (11|ser|sr)
        URL=$(echo "cnMudGl3YXIubmV0" | base64 -d)
        echo "11" > "$HOME/twm/ur_file"
        TMP="$HOME/twm/.11"
        export TZ="Europe/Belgrade"; ALLIAS="_WORK"
        set_config "LANGUAGE" "sr"
        ;;
    (12|chi|zh)
        URL=$(echo "Y24udGl3YXIubmV0" | base64 -d)
        echo "12" > "$HOME/twm/ur_file"
        TMP="$HOME/twm/.12"
        export TZ="Asia/Shanghai"; ALLIAS="_WORK"
        set_config "LANGUAGE" "zh"
        ;;
    (13|eng|en)
        URL=$(echo "dGl3YXIubmV0" | base64 -d)
        echo "13" > "$HOME/twm/ur_file"
        TMP="$HOME/twm/.13"
        export TZ="Europe/London"; ALLIAS="_WORK"
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

    twm_dir="twm"  # Define twm_dir variable

    # Verifica se o arquivo de User-Agent já existe e tem conteúdo
    if [ -f "$HOME/$twm_dir/fileAgent.txt" ] && [ -s "$HOME/$twm_dir/fileAgent.txt" ]; then
        UA=$(cat "$HOME/$twm_dir/fileAgent.txt")
    else
        echo_t "Set up User-Agent [1 to 2]:"
        read -r UA
    fi

    case $UA in
        0)
            clear
            echo "0" > "$HOME/$twm_dir/fileAgent.txt"

            if [ ! -e "$TMP/userAgent.txt" ] || [ -z "$UA" ]; then
                cat "$HOME/$twm_dir/userAgent.txt" > "$TMP/userAgent.txt"
            else
                random_ua
            fi
            ;;

        1)
            clear
            xdg-open "$(echo "aHR0cHM6Ly93d3cud2hhdHNteXVhLmluZm8=" | base64 -d)" >/dev/null 2>&1
            echo "0" > "$HOME/$twm_dir/fileAgent.txt"
            read -r UA
            echo "$UA" > "$TMP/userAgent.txt"

            if [ ! -e "$TMP/userAgent.txt" ] || [ -z "$UA" ]; then
                echo_t " ..."
                cat "$HOME/$twm_dir/userAgent.txt" > "$TMP/userAgent.txt"
            else
                random_ua
            fi
            ;;

        2)
            echo_t " ..."
            cat "$HOME/$twm_dir/userAgent.txt" > "$TMP/userAgent.txt"
            echo "0" > "$HOME/$twm_dir/fileAgent.txt"

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

    unset UA
}

  if [ ! -e "$TMP/userAgent.txt" ] || [ "$(wc -c < "$TMP/userAgent.txt")" -lt 10 ] || [ "$(wc -c < "$TMP/userAgent.txt")" -gt 65 ]; then
	# Check if the user agent file is missing or has an invalid size; if so, prompt for a new one.
		if [ ! -e "$TMP/userAgent.txt" ] || [ $(cat "$TMP/userAgent.txt" | wc -c) -lt 10 ] || [ $(cat "$TMP/userAgent.txt" | wc -c) -gt 65 ]; then
			user_agent # Call function to set up user agent if conditions are met.
		else
		# Display a random user agent from the existing list.
			echo_t "User-Agent: $(shuf -n 1 "$TMP"/userAgent.txt)" "${BLACK_PINK}" "${COLOR_RESET}"
		fi
		sed -i 's/^M$//g' "$TMP/userAgent.txt" >/dev/null 2>&1 # Remove carriage return characters (DOS)
		sed -i 's/\x0D$//g' "$TMP/userAgent.txt" >/dev/null 2>&1 # Another method to ensure line endings are clean
		sed -i 's/^M$//g' "$TMP/userAgent.txt" &>/dev/null # Remove carriage return characters (DOS)
		sed -i 's/\x0D$//g' "$TMP/userAgent.txt" &>/dev/null # Another method to ensure line endings are clean
	fi
}