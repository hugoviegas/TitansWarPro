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

    PLAYER_STRENGTH=$(player_stats)  # Obtendo a força do jogador
    fetch_available_fights  # Buscando lutas disponíveis
    
    # Loop até que não haja mais lutas disponíveis
    for i in $(seq 1 "$AVAILABLE_FIGHTS"); do
        j=1

        fetch_page "/league/"
        # Extract the fight button for the current enemy
        click=$(grep -o -E "/league/fight/[0-9]{1,3}/\?r=[0-9]{1,8}" "$TMP/SRC" | sed -n "${j}p")  # Get the j-th fight button
        echo "${URL}$click"
        # Verificar se o link contém a palavra "/league/refreshFights/"
        if [[ "$click" == *"/league/refreshFights/"* ]]; then
            echo "Limite de ataques finalizado. Encerrando..."
            break  # Sair do loop se o limite de ataques for atingido
        fi

        # Verificar se o link de refresh está presente
        if [ -n "$click" ]; then
            ENEMY_NUMBER=$(echo "$click" | grep -o -E '[0-9]+' | head -n 1)
            
            # Calcular índices para as estatísticas do inimigo
            INDEX=$(( (i - 1) * 4 ))

            # Extrair as estatísticas do inimigo
            E_STRENGTH=$(get_enemy_stat "$INDEX" 1)
            E_HEALTH=$(get_enemy_stat "$INDEX" 2)
            E_AGILITY=$(get_enemy_stat "$INDEX" 3)
            E_PROTECTION=$(get_enemy_stat "$INDEX" 4)

            # Exibir informações do inimigo
            echo -e "Enemy Number: $ENEMY_NUMBER"
            echo -e "Enemy Stats:"
            echo -e "  Strength:   ${E_STRENGTH:-0}"
            sleep 5s

            fetch_available_fights
            k="$AVAILABLE_FIGHTS"
            echo "$k"
            # Comparar a força do jogador com a do inimigo
            if [[ "$PLAYER_STRENGTH" =~ ^[0-9]+$ ]] && [[ "$E_STRENGTH" =~ ^[0-9]+$ ]] && [[ "$k" -ge 1 ]]; then
            while [ "$PLAYER_STRENGTH" -lt "$E_STRENGTH" ] || [ "$i" -ge 4 ]; do
                if [ "$PLAYER_STRENGTH" -gt "$E_STRENGTH" ]; then

                    echo "Player's strength ($PLAYER_STRENGTH) is greater than enemy's strength ($E_STRENGTH)."
                    echo "Fight $j initiated with enemy number $ENEMY_NUMBER ✅"
                    fetch_page "$click"
                break
                else
                    echo "Player's strength ($PLAYER_STRENGTH) is not sufficient to attack enemy's strength ($E_STRENGTH). Skipping to next enemy."
                    # Incrementar o índice para o próximo inimigo
                    #local i=0

                        fetch_page "/league/"
                        j=$((j + 2))
                        ((i++))

                        click=$(grep -o -E "/league/fight/[0-9]{1,3}/\?r=[0-9]{1,8}" "$TMP"/SRC | sed -n "${j}p")  # Get the j-th fight button
                        ENEMY_NUMBER=$(echo "$click" | grep -o -E '[0-9]+' | head -n 1)
                        INDEX=$(( (i - 1) * 4 ))

                        # Extrair novamente as estatísticas do inimigo para o próximo índice
                        E_STRENGTH=$(get_enemy_stat "$INDEX" 1)
                        E_HEALTH=$(get_enemy_stat "$INDEX" 2)
                        E_AGILITY=$(get_enemy_stat "$INDEX" 3)
                        E_PROTECTION=$(get_enemy_stat "$INDEX" 4)

                        # Exibir informações do inimigo
                        echo -e "Enemy Number: $ENEMY_NUMBER"
                        echo -e "Enemy Stats:"
                        echo -e "  Strength:   ${E_STRENGTH:-0}"

                        echo "${URL}$click"
                        fetch_page "$click"
                        
                        sleep 1s
                        if [ $i -ge 4]; then
                            return #exit from all loops
                        fi
                fi
            done
            else
                echo "DEBUG: Invalid values - Player Strength: '$PLAYER_STRENGTH', Enemy Strength: '$E_STRENGTH'"
            fi
        else
            if grep -q -E '/league/refreshFights/\?r=[0-9]+' "$TMP"/SRC; then
                echo "Refresh fights link found. Stopping the fight loop."
                break
            fi
        echo "No fight buttons found on attempt $i ❌"
        break
        fi
    done

    click=$(grep -o -E "league/takeReward/\?r=[0-9]+" "$TMP"/SRC | sed -n 1p)
    fetch_page "$click"
    unset click ENEMY_NUMBER PLAYER_STRENGTH E_STRENGTH AVAILABLE_FIGHTS i j

    echo -e "${GREEN_BLACK}League Routine Completed ✅${COLOR_RESET}\n"
}

# https://furiadetitas.net/league/takeReward/?r=52027565