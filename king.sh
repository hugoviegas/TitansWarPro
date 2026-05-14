# shellcheck disable=SC2148,SC2155,SC2034
# ============================================================================
# KING BATTLE v3.0 - TitansWarPro AI Engine
# Integrated: core/helpers.sh (_fetch, _parse_battle_state, _log_battle_event)
# ============================================================================

source "$(dirname "${BASH_SOURCE[0]}")/core/helpers.sh" 2>/dev/null || true

# ============================================================================
# MODULE: CONFIG
# ============================================================================

_king_load_config() {
    local la hper rper
    la=$(   _cfg_get "king" "la_start" 2>/dev/null)
    hper=$( _cfg_get "king" "hper"     2>/dev/null)
    rper=$( _cfg_get "king" "rper"     2>/dev/null)
    LA="${la:-${KING_LA:-5.0}}"
    HPER="${hper:-${KING_HPER:-45}}"
    RPER="${rper:-${KING_RPER:-10}}"
}

# ============================================================================
# MODULE: FIGHT
# ============================================================================

king_fight() {
    local dir_ram; dir_ram=$(_ram_dir)
    mkdir -p "$dir_ram"
    src_ram=$(mktemp -p "$dir_ram" data.XXXXXX)
    full_ram=$(mktemp -p "$dir_ram" data.XXXXXX)
    tmp_ram=$(mktemp -d -t twmdir.XXXXXX)
    cp -r "$TMP"/* "$tmp_ram"
    cd "$tmp_ram" || exit

    _king_load_config

    local _k_battle_start _k_result _k_match_atks _k_match_heals
    local _k_match_dodges _k_match_atkrnds _k_match_kills _k_match_deaths
    local _k_stone_used _k_grass_used _k_loop_count
    _k_battle_start=$(date +%s)
    _k_result=""; _k_match_atks=0; _k_match_heals=0
    _k_match_dodges=0; _k_match_atkrnds=0; _k_match_kills=0; _k_match_deaths=0
    _k_stone_used=0; _k_grass_used=0; _k_loop_count=0
    BREAK_LOOP=""

    printf "  ${GOLD_BLACK}\u265a  KING BATTLE  LA:%-5s  HPER:%-2d%%  RPER:%-2d%%${COLOR_RESET}\n" "$LA" "$HPER" "$RPER"

    # Get max HP
    _fetch "/train" "$full_ram" 20
    grep -m1 -oP '\(\K[0-9]+(?=\))' "$full_ram" > "${full_ram}.hp" 2>/dev/null
    echo "$(cat "${full_ram}.hp" 2>/dev/null)" > "$full_ram"

    _fetch "/settings/graphics/0" "$src_ram" 10
    _fetch "/king" "$src_ram" 17

    if grep -q -o '?end_fight' "$src_ram"; then
        _fetch "/king/?end_fight=true" "$src_ram" 17
        _fetch "/king" "$src_ram" 17
    fi

    local go_stop
    go_stop=$(grep -m1 -oP '/king/enterFight/\?r=[0-9]+' "$src_ram")

    if [ -n "$go_stop" ]; then
        _fetch "$go_stop" "$src_ram" 17

        local wait_start; wait_start=$(date +%s)
        until grep -q -o 'king/dodge/' "$src_ram" || [ $(( $(date +%s) - wait_start )) -gt 90 ]; do
            local access_link
            access_link=$(grep -m1 -oP '/king(/[A-Za-z]+/\?r=[0-9]+|/)' "$src_ram" | grep -v 'dodge\|enter')
            [ -z "$access_link" ] && access_link="/king"
            _fetch "$access_link" "$src_ram" 17
            sleep 3s
        done

        _k_battle_start=$(date +%s)
        last_heal=$(( $(date +%s) - 90 ))
        last_dodge=$(( $(date +%s) - 20 ))
        last_atk=$(( $(date +%s) - ${LA%%.*} ))

        # cl_access equivalent
        king_access() {
            _parse_battle_state "$src_ram"
            RHP=$(awk -v u="$USH" -v r="$RPER" 'BEGIN{printf"%.0f",u*r/100+u}')
            HLHP=$(awk -v m="$(cat "$full_ram")" -v h="$HPER" 'BEGIN{printf"%.0f",m*h/100}')
            if ! grep -q -o '/dodge/' "$src_ram"; then
                BREAK_LOOP=1
            fi
        }

        king_access
        local OLDHP=$USH

        until [[ -n "$BREAK_LOOP" ]]; do
            local now; now=$(date +%s)
            local time_since_last_heal=$((  now - last_heal  ))
            local time_since_last_dodge=$(( now - last_dodge ))
            local time_since_last_atk=$((   now - last_atk   ))
            _k_loop_count=$(( _k_loop_count + 1 ))

            # STONE
            if [ "${_k_stone_used:-0}" -eq 0 ] && [ -n "$STONE" ] && \
               ! grep -q "b_grey[^>]*href='/king/stone" "$src_ram"; then
                _fetch "$STONE" "$src_ram" 17; king_access; _k_stone_used=1; last_atk=$now

            # HEAL
            elif awk -v u="$USH" -v h="$HLHP" 'BEGIN{exit!(u+0<h+0)}' && \
                 [[ $time_since_last_heal -gt 90 && $time_since_last_heal -lt 300 ]] && [ -n "$HEAL" ]; then
                _fetch "$HEAL" "$src_ram" 17; king_access
                last_heal=$now; last_atk=$now; _k_match_heals=$(( _k_match_heals + 1 ))

            # GRASS
            elif [ "${_k_grass_used:-0}" -eq 0 ] && [ -n "$GRASS" ] && \
                 awk -v u="$USH" -v m="$(cat "$full_ram" 2>/dev/null)" 'BEGIN{exit!(m>0&&u+0<=m*0.50)}'; then
                _fetch "$GRASS" "$src_ram" 17; king_access; _k_grass_used=1; last_atk=$now

            # DODGE
            elif [[ $time_since_last_dodge -gt 20 && $time_since_last_dodge -lt 300 ]] && \
                 awk -v u="$USH" -v o="$OLDHP" 'BEGIN{exit!(u+0<o+0)}' && [ -n "$DODGE" ]; then
                _fetch "$DODGE" "$src_ram" 17; king_access
                OLDHP=$USH; last_dodge=$now; last_atk=$now; _k_match_dodges=$(( _k_match_dodges + 1 ))

            # RANDOM ATK
            elif awk -v t="$time_since_last_atk" -v la="${LA%%.*}" 'BEGIN{exit!(t+0>=la+0)}' && \
                 awk -v r="$RHP" -v e="$ENH" 'BEGIN{exit!(e+0>r+0)}' && [ -n "$ATKRND" ]; then
                _fetch "$ATKRND" "$src_ram" 17; king_access
                last_atk=$now; _k_match_atkrnds=$(( _k_match_atkrnds + 1 ))

            # ATK
            elif awk -v t="$time_since_last_atk" -v la="${LA%%.*}" 'BEGIN{exit!(t+0>=la+0)}' && [ -n "$ATK" ]; then
                _fetch "$ATK" "$src_ram" 17; king_access
                last_atk=$now; _k_match_atks=$(( _k_match_atks + 1 ))

            else
                _fetch "/king" "$src_ram" 17; king_access; sleep 1s
            fi
        done

        # Parse result
        local rendered; rendered=$(w3m -dump -T text/html "$src_ram" 2>/dev/null)
        if echo "$rendered" | grep -qi -E 'vit[o\u00f3]ria|victory'; then
            _k_result="win"
        elif echo "$rendered" | grep -qi -E 'derrota|defeat'; then
            _k_result="loss"
        else
            _k_result="unknown"
        fi

        local _k_dur=$(( $(date +%s) - _k_battle_start ))
        _log_battle_event "king" "$_k_result" "$_k_dur" \
            "$LA" "$HPER" "$_k_match_atks" "$_k_match_heals" "$_k_match_kills"

        rm -f "$src_ram" "$full_ram" "${full_ram}.hp"
        rm -rf "$tmp_ram"
        unset king_access last_heal last_dodge last_atk BREAK_LOOP
        unset USH ENH ATK ATKRND DODGE HEAL STONE GRASS
    else
        echo_t "King battle not available." "${WHITEb_BLACK}" "${COLOR_RESET}"
    fi
}

# ============================================================================
# MODULE: START
# ============================================================================

king_start() {
    [ "$FUNC_king" = "n" ] && return
    if echo "$RUN" | grep -q -E '[-]kg'; then
        king_fight
    fi
}
