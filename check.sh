check_missions() {
    echo -e "${GOLD_BLACK}Checking Missions 📜${COLOR_RESET}"

    # Fetch the quest page
    fetch_page "/quest/"

    # Open chests for the first two chests
    for i in {1..2}; do
        if grep -o -E "/quest/openChest/$i/[?]r=[0-9]+" "$TMP/SRC"; then
            local click
            click=$(grep -o -E "/quest/openChest/$i/[?]r=[0-9]+" "$TMP/SRC" | head -n1)
            # Fetch the chest opening URL
            fetch_page "$click"
            
            # Confirm chest opening
            echo -e "${GREEN_BLACK}Chest $i opened ✅${COLOR_RESET}"
        fi
    done

    # Collect quests 
    i=0

    # Fetch the quest page again to check for quest completions
    

    for i in {0..15}; do
        fetch_page "/quest/"
        if grep -o -E "/quest/end/${i}[?]r=[0-9]+" "$TMP/SRC"; then
            click=$(grep -o -E "/quest/end/${i}[?]r=[0-9]+" "$TMP/SRC" | sed -n '1p' | cat)
            fetch_page "$click"
            MISSION_NUMBER=$(echo "$click" | cut -d'/' -f5 | cut -d'?' -f1)
            echo -e "${GREEN_BLACK} Mission [$MISSION_NUMBER] Completed ✅${COLOR_RESET}"
        fi
    done

    # Collect rewards from relics

    for i in {0..11}; do
        fetch_page "/relic/reward/"
        if grep -o -E "/relic/reward/${i}/[?]r=[0-9]+" "$TMP/SRC"; then
            click=$(grep -o -E "/relic/reward/${i}/[?]r=[0-9]+" "$TMP/SRC" | sed -n '1p' | cat)
            fetch_page "$click"
            echo -e " ${GREEN_BLACK}Relic [$i] collected ✅${COLOR_RESET}"
        fi
    done

    # Collect collections from the collector page
    fetch_page "/collector/"
    if grep -o -E "/collector/reward/element/[?]r=[0-9]+" "$TMP"/SRC; then
        click=$(grep -o -E '/collector/reward/element/[?]r=[0-9]+' "$TMP"/SRC | cat -)
        fetch_page "$click"
        echo -e "${GREEN_BLACK}Collection collected ✅${COLOR_RESET}\n"
    fi
  echo -e "${GREEN_BLACK}Missions ✅${COLOR_RESET}\n"
}

apply_event() {
  # Apply to fight
  event=("$@")  # Store arguments as an array

  fetch_page "/${event[*]}/"
  if grep -o -E "/${event[*]}/enter(Game|Fight)/[?]r=[0-9]+" "$TMP"/SRC; then
    APPLY=$(grep -o -E "/${event[*]}/enter(Game|Fight)/[?]r=[0-9]+" "$TMP"/SRC | cat -)
    fetch_page "${APPLY}"

    echo -e "${BLACK_YELLOW}Applied for battle ✅${COLOR_RESET}\n"
  fi
}

use_elixir() {
    # Initial fetch to get the starting URLs
    fetch_page "/inv/chest/"

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
        fetch_page "$click"
    done

    echo -e "${BLACK_YELLOW}Applied all elixir 💊${COLOR_RESET}\n"
}