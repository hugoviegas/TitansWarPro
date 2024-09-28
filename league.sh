fetch_available_fights() {
    fetch_page "/league/" "LEAGUE_DEBUG_SRC"
    
    # Verifica se o arquivo foi criado
    if [ -f "$TMP/LEAGUE_DEBUG_SRC" ]; then
        echo " Looking for available"
        
        # Removendo tudo antes de "<b>" e depois do número
        AVAILABLE_FIGHTS=$(grep -o -E '<b>[0-5]</b>' "$TMP/LEAGUE_DEBUG_SRC" | head -n 1 | sed -n 's/.*<b>\([0-5]\)<\/b>.*/\1/p')
        echo "Fights left: $AVAILABLE_FIGHTS"
    else
        echo "O arquivo LEAGUE_DEBUG_SRC não foi encontrado."
        AVAILABLE_FIGHTS=0  # Define como 0 se o arquivo não for encontrado
    fi
}

# Function to get enemy stats
get_enemy_stat() {
    local index=$1
    local stat_num=$2
    local stat

    # Loop to find the valid stat
    while true; do
        # Extract the stat using grep and sed
        stat=$(grep -o -E ': [0-9]+' "$TMP"/SRC | sed -n "$((index + stat_num))s/: //p" | tr -d '()' | tr -d ' ')

        # Check if the stat is valid (not empty and greater than 49)
        if [[ -n "$stat" && "$stat" -gt 49 ]]; then
            echo "$stat"
            return
        fi
        
        # Increment the stat_num to check the next one
        ((stat_num++))
    done
}

league_play() {
    echo -e "${GOLD_BLACK}League ⚔️${COLOR_RESET}"

    # Assuming you have a way to get the player's strength
    PLAYER_STRENGTH=$(player_stats)  # Call your existing player_stats function

    # Fetch the number of available fights
    fetch_available_fights

    # Fetch the league page
    fetch_page "/league/"

    # Extract all valid enemy links from the league page
    mapfile -t ENEMY_LINKS < <(grep -o -E "${URL}/league/fight/[0-9]{1,3}/\?r=[0-9]{1,8}" "$TMP"/SRC)

    # Loop through each extracted enemy link
    for click in "${ENEMY_LINKS[@]}"; do
        ENEMY_NUMBER=$(echo "$click" | grep -o -E '[0-9]{1,3}' | head -n 1)  # Extract the enemy number
        
        # Validate that ENEMY_NUMBER is between 1 and 999
        if [[ "$ENEMY_NUMBER" =~ ^[1-9][0-9]{0,2}$ ]] && [ "$ENEMY_NUMBER" -le 999 ]; then
            echo "Valid enemy number: $ENEMY_NUMBER"
        else
            echo "Invalid enemy number: $ENEMY_NUMBER. It must be between 1 and 999."
            continue  # Skip if the enemy number is invalid
        fi

        # Extract enemy stats
        INDEX=$((${#ENEMY_LINKS[@]} - ${#ENEMY_LINKS[@]} + 1))  # Get the current index in the loop
        E_STRENGTH=$(get_enemy_stat "$INDEX" 1)  # 1st stat
        E_HEALTH=$(get_enemy_stat "$INDEX" 2)    # 2nd stat
        E_AGILITY=$(get_enemy_stat "$INDEX" 3)   # 3rd stat
        E_PROTECTION=$(get_enemy_stat "$INDEX" 4) # 4th stat

        # Print enemy stats
        echo -e "Enemy Stats:\n"
        echo -e "${E_STRENGTH:-0}"
        echo -e "${E_HEALTH:-0}"
        echo -e "${E_AGILITY:-0}"
        echo -e "${E_PROTECTION:-0}"

        # Ensure all values are integers before comparing
        E_STRENGTH=${E_STRENGTH:-0}
        E_HEALTH=${E_HEALTH:-0}
        E_AGILITY=${E_AGILITY:-0}
        E_PROTECTION=${E_PROTECTION:-0}

        # Check if PLAYER_STRENGTH is a valid integer
        if [[ "$PLAYER_STRENGTH" =~ ^[0-9]+$ ]] && [[ "$E_STRENGTH" =~ ^[0-9]+$ ]]; then
            # Compare player's strength with enemy's strength using -gt
            if [ "$PLAYER_STRENGTH" -gt "$E_STRENGTH" ]; then
                echo "Player's strength ($PLAYER_STRENGTH) is greater than enemy's strength ($E_STRENGTH)."
                echo "Fight initiated with enemy number $ENEMY_NUMBER ✅"
                fetch_page "$click"

                # After the fight, update the available fights
                fetch_available_fights

                # Check if available fights are 0 after the update
                if (( AVAILABLE_FIGHTS <= 0 )); then
                    echo "No more available fights. Exiting league play."
                    return
                fi
            else
                echo "Player's strength ($PLAYER_STRENGTH) is not sufficient to attack enemy's strength ($E_STRENGTH). Skipping to next enemy."
            fi
        else
            echo "DEBUG: Invalid values - Player Strength: '$PLAYER_STRENGTH', Enemy Strength: '$E_STRENGTH'"
        fi
    done

    echo -e "${GREEN_BLACK}League Routine Completed ✅${COLOR_RESET}\n"
}


# https://furiadetitas.net/league/takeReward/?r=52027565# Calculate indices for the current enemy's stats