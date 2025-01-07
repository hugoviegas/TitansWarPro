# shellcheck disable=SC2034
fetch_available_fights() {
    fetch_page "/league/" "LEAGUE_SRC"
    
    if [ -f "$TMP/LEAGUE_SRC" ]; then
        echo_t "Looking for available fights..."
        # Extract the number of available fights
        AVAILABLE_FIGHTS=$(grep -o -E '<b>[0-5]</b>' "$TMP/LEAGUE_SRC" | head -n 1 | sed -n 's/.*<b>\([0-5]\)<\/b>.*/\1/p')
        
        # Check if AVAILABLE_FIGHTS is a number
        if [[ "$AVAILABLE_FIGHTS" =~ ^[0-5]$ ]]; then
            echo_t "Available fights:" "" "$AVAILABLE_FIGHTS"
        else
            echo "Error: No available fights or not found." >> "$TMP/ERROR_DEBUG"
            AVAILABLE_FIGHTS=0
        fi
    else
        echo "The LEAGUE_SRC file was not found." >> "$TMP/ERROR_DEBUG"
        AVAILABLE_FIGHTS=0
    fi
    
    # Ensure AVAILABLE_FIGHTS is an integer
    AVAILABLE_FIGHTS=${AVAILABLE_FIGHTS:-0}
    
    # Return 0 if fights are available, 1 otherwise
    [ "$AVAILABLE_FIGHTS" -gt 0 ]
}

# Função para extrair estatísticas dos inimigos
get_enemy_stat() {
    local index=$1
    local stat_num=$2
    local stat
    local attempts=0
    local max_attempts=10  # Defina um limite de tentativas

    while (( attempts < max_attempts )); do
        stat=$(grep -o -E ': [0-9]+' "$TMP"/SRC | sed -n "$((index + stat_num))s/: //p" | tr -d '()' | tr -d ' ')

        if [[ -n "$stat" && "$stat" -gt 49 ]]; then
            echo "$stat"
            return
        fi
        ((stat_num++))
        ((attempts++))
    done

    echo "Error: Stat not found after $max_attempts attempts." >> "$TMP/ERROR_DEBUG"  # Mensagem de erro se não encontrar
    return 1  # Retorna um código de erro
}

# Função principal para jogar na liga
league_play() {
    echo -e "${GOLD_BLACK}League ⚔️${COLOR_RESET}"
    # FUNC_play_league=""  # Assign a value to FUNC_play_league
    load_config  # Carregar as configurações do arquivo de configuração
    checkQuest 2 apply
    checkQuest 1 apply

    PLAYER_STRENGTH=$(player_stats)  # Obtendo a força do jogador
    fetch_available_fights  # Buscando lutas disponíveis

    # Definir uma variável para controlar o estado do loop
    action="check_fights"
    fights_done=0
    j=1  # Index for fight buttons (skipping every 2 links)
    enemy_index=1  # Separate index for enemy stats

#[ "$fights_done" -lt "$AVAILABLE_FIGHTS" ] && 

    while [ "$AVAILABLE_FIGHTS" -gt 0 ]; do
        case "$action" in
            check_fights)
                #echo "DEBUG: Player Stats = $PLAYER_STRENGTH"
                #echo "DEBUG: Button j = $j"
                #echo "DEBUG: Enemy Index = $enemy_index"
                #echo "DEBUG: Fights done = $fights_done"
                fetch_page "/league/"
                
                click=$(grep -o -E "/league/fight/[0-9]{1,3}/\?r=[0-9]{1,8}" "$TMP/SRC" | sed -n "${j}p")  # Get the j-th fight button
                #echo "${URL}$click"
                if [[ "$click" == *"/league/refreshFights/"* ]]; then
                    echo_t "Fights limit reached, finishing..."
                    action="exit_loops"
                elif [ -n "$click" ]; then
                    ENEMY_NUMBER=$(echo "$click" | grep -o -E '[0-9]+' | head -n 1)

                    # Extrair as estatísticas do inimigo usando enemy_index
                    INDEX=$(( (enemy_index - 1) * 4 ))

                    E_STRENGTH=$(get_enemy_stat "$INDEX" 1)
                    E_HEALTH=$(get_enemy_stat "$INDEX" 2)
                    E_AGILITY=$(get_enemy_stat "$INDEX" 3)
                    E_PROTECTION=$(get_enemy_stat "$INDEX" 4)

                    echo_t "Enemy Number:" "" "$ENEMY_NUMBER"
                    #echo -e "Enemy Stats: Strength: ${E_STRENGTH:-0}"
                    action="fight_or_skip"
                else
                    echo "No fight buttons found for button $j ❌" >> "$TMP/ERROR_DEBUG"
                    action="exit_loops"
                fi
                ;;
            
            fight_or_skip)
                if [ "$PLAYER_STRENGTH" -gt "$E_STRENGTH" ] || [ -f "$TMP/POTION" ]; then
                    printf_t "Your Player strength"
                    printf " ($PLAYER_STRENGTH) " 
                    printf_t "is greater than enemys strength"
                    printf " ($E_STRENGTH).\n"
                    fetch_page "$click" # click
                    fights_done=$((fights_done + 1))  # Count the fight
                    echo_t "Fight the enemy number $ENEMY_NUMBER ✅ ." "" "\n"
                    enemy_index=1  # Reset enemy index after a fight
                    j=1  # Reset button index after a fight
                    fetch_available_fights  # Recheck available fights
                    action="check_fights" # back to check fights
                    # Delete the potion file if it exists
                    if [ -f "$TMP/POTION" ]; then
                        rm -rf "$TMP/POTION"
                    fi
                else
                    printf_t "Your Player strength" 
                    printf "($PLAYER_STRENGTH) " 
                    printf_t "< enemys strength " 
                    printf "($E_STRENGTH)"
                    printf_t ". Skipping enemy. " "" "\n" "after" "⏩"
                    enemy_index=$((enemy_index + 1))  # Move to the next enemy
                    #echo "$enemy_index"
                    j=$((j + 2))  # Move to the next button (skip every 2 links)
                    last_click=$(grep -o -E "/league/fight/[0-9]{1,3}/\?r=[0-9]{1,8}" "$TMP/SRC" | sed -n "${j}p")  # Get the j-th fight
                    #echo "$last_click" 
                    fetch_available_fights  # Recheck available fights
                    if [ -z "$last_click" ] && [ "$AVAILABLE_FIGHTS" -gt 0 ]; then  # If there are more than 4 enemies
                        echo_t " Reached the last enemy. Attacking the last one and using a potion..."
                        j=$((j - 2))  # Move to the previous button (skip every 2 links)
                        
                        # Attack the last enemy
                        click=$(grep -o -E "/league/fight/[0-9]{1,3}/\?r=[0-9]{1,8}" "$TMP/SRC" | sed -n "${j}p")
                        fetch_page "$click"
                        fights_done=$((fights_done + 1))  # Count the fight
                        fetch_available_fights  # Recheck available fights
                        sleep 1s

                        # Use potion /league/potion/?r=25771396
                        potion_click=$(grep -o -E "/league/potion/\?r=[0-9]+" "$TMP/SRC" | sed -n 1p)
                        fetch_page "$potion_click"
                        echo_t "Used a potion" "" "" "after" "🧪" 
                        echo "potion used" > "$TMP/POTION"
                        E_STRENGTH=50 # set a fake strength to the first enemy
                        # Reset the index to attack the first enemy
                        enemy_index=1
                        j=1
                    elif [ -z "$last_click" ] && [ "$AVAILABLE_FIGHTS" -eq 0 ] && [ "$FUNC_play_league" = "y" ] && [ "$ENEMY_NUMBER" -gt 50 ]; then
                        # /league/refreshFights/?r=56720053
                        click=$(grep -o -E "/league/refreshFights/\?r=[0-9]+" "$TMP/SRC" | sed -n 1p)
                        fetch_page "$click"
                        enemy_index=1
                        j=1
                        echo_t "Refreshed fights" "" "" "after" "🔄"
                        action="fight_or_skip"
                    else
                        action="check_fights"
                    fi
                fi
                ;;
            
            exit_loops)
                break
                ;;
        esac
        # Recompensa
        if [[ "$AVAILABLE_FIGHTS" =~ ^[0-9]+$ ]]; then
            if [ "$AVAILABLE_FIGHTS" -eq 0 ] && [ "$(grep -o -E "/league/takeReward/\?r=[0-9]+" "$TMP"/SRC | sed -n 1p)" ]; then
                clickReward=$(grep -o -E "/league/takeReward/\?r=[0-9]+" "$TMP"/SRC | sed -n 1p)
                fetch_page "$clickReward" 
                echo_t "Claimed reward" "" "" "after" "🎁"
            fi
        else
            echo "Error: $AVAILABLE_FIGHTS is not a valid number." >> "$TMP/ERROR_DEBUG"
            # Handle the error condition
            AVAILABLE_FIGHTS=0  # Set to 0 to prevent further errors
        fi
    done

    unset click ENEMY_NUMBER PLAYER_STRENGTH E_STRENGTH AVAILABLE_FIGHTS fights_done enemy_index j

    checkQuest 2 end
    checkQuest 1 end

    echo -e "${GREEN_BLACK}League Routine Completed ✅${COLOR_RESET}\n"
}
