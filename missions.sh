# shellcheck disable=SC2148,SC2034

# ============================================================================
# MISSIONS SYSTEM - TitansWarPro
# ============================================================================
# Handles player missions: debug, execution and reward collection
# ============================================================================

# ── HELPER: Fetch page and append HTML + text dump to a debug log ─────────
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

    {
        echo "--- LINKS (href) ---"
        grep -o -E "href='[^']+'" "$TMP/SRC" | sort -u
        echo ""
        echo "--- TEXT RENDER ---"
        w3m -dump -T text/html "$TMP/SRC" 2>/dev/null
        echo ""
        echo "--- HTML SOURCE ---"
        cat "$TMP/SRC"
        echo ""
    } >> "$log_file"
}

# ============================================================================
# MISSION DEBUG — reads quest, arena, league and alchemy pages
# Run once manually to inspect which quest IDs map to which activities
# ============================================================================
mission_debug() {
    local debug_dir="${ACCOUNT_LOGS:-$TMP}"
    local debug_ts
    printf -v debug_ts '%(%Y%m%d_%H%M%S)T' -1
    local debug_file="${debug_dir}/mission_debug_${debug_ts}.log"

    echo_t "Mission Debug" "${GOLD_BLACK}" "${COLOR_RESET}" "after" "📜"

    : > "$debug_file"
    {
        echo "MISSION DEBUG — $(date)"
        echo "Account: ${ACC:-unknown} | URL: ${URL}"
    } >> "$debug_file"

    # Pages to inspect
    local pages=("/quest/" "/arena/" "/league/" "/lab/alchemy/")

    for page in "${pages[@]}"; do
        echo_t "  Fetching ${page}" "${GRAY_BLACK}" "${COLOR_RESET}" "before" "🔍"
        _mission_dump_page "$page" "$debug_file"
    done

    echo_t "Debug saved: $debug_file" "${GREEN_BLACK}" "${COLOR_RESET}" "after" "✅"
    echo "$debug_file"
}

# ============================================================================
# DO MISSIONS — execute available player missions then collect rewards
# Respects FUNC_do_missions and weekend pause (FUNC_pause_weekends)
# 3 missions cannot be automated and are ignored (to be defined after debug)
# ============================================================================
do_missions() {
    if [ "${FUNC_do_missions:-n}" != "y" ]; then
        return
    fi

    # Respect weekend pause setting (reuses the same flag as mission rewards)
    if [ "${FUNC_pause_weekends:-y}" = "y" ]; then
        local current_day
        current_day=$(date +%u)  # 1=Mon ... 7=Sun
        if [ "$current_day" -eq 6 ] || [ "$current_day" -eq 7 ]; then
            echo_t "Missions paused for the weekend" "${BLACK_RED}" "${COLOR_RESET}" "after" "⏸️"
            return
        fi
    fi

    echo_t "Doing Missions" "${GOLD_BLACK}" "${COLOR_RESET}" "after" "📜"

    fetch_page "/quest/"

    # ── Mission execution will be implemented after debug analysis ──
    # Placeholder: collect any missions already completed
    for i in {0..16}; do
        local click
        click=$(grep -o -E "/quest/end/${i}[?]r=[0-9]+" "$TMP/SRC" | sed -n '1p')
        if [ -n "$click" ]; then
            fetch_page "$click"
            echo_t " Mission ${i} reward collected" "${GREEN_BLACK}" "${COLOR_RESET}" "after" "✅\n"
        fi
    done

    echo_t "Missions done" "${GREEN_BLACK}" "${COLOR_RESET}" "after" "✅\n"
}
