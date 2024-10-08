clan_id() {
  cd "$TMP" || exit
  #/Executa o comando especificado no SOURCE com a URL do clã e um userAgent.txt aleatório
  fetch_page "/clan"
  
  #/Lê o conteúdo do arquivo CLD, substitui cada ocorrência de "/clan/" por uma nova linha,
  #/seleciona somente as linhas que contêm a string "built/", e extrai a primeira parte da string
  CLD=$(cat CLD | sed "s/\/clan\//\\n/g" | grep 'built/' | awk -F/ '{ print $1 }')

}

checkQuest() {
  quest_id="$*"
  if [ -n "${CLD}" ]; then
    fetch_page "/clan/${CLD}/quest/"
    fetch_page "/clan/${CLD}/quest/" "$TMP/debug_output.txt"
    click=$(grep -o -E "/quest/(take|help|deleteHelp|end)/$quest_id/\?r=[0-9]{8}" "$TMP"/SRC | sed -n '1p')
    #echo "DEBUG CLICK: $click"
    
    # Find the click button
    if [ -n "$click" ]; then
      fetch_page "/clan/${CLD}$click"
      echo " Quest $quest_id Check... 🔎"
      return 0  # Success if found
    else
      echo " Quest ID: $quest_id not ready. 🔎"
      return 1  # Not found
    fi
  else
    fetch_page "/clanrating/wantedToClan"
    echo " Quest ID: $quest_id not ready. 🔎"
    return 1  # Fail in case CLD is empty
  fi
}

check_leader() {
    # Fetch clan page and extract relevant data
     w3m -cookie -o http_proxy=$PROXY -o accept_encoding=UTF-8 -dump "${URL}/clan/" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" | sed -ne '/\[[^a-z]\]/,/\[arrow\]/p' > "$TMP/CODE" 2>/dev/null

    # Ensure the fetch command completed successfully
    if [ $? -ne 0 ]; then
        echo "Failed to fetch the clan page."
        return 1
    fi

    # Check if the CODE file is empty after processing
    if [ ! -s "$TMP/CODE" ]; then
        echo "No relevant data found in the clan page."
        return 1
    fi

    # Read the content of the CODE file
    CODE=$(cat "$TMP/CODE")

    # Find the clan leader (Clã líder) and vice-leader (Vice-líder)
    LEADERS=$(echo "$CODE" | grep -E 'líder|Vice-líder' | awk -F',' '{print $1}')

    # Initialize the final variable to false
    is_leader=false

    # Check if ACC is one of the leaders
    if echo "$LEADERS" | grep -q "$ACC"; then
        is_leader=true
    fi

}

clan_statue() {
    check_leader
    if [ -n "$CLD" ] && [ "$is_leader" == true ]; then  # Proceed only if CLD is set (indicating a valid clan)
        echo -e "${GOLD_BLACK}Clan Statue Check 🗿${COLOR_RESET}"

        # Fetch the code from the arena/quit page
        (
          w3m -cookie -o http_proxy=$PROXY -o accept_encoding=UTF-8 -debug -dump_source "${URL}/arena/quit" -o user_agent="$(shuf -n1 $TMP/userAgent.txt)" | sed "s/href='/\n/g" | grep "attack/1" | head -n 1 | awk -F\/ '{ print $5 }' | tr -cd "[:digit:]" >$TMP/CODE
        ) &
        time_exit 17  # Wait for the process to finish

        # Upgrade clan building with gold
        (
          w3m -cookie -o http_proxy=$PROXY -o accept_encoding=UTF-8 -debug "${URL}/clan/${CLD}/built/?goldUpgrade=true&r=$(cat $TMP/CODE)" -o user_agent="$(shuf -n1 $TMP/userAgent.txt)" | tail -n 0
        ) &
        time_exit 17  # Wait for the process to finish
        echo " Gold Statue Upgrade..."

        # Fetch the code again for silver upgrade
        (
          w3m -cookie -o http_proxy=$PROXY -o accept_encoding=UTF-8 -debug -dump_source "${URL}/arena/quit" -o user_agent="$(shuf -n1 $TMP/userAgent.txt)" | sed "s/href='/\n/g" | grep "attack/1" | head -n 1 | awk -F\/ '{ print $5 }' | tr -cd "[:digit:]" >$TMP/CODE
        ) &
        time_exit 17  # Wait for the process to finish

        # Upgrade clan building with silver
        (
          w3m -cookie -o http_proxy=$PROXY -o accept_encoding=UTF-8 -debug "${URL}/clan/${CLD}/built/?silverUpgrade=true&r=$(cat $TMP/CODE)" -o user_agent="$(shuf -n1 $TMP/userAgent.txt)" | tail -n 0
        ) &
        time_exit 17  # Wait for the process to finish
        echo " Silver Statue Upgrade..."

        echo -e "${GREEN_BLACK}Clan Statue ✅${COLOR_RESET}\n"
    fi
}

clanDungeon() {
  #clan_id
  if [ -n "$CLD" ]; then
  echo -e "${GOLD_BLACK}Checking clan dungeon 👹${COLOR_RESET}"
    fetch_page "/clandungeon/?close"
    local CLANDUNGEON
    CLANDUNGEON=$(grep -o -E '/clandungeon/(attack/[?][r][=][0-9]+|[?]close)' "$TMP"/SRC | head -n 1)
    local BREAK=$(($(date +%s) + 60))
    until [ -z "$CLANDUNGEON" ] || [ $(date +%s) -ge "$BREAK" ]; do
      fetch_page "${CLANDUNGEON}"
      local count 
      count=$((count + 1))
      echo " ⚔ Atack $count"
      local CLANDUNGEON=$(grep -o -E '/clandungeon/(attack/[?][r][=][0-9]+|[?]close)' "$TMP"/SRC | head -n 1)
    done
    echo -e "${GREEN_BLACK}Clan Dungeon ✅${COLOR_RESET}\n"
  fi
}

clanElixirQuest() {
  # Checking for available quests
  if checkQuest 7; then
    fetch_page "/lab/alchemy/"
  
    # Generate a random number between 1 and 4
    i=$(shuf -i 1-4 -n 1)
    fetch_page "/lab/alchemy/$i/"
    # Search for the potion-making link /lab/alchemy/1/makePotion?r=42378359
    click=$(grep -o -E "/lab/alchemy/$i/makePotion[?]r=[0-9]+" "$TMP"/SRC | sed -n '1p')
    
    # If a link is found, fetch the page to make the potion
    if [ -n "$click" ]; then
      fetch_page "$click"
      sleep 1s
      click=$(grep -o -E "/lab/alchemy/$i/makePotion[?]r=[0-9]+" "$TMP"/SRC | sed -n '1p')
      fetch_page "$click"
      # Finalize the quest
      checkQuest 7
    fi
  fi
  
}

clanMerchantQuest() {
  # Checking for available quests
  if checkQuest 8; then
    # Fetch the coliseum merchant page
    fetch_page "/coliseum/merchant/"

    # Generate a random number between 1 and 2
    i=$(shuf -i 1-2 -n 1)
    # /coliseum/merchant/2/startMaking?r=42378359&ref=lab
    # Search for the merchant-making link with reference to the lab
    click=$(grep -o -E "/coliseum/merchant/$i/startMaking[?]r=[0-9]+&ref=lab" "$TMP"/SRC | sed -n '1p')

    # If a link is found, fetch the page to start the merchant process
    if [ -n "$click" ]; then
      fetch_page "$click"
      click=$(grep -o -E "/coliseum/merchant/$i/startMaking[?]r=[0-9]+&ref=lab" "$TMP"/SRC | sed -n '1p')
      fetch_page "$click"
      click=$(grep -o -E "/coliseum/merchant/$i/startMaking[?]r=[0-9]+&ref=lab" "$TMP"/SRC | sed -n '1p')
      fetch_page "$click"
      sleep 1s
      checkQuest 8
    fi
  fi
}
