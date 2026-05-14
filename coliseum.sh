# shellcheck disable=SC2148,SC2155,SC2034
# ============================================================================
# COLISEUM BATTLE SYSTEM v3.0 - TitansWarPro AI Engine
# Integrated: _fetch, _parse_battle_state, _log_battle_event, strategy_config
# Modules: Debug, Stats, Display, Adaptive, Parser, Fight, Start
# ============================================================================

# Load shared helpers
# shellcheck source=core/helpers.sh
source "$(dirname "${BASH_SOURCE[0]}")/core/helpers.sh" 2>/dev/null || true

# ── Coliseum-specific fetch shorthand (keeps backward compat) ───────────────
_cl_fetch() { _fetch "$1" "${2:-$src_ram}" "${3:-17}"; }

# ============================================================================
# MODULE: STATISTICS
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
    local duration
    duration=$(( $(date +%s) - _cl_battle_start ))
    printf '%(%Y-%m-%d %H:%M)T|%s|%s|%ds|kills:%d|deaths:%d|heals:%d|dodges:%d|atks:%d|atkrnds:%d\n' \
        -1 "$_cl_result" "$_cl_opponent" "$duration" \
        "$_cl_match_kills" "$_cl_match_deaths" "$_cl_match_heals" "$_cl_match_dodges" \
        "$_cl_match_atks" "$_cl_match_atkrnds" >> "$hist_file"
}

_cl_stats_show() {
    _cl_stats_load
    local wr=0
    [ "$cl_total_matches" -gt 0 ] && \
        wr=$(awk -v w="$cl_wins" -v t="$cl_total_matches" 'BEGIN { printf "%.1f", w/t*100 }')
    printf '  %sMatches: %d  W: %s%d%s  L: %s%d%s  WR: %s%%%s\n' \
        "$GRAY_BLACK" "$cl_total_matches" \
        "$GREEN_BLACK" "$cl_wins" "$GRAY_BLACK" \
        "$RED_BLACK" "$cl_losses" "$GRAY_BLACK" \
        "$wr" "$COLOR_RESET"
    printf '  %sKills: %d  Deaths: %d  Streak: %d (best: %d)%s\n' \
        "$GRAY_BLACK" "$cl_total_kills" "$cl_total_deaths" \
        "$cl_current_win_streak" "$cl_longest_win_streak" "$COLOR_RESET"
}

# ============================================================================
# MODULE: DISPLAY
# ============================================================================

_cl_display_battle() {
    [ -z "$USH" ] && return
    local max_hp
    max_hp=$(cat "$full_ram" 2>/dev/null)
    [ -z "$max_hp" ] || [ "$max_hp" -eq 0 ] 2>/dev/null && max_hp="$USH"

    local hp_pct bar_filled bar_empty hp_color
    hp_pct=$(awk -v c="$USH" -v m="$max_hp" 'BEGIN { v=c/m*100; if(v>100)v=100; if(v<0)v=0; printf "%.0f", v }')
    bar_filled=$(awk -v p="$hp_pct" 'BEGIN { v=int(p*16/100); if(v<0)v=0; if(v>16)v=16; print v }')
    bar_empty=$(( 16 - bar_filled ))

    if   [ "$hp_pct" -gt 60 ] 2>/dev/null; then hp_color="$GREEN_BLACK"
    elif [ "$hp_pct" -gt 30 ] 2>/dev/null; then hp_color="$GOLD_BLACK"
    else hp_color="$RED_BLACK"; fi

    local bar="" j
    for (( j=0; j<bar_filled; j++ )); do bar+="█"; done
    for (( j=0; j<bar_empty;  j++ )); do bar+="░"; done

    local elapsed min sec current_time adp_info
    elapsed=$(( $(date +%s) - _cl_battle_start ))
    min=$(( elapsed / 60 )); sec=$(( elapsed % 60 ))
    printf -v current_time '%(%H:%M)T' -1
    [ "${_cl_la_adjusted:-0}" -eq 1 ] && adp_info="${GOLD_BLACK}(adapted)${COLOR_RESET}" || adp_info=""

    local stone_st grass_st heal_info
    [ "${_cl_stone_used:-0}" -eq 0 ] && stone_st="${GREEN_BLACK}READY${COLOR_RESET}" || stone_st="${GRAY_BLACK}USED${COLOR_RESET}"
    [ "${_cl_grass_used:-0}"  -eq 0 ] && grass_st="${GREEN_BLACK}READY${COLOR_RESET}" || grass_st="${GRAY_BLACK}USED${COLOR_RESET}"
    if [ "${time_since_last_heal:-90}" -lt 90 ] 2>/dev/null; then
        heal_info="${GOLD_BLACK}⏳$(( 90 - time_since_last_heal ))s${COLOR_RESET}"
    else
        heal_info="${GREEN_BLACK}READY${COLOR_RESET}"
    fi

    # Single render pass - reuse for log and display
    local _page_render
    _page_render=$(w3m -dump -T text/html "$src_ram" 2>/dev/null)

    printf "\n  ${GOLD_BLACK}═══════ COLISEUM BATTLE ═══════${COLOR_RESET}\n"
    printf "  ${hp_color}HP: %-5d/%-5d${COLOR_RESET} [${bar}] %-3d%%   %s  (%dm%ds)\n" "$USH" "$max_hp" "$hp_pct" "$current_time" "$min" "$sec"
    printf "  ${GRAY_BLACK}VS: %-16s  ENH: %-8d  Team:[%d]${COLOR_RESET}\n" "${_cl_opponent:-?}" "$ENH" "${_cl_team:-0}"
    printf "  ${GRAY_BLACK}LA: %s %s  HPER: %-2d%%  Heal: %b  RPER: %-2d%%  Fails: %-2d${COLOR_RESET}\n" \
        "$LA" "$adp_info" "$HPER" "$heal_info" "$RPER" "${_cl_atk_failures:-0}"
    printf "  ${GREEN_BLACK}ATK: %-3d  RND: %-3d  DODGE: %-3d  HEAL: %-3d${COLOR_RESET}\n" \
        "${_cl_match_atks:-0}" "${_cl_match_atkrnds:-0}" "${_cl_match_dodges:-0}" "${_cl_match_heals:-0}"
    printf "  🪨 Stone: %b  🌿 Grass: %b\n" "$stone_st" "$grass_st"

    # Participants + battle log from single render
    printf "  ${GRAY_BLACK}────── PARTICIPANTS ──────${COLOR_RESET}\n"
    echo "$_page_render" | grep "Os participantes:" | \
        sed 's|\[0\]|🔴|g; s|\[1\]|🔵|g; s|\[health\]|🧡|g' | \
        while IFS= read -r l; do printf "  ${GRAY_BLACK}%s${COLOR_RESET}\n" "$l"; done

    printf "  ${GRAY_BLACK}────── BATTLE LOG ──────${COLOR_RESET}\n"
    echo "$_page_render" | sed -n '/^Os participantes:/,/^A batalha já começou!/p' | \
        grep -v '^$\|Os participantes:\|A batalha já começou' | \
        sed 's|\[0\]|🔴|g;s|\[1\]|🔵|g;s|\[rip\]|💀|g;s|assassinou|💥|;s|perdeu|❌|;s|Você acertar|✓|;s|Você usou|⚡|' | \
        tail -n 8 | while IFS= read -r l; do printf "  ${GRAY_BLACK}%s${COLOR_RESET}\n" "$l"; done
}

_cl_display_post_match() {
    local duration min sec wr=0
    duration=$(( $(date +%s) - _cl_battle_start ))
    min=$(( duration / 60 )); sec=$(( duration % 60 ))
    [ "$cl_total_matches" -gt 0 ] && wr=$(awk -v w="$cl_wins" -v t="$cl_total_matches" 'BEGIN{printf"%.0f",w/t*100}')

    printf "\n"
    printf "  ${GOLD_BLACK}╔══════════════════════════════════════════════════════════╗${COLOR_RESET}\n"
    printf "  ${GOLD_BLACK}║                   BATTLE SUMMARY                        ║${COLOR_RESET}\n"
    printf "  ${GOLD_BLACK}╠══════════════════════════════════════════════════════════╣${COLOR_RESET}\n"
    if   [ "$_cl_result" = "win"  ]; then printf "  ${GREEN_BLACK}║     ✅  VICTORY!                                       ║${COLOR_RESET}\n"
    elif [ "$_cl_result" = "loss" ]; then printf "  ${RED_BLACK}║     ❌  DEFEAT                                         ║${COLOR_RESET}\n"
    else                                  printf "  ${GOLD_BLACK}║     ❓  RESULT UNKNOWN                                 ║${COLOR_RESET}\n"; fi
    printf "  ${GOLD_BLACK}╠══════════════════════════════════════════════════════════╣${COLOR_RESET}\n"
    printf "  ${GRAY_BLACK}║ Duration:${GOLD_BLACK} %-3dm%-3ds${GRAY_BLACK}  Opponent:${GOLD_BLACK} %-20s${GRAY_BLACK}Team:[${GOLD_BLACK}%d${GRAY_BLACK}]║${COLOR_RESET}\n" "$min" "$sec" "${_cl_opponent:-?}" "${_cl_team:-0}"
    printf "  ${GOLD_BLACK}╠══════════════════════════════════════════════════════════╣${COLOR_RESET}\n"
    printf "  ${GRAY_BLACK}║ ATK:${GREEN_BLACK}%-3d${GRAY_BLACK} RND:${GREEN_BLACK}%-3d${GRAY_BLACK} DODGE:${GREEN_BLACK}%-3d${GRAY_BLACK} HEAL:${GREEN_BLACK}%-3d${GRAY_BLACK} Kills:${GREEN_BLACK}%-3d${GRAY_BLACK} Deaths:${RED_BLACK}%-3d${GRAY_BLACK} ║${COLOR_RESET}\n" \
        "${_cl_match_atks:-0}" "${_cl_match_atkrnds:-0}" "${_cl_match_dodges:-0}" "${_cl_match_heals:-0}" "${_cl_match_kills:-0}" "${_cl_match_deaths:-0}"
    printf "  ${GRAY_BLACK}║ LA Final: %s  Fails: %-2d${COLOR_RESET}\n" "$LA" "${_cl_atk_failures:-0}"
    printf "  ${GOLD_BLACK}╠══════════════════════════════════════════════════════════╣${COLOR_RESET}\n"
    printf "  ${GRAY_BLACK}║ W:${GREEN_BLACK}%-3d${GRAY_BLACK} L:${RED_BLACK}%-3d${GRAY_BLACK} (%-2d%%)  Streak:${GREEN_BLACK}%-3d${GRAY_BLACK} Best:${GREEN_BLACK}%-3d${GRAY_BLACK}║${COLOR_RESET}\n" \
        "$cl_wins" "$cl_losses" "$wr" "$cl_current_win_streak" "$cl_longest_win_streak"
    printf "  ${GOLD_BLACK}╚══════════════════════════════════════════════════════════╝${COLOR_RESET}\n"
    sleep 10s
}

# ============================================================================
# MODULE: PARSER
# ============================================================================

_cl_parse_end_fight() {
    _cl_fetch "/coliseum/?end_fight=true"
    local rendered team0_rip=0 team1_rip=0
    rendered=$(w3m -dump -T text/html "$src_ram" 2>/dev/null)

    while IFS= read -r line; do
        if echo "$line" | grep -q '\[rip\]'; then
            echo "$line" | grep -q '\[0\]' && team0_rip=$(( team0_rip + 1 ))
            echo "$line" | grep -q '\[1\]' && team1_rip=$(( team1_rip + 1 ))
        fi
    done <<< "$rendered"

    if echo "$rendered" | grep -q -i -E 'vit[oó]ria|victory|victoire|vittoria|gewonnen'; then
        _cl_result="win"
    elif echo "$rendered" | grep -q -i -E 'derrota|defeat|defaite|sconfitta|verloren'; then
        _cl_result="loss"
    else
        if [ "$_cl_team" = "0" ]; then
            [ "$team1_rip" -ge "$team0_rip" ] && _cl_result="win" || _cl_result="loss"
        elif [ "$_cl_team" = "1" ]; then
            [ "$team0_rip" -ge "$team1_rip" ] && _cl_result="win" || _cl_result="loss"
        else
            _cl_result="unknown"
        fi
    fi

    if [ "$_cl_team" = "0" ]; then
        _cl_match_kills=$team1_rip; _cl_match_deaths=$team0_rip
    elif [ "$_cl_team" = "1" ]; then
        _cl_match_kills=$team0_rip; _cl_match_deaths=$team1_rip
    else
        _cl_match_kills=$(( team0_rip + team1_rip )); _cl_match_deaths=0
    fi
}

# ============================================================================
# MODULE: ADAPTIVE
# ============================================================================

_cl_check_attack_success() {
    local prev_enh="$1" curr_enh="$2"
    local rendered
    rendered=$(w3m -dump -T text/html "$src_ram" 2>/dev/null | head -n 20)
    echo "$rendered" | grep -q -i -E 'perdeu|falhou|failed|cooldown|too fast|muito r' && return 1
    if [ -n "$prev_enh" ] && [ "$curr_enh" = "$prev_enh" ]; then
        local new_atk
        new_atk=$(grep -m1 -oP '/coliseum/atk\?[^"]*' "$src_ram")
        [ "$new_atk" = "$ATK" ] && [ -n "$ATK" ] && return 1
    fi
    return 0
}

_cl_track_hp() {
    [ -z "$USH" ] && return
    local now; now=$(date +%s)
    _cl_hp_times[$_cl_hp_count]=$now
    _cl_hp_values[$_cl_hp_count]=$USH
    _cl_hp_count=$(( _cl_hp_count + 1 ))
    if [ "$_cl_hp_count" -gt 10 ]; then
        local i; for (( i=0; i<9; i++ )); do
            _cl_hp_times[$i]=${_cl_hp_times[$((i+1))]}
            _cl_hp_values[$i]=${_cl_hp_values[$((i+1))]}
        done
        _cl_hp_count=10
    fi
}

_cl_adapt_hper() {
    [ "$_cl_hp_count" -lt 3 ] && return
    local t1=${_cl_hp_times[0]} hp1=${_cl_hp_values[0]}
    local t2=${_cl_hp_times[$(( _cl_hp_count - 1 ))]} hp2=${_cl_hp_values[$(( _cl_hp_count - 1 ))]}
    local dt=$(( t2 - t1 ))
    [ "$dt" -eq 0 ] && return
    local max_hp; max_hp=$(cat "$full_ram" 2>/dev/null)
    [ -z "$max_hp" ] || [ "$max_hp" -eq 0 ] 2>/dev/null && return
    local dmg_rate high_t low_t
    dmg_rate=$(awk -v hp1="$hp1" -v hp2="$hp2" -v dt="$dt" 'BEGIN { r=(hp1-hp2)/dt; if(r<0)r=0; printf "%.1f", r }')
    high_t=$(awk -v mx="$max_hp" 'BEGIN { printf "%.1f", mx*0.02 }')
    low_t=$(awk  -v mx="$max_hp" 'BEGIN { printf "%.1f", mx*0.005 }')
    if awk -v r="$dmg_rate" -v h="$high_t" 'BEGIN{exit!(r>h)}'; then
        HPER=$(awk -v h="$HPER" 'BEGIN{v=h+5;if(v>60)v=60;printf"%.0f",v}')
    elif awk -v r="$dmg_rate" -v l="$low_t" 'BEGIN{exit!(r<l)}'; then
        HPER=$(awk -v h="$HPER" 'BEGIN{v=h-2;if(v<20)v=20;printf"%.0f",v}')
    fi
}

_cl_adapt_rper() {
    local max_hp enh ratio
    max_hp=$(cat "$full_ram" 2>/dev/null)
    enh="$ENH"
    [ -z "$max_hp" ] || [ -z "$enh" ] && return
    ratio=$(awk -v e="$enh" -v m="$max_hp" 'BEGIN{if(m>0)printf"%.1f",e/m;else print"1.0"}')
    if   awk -v r="$ratio" 'BEGIN{exit!(r>2.0)}'; then RPER=20
    elif awk -v r="$ratio" 'BEGIN{exit!(r>1.5)}'; then RPER=15
    elif awk -v r="$ratio" 'BEGIN{exit!(r>1.0)}'; then RPER=10
    else RPER=5; fi
}

_cl_detect_opponent() {
    _cl_opp_type="normal"
    local max_hp enh ratio
    max_hp=$(cat "$full_ram" 2>/dev/null)
    enh="$ENH"
    [ -z "$max_hp" ] || [ -z "$enh" ] && return
    ratio=$(awk -v e="$enh" -v m="$max_hp" 'BEGIN{if(m>0)printf"%.1f",e/m;else print"1.0"}')
    if   awk -v r="$ratio" 'BEGIN{exit!(r>2.0)}'; then _cl_opp_type="strong"
    elif awk -v r="$ratio" 'BEGIN{exit!(r<0.5)}'; then _cl_opp_type="weak"; fi
}

# ============================================================================
# MODULE: FIGHT
# ============================================================================

coliseum_fight() {
    # ── Temp files in RAM ─────────────────────────────────────────
    local dir_ram; dir_ram=$(_ram_dir)
    mkdir -p "$dir_ram"
    src_ram=$(mktemp -p "$dir_ram" data.XXXXXX)
    full_ram=$(mktemp -p "$dir_ram" data.XXXXXX)
    tmp_ram=$(mktemp -d -t twmdir.XXXXXX)
    _cl_battle_history=$(mktemp -p "$dir_ram" history.XXXXXX)
    cp -r "$TMP"/* "$tmp_ram"
    cd "$tmp_ram" || exit

    # ── Load config from strategy_config.json (falls back to env/defaults) ──
    local _cfg_la _cfg_hper _cfg_rper
    _cfg_la=$(   _cfg_get "coliseum" "la_start" 2>/dev/null)
    _cfg_hper=$( _cfg_get "coliseum" "hper"     2>/dev/null)
    _cfg_rper=$( _cfg_get "coliseum" "rper"     2>/dev/null)
    local LA="${_cfg_la:-${COLISEUM_LA:-4.5}}"
    local HPER="${_cfg_hper:-${COLISEUM_HPER:-38}}"
    local RPER="${_cfg_rper:-${COLISEUM_RPER:-5}}"

    # ── Per-match counters ─────────────────────────────────────────
    _cl_match_heals=0; _cl_match_dodges=0; _cl_match_atks=0; _cl_match_atkrnds=0
    _cl_match_kills=0; _cl_match_deaths=0; _cl_result=""; _cl_opponent=""; _cl_team=""
    _cl_atk_failures=0; _cl_atk_successes=0; _cl_la_adjusted=0
    _cl_hp_times=(); _cl_hp_values=(); _cl_hp_count=0; _cl_opp_type="normal"
    _cl_loop_count=0; _cl_battle_start=0; _cl_stone_used=0; _cl_grass_used=0

    _cl_stats_load

    # ── Pre-battle panel ───────────────────────────────────────────
    local _cf_wr=0
    [ "$cl_total_matches" -gt 0 ] && \
        _cf_wr=$(awk -v w="$cl_wins" -v t="$cl_total_matches" 'BEGIN{printf"%.0f",w/t*100}')
    printf "\n  ${GOLD_BLACK}╔═══════════════════════════════════╗${COLOR_RESET}\n"
    printf "  ${GOLD_BLACK}║  ⚔️  COLISEUM  BATTLE              ║${COLOR_RESET}\n"
    printf "  ${GOLD_BLACK}╠═══════════════════════════════════╣${COLOR_RESET}\n"
    printf "  ${GOLD_BLACK}║  LA: %-5s  HPER: %-2d%%  RPER: %-2d%%   ║${COLOR_RESET}\n" "$LA" "$HPER" "$RPER"
    printf "  ${GOLD_BLACK}║  W:${GREEN_BLACK}%-3d${GOLD_BLACK} L:${RED_BLACK}%-3d${GOLD_BLACK} (%-2d%%)  Streak:${GREEN_BLACK}%-3d${GOLD_BLACK}  ║${COLOR_RESET}\n" \
        "$cl_wins" "$cl_losses" "$_cf_wr" "$cl_current_win_streak"
    printf "  ${GOLD_BLACK}╚═══════════════════════════════════╝${COLOR_RESET}\n"

    # ── Get max HP ─────────────────────────────────────────────────
    _fetch "/train" "$full_ram" 20
    grep -m1 -oP '\(\K[0-9]+(?=\))' "$full_ram" > "${full_ram}.hp" 2>/dev/null
    local _cf_maxhp; _cf_maxhp=$(cat "${full_ram}.hp" 2>/dev/null)
    [ -n "$_cf_maxhp" ] && printf "  ${GRAY_BLACK}Max HP: %-6d${COLOR_RESET}\n" "$_cf_maxhp"
    echo "$_cf_maxhp" > "$full_ram"

    # ── Disable graphics for clean HTML ───────────────────────────
    _fetch "/settings/graphics/0" "$src_ram" 10

    # ── Fetch lobby ───────────────────────────────────────────────
    _cl_fetch "/coliseum"

    # ── Handle leftover end_fight ──────────────────────────────────
    if grep -q -o '?end_fight' "$src_ram"; then
        _cl_parse_end_fight
        _cl_fetch "/coliseum"
    fi

    # ── Find enterFight ────────────────────────────────────────────
    local go_stop
    go_stop=$(grep -m1 -oP '/coliseum/enterFight/\?r=[0-9]+' "$src_ram")

    if [ -n "$go_stop" ]; then
        printf '%b\n' "  ${GOLD_BLACK}🤺 Entrando na batalha...${COLOR_RESET}"
        _cl_fetch "$go_stop"

        # ── Wait for battle (max 90s) ──────────────────────────────
        local wait_start; wait_start=$(date +%s)
        until grep -q -o 'coliseum/dodge/' "$src_ram" || \
              [ $(( $(date +%s) - wait_start )) -gt 90 ]; do
            local _wt=$(( $(date +%s) - wait_start ))
            local _qstat
            _qstat=$(w3m -dump -T text/html "$src_ram" 2>/dev/null | \
                     grep -m1 -oE 'na fila: [0-9]+ de [0-9]+')
            printf "\r\033[K  ${GOLD_BLACK}⏳ Queue: %-20s [%02ds]${COLOR_RESET}" "${_qstat:-waiting...}" "$_wt"
            local access_link
            access_link=$(grep -m1 -oP '/coliseum(/[A-Za-z]+/\?r=[0-9]+|/)' "$src_ram" | \
                          grep -v 'dodge\|enter')
            [ -z "$access_link" ] && access_link="/coliseum"
            _cl_fetch "$access_link"
            sleep 3s
        done
        printf '\n'

        # ── Battle started ─────────────────────────────────────────
        _cl_battle_start=$(date +%s)

        # ── cl_access: extract state + display ────────────────────
        cl_access() {
            # Single parse call
            _parse_battle_state "$src_ram"

            RHP=$(awk   -v u="$USH"  -v r="$RPER" 'BEGIN{printf"%.0f",u*r/100+u}')
            HLHP=$(awk  -v m="$(cat "$full_ram")" -v h="$HPER" 'BEGIN{printf"%.0f",m*h/100}')

            _cl_track_hp
            [ -n "$USER" ] && _cl_opponent="$USER"

            if [ -z "$_cl_team" ]; then
                local pl; pl=$(w3m -dump -T text/html "$src_ram" 2>/dev/null | head -n 5)
                echo "$pl" | grep -q '\[1\]' && _cl_team="1"
                echo "$pl" | grep -q '\[0\]' && _cl_team="0"
            fi

            if grep -q -o '/dodge/' "$src_ram"; then
                _cl_display_battle
            else
                if grep -q -o '?end_fight=true' "$src_ram"; then
                    [ $(( $(date +%s) - _cl_battle_start )) -lt 300 ] && _cl_parse_end_fight && _cl_display_post_match
                else
                    BREAK_LOOP=1
                    echo_t "Battle over." "${RED_BLACK}" "${COLOR_RESET}"
                    sleep 2s
                fi
            fi
        }

        # ── Init cooldown timers ───────────────────────────────────
        last_heal=$((   $(date +%s) - 90 ))
        last_dodge=$((  $(date +%s) - 20 ))
        last_atk=$((    $(date +%s) - ${LA%%.*} ))

        cl_access
        local OLDHP=$USH
        BREAK_LOOP=""

        printf "  ${GREEN_BLACK}⚔️  BATTLE vs %-16s [Team %d]${COLOR_RESET}\n" "${_cl_opponent:-?}" "${_cl_team:-0}"

        # Reset LA for this battle
        LA="${_cfg_la:-4.5}"
        _cl_la_adjusted=0; _cl_atk_successes=0
        _cl_detect_opponent; _cl_adapt_rper

        # ── Main battle loop ───────────────────────────────────────
        until [[ -n "$BREAK_LOOP" ]]; do
            local now; now=$(date +%s)
            time_since_last_heal=$((  now - last_heal  ))
            time_since_last_dodge=$(( now - last_dodge ))
            time_since_last_atk=$((   now - last_atk   ))
            _cl_loop_count=$(( _cl_loop_count + 1 ))

            # Save battle history every 3 loops
            if [ $(( _cl_loop_count % 3 )) -eq 0 ]; then
                local _pr; _pr=$(w3m -dump -T text/html "$src_ram" 2>/dev/null)
                {
                    printf '[Loop %d] %(%H:%M:%S)T\n' "$_cl_loop_count" -1
                    echo "$_pr" | sed -n '/^Os participantes:/,/^A batalha já começou!/p' | \
                        grep -v '^$\|Os participantes:\|A batalha já começou'
                } >> "$_cl_battle_history"
            fi

            # Adaptive HPER every 5 loops
            [ $(( _cl_loop_count % 5 )) -eq 0 ] && _cl_adapt_hper

            # ── Priority 0: STONE ──────────────────────────────────
            if [ "${_cl_stone_used:-0}" -eq 0 ] && [ -n "$STONE" ] && \
               ! grep -q "b_grey[^>]*href='/coliseum/stone" "$src_ram"; then
                _cl_fetch "$STONE"; cl_access; _cl_stone_used=1; last_atk=$now

            # ── Priority 1: HEAL ───────────────────────────────────
            elif awk -v u="$USH" -v h="$HLHP" 'BEGIN{exit!(u+0<h+0)}' && \
                 [[ $time_since_last_heal -gt 90 && $time_since_last_heal -lt 300 ]] && [ -n "$HEAL" ]; then
                _cl_fetch "$HEAL"; cl_access
                last_heal=$now; last_atk=$now
                _cl_match_heals=$(( _cl_match_heals + 1 ))

            # ── Priority 1.5: GRASS ────────────────────────────────
            elif [ "${_cl_grass_used:-0}" -eq 0 ] && [ -n "$GRASS" ] && \
                 ! grep -q "b_grey[^>]*href='/coliseum/grass" "$src_ram" && \
                 awk -v u="$USH" -v m="$(cat "$full_ram" 2>/dev/null)" 'BEGIN{exit!(m>0&&u+0<=m*0.50)}'; then
                _cl_fetch "$GRASS"; cl_access; _cl_grass_used=1; last_atk=$now

            # ── Priority 2: DODGE ──────────────────────────────────
            elif ! grep -q -o 'txt smpl grey' "$src_ram" && \
                 [[ $time_since_last_dodge -gt 20 && $time_since_last_dodge -lt 300 ]] && \
                 awk -v u="$USH" -v o="$OLDHP" 'BEGIN{exit!(u+0<o+0)}' && [ -n "$DODGE" ]; then
                _cl_fetch "$DODGE"; cl_access
                OLDHP=$USH; last_dodge=$now; last_atk=$now
                _cl_match_dodges=$(( _cl_match_dodges + 1 ))

            # ── Priority 3: RANDOM ATTACK ──────────────────────────
            elif awk -v t="$time_since_last_atk" -v la="${LA%%.*}" 'BEGIN{exit!(t+0>=la+0)}' && \
                 ! grep -q -o 'txt smpl grey' "$src_ram" && \
                 awk -v r="$RHP" -v e="$ENH" 'BEGIN{exit!(e+0>r+0)}' && [ -n "$ATKRND" ]; then
                local _prev_enh="$ENH"
                _cl_fetch "$ATKRND"; cl_access; last_atk=$now
                _cl_match_atkrnds=$(( _cl_match_atkrnds + 1 ))

            # ── Priority 4: REGULAR ATTACK ─────────────────────────
            elif awk -v t="$time_since_last_atk" -v la="${LA%%.*}" 'BEGIN{exit!(t+0>=la+0)}' && [ -n "$ATK" ]; then
                local _prev_enh="$ENH" _prev_atk="$ATK"
                _cl_fetch "$ATK"; cl_access

                if ! _cl_check_attack_success "$_prev_enh" "$ENH"; then
                    _cl_atk_failures=$(( _cl_atk_failures + 1 ))
                    _cl_atk_successes=0
                    LA=$(awk -v la="$LA" 'BEGIN{printf"%.1f",la+0.2}')
                    _cl_la_adjusted=1
                else
                    _cl_atk_successes=$(( _cl_atk_successes + 1 ))
                    _cl_match_atks=$(( _cl_match_atks + 1 ))
                    if [ "$_cl_atk_successes" -ge 10 ] && [ "$_cl_la_adjusted" -eq 1 ]; then
                        awk -v la="$LA" 'BEGIN{exit!(la>3.0)}' && \
                            LA=$(awk -v la="$LA" 'BEGIN{printf"%.1f",la-0.1}')
                        _cl_atk_successes=0
                    fi
                fi
                last_atk=$now

            # ── Priority 5: REFRESH ────────────────────────────────
            else
                _cl_fetch "/coliseum"; cl_access; sleep 1s
            fi
        done

        # ── Post-battle: stats + AI log ────────────────────────────
        local _battle_dur=$(( $(date +%s) - _cl_battle_start ))

        cl_total_matches=$(( cl_total_matches + 1 ))
        if [ "$_cl_result" = "win" ]; then
            cl_wins=$(( cl_wins + 1 ))
            cl_current_win_streak=$(( cl_current_win_streak + 1 ))
            [ "$cl_current_win_streak" -gt "$cl_longest_win_streak" ] && \
                cl_longest_win_streak=$cl_current_win_streak
        elif [ "$_cl_result" = "loss" ]; then
            cl_losses=$(( cl_losses + 1 ))
            cl_current_win_streak=0
        fi
        cl_total_kills=$(( cl_total_kills + _cl_match_kills ))
        cl_total_deaths=$(( cl_total_deaths + _cl_match_deaths ))
        cl_heals_used=$(( cl_heals_used + _cl_match_heals ))
        cl_dodges_used=$(( cl_dodges_used + _cl_match_dodges ))
        cl_attacks_sent=$(( cl_attacks_sent + _cl_match_atks ))
        cl_random_attacks_sent=$(( cl_random_attacks_sent + _cl_match_atkrnds ))
        cl_total_battle_seconds=$(( cl_total_battle_seconds + _battle_dur ))

        _cl_stats_save
        _cl_history_append

        # ── AI event log (feeds orchestrator) ─────────────────────
        _log_battle_event "coliseum" "$_cl_result" "$_battle_dur" \
            "$LA" "$HPER" "$_cl_match_atks" "$_cl_match_heals" "$_cl_match_kills"

        # ── Cleanup ────────────────────────────────────────────────
        rm -f "$src_ram" "$full_ram" "${full_ram}.hp" "$_cl_battle_history"
        rm -rf "$tmp_ram"
        unset last_heal last_dodge last_atk USH ENH USER ATK ATKRND DODGE HEAL STONE GRASS BREAK_LOOP cl_access
        unset _cl_match_heals _cl_match_dodges _cl_match_atks _cl_match_atkrnds
        unset _cl_match_kills _cl_match_deaths _cl_result _cl_opponent _cl_team
        unset _cl_battle_start _cl_atk_failures _cl_atk_successes _cl_la_adjusted
        unset _cl_hp_times _cl_hp_values _cl_hp_count _cl_opp_type _cl_loop_count
        unset _cl_stone_used _cl_grass_used
        func_unset

        awk -v s="$RUN" -v r="-cl" 'BEGIN{exit!(s!=r)}' && printf "\nYou can run ./twm/play.sh -cl\n"
        echo_t "The battle is over!" "${RED_BLACK}" "${COLOR_RESET}" "after" "⚔️\n"
    else
        echo_t "It was not possible to start the battle at this time." "${WHITEb_BLACK}" "${COLOR_RESET}"
    fi
}

# ============================================================================
# MODULE: START
# ============================================================================

coliseum_start() {
    [ "$FUNC_coliseum" = "n" ] && return

    if case $(date +%H:%M) in
        (09:2[4-9]|9:5[4-9]|10:1[0-4]|10:2[4-9]|10:5[4-9]|12:2[4-9]|13:5[4-9]|14:5[4-9]|15:5[4-9]|16:1[0-4]|16:2[4-9]|18:5[4-9]|20:5[4-9]|21:2[4-9]|21:5[4-9]|22:2[4-9])
            exit 1;;
        esac; then

        if echo "$RUN" | grep -q -E '[-]boot'; then
            (
                w3mc -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 \
                    -debug -dump_source "${URL}/quest/" \
                    -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
            ) </dev/null &>/dev/null &
            time_exit 20

            while grep -q -o -E '/coliseum/[?]quest_t[=]quest&quest_id[=]11&qz[=][a-z0-9]+' "$TMP"/SRC; do
                coliseum_fight
                (
                    w3mc -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 \
                        -debug -dump_source "${URL}/quest/" \
                        -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
                ) </dev/null &>/dev/null &
                time_exit 20
                local ENDQUEST
                ENDQUEST=$(grep -m1 -oP '/quest/end/11\?r=[A-Za-z0-9]+' "$TMP"/SRC)
                [ -n "$ENDQUEST" ] && _fetch "$ENDQUEST" "$TMP/SRC" 20
            done

        elif echo "$RUN" | grep -q -E '[-]cl'; then
            coliseum_fight
        fi
    else
        echo_t "Battle or event time..."
        sleep 5s
    fi
}
