# shellcheck disable=SC2154
members_allies() {
    cd "$TMP" || exit
    echo "" >> allies.txt
    clan_id
    echo "" > callies.txt

    if [ -n "$CLD" ]; then
        echo_t "Updating clan members into allies" "$BLACK_CYAN" "$COLOR_RESET" "before" ""
        
        for num in $(seq 5 -1 1); do
            echo_t "/clan/${CLD}/${num}" "$PURPLEis_BLACK" "$COLOR_RESET" "before" ""
            (
                w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}/clan/${CLD}/${num}" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" | grep -o -E "[/]>([[:upper:]][[:lower:]]{0,15}[[:space:]]{0,1}[[:upper:]]{0,1}[[:lower:]]{0,14},[[:space:]])<s" | awk -F"[>]" '{print $2}' | awk -F"[,]" '{print $1}' | sed 's,\ ,_,' >> allies.txt
            ) </dev/null &>/dev/null &
            time_exit 17
        done
        
        sort -u allies.txt -o allies.txt
    fi

    echo_t "Allies for Coliseum and King of the Immortals: " "$BLACK_CYAN" "$COLOR_RESET" "before" "🧱 👑"
    cat allies.txt

    echo_t "Wait to continue. " "$BLACK_CYAN" "$COLOR_RESET" "after" "👈"
    sleep 2
}

id_allies() {
    printf_t "Looking for allies on friends list" "$BLACK_CYAN" "$COLOR_RESET" "after" "🔎"
    cd "$TMP" || exit
    printf_t "/mail/friends" "$PURPLEis_BLACK" "$COLOR_RESET" "before" ""

    (
        w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}/mail/friends" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" > "$TMP"/SRC
    ) </dev/null &>/dev/null &
    time_exit 17

    NPG=$(cat "$TMP"/SRC | grep -o -E '/mail/friends/([0-9]{0,4})[^[:alnum:]]{4}62[^[:alnum:]]{3}62[^[:alnum:]]' | sed 's/\/mail\/friends\/\([0-9]\{0,4\}\).*/\1/') > tmp.txt
    
    if [ -z "$NPG" ]; then
        printf_t "/mail/friends" "$PURPLEis_BLACK" "$COLOR_RESET" "before" ""
        (
            w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}/mail/friends" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" | sed 's,/user/,\n/user/,g' | grep '/user/' | grep '/mail/' | cut -d\< -f1 >> tmp.txt
        ) </dev/null &>/dev/null &
        time_exit 17
    fi

    NPG=$(cat "$TMP"/SRC | grep -o -E '/mail/friends/([0-9]{0,4})[^[:alnum:]]{4}62[^[:alnum:]]{3}62[^[:alnum:]]' | sed 's/\/mail\/friends\/\([0-9]\{0,4\}\).*/\1/') > tmp.txt

    if [ -z "$NPG" ]; then
        echo_t "/mail/friends" "$PURPLEis_BLACK" "$COLOR_RESET" "before" ""
        (
            w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}/mail/friends" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" | sed 's,/user/,\n/user/,g' | grep '/user/' | grep '/mail/' | cut -d\< -f1 >> tmp.txt
        ) </dev/null &>/dev/null &
        time_exit 17
    else
        for num in $(seq "$NPG" -1 1); do
            echo_t "Friends list page ${num}" "$BLACK_CYAN" "$COLOR_RESET" "before" ""
            (
                w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}/mail/friends/${num}" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" | sed 's,/user/,\n/user/,g' | grep '/user/' | grep '/mail/' | cut -d\< -f1 >> tmp.txt
            ) </dev/null &>/dev/null &
            time_exit 17
        done
    fi

    sort -u tmp.txt -o tmp.txt  # Sort and remove duplicates from friend IDs
    cat tmp.txt | cut -d\> -f2 | sed 's,\ ,_,' > allies.txt  # Format and save to allies.txt
}

clan_allies() {
    clan_id  # Get the current clan ID

    if [ -n "$CLD" ]; then
        cd "$TMP" || exit
        echo "" > callies.txt
        cut -d/ -f3 tmp.txt > ids.txt  # Extrai IDs diretamente para ids.txt

        printf_t "Clan allies by Leader/Deputy on friends list" "$BLACK_CYAN" "$COLOR_RESET" "before" ""
        Lnl=$(wc -l < ids.txt)  # Contar linhas em ids.txt
        ts=0
        
        for num in $(seq "$Lnl" -1 1); do
            IDN=$(sed -n "${num}p" ids.txt)  # Pega a ID correspondente
            if [ -n "$IDN" ]; then
                echo_t "/user/${IDN}" "$PURPLEis_BLACK" "$COLOR_RESET" "before" ""

                (
                    w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}/user/${IDN}" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" > "$TMP"/SRC
                ) </dev/null &>/dev/null &
                time_exit 17
                
                LEADPU=$(sed 's,/clan/,\n/clan/,g' "$TMP"/SRC | grep -E "</a>, <span class='blue'|</a>, <span class='green'" | cut -d\< -f1 | cut -d\> -f2)
                alCLAN=$(grep -E -o '/clan/[0-9]{1,3}' "$TMP"/SRC | tail -n1)
                
                printf_t "${LEADPU} - ${alCLAN}" "$PURPLEis_BLACK" "$COLOR_RESET" "before" ""
                
                if [ -n "$LEADPU" ]; then
                    ts=$((ts + 1))  # Increment ally count
                    echo -e "$LEADPU" | sed 's,\ ,_,' >> callies.txt  # Save ally name formatted with underscores

                    echo_t "${ts}. Ally ${LEADPU} ${alCLAN} added." "$BLACK_CYAN" "$COLOR_RESET" "before" ""
                    sort -u callies.txt -o callies.txt  # Sort and remove duplicates in callies.txt
                fi
                
                sleep 1s  # Brief pause between requests to avoid overwhelming the server
            fi
        done
    fi
}


conf_allies() {
    cd "$TMP" || exit  # Change to the temporary directory
    clear
    
    # Exibe o cabeçalho da seção de configuração de aliados
    printf_t "The script will consider users on your friends list and Clan as allies.\nLeader on friend list will add Clan allies." "$BLACK_CYAN" "$COLOR_RESET" "before" ""

    # Opções de configuração com emojis para cada item do menu
    printf_t "1) Add/Update alliances (All Battles)" "" "" "before" "🔵👨 🔴🧑‍🦰"
    printf_t "2) Add/Update just Herois alliances (Coliseum/King of immortals)" "" "" "before" "👫"
    printf_t "3) Add/Update just Clan alliances (Altars, Clan Coliseum and Clan Fight)" "" "" "before" "🔴 🔵"
    printf_t "4) Do nothing" "" "" "before" "🚶"

    # Verifica se o arquivo de alianças existe e possui conteúdo; caso contrário, pede ao usuário para configurar
    if [ -f "$HOME/twm/al_file" ] && [ -s "$HOME/twm/al_file" ]; then
        AL=$(cat "$HOME"/twm/al_file)
    else
        printf_t "Set up alliances [1 to 4]:" "" "" "after" ""
        read -r -n 1 AL
    fi

    case $AL in
         #/Opção 1: Ativa alianças em todas as batalhas (chama as funções AlliesID, ClanAlliesID e Members, define a variável ALD como 1, armazena o valor "1" no arquivo al_file e exibe uma mensagem de confirmação)
      1)
            id_allies
            clan_allies
            members_allies
            ALD=1
            echo "1" > "$HOME/twm/al_file"
            printf_t "Alliances on all battles active" "" "" "before" "🔵👨 🔴🧑‍🦰"
        ;;
        # Opção 2: Ativa alianças apenas em Herois
        2) 
            id_allies
            members_allies
            if [ -e "$TMP/callies.txt" ]; then
                : > "$TMP"/callies.txt
            fi
            ALD=1
            echo "2" > "$HOME/twm/al_file"
            printf_t "Just Herois alliances now." "" "" "before" "👫"
        ;;
        # Opção 3: Ativa alianças apenas no Clan
        3) 
            id_allies
            clan_allies
            if [ -e "$TMP/allies.txt" ]; then
                : > "$TMP"/allies.txt
            fi
            unset ALD
            echo "3" > "$HOME/twm/al_file"
            printf_t "Just Clan alliances now." "" "" "before" "🔴 🔵"
        ;;
        # Opção 4: Não faz nada
        4) 
            printf_t "Nothing changed." "" "" "before" "🚶"
            ALD=1
            echo "4" > "$HOME/twm/al_file"
            : >> "$TMP"/allies.txt
            : >> "$TMP"/callies.txt
        ;;
        # Opção inválida ou tempo excedido
        *) 
            clear
            if [ -n "$AL" ]; then
                echo_t "Invalid option: $AL" "" "" "before" ""
                kill -9 $$
            else
                echo_t "Time exceeded!" "" "" "before" ""
            fi
        ;;
    esac
}
