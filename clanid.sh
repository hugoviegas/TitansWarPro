clan_id() {
    cd "$TMP" || exit 1

    # Fetch the clan page and save the output to CLD file
    fetch_page "/clan" "CLD"

    # Extract the first occurrence of /clan/ followed by digits and store the ID in CLD
    CLD=$(grep -oP '/clan/(\d+)/' CLD | head -n 1 | awk -F'/' '{ print $3 }')

    # Check if we found a valid CLAN ID
    if [[ -z "$CLD" ]]; then
        echo_t "CLAN ID not found!"
        return 1
    else
        # echo "CLAN ID found: $CLD"
        echo "$CLD" > CLD  # Save the extracted CLAN ID back to CLD file
    fi
}


checkQuest() {
  quest_id="$1"
  action="$2" # Segundo argumento que define se é "apply" ou "end"

  # Block clan missions if disabled
  if [ "${FUNC_clan_missions:-y}" != "y" ]; then
      return 0
  fi

  if [ -n "${CLD}" ]; then
    fetch_page "/clan/${CLD}/quest/"
    #fetch_page "/clan/${CLD}/quest/" "$TMP/debug_output.txt"
    
    # Dependendo do valor de $action, alterar os padrões de busca do grep
    if [ "$action" == "apply" ]; then
      click=$(grep -o -E "/quest/(take|help)/$quest_id/\?r=[0-9]{8}" "$TMP/SRC" | sed -n '1p')
    elif [ "$action" == "end" ]; then
      click=$(grep -o -E "/quest/(deleteHelp|end)/$quest_id/\?r=[0-9]{8}" "$TMP/SRC" | sed -n '1p')
    else
      echo_t "Invalid action:" && printf "$action." && echo_t "Use 'apply' or 'end'."
      return 1 # Retorna falha se a ação for inválida
    fi

    # Verificar se encontrou o botão correto
    if [ -n "$click" ]; then
        fetch_page "/clan/${CLD}$click"
        if [ "$action" == "apply" ]; then
            echo_t " Starting clan mission: " "" "" "after" " ${quest_id} 🔎"
        else
            echo_t " Collect reward from mission: " "" "" "after" " ${quest_id} 🎁"
        fi
        return 0 # Sucesso se o botão foi encontrado
    else
        # echo_t " Can not start the clan mission:" "" "" "after" " ${quest_id} 🔎"
        return 1 # Não encontrou o botão
    fi
    else
        fetch_page "/clanrating/wantedToClan"
        # echo_t " Can not find the clan mission: " "" "" "after" " ${quest_id} ❌🔎"
        return 1 # Falha se CLD estiver vazio
    fi
}


check_leader() {
  # Fetch clan page and extract relevant data
  if ! w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -dump "${URL}/clan/" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" | sed -ne '/\[[^a-z]\]/,/\[arrow\]/p' > "$TMP/CODE" 2>/dev/null; then
    echo "Failed to fetch the clan page."
    return 1
  fi

  # Check if the CODE file is empty after processing
  if [ ! -s "$TMP/CODE" ]; then
      echo_t "No relevant data found in the clan page."
      return 1
  fi

  # Read the content of the CODE file
  CODE=$(cat "$TMP/CODE")

  # Create variables for leader titles that can be translated
  LEADER_TITLE=$(translate_and_cache "$LANGUAGE" "leader")
  VICE_LEADER_TITLE=$(translate_and_cache "$LANGUAGE" "Vice-leader")

  # Combine them into a grep pattern, escaping any special characters
  LEADER_PATTERN=$(echo "${LEADER_TITLE}|${VICE_LEADER_TITLE}" | sed 's/[[\.*^$/]/\\&/g')
  # echo "$LEADER_PATTERN"

  # Modified grep command using the translated pattern
  LEADERS=$(echo "$CODE" | grep -E "${LEADER_PATTERN}" | awk -F',' '{print $1}')

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
        echo_t "Clan statue check" "${GOLD_BLACK}" "${COLOR_RESET}" "after" "🗿"

        # Fetch the code from the arena/quit page
        (
          w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}/arena/quit" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" | sed "s/href='/\n/g" | grep "attack/1" | head -n 1 | awk -F / '{ print $5 }' | tr -cd "[:digit:]" >"$TMP"/CODE
        ) &
        time_exit 17  # Wait for the process to finish

        # Upgrade clan building with gold
        (
          w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug "${URL}/clan/${CLD}/built/?goldUpgrade=true&r=$(cat "$TMP"/CODE)" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" | tail -n 0
        ) &
        time_exit 17  # Wait for the process to finish
        echo_t " Gold Statue Upgrade..."

        # Fetch the code again for silver upgrade
        (
          w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}/arena/quit" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" | sed "s/href='/\n/g" | grep "attack/1" | head -n 1 | awk -F / '{ print $5 }' | tr -cd "[:digit:]" >"$TMP"/CODE
        ) &
        time_exit 17  # Wait for the process to finish

        # Upgrade clan building with silver
        (
          w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug "${URL}/clan/${CLD}/built/?silverUpgrade=true&r=$(cat "$TMP"/CODE)" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" | tail -n 0
        ) &
        time_exit 17  # Wait for the process to finish
        echo_t " Silver Statue Upgrade..."
        echo_t "Clan Statue" "${GREEN_BLACK}" "${COLOR_RESET}" "after" "🗿✅\n"
    fi
}

clanDungeon() {
  #clan_id
  if [ -n "$CLD" ]; then
  echo_t "Checking clan dungeon" "${GOLD_BLACK}" "${COLOR_RESET}" "after" "👹"
    fetch_page "/clandungeon/?close"
    local CLANDUNGEON
    CLANDUNGEON=$(grep -o -E '/clandungeon/(attack/[?][r][=][0-9]+|[?]close)' "$TMP"/SRC | head -n 1)
    local BREAK=$(($(date +%s) + 60))
    until [ -z "$CLANDUNGEON" ] || [ "$(date +%s)" -ge "$BREAK" ]; do
      fetch_page "${CLANDUNGEON}"
      local count 
      count=$((count + 1))
      echo_t "  Attacking monster " "" "" "after" "${count} ⚔️"
      local CLANDUNGEON
      CLANDUNGEON=$(grep -o -E '/clandungeon/(attack/[?][r][=][0-9]+|[?]close)' "$TMP"/SRC | head -n 1)
    done
    echo_t "The clan dungeon" "${GREEN_BLACK}" "${COLOR_RESET}" "after" "😈✅\n"
  fi
}

clanElixirQuest() {
  # Checking for available quests
  fetch_page "/lab/alchemy/"

  # Generate a random number between 1 and 4
  i=$(shuf -i 1-4 -n 1)
  fetch_page "/lab/alchemy/$i/"
  # Search for the potion-making link /lab/alchemy/1/makePotion?r=42378359
  click=$(grep -o -E "/lab/alchemy/$i/makePotion[?]r=[0-9]+" "$TMP"/SRC | sed -n '1p')
  
  # If a link is found, fetch the page to make the potion
  if [ -n "$click" ]; then
    case $i in
    (1)
      echo_t " Buying elixir strength" ;;
    (2)
      echo_t " Buying elixir health" ;;
    (3)
      echo_t " Buying elixir agility" ;;
    (4)
      echo_t " Buying elixir protection" ;;    
    esac
    fetch_page "$click"
    sleep 1s
    click=$(grep -o -E "/lab/alchemy/$i/makePotion[?]r=[0-9]+" "$TMP"/SRC | sed -n '1p')
    fetch_page "$click"
    sleep 2s
    # Finalize the quest
    checkQuest 7 end
  fi
  
}

clanMerchantQuest() {
  # Checking for available quests
  # Fetch the coliseum merchant page
  fetch_page "/coliseum/merchant/"

  # Generate a random number between 1 and 2
  i=$(shuf -i 1-2 -n 1)
  # /coliseum/merchant/2/startMaking?r=42378359&ref=lab
  # Search for the merchant-making link with reference to the lab
  click=$(grep -o -E "/coliseum/merchant/$i/startMaking[?]r=[0-9]+&ref=lab" "$TMP"/SRC | sed -n '1p')

  # If a link is found, fetch the page to start the merchant process
  if [ -n "$click" ]; then
    case $i in
      (1)
        echo_t " Buying Stones" "" "" "after" "🪨"
        ;;
      (2)
        echo_t " Buying Grass" "" "" "after" "🍃"
    esac
    fetch_page "$click"
    sleep 3s
    click=$(grep -o -E "/coliseum/merchant/$i/startMaking[?]r=[0-9]+&ref=lab" "$TMP"/SRC | sed -n '1p')
    fetch_page "$click"
    sleep 3s
    click=$(grep -o -E "/coliseum/merchant/$i/startMaking[?]r=[0-9]+&ref=lab" "$TMP"/SRC | sed -n '1p')
    fetch_page "$click"
    sleep 3s
    checkQuest 8 end
  fi
}

clanQuests() {
  #echo -e "${GOLD_BLACK}Clan Missions ${COLOR_RESET}"
  echo_t "Clan missions" "${GOLD_BLACK}" "${COLOR_RESET}" "after" "🔱🎯"
    if checkQuest 7 apply; then
    clanElixirQuest
    fi
    if checkQuest 8 apply; then
    clanMerchantQuest
    fi    
    if checkQuest 5 apply; then
    cave_routine
    fi
    if checkQuest 1 apply || checkQuest 2 apply; then
    league_play
    fi
  echo_t "Clan missions done" "${GREEN_BLACK}" "${COLOR_RESET}" "after" "✅"
}
