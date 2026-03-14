check_missions() {
    
    echo_t "Checking Missions" "${GOLD_BLACK}" "${COLOR_RESET}" "after" "📜"

    # Abrir os dois primeiros baus
    fetch_page "/quest/"
    for i in {1..2}; do
        local click
        click=$(grep -o -E "/quest/openChest/$i/[?]r=[0-9]+" "$TMP/SRC" | head -n1)
        if [ -n "$click" ]; then
            fetch_page "$click"  # Acessa a URL de abertura do bau
            echo -e "${GREEN_BLACK}Chest ${i} opened ✅${COLOR_RESET}"
        fi
    done

	# Verifica se a coleta de missoes esta habilitada
    if [ "$FUNC_collect_mission_rewards" = "n" ]; then
        return
    fi

    # Coletar missoes completadas
    for i in {0..16}; do
        local click
        click=$(grep -o -E "/quest/end/${i}[?]r=[0-9]+" "$TMP/SRC" | sed -n '1p')
        if [ -n "$click" ]; then
            fetch_page "$click"  # Acessa a URL de finalizacao da missao
            echo_t " Mission ${i} Completed" "${GREEN_BLACK}" "${COLOR_RESET}" "after" "✅\n"
        fi
    done

    # Coletar colecoes da pagina do coletor
    fetch_page "/collector/"
    if click=$(grep -o -E "/collector/reward/element/[?]r=[0-9]+" "$TMP/SRC"); then
        fetch_page "$click"  # URL de recompensa da colecao
        echo_t "Collection collected" "${GREEN_BLACK}" "${COLOR_RESET}" "after" "✅\n"
    fi

    echo_t "Missions" "${GREEN_BLACK}" "${COLOR_RESET}" "after" "✅\n"
}

check_rewards() {
    if [ "$FUNC_check_rewards" = "n" ]; then
        return
    fi

    # Coletar recompensas de reliquias
    fetch_page "/relic/reward/"
    for i in {0..11}; do
        local click
        click=$(grep -o -E "/relic/reward/${i}/[?]r=[0-9]+" "$TMP/SRC")
        if [ -n "$click" ]; then
            fetch_page "$click"  # URL da recompensa da reliquia
            echo_t "Relic ${i} collected" "${GREEN_BLACK}" "${COLOR_RESET}" "after" "✅\n"
        fi
    done
}

apply_event() {
    # Aplicar em batalha
    local event_path="${1}"
    fetch_page "/${event_path}/"
    if grep -o -E "/${event_path}/enter(Game|Fight)/[?]r=[0-9]+" "$TMP"/SRC; then
        APPLY=$(grep -o -E "/${event_path}/enter(Game|Fight)/[?]r=[0-9]+" "$TMP"/SRC)
        fetch_page "$APPLY"
        echo_t "Applied for battle" "${BLACK_YELLOW}" "${COLOR_RESET}" "after" "✅\n"
    fi
}

use_elixir() {
    if [ "$FUNC_use_elixir" = "n" ]; then
        return
    fi

    # Acesso inicial para obter URLs
    fetch_page "/inv/chest/"

    # Loop para processar clicks
    for ((i=1; i<=4; i++)); do
        click=$(grep -o -E "/inv/chest/use/[0-9]+/1/[?]r=[0-9]+" "$TMP/SRC" | sed -n "${i}p")
        if [[ -z "$click" ]]; then
            echo_t "No more URLs to process."
            break
        fi
        fetch_page "$click"  # Usar todos os elixires
    done

    echo_t "Applied all elixir" "${BLACK_YELLOW}" "${COLOR_RESET}" "after" "💊"
}