check_missions() {
    echo -e "${GOLD_BLACK}Checking Missions 📜${COLOR_RESET}"
    # Open chests for the first two chests
    fetch_page "/quest/"
    for i in {1..2}; do
    local click
    click=$(grep -o -E "/quest/openChest/$i/[?]r=[0-9]+" "$TMP/SRC" | head -n1)
        if [ -n "$click" ]; then
            fetch_page "$click"  # Fetch the chest opening URL
            echo -e "${GREEN_BLACK}Chest $i opened ✅${COLOR_RESET}"
        fi
    done

    # Collect completed quests
    for i in {0..16}; do
    local click
    click=$(grep -o -E "/quest/end/${i}[?]r=[0-9]+" "$TMP/SRC" | sed -n '1p')
        if [ -n "$click" ]; then
            fetch_page "$click"  # Fetch the mission completion URL
            echo -e "${GREEN_BLACK} Mission [$i] Completed ✅${COLOR_RESET}"
        fi
    done

    # Collect collections from the collector page
    fetch_page "/collector/"
    if click=$(grep -o -E "/collector/reward/element/[?]r=[0-9]+" "$TMP/SRC"); then
        fetch_page "$click"  # Fetch the collection reward URL
        echo -e "${GREEN_BLACK}Collection collected ✅${COLOR_RESET}\n"
    fi

    echo -e "${GREEN_BLACK}Missions ✅${COLOR_RESET}\n"

    clanElixirQuest
    clanMerchantQuest
}

check_rewards(){
    # Collect rewards from relics
    fetch_page "/relic/reward/"
    for i in {0..11}; do
    local click
    click=$(grep -o -E "/relic/reward/${i}/[?]r=[0-9]+" "$TMP/SRC")
        if [ -n "$click" ]; then
            fetch_page "$click"  # Fetch the relic reward URL
            echo -e " ${GREEN_BLACK}Relic [$i] collected ✅${COLOR_RESET}"
        fi
    done
}

apply_event() {
  # Apply to fight
  event=("$@")  # Store arguments as an array
  fetch_page "/$event/"
  if grep -o -E "/$event/enter(Game|Fight)/[?]r=[0-9]+" "$TMP"/SRC; then
    APPLY=$(grep -o -E "/$event/enter(Game|Fight)/[?]r=[0-9]+" "$TMP"/SRC)
    fetch_page "$APPLY"
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