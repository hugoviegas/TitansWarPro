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
    local seen_enemies=() # Array para armazenar inimigos já processados
    local unique_links=() # Array para armazenar links únicos

    # Extraímos apenas os links de inimigos válidos
    local links=$(grep -o -E '/league/fight/[0-9]{1,3}/\?r=[0-9]{1,8}' "$TMP"/SRC)

    echo "DEBUG: Links encontrados na página: $links"

    # Loop para processar cada link
    while IFS= read -r link; do
        # Extraímos o número do inimigo
        local enemy_number=$(echo "$link" | grep -o -E '[0-9]{1,3}' | head -n 1)

        echo "DEBUG: Número do inimigo extraído: $enemy_number"

        # Verificamos se o inimigo já foi processado
        if [[ ! " ${seen_enemies[*]} " =~ " ${enemy_number} " ]]; then
            unique_links+=("$link")
            seen_enemies+=("$enemy_number")
            echo "DEBUG: Link adicionado: $link"
        else
            echo "DEBUG: Número do inimigo $enemy_number já visto, ignorando link duplicado."
        fi
    done <<< "$links"

    # Retorna os links únicos
    echo "${unique_links[@]}"
}

# Função principal para executar as lutas na liga
league_play() {
    echo -e "${GOLD_BLACK}League ⚔️${COLOR_RESET}"

    # Busca o número de lutas disponíveis
    fetch_available_fights

    # Verifica se há lutas disponíveis
    if [ "$AVAILABLE_FIGHTS" -le 0 ]; then
        echo "Nenhuma luta disponível no momento."
        return
    fi

    # Obtém a força do jogador
    PLAYER_STRENGTH=$(player_stats)  # Substitua pela função correta de obtenção da força do jogador

    echo "Força do jogador: $PLAYER_STRENGTH"

    # Busca a página da liga
    fetch_page "/league/"

    # Debug: Exibe o conteúdo da página de liga
    echo "DEBUG: Conteúdo da página de liga:"
    cat "$TMP"/SRC

    # Extrai os links únicos de inimigos
    ENEMY_LINKS=$(extract_unique_enemy_links)

    # Verifica se os links foram corretamente extraídos
    if [ -z "$ENEMY_LINKS" ]; then
        echo "DEBUG: Nenhum link de inimigo encontrado. Encerrando a rotina da liga."
        return
    fi

    # Debug: Exibe os links de inimigos
    echo "DEBUG: Links de inimigos encontrados: $ENEMY_LINKS"

    # Itera sobre cada link de inimigo
    for click in $ENEMY_LINKS; do
        echo "DEBUG: Processando link: $click"

        # Extrai o número do inimigo do link
        ENEMY_NUMBER=$(echo "$click" | grep -o -E '[0-9]{1,3}' | head -n 1)
        echo "DEBUG: Número do inimigo extraído: $ENEMY_NUMBER"

        # Valida se o número do inimigo é um número válido
        if [[ "$ENEMY_NUMBER" =~ ^[0-9]+$ ]]; then
            echo "Valid enemy number: $ENEMY_NUMBER"
        else
            echo "Invalid enemy number: $ENEMY_NUMBER. Skipping..."
            continue
        fi

        # Carrega a página do inimigo
        fetch_page "$click"

        # Debug: Verifica o conteúdo da página de luta do inimigo
        echo "DEBUG: Conteúdo da página de luta do inimigo:"
        cat "$TMP"/SRC

        # Extrai as estatísticas do inimigo
        E_STRENGTH=$(get_enemy_stat "$ENEMY_NUMBER" 1)  # Força
        E_HEALTH=$(get_enemy_stat "$ENEMY_NUMBER" 2)    # Saúde
        E_AGILITY=$(get_enemy_stat "$ENEMY_NUMBER" 3)   # Agilidade
        E_PROTECTION=$(get_enemy_stat "$ENEMY_NUMBER" 4) # Proteção

        # Debug: Exibe as estatísticas do inimigo
        echo -e "Enemy Stats:\nStrength: ${E_STRENGTH:-0}\nHealth: ${E_HEALTH:-0}\nAgility: ${E_AGILITY:-0}\nProtection: ${E_PROTECTION:-0}"

        # Verifica se as estatísticas foram extraídas corretamente
        if [[ -z "$E_STRENGTH" ]]; then
            echo "Erro ao extrair estatísticas do inimigo. Pulando para o próximo inimigo."
            continue
        fi

        # Compara a força do jogador com a força do inimigo
        if [ "$PLAYER_STRENGTH" -gt "$E_STRENGTH" ]; then
            echo "Player's strength ($PLAYER_STRENGTH) is greater than enemy's strength ($E_STRENGTH)."
            echo "Fight initiated with enemy number $ENEMY_NUMBER ✅"
            # Lógica para iniciar a luta aqui
        else
            echo "Player's strength ($PLAYER_STRENGTH) is not sufficient to attack enemy's strength ($E_STRENGTH). Skipping to next enemy."
        fi
    done

    echo -e "${GREEN_BLACK}League Routine Completed ✅${COLOR_RESET}\n"
}



# https://furiadetitas.net/league/takeReward/?r=52027565# Calculate indices for the current enemy's stats