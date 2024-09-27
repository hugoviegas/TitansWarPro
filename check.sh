check_missions() {
    echo -e "${GOLD_BLACK}Checking Missions 📜${COLOR_RESET}"

    # Fetch the quest page
    (
        w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}/quest/" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" > "$TMP/SRC"
    ) </dev/null &>/dev/null &  # Run in background and suppress output
    time_exit 20  # Wait for the process to finish

    # Open chests for the first two chests
    for i in {1..2}; do
        if grep -o -E "/quest/openChest/$i/[?]r=[0-9]+" "$TMP/SRC"; then
            click=$(grep -o -E "/quest/openChest/$i/[?]r=[0-9]+" "$TMP"/SRC | cat -)
            (
                w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}/$click" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" > "$TMP/SRC"
            ) </dev/null &>/dev/null &  # Run in background and suppress output
            time_exit 20  # Wait for the process to finish
            echo -e "${GREEN_BLACK}Chest opened ✅${COLOR_RESET}"
        fi
    done

    # Collect quests 
    i=0

    # Fetch the quest page again to check for quest completions
    (
        w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}/quest/" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" > "$TMP/SRC"
    ) </dev/null &>/dev/null &  # Run in background and suppress output
    time_exit 20  # Wait for the process to finish

    for i in {0..15}; do
        if grep -o -E "/quest/end/${i}[?]r[=][0-9]+" "$TMP"/SRC; then
            click=$(grep -o -E "/quest/end/${i}[?]r[=][0-9]+" "$TMP"/SRC | sed -n '1p' | cat -)
            (
                w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}${click}" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" > "$TMP/SRC"
            ) </dev/null &>/dev/null &  # Run in background and suppress output
            time_exit 20  # Wait for the process to finish
            #MISSION_NUMBER=$(echo "$click" | cut -d'/' -f5 | cut -d'?' -f1)
            echo -e "${GREEN_BLACK} Mission [$i] Completed ✅${COLOR_RESET}"
        fi
    done

    # Collect rewards from relics
    (
        w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug --dump_source "${URL}/relic/reward/" --user_agent="$(shuf-n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
    ) </dev/null &>/dev/null &  # Run in background and suppress output
    time_exit 20  # Wait for the process to finish

    i=0
    for i in {0..11}; do
        if grep -o -E "/relic/reward/${i}/[?]r[=][0-9]+" "$TMP"/SRC; then
            click=$(grep -o -E "/relic/reward/${i}/[?]r[=][0-9]+" "$TMP"/SRC | sed -n '1p' | cat -)
            (
        w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}${click}" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
      ) </dev/null &>/dev/null &
      time_exit 20
      echo -e " ${GREEN_BLACK}Relic [$i] collected ✅${COLOR_RESET}"
        fi
    done

    # Collect collections from the collector page
    (
    w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}/collector/" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
  ) </dev/null &>/dev/null &
  time_exit 20
  if grep -o -E "/collector/reward/element/[?]r=[0-9]+" "$TMP"/SRC; then
    click=$(grep -o -E '/collector/reward/element/[?]r=[0-9]+' "$TMP"/SRC | cat -)
        (
      w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}${click}" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
    ) </dev/null &>/dev/null &
    time_exit 20
    echo -e "${GREEN_BLACK}Collection collected ✅${COLOR_RESET}\n"
    fi
  echo -e "${GREEN_BLACK}Missions ✅${COLOR_RESET}\n"
}

apply_event() {
  # Apply to fight
  event=("$@")  # Store arguments as an array
  (
    w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}/$event/" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
  ) </dev/null &>/dev/null &
  time_exit 20
  if grep -o -E "/$event/enter(Game|Fight)/[?]r=[0-9]+" "$TMP"/SRC; then
    APPLY=$(grep -o -E "/$event/enter(Game|Fight)/[?]r=[0-9]+" "$TMP"/SRC | cat -)
    (
      w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}${APPLY}" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
    ) </dev/null &>/dev/null &
    time_exit 20
    echo -e "${BLACK_YELLOW}Applied for battle ✅${COLOR_RESET}\n"
  fi
}

use_elixir() {
    # Initial fetch to get the starting URLs
    (
        w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}/inv/chest/" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
    ) </dev/null &>/dev/null &  # Run in background and suppress output
    time_exit 20  # Wait for the process to finish

    # Loop to process clicks
    for ((i=1; i<=4; i++)); do
        # Capture the i-th match into a variable
        click=$(grep -o -E "/inv/chest/use/[0-9]+/1/[?]r=[0-9]+" "$TMP/SRC" | sed -n "${i}p")

        # Break the loop if no more clicks are found
        if [[ -z "$click" ]]; then
            echo "No more URLs to process."
            break
        fi

        # Using all elixir
        (
            w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}$click" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
        ) </dev/null &>/dev/null &  # Run in background and suppress output
        time_exit 20  # Wait for the process to finish
    done

    echo -e "${BLACK_YELLOW}Applied all elixir 💊${COLOR_RESET}\n"
}