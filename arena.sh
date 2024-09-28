# shellcheck disable=SC2148
arena_fault() {
  (
    w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "$URL/fault" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
  ) </dev/null &>/dev/null &
  time_exit 17
    local BREAK=$(($(date +%s) + 10))
    while grep -q -o '/fault/attack' "$TMP"/SRC || [ "$(date +%s)" -lt "$BREAK" ]; do
    local ACCESS=$(grep -o -E '(/fault/attack/[^A-Za-z0-9]r[^A-Za-z0-9][0-9]+)' "$TMP"/SRC | sed -n '1p')
    (
      w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "$URL$ACCESS" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
    ) </dev/null &>/dev/null &
            time_exit 17
            echo "$ACCESS"
        sleep 1s
    done
    echo -e "fault (✔)\n"
}
arena_collFight() {
  (
    w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "$URL/collfight/enterFight" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
  ) </dev/null &>/dev/null &
  time_exit 17
  if grep -q -o '/collfight/' "$TMP"/SRC; then
    echo "collfight ..."
    echo "/collfight/enterFight"
    local ACCESS=$(cat "$TMP"/SRC | sed 's/href=/\n/g' | grep 'collfight/take' | head -n1 | awk -F\' '{ print $2 }')
    (
      w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "$URL$ACCESS" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" | tail -n0
    ) </dev/null &>/dev/null &
    time_exit 17
    echo "$ACCESS"
    (
      w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "$URL/collfight/enterFight" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" | tail -n0
    ) </dev/null &>/dev/null &
    time_exit 17
    echo "/collfight/enterFight"
    echo -e "collfight (✔)\n"
  fi
}
arena_takeHelp() {
    clan_id  # Ensure the clan ID is set

    if [ -n "$CLD" ]; then
        # Fetch the take or help quest link from the page
        local click=$(grep -o -E "/clan/$CLD/quest/(take|help)/[0-9]+" "$TMP"/SRC | head -n1)

        if [ -n "$click" ]; then
            # Process the first take/help quest link
            fetch_page "$click"
            time_exit 17
            echo " Quest Arena 3"

            # Simulate fetching the next quest action
            local next_click=$(echo "$click" | sed 's/[0-9]\+$/4/')
            fetch_page "$next_click"
            time_exit 17
            echo " Quest Arena 4"
        else
            echo "No valid quest actions found for clan $CLD."
        fi
    else
        # If no clan ID is available, fallback to a clan invite settings URL
        fetch_page "/settings/claninvite/1"
        time_exit 17
    fi
}


arena_deleteEnd() {
    clan_id  # Ensure the clan ID is set

    if [ -n "$CLD" ]; then
        # Fetch the clan's quest deleteHelp or end link from the page
        local click=$(grep -o -E "/clan/$CLD/quest/(deleteHelp|end)/[0-9]+" "$TMP"/SRC | head -n1)

        if [ -n "$click" ]; then
            # Process the first deleteHelp or end link
            fetch_page "$click"
            time_exit 17
            echo "$click"

            # Simulate fetching a similar follow-up action (if applicable)
            local next_click=$(echo "$click" | sed 's/[0-9]\+$/4/')
            fetch_page "$next_click"
            time_exit 17
            echo "$next_click"
        else
            echo "No valid quest actions found for clan $CLD."
        fi
    else
        # If no clan ID is available, fallback to a general clan URL
        fetch_page "/clanrating/wantedToClan"
        time_exit 17
    fi
}


arena_duel() {
    echo -e "${GOLD_BLACK}Arena ⚔️${COLOR_RESET}"
    checkQuest 3
    checkQuest 4

    # Fetch initial arena page
    fetch_page "/arena/"

    local BREAK=$(($(date +%s) + 60))
    local count=0

    # Loop until wizard lab link is found or time exceeds the BREAK point
    until grep -q -o 'lab/wizard' "$TMP"/SRC || [ "$(date +%s)" -gt "$BREAK" ]; do
        # Extract attack link from the arena page
        local ACCESS=$(grep -o -E '(/arena/attack/1/[?]r[=][0-9]+)' "$TMP"/SRC | sed -n '1p')

        # Fetch the attack page
        fetch_page "$ACCESS"
        
        count=$((count + 1))
        echo " ⚔ Attack $count"
        
        sleep 0.6s
    done

    # Fetch the bag inventory page after the duel
    fetch_page "/inv/bag/"

    # Extract and execute the sell-all-items action
    local SELL=$(grep -o -E '(/inv/bag/sellAll/1/[?]r[=][0-9]+)' "$TMP"/SRC | sed -n '1p')
    fetch_page "$SELL"
    
    checkQuest 3
    checkQuest 4
    
    echo " Sell all items ✅"
    echo -e "${GREEN_BLACK}Arena ✅${COLOR_RESET}\n"
}

arena_fullmana() {
  echo "energy arena ...\n"
  (
    w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}"/arena/quit -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" | sed "s/href='/\n/g" | grep 'attack/1' | head -n1 | awk -F\/ '{ print $5 }' | tr -cd "[[:digit:]]" >ARENA
  ) </dev/null &>/dev/null &
    time_exit 17
  echo " ⚔ - 1 Attack..."
  (
    w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}/arena/attack/1/?r=$(cat ARENA)" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" | sed "s/href='/\n/g" | grep 'arena/lastPlayer' | head -n1 | awk -F\' '{ print $1 }' | tr -cd "[[:digit:]]" >ATK1
  ) </dev/null &>/dev/null &
    time_exit 17
    echo " ⚔ - Full Attack..."
  (
    w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump "${URL}/arena/lastPlayer/?r=$(cat ATK1)&fullmana=true" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" | head -n5 | tail -n4
  ) </dev/null &>/dev/null &
    time_exit 17
    


  echo -e "${GREEN_BLACK}Energy arena ✅${COLOR_RESET}\n"
}