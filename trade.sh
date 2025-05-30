func_trade() {
  echo_t "Trade" "${GOLD_BLACK}" "${COLOR_RESET}" "after" "⚖️"

    # Fetch the trade exchange page
    fetch_page "/trade/exchange"

    # Extract the first access link for silver exchange
    local ACCESS=$(grep -o -E '/trade/exchange/silver/[0-9]+[?]r[=][0-9]+' "$TMP/SRC" | head -n 1)
    
    # Set a timeout for accessing the exchange
    local BREAK=$(($(date +%s) + 30))  # 30 seconds from now

    # Loop until a valid ACCESS link is found or timeout occurs
    until [ -z "$ACCESS" ] || [ "$(date +%s)" -gt "$BREAK" ]; do
        SILVER_NUMBER=$(echo "$ACCESS" | cut -d'/' -f5 | cut -d'?' -f1)  # Extract silver amount

        echo_t "Exchange " "" "" "before" "" && echo -e "${GOLD_BLACK}$SILVER_NUMBER🪙${COLOR_RESET}"

        # Fetch the specific silver exchange details
        fetch_page "$ACCESS"

        # Update ACCESS with the next available silver exchange link
        ACCESS=$(grep -o -E '/trade/exchange/silver/[0-9]+[?]r[=][0-9]+' "$TMP/SRC" | head -n 1)
    done
    echo_t "Trade " "${GREEN_BLACK}" "${COLOR_RESET}" "after" "⚖️✅\n"
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
