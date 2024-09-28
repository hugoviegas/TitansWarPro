# Função para buscar o número de lutas disponíveis
fetch_available_fights() {
    fetch_page "/league/" "LEAGUE_DEBUG_SRC"
    
    if [ -f "$TMP/LEAGUE_DEBUG_SRC" ]; then
        echo "Looking for available fights..."
        # Remover tudo antes e depois do número de lutas disponíveis
        AVAILABLE_FIGHTS=$(grep -o -E '<b>[0-5]</b>' "$TMP/LEAGUE_DEBUG_SRC" | head -n 1 | sed -n 's/.*<b>\([0-5]\)<\/b>.*/\1/p')
        echo "Fights left: $AVAILABLE_FIGHTS"
    else
        echo "O arquivo LEAGUE_DEBUG_SRC não foi encontrado."
        AVAILABLE_FIGHTS=0  # Define como 0 se o arquivo não for encontrado
    fi
}

# Função para extrair estatísticas do inimigo
get_enemy_stat() {
    local index=$1
    local stat_num=$2
    local stat

    while true; do
        stat=$(grep -o -E ': [0-9]+' "$TMP"/SRC | sed -n "$((index + stat_num))s/: //p" | tr -d '()' | tr -d ' ')
        
        if [[ -n "$stat" && "$stat" -gt 49 ]]; then
            echo "$stat"
            return
        fi
        ((stat_num++))
    done
}

# Função para extrair links únicos de inimigos
extract_unique_enemy_links() {
    local seen_enemies=()
    local unique_links=()

    local links=$(grep -o -E "${URL}/league/fight/[0-9]{1,3}/\?r=[0-9]{1,8}" "$TMP"/SRC)

    while IFS= read -r link; do
        local enemy_number=$(echo "$link" | grep -o -E '/league/fight/[0-9]+' | cut -d'/' -f4)

        if [[ ! " ${seen_enemies[*]} " =~ ${enemy_number} ]]; then
            unique_links+=("$link")
            seen_enemies+=("$enemy_number")
        fi
    done <<< "$links"

    echo "${unique_links[@]}"
}

# Função principal para executar as lutas na liga
league_play() {
    echo -e "${GOLD_BLACK}League ⚔️${COLOR_RESET}"

    PLAYER_STRENGTH=$(player_stats)  # Força do jogador

    # Buscar o número de lutas disponíveis
    fetch_available_fights

    # Loop enquanto houver lutas disponíveis
    while [ "$AVAILABLE_FIGHTS" -gt 0 ]; do
        fetch_page "/league/"  # Atualizar a página da liga

        ENEMY_LINKS=$(extract_unique_enemy_links)  # Extrair links de inimigos

        for click in "${ENEMY_LINKS[@]}"; do
            ENEMY_NUMBER=$(echo "$click" | grep -o -E '[0-9]{1,3}' | head -n 1)
            
            # Verifica se o número do inimigo é válido
            if [[ "$ENEMY_NUMBER" =~ ^[1-9][0-9]{0,2}$ ]] && [ "$ENEMY_NUMBER" -le 999 ]; then
                echo "Valid enemy number: $ENEMY_NUMBER"
            else
                echo "Invalid enemy number: $ENEMY_NUMBER. Skipping..."
                continue
            fi

            # Buscar a página do inimigo
            fetch_page "$click"

            # Extrair estatísticas do inimigo
            E_STRENGTH=$(get_enemy_stat "$ENEMY_NUMBER" 1)
            E_HEALTH=$(get_enemy_stat "$ENEMY_NUMBER" 2)
            E_AGILITY=$(get_enemy_stat "$ENEMY_NUMBER" 3)
            E_PROTECTION=$(get_enemy_stat "$ENEMY_NUMBER" 4)

            echo -e "Enemy Stats:\nStrength: ${E_STRENGTH:-0}\nHealth: ${E_HEALTH:-0}\nAgility: ${E_AGILITY:-0}\nProtection: ${E_PROTECTION:-0}"

            E_STRENGTH=${E_STRENGTH:-0}

            # Comparar força do jogador com a força do inimigo
            if [ "$PLAYER_STRENGTH" -gt "$E_STRENGTH" ]; then
                echo "Player's strength ($PLAYER_STRENGTH) is greater than enemy's strength ($E_STRENGTH)."
                echo "Fight initiated with enemy number $ENEMY_NUMBER ✅"
                # Inserir lógica para iniciar a luta aqui

                # Reduz o número de lutas disponíveis
                ((AVAILABLE_FIGHTS--))

                # Se não houver mais lutas disponíveis, sair do loop
                if [ "$AVAILABLE_FIGHTS" -le 0 ]; then
                    break
                fi
            else
                echo "Player's strength ($PLAYER_STRENGTH) is not sufficient to attack enemy's strength ($E_STRENGTH). Skipping to next enemy."
            fi
        done

        # Atualizar o número de lutas disponíveis
        fetch_available_fights

        # Se não houver lutas disponíveis, sair do loop
        if [ "$AVAILABLE_FIGHTS" -le 0 ]; then
            break
        fi
    done

    echo -e "${GREEN_BLACK}League Routine Completed ✅${COLOR_RESET}\n"
}

# https://furiadetitas.net/league/takeReward/?r=52027565# Calculate indices for the current enemy's stats