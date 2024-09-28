fetch_available_fights() {
    fetch_page "/league/"
    
    # Verifica se o arquivo foi criado
    if [ -f "$TMP/LEAGUE_DEBUG_SRC" ]; then
        echo "Procurando número de lutas disponíveis..."
        
        # Removendo tudo antes de "<b>" e depois do número
        AVAILABLE_FIGHTS=$(grep -o -E ': [0-9]+' "$TMP/LEAGUE_DEBUG_SRC" | sed -n '1s/: //p' | tr -d '()' | tr -d ' ')
        echo "DEBUG: Fights: $AVAILABLE_FIGHTS"
    else
        echo "O arquivo LEAGUE_DEBUG_SRC não foi encontrado."
        AVAILABLE_FIGHTS=0  # Define como 0 se o arquivo não for encontrado
    fi
}

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
    E_STRENGTH=$(grep -o -E ': [0-9]+' "$TMP"/SRC | sed -n "$((INDEX + 1))s/: //p" | tr -d '()' | tr -d ' ')  # 1st stat
    E_HEALTH=$(grep -o -E ': [0-9]+' "$TMP"/SRC | sed -n "$((INDEX + 2))s/: //p" | tr -d '()' | tr -d ' ')   # 2nd stat
    E_AGILITY=$(grep -o -E ': [0-9]+' "$TMP"/SRC | sed -n "$((INDEX + 3))s/: //p" | tr -d '()' | tr -d ' ')  # 3rd stat
    E_PROTECTION=$(grep -o -E ': [0-9]+' "$TMP"/SRC | sed -n "$((INDEX + 4))s/: //p" | tr -d '()' | tr -d ' ') # 4th stat

    # Print enemy stats along with the enemy number
    #echo -e "Enemy Number: $ENEMY_NUMBER"
    echo -e "Enemy Stats:\n"
    echo -e "${E_STRENGTH:-0}"  # Default to 0 if empty
    echo -e "${E_HEALTH:-0}"      # Default to 0 if empty
    echo -e "${E_AGILITY:-0}"    # Default to 0 if empty
    echo -e "${E_PROTECTION:-0}"  # Default to 0 if empty

    # Ensure all values are integers before comparing
    E_STRENGTH=${E_STRENGTH:-0}
    E_HEALTH=${E_HEALTH:-0}
    E_AGILITY=${E_AGILITY:-0}
    E_PROTECTION=${E_PROTECTION:-0}
    echo " --- "
    PLAYER_STRENGTH=$(echo "$PLAYER_STRENGTH" | xargs)
    E_STRENGTH=$(echo "$E_STRENGTH" | xargs)

    # Extract the fight button for the current enemy
    click=$(grep -o -E '/league/fight/[0-9]+/\?r=[0-9]+' "$TMP"/SRC | sed -n "$((i))p")  # Get the i-th fight button
    ENEMY_NUMBER=$(echo "$click" | grep -o -E '/fight/[0-9]+' | grep -o -E '[0-9]+')

    # Check if a fight button was found
    if [ -n "$click" ]; then
      echo "Found fight button: $URL$click"

      # Check if PLAYER_STRENGTH is a valid integer
      if [[ "$PLAYER_STRENGTH" =~ ^[0-9]+$ ]] && [[ "$E_STRENGTH" =~ ^[0-9]+$ ]]; then
        # Compare player's strength with enemy's strength using -gt
        if [ "$PLAYER_STRENGTH" -gt "$E_STRENGTH" ]; then
            echo "Player's strength ($PLAYER_STRENGTH) is greater than enemy's strength ($E_STRENGTH)."
            echo "Fight $i initiated with enemy number $ENEMY_NUMBER ✅"
            #fetch_page "$click"
        else
            echo "Player's strength ($PLAYER_STRENGTH) is not sufficient to attack enemy's strength ($E_STRENGTH). Skipping to next enemy."
        continue
        fi
      else
      echo "DEBUG: Invalid values - Player Strength: '$PLAYER_STRENGTH', Enemy Strength: '$E_STRENGTH'"
    fi
      echo "No fight buttons found on attempt $i ❌"
      break
    fi
  done

  echo -e "${GREEN_BLACK}League Routine Completed ✅${COLOR_RESET}\n"
}

# https://furiadetitas.net/league/takeReward/?r=52027565# Calculate indices for the current enemy's stats