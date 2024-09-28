league_play() {
  echo -e "${GOLD_BLACK}League ⚔️${COLOR_RESET}"

  # Assuming you have a way to get the player's strength
  PLAYER_STRENGTH=$(player_stats)  # Call your existing player_stats function

  # Loop to click the first fight button 5 times
  for i in {1..5}; do
    # Fetch the league page
    fetch_page "/league/"

    # Calculate indices for the current enemy's stats
    INDEX=$(( (i - 1) * 4 ))  # Calculate the starting index for each enemy (0-based)

    # Extracting enemy stats using grep and sed
    E_STRENGTH=$(grep -o -E ': [0-9]+' "$TMP"/SRC | sed -n "$((INDEX + 1))s/: //p")  # 1st stat
    E_HEALTH=$(grep -o -E ': [0-9]+' "$TMP"/SRC | sed -n "$((INDEX + 2))s/: //p")   # 2nd stat
    E_AGILITY=$(grep -o -E ': [0-9]+' "$TMP"/SRC | sed -n "$((INDEX + 3))s/: //p")  # 3rd stat
    E_PROTECTION=$(grep -o -E ': [0-9]+' "$TMP"/SRC | sed -n "$((INDEX + 4))s/: //p") # 4th stat

    # Extract the fight button for the current enemy
    click=$(grep -o -E '/league/fight/[0-9]+/\?r=[0-9]+' "$TMP"/SRC | sed -n "${i}p")  # Get the i-th fight button
    ENEMY_NUMBER=$(echo "$click" | grep -o -E '[0-9]+' | head -n 1)

    # Print enemy stats along with the enemy number
    echo -e "Enemy Number: $ENEMY_NUMBER"
    echo -e "Enemy Stats:\n"
    echo -e "Strength: $E_STRENGTH"
    echo -e "Health: $E_HEALTH"
    echo -e "Agility: $E_AGILITY"
    echo -e "Protection: $E_PROTECTION"

    # Check if a fight button was found
    if [ -n "$click" ]; then
      echo "Found fight button: $URL$click"

      # Compare player's strength with enemy's strength using -gt
      if [ "$PLAYER_STRENGTH" -gt "$E_STRENGTH" ]; then
        echo "Player's strength ($PLAYER_STRENGTH) is greater than enemy's strength ($E_STRENGTH)."
        echo "Fight $i initiated with enemy number $ENEMY_NUMBER ✅"

        # Click the first fight button (fetch the page)
        fetch_page "$click"
      else
        echo "Player's strength ($PLAYER_STRENGTH) is not sufficient to attack enemy's strength ($E_STRENGTH). Skipping to next enemy."
        continue  # Move to the next iteration without clicking the fight button
      fi
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
