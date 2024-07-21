league_play() {
(
  w3m -cookie -o http_proxy=$PROXY -o accept_encoding=UTF-8 -debug -dump_source "${URL}/quest/" -o user_agent="$(shuf -n1 $TMP/userAgent.txt)" >$TMP/SRC
) </dev/null &>/dev/null &
time_exit 20
#if grep -q -o -E '/league/[?]quest_t[=]quest&quest_id[=]7&qz[=][a-z0-9]+' $TMP/SRC; then
  echo -e "${GOLD_BLACK}League ⚔️${COLOR_RESET}"
  #for num in $(seq 5 -1 1); do
    # Define input and output files
    input_file="$TMP/league_file"
    output_file="$TMP/cleaned_league_file"

    # Fetch the webpage and save it to SRC
  (
    w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}/league/" -o user_agent="$(shuf -n1 $TMP/userAgent.txt)" >"$TMP/SRC"
  ) </dev/null &>/dev/null &
  time_exit 20

  (
    w3m -cookie -o http_proxy=$PROXY -o accept_encoding=UTF-8 -dump "${URL}/league/" -o user_agent="$(shuf -n1 $TMP/userAgent.txt)" | sed -ne '/images/icon/2hit.png/,/display:inline-block;text-align:left/' >>$TMP/league_players
  ) </dev/null &>/dev/null &
  time_exit 20

  # Wait for the background process to finish
  wait

  # Copy SRC to input_file
  cp "$TMP/SRC" "$input_file"

  # Extract the first occurrence of the desired pattern
  ATK=$(grep -o -E '/league/fight/[0-9]{1,4}/[?]r=[0-9]+' "$TMP/SRC" | sed -n '1p')
  echo -e "$ATK"

  # Initialize variables to hold sums
sum_str=0
sum_vit=0
sum_agi=0
sum_def=0

# Read the input file line by line
while IFS= read -r line; do
    # Extract values for each stat from the current line
    str_value=$(echo "$line" | grep -o -E "alt='str'/> Força: [0-9]+" | awk '{print $NF}')
    vit_value=$(echo "$line" | grep -o -E "alt='vit'/> Saúde: [0-9]+" | awk '{print $NF}')
    agi_value=$(echo "$line" | grep -o -E "alt='agi'/> Agilidade: [0-9]+" | awk '{print $NF}')
    def_value=$(echo "$line" | grep -o -E "alt='def'/> Proteção: [0-9]+" | awk '{print $NF}')

    # Sum the values if they are not empty
    if [[ -n $str_value ]]; then
        sum_str=$((sum_str + str_value))
    fi
    if [[ -n $vit_value ]]; then
        sum_vit=$((sum_vit + vit_value))
    fi
    if [[ -n $agi_value ]]; then
        sum_agi=$((sum_agi + agi_value))
    fi
    if [[ -n $def_value ]]; then
        sum_def=$((sum_def + def_value))
    fi
done < "$input_file"

# Output the results
echo "Total Força: $sum_str"
echo "Total Saúde: $sum_vit"
echo "Total Agilidade: $sum_agi"
echo "Total Proteção: $sum_def"

# Print the results to the console (optional)
#cat "$output_file"
    #done
    echo -e "${GREEN_BLACK}League ✅${COLOR_RESET}\n"
  #fi
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
