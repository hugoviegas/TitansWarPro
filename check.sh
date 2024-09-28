check_missions() {
    echo -e "${GOLD_BLACK}Checking Missions 📜${COLOR_RESET}"

    # Fetch the quest page and relic rewards once
    fetch_page "/quest/"
    quest_page="$TMP/SRC"  # Store the fetched quest page content
    fetch_page "/relic/reward/"
    relic_page="$TMP/SRC"  # Store the fetched relic page content
    fetch_page "/collector/"
    collector_page="$TMP/SRC"  # Store the fetched collector page content

    # Open chests for the first two chests
    for i in {1..2}; do
        if click=$(grep -o -E "/quest/openChest/$i/[?]r=[0-9]+" "$quest_page" | head -n1); then
            fetch_page "$click"  # Fetch the chest opening URL
            echo -e "${GREEN_BLACK}Chest $i opened ✅${COLOR_RESET}"
        fi
    done

    # Collect completed quests
    for i in {0..15}; do
        if click=$(grep -o -E "/quest/end/${i}[?]r=[0-9]+" "$quest_page" | sed -n '1p'); then
            fetch_page "$click"  # Fetch the mission completion URL
            MISSION_NUMBER=$(echo "$click" | cut -d'/' -f5 | cut -d'?' -f1)
            echo -e "${GREEN_BLACK} Mission [$MISSION_NUMBER] Completed ✅${COLOR_RESET}"
        fi
    done

    # Collect rewards from relics
    for i in {0..11}; do
        if click=$(grep -o -E "/relic/reward/${i}/[?]r=[0-9]+" "$relic_page"); then
            fetch_page "$click"  # Fetch the relic reward URL
            echo -e " ${GREEN_BLACK}Relic [$i] collected ✅${COLOR_RESET}"
        fi
    done

    # Collect collections from the collector page
    if click=$(grep -o -E "/collector/reward/element/[?]r=[0-9]+" "$collector_page"); then
        fetch_page "$click"  # Fetch the collection reward URL
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