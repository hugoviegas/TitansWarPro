# shellcheck disable=SC2148,SC2034

# ============================================================================
# MISSIONS SYSTEM - TitansWarPro
# ============================================================================
# Quest IDs confirmed from debug 2026-03-15 (furiadetitas.net):
#
#  ID  1  → Só ganha!             — só coletar (10 vitórias seguidas arena)
#  ID  2  → Busca de recursos      — cave_routine (2 pesquisas)
#  ID  3  → Missões do Sábio      — só coletar (completa automaticamente)
#  ID  4  → Eu preciso de ouro!   — IGNORAR (compra 100 ouro)
#  ID  5  → Campanha              — campaign_func (luta 3x)
#  ID  6  → Lutador               — league_play (10 lutas)
#  ID  7  → Lutador lendário      — league_play (5 vitórias)
#  ID  8  → Ouro segredo          — IGNORAR (compra 500 ouro)
#  ID  9  → Eu quero sangue!      — só coletar (vale dos imortais)
#  ID 10  → Altares antigos        — altars_fight (entrar e lutar)
#  ID 11  → Gladiador             — coliseum_fight x3
#  ID 12  → Ajude o seu Clã!      — IGNORAR (compra 500 ouro para clã)
#  ID 13  → Alquimia              — usar 1 elixir do inventário (/inv/chest/)
#  ID 16  → Torneio               — só coletar (career já roda antes)
# ============================================================================

# ── Verificação de fim de semana (pausa coleta de recompensas apenas) ─────
_missions_is_weekend() {
    [ "${FUNC_pause_weekends:-y}" = "y" ] || return 1
    local d
    d=$(date +%u)  # 1=Seg ... 7=Dom
    [ "$d" -eq 6 ] || [ "$d" -eq 7 ]
}

# ── Helper: coleta de recompensas (respeitando pausa de weekend) ──────────
_mission_collect_rewards() {
    if _missions_is_weekend; then
        echo_t "Mission rewards skipped (weekend pause)" "${BLACK_RED}" "${COLOR_RESET}" "after" "⏸️"
        return
    fi

    fetch_page "/quest/"

    local collected=0
    for i in {0..16}; do
        local click
        click=$(grep -o -E "/quest/end/${i}[?]r=[0-9]+" "$TMP/SRC" | sed -n '1p')
        if [ -n "$click" ]; then
            fetch_page "$click"
            echo_t "  Mission ${i} reward collected" "${GREEN_BLACK}" "${COLOR_RESET}" "after" "✅"
            collected=$((collected + 1))
        fi
    done

    [ "$collected" -eq 0 ] && echo_t "No mission rewards ready" "${GRAY_BLACK}" "${COLOR_RESET}" "after" "📭"
}

# ── Helper: análise do estado das missões (usado no debug) ────────────────
_mission_analyze_state() {
    local src_file="${1:-$TMP/SRC}"

    printf "\n=== MISSION STATE ANALYSIS ===\n"

    # Missões com IDs conhecidos
    # Formato: "ID:Nome:Ignorar?"
    local known_missions="1:So_ganha:no 2:Busca_de_recursos:no 3:Missoes_do_Sabio:no \
4:Eu_preciso_de_ouro:IGNORE 5:Campanha:no 6:Lutador:no 7:Lutador_lendario:no \
8:Ouro_segredo:IGNORE 9:Eu_quero_sangue:no 10:Altares_antigos:no 11:Gladiador:no \
12:Ajude_o_Cla:IGNORE 13:Alquimia:no 16:Torneio:no"

    for entry in $known_missions; do
        local id name ignore
        id="${entry%%:*}"
        name="$(echo "$entry" | cut -d: -f2)"
        ignore="$(echo "$entry" | cut -d: -f3)"

        if grep -q "/quest/end/${id}[?]r=" "$src_file" 2>/dev/null; then
            printf "  [ID %2d] %-22s → ⭐ RESGATAR\n" "$id" "$name"
        elif grep -q "quest_id=${id}&" "$src_file" 2>/dev/null; then
            if [ "$ignore" = "IGNORE" ]; then
                printf "  [ID %2d] %-22s → 🚫 DISPONÍVEL (ignorar)\n" "$id" "$name"
            else
                printf "  [ID %2d] %-22s → ▶️  DISPONÍVEL\n" "$id" "$name"
            fi
        else
            printf "  [ID %2d] %-22s → ⏳ TIMER/LOCK\n" "$id" "$name"
        fi
    done

    printf "===========================\n"
}

# ── Helper: dump de página para o log de debug ───────────────────────────
_mission_dump_page() {
    local page="$1"
    local log_file="$2"

    {
        echo ""
        echo "========================================"
        echo "PAGE: ${URL}${page}"
        echo "========================================"
        echo ""
    } >> "$log_file"

    fetch_page "$page"

    # Verificar se o arquivo foi baixado
    if [ ! -s "$TMP/SRC" ]; then
        echo "ERROR: Failed to fetch $page" >> "$log_file"
        return 1
    fi

    {
        echo "--- LINKS (href) ---"
        timeout 5 grep -o -E "href='[^']+'" "$TMP/SRC" 2>/dev/null | sort -u || echo "TIMEOUT: grep links"
        echo ""
        echo "--- FILE SIZE ---"
        wc -c < "$TMP/SRC"
        echo "--- TEXT RENDER (first 100 lines) ---"
        timeout 5 w3m -dump -T text/html "$TMP/SRC" 2>/dev/null | head -n 100 || echo "TIMEOUT: w3m render"
        echo ""
    } >> "$log_file"
}

# ============================================================================
# MISSION DEBUG — lê páginas de missões e analisa estado de cada uma
# ============================================================================
mission_debug() {
    local debug_dir="${ACCOUNT_LOGS:-$TMP}"
    local debug_ts
    printf -v debug_ts '%(%Y%m%d_%H%M%S)T' -1
    local debug_file="${debug_dir}/mission_debug_${debug_ts}.log"

    echo_t "Mission Debug" "${GOLD_BLACK}" "${COLOR_RESET}" "after" "📜"
    echo_t "This will take ~2 minutes (4 pages × 17s each)..." "${GRAY_BLACK}" "${COLOR_RESET}" "before" "⏱️"

    : > "$debug_file"
    {
        echo "MISSION DEBUG — $(date)"
        echo "Account: ${ACC:-unknown} | URL: ${URL}"
        echo ""
    } >> "$debug_file"

    # Páginas a inspecionar
    local pages=("/quest/" "/arena/" "/league/" "/lab/alchemy/")
    local page_count=0
    for page in "${pages[@]}"; do
        page_count=$((page_count + 1))
        echo_t "  [${page_count}/4] Fetching ${page}" "${GRAY_BLACK}" "${COLOR_RESET}" "before" "🔍"
        _mission_dump_page "$page" "$debug_file"
        [ $? -eq 0 ] && echo_t "    OK" "${GREEN_BLACK}" "${COLOR_RESET}" "after" "✅" || echo_t "    FAILED" "${RED_BLACK}" "${COLOR_RESET}" "after" "❌"
    done

    # Análise de estado a partir da página /quest/ (já está em $TMP/SRC após último fetch)
    echo_t "  Analyzing mission states..." "${GRAY_BLACK}" "${COLOR_RESET}" "before" "📊"
    fetch_page "/quest/"

    # Exibe e salva análise no log
    _mission_analyze_state "$TMP/SRC" | tee -a "$debug_file"

    # Status de fim de semana
    if _missions_is_weekend; then
        echo_t "  Weekend: reward collection PAUSED" "${BLACK_RED}" "${COLOR_RESET}" "after" "⏸️"
        printf "  [WEEKEND] Coleta pausada — fim de semana\n" >> "$debug_file"
    else
        echo_t "  Weekend: reward collection ACTIVE" "${GREEN_BLACK}" "${COLOR_RESET}" "after" "✅"
        printf "  [WEEKEND] Coleta ATIVA\n" >> "$debug_file"
    fi

    echo_t "Debug saved: $debug_file" "${GREEN_BLACK}" "${COLOR_RESET}" "after" "✅"
    echo ""
    echo_t "You can view the full debug log with:" "${GRAY_BLACK}" "${COLOR_RESET}" "before" "📖"
    echo "  tail -f $debug_file"
    echo ""
    echo "$debug_file"
}

# ============================================================================
# SUB-ROTINAS DE MISSÃO
# ============================================================================

# ── Altares antigos (ID 10) ───────────────────────────────────────────────
_mission_altars() {
    echo_t "  Altares antigos" "${GOLD_BLACK}" "${COLOR_RESET}" "before" "🏛️"

    # Fechar resultado anterior, se existir, e entrar na luta
    fetch_page "/altars/?close=reward"

    local enter
    enter=$(grep -o -E '/altars/enterFight/[?]r=[0-9]+' "$TMP/SRC" | head -n1)
    [ -z "$enter" ] && enter="/altars/enterFight"

    fetch_page "$enter"

    # Aguardar link de combate (mesma lógica do altars_start)
    local BREAK=$(( $(date +%s) + 30 ))
    until grep -q -o 'altars/dodge/' "$TMP/SRC" || [ "$(date +%s)" -gt "$BREAK" ]; do
        fetch_page "/altars"
        sleep 2s
    done

    # Iniciar batalha
    altars_fight
}

# ── Campanha ──────────────────────────────────────────────────────────────
_mission_campaign() {
    echo_t "  Campaign" "${GOLD_BLACK}" "${COLOR_RESET}" "before" "⛺"

    fetch_page "/campaign/"
    if grep -q -E '/campaign/(go|fight|attack)/[?]r[=][0-9]+' "$TMP/SRC"; then
        campaign_func
    else
        echo_t "  Campaign not available yet" "${GRAY_BLACK}" "${COLOR_RESET}" "after" "⏳"
    fi
}

# ── League — Lutador (ID 6) + Lutador lendário (ID 7) ────────────────────
_mission_league() {
    echo_t "  League Missions" "${GOLD_BLACK}" "${COLOR_RESET}" "before" "🏆"

    # Pré-restaurar lutas se necessário (máximo 2 vezes)
    local refills=0
    local max_refills=2

    fetch_page "/league/"
    local avail
    avail=$(grep -o -E 'Lutas disponiveis: <b>[0-9]+</b>' "$TMP/SRC" | grep -o '[0-9]*</b>' | tr -cd '0-9')
    avail=${avail:-0}

    while [ "${avail:-0}" -eq 0 ] && [ "$refills" -lt "$max_refills" ]; do
        local refresh
        refresh=$(grep -o -E '/league/refreshFights/[?]r=[0-9]+' "$TMP/SRC" | head -n1)
        if [ -n "$refresh" ]; then
            fetch_page "$refresh"
            refills=$((refills + 1))
            echo_t "   League fights restored (${refills}/${max_refills})" "${GRAY_BLACK}" "${COLOR_RESET}" "after" "🔄"
            fetch_page "/league/"
            avail=$(grep -o -E 'Lutas disponiveis: <b>[0-9]+</b>' "$TMP/SRC" | grep -o '[0-9]*</b>' | tr -cd '0-9')
            avail=${avail:-0}
        else
            break
        fi
    done

    # league_play já combina missões de clã (checkQuest 1/2 apply+end internamente)
    league_play
}

# ── Gladiador — 3 batalhas no coliseu (ID 11) ────────────────────────────
_mission_coliseum() {
    echo_t "  Gladiador (Coliseum x3)" "${GOLD_BLACK}" "${COLOR_RESET}" "before" "⚔️"

    local fights=0
    local target=3

    while [ "$fights" -lt "$target" ]; do
        fetch_page "/quest/"
        # Parar se a missão não está mais disponível (concluída ou outro estado)
        if ! grep -q "quest_id=11" "$TMP/SRC"; then
            break
        fi

        coliseum_fight
        fights=$((fights + 1))
        echo_t "   Coliseum fight ${fights}/${target}" "${GREEN_BLACK}" "${COLOR_RESET}" "after" "✅"
        sleep 2s
    done
}

# ── Busca de recursos — 2 pesquisas na caverna (ID 2) ──────────────────────
_mission_cave() {
    echo_t "  Cave Resources (2 searches)" "${GOLD_BLACK}" "${COLOR_RESET}" "before" "🪨"

    # Combinar com missão de clã de caverna se disponível
    if checkQuest 5 apply; then
        echo_t "   Clan cave mission combined" "${GRAY_BLACK}" "${COLOR_RESET}" "after" "🔱"
    fi

    cave_routine

    checkQuest 5 end
}

# ── Alquimia — usar 1 elixir do inventário (ID 13) ───────────────────────
_mission_alchemy() {
    echo_t "  Alquimia (usar elixir)" "${GOLD_BLACK}" "${COLOR_RESET}" "before" "⚗️"

    # Pegar link da missão a partir da página /quest/ já em $TMP/SRC
    local quest_link
    quest_link=$(grep -o -E "/inv/chest/\?quest_t=quest&quest_id=13&qz=[a-f0-9]+" "$TMP/SRC" | head -n1)

    if [ -z "$quest_link" ]; then
        echo_t "  Alchemy mission not available" "${GRAY_BLACK}" "${COLOR_RESET}" "after" "⏳"
        return
    fi

    # Abrir a página de inventário da missão
    fetch_page "$quest_link"

    if [ ! -s "$TMP/SRC" ]; then
        echo_t "  Error fetching alchemy mission page" "${RED_BLACK}" "${COLOR_RESET}" "after" "❌"
        return 1
    fi

    # Encontrar o use link do elixir com maior quantidade
    # Para cada use link, busca a última ocorrência de "N pc" antes dele no HTML
    # (funciona mesmo que o HTML esteja todo em uma única linha)
    local use_links html_content best_link best_qty
    best_qty=0
    html_content=$(cat "$TMP/SRC")
    use_links=$(grep -o -E '/inv/chest/use/[0-9]+/1/\?r=[0-9]+' "$TMP/SRC")

    while IFS= read -r link; do
        [ -z "$link" ] && continue
        local before_link qty
        # Pega tudo que aparece antes deste link no HTML
        before_link="${html_content%%"${link}"*}"
        # Extrai a última quantidade "N pc" antes do link
        qty=$(echo "$before_link" | grep -o -E '[0-9]+[[:space:]]*pc' | tail -1 | grep -o -E '^[0-9]+')
        qty=${qty:-0}
        if [ "$qty" -gt "$best_qty" ]; then
            best_qty="$qty"
            best_link="$link"
        fi
    done <<< "$use_links"

    # Fallback: usa o primeiro elixir encontrado se não detectou quantidade
    [ -z "$best_link" ] && best_link=$(echo "$use_links" | head -n1)

    if [ -z "$best_link" ]; then
        echo_t "  No elixirs available to use" "${GRAY_BLACK}" "${COLOR_RESET}" "after" "⚠️"
        return
    fi

    echo_t "   Using elixir (qty: ${best_qty})" "${GRAY_BLACK}" "${COLOR_RESET}" "before" "⚗️"
    fetch_page "$best_link"
    sleep 1s

    echo_t "  Elixir used!" "${GREEN_BLACK}" "${COLOR_RESET}" "after" "✅"
}

# ============================================================================
# DO MISSIONS — executa missões disponíveis (automático, sempre)
# Respects: FUNC_pause_weekends (y/n) para coleta de recompensas apenas
# Ignored IDs: 4 (Eu preciso de ouro!), 8 (Ouro segredo), 12 (Ajude o Clã!)
# ============================================================================
# Função auxiliar para verificar timeout (deve ser definida fora de do_missions)
_check_timeout() {
    local elapsed=$(( $(date +%s) - mission_start ))
    if [ "$elapsed" -gt "$mission_timeout" ]; then
        echo_t "Mission timeout exceeded, stopping" "${RED_BLACK}" "${COLOR_RESET}" "after" "⏱️"
        return 1
    fi
    return 0
}

do_missions() {

    echo_t "Doing Missions" "${GOLD_BLACK}" "${COLOR_RESET}" "after" "📜"

    # Timeout global para do_missions (30 minutos máximo)
    mission_timeout=1800
    mission_start=$(date +%s)

    fetch_page "/quest/" || { echo_t "ERROR: Cannot access /quest/" "${RED_BLACK}" "${COLOR_RESET}" "after" "❌"; return 1; }

    # ── Lutador (ID 6) + Lutador lendário (ID 7) ──────────────
    _check_timeout || return 0
    if grep -q "quest_id=6" "$TMP/SRC" || grep -q "quest_id=7" "$TMP/SRC"; then
        _mission_league
        fetch_page "/quest/"
    fi

    # ── Campanha (ID 5) ────────────────────────────────────────
    _check_timeout || return 0
    if grep -q "quest_id=5" "$TMP/SRC"; then
        _mission_campaign
        fetch_page "/quest/"
    fi

    # ── Altares antigos (ID 10) ────────────────────────────────
    _check_timeout || return 0
    if grep -q "quest_id=10" "$TMP/SRC"; then
        _mission_altars
        fetch_page "/quest/"
    fi

    # ── Gladiador (ID 11) ──────────────────────────────────────
    _check_timeout || return 0
    if grep -q "quest_id=11" "$TMP/SRC"; then
        _mission_coliseum
        fetch_page "/quest/"
    fi

    # ── Busca de recursos (ID 2) ──────────────────────────────
    _check_timeout || return 0
    if grep -q "quest_id=2" "$TMP/SRC"; then
        _mission_cave
        fetch_page "/quest/"
    fi

    # ── Alquimia (ID 13) ───────────────────────────────────────
    _check_timeout || return 0
    if grep -q "quest_id=13" "$TMP/SRC"; then
        _mission_alchemy
        fetch_page "/quest/"
    fi

    # ── Coletar todas as recompensas disponíveis ───────────────
    _check_timeout || return 0
    _mission_collect_rewards

    echo_t "Missions done" "${GREEN_BLACK}" "${COLOR_RESET}" "after" "✅\n"
}
