fetch_available_fights() {
    fetch_page "/league/" "LEAGUE_DEBUG_SRC"
    
    if [ -f "$TMP/LEAGUE_DEBUG_SRC" ]; then
        echo "Looking for available fights..."
        # Remover tudo antes e depois do número de lutas disponíveis
        AVAILABLE_FIGHTS=$(grep -o -E '<b>[0-5]</b>' "$TMP/LEAGUE_DEBUG_SRC" | head -n 1 | sed -n 's/.*<b>\([0-5]\)<\/b>.*/\1/p')
        echo "Fights left: $AVAILABLE_FIGHTS"
        
        if [ -z "$AVAILABLE_FIGHTS" ]; then
            echo "Erro: Nenhuma luta disponível encontrada."
            return 1  # Retorna um código de erro
        fi
    else
        echo "O arquivo LEAGUE_DEBUG_SRC não foi encontrado."
        AVAILABLE_FIGHTS=0  # Define como 0 se o arquivo não for encontrado
        return 1  # Retorna um código de erro
    fi
    
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

    echo "Stat not found after $max_attempts attempts."  # Mensagem de erro se não encontrar
    return 1  # Retorna um código de erro
}

# Função principal para jogar na liga
league_play() {
    echo -e "${GOLD_BLACK}League ⚔️${COLOR_RESET}"
    checkQuest 2
    checkQuest 1

    PLAYER_STRENGTH=$(player_stats)  # Obtendo a força do jogador
    fetch_available_fights  # Buscando lutas disponíveis

    # Definir uma variável para controlar o estado do loop
    action="check_fights"
    fights_done=0
    j=1  # Index for fight buttons (skipping every 2 links)
    enemy_index=1  # Separate index for enemy stats

    while [ "$fights_done" -lt "$AVAILABLE_FIGHTS" ] || [ "$AVAILABLE_FIGHTS" -gt 0 ]; do
        case "$action" in
            check_fights)
                echo "DEBUG: Player Stats = $PLAYER_STRENGTH"
                echo "DEBUG: Button j = $j"
                echo "DEBUG: Enemy Index = $enemy_index"
                echo "DEBUG: Fights done = $fights_done"
                fetch_page "/league/"
                
                click=$(grep -o -E "/league/fight/[0-9]{1,3}/\?r=[0-9]{1,8}" "$TMP/SRC" | sed -n "${j}p")  # Get the j-th fight button
                #echo "${URL}$click"
                if [[ "$click" == *"/league/refreshFights/"* ]]; then
                    echo "Limite de ataques finalizado. Encerrando..."
                    action="exit_loops"
                elif [ -n "$click" ]; then
                    ENEMY_NUMBER=$(echo "$click" | grep -o -E '[0-9]+' | head -n 1)

                    # Extrair as estatísticas do inimigo usando enemy_index
                    INDEX=$(( (enemy_index - 1) * 4 ))

                    E_STRENGTH=$(get_enemy_stat "$INDEX" 1)
                    E_HEALTH=$(get_enemy_stat "$INDEX" 2)
                    E_AGILITY=$(get_enemy_stat "$INDEX" 3)
                    E_PROTECTION=$(get_enemy_stat "$INDEX" 4)

                    echo -e "Enemy Number: $ENEMY_NUMBER"
                    echo -e "Enemy Stats: Strength: ${E_STRENGTH:-0}"
                    action="fight_or_skip"
                else
                    echo "No fight buttons found for button $j ❌"
                    action="exit_loops"
                fi
                ;;
            
            fight_or_skip)
                if [ "$PLAYER_STRENGTH" -gt "$E_STRENGTH" ]; then
                    echo "Player's strength ($PLAYER_STRENGTH) is greater than enemy's strength ($E_STRENGTH)."
                    echo -e "Fight $((fights_done + 1)) initiated with enemy number $ENEMY_NUMBER ✅ .\n"
                    fetch_page "$click"
                    action="check_fights"
                    fights_done=$((fights_done + 1))  # Count the fight
                    enemy_index=1  # Reset enemy index after a fight
                    j=1  # Reset button index after a fight
                    fetch_available_fights  # Recheck available fights
                else
                    echo "Player's strength ($PLAYER_STRENGTH) is not sufficient to attack enemy's strength ($E_STRENGTH). Skipping to next enemy."
                    enemy_index=$((enemy_index + 1))  # Move to the next enemy
                    j=$((j + 2))  # Move to the next button (skip every 2 links)

                    if [ "$enemy_index" -gt 4 ]; then  # Limite de inimigos (assuming 4 enemies)
                        enemy_index=1  # Reset enemy index after checking all enemies
                        action="exit_loops"  # Exit if no viable enemies
                    else
                        action="check_fights"
                    fi
                fi
                ;;
            
            exit_loops)
                break
                ;;
        esac
    done

    # Recompensa
    click=$(grep -o -E "/league/takeReward/\?r=[0-9]+" "$TMP"/SRC | sed -n 1p)
    fetch_page "$click"
    
    unset click ENEMY_NUMBER PLAYER_STRENGTH E_STRENGTH AVAILABLE_FIGHTS fights_done enemy_index j

    checkQuest 2
    checkQuest 1

    echo -e "${GREEN_BLACK}League Routine Completed ✅${COLOR_RESET}\n"
}
