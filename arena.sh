# shellcheck disable=SC2148
arena_fault() {
    # Fetch the fault page
    fetch_page "/fault"

    # Set a timeout for 10 seconds
    local BREAK=$(($(date +%s) + 10))

    # Loop while fault attack is available or until timeout occurs
    while grep -q -o '/fault/attack' "$TMP"/SRC || [ "$(date +%s)" -lt "$BREAK" ]; do
        # Extract the attack URL from the fault page
        local ACCESS=$(grep -o -E '/fault/attack/[?]r[=][0-9]+' "$TMP"/SRC | sed -n '1p')

        if [ -n "$ACCESS" ]; then
            # Fetch the fault attack page
            fetch_page "$ACCESS"
            time_exit 17
            echo "$ACCESS"
        else
            echo "No fault attack available."
        fi

        # Pause before retrying
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
  
    echo " Sell all items ✅"
    echo -e "${GREEN_BLACK}Arena ✅${COLOR_RESET}\n"
}

arena_fullmana() {
    echo "Energy arena... ⚡"

    # Fetch the arena quit page and extract the first attack ID
    fetch_page "/arena/quit"
    grep 'attack/1' "$TMP"/SRC | head -n1 | awk -F'/' '{ print $5 }' | tr -cd "[[:digit:]]" > ARENA

    time_exit 17
    echo " ⚔ - 1st Attack..."

    # Use the extracted attack ID to initiate the first attack
    fetch_page "/arena/attack/1/?r=$(cat ARENA)"
    grep 'arena/lastPlayer' "$TMP"/SRC | head -n1 | awk -F\' '{ print $1 }' | tr -cd "[[:digit:]]" > ATK1

    time_exit 17
    echo " ⚔ - Full Attack..."

    # Perform a full mana attack on the last player
    fetch_page "/arena/lastPlayer/?r=$(cat ATK1)&fullmana=true"

    # Output attack results
    head -n5 "$TMP"/SRC | tail -n4

    time_exit 17
    echo -e "${GREEN_BLACK}Energy arena ✅${COLOR_RESET}\n"
}
