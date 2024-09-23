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
    (
      w3m -cookie -o http_proxy=$PROXY -o accept_encoding=UTF-8 -debug -dump_source "${URL}/arena/quit" -o user_agent="$(shuf -n1 $TMP/userAgent.txt)" | sed "s/href='/\n/g" | grep "attack/1" | head -n 1 | awk -F\/ '{ print $5 }' | tr -cd "[[:digit:]]" >$TMP/CODE
    ) &
    time_exit 17
    printf "/clan/${CLD}/money/?r=$(cat $TMP/CODE)&silver=1000&gold=0&confirm=true&type=limit\n"
    (
      w3m -cookie -o http_proxy=$PROXY -o accept_encoding=UTF-8 -debug "${URL}/clan/${CLD}/money/?r=$(cat $TMP/CODE)&silver=1000&gold=0&confirm=true&type=limit" -o user_agent="$(shuf -n1 $TMP/userAgent.txt)" | tail -n 0
    ) &
    time_exit 17
    (
      w3m -cookie -o http_proxy=$PROXY -o accept_encoding=UTF-8 -debug -dump_source "${URL}/arena/quit" -o user_agent="$(shuf -n1 $TMP/userAgent.txt)" | sed "s/href='/\n/g" | grep "attack/1" | head -n 1 | awk -F\/ '{ print $5 }' | tr -cd "[[:digit:]]" >$TMP/CODE
    ) &
    time_exit 17
    printf "/clan/${CLD}/money/?r=$(cat $TMP/CODE)&silver=1000&gold=0&confirm=true&type=limit\n"
    (
      w3m -cookie -o http_proxy=$PROXY -o accept_encoding=UTF-8 -debug "${URL}/clan/${CLD}/money/?r=$(cat $TMP/CODE)&silver=1000&gold=0&confirm=true&type=limit" -o user_agent="$(shuf -n1 $TMP/userAgent.txt)" | tail -n 0
    ) &
    time_exit 17
    printf "Clan money (✔)\n"
  fi
}
clan_statue() {
  clan_id
  if [ -n "$CLD" ]; then
    printf "Clan built ...\n"
    (
      w3m -cookie -o http_proxy=$PROXY -o accept_encoding=UTF-8 -debug -dump_source "${URL}/arena/quit" -o user_agent="$(shuf -n1 $TMP/userAgent.txt)" | sed "s/href='/\n/g" | grep "attack/1" | head -n 1 | awk -F\/ '{ print $5 }' | tr -cd "[[:digit:]]" >$TMP/CODE
    ) &
    time_exit 17
    (
      w3m -cookie -o http_proxy=$PROXY -o accept_encoding=UTF-8 -debug "${URL}/clan/${CLD}/built/?goldUpgrade=true&r=$(cat $TMP/CODE)" -o user_agent="$(shuf -n1 $TMP/userAgent.txt)" | tail -n 0
    ) &
    time_exit 17
    printf "/clan/${CLD}/built/?goldUpgrade=true&r=$(cat $TMP/CODE)\n"
    (
      w3m -cookie -o http_proxy=$PROXY -o accept_encoding=UTF-8 -debug -dump_source "${URL}/arena/quit" -o user_agent="$(shuf -n1 $TMP/userAgent.txt)" | sed "s/href='/\n/g" | grep "attack/1" | head -n 1 | awk -F\/ '{ print $5 }' | tr -cd "[[:digit:]]" >$TMP/CODE
    ) &
    time_exit 17
    (
      w3m -cookie -o http_proxy=$PROXY -o accept_encoding=UTF-8 -debug "${URL}/clan/${CLD}/built/?silverUpgrade=true&r=$(cat $TMP/CODE)" -o user_agent="$(shuf -n1 $TMP/userAgent.txt)" | tail -n 0
    ) &
    time_exit 17
    printf "/clan/${CLD}/built/?silverUpgrade=true&r=$(cat $TMP/CODE)\n"
    printf "clan built (✔)\n"
  fi
}

clan_statue() {
    clan_id  # Retrieve the current clan ID

    if [ -n "$CLD" ]; then  # Proceed only if CLD is set (indicating a valid clan)
        echo "Clan built ..."

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

        echo "Clan built ✅"
    fi
}