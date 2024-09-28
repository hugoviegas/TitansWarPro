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

# Function to count the number of enemies available on the page
count_enemies() {
    # Search for valid enemy links inside href attributes
    grep -o -E "href='/league/fight/[0-9]{1,3}/\?r=[0-9]{1,8}'" "$TMP"/SRC | wc -l
}

# Function to get enemy links
get_enemy_links() {
    # Extract all valid enemy links into an array, removing the leading "href='"
    mapfile -t ENEMY_LINKS < <(grep -o -E "href='/league/fight/[0-9]{1,3}/\?r=[0-9]{1,8}'" "$TMP"/SRC | sed "s/href='//g" | sed "s/'//g")
}

league_play() {
    echo -e "${GOLD_BLACK}League ⚔️${COLOR_RESET}"

    # Assuming you have a way to get the player's strength
    PLAYER_STRENGTH=$(player_stats)  # Call your existing player_stats function

    # Fetch the league page
    fetch_page "/league/"

    # Debug: Output the content fetched
    echo "Content fetched from league page:"
    cat "$TMP"/SRC

    # Get enemy links
    get_enemy_links

    # Count the number of enemies
    local TOTAL_ENEMIES=${#ENEMY_LINKS[@]}
    echo "Enemies found: $TOTAL_ENEMIES"

    # Check if there are any enemies available
    if [ "$TOTAL_ENEMIES" -eq 0 ]; then
        echo "No enemies available for fighting."
        return
    fi

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

        # Fetch page and extract enemy stats
        fetch_page "$click"

        # Here, you'd extract and process enemy stats from the newly fetched page
        # Assuming you have a function to get stats; replace with your logic
        E_STRENGTH=$(get_enemy_stat "$ENEMY_NUMBER" 1)  # 1st stat
        E_HEALTH=$(get_enemy_stat "$ENEMY_NUMBER" 2)    # 2nd stat
        E_AGILITY=$(get_enemy_stat "$ENEMY_NUMBER" 3)   # 3rd stat
        E_PROTECTION=$(get_enemy_stat "$ENEMY_NUMBER" 4) # 4th stat

        # Print enemy stats
        echo -e "Enemy Stats:\nStrength: ${E_STRENGTH:-0}\nHealth: ${E_HEALTH:-0}\nAgility: ${E_AGILITY:-0}\nProtection: ${E_PROTECTION:-0}"

        # Ensure all values are integers before comparing
        E_STRENGTH=${E_STRENGTH:-0}

        # Compare player's strength with enemy's strength
        if [ "$PLAYER_STRENGTH" -gt "$E_STRENGTH" ]; then
            echo "Player's strength ($PLAYER_STRENGTH) is greater than enemy's strength ($E_STRENGTH)."
            echo "Fight initiated with enemy number $ENEMY_NUMBER ✅"
            # Insert logic for fight initiation here
        else
            echo "Player's strength ($PLAYER_STRENGTH) is not sufficient to attack enemy's strength ($E_STRENGTH). Skipping to next enemy."
        fi
    done

    echo -e "${GREEN_BLACK}League Routine Completed ✅${COLOR_RESET}\n"
}

# https://furiadetitas.net/league/takeReward/?r=52027565# Calculate indices for the current enemy's stats