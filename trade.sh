func_trade() {
    echo -e "${GOLD_BLACK}Trade ⚖️${COLOR_RESET}"

    # Fetch the trade exchange page
    (
      w3m -cookie -o http_proxy=$PROXY -o accept_encoding=UTF-8 -debug -dump_source "${URL}/trade/exchange" -o user_agent="$(shuf -n1 $TMP/userAgent.txt)" >$TMP/SRC
    ) &
    time_exit 17  # Wait for the process to finish

    # Extract the first access link for silver exchange
    local ACCESS=$(grep -o -E '/trade/exchange/silver/[0-9]+[?]r[=][0-9]+' "$TMP/SRC" | head -n 1)
    
    # Set a timeout for accessing the exchange
    local BREAK=$(($(date +%s) + 30))  # 30 seconds from now

    # Loop until a valid ACCESS link is found or timeout occurs
    until [ -z "$ACCESS" ] || [ "$(date +%s)" -gt "$BREAK" ]; do
        SILVER_NUMBER=$(echo "$ACCESS" | cut -d'/' -f5 | cut -d'?' -f1)  # Extract silver amount

        echo -e " Exchange ${GOLD_BLACK}$SILVER_NUMBER🪙${COLOR_RESET}"

        # Fetch the specific silver exchange details
        (
          w3m -cookie -o http_proxy=$PROXY -o accept_encoding=UTF-8 -debug -dump_source "${URL}$ACCESS" -o user_agent="$(shuf -n1 $TMP/userAgent.txt)" >$TMP/SRC
        ) </dev/null &>/dev/null &
        time_exit 17  # Wait for the process to finish

        # Update ACCESS with the next available silver exchange link
        ACCESS=$(grep -o -E '/trade/exchange/silver/[0-9]+[?]r[=][0-9]+' "$TMP/SRC" | head -n 1)
    done

    echo -e "${GREEN_BLACK}Trade ✅${COLOR_RESET}\n"
}

clan_money() {
  clan_id
  if [ -n "$CLD" ]; then
    printf "Clan money ...\n"

    # Fetch and extract the code for the transaction
    fetch_page "${URL}/arena/quit"
    awk_code=$(sed "s/href='/\n/g" "$TMP/SRC" | grep "attack/1" | head -n 1 | awk -F\/ '{ print $5 }' | tr -cd "[[:digit:]]")
    echo "$awk_code" > "$TMP/CODE"

    # Perform the clan money transaction with the extracted code
    printf "/clan/${CLD}/money/?r=$(cat $TMP/CODE)&silver=1000&gold=0&confirm=true&type=limit\n"
    fetch_page "${URL}/clan/${CLD}/money/?r=$(cat $TMP/CODE)&silver=1000&gold=0&confirm=true&type=limit"

    # Repeat the fetch and transaction
    fetch_page "${URL}/arena/quit"
    awk_code=$(sed "s/href='/\n/g" "$TMP/SRC" | grep "attack/1" | head -n 1 | awk -F\/ '{ print $5 }' | tr -cd "[[:digit:]]")
    echo "$awk_code" > "$TMP/CODE"

    printf "/clan/${CLD}/money/?r=$(cat $TMP/CODE)&silver=1000&gold=0&confirm=true&type=limit\n"
    fetch_page "${URL}/clan/${CLD}/money/?r=$(cat $TMP/CODE)&silver=1000&gold=0&confirm=true&type=limit"

    printf "Clan money (✔)\n"
  fi
}
