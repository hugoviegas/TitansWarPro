# shellcheck disable=SC2148,SC2155,SC2034
# ============================================================================
# FLAG FIGHT v3.0 - TitansWarPro AI Engine
# Integrated: core/helpers.sh
# ============================================================================

source "$(dirname "${BASH_SOURCE[0]}")/core/helpers.sh" 2>/dev/null || true

_flagfight_load_config() {
    local la hper rper
    la=$(   _cfg_get "flagfight" "la_start" 2>/dev/null)
    hper=$( _cfg_get "flagfight" "hper"     2>/dev/null)
    rper=$( _cfg_get "flagfight" "rper"     2>/dev/null)
    LA="${la:-${FF_LA:-5.0}}"
    HPER="${hper:-${FF_HPER:-40}}"
    RPER="${rper:-${FF_RPER:-5}}"
}

flagfight_fight() {
    local dir_ram; dir_ram=$(_ram_dir)
    src_ram=$(mktemp -p "$dir_ram" data.XXXXXX)
    full_ram=$(mktemp -p "$dir_ram" data.XXXXXX)
    tmp_ram=$(mktemp -d -t twmdir.XXXXXX)
    cp -r "$TMP"/* "$tmp_ram"
    cd "$tmp_ram" || exit

    _flagfight_load_config

    local _ff_battle_start _ff_result _ff_match_atks _ff_match_heals
    local _ff_match_dodges _ff_match_atkrnds _ff_match_kills
    local _ff_loop_count
    _ff_battle_start=$(date +%s)
    _ff_result=""; _ff_match_atks=0; _ff_match_heals=0
    _ff_match_dodges=0; _ff_match_atkrnds=0; _ff_match_kills=0
    _ff_loop_count=0; BREAK_LOOP=""

    printf "  ${GOLD_BLACK}\u2691\ufe0f  FLAG FIGHT  LA:%-5s  HPER:%-2d%%${COLOR_RESET}\n" "$LA" "$HPER"

    _fetch "/train" "$full_ram" 20
    grep -m1 -oP '\(\K[0-9]+(?=\))' "$full_ram" > "${full_ram}.hp" 2>/dev/null
    echo "$(cat "${full_ram}.hp" 2>/dev/null)" > "$full_ram"

    _fetch "/settings/graphics/0" "$src_ram" 10
    _fetch "/flagfight" "$src_ram" 17

    if grep -q -o '?end_fight' "$src_ram"; then
        _fetch "/flagfight/?end_fight=true" "$src_ram" 17
        _fetch "/flagfight" "$src_ram" 17
    fi

    local go_stop
    go_stop=$(grep -m1 -oP '/flagfight/enterFight/\?r=[0-9]+' "$src_ram")

    if [ -n "$go_stop" ]; then
        _fetch "$go_stop" "$src_ram" 17

        local wait_start; wait_start=$(date +%s)
        until grep -q -o 'flagfight/dodge/' "$src_ram" || [ $(( $(date +%s) - wait_start )) -gt 90 ]; do
            local al; al=$(grep -m1 -oP '/flagfight(/[A-Za-z]+/\?r=[0-9]+|/)' "$src_ram" | grep -v 'dodge\|enter')
            [ -z "$al" ] && al="/flagfight"
            _fetch "$al" "$src_ram" 17; sleep 3s
        done

        _ff_battle_start=$(date +%s)
        last_heal=$(( $(date +%s) - 90 ))
        last_dodge=$(( $(date +%s) - 20 ))
        last_atk=$(( $(date +%s) - ${LA%%.*} ))

        flagfight_access() {
            _parse_battle_state "$src_ram"
            RHP=$(awk -v u="$USH" -v r="$RPER" 'BEGIN{printf"%.0f",u*r/100+u}')
            HLHP=$(awk -v m="$(cat "$full_ram")" -v h="$HPER" 'BEGIN{printf"%.0f",m*h/100}')
            grep -q -o '/dodge/' "$src_ram" || BREAK_LOOP=1
        }
        flagfight_access
        local OLDHP=$USH

        until [[ -n "$BREAK_LOOP" ]]; do
            local now; now=$(date +%s)
            local tsh=$(( now - last_heal ))
            local tsd=$(( now - last_dodge ))
            local tsa=$(( now - last_atk ))
            _ff_loop_count=$(( _ff_loop_count + 1 ))

            if awk -v u="$USH" -v h="$HLHP" 'BEGIN{exit!(u+0<h+0)}' && \
               [[ $tsh -gt 90 && $tsh -lt 300 ]] && [ -n "$HEAL" ]; then
                _fetch "$HEAL" "$src_ram" 17; flagfight_access
                last_heal=$now; last_atk=$now; _ff_match_heals=$(( _ff_match_heals + 1 ))

            elif [[ $tsd -gt 20 && $tsd -lt 300 ]] && \
                 awk -v u="$USH" -v o="$OLDHP" 'BEGIN{exit!(u+0<o+0)}' && [ -n "$DODGE" ]; then
                _fetch "$DODGE" "$src_ram" 17; flagfight_access
                OLDHP=$USH; last_dodge=$now; last_atk=$now; _ff_match_dodges=$(( _ff_match_dodges + 1 ))

            elif awk -v t="$tsa" -v la="${LA%%.*}" 'BEGIN{exit!(t+0>=la+0)}' && \
                 awk -v r="$RHP" -v e="$ENH" 'BEGIN{exit!(e+0>r+0)}' && [ -n "$ATKRND" ]; then
                _fetch "$ATKRND" "$src_ram" 17; flagfight_access
                last_atk=$now; _ff_match_atkrnds=$(( _ff_match_atkrnds + 1 ))

            elif awk -v t="$tsa" -v la="${LA%%.*}" 'BEGIN{exit!(t+0>=la+0)}' && [ -n "$ATK" ]; then
                _fetch "$ATK" "$src_ram" 17; flagfight_access
                last_atk=$now; _ff_match_atks=$(( _ff_match_atks + 1 ))

            else
                _fetch "/flagfight" "$src_ram" 17; flagfight_access; sleep 1s
            fi
        done

        local rendered; rendered=$(w3m -dump -T text/html "$src_ram" 2>/dev/null)
        echo "$rendered" | grep -qi -E 'vit|victory' && _ff_result="win" || _ff_result="loss"

        local _ff_dur=$(( $(date +%s) - _ff_battle_start ))
        _log_battle_event "flagfight" "$_ff_result" "$_ff_dur" \
            "$LA" "$HPER" "$_ff_match_atks" "$_ff_match_heals" "$_ff_match_kills"

        rm -f "$src_ram" "$full_ram" "${full_ram}.hp"; rm -rf "$tmp_ram"
        unset flagfight_access last_heal last_dodge last_atk BREAK_LOOP
        unset USH ENH ATK ATKRND DODGE HEAL STONE GRASS
    else
        echo_t "Flag Fight not available." "${WHITEb_BLACK}" "${COLOR_RESET}"
    fi
}

flagfight_start() {
    [ "$FUNC_flagfight" = "n" ] && return
    echo "$RUN" | grep -q -E '[-]ff' && flagfight_fight
}
