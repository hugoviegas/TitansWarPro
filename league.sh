league_play() {
    echo -e "${GOLD_BLACK}League ⚔️${COLOR_RESET}"

    # Get player's strength
    PLAYER_STRENGTH=$(player_stats)

    # Fetch available fights before starting the loop
    fetch_available_fights
    AVAILABLE_FIGHTS=$(grep -o -E ':</b> [0-9]+' "$TMP/LEAGUE_DEBUG_SRC" | grep -o -E '[0-9]+' | head -n 1)

    # Loop until there are no available fights left
    while (( AVAILABLE_FIGHTS > 0 )); do
        # Fetch the league page
        fetch_page "/league/"

        # Calculate indices for the current enemy's stats
        INDEX=$(( (5 - AVAILABLE_FIGHTS) * 4 ))  # Calculate the starting index for each enemy (0-based)

        # Extracting enemy stats using grep and sed
        E_STRENGTH=$(grep -o -E ': [0-9]+' "$TMP"/SRC | sed -n "$((INDEX + 1))s/: //p" | tr -d '()' | tr -d ' ')
        E_HEALTH=$(grep -o -E ': [0-9]+' "$TMP"/SRC | sed -n "$((INDEX + 2))s/: //p" | tr -d '()' | tr -d ' ')
        E_AGILITY=$(grep -o -E ': [0-9]+' "$TMP"/SRC | sed -n "$((INDEX + 3))s/: //p" | tr -d '()' | tr -d ' ')
        E_PROTECTION=$(grep -o -E ': [0-9]+' "$TMP"/SRC | sed -n "$((INDEX + 4))s/: //p" | tr -d '()' | tr -d ' ')

        # Extract the fight button for the current enemy
        click=$(grep -o -E '/league/fight/[0-9]+/\?r=[0-9]+' "$TMP"/SRC | sed -n "1p")  # Get the first fight button
        ENEMY_NUMBER=$(echo "$click" | grep -o -E '[0-9]+' | head -n 1)

        # Ensure all values are integers before comparing
        E_STRENGTH=${E_STRENGTH:-0}
        PLAYER_STRENGTH=$(echo "$PLAYER_STRENGTH" | xargs)
        E_STRENGTH=$(echo "$E_STRENGTH" | xargs)

        # Check if a fight button was found
        if [ -n "$click" ]; then
            echo "Found fight button: $URL$click"

            # Check if PLAYER_STRENGTH is a valid integer
            if [[ "$PLAYER_STRENGTH" =~ ^[0-9]+$ ]] && [[ "$E_STRENGTH" =~ ^[0-9]+$ ]]; then
                # Compare player's strength with enemy's strength using -gt
                if [ "$PLAYER_STRENGTH" -gt "$E_STRENGTH" ]; then
                    echo "Player's strength ($PLAYER_STRENGTH) is greater than enemy's strength ($E_STRENGTH)."
                    echo "Fight initiated with enemy number $ENEMY_NUMBER ✅"
                    fetch_page "$click"

                    # Decrement available fights
                    (( AVAILABLE_FIGHTS-- ))
                else
                    echo "Player's strength ($PLAYER_STRENGTH) is not sufficient to attack enemy's strength ($E_STRENGTH). Skipping to next enemy."
                    (( AVAILABLE_FIGHTS-- ))  # Also decrement fights even if the attack didn't happen
                fi
            else
                echo "Invalid player strength or enemy strength. Skipping to next enemy."
                (( AVAILABLE_FIGHTS-- ))
            fi
        else
            echo "No fight buttons found. Exiting loop."
            break
        fi
    done

    echo -e "${GREEN_BLACK}League Routine Completed ✅${COLOR_RESET}\n"
}

# https://furiadetitas.net/league/takeReward/?r=52027565