# shellcheck disable=SC2155
# shellcheck disable=SC2154
cave_process() {
    local mode="$1"
    local BREAK

    echo_t "Cave" "$GOLD_BLACK" "$COLOR_RESET" "after" "🪨"

    # Determinar o tempo de execução
    if [ "$mode" == "start" ]; then
        clan_id
        BREAK=$(($(date +%s) + 1800))
    else
        BREAK=0
    fi

    # Inicializar contadores
    local count=0

    # Verificar se existem quests disponíveis
    if [ "$mode" == "routine" ] && checkQuest 5 apply; then
        count=0
        echo_t "Quests available speeding up mine to complete!" "" "" "after" " "
    else
        count=8
    fi

    # Buscar dados iniciais da caverna
    fetch_page "/cave/"

    while true; do
        # Obter a primeira ação da caverna
        local CAVE=$(grep -o -E '/cave/(gather|down|runaway|speedUp)/[?]r[=][0-9]+' "$TMP"/SRC | sed -n '1p')
        local RESULT=$(echo "$CAVE" | cut -d'/' -f3)

        # Verificar limites de speedUp
        if [[ "$RESULT" == "speedUp" && (( "$mode" == "start" && count -ge 20 )) || (( "$mode" == "routine" && count -ge 8 )) ]]; then
            echo_t "Cave limit reached" "" "" "after" "⛏️"
            break
        fi

        # Processar a ação atual da caverna
        case $RESULT in
            gather|down|runaway|speedUp)
                fetch_page "$CAVE"

                # Feedback baseado na ação atual
                case $RESULT in
                    down*)
                        echo_t "New search" "" "" "after" "🔍"
                        ((count++))  # Incrementar contador
                        ;;
                    gather*)
                        echo_t "Start mining" "" "" "after" "⛏️"
                        ;;
                    runaway*)
                        echo_t "Run away" "" "" "after" "💨"
                        ;;
                    speedUp*)
                        echo_t "Speed up mining" "" "" "after" "⚡"
                        ;;
                esac
                ;;
        esac

        # Atualizar os dados da caverna
        fetch_page "/cave/"

        # Para o modo de início, verificar o RUN
        if [ "$mode" == "start" ] && echo "$RUN" | grep -q -E '[-]cv'; then
            echo -e "\nYou can run ./twm/play.sh -cv"
        fi

        unset ACCESS1 ACCESS2 ACTION DOWN MEGA
        
        # Encerrar se for o modo start e o tempo esgotar
        if [ "$mode" == "start" ] && [ "$(date +%s)" -ge "$BREAK" ]; then
            break
        fi
    done

    echo_t "Cave" "${GREEN_BLACK}" "${COLOR_RESET}" "✅\n"
    
    # Se for o modo start, mudar o modo de execução e reiniciar o script
    if [ "$mode" == "start" ]; then
        echo "-boot" > "$HOME/twm/runmode_file"
        restart_script
    fi
}
