# shellcheck disable=SC2148,SC2155,SC2034
# ============================================================================
# CLAN DMG v3.0 - TitansWarPro AI Engine
# Integrated: core/helpers.sh
# ============================================================================

source "$(dirname "${BASH_SOURCE[0]}")/core/helpers.sh" 2>/dev/null || true

_clandmg_load_config() {
    local la hper rper
    la=$(   _cfg_get "clandmg" "la_start" 2>/dev/null)
    hper=$( _cfg_get "clandmg" "hper"     2>/dev/null)
    rper=$( _cfg_get "clandmg" "rper"     2>/dev/null)
    LA="${la:-${CDG_LA:-4.0}}"
    HPER="${hper:-${CDG_HPER:-35}}"
    RPER="${rper:-${CDG_RPER:-5}}"
}

clandmg_fight() {
    local dir_ram; dir_ram=$(_ram_dir)
    src_ram=$(mktemp -p "$dir_ram" data.XXXXXX)
    full_ram=$(mktemp -p "$dir_ram" data.XXXXXX)
    tmp_ram=$(mktemp -d -t twmdir.XXXXXX)
    cp -r "$TMP"/* "$tmp_ram"
    cd "$tmp_ram" || exit

    _clandmg_load_config

    local _cd_battle_start _cd_result _cd_match_atks _cd_match_heals
    local _cd_match_dodges _cd_match_atkrnds _cd_match_kills
    local _cd_stone_used _cd_grass_used _cd_loop_count
    _cd_battle_start=$(date +%s)
    _cd_result=""; _cd_match_atks=0; _cd_match_heals=0
    _cd_match_dodges=0; _cd_match_atkrnds=0; _cd_match_kills=0
    _cd_stone_used=0; _cd_grass_used=0; _cd_loop_count=0; BREAK_LOOP=""

    printf "  ${GOLD_BLACK}\u2694\ufe0f  CLAN DMG  LA:%-5s  HPER:%-2d%%${COLOR_RESET}\n" "$LA" "$HPER"

    _fetch "/train" "$full_ram" 20
    grep -m1 -oP '\(\K[0-9]+(?=\))' "$full_ram" > "${full_ram}.hp" 2>/dev/null
    echo "$(cat "${full_ram}.hp" 2>/dev/null)" > "$full_ram"

    _fetch "/settings/graphics/0" "$src_ram" 10
    _fetch "/clandmg" "$src_ram" 17

    if grep -q -o '?end_fight' "$src_ram"; then
        _fetch "/clandmg/?end_fight=true" "$src_ram" 17
        _fetch "/clandmg" "$src_ram" 17
    fi

    local go_stop
    go_stop=$(grep -m1 -oP '/clandmg/enterFight/\?r=[0-9]+' "$src_ram")

    if [ -n "$go_stop" ]; then
        _fetch "$go_stop" "$src_ram" 17

        local wait_start; wait_start=$(date +%s)
        until grep -q -o 'clandmg/dodge/' "$src_ram" || [ $(( $(date +%s) - wait_start )) -gt 90 ]; do
            local al; al=$(grep -m1 -oP '/clandmg(/[A-Za-z]+/\?r=[0-9]+|/)' "$src_ram" | grep -v 'dodge\|enter')
            [ -z "$al" ] && al="/clandmg"
            _fetch "$al" "$src_ram" 17; sleep 3s
        done

        _cd_battle_start=$(date +%s)
        last_heal=$(( $(date +%s) - 90 ))
        last_dodge=$(( $(date +%s) - 20 ))
        last_atk=$(( $(date +%s) - ${LA%%.*} ))

        clandmg_access() {
            _parse_battle_state "$src_ram"
            RHP=$(awk -v u="$USH" -v r="$RPER" 'BEGIN{printf"%.0f",u*r/100+u}')
            HLHP=$(awk -v m="$(cat "$full_ram")" -v h="$HPER" 'BEGIN{printf"%.0f",m*h/100}')
            grep -q -o '/dodge/' "$src_ram" || BREAK_LOOP=1
        }
        clandmg_access
        local OLDHP=$USH

        until [[ -n "$BREAK_LOOP" ]]; do
            local now; now=$(date +%s)
            local tsh=$(( now - last_heal ))
            local tsd=$(( now - last_dodge ))
            local tsa=$(( now - last_atk ))
            _cd_loop_count=$(( _cd_loop_count + 1 ))

            if [ "${_cd_stone_used:-0}" -eq 0 ] && [ -n "$STONE" ] && \
               ! grep -q "b_grey[^>]*href='/clandmg/stone" "$src_ram"; then
                _fetch "$STONE" "$src_ram" 17; clandmg_access; _cd_stone_used=1; last_atk=$now

            elif awk -v u="$USH" -v h="$HLHP" 'BEGIN{exit!(u+0<h+0)}' && \
                 [[ $tsh -gt 90 && $tsh -lt 300 ]] && [ -n "$HEAL" ]; then
                _fetch "$HEAL" "$src_ram" 17; clandmg_access
                last_heal=$now; last_atk=$now; _cd_match_heals=$(( _cd_match_heals + 1 ))

            elif [ "${_cd_grass_used:-0}" -eq 0 ] && [ -n "$GRASS" ] && \
                 awk -v u="$USH" -v m="$(cat "$full_ram" 2>/dev/null)" 'BEGIN{exit!(m>0&&u+0<=m*0.50)}'; then
                _fetch "$GRASS" "$src_ram" 17; clandmg_access; _cd_grass_used=1; last_atk=$now

            elif [[ $tsd -gt 20 && $tsd -lt 300 ]] && \
                 awk -v u="$USH" -v o="$OLDHP" 'BEGIN{exit!(u+0<o+0)}' && [ -n "$DODGE" ]; then
                _fetch "$DODGE" "$src_ram" 17; clandmg_access
                OLDHP=$USH; last_dodge=$now; last_atk=$now; _cd_match_dodges=$(( _cd_match_dodges + 1 ))

            elif awk -v t="$tsa" -v la="${LA%%.*}" 'BEGIN{exit!(t+0>=la+0)}' && \
                 awk -v r="$RHP" -v e="$ENH" 'BEGIN{exit!(e+0>r+0)}' && [ -n "$ATKRND" ]; then
                _fetch "$ATKRND" "$src_ram" 17; clandmg_access
                last_atk=$now; _cd_match_atkrnds=$(( _cd_match_atkrnds + 1 ))

            elif awk -v t="$tsa" -v la="${LA%%.*}" 'BEGIN{exit!(t+0>=la+0)}' && [ -n "$ATK" ]; then
                _fetch "$ATK" "$src_ram" 17; clandmg_access
                last_atk=$now; _cd_match_atks=$(( _cd_match_atks + 1 ))

            else
                _fetch "/clandmg" "$src_ram" 17; clandmg_access; sleep 1s
            fi
        done

        local rendered; rendered=$(w3m -dump -T text/html "$src_ram" 2>/dev/null)
        echo "$rendered" | grep -qi -E 'vit|victory' && _cd_result="win" || _cd_result="loss"

        local _cd_dur=$(( $(date +%s) - _cd_battle_start ))
        _log_battle_event "clandmg" "$_cd_result" "$_cd_dur" \
            "$LA" "$HPER" "$_cd_match_atks" "$_cd_match_heals" "$_cd_match_kills"

        rm -f "$src_ram" "$full_ram" "${full_ram}.hp"; rm -rf "$tmp_ram"
        unset clandmg_access last_heal last_dodge last_atk BREAK_LOOP
        unset USH ENH ATK ATKRND DODGE HEAL STONE GRASS
    else
        echo_t "Clan DMG not available." "${WHITEb_BLACK}" "${COLOR_RESET}"
    fi
}

clandmg_start() {
    [ "$FUNC_clandmg" = "n" ] && return
    echo "$RUN" | grep -q -E '[-]cdmg' && clandmg_fight
}
