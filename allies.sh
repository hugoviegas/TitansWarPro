# shellcheck disable=SC2154
members_allies() {
    cd "$TMP" || exit
    echo "" >> allies.txt
    clan_id
    echo "" > callies.txt

    if [ -n "$CLD" ]; then
        echo -e "${BLACK_CYAN}$(translate_and_cache "$LANGUAGE" "Updating clan members into allies")${COLOR_RESET}"
        
        for num in $(seq 5 -1 1); do
            echo -e "${PURPLEis_BLACK}/clan/${CLD}/${num}${COLOR_RESET}"
            (
              w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}/clan/${CLD}/${num}" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" | grep -o -E "[/]>([[:upper:]][[:lower:]]{0,15}[[:space:]]{0,1}[[:upper:]]{0,1}[[:lower:]]{0,14},[[:space:]])<s" | awk -F"[>]" '{print $2}' | awk -F"[,]" '{print $1}' | sed 's,\ ,_,' >>allies.txt
            ) </dev/null &>/dev/null &
            time_exit 17
        done
        
        sort -u allies.txt -o allies.txt
    fi

    echo -e "${BLACK_CYAN}$(translate_and_cache "$LANGUAGE" "Allies for Coliseum and King of the Immortals:") 🧱 👑${COLOR_RESET}"
    cat allies.txt

    echo -e "${BLACK_CYAN}$(translate_and_cache "$LANGUAGE" "Wait to continue. ") 👈${COLOR_RESET}"
    sleep 2
}

id_allies() {
  printf "${BLACK_CYAN}$(translate_and_cache "$LANGUAGE" "Looking for allies on friends list")${COLOR_RESET}\n"
    cd "$TMP" || exit
  printf "${PURPLEis_BLACK}/mail/friends${COLOR_RESET}\n"
  (
    w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}/mail/friends" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
  ) </dev/null &>/dev/null &
  time_exit 17
  #  NPG=$(cat $TMP/SRC | sed 's/href=/\n/g' | grep "/mail/friends/[0-9]'>&#62;&#62;" | cut -d\' -f2 | cut -d\/ -f4)
    NPG=$(cat "$TMP"/SRC | grep -o -E '/mail/friends/([[:digit:]]{0,4})[^[:alnum:]]{4}62[^[:alnum:]]{3}62[^[:alnum:]]' | sed 's/\/mail\/friends\/\([[:digit:]]\{0,4\}\).*/\1/') >tmp.txt
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
            echo -e "${BLACK_CYAN}$(translate_and_cache "$LANGUAGE" "Friends list page ")${num}${COLOR_RESET}"
            (
              w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}/mail/friends/${num}" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" | sed 's,/user/,\n/user/,g' | grep '/user/' | grep '/mail/' | cut -d\< -f1 >>tmp.txt
            ) </dev/null &>/dev/null &
            time_exit 17  # Wait for the process to finish
        done
    fi

    sort -u tmp.txt -o tmp.txt  # Sort and remove duplicates from friend IDs
    cat tmp.txt | cut -d\> -f2 | sed 's,\ ,_,' > allies.txt  # Format and save to allies.txt
  fi
}

clan_allies() {
    clan_id  # Get the current clan ID

    if [ -n "$CLD" ]; then
    cd "$TMP" || exit
    echo "" >callies.txt
    cat tmp.txt | cut -d/ -f3 >ids.txt

    printf "${BLACK_CYAN}\n$(translate_and_cache "$LANGUAGE" "Clan allies by Leader/Deputy on friends list")\n${COLOR_RESET}\n"
    Lnl=$(cat ids.txt | wc -l)
    nl=1
    ts=0
    for num in $(seq "$Lnl" -1 "$nl"); do
      IDN=$(cat ids.txt | tail -n "$Lnl" | head -n 1)
            if [ -n "$IDN" ]; then
                echo -e "${Lnl} ${PURPLEis_BLACK}/user/${IDN}${COLOR_RESET}"

                (
          w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}/user/${IDN}" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
                ) </dev/null &>/dev/null &
                time_exit 17
        LEADPU=$(cat "$TMP"/SRC | sed 's,/clan/,\n/clan/,g' | grep -E "</a>, <span class='blue'|</a>, <span class='green'" | cut -d\< -f1 | cut -d\> -f2)
        alCLAN=$(cat "$TMP"/SRC | grep -E -o '/clan/[0-9]{1,3}' | tail -n1)
        printf "${PURPLEi_BLACK} ${LEADPU} - ${alCLAN}${COLOR_RESET}\n"
                if [ -n "$LEADPU" ]; then
                    ts=$((ts + 1))  # Increment ally count
                    echo -e "$LEADPU" | sed 's,\ ,_,' >> callies.txt  # Save ally name formatted with underscores
                    
                    echo -e "${BLACK_CYAN} ${ts}. $(translate_and_cache "$LANGUAGE" "Ally") ${LEADPU} ${alCLAN} $(translate_and_cache "$LANGUAGE" "added.")${COLOR_RESET}"
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
  printf "${BLACK_CYAN}\n%s${COLOR_RESET}\n" "$(translate_and_cache "$LANGUAGE" "The script will consider users on your friends list and Clan as allies.\nLeader on friend list will add Clan allies.")\n"
  printf "%s🔵👨 🔴🧑‍🦰\n" "$(translate_and_cache "$LANGUAGE" "1) Add/Update alliances (All Battles)")"
  printf "2) 👫 %s\n" "$(translate_and_cache "$LANGUAGE" "Add/Update just Herois alliances (Coliseum/King of immortals)")"
  printf "3) 🔴 🔵 %s\n" "$(translate_and_cache "$LANGUAGE" "Add/Update just Clan alliances (Altars, Clan Coliseum and Clan Fight)")"
  printf "4) 🚶 %s\n" "$(translate_and_cache "$LANGUAGE" "Do nothing")"

  if [ -f "$HOME/twm/al_file" ] && [ -s "$HOME/twm/al_file" ]; then
    AL=$(cat "$HOME"/twm/al_file)
  else
    printf "$(translate_and_cache "$LANGUAGE" "Set up alliances[1 to 4]: ")\n"
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
        printf "%s🔵👨 🔴🧑‍🦰\n" "$(translate_and_cache "$LANGUAGE" "Alliances on all battles active")\n"
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
        printf "👫 %s\n" "$(translate_and_cache "$LANGUAGE" "Just Herois alliances now.")\n"
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
        printf "🔴 🔵 %s\n""$(translate_and_cache "$LANGUAGE" "Just Clan alliances now.")\n"
      ;;
      #/Opção 4: Não faz nada (exibe uma mensagem de confirmação e adiciona linhas vazias nos arquivos allies.txt e callies.txt, caso existam)
      4)
        printf "🚶 %s\n" "$(translate_and_cache "$LANGUAGE" "Nothing changed.")\n"
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
          echo -e "\n $(translate_and_cache "$LANGUAGE" "Invalid option: ") $AL"
          kill -9 $$
        else
          echo -e "\n $(translate_and_cache "$LANGUAGE" "Time exceeded!")"
        fi
      ;;
    esac
}
