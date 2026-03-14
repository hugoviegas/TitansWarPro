# shellcheck disable=SC2155,SC2034

# ============================================================================
# COLISEUM BATTLE SYSTEM v2.0 - TitansWarPro
# ============================================================================
# Modules: Debug, Stats, Display, Adaptive, Parser, Fight, Start
# ============================================================================

# ── Helper: w3m fetch shorthand (coliseum-specific) ────────────────────────
_cl_fetch() {
    local url_path="$1"
    (
        w3mc -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 \
            -debug -dump_source "${URL}${url_path}" \
            -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$src_ram"
    ) </dev/null &>/dev/null &
    time_exit 17
}

# ============================================================================
# MODULE: DEBUG - Captures raw HTML from all coliseum page states
# ============================================================================

coliseum_debug() {
    local debug_dir="${ACCOUNT_LOGS:-$TMP}"
    local debug_ts
    printf -v debug_ts '%(%Y%m%d_%H%M%S)T' -1
    local debug_file="${debug_dir}/coliseum_debug_${debug_ts}.log"

    local dir_ram
    if [ -d "/dev/shm" ]; then dir_ram="/dev/shm/"; else dir_ram="$PREFIX/tmp/"; fi
    mkdir -p "$dir_ram"
    local src_ram
    src_ram=$(mktemp -p "$dir_ram" debug.XXXXXX)

    # Helper: capture a single page state
    _debug_capture() {
        local label="$1"
        local url_path="$2"

        printf '\n%s\n' "============================================================" >> "$debug_file"
        printf '=  %s\n' "$label" >> "$debug_file"
        printf '============================================================\n' >> "$debug_file"
        printf 'URL: %s%s\n' "$URL" "$url_path" >> "$debug_file"
        printf 'Timestamp: %(%Y-%m-%d %H:%M:%S)T\n' -1 >> "$debug_file"

        (
            w3mc -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 \
                -debug -dump_source "${URL}${url_path}" \
                -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$src_ram"
        ) </dev/null &>/dev/null &
        time_exit 20

        printf '\n--- W3M RENDERED DUMP ---\n' >> "$debug_file"
        w3m -dump -T text/html "$src_ram" >> "$debug_file" 2>/dev/null

        printf '\n--- EXTRACTED LINKS ---\n' >> "$debug_file"
        grep -o -E '/coliseum/[A-Za-z]+(/[?]r[=][0-9]+)?' "$src_ram" >> "$debug_file" 2>/dev/null
        printf '(enterFight): %s\n' "$(grep -o -E '/coliseum/enterFight/[?]r[=][0-9]+' "$src_ram" 2>/dev/null)" >> "$debug_file"

        printf '\n--- HP VALUES ---\n' >> "$debug_file"
        printf 'Player HP pattern (hp): %s\n' "$(grep -o -E '(hp)[^A-Za-z0-9]{1,4}[0-9]{2,5}' "$src_ram" 2>/dev/null)" >> "$debug_file"
        printf 'Player HP value: %s\n' "$(grep -o -E '(hp)[^A-Za-z0-9]{1,4}[0-9]{2,5}' "$src_ram" 2>/dev/null | grep -o -E '[0-9]{2,5}')" >> "$debug_file"
        printf 'Enemy HP pattern (nbsp): %s\n' "$(grep -o -E '(nbsp)[^A-Za-z0-9]{1,2}[0-9]{1,6}' "$src_ram" 2>/dev/null)" >> "$debug_file"
        printf 'Enemy HP value: %s\n' "$(grep -o -E '(nbsp)[^A-Za-z0-9]{1,2}[0-9]{1,6}' "$src_ram" 2>/dev/null | sed -n 's,nbsp[;],,;s,\ ,,;1p')" >> "$debug_file"

        printf '\n--- USERNAMES ---\n' >> "$debug_file"
        printf 'Pattern matches:\n' >> "$debug_file"
        grep -o -E "([[:upper:]][[:lower:]]{0,15}( [[:upper:]][[:lower:]]{0,13})?)[[:space:]][^[:alnum:]]s" "$src_ram" >> "$debug_file" 2>/dev/null

        printf '\n--- MARKERS ---\n' >> "$debug_file"
        printf 'end_fight present: %s\n' "$(grep -c 'end_fight' "$src_ram" 2>/dev/null)" >> "$debug_file"
        printf 'dodge link present: %s\n' "$(grep -c '/dodge/' "$src_ram" 2>/dev/null)" >> "$debug_file"
        printf 'txt smpl grey: %s\n' "$(grep -c 'txt smpl grey' "$src_ram" 2>/dev/null)" >> "$debug_file"
        printf 'team [0] count: %s\n' "$(grep -o '\[0\]' "$src_ram" 2>/dev/null | wc -l)" >> "$debug_file"
        printf 'team [1] count: %s\n' "$(grep -o '\[1\]' "$src_ram" 2>/dev/null | wc -l)" >> "$debug_file"
        printf 'rip count: %s\n' "$(grep -o '\[rip\]' "$src_ram" 2>/dev/null | wc -l)" >> "$debug_file"

        printf '\n--- ACTION LINKS ---\n' >> "$debug_file"
        printf 'ATK: %s\n' "$(grep -o -E '/coliseum/atk/[?]r[=][0-9]+' "$src_ram" 2>/dev/null | head -1)" >> "$debug_file"
        printf 'ATKRND: %s\n' "$(grep -o -E '/coliseum/atkrnd/[?]r[=][0-9]+' "$src_ram" 2>/dev/null)" >> "$debug_file"
        printf 'DODGE: %s\n' "$(grep -o -E '/coliseum/dodge/[?]r[=][0-9]+' "$src_ram" 2>/dev/null)" >> "$debug_file"
        printf 'HEAL: %s\n' "$(grep -o -E '/coliseum/heal/[?]r[=][0-9]+' "$src_ram" 2>/dev/null)" >> "$debug_file"
        printf 'STONE: %s\n' "$(grep -o -E '/coliseum/stone/[?]r[=][0-9]+' "$src_ram" 2>/dev/null)" >> "$debug_file"
        printf 'GRASS: %s\n' "$(grep -o -E '/coliseum/grass/[?]r[=][0-9]+' "$src_ram" 2>/dev/null)" >> "$debug_file"
        printf 'STONE grey: %s\n' "$(grep -o "b_grey[^>]*href='/coliseum/stone" "$src_ram" 2>/dev/null | head -1)" >> "$debug_file"
        printf 'GRASS grey: %s\n' "$(grep -o "b_grey[^>]*href='/coliseum/grass" "$src_ram" 2>/dev/null | head -1)" >> "$debug_file"

        printf '\n--- FULL TEXT SEARCH (victory/defeat keywords) ---\n' >> "$debug_file"
        local rendered
        rendered=$(w3m -dump -T text/html "$src_ram" 2>/dev/null)
        echo "$rendered" | grep -i -E 'vit[oó]ria|victory|defeat|derrota|perdeu|ganhou|won|lost|winner|loser|venceu|reward' >> "$debug_file" 2>/dev/null
        printf '(end of keyword search)\n' >> "$debug_file"
    }

    echo_t "Coliseum Debug - Starting capture..." "${GOLD_BLACK}" "${COLOR_RESET}" "after" "🔍"
    printf 'Coliseum Debug Log - %(%Y-%m-%d %H:%M:%S)T\n' -1 > "$debug_file"
    printf 'Server URL: %s\n' "$URL" >> "$debug_file"

    # 1. Lobby
    _debug_capture "STATE: LOBBY (main /coliseum page)" "/coliseum"

    # 2. Check for enterFight link
    local ef_link
    ef_link=$(grep -o -E '/coliseum/enterFight/[?]r[=][0-9]+' "$src_ram" 2>/dev/null)

    if [ -n "$ef_link" ]; then
        # 3. Enter fight
        _debug_capture "STATE: ENTER FIGHT (clicking enterFight)" "$ef_link"

        # 4. Waiting for battle (poll a couple of times)
        local wait_count=0
        while ! grep -q -o 'coliseum/dodge/' "$src_ram" && [ "$wait_count" -lt 12 ]; do
            sleep 3s
            local wait_link
            wait_link=$(grep -o -E '/coliseum(/[A-Za-z]+/[?]r[=][0-9]+|/)' "$src_ram" | grep -v 'dodge' | head -1)
            [ -z "$wait_link" ] && wait_link="/coliseum"
            _debug_capture "STATE: WAITING (poll #$((wait_count+1)))" "$wait_link"
            wait_count=$((wait_count + 1))
        done

        # 5. In battle (if dodge appeared)
        if grep -q -o 'coliseum/dodge/' "$src_ram"; then
            _debug_capture "STATE: IN BATTLE (dodge link found)" "/coliseum"
        fi
    else
        printf '\n(No enterFight link found - not battle time or already in battle)\n' >> "$debug_file"
    fi

    # 6. Check for end_fight
    if grep -q -o 'end_fight' "$src_ram"; then
        _debug_capture "STATE: END FIGHT (result page)" "/coliseum/?end_fight=true"
    fi

    # 7. Merchant page
    _debug_capture "STATE: MERCHANT (shop page)" "/coliseum/merchant/"

    # 8. Max HP from /train
    printf '\n============================================================\n' >> "$debug_file"
    printf '=  MAX HP FROM /train\n' >> "$debug_file"
    printf '============================================================\n' >> "$debug_file"
    (
        w3mc -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 \
            -debug -dump_source "$URL/train" \
            -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$src_ram"
    ) </dev/null &>/dev/null &
    time_exit 20
    printf 'Full HP pattern: %s\n' "$(grep -o -E '\(([0-9]+)\)' "$src_ram" 2>/dev/null)" >> "$debug_file"
    printf 'Full HP value: %s\n' "$(grep -o -E '\(([0-9]+)\)' "$src_ram" 2>/dev/null | sed 's/[()]//g')" >> "$debug_file"

    # Cleanup
    rm -f "$src_ram"
    unset _debug_capture

    echo_t "Debug capture complete!" "${GREEN_BLACK}" "${COLOR_RESET}" "after" "✅"
    printf 'File: %s\n' "$debug_file"
    printf 'Size: %s bytes\n' "$(wc -c < "$debug_file" 2>/dev/null)"
}

# ============================================================================
# MODULE: STATISTICS - Track wins, losses, kills, match history
# ============================================================================

_cl_stats_load() {
    local stats_file="${ACCOUNT_LOGS:-$TMP}/coliseum_stats.dat"
    if [ -f "$stats_file" ]; then
        # shellcheck disable=SC1090
        . "$stats_file"
    else
        cl_total_matches=0; cl_wins=0; cl_losses=0
        cl_total_kills=0; cl_total_deaths=0
        cl_heals_used=0; cl_dodges_used=0
        cl_attacks_sent=0; cl_random_attacks_sent=0
        cl_longest_win_streak=0; cl_current_win_streak=0
        cl_total_battle_seconds=0
    fi
}

_cl_stats_save() {
    local stats_file="${ACCOUNT_LOGS:-$TMP}/coliseum_stats.dat"
    {
        echo "# Coliseum Statistics - Auto-generated"
        echo "cl_total_matches=$cl_total_matches"
        echo "cl_wins=$cl_wins"
        echo "cl_losses=$cl_losses"
        echo "cl_total_kills=$cl_total_kills"
        echo "cl_total_deaths=$cl_total_deaths"
        echo "cl_heals_used=$cl_heals_used"
        echo "cl_dodges_used=$cl_dodges_used"
        echo "cl_attacks_sent=$cl_attacks_sent"
        echo "cl_random_attacks_sent=$cl_random_attacks_sent"
        printf 'cl_last_match_date=%(%Y-%m-%d)T\n' -1
        echo "cl_last_match_result=$_cl_result"
        echo "cl_last_opponent=$_cl_opponent"
        echo "cl_longest_win_streak=$cl_longest_win_streak"
        echo "cl_current_win_streak=$cl_current_win_streak"
        echo "cl_total_battle_seconds=$cl_total_battle_seconds"
    } > "$stats_file"
}

_cl_history_append() {
    local hist_file="${ACCOUNT_LOGS:-$TMP}/coliseum_history.log"
    local ts duration
    printf -v ts '%(%Y-%m-%d %H:%M)T' -1
    duration=$(( $(date +%s) - _cl_battle_start ))
    printf '%s|%s|%s|%ds|kills:%d|deaths:%d|heals:%d|dodges:%d|atks:%d|atkrnds:%d\n' \
        "$ts" "$_cl_result" "$_cl_opponent" "$duration" \
        "$_cl_match_kills" "$_cl_match_deaths" "$_cl_match_heals" "$_cl_match_dodges" \
        "$_cl_match_atks" "$_cl_match_atkrnds" >> "$hist_file"
}

_cl_stats_show() {
    _cl_stats_load
    local wr=0
    if [ "$cl_total_matches" -gt 0 ]; then
        wr=$(awk -v w="$cl_wins" -v t="$cl_total_matches" 'BEGIN { printf "%.1f", w/t*100 }')
    fi
    printf '  %sMatches: %d  |  W: %s%d%s  L: %s%d%s  |  WR: %s%%%s\n' \
        "$GRAY_BLACK" "$cl_total_matches" \
        "$GREEN_BLACK" "$cl_wins" "$GRAY_BLACK" \
        "$RED_BLACK" "$cl_losses" "$GRAY_BLACK" \
        "$wr" "$COLOR_RESET"
    printf '  %sKills: %d  Deaths: %d  |  Streak: %d (best: %d)%s\n' \
        "$GRAY_BLACK" "$cl_total_kills" "$cl_total_deaths" \
        "$cl_current_win_streak" "$cl_longest_win_streak" "$COLOR_RESET"
}

# ============================================================================
# MODULE: DISPLAY - Formatted battle output and post-match summary
# ============================================================================

_cl_display_battle() {
    [ -z "$USH" ] && return

    local max_hp
    max_hp=$(cat "$full_ram" 2>/dev/null)
    [ -z "$max_hp" ] || [ "$max_hp" -eq 0 ] 2>/dev/null && max_hp="$USH"

    # HP percentage
    local hp_pct
    hp_pct=$(awk -v cur="$USH" -v mx="$max_hp" 'BEGIN { v=cur/mx*100; if(v>100)v=100; printf "%.0f", v }')

    # HP bar (16 chars)
    local bar_filled bar_empty hp_color
    bar_filled=$(awk -v pct="$hp_pct" 'BEGIN { v=pct*16/100; if(v<0)v=0; if(v>16)v=16; printf "%.0f", v }')
    bar_empty=$((16 - bar_filled))

    if [ "$hp_pct" -gt 60 ] 2>/dev/null; then
        hp_color="$GREEN_BLACK"
    elif [ "$hp_pct" -gt 30 ] 2>/dev/null; then
        hp_color="$GOLD_BLACK"
    else
        hp_color="$RED_BLACK"
    fi

    local bar=""
    local j
    for ((j=0; j<bar_filled; j++)); do bar+="█"; done
    for ((j=0; j<bar_empty; j++)); do bar+="░"; done

    local elapsed=$(( $(date +%s) - _cl_battle_start ))
    local min=$((elapsed / 60))
    local sec=$((elapsed % 60))

    printf '\n'
    printf '  %s═══════ COLISEUM BATTLE ═══════%s\n' "$GOLD_BLACK" "$COLOR_RESET"
    printf '  HP: %s%s/%s%s [%s] %d%%   %(%H:%M)T  (%dm%02ds)\n' \
        "$hp_color" "$USH" "$max_hp" "$COLOR_RESET" "$bar" "$hp_pct" -1 "$min" "$sec"
    printf '  VS: %s  ENH: %s\n' "${_cl_opponent:-?}" "${ENH:-?}"
    printf '  %s──────────────────────────────%s\n' "$GRAY_BLACK" "$COLOR_RESET"
    printf '  Last: %-28s  LA: %ss\n' "$_cl_last_action" "$LA"
    printf '  %s──────────────────────────────%s\n' "$GRAY_BLACK" "$COLOR_RESET"
    printf '  ATK:%d  RND:%d  DODGE:%d  HEAL:%d\n' \
        "$_cl_match_atks" "$_cl_match_atkrnds" "$_cl_match_dodges" "$_cl_match_heals"
    local stone_st grass_st
    [ "${_cl_stone_used:-0}" -eq 0 ] && stone_st="${GREEN_BLACK}READY${COLOR_RESET}" || stone_st="${GRAY_BLACK}USED${COLOR_RESET}"
    [ "${_cl_grass_used:-0}" -eq 0 ] && grass_st="${GREEN_BLACK}READY${COLOR_RESET}" || grass_st="${GRAY_BLACK}USED${COLOR_RESET}"
    printf '  🪨 Stone:%b  🌿 Grass:%b\n' "$stone_st" "$grass_st"
}

_cl_display_post_match() {
    local duration=$(( $(date +%s) - _cl_battle_start ))
    local min=$((duration / 60))
    local sec=$((duration % 60))

    printf '\n'
    printf '  %s═══════ MATCH COMPLETE ═══════%s\n' "$GOLD_BLACK" "$COLOR_RESET"

    if [ "$_cl_result" = "win" ]; then
        printf '  Result: %sVICTORY!%s\n' "$GREEN_BLACK" "$COLOR_RESET"
    else
        printf '  Result: %sDEFEAT%s\n' "$RED_BLACK" "$COLOR_RESET"
    fi

    printf '  Duration: %dm %ds  |  Opponent: %s\n' "$min" "$sec" "${_cl_opponent:-?}"
    printf '  %s──────────────────────────────%s\n' "$GRAY_BLACK" "$COLOR_RESET"
    printf '  ATK:%d  RND:%d  DODGE:%d  HEAL:%d\n' \
        "$_cl_match_atks" "$_cl_match_atkrnds" "$_cl_match_dodges" "$_cl_match_heals"
    printf '  Kills: %d   Deaths: %d\n' "$_cl_match_kills" "$_cl_match_deaths"
    printf '  %s──────────────────────────────%s\n' "$GRAY_BLACK" "$COLOR_RESET"
    _cl_stats_show
    printf '  %s══════════════════════════════%s\n' "$GOLD_BLACK" "$COLOR_RESET"
}

# ============================================================================
# MODULE: PARSER - Detect win/loss from end_fight page
# ============================================================================

_cl_parse_end_fight() {
    # Fetch end_fight page
    (
        w3mc -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 \
            -debug -dump_source "$URL/coliseum/?end_fight=true" \
            -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$src_ram"
    ) </dev/null &>/dev/null &
    time_exit 17

    local rendered
    rendered=$(w3m -dump -T text/html "$src_ram" 2>/dev/null)

    # Count rips (deaths) per team from rendered output
    local team0_rip=0 team1_rip=0
    # Each line with [rip] also has a team marker [0] or [1] nearby
    # Parse line by line from rendered dump
    while IFS= read -r line; do
        if echo "$line" | grep -q '\[rip\]'; then
            if echo "$line" | grep -q '\[0\]'; then
                team0_rip=$((team0_rip + 1))
            elif echo "$line" | grep -q '\[1\]'; then
                team1_rip=$((team1_rip + 1))
            fi
        fi
    done <<< "$rendered"

    # Try to detect victory via keywords (multi-language)
    if echo "$rendered" | grep -q -i -E 'vit[oó]ria|victory|victoire|vittoria|gewonnen|zwyciest|pobeda|kemenangan'; then
        _cl_result="win"
    elif echo "$rendered" | grep -q -i -E 'derrota|defeat|defaite|sconfitta|verloren|przegra|porazhenie'; then
        _cl_result="loss"
    else
        # Fallback: compare rip counts using team detection
        if [ -n "$_cl_team" ]; then
            if [ "$_cl_team" = "0" ]; then
                [ "$team1_rip" -ge "$team0_rip" ] && _cl_result="win" || _cl_result="loss"
            else
                [ "$team0_rip" -ge "$team1_rip" ] && _cl_result="win" || _cl_result="loss"
            fi
        else
            _cl_result="unknown"
        fi
    fi

    # Set kills/deaths based on team
    if [ "$_cl_team" = "0" ]; then
        _cl_match_kills=$team1_rip
        _cl_match_deaths=$team0_rip
    elif [ "$_cl_team" = "1" ]; then
        _cl_match_kills=$team0_rip
        _cl_match_deaths=$team1_rip
    else
        _cl_match_kills=$((team0_rip + team1_rip))
        _cl_match_deaths=0
    fi
}

# ============================================================================
# MODULE: ADAPTIVE - Attack timing, heal threshold, opponent detection
# ============================================================================

# Check if an attack was successful
_cl_check_attack_success() {
    local prev_enh="$1"
    local curr_enh="$2"

    # Check for explicit failure text in the rendered page
    local rendered
    rendered=$(w3m -dump -T text/html "$src_ram" 2>/dev/null | head -n 20)
    if echo "$rendered" | grep -q -i -E 'perdeu|falhou|failed|cooldown|too fast|muito r'; then
        return 1
    fi

    # If enemy HP unchanged AND action token unchanged -> rejected
    if [ -n "$prev_enh" ] && [ "$curr_enh" = "$prev_enh" ]; then
        local new_atk
        new_atk=$(grep -o -E '/coliseum/atk/[?]r[=][0-9]+' "$src_ram" | head -1)
        if [ "$new_atk" = "$ATK" ] && [ -n "$ATK" ]; then
            return 1
        fi
    fi

    return 0
}

# Track HP samples for damage rate calculation
_cl_track_hp() {
    [ -z "$USH" ] && return
    local now
    now=$(date +%s)
    _cl_hp_times[$_cl_hp_count]=$now
    _cl_hp_values[$_cl_hp_count]=$USH
    _cl_hp_count=$((_cl_hp_count + 1))
    # Keep only last 10 samples
    if [ "$_cl_hp_count" -gt 10 ]; then
        local i
        for ((i=0; i<9; i++)); do
            _cl_hp_times[$i]=${_cl_hp_times[$((i+1))]}
            _cl_hp_values[$i]=${_cl_hp_values[$((i+1))]}
        done
        _cl_hp_count=10
    fi
}

# Adapt HPER based on damage rate
_cl_adapt_hper() {
    [ "$_cl_hp_count" -lt 3 ] && return

    local t1=${_cl_hp_times[0]}
    local hp1=${_cl_hp_values[0]}
    local t2=${_cl_hp_times[$((_cl_hp_count - 1))]}
    local hp2=${_cl_hp_values[$((_cl_hp_count - 1))]}
    local dt=$((t2 - t1))
    [ "$dt" -eq 0 ] && return

    local max_hp
    max_hp=$(cat "$full_ram" 2>/dev/null)
    [ -z "$max_hp" ] || [ "$max_hp" -eq 0 ] 2>/dev/null && return

    # damage_rate = HP lost per second
    local high_threshold low_threshold
    high_threshold=$(awk -v mx="$max_hp" 'BEGIN { printf "%.1f", mx * 0.02 }')
    low_threshold=$(awk -v mx="$max_hp" 'BEGIN { printf "%.1f", mx * 0.005 }')
    local dmg_rate
    dmg_rate=$(awk -v hp1="$hp1" -v hp2="$hp2" -v dt="$dt" 'BEGIN { r=(hp1-hp2)/dt; if(r<0)r=0; printf "%.1f", r }')

    if awk -v rate="$dmg_rate" -v th="$high_threshold" 'BEGIN { exit !(rate > th) }'; then
        # Heavy damage - heal earlier (increase %, max 60)
        HPER=$(awk -v h="$HPER" 'BEGIN { v=h+5; if(v>60)v=60; printf "%.0f", v }')
    elif awk -v rate="$dmg_rate" -v th="$low_threshold" 'BEGIN { exit !(rate < th) }'; then
        # Light damage - be aggressive (decrease %, min 20)
        HPER=$(awk -v h="$HPER" 'BEGIN { v=h-2; if(v<20)v=20; printf "%.0f", v }')
    fi
}

# Adapt RPER based on opponent strength
_cl_adapt_rper() {
    local max_hp enh
    max_hp=$(cat "$full_ram" 2>/dev/null)
    enh="$ENH"
    [ -z "$max_hp" ] || [ -z "$enh" ] && return

    local ratio
    ratio=$(awk -v e="$enh" -v m="$max_hp" 'BEGIN { if(m>0) printf "%.1f", e/m; else print "1.0" }')

    if awk -v r="$ratio" 'BEGIN { exit !(r > 2.0) }'; then
        RPER=20
    elif awk -v r="$ratio" 'BEGIN { exit !(r > 1.5) }'; then
        RPER=15
    elif awk -v r="$ratio" 'BEGIN { exit !(r > 1.0) }'; then
        RPER=10
    else
        RPER=5
    fi
}

# Detect opponent type
_cl_detect_opponent() {
    _cl_opp_type="normal"

    # Check allied
    if [ -n "$USER" ] && grep -q -o "$USER" allies.txt 2>/dev/null; then
        _cl_opp_type="ally"
        RPER=100
        return
    fi

    local max_hp enh
    max_hp=$(cat "$full_ram" 2>/dev/null)
    enh="$ENH"
    [ -z "$max_hp" ] || [ -z "$enh" ] && return

    local ratio
    ratio=$(awk -v e="$enh" -v m="$max_hp" 'BEGIN { if(m>0) printf "%.1f", e/m; else print "1.0" }')

    if awk -v r="$ratio" 'BEGIN { exit !(r > 2.0) }'; then
        _cl_opp_type="strong"
    elif awk -v r="$ratio" 'BEGIN { exit !(r < 0.5) }'; then
        _cl_opp_type="weak"
    fi
}

# ============================================================================
# MODULE: FIGHT - Main battle function (rewrite)
# ============================================================================

coliseum_fight() {
    # ── Setup temp files ───────────────────────────────────────────
    local dir_ram
    if [ -d "/dev/shm" ]; then dir_ram="/dev/shm/"; else dir_ram="$PREFIX/tmp/"; fi
    mkdir -p "$dir_ram"
    src_ram=$(mktemp -p "$dir_ram" data.XXXXXX)
    full_ram=$(mktemp -p "$dir_ram" data.XXXXXX)
    tmp_ram=$(mktemp -d -t twmdir.XXXXXX)
    cp -r "$TMP"/* "$tmp_ram"
    cd "$tmp_ram" || exit

    # ── Load config (with defaults) ────────────────────────────────
    local LA="${COLISEUM_LA:-5}"
    local HPER="${COLISEUM_HPER:-38}"
    local RPER="${COLISEUM_RPER:-5}"

    # ── Per-match counters ─────────────────────────────────────────
    _cl_match_heals=0; _cl_match_dodges=0; _cl_match_atks=0; _cl_match_atkrnds=0
    _cl_match_kills=0; _cl_match_deaths=0; _cl_result=""
    _cl_opponent=""; _cl_team=""
    _cl_last_action="waiting..."
    _cl_atk_failures=0; _cl_atk_successes=0; _cl_la_adjusted=0
    _cl_hp_times=(); _cl_hp_values=(); _cl_hp_count=0
    _cl_opp_type="normal"
    _cl_loop_count=0
    _cl_battle_start=0
    _cl_stone_used=0; _cl_grass_used=0

    # ── Load cumulative stats ──────────────────────────────────────
    _cl_stats_load

    echo_t "Coliseum" "${GOLD_BLACK}" "${COLOR_RESET}" "after" "🧱"

    # ── Get max HP from /train ─────────────────────────────────────
    (
        w3mc -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 \
            -debug -dump_source "$URL/train" \
            -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" | \
            grep -o -E '\(([0-9]+)\)' | sed 's/[()]//g' >"$full_ram"
    ) &
    time_exit 20

    # ── Set graphics to 0 ─────────────────────────────────────────
    (
        w3mc -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 \
            -debug "$URL/settings/graphics/0" \
            -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$src_ram"
    ) </dev/null &>/dev/null &
    time_exit 17

    # ── Fetch coliseum lobby ───────────────────────────────────────
    _cl_fetch "/coliseum"

    # ── Handle leftover end_fight ──────────────────────────────────
    if grep -q -o '?end_fight' "$src_ram"; then
        _cl_parse_end_fight
        _cl_fetch "/coliseum"
    fi

    # ── Find enterFight link ───────────────────────────────────────
    local go_stop
    go_stop=$(grep -o -E '/coliseum/enterFight/[?]r[=][0-9]+' "$src_ram")

    if [ -n "$go_stop" ]; then
        echo_t "  Entering..." "" "\n" "before" "🤺"
        _cl_fetch "$go_stop"

        echo_t " Preparing for battle, waiting for other players..." "" "\n" "before" "😠"

        # ── Wait for battle to start (max 30s) ─────────────────────
        local wait_start
        wait_start=$(date +%s)
        until grep -q -o 'coliseum/dodge/' "$src_ram" || \
              [ $(($(date +%s) - wait_start)) -gt 30 ]; do
            local access_link
            access_link=$(grep -o -E '/coliseum(/[A-Za-z]+/[?]r[=][0-9]+|/)' "$src_ram" | \
                          grep -v 'dodge' | head -1)
            [ -z "$access_link" ] && access_link="/coliseum"
            _cl_fetch "$access_link"
            echo_t " 	Preparing..." "" "\n" "before" "😡"
            sleep 3s
        done

        # ── Battle started ─────────────────────────────────────────
        _cl_battle_start=$(date +%s)

        # Parse current state
        cl_access() {
            # Initialize cooldown timers
            last_heal=$(($(date +%s) - 90))
            last_dodge=$(($(date +%s) - 20))
            last_atk=$(($(date +%s) - ${LA%%.*}))

            # Extract battle data
            USH=$(grep -o -E '(hp)[^A-Za-z0-9]{1,4}[0-9]{2,5}' "$src_ram" | grep -o -E '[0-9]{2,5}' | sed 's, ,,g')
            ENH=$(grep -o -E '(nbsp)[^A-Za-z0-9]{1,2}[0-9]{1,6}' "$src_ram" | sed -n 's,nbsp[;],,;s, ,,;1p')
            USER=$(grep -o -E '([[:upper:]][[:lower:]]{0,15}( [[:upper:]][[:lower:]]{0,13})?)[[:space:]][^[:alnum:]]s' "$src_ram" | sed -n 's, [<]s,,;s, ,_,;2p')

            # Action links
            ATK=$(grep -o -E '/coliseum/atk/[?]r[=][0-9]+' "$src_ram" | head -1)
            ATKRND=$(grep -o -E '/coliseum/atkrnd/[?]r[=][0-9]+' "$src_ram")
            DODGE=$(grep -o -E '/coliseum/dodge/[?]r[=][0-9]+' "$src_ram")
            HEAL=$(grep -o -E '/coliseum/heal/[?]r[=][0-9]+' "$src_ram")
            STONE=$(grep -o -E '/coliseum/stone/[?]r[=][0-9]+' "$src_ram")
            GRASS=$(grep -o -E '/coliseum/grass/[?]r[=][0-9]+' "$src_ram")

            # Compute thresholds
            RHP=$(awk -v ush="$USH" -v rper="$RPER" 'BEGIN { printf "%.0f", ush * rper / 100 + ush }')
            HLHP=$(awk -v ush="$(cat "$full_ram")" -v hper="$HPER" 'BEGIN { printf "%.0f", ush * hper / 100 }')

            # Track HP for adaptive system
            _cl_track_hp

            # Set opponent
            [ -n "$USER" ] && _cl_opponent="$USER"

            # Detect team (first time only)
            if [ -z "$_cl_team" ]; then
                local player_line
                player_line=$(w3m -dump -T text/html "$src_ram" 2>/dev/null | head -n 5)
                if echo "$player_line" | grep -q '\[0\]'; then
                    _cl_team="0"
                elif echo "$player_line" | grep -q '\[1\]'; then
                    _cl_team="1"
                fi
            fi

            # Display or detect battle end
            if grep -q -o '/dodge/' "$src_ram"; then
                _cl_display_battle
            else
                if grep -q -o '?end_fight=true' "$src_ram"; then
                    if [ $(($(date +%s) - _cl_battle_start)) -lt 300 ]; then
                        _cl_parse_end_fight
                        _cl_display_post_match
                    fi
                else
                    BREAK_LOOP=1
                    echo_t "Battle over." "${RED_BLACK}" "${COLOR_RESET}"
                    sleep 2s
                fi
            fi
        }

        # ── Initialize battle ──────────────────────────────────────
        cl_access
        local OLDHP=$USH
        BREAK_LOOP=""

        # Detect opponent and adapt
        _cl_detect_opponent
        _cl_adapt_rper

        # ── Main battle loop ───────────────────────────────────────
        until [[ -n "$BREAK_LOOP" ]]; do
            now=$(date +%s)
            time_since_last_heal=$((now - last_heal))
            time_since_last_dodge=$((now - last_dodge))
            time_since_last_atk=$((now - last_atk))

            _cl_loop_count=$((_cl_loop_count + 1))

            # Periodic adaptive adjustments (every 5 loops)
            if [ $((_cl_loop_count % 5)) -eq 0 ]; then
                _cl_adapt_hper
            fi

            # ── Priority 0: STONE (first action of battle) ────────
            if [ "$_cl_stone_used" -eq 0 ] && [ -n "$STONE" ] && \
               ! grep -q "b_grey[^>]*href='/coliseum/stone" "$src_ram"; then
                _cl_fetch "$STONE"
                cl_access
                _cl_stone_used=1
                last_atk=$now
                _cl_last_action="🪨 Stone (+35% dmg)"

            # ── Priority 1: HEAL ───────────────────────────────────
            elif awk -v ush="$USH" -v hlhp="$HLHP" 'BEGIN { exit !(ush < hlhp) }' &&
               [[ "$time_since_last_heal" -gt 90 && "$time_since_last_heal" -lt 300 ]]; then
                _cl_fetch "$HEAL"
                cl_access
                echo "$USH" >"$full_ram"
                last_heal=$now
                last_atk=$now
                _cl_match_heals=$((_cl_match_heals + 1))
                _cl_last_action="🌿 Heal → HP:${USH}"

            # ── Priority 1.5: GRASS (use once when HP <= 50%) ─────
            elif [ "$_cl_grass_used" -eq 0 ] && [ -n "$GRASS" ] && \
                 ! grep -q "b_grey[^>]*href='/coliseum/grass" "$src_ram" && \
                 awk -v ush="$USH" -v mx="$(cat "$full_ram" 2>/dev/null)" \
                     'BEGIN { exit !(mx > 0 && ush <= mx * 0.50) }'; then
                _cl_fetch "$GRASS"
                cl_access
                _cl_grass_used=1
                last_atk=$now
                _cl_last_action="🌿 Grass (-35% dmg)"

            # ── Priority 2: DODGE ──────────────────────────────────
            elif ! grep -q -o 'txt smpl grey' "$src_ram" &&
                 [[ "$time_since_last_dodge" -gt 20 && "$time_since_last_dodge" -lt 300 ]] &&
                 awk -v ush="$USH" -v oldhp="$OLDHP" 'BEGIN { exit !(ush < oldhp) }'; then
                _cl_fetch "$DODGE"
                cl_access
                OLDHP=$USH
                last_dodge=$now
                last_atk=$now
                _cl_match_dodges=$((_cl_match_dodges + 1))
                _cl_last_action="🛡️ Dodge"

            # ── Priority 3: RANDOM ATTACK ──────────────────────────
            elif awk -v latk="$time_since_last_atk" -v atktime="${LA%%.*}" 'BEGIN { exit !(latk != atktime) }' &&
                 ! grep -q -o 'txt smpl grey' "$src_ram" &&
                 (awk -v rhp="$RHP" -v enh="$ENH" 'BEGIN { exit !(rhp < enh) }' ||
                 (awk -v latk="$time_since_last_atk" -v atktime="${LA%%.*}" 'BEGIN { exit !(latk != atktime) }' &&
                 ! grep -q -o 'txt smpl grey' "$src_ram" && grep -q -o "$USER" allies.txt 2>/dev/null)); then
                local prev_enh_val="$ENH"
                _cl_fetch "$ATKRND"
                cl_access
                last_atk=$now
                _cl_match_atkrnds=$((_cl_match_atkrnds + 1))
                _cl_last_action="🎲 Random Atk"

            # ── Priority 4: REGULAR ATTACK ─────────────────────────
            elif awk -v latk="$time_since_last_atk" -v atktime="${LA%%.*}" 'BEGIN { exit !(latk > atktime) }'; then
                local prev_enh_val="$ENH"
                local prev_atk_token="$ATK"
                _cl_fetch "$ATK"
                cl_access

                # Adaptive: check attack success
                if ! _cl_check_attack_success "$prev_enh_val" "$ENH"; then
                    _cl_atk_failures=$((_cl_atk_failures + 1))
                    _cl_atk_successes=0
                    LA=$(awk -v la="$LA" 'BEGIN { printf "%.1f", la + 0.2 }')
                    _cl_la_adjusted=1
                    _cl_last_action="⚔️ Atk → MISS (LA→${LA}s)"
                else
                    _cl_atk_successes=$((_cl_atk_successes + 1))
                    _cl_match_atks=$((_cl_match_atks + 1))
                    _cl_last_action="⚔️ Atk → hit!"
                    # After 10 consecutive successes, try reducing LA
                    if [ "$_cl_atk_successes" -ge 10 ] && [ "$_cl_la_adjusted" -eq 1 ]; then
                        if awk -v la="$LA" 'BEGIN { exit !(la > 3.0) }'; then
                            LA=$(awk -v la="$LA" 'BEGIN { printf "%.1f", la - 0.1 }')
                        fi
                        _cl_atk_successes=0
                    fi
                fi
                last_atk=$now

            # ── Priority 5: REFRESH ────────────────────────────────
            else
                _cl_fetch "/coliseum"
                cl_access
                sleep 1s
                _cl_last_action="🔄 Refresh"
            fi
        done

        # ── Post-battle: Update cumulative stats ───────────────────
        cl_total_matches=$((cl_total_matches + 1))
        if [ "$_cl_result" = "win" ]; then
            cl_wins=$((cl_wins + 1))
            cl_current_win_streak=$((cl_current_win_streak + 1))
            [ "$cl_current_win_streak" -gt "$cl_longest_win_streak" ] && \
                cl_longest_win_streak=$cl_current_win_streak
        elif [ "$_cl_result" = "loss" ]; then
            cl_losses=$((cl_losses + 1))
            cl_current_win_streak=0
        fi
        cl_total_kills=$((cl_total_kills + _cl_match_kills))
        cl_total_deaths=$((cl_total_deaths + _cl_match_deaths))
        cl_heals_used=$((cl_heals_used + _cl_match_heals))
        cl_dodges_used=$((cl_dodges_used + _cl_match_dodges))
        cl_attacks_sent=$((cl_attacks_sent + _cl_match_atks))
        cl_random_attacks_sent=$((cl_random_attacks_sent + _cl_match_atkrnds))
        local battle_dur=$(($(date +%s) - _cl_battle_start))
        cl_total_battle_seconds=$((cl_total_battle_seconds + battle_dur))

        _cl_stats_save
        _cl_history_append

        # Save adapted LA if changed
        if [ "$_cl_la_adjusted" -eq 1 ]; then
            update_config "COLISEUM_LA" "$LA"
        fi

        # ── Cleanup ────────────────────────────────────────────────
        rm -f "$src_ram" "$full_ram"
        rm -rf "$tmp_ram"
        unset last_heal last_dodge last_atk USH ENH USER ATK ATKRND DODGE HEAL STONE GRASS BREAK_LOOP cl_access
        unset _cl_match_heals _cl_match_dodges _cl_match_atks _cl_match_atkrnds
        unset _cl_match_kills _cl_match_deaths _cl_result _cl_opponent _cl_team
        unset _cl_last_action _cl_battle_start _cl_atk_failures _cl_atk_successes _cl_la_adjusted
        unset _cl_hp_times _cl_hp_values _cl_hp_count _cl_opp_type _cl_loop_count
        unset _cl_stone_used _cl_grass_used
        func_unset

        if awk -v smodplay="$RUN" -v rmodplay="-cl" 'BEGIN { exit !(smodplay != rmodplay) }'; then
            printf "\nYou can run ./twm/play.sh -cl\n"
        fi

        echo_t "The battle is over!" "${RED_BLACK}" "${COLOR_RESET}" "after" "⚔️\n"
    else
        # shellcheck disable=SC2154
        echo_t "It was not possible to start the battle at this time." "${WHITEb_BLACK}" "${COLOR_RESET}"
    fi
}

# ============================================================================
# MODULE: START - Scheduler/caller (backward compatible, minimal changes)
# ============================================================================

coliseum_start() {
    if [ "$FUNC_coliseum" = "n" ]; then
        return
    fi

    # Check if it's battle time
    if case $(date +%H:%M ) in
        (09:2[4-9] | 9:5[4-9] | 10:1[0-4] | 10:2[4-9] | 10:5[4-9] | 12:2[4-9] | 13:5[4-9] | 14:5[4-9] | 15:5[4-9] | 16:1[0-4] | 16:2[4-9] | 18:5[4-9] | 20:5[4-9] | 21:2[4-9] | 21:5[4-9] | 22:2[4-9])
            exit 1
            ;;
        esac then

        # Handle boot mode - quest related coliseum fights
        if echo "$RUN" | grep -q -E '[-]boot'; then
            (
                w3mc -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}/quest/" \
                    -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
            ) </dev/null &>/dev/null &
            time_exit 20

            # Continue fighting while quest is active
            while grep -q -o -E '/coliseum/[?]quest_t[=]quest&quest_id[=]11&qz[=][a-z0-9]+' "$TMP"/SRC; do
                coliseum_fight
                (
                    w3mc -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}/quest/" \
                        -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
                ) </dev/null &>/dev/null &
                time_exit 20

                # End quest if possible
                local ENDQUEST=$(grep -o -E '/quest/end/11[?]r[=][A_z0-9]+' "$TMP"/SRC)
                if [ -n "$ENDQUEST" ]; then
                    (
                        w3mc -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}${ENDQUEST}" \
                            -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
                    ) </dev/null &>/dev/null &
                    time_exit 20
                fi
            done

        # Handle direct coliseum mode
        elif echo "$RUN" | grep -q -E '[-]cl'; then
            coliseum_fight
        fi
    else
        echo_t "Battle or event time..."
        sleep 5s
    fi
}
