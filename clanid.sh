clan_id() {
  cd "$TMP" || exit
  #/Executa o comando especificado no SOURCE com a URL do clã e um userAgent.txt aleatório
  (
    w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}/clan" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >CLD
  ) </dev/null &>/dev/null &
  time_exit 20
  
  #/Lê o conteúdo do arquivo CLD, substitui cada ocorrência de "/clan/" por uma nova linha,
  #/seleciona somente as linhas que contêm a string "built/", e extrai a primeira parte da string
  CLD=$(cat CLD | sed "s/\/clan\//\\n/g" | grep 'built/' | awk -F/ '{ print $1 }')

  ## add an option to check the first two members of the clan look from the link https://furiadetitas.net/clan/
  ## 
  ## ex: https://furiadetitas.net/user/528904/ get the name and check with the variable ${ACC}
  ## if so, make variable leader true.
}
check_leader() {
    echo "DEBUG: Starting check_leader function"

    # Fetch clan page and extract relevant data
    (
        echo "DEBUG: Fetching clan page..."
        w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -dump "${URL}/clan/" \
        -o user_agent="$(shuf -n1 $TMP/userAgent.txt)" | sed -ne '/\[[^a-z]\]/,/\[menuList\]/p' | sed '$d;20q' >>"$TMP/CODE"
        echo "DEBUG: Clan page fetched and processed."
    ) </dev/null &>/dev/null &
    time_exit 17

    # Read members from the CODE file
    if [ ! -f "$TMP/CODE" ]; then
        echo "DEBUG: CODE file not found."
        echo "No members found."
        return
    fi

    # Check if ACC is present in CODE file
    if grep -q "$ACC" "$TMP/CODE"; then
        echo "Leader found: ${ACC}"
    else
        echo "No leader found in the CODE file."
    fi

    # Optionally return or use any other variable as needed
}

clan_statue() {
    clan_id  # Retrieve the current clan ID
    check_leader
    if [ -n "$CLD" ] && [ $leader == true ]; then  # Proceed only if CLD is set (indicating a valid clan)
        echo -e "${GOLD_BLACK}Clan Statue Check 🗿${COLOR_RESET}"

        # Fetch the code from the arena/quit page
        (
          w3m -cookie -o http_proxy=$PROXY -o accept_encoding=UTF-8 -debug -dump_source "${URL}/arena/quit" -o user_agent="$(shuf -n1 $TMP/userAgent.txt)" | sed "s/href='/\n/g" | grep "attack/1" | head -n 1 | awk -F\/ '{ print $5 }' | tr -cd "[[:digit:]]" >$TMP/CODE
        ) &
        time_exit 17  # Wait for the process to finish

        # Upgrade clan building with gold
        (
          w3m -cookie -o http_proxy=$PROXY -o accept_encoding=UTF-8 -debug "${URL}/clan/${CLD}/built/?goldUpgrade=true&r=$(cat $TMP/CODE)" -o user_agent="$(shuf -n1 $TMP/userAgent.txt)" | tail -n 0
        ) &
        time_exit 17  # Wait for the process to finish
        echo "/clan/${CLD}/built/?goldUpgrade=true&r=$(cat $TMP/CODE)"

        # Fetch the code again for silver upgrade
        (
          w3m -cookie -o http_proxy=$PROXY -o accept_encoding=UTF-8 -debug -dump_source "${URL}/arena/quit" -o user_agent="$(shuf -n1 $TMP/userAgent.txt)" | sed "s/href='/\n/g" | grep "attack/1" | head -n 1 | awk -F\/ '{ print $5 }' | tr -cd "[[:digit:]]" >$TMP/CODE
        ) &
        time_exit 17  # Wait for the process to finish

        # Upgrade clan building with silver
        (
          w3m -cookie -o http_proxy=$PROXY -o accept_encoding=UTF-8 -debug "${URL}/clan/${CLD}/built/?silverUpgrade=true&r=$(cat $TMP/CODE)" -o user_agent="$(shuf -n1 $TMP/userAgent.txt)" | tail -n 0
        ) &
        time_exit 17  # Wait for the process to finish
        echo "/clan/${CLD}/built/?silverUpgrade=true&r=$(cat $TMP/CODE)"

        echo -e "${GREEN_BLACK}Clan Statue ✅${COLOR_RESET}\n"
    fi
}