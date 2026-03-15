# shellcheck disable=SC2155,SC2034,SC2148

# ============================================================================
# KING OF THE IMMORTALS BATTLE SYSTEM v2.0 - TitansWarPro
# ============================================================================
# 2-Phase battle:
#   Phase 1: Attack the King (KINGATK) until dead
#            - Attack while King HP% > 10%
#            - Pause at 10%, refresh every 1s watching HP%
#            - Resume attack when King HP% <= 2%
#            - "Você assassinou o Rei dos imortais" = king killed
#   Phase 2: PvP (ATK/ATKRND) using coliseum logic
#            - Adaptive LA, HPER, RPER, alliance, display
# ============================================================================

# ── Helper: w3m fetch shorthand (king-specific) ─────────────────────────────
_kg_fetch() {
    local url_path="$1"
    (
        w3mc -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 \
            -debug -dump_source "${URL}${url_path}" \
            -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$src_ram" 2>/dev/null
    ) &
    time_exit 17
}

# ============================================================================
# KING DEBUG - Full battle with logging + 2-phase strategy
# ============================================================================

king_debug() {
    local debug_dir="${ACCOUNT_LOGS:-$TMP}"
    local debug_ts
    printf -v debug_ts '%(%Y%m%d_%H%M%S)T' -1
    local debug_file="${debug_dir}/king_debug_${debug_ts}.log"

    local dir_ram
    if [ -d "/dev/shm" ]; then dir_ram="/dev/shm/"; else dir_ram="$PREFIX/tmp/"; fi
    mkdir -p "$dir_ram"
    local src_ram
    src_ram=$(mktemp -p "$dir_ram" kingdbg.XXXXXX)
    local full_ram
    full_ram=$(mktemp -p "$dir_ram" kingdbg.XXXXXX)
    local tmp_ram
    tmp_ram=$(mktemp -d -t twmkdbg.XXXXXX)
    local _kd_battle_history
    _kd_battle_history=$(mktemp -p "$dir_ram" history.XXXXXX)
    cp -r "$TMP"/* "$tmp_ram" 2>/dev/null
    cd "$tmp_ram" || return 1

    # Load config with defaults
    local LA="${KING_LA:-4}"
    local HPER="${KING_HPER:-38}"
    local RPER="${KING_RPER:-5}"

    # ── Helper: log a page state to debug file ───────────────────────────
    _kd_page() {
        local label="$1"
        {
            printf '\n============================================================\n'
            printf '=  %s\n' "$label"
            printf '============================================================\n'
            printf 'Timestamp: %(%Y-%m-%d %H:%M:%S)T\n' -1
            printf '\n--- W3M RENDERED DUMP ---\n'
            w3m -dump -T text/html "$src_ram" 2>/dev/null
            printf '\n--- ACTION LINKS ---\n'
            printf 'ATK:     %s\n' "$(grep -o -E '/king/attack/[?]r[=][0-9]+' "$src_ram" 2>/dev/null | head -1)"
            printf 'KINGATK: %s\n' "$(grep -o -E '/king/kingatk/[?]r[=][0-9]+' "$src_ram" 2>/dev/null)"
            printf 'ATKRND:  %s\n' "$(grep -o -E '/king/at[a-z]{0,3}k[a-z]{3,6}/[?]r[=][0-9]+' "$src_ram" 2>/dev/null)"
            printf 'DODGE:   %s\n' "$(grep -o -E '/king/dodge/[?]r[=][0-9]+' "$src_ram" 2>/dev/null)"
            printf 'STONE:   %s\n' "$(grep -o -E '/king/stone/[?]r[=][0-9]+' "$src_ram" 2>/dev/null)"
            printf 'HEAL:    %s\n' "$(grep -o -E '/king/heal/[?]r[=][0-9]+' "$src_ram" 2>/dev/null)"
            printf 'UNRIP:   %s\n' "$(grep -o -E '/king/unrip/[^A-Za-z0-9_]r[^A-Za-z0-9_][0-9]+' "$src_ram" 2>/dev/null)"
            printf '\n--- HP VALUES ---\n'
            printf 'Player HP: %s\n' "$(grep -o -E '(hp)[^A-Za-z0-9]{1,4}[0-9]{2,5}' "$src_ram" 2>/dev/null | grep -o -E '[0-9]{2,5}' | head -1)"
            printf 'King/Enemy HP%%: %s\n' "$(grep -o -E '(nbsp)[^A-Za-z0-9]{1,2}[0-9]{1,6}' "$src_ram" 2>/dev/null | sed -n 's,nbsp[;],,;s, ,,;1p')"
            printf '\n--- MARKERS ---\n'
            printf 'dodge:%s  unrip:%s  grey:%s  rip:%s  kingatk:%s\n' \
                "$(grep -c '/dodge/' "$src_ram" 2>/dev/null)" \
                "$(grep -c '/king/unrip/' "$src_ram" 2>/dev/null)" \
                "$(grep -c 'txt smpl grey' "$src_ram" 2>/dev/null)" \
                "$(grep -c '\[rip\]' "$src_ram" 2>/dev/null)" \
                "$(grep -c 'king/kingatk/' "$src_ram" 2>/dev/null)"
            printf '\n--- KEYWORD SEARCH ---\n'
            w3m -dump -T text/html "$src_ram" 2>/dev/null | \
                grep -i -E 'vit[oó]ria|victory|defeat|derrota|assassinou.*[Rr]ei|killed.*[Kk]ing' 2>/dev/null || true
        } >> "$debug_file"
    }

    # ── Helper: log a battle action ──────────────────────────────────────
    _kd_action() {
        local action_label="$1" ush_before="$2" enh_before="$3" la_val="$4" ush_after="$5" enh_after="$6"
        local ts
        printf -v ts '%(%H:%M:%S)T' -1
        {
            printf '[%s] #%d %s | %s\n' "$ts" "$_kd_loop" "$_kd_phase_label" "$action_label"
            printf '       HP: %s->%s  ENH%%: %s->%s  LA:%ss  HPER:%s%%  RPER:%s%%\n' \
                "$ush_before" "${ush_after:--}" "$enh_before" "${enh_after:--}" \
                "$la_val" "$HPER" "$RPER"
        } >> "$debug_file"
    }

    # ── Helper: extract current page data ────────────────────────────────
    local _kd_USH _kd_ENH _kd_ATK _kd_KINGATK _kd_ATKRND
    local _kd_DODGE _kd_STONE _kd_HEAL _kd_UNRIP _kd_RHP _kd_HLHP _kd_USER
    _kd_extract() {
        _kd_USH=$(grep -o -E '(hp)[^A-Za-z0-9]{1,4}[0-9]{2,5}' "$src_ram" | grep -o -E '[0-9]{2,5}' | sed 's, ,,g' | head -1)
        _kd_ENH=$(grep -o -E '(nbsp)[^A-Za-z0-9]{1,2}[0-9]{1,6}' "$src_ram" | sed -n 's,nbsp[;],,;s, ,,;1p')
        _kd_ATK=$(grep -o -E '/king/attack/[?]r[=][0-9]+' "$src_ram" | head -1)
        _kd_KINGATK=$(grep -o -E '/king/kingatk/[?]r[=][0-9]+' "$src_ram" | head -1)
        _kd_ATKRND=$(grep -o -E '/king/at[a-z]{0,3}k[a-z]{3,6}/[?]r[=][0-9]+' "$src_ram")
        _kd_DODGE=$(grep -o -E '/king/dodge/[?]r[=][0-9]+' "$src_ram")
        _kd_STONE=$(grep -o -E '/king/stone/[?]r[=][0-9]+' "$src_ram")
        _kd_HEAL=$(grep -o -E '/king/heal/[?]r[=][0-9]+' "$src_ram")
        _kd_UNRIP=$(grep -o -E '/king/unrip/[?]r[=][1-9][0-9]+' "$src_ram" | head -1)
        _kd_USER=$(grep -o -E '([[:upper:]][[:lower:]]{0,15}( [[:upper:]][[:lower:]]{0,13})?)[[:space:]][^[:alnum:][:space:]]' "$src_ram" | sed -n 's,<[^>]*>,,g; s, ,_,;2p')
        # Recalculate thresholds (refresh on each extract to handle HP changes)
        if [ -n "${_kd_USH:-}" ]; then
            _kd_RHP=$(awk -v ush="$_kd_USH" -v rper="$RPER" 'BEGIN { printf "%.0f", ush * (1 + rper / 100) }')
            _kd_HLHP=$(awk -v ush="${_kd_maxhp:-1}" -v hper="$HPER" 'BEGIN { printf "%.0f", ush * hper / 100 }')
        fi
        [ -n "$_kd_USER" ] && _kd_opponent="$_kd_USER"
    }

    # ── Write debug file header ──────────────────────────────────────────
    {
        printf 'King Debug Log - %(%Y-%m-%d %H:%M:%S)T\n' -1
        printf 'Server: %s  Account: %s\n' "$URL" "${ACCOUNT_ID:-unknown}"
        printf '\n--- CONFIG ---\n'
        printf 'LA=%ss  HPER=%s%%  RPER=%s%%\n' "$LA" "$HPER" "$RPER"
    } > "$debug_file"

    # ── Terminal pre-battle panel ────────────────────────────────────────
    printf "\n  ${GOLD_BLACK}╔══════════════════════════════════════╗${COLOR_RESET}\n"
    printf "  ${GOLD_BLACK}║     KING  DEBUG  MODE  👑             ║${COLOR_RESET}\n"
    printf "  ${GOLD_BLACK}╠══════════════════════════════════════╣${COLOR_RESET}\n"
    printf "  ${GOLD_BLACK}║ LA: %-5s  HPER: %-3d%%  RPER: %-3d%%      ║${COLOR_RESET}\n" "$LA" "$HPER" "$RPER"
    printf "  ${GOLD_BLACK}╚══════════════════════════════════════╝${COLOR_RESET}\n"

    # ── Get max HP from /train ───────────────────────────────────────────
    (
        w3mc -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 \
            -debug -dump_source "$URL/train" \
            -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" | \
            grep -o -E '\(([0-9]+)\)' | sed 's/[()]//g' >"$full_ram"
    ) &
    time_exit 20
    local _kd_maxhp
    _kd_maxhp=$(cat "$full_ram" 2>/dev/null)
    [ -z "$_kd_maxhp" ] && _kd_maxhp=$(cat FULL 2>/dev/null)
    printf "  ${GRAY_BLACK}Max HP: %-6d${COLOR_RESET}\n" "${_kd_maxhp:-0}"
    printf '\n--- MAX HP ---\nMax HP: %s\n' "$_kd_maxhp" >> "$debug_file"

    # Set graphics to 0 for clean HTML
    (
        w3mc -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 \
            -debug "$URL/settings/graphics/0" \
            -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >/dev/null 2>&1
    ) &
    time_exit 17

    # ── Use existing SRC if king_start already entered the battle ────────
    # king_start fetches enterGame and saves to $TMP/SRC before calling king_debug.
    # Reuse that page to avoid double-entry into the battle.
    cp "$TMP/SRC" "$src_ram" 2>/dev/null

    if grep -q 'king/dodge/\|king/kingatk/' "$src_ram" 2>/dev/null; then
        printf "  ${GOLD_BLACK}👑 Battle already live (from king_start entry)${COLOR_RESET}\n"
        _kd_page "STATE: ENTER (from king_start SRC)"
    else
        # Enter fresh if not already in battle
        printf "  ${GOLD_BLACK}👑 Entering King of the Immortals...${COLOR_RESET}\n"
        _kg_fetch "/king/enterGame"
        _kd_page "STATE: ENTER GAME"

        # ── Wait for battle to become live ──────────────────────────────
        # Battle is live when dodge/ OR kingatk/ link is present.
        # dodge/  = PvP phase (king already dead or battle in progress)
        # kingatk/ = King phase (king still alive)
        printf "  ${GOLD_BLACK}😴 Waiting for battle to start...${COLOR_RESET}\n"
        local _kd_wait_start _kd_wait_now
        printf -v _kd_wait_start '%(%s)T' -1
        local _kd_wait_n=0
        until grep -q 'king/dodge/\|king/kingatk/' "$src_ram" 2>/dev/null; do
            printf -v _kd_wait_now '%(%s)T' -1
            local _kd_welapsed=$(( _kd_wait_now - _kd_wait_start ))
            if [ "$_kd_welapsed" -gt 90 ]; then
                break
            fi
            printf "\r\033[K  ${GOLD_BLACK}⏳ Waiting... [%02ds]${COLOR_RESET}" "$_kd_welapsed"

            # Handle UNRIP if hero is dead (valid r token, not r=0)
            local _kd_unrip_wait
            _kd_unrip_wait=$(grep -o -E '/king/unrip/[?]r[=][1-9][0-9]+' "$src_ram" 2>/dev/null | head -1)
            if [ -n "$_kd_unrip_wait" ]; then
                _kg_fetch "$_kd_unrip_wait"
            else
                _kg_fetch "/king"
            fi
            _kd_wait_n=$(( _kd_wait_n + 1 ))
            _kd_page "STATE: WAITING (poll #${_kd_wait_n})"
            sleep 2s
        done
        printf '\n'

        if ! grep -q 'king/dodge/\|king/kingatk/' "$src_ram" 2>/dev/null; then
            printf "%b\n" "  ${RED_BLACK}(Timeout: battle did not start within 90s)${COLOR_RESET}"
            printf '\n(Timeout waiting for battle)\n' >> "$debug_file"
            rm -f "$src_ram" "$full_ram" "$_kd_battle_history"
            cd - >/dev/null 2>&1; rm -rf "$tmp_ram"
            unset _kd_page _kd_action _kd_extract
            return 1
        fi
    fi

    # ── Battle started ───────────────────────────────────────────────────
    local _kd_battle_start
    printf -v _kd_battle_start '%(%s)T' -1
    _kd_extract

    # Detect team
    local _kd_team=""
    local _kd_pfive
    _kd_pfive=$(w3m -dump -T text/html "$src_ram" 2>/dev/null | head -n 5)
    if echo "$_kd_pfive" | grep -q '\[1\]'; then _kd_team="1"
    elif echo "$_kd_pfive" | grep -q '\[0\]'; then _kd_team="0"
    fi
    local _kd_opponent="${_kd_USER:-?}"

    printf '\n'
    printf "  ${GREEN_BLACK}👑 KING BATTLE [Team %s]${COLOR_RESET}\n" "${_kd_team:-?}"
    printf "  ${GRAY_BLACK}Max HP: %-6d  King HP%%: %-3d${COLOR_RESET}\n" "${_kd_maxhp:-0}" "${_kd_ENH:-0}"
    {
        printf '\n============================================================\n'
        printf '=  BATTLE START\n'
        printf '============================================================\n'
        printf 'Timestamp: %(%Y-%m-%d %H:%M:%S)T\n' -1
        printf 'Team: [%s]  MaxHP: %s  KingHP%%: %s\n' \
            "${_kd_team:-?}" "${_kd_maxhp:-?}" "${_kd_ENH:-?}"
        printf '\n--- ACTION LOG ---\n'
        printf '%-10s %-4s %-8s %-36s %-14s %-14s\n' \
            'TIME' '#' 'PHASE' 'ACTION' 'HP_before->after' 'ENH%%_before->after'
        printf '%s\n' '────────────────────────────────────────────────────────────────────────────────'
    } >> "$debug_file"

    # ── Battle variables ─────────────────────────────────────────────────
    local _kd_OLDHP="$_kd_USH"
    local _kd_last_heal=$(( _kd_battle_start - 90 ))
    local _kd_last_dodge=$(( _kd_battle_start - 20 ))
    local _kd_last_atk=$(( _kd_battle_start - ${LA%%.*} ))
    local _kd_stone_used=0
    local _kd_heals=0 _kd_dodges=0 _kd_atks=0 _kd_atkrnds=0 _kd_kingatks=0
    local _kd_la_failures=0 _kd_la_successes=0 _kd_la_adjusted=0
    local _kd_loop=0
    local _kd_king_dead=0
    local _kd_king_kill=0  # 1 = we got the kill
    local _kd_phase="KING"  # KING or PVP
    local _kd_phase_label="[KING]"
    local _kd_king_wait=0  # 1 = waiting for king HP to drop to 2%

    # Reset LA for battle start
    LA="4.5"

    # ── Main battle loop ─────────────────────────────────────────────────
    # shellcheck disable=SC1073
    # shellcheck disable=SC1061
    while :; do
        local _kd_now
        printf -v _kd_now '%(%s)T' -1
        local _kd_elapsed=$(( _kd_now - _kd_battle_start ))
        local _kd_min=$(( _kd_elapsed / 60 ))
        local _kd_sec=$(( _kd_elapsed % 60 ))
        local _kd_tsh=$(( _kd_now - _kd_last_heal ))
        local _kd_tsd=$(( _kd_now - _kd_last_dodge ))
        local _kd_tsa=$(( _kd_now - _kd_last_atk ))
        local _kd_hp_before="$_kd_USH"
        local _kd_enh_before="$_kd_ENH"
        local _kd_action_label=""

        _kd_loop=$(( _kd_loop + 1 ))

        # Save full page dump at loop 10
        if [ "$_kd_loop" -eq 10 ]; then
            local _kd_loop10_file="${debug_dir}/king_debug_${debug_ts}_LOOP10_FULL_PAGE.txt"
            local _kd_now_fmt
            printf -v _kd_now_fmt '%(%Y-%m-%d %H:%M:%S)T' -1
            {
                printf '============================================================\n'
                printf '=  FULL PAGE DUMP AT LOOP 10\n'
                printf '============================================================\n'
                printf 'Timestamp: %s\n' "$_kd_now_fmt"
                printf 'Loop: %d  |  Battle elapsed: %dm%ds  |  Phase: %s\n\n' \
                    "$_kd_loop" "$_kd_min" "$_kd_sec" "$_kd_phase"
                printf '\n--- RENDERED HTML (w3m dump) ---\n'
                w3m -dump -T text/html "$src_ram" 2>/dev/null
                printf '\n--- RAW HTML SOURCE (first 3000 chars) ---\n'
                head -c 3000 "$src_ram" 2>/dev/null
            } > "$_kd_loop10_file"
            printf "  ${GRAY_BLACK}[Loop 10 page saved: %s]${COLOR_RESET}\n" "$_kd_loop10_file" >&2
        fi

        # History capture every 3 loops
        if [ $(( _kd_loop % 3 )) -eq 0 ]; then
            local _kd_page_render
            local _kd_hist_fmt
            printf -v _kd_hist_fmt '%(%H:%M:%S)T' -1
            _kd_page_render=$(w3m -dump -T text/html "$src_ram" 2>/dev/null)
            {
                printf '[Loop %d] %s Phase:%s\n' "$_kd_loop" "$_kd_hist_fmt" "$_kd_phase"
                echo "$_kd_page_render" | sed -n '/^Os participantes:/,/^A batalha já começou!/p' | \
                    grep -v '^$' | grep -v 'Os participantes:' | grep -v 'A batalha já começou'
            } >> "$_kd_battle_history"
        fi

        # ── Detect phase transition: King died? ──────────────────────────
        if [ "$_kd_king_dead" -eq 0 ]; then
            # Check if king kill message appeared
            local _kd_rendered_check
            _kd_rendered_check=$(w3m -dump -T text/html "$src_ram" 2>/dev/null)
            if echo "$_kd_rendered_check" | grep -q -i -E 'assassinou.*[Rr]ei|killed.*[Kk]ing'; then
                _kd_king_dead=1
                _kd_phase="PVP"
                _kd_phase_label="[PVP]"
                # Check if WE got the kill
                if echo "$_kd_rendered_check" | grep -q -i -E 'Você assassinou'; then
                    _kd_king_kill=1
                    printf "\n  ${GREEN_BLACK}👑💀 VOCE ASSASSINOU O REI DOS IMORTAIS!${COLOR_RESET}\n"
                    printf '\n[%(%H:%M:%S)T] *** KING KILLED BY PLAYER ***\n' -1 >> "$debug_file"
                else
                    printf "\n  ${GOLD_BLACK}👑💀 O REI FOI MORTO! Fase PvP iniciando...${COLOR_RESET}\n"
                    printf '\n[%(%H:%M:%S)T] *** KING KILLED (by another player) ***\n' -1 >> "$debug_file"
                fi
                # Reset LA for PvP phase
                LA="${KING_LA:-4}"
                _kd_la_adjusted=0
                _kd_la_successes=0
                _kd_la_failures=0
                _kd_last_atk=$(( _kd_now - ${LA%%.*} ))
            fi
            # Also detect: no KINGATK link anymore = king is dead
            if [ "$_kd_king_dead" -eq 0 ] && [ -z "$_kd_KINGATK" ] && [ -n "$_kd_ATK" ]; then
                _kd_king_dead=1
                _kd_phase="PVP"
                _kd_phase_label="[PVP]"
                printf "\n  ${GOLD_BLACK}👑 Rei morto (KINGATK ausente). Fase PvP...${COLOR_RESET}\n"
                printf '\n[%(%H:%M:%S)T] *** KING DEAD (KINGATK link absent, ATK available) ***\n' -1 >> "$debug_file"
                LA="${KING_LA:-4}"
                _kd_la_adjusted=0
                _kd_la_successes=0
                _kd_la_failures=0
                _kd_last_atk=$(( _kd_now - ${LA%%.*} ))
            fi
        fi

        # ── Detect battle end / hero dead (original logic: dodge = battle live) ─
        # If no dodge AND no kingatk: hero is dead or battle ended
        if [ -z "$_kd_DODGE" ] && [ -z "$_kd_KINGATK" ]; then
            if [ -n "$_kd_UNRIP" ]; then
                # Hero dead - revive and restart loop iteration
                _kg_fetch "$_kd_UNRIP"
                _kd_extract
                _kd_action "💀 UNRIP (revived)" "$_kd_hp_before" "$_kd_enh_before" \
                           "$LA" "$_kd_USH" "$_kd_ENH"
                continue
            else
                # Confirm by re-fetching /king before giving up
                _kg_fetch "/king"
                _kd_extract
                if [ -n "$_kd_UNRIP" ]; then
                    # Got unrip after refresh - revive
                    _kg_fetch "$_kd_UNRIP"
                    _kd_extract
                    _kd_action "💀 UNRIP (after refresh)" "$_kd_hp_before" "$_kd_enh_before" \
                               "$LA" "$_kd_USH" "$_kd_ENH"
                    continue
                elif [ -z "$_kd_DODGE" ] && [ -z "$_kd_KINGATK" ]; then
                    # Still no battle links after refresh - battle over
                    _kd_action_label="🏁 BATTLE END"
                    _kd_action "$_kd_action_label" "$_kd_hp_before" "$_kd_enh_before" \
                              "$LA" "$_kd_USH" "$_kd_ENH"
                    break
                fi
            fi
        fi

        # ======================================================================
        # PHASE 1: KING ATTACK
        # ======================================================================
        if [ "$_kd_phase" = "KING" ]; then

            # ── Priority 0: HEAL (survival first) ────────────────────────
            if [ "${_kd_USH:-0}" -lt "$_kd_HLHP" ] && \
               [ "$_kd_tsh" -gt 90 ] && [ "$_kd_tsh" -lt 300 ] && [ -n "$_kd_HEAL" ]; then
                _kg_fetch "$_kd_HEAL"
                _kd_extract; _kd_last_heal=$_kd_now; _kd_last_atk=$_kd_now
                _kd_heals=$(( _kd_heals + 1 ))
                _kd_action_label="💚 HEAL -> HP:${_kd_USH}"

            # ── Priority 1: DODGE ────────────────────────────────────────
            elif ! grep -q 'txt smpl grey' "$src_ram" 2>/dev/null && \
                 [ "$_kd_tsd" -gt 20 ] && [ "$_kd_tsd" -lt 300 ] && \
                 [ "$_kd_USH" -lt "$_kd_OLDHP" ] && \
                 [ -n "$_kd_DODGE" ]; then
                _kg_fetch "$_kd_DODGE"
                _kd_extract; _kd_OLDHP="$_kd_USH"; _kd_last_dodge=$_kd_now; _kd_last_atk=$_kd_now
                _kd_dodges=$(( _kd_dodges + 1 ))
                _kd_action_label="🛡️ DODGE"

            # ── Priority 2: STONE when King HP% < 25 ────────────────────
            elif [ "$_kd_stone_used" -eq 0 ] && [ -n "$_kd_STONE" ] && [ "${_kd_ENH:-100}" -lt 25 ]; then
                _kg_fetch "$_kd_STONE"
                _kd_extract; _kd_stone_used=1; _kd_last_atk=$_kd_now
                _kd_action_label="💪 STONE (King HP%:${_kd_enh_before}<25)"

            # ── Priority 3: KING ATTACK (with 10%/2% threshold) ─────────
            elif [ -n "$_kd_KINGATK" ] && \
                 awk -v t="$_kd_tsa" -v la="${LA%%.*}" 'BEGIN { exit !(t+0 >= la+0) }'; then

                local _kd_king_hp="${_kd_ENH:-100}"

                # Strategy: Attack while HP > 10%, pause between 10-2%, attack at <= 2%
                if [ "$_kd_king_hp" -gt 10 ]; then
                    # King HP > 10% -> ATTACK FREELY
                    _kd_king_wait=0
                    _kg_fetch "$_kd_KINGATK"
                    _kd_extract; _kd_last_atk=$_kd_now
                    _kd_kingatks=$(( _kd_kingatks + 1 ))
                    _kd_action_label="👑 KINGATK (HP%:${_kd_king_hp}->${_kd_ENH})"

                elif [ "$_kd_king_hp" -le 2 ]; then
                    # King HP <= 2% -> ATTACK FOR THE KILL!
                    _kd_king_wait=0
                    _kg_fetch "$_kd_KINGATK"
                    _kd_extract; _kd_last_atk=$_kd_now
                    _kd_kingatks=$(( _kd_kingatks + 1 ))
                    _kd_action_label="👑🗡️ KINGATK KILL SHOT! (HP%:${_kd_king_hp}->${_kd_ENH})"

                else
                    # King HP between 10% and 2% -> WAIT, refresh only
                    _kd_king_wait=1
                    _kg_fetch "/king"
                    _kd_extract
                    _kd_action_label="⏳ WAITING (King HP%:${_kd_king_hp}%, target <=2%)"
                    sleep 1s
                fi

            # ── Priority 4: REFRESH ──────────────────────────────────────
            else
                _kg_fetch "/king"
                _kd_extract
                _kd_action_label="🔄 REFRESH [KING]"
                sleep 1s
            fi

        # ======================================================================
        # PHASE 2: PVP (post-king, coliseum logic)
        # ======================================================================
        else
            # ── Priority 0: HEAL ─────────────────────────────────────────
            if [ "${_kd_USH:-0}" -lt "$_kd_HLHP" ] && \
               [ "$_kd_tsh" -gt 90 ] && [ "$_kd_tsh" -lt 300 ] && [ -n "$_kd_HEAL" ]; then
                _kg_fetch "$_kd_HEAL"
                _kd_extract; _kd_last_heal=$_kd_now; _kd_last_atk=$_kd_now
                _kd_heals=$(( _kd_heals + 1 ))
                _kd_action_label="💚 HEAL -> HP:${_kd_USH}"

            # ── Priority 1: DODGE ────────────────────────────────────────
            elif ! grep -q 'txt smpl grey' "$src_ram" 2>/dev/null && \
                 [ "$_kd_tsd" -gt 20 ] && [ "$_kd_tsd" -lt 300 ] && \
                 [ "$_kd_USH" -lt "$_kd_OLDHP" ] && \
                 [ -n "$_kd_DODGE" ]; then
                _kg_fetch "$_kd_DODGE"
                _kd_extract; _kd_OLDHP="$_kd_USH"; _kd_last_dodge=$_kd_now; _kd_last_atk=$_kd_now
                _kd_dodges=$(( _kd_dodges + 1 ))
                _kd_action_label="🛡️ DODGE"

            # ── Priority 2: ATKRND (random - ally or strong enemy) ───────
            elif awk -v t="$_kd_tsa" -v la="${LA%%.*}" 'BEGIN { exit !(t+0 >= la+0) }' && \
                 ! grep -q 'txt smpl grey' "$src_ram" 2>/dev/null && \
                 [ -n "$_kd_ATKRND" ] && \
                 { awk -v rhp="$_kd_RHP" -v enh="${_kd_ENH:-0}" 'BEGIN { exit !(rhp+0 < enh+0) }' || \
                   { [ -n "$_kd_USER" ] && grep -q "$_kd_USER" "$tmp_ram/allies.txt" 2>/dev/null; }; }; then
                local _kd_prev_enh="$_kd_ENH"
                _kg_fetch "$_kd_ATKRND"
                _kd_extract; _kd_last_atk=$_kd_now
                _kd_atkrnds=$(( _kd_atkrnds + 1 ))
                _kd_action_label="🎲 ATKRND (ENH%:${_kd_prev_enh}->${_kd_ENH})"

            # ── Priority 3: ATK (direct PvP attack with adaptive LA) ────
            elif awk -v t="$_kd_tsa" -v la="${LA%%.*}" 'BEGIN { exit !(t+0 >= la+0) }' && \
                 [ -n "$_kd_ATK" ]; then
                local _kd_prev_enh="$_kd_ENH"
                local _kd_prev_atk="$_kd_ATK"
                _kg_fetch "$_kd_ATK"
                _kd_extract; _kd_last_atk=$_kd_now

                # Check attack success (adaptive LA)
                local _kd_success=1
                local _kd_rcheck
                _kd_rcheck=$(w3m -dump -T text/html "$src_ram" 2>/dev/null | head -n 20)
                if echo "$_kd_rcheck" | grep -q -i -E 'perdeu|falhou|failed|cooldown|too fast'; then
                    _kd_success=0
                elif [ "$_kd_ENH" = "$_kd_prev_enh" ] && \
                     [ "$_kd_ATK" = "$_kd_prev_atk" ] && [ -n "$_kd_ATK" ]; then
                    _kd_success=0
                fi

                if [ "$_kd_success" -eq 0 ]; then
                    _kd_la_failures=$(( _kd_la_failures + 1 ))
                    _kd_la_successes=0
                    LA=$(awk -v la="$LA" 'BEGIN { printf "%.1f", la + 0.2 }')
                    _kd_la_adjusted=1
                    _kd_action_label="⚔️ ATK -> MISS (LA->${LA}s)"
                else
                    _kd_la_successes=$(( _kd_la_successes + 1 ))
                    _kd_atks=$(( _kd_atks + 1 ))
                    _kd_action_label="⚔️ ATK -> HIT (ENH%:${_kd_prev_enh}->${_kd_ENH})"
                    if [ "$_kd_la_successes" -ge 10 ] && [ "$_kd_la_adjusted" -eq 1 ]; then
                        if awk -v la="$LA" 'BEGIN { exit !(la > 3.0) }'; then
                            LA=$(awk -v la="$LA" 'BEGIN { printf "%.1f", la - 0.1 }')
                            _kd_action_label="${_kd_action_label} LA<${LA}s"
                        fi
                        _kd_la_successes=0
                    fi
                fi

            # ── Priority 4: REFRESH ──────────────────────────────────────
            else
                _kg_fetch "/king"
                _kd_extract
                _kd_action_label="🔄 REFRESH [PVP]"
                sleep 1s
            fi
        fi

        # ── Log action to file ───────────────────────────────────────────
        _kd_action "$_kd_action_label" "$_kd_hp_before" "$_kd_enh_before" \
                   "$LA" "$_kd_USH" "$_kd_ENH"

        # ── Terminal display ─────────────────────────────────────────────
        local _kd_hp_pct
        _kd_hp_pct=$(awk -v c="${_kd_USH:-0}" -v m="${_kd_maxhp:-1}" \
                     'BEGIN { v=c/m*100; if(v>100)v=100; if(v<0)v=0; printf "%.0f", v }')
        local _kd_bfill
        _kd_bfill=$(awk -v p="$_kd_hp_pct" 'BEGIN { v=int(p*16/100); if(v<0)v=0; if(v>16)v=16; print v }')
        local _kd_bar="" _kd_j
        for (( _kd_j=0; _kd_j<_kd_bfill; _kd_j++ )); do _kd_bar+="█"; done
        for (( _kd_j=0; _kd_j<(16-_kd_bfill); _kd_j++ )); do _kd_bar+="░"; done
        local _kd_hcol
        if [ "$_kd_hp_pct" -gt 60 ]; then _kd_hcol="$GREEN_BLACK"
        elif [ "$_kd_hp_pct" -gt 30 ]; then _kd_hcol="$GOLD_BLACK"
        else _kd_hcol="$RED_BLACK"; fi

        local _kd_stone_st
        [ "$_kd_stone_used" -eq 0 ] && _kd_stone_st="${GREEN_BLACK}READY${COLOR_RESET}" || _kd_stone_st="${GRAY_BLACK}USED${COLOR_RESET}"

        # Phase-specific header
        local _kd_phase_display
        if [ "$_kd_phase" = "KING" ]; then
            if [ "$_kd_king_wait" -eq 1 ]; then
                _kd_phase_display="${GOLD_BLACK}KING PHASE [WAITING HP%<=2%]${COLOR_RESET}"
            else
                _kd_phase_display="${RED_BLACK}KING PHASE [ATTACKING]${COLOR_RESET}"
            fi
        else
            _kd_phase_display="${GREEN_BLACK}PVP PHASE${COLOR_RESET}"
        fi

        printf "\n  ${GOLD_BLACK}══ KING DEBUG ${_kd_min}m${_kd_sec}s (loop #${_kd_loop}) ══${COLOR_RESET}\n"
        printf "  ${_kd_phase_display}\n"
        printf "  ${_kd_hcol}HP: %-5d/%-5d${COLOR_RESET} [${_kd_bar}] %-3d%%\n" "${_kd_USH:-0}" "${_kd_maxhp:-0}" "$_kd_hp_pct"
        if [ "$_kd_phase" = "KING" ]; then
            printf "  ${GRAY_BLACK}King HP%%: ${GOLD_BLACK}%-3d%%${GRAY_BLACK}  Team:[%s]${COLOR_RESET}\n" "${_kd_ENH:-0}" "${_kd_team:-?}"
        else
            printf "  ${GRAY_BLACK}VS: %-16s  ENH%%: %-3d  Team:[%s]${COLOR_RESET}\n" "${_kd_opponent:-?}" "${_kd_ENH:-0}" "${_kd_team:-?}"
        fi
        printf "  ${GRAY_BLACK}────────────────────────────────${COLOR_RESET}\n"
        printf "  %s\n" "$_kd_action_label"
        local _kd_heal_info
        if [ "$_kd_tsh" -lt 90 ]; then
            _kd_heal_info="${GOLD_BLACK}⏳$(( 90 - _kd_tsh ))s${COLOR_RESET}"
        else
            _kd_heal_info="${GREEN_BLACK}READY${COLOR_RESET}"
        fi
        printf "  ${GRAY_BLACK}LA: %-4s  HPER: %-2d%%  Heal: ${_kd_heal_info}  Fails: %-2d${COLOR_RESET}\n" "$LA" "$HPER" "$_kd_la_failures"
        printf "  ${GRAY_BLACK}────────────────────────────────${COLOR_RESET}\n"
        printf "  ${GREEN_BLACK}KINGATK: %-3d  ATK: %-3d  RND: %-3d  DODGE: %-3d  HEAL: %-3d${COLOR_RESET}\n" \
            "$_kd_kingatks" "$_kd_atks" "$_kd_atkrnds" "$_kd_dodges" "$_kd_heals"
        printf "  💪 Stone: ${_kd_stone_st}\n"
        if [ "$_kd_king_kill" -eq 1 ]; then
            printf "  ${GREEN_BLACK}👑 KING SLAYER!${COLOR_RESET}\n"
        fi
        printf "  ${GRAY_BLACK}─── PARTICIPANTS ───${COLOR_RESET}\n"
        w3m -dump -T text/html "$src_ram" 2>/dev/null | \
            grep "Os participantes:" | \
            sed 's|\[0\]|🔴|g; s|\[1\]|🔵|g; s|\[health\]|🧡|g; s|\[king\]|👑|g' | \
            while IFS= read -r logline; do
                printf "  ${GRAY_BLACK}%s${COLOR_RESET}\n" "$logline"
            done
        printf "  ${GRAY_BLACK}─── BATTLE LOG ───${COLOR_RESET}\n"
        local _kd_prender
        _kd_prender=$(w3m -dump -T text/html "$src_ram" 2>/dev/null)
        echo "$_kd_prender" | sed -n '/^Os participantes:/,/^A batalha já começou!/p' | \
            grep -v '^$' | grep -v 'Os participantes:' | grep -v 'A batalha já começou' | \
            sed 's|\[0\]|🔴|g; s|\[1\]|🔵|g; s|\[rip\]|💀|g; s|\[king\]|👑|g; s|assassinou|💥|; s|perdeu|❌|; s|Você acertar|✓|; s|Você usou|⚡|' | \
            tail -n 8 | \
            while IFS= read -r logline; do
                printf "  ${GRAY_BLACK}%s${COLOR_RESET}\n" "$logline"
            done
    done

    # ── Post-battle ──────────────────────────────────────────────────────
    local _kd_end; printf -v _kd_end '%(%s)T' -1
    local _kd_dur=$(( _kd_end - _kd_battle_start ))
    local _kd_dmin=$(( _kd_dur / 60 )) _kd_dsec=$(( _kd_dur % 60 ))

    _kd_page "STATE: POST-BATTLE"

    # Parse result
    local _kd_result="unknown"
    local _kd_rend
    _kd_rend=$(w3m -dump -T text/html "$src_ram" 2>/dev/null)
    if echo "$_kd_rend" | grep -q -i -E 'vit[oó]ria|victory|victoire'; then
        _kd_result="WIN"
    elif echo "$_kd_rend" | grep -q -i -E 'derrota|defeat|defaite'; then
        _kd_result="LOSS"
    fi

    # ── Terminal post-match display ──────────────────────────────────────
    local _kd_captured_fails=$(grep -c "perdeu" "$_kd_battle_history" 2>/dev/null || echo "0")
    local _kd_captured_kills=$(grep -c "assassinou" "$_kd_battle_history" 2>/dev/null || echo "0")

    printf "\n"
    printf "  ${GOLD_BLACK}╔══════════════════════════════════════════════════════════╗${COLOR_RESET}\n"
    printf "  ${GOLD_BLACK}║               KING BATTLE SUMMARY  👑                   ║${COLOR_RESET}\n"
    printf "  ${GOLD_BLACK}╠══════════════════════════════════════════════════════════╣${COLOR_RESET}\n"
    if [ "$_kd_result" = "WIN" ]; then
        printf "  ${GREEN_BLACK}║     ✅  VICTORY!                                       ║${COLOR_RESET}\n"
    elif [ "$_kd_result" = "LOSS" ]; then
        printf "  ${RED_BLACK}║     ❌  DEFEAT                                         ║${COLOR_RESET}\n"
    else
        printf "  ${GOLD_BLACK}║     ❓  RESULT UNKNOWN                                 ║${COLOR_RESET}\n"
    fi
    if [ "$_kd_king_kill" -eq 1 ]; then
        printf "  ${GREEN_BLACK}║     👑 KING SLAYER! (You killed the King!)              ║${COLOR_RESET}\n"
    fi
    printf "  ${GOLD_BLACK}╠══════════════════════════════════════════════════════════╣${COLOR_RESET}\n"
    printf "  ${GRAY_BLACK}║ Duration:${GOLD_BLACK} %-3dm%-3ds${GRAY_BLACK}  |  Loops:${GOLD_BLACK} %-5d${GRAY_BLACK}  |  Team:[${GOLD_BLACK}%s${GRAY_BLACK}]       ║${COLOR_RESET}\n" \
        "$_kd_dmin" "$_kd_dsec" "$_kd_loop" "${_kd_team:-?}"
    printf "  ${GOLD_BLACK}╠══════════════════════════════════════════════════════════╣${COLOR_RESET}\n"
    printf "  ${GRAY_BLACK}║ ACTIONS:${COLOR_RESET}\n"
    printf "  ${GRAY_BLACK}║   KINGATK:${GREEN_BLACK}%-3d${GRAY_BLACK}  ATK:${GREEN_BLACK}%-3d${GRAY_BLACK}  RND:${GREEN_BLACK}%-3d${GRAY_BLACK}  DODGE:${GREEN_BLACK}%-3d${GRAY_BLACK}  HEAL:${GREEN_BLACK}%-3d${GRAY_BLACK}  Stone:%d${COLOR_RESET}\n" \
        "$_kd_kingatks" "$_kd_atks" "$_kd_atkrnds" "$_kd_dodges" "$_kd_heals" "$_kd_stone_used"
    printf "  ${GOLD_BLACK}╠══════════════════════════════════════════════════════════╣${COLOR_RESET}\n"
    printf "  ${GRAY_BLACK}║ LEARNING ATTACK (LA):${COLOR_RESET}\n"
    printf "  ${GRAY_BLACK}║   Start: ${KING_LA:-4}s  |  End: ${LA}s  |  Fails: ${RED_BLACK}%-2d${COLOR_RESET}\n" "$_kd_la_failures"
    printf "  ${GRAY_BLACK}║   Fails from log:${RED_BLACK}%-2d${GRAY_BLACK}  |  Kills from log:${GREEN_BLACK}%-2d${COLOR_RESET}\n" \
        "$_kd_captured_fails" "$_kd_captured_kills"
    printf "  ${GOLD_BLACK}╠══════════════════════════════════════════════════════════╣${COLOR_RESET}\n"
    printf "  ${GRAY_BLACK}║ Debug file: ${GOLD_BLACK}%-46s${GRAY_BLACK}║${COLOR_RESET}\n" "${debug_file##*/}"
    printf "  ${GOLD_BLACK}╚══════════════════════════════════════════════════════════╝${COLOR_RESET}\n"
    printf "\n  ${GRAY_BLACK}(closing in 10 seconds...)${COLOR_RESET}\n"
    sleep 10s

    # ── Write battle summary to debug file ───────────────────────────────
    {
        printf '\n============================================================\n'
        printf '=  BATTLE SUMMARY\n'
        printf '============================================================\n'
        printf 'Result: %s\n' "$_kd_result"
        printf 'King Kill: %s\n' "$([ "$_kd_king_kill" -eq 1 ] && echo "YES" || echo "no")"
        printf 'Duration: %dm %ds  |  Loops: %d\n' "$_kd_dmin" "$_kd_dsec" "$_kd_loop"
        printf 'KINGATK:%d  ATK:%d  RND:%d  DODGE:%d  HEAL:%d  Stone:%d\n' \
            "$_kd_kingatks" "$_kd_atks" "$_kd_atkrnds" "$_kd_dodges" "$_kd_heals" "$_kd_stone_used"
        printf 'ATK Fails:%d  LA Start:%s  LA End:%s\n' \
            "$_kd_la_failures" "${KING_LA:-4}" "$LA"
        printf 'HPER Final:%s  RPER Final:%s\n' "$HPER" "$RPER"
        printf '\n--- BATTLE HISTORY (captured during battle) ---\n'
        if [ -f "$_kd_battle_history" ] && [ -s "$_kd_battle_history" ]; then
            cat "$_kd_battle_history"
        else
            printf '(no history captured)\n'
        fi
        printf '\n--- ATTACK ANALYSIS ---\n'
        printf 'perdeu (fails detected): %d\n' "$_kd_captured_fails"
        printf 'assassinou (kills): %d\n' "$_kd_captured_kills"
        printf '\n--- DEBUG ARTIFACTS ---\n'
        printf 'Full page dump at Loop 10: king_debug_%s_LOOP10_FULL_PAGE.txt\n' "$debug_ts"
    } >> "$debug_file"

    # ── Cleanup ──────────────────────────────────────────────────────────
    rm -f "$src_ram" "$full_ram" "$_kd_battle_history"
    cd - >/dev/null 2>&1
    rm -rf "$tmp_ram"
    unset _kd_page _kd_action _kd_extract
    unset _kd_USH _kd_ENH _kd_ATK _kd_KINGATK _kd_ATKRND
    unset _kd_DODGE _kd_STONE _kd_HEAL _kd_UNRIP _kd_RHP _kd_HLHP _kd_USER
}

# ============================================================================
# KING FIGHT - Legacy battle function (kept for backward compat, delegates)
# ============================================================================

king_fight() {
    king_debug
    func_unset
    apply_event
    echo -e "${RED_BLACK}👑King ✅${COLOR_RESET}"
    sleep 10s
    [ -t 1 ] && clear
}

# ============================================================================
# KING START DEBUG - Immediate start (manual trigger)
# ============================================================================

king_start_debug() {
    cd "$TMP" || return
    (
        w3mc -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 \
            -debug -dump_source "$URL/train" \
            -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" | \
            grep -o -E '\(([0-9]+)\)' | sed 's/[()]//g' >"$TMP"/FULL
    ) </dev/null &>/dev/null &
    time_exit 17
    (
        w3mc -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 \
            -debug -dump_source "$URL/king/enterGame" \
            -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
    ) </dev/null &>/dev/null &
    time_exit 17
    printf "\n${GOLD_BLACK}👑 King Debug Mode - starting immediately${COLOR_RESET}\n"
    king_debug
}

# ============================================================================
# KING START - Scheduler/caller (backward compatible with run.sh/crono.sh)
# ============================================================================

king_start() {
    case $(date +%H:%M) in
    (12:2[5-9]|16:2[5-9]|22:2[5-9])
        cd "$TMP" || return
        (
            w3mc -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 \
                -debug -dump_source "$URL/train" \
                -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" | \
                grep -o -E '\(([0-9]+)\)' | sed 's/[()]//g' >"$TMP"/FULL
        ) </dev/null &>/dev/null &
        time_exit 17
        (
            w3mc -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 \
                -debug -dump_source "$URL/king/enterGame" \
                -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
        ) </dev/null &>/dev/null &
        time_exit 17
        echo -e "${GOLD_BLACK}👑King of the Immortals will be started...${COLOR_RESET}"
        until (case $(date +%M) in (2[5-9]) exit 1 ;; esac); do
            sleep 3
        done
        (
            w3mc -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 \
                -debug -dump_source "$URL/king/enterGame" \
                -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
        ) </dev/null &>/dev/null &
        time_exit 17
        printf "\nKing\n$URL\n"
        grep -o -E '(/[a-z]+(/[a-z]+/[^A-Za-z0-9]r[^A-Za-z0-9][0-9]+|/))' "$TMP"/SRC | sed -n '1p' >ACCESS 2>/dev/null
        printf " 👣 Entering...\n$(cat ACCESS)\n"
        printf " 😴 Waiting...\n"
        cat < "$TMP"/SRC | grep -o 'king/kingatk/\|king/dodge/' >EXIT 2>/dev/null
        local BREAK=$(( $(date +%s) + 30 ))
        until [ -s "EXIT" ] || [ "$(date +%s)" -gt "$BREAK" ]; do
            printf " 💤\t...\n$(cat ACCESS)\n"
            (
                w3mc -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 \
                    -debug -dump_source "${URL}$(cat ACCESS)" \
                    -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
            ) </dev/null &>/dev/null &
            time_exit 17
            cat < "$TMP"/SRC | sed 's/href=/\n/g' | grep '/king/' | head -n 1 | awk -F"[']" '{ print $2 }' >ACCESS 2>/dev/null
            cat < "$TMP"/SRC | grep -o 'king/kingatk/\|king/dodge/' >EXIT 2>/dev/null
            sleep 2
        done
        king_debug
        ;;
    esac
}
