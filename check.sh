check_missions() {
    echo_t "Checking Missions" "${GOLD_BLACK}" "${COLOR_RESET}" "after" "📜"
    # Open chests for the first two chests
    fetch_page "/quest/"
    for i in {1..2}; do
    local click
    click=$(grep -o -E "/quest/openChest/$i/[?]r=[0-9]+" "$TMP/SRC" | head -n1)
        if [ -n "$click" ]; then
            fetch_page "$click"  # Fetch the chest opening URL
            echo -e "${GREEN_BLACK}Chest ${i} opened ✅${COLOR_RESET}"
        fi
    done

    # Collect completed quests
    for i in {0..16}; do
    local click
    click=$(grep -o -E "/quest/end/${i}[?]r=[0-9]+" "$TMP/SRC" | sed -n '1p')
        if [ -n "$click" ]; then
            fetch_page "$click"  # Fetch the mission completion URL
            echo_t " Mission ${i} Completed" "${GREEN_BLACK}" "${COLOR_RESET}" "after" "✅\n"
        fi
    done

    # Collect collections from the collector page
    fetch_page "/collector/"
    if click=$(grep -o -E "/collector/reward/element/[?]r=[0-9]+" "$TMP/SRC"); then
        fetch_page "$click"  # Fetch the collection reward URL
        echo_t "Collection collected" "${GREEN_BLACK}" "${COLOR_RESET}" "after" "✅\n"
    fi
    echo_t "Missions" "${GREEN_BLACK}" "${COLOR_RESET}" "after" "✅\n"

}

check_rewards(){
    if [ "$FUNC_rewards" = "n" ]; then
        return
    fi
    # Collect rewards from relics
    fetch_page "/relic/reward/"
    for i in {0..11}; do
    local click
    click=$(grep -o -E "/relic/reward/${i}/[?]r=[0-9]+" "$TMP/SRC")
        if [ -n "$click" ]; then
            fetch_page "$click"  # Fetch the relic reward URL
            echo_t "Relic ${i} collected" "${GREEN_BLACK}" "${COLOR_RESET}" "after" "✅\n"
        fi
    done
}

apply_event() {
  # Apply to fight
  local event_path="${1}"  # Use primeiro argumento diretamente
  fetch_page "/${event_path}/"
  if grep -o -E "/${event_path}/enter(Game|Fight)/[?]r=[0-9]+" "$TMP"/SRC; then
    APPLY=$(grep -o -E "/${event_path}/enter(Game|Fight)/[?]r=[0-9]+" "$TMP"/SRC)
    fetch_page "$APPLY"
    echo_t "Applied for battle" "${BLACK_YELLOW}" "${COLOR_RESET}" "after" "✅\n"
  fi
}

use_elixir() {
    if [ "$FUNC_elixir" = "n" ]; then
        return
    fi
    # Initial fetch to get the starting URLs
    fetch_page "/inv/chest/"

    # Loop to process clicks
    for ((i=1; i<=4; i++)); do
        # Capture the i-th match into a variable
        click=$(grep -o -E "/inv/chest/use/[0-9]+/1/[?]r=[0-9]+" "$TMP/SRC" | sed -n "${i}p")

        # Break the loop if no more clicks are found
        if [[ -z "$click" ]]; then
            echo_t "No more URLs to process."
            break
        fi

        # Using all elixir
        fetch_page "$click"
    done

    echo_t "Applied all elixir" "${BLACK_YELLOW}" "${COLOR_RESET}" "after" "💊"
}