# shellcheck disable=SC2154
members_allies() {
    cd "$TMP" || exit  # Change to the temporary directory
    echo "" >> allies.txt  # Ensure allies.txt exists
    clan_id  # Call clan_id to set CLD variable
    echo "" > callies.txt # Ensure callies.txt exists

    if [ -n "$CLD" ]; then
        echo -e "${BLACK_CYAN}Updating clan members into allies${COLOR_RESET}"
        
        # Loop through the last 5 clan member pages (5 to 1)
        for num in $(seq 5 -1 1); do
            
            echo -e "${PURPLEis_BLACK}/clan/${CLD}/${num}${COLOR_RESET}"
            (
              w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}/clan/${CLD}/${num}" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" | grep -o -E "[/]>([[:upper:]][[:lower:]]{0,15}[[:space:]]{0,1}[[:upper:]]{0,1}[[:lower:]]{0,14},[[:space:]])<s" | awk -F"[>]" '{print $2}' | awk -F"[,]" '{print $1}' | sed 's,\ ,_,' >>allies.txt
            ) </dev/null &>/dev/null &
            time_exit 17  # Wait for the process to finish
        done
        
        sort -u allies.txt -o allies.txt  # Sort and remove duplicates
    fi

    # Display the updated list of allies
    echo -e "${BLACK_CYAN}Allies for Coliseum and King of the Immortals:${COLOR_RESET}"
    cat allies.txt  # Show contents of allies.txt

    echo -e "${BLACK_CYAN}Wait to continue. 👈${COLOR_RESET}"
    sleep 2  # Pause before continuing
}

id_allies() {
  printf "${BLACK_CYAN}Looking for allies on friends list${COLOR_RESET}\n"
  cd "$TMP" || exit
  printf "${PURPLEis_BLACK}/mail/friends${COLOR_RESET}\n"
  (
    w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}/mail/friends" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
  ) </dev/null &>/dev/null &
  time_exit 17
  #  NPG=$(cat $TMP/SRC | sed 's/href=/\n/g' | grep "/mail/friends/[0-9]'>&#62;&#62;" | cut -d\' -f2 | cut -d\/ -f4)
  NPG=$(grep -o -E '/mail/friends/([[:digit:]]{0,4})[^[:alnum:]]{4}62[^[:alnum:]]{3}62[^[:alnum:]]' "$TMP/SRC" | sed 's/\/mail\/friends\/\([[:digit:]]\{0,4\}\).*/\1/') > tmp.txt
  if [ -z "$NPG" ]; then
    printf "${PURPLEis_BLACK}/mail/friends${COLOR_RESET}\n"
    (
      w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}/mail/friends" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" | sed 's,/user/,\n/user/,g' | grep '/user/' | grep '/mail/' | cut -d\< -f1 >>tmp.txt
    ) </dev/null &>/dev/null &
    time_exit 17  # Wait for the process to finish

    # Extract friend IDs from the source file
    NPG=$(grep -o -E '/mail/friends/([0-9]{0,4})[^[:alnum:]]{4}62[^[:alnum:]]{3}62[^[:alnum:]]' "$TMP/SRC" | \
         sed 's/\/mail\/friends\/\([0-9]\{0,4\}\).*/\1/') > tmp.txt

    if [ -z "$NPG" ]; then
        echo "${PURPLEis_BLACK}/mail/friends${COLOR_RESET}"
        (
          w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}/mail/friends" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" | sed 's,/user/,\n/user/,g' | grep '/user/' | grep '/mail/' | cut -d\< -f1 >>tmp.txt
        ) </dev/null &>/dev/null &
        time_exit 17  # Wait for the process to finish
    else
        for num in $(seq "$NPG" -1 1); do
            echo -e "${BLACK_CYAN}Friends list page ${num}${COLOR_RESET}"
            (
              w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}/mail/friends/${num}" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" | sed 's,/user/,\n/user/,g' | grep '/user/' | grep '/mail/' | cut -d\< -f1 >>tmp.txt
            ) </dev/null &>/dev/null &
            time_exit 17  # Wait for the process to finish
        done
    fi

    sort -u tmp.txt -o tmp.txt  # Sort and remove duplicates from friend IDs
    tmp.txt | cut -d\> -f2 | sed 's,\ ,_,' > allies.txt  # Format and save to allies.txt
  fi
}

clan_allies() {
    clan_id  # Get the current clan ID

    if [ -n "$CLD" ]; then
    cd "$TMP" || exit
    echo "" >callies.txt
    tmp.txt | cut -d/ -f3 >ids.txt
    printf "${BLACK_CYAN}\nClan allies by Leader/Deputy on friends list\n${COLOR_RESET}\n"
    Lnl=$(ids.txt | wc -l)
    nl=1
    ts=0
    for num in $(seq "$Lnl" -1 "$nl"); do
      IDN=$(ids.txt | tail -n "$Lnl" | head -n 1)
            if [ -n "$IDN" ]; then
                echo -e "${Lnl} ${PURPLEis_BLACK}/user/${IDN}${COLOR_RESET}"

                (
          w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}/user/${IDN}" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
                ) </dev/null &>/dev/null &
                time_exit 17
        LEADPU=$("$TMP"/SRC | sed 's,/clan/,\n/clan/,g' | grep -E "</a>, <span class='blue'|</a>, <span class='green'" | cut -d\< -f1 | cut -d\> -f2)
        alCLAN=$("$TMP"/SRC | grep -E -o '/clan/[0-9]{1,3}' | tail -n1)
        printf "${PURPLEi_BLACK} ${LEADPU} - ${alCLAN}${COLOR_RESET}\n"
                if [ -n "$LEADPU" ]; then
                    ts=$((ts + 1))  # Increment ally count
                    echo -e "$LEADPU" | sed 's,\ ,_,' >> callies.txt  # Save ally name formatted with underscores
                    
                    echo -e "${BLACK_CYAN} ${ts}. Ally ${LEADPU} ${alCLAN} added.${COLOR_RESET}"
                    sort -u callies.txt -o callies.txt  # Sort and remove duplicates in callies.txt
                fi
                
                Lnl=$((Lnl-1))  # Decrease line count after processing an ID
            fi
            
            sleep 1s  # Brief pause between requests to avoid overwhelming the server
        done
    fi
}

conf_allies() {
    cd "$TMP" || exit  # Change to the temporary directory
    clear
  printf "${BLACK_CYAN}\nThe script will consider users on your friends list and \nClan as allies.\nLeader/Deputy on friend list will add \nClan allies.\n${COLOR_RESET}\n1) Add/Update alliances(All Battles)🏳️👨‍🏴‍👩‍🏳️👧‍🏴‍👦🏳️\n\n2) 👫 Add/Update just Herois alliances(Coliseum/King of immortals)\n\n3) 🏴🏳️ Add/Update just Clan alliances(Altars,Clan Coliseum and Clan Fight)\n\n4) 🚶Do nothing\n"
  if [ -f "$HOME/twm/al_file" ] && [ -s "$HOME/twm/al_file" ]; then
    AL=$(cat "$HOME"/twm/al_file)
  else
    printf "Set up alliances[1 to 4]: \n"
    read -r -n 1 AL
    fi

    case $AL in
      #/Opção 1: Ativa alianças em todas as batalhas (chama as funções AlliesID, ClanAlliesID e Members, define a variável ALD como 1, armazena o valor "1" no arquivo al_file e exibe uma mensagem de confirmação)
      1)
        id_allies
        clan_allies
        members_allies
        ALD=1
        echo "1" >"$HOME"/twm/al_file
        printf "🏳️👨‍🏴‍👩‍🏳️👧‍🏴‍👦🏳️Alliances on all battles active\n"
      ;;
      #/Opção 2: Ativa alianças apenas em Herois (chama as funções AlliesID e Members, verifica se o arquivo callies.txt existe e, se existir, o esvazia, define a variável ALD como 1, armazena o valor "2" no arquivo al_file e exibe uma mensagem de confirmação)
      2)
        id_allies
        members_allies
        if [ -e "$TMP/callies.txt" ]; then
          : > "$TMP"/callies.txt
        fi
        ALD=1
        echo "2" >"$HOME"/twm/al_file
        printf "👫 Just Herois alliances now.\n"
      ;;
      #/Opção 3: Ativa alianças apenas no Clan (chama as funções AlliesID, ClanAlliesID e verifica se o arquivo allies.txt existe e, se existir, o esvazia, desfaz a definição da variável ALD, armazena o valor "3" no arquivo al_file e exibe uma mensagem de confirmação)
      3)
        id_allies
        clan_allies
        if [ -e "$TMP/allies.txt" ]; then
          : > "$TMP"/allies.txt
        fi
        unset ALD
        echo "3" >"$HOME"/twm/al_file
        printf "🏴🏳️ Just Clan alliances now.\n"
      ;;
      #/Opção 4: Não faz nada (exibe uma mensagem de confirmação e adiciona linhas vazias nos arquivos allies.txt e callies.txt, caso existam)
      4)
        printf "🚶Nothing changed.\n"
        # shellcheck disable=SC2034
        ALD=1
        echo "4" >"$HOME"/twm/al_file
        : >>allies.txt
        : >>callies.txt
      ;;
      #/Nenhuma opção válida selecionada
      *)
        clear
        if [ -n "$AL" ]; then
          echo -e "\n Invalid option:  $AL"
          kill -9 $$
        else
          echo -e "\n Time exceeded!"
        fi
      ;;
    esac
}
