league_play() {
  echo -e "${GOLD_BLACK}League ⚔️${COLOR_RESET}"
  # Fetch the league page
    fetch_page "/league/"

    # Loop to click the first fight button 5 times
    for i in {1..5}; do
        # Extract the first available fight button
        click=$(grep -o -E '/league/fight/[0-9]+/\?r=[0-9]+' "$TMP"/SRC | sed -n '1p')

        # Check if a fight button was found
        if [ -n "$click" ]; then
            echo "Found fight button: $URL$click"

            # Click the first fight button (fetch the page)
            fetch_page "$click"
            echo "Fight $i initiated with player $(echo "$click" | cut -d'/' -f4) ✅"

            # Fetch the updated league page for the next round
            fetch_page "/league/"
        else
            echo "No fight buttons found on attempt $i ❌"
            break
        fi
    done

    echo -e "${GREEN_BLACK}League Routine Completed ✅${COLOR_RESET}\n"
}

league_test() {
  (
        w3m -cookie -o http_proxy=$PROXY -o accept_encoding=UTF-8 -debug -dump_source "${URL}${ATK}" -o user_agent="$(shuf -n1 $TMP/userAgent.txt)" >$TMP/SRC
      ) </dev/null &>/dev/null &
      time_exit 20
    (
      w3m -cookie -o http_proxy=$PROXY -o accept_encoding=UTF-8 -debug -dump_source "${URL}/quest/" -o user_agent="$(shuf -n1 $TMP/userAgent.txt)" >$TMP/SRC
    ) </dev/null &>/dev/null &
    time_exit 20
    QUEST_END=$(grep -o -E '/quest/end/7[?]r[=][0-9]+' $TMP/SRC)
    if [ ! -z $QUEST_END ]; then
      (
        w3m -cookie -o http_proxy=$PROXY -o accept_encoding=UTF-8 -debug -dump_source "${URL}${QUEST_END}" -o user_agent="$(shuf -n1 $TMP/userAgent.txt)" >$TMP/SRC
      ) </dev/null &>/dev/null &
      time_exit 20
    fi



# Sample HTML content (you may want to read this from a file or URL)
output_file="$TMP/league_file"
echo "" > "$output_file"

# Extract values for each stat and write to file
for stat in "str" "vit" "agi" "def"; do
    value=$(echo "$output_file" | grep -o -E "alt='$stat'/> [^<]+" | head -n 1 | sed 's/.*: //')
    echo "$stat: $value" >> "$output_file"
done

# Read values from the file and sum them
total=0
while IFS=: read -r stat value; do
    total=$((total + value))
done < "$output_file"

# Output the results
echo "Values saved in $output_file:"
cat "$output_file"
echo "Total: $total"


}
