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

league_play() {
    echo -e "${GOLD_BLACK}League ⚔️${COLOR_RESET}"

    # Obter a força do jogador
    PLAYER_STRENGTH=$(player_stats)  # Chame sua função existente player_stats

    # Loop para clicar nos botões de luta 5 vezes
    for i in {1..5}; do
        # Busca a página da liga
        fetch_page "/league/"

        # Calcular os índices para as estatísticas do inimigo
        INDEX=$(( (i - 1) * 4 ))  # Calcular o índice inicial para cada inimigo (base 0)

        # Extrair estatísticas do inimigo usando a função get_enemy_stat
        E_STRENGTH=$(get_enemy_stat "$INDEX" 1)  # 1ª estatística
        E_HEALTH=$(get_enemy_stat "$INDEX" 2)   # 2ª estatística
        E_AGILITY=$(get_enemy_stat "$INDEX" 3)  # 3ª estatística
        E_PROTECTION=$(get_enemy_stat "$INDEX" 4) # 4ª estatística

        # Extrair o botão de luta para o inimigo atual
        click=$(grep -o -E '/league/fight/[0-9]+/\?r=[0-9]+' "$TMP"/SRC | sed -n "${i}p")  # Obter o botão de luta i-ésimo
        ENEMY_NUMBER=$(echo "$click" | grep -o -E '[0-9]+' | head -n 1)

        # Verificar se o botão de luta foi encontrado
        if [ -n "$click" ]; then
            # Imprimir as estatísticas do inimigo junto com o número do inimigo
            echo -e "Enemy Number: $ENEMY_NUMBER"
            echo -e "Enemy Stats:\n"
            echo -e "Strength: ${E_STRENGTH:-0}"  # Default para 0 se vazio
            echo -e "Health: ${E_HEALTH:-0}"      # Default para 0 se vazio
            echo -e "Agility: ${E_AGILITY:-0}"    # Default para 0 se vazio
            echo -e "Protection: ${E_PROTECTION:-0}"  # Default para 0 se vazio
            echo " --- "

            # Garantir que todos os valores sejam inteiros antes da comparação
            PLAYER_STRENGTH=$(echo "$PLAYER_STRENGTH" | xargs)
            E_STRENGTH=$(echo "$E_STRENGTH" | xargs)

            # Verifica se a força do jogador é um inteiro válido
            if [[ "$PLAYER_STRENGTH" =~ ^[0-9]+$ ]] && [[ "$E_STRENGTH" =~ ^[0-9]+$ ]]; then
                # Comparar a força do jogador com a força do inimigo usando -gt
                if [ "$PLAYER_STRENGTH" -gt "$E_STRENGTH" ]; then
                    echo "Player's strength ($PLAYER_STRENGTH) is greater than enemy's strength ($E_STRENGTH)."
                    echo "Fight $i initiated with enemy number $ENEMY_NUMBER ✅"
                    fetch_page "$click"  # Chame a página de luta do inimigo
                else
                    echo "Player's strength ($PLAYER_STRENGTH) is not sufficient to attack enemy's strength ($E_STRENGTH). Skipping to next enemy."
                fi
            else
                echo "DEBUG: Invalid values - Player Strength: '$PLAYER_STRENGTH', Enemy Strength: '$E_STRENGTH'"
            fi
        else
            echo "No fight buttons found on attempt $i ❌"
            break
        fi
    done

    echo -e "${GREEN_BLACK}League Routine Completed ✅${COLOR_RESET}\n"
}

# https://furiadetitas.net/league/takeReward/?r=52027565