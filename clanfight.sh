#
#/clanfight/dodge/?r=0
#/clanfight/attack/?r=0
#/clanfight/attackrandom/?r=0
#/clanfight/heal/?r=0
#/clanfight/stone/?r=0
#/clanfight/grass/?r=0
#/clanfight/?out_gate
clanfight_fight() {
  cd $TMP || exit
  #/enterFight
  local LA=4    # interval attack
  local HPER=48 # % to heal
  local RPER=15 # % to random
  awk -v ush="$(cat FULL)" -v hper="$HPER" 'BEGIN { printf "%.0f", ush * hper / 100 }' >HLHP
  cf_access() {
    grep -o -E '(/[a-z]+/[a-z]{0,4}at[a-z]{0,3}k/[^A-Za-z0-9]r[^A-Za-z0-9][0-9]+)' "$TMP"/SRC | sed -n '1p' >ATK 2>/dev/null
    grep -o -E '(/[a-z]+/at[a-z]{0,3}k[a-z]{3,6}/[^A-Za-z0-9]r[^A-Za-z0-9][0-9]+)' "$TMP"/SRC >ATKRND 2>/dev/null
    grep -o -E '(/clanfight/dodge/[^A-Za-z0-9]r[^A-Za-z0-9][0-9]+)' "$TMP"/SRC >DODGE 2>/dev/null
    grep -o -E '(/clanfight/heal/[^A-Za-z0-9]r[^A-Za-z0-9][0-9]+)' "$TMP"/SRC >HEAL 2>/dev/null
    grep -o -E '(/clanfight/grass/[^A-Za-z0-9]r[^A-Za-z0-9][0-9]+)' "$TMP"/SRC >GRASS 2>/dev/null
    grep -o -E '([[:upper:]][[:lower:]]{0,20}( [[:upper:]][[:lower:]]{0,17})?)[[:space:]]\(' "$TMP"/SRC | sed -n 's,\ [(],,;s,\ ,_,;2p' >CLAN 2>/dev/null
    #  grep -o -E '([[:upper:]][[:lower:]]{0,15}( [[:upper:]][[:lower:]]{0,13})?)[[:space:]][^[:alnum:]]s' $TMP/SRC|sed -n 's,\ [<]s,,;s,\ ,_,;2p' >USER 2> /dev/null
    grep -o -E "(hp)[^A-Za-z0-9]{1,4}[0-9]{1,6}" "$TMP"/SRC | sed "s,hp[']\/[>],,;s,\ ,," >HP 2>/dev/null
    grep -o -E "(nbsp)[^A-Za-z0-9]{1,2}[0-9]{1,6}" "$TMP"/SRC | sed -n 's,nbsp[;],,;s,\ ,,;1p' >HP2 2>/dev/null
    awk -v ush="$(cat HP)" -v rper="$RPER" 'BEGIN { printf "%.0f", ush * rper / 100 + ush }' >RHP
    awk -v ush="$(cat FULL)" -v hper="$HPER" 'BEGIN { printf "%.0f", ush * hper / 100 }' >HLHP
    if grep -q -o '/dodge/' "$TMP"/SRC; then
      printf "\n     🙇‍ "
      w3m -dump -T text/html "$TMP/SRC" | head -n 18 | sed '0,/^\([a-z]\{2\}\)[[:space:]]\([0-9]\{1,6\}\)\([0-9]\{2\}\):\([0-9]\{2\}\)/s//\♥️\2 ⏰\3:\4/;s,\[0\]\ ,\🔴,g;s,\[1\]\ ,\🔵,g;s,\[stone\],\ 💪,;s,\[herb\],\ 🌿,;s,\[grass\],\ 🌿,g;s,\[potio\],\ 💊,;s,\ \[health\]\ ,\ 🧡,;s,\ \[icon\]\ ,\ 🐾,g;s,\[rip\]\ ,\ 💀,g'
    else
      echo 1 >BREAK_LOOP
      echo_t "Battle is over!" "${RED_BLACK}" "${COLOR_RESET}" "after" "⚔️\n"
      sleep 2s
    fi
  }
  cf_access
  >BREAK_LOOP
  cat HP >old_HP
  echo $(($(date +%s) - 20)) >last_dodge
  echo $(($(date +%s) - 90)) >last_heal
  echo $(($(date +%s) - $LA)) >last_atk
  until [ -s "BREAK_LOOP" ]; do
    cf_access
    #/dodge/
    if ! grep -q -o 'txt smpl grey' "$TMP"/SRC && [ "$(($(date +%s) - $(cat last_dodge)))" -gt 20 -a "$(($(date +%s) - $(cat last_dodge)))" -lt 300 ] && awk -v ush="$(cat HP)" -v oldhp="$(cat old_HP)" 'BEGIN { exit !(ush < oldhp) }'; then
      (
        w3mc -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}$(cat DODGE)" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
      ) </dev/null &>/dev/null &
      time_exit 17
      cf_access
      cat HP >old_HP
      date +%s >last_dodge
    #/heal/
    elif awk -v ush="$(cat HP)" -v hlhp="$(cat HLHP)" 'BEGIN { exit !(ush < hlhp) }' && [ "$(($(date +%s) - $(cat last_heal)))" -gt 90 -a "$(($(date +%s) - $(cat last_heal)))" -lt 300 ]; then
      (
        w3mc -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}$(cat HEAL)" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
      ) </dev/null &>/dev/null &
      time_exit 17
      sleep 0.3s
      (
        w3mc -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}$(cat GRASS)" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
      ) </dev/null &>/dev/null &
      time_exit 17
      cf_access
      cat HP >FULL
      cat HP >old_HP
      date +%s >last_heal
    #/random
    elif awk -v latk="$(($(date +%s) - $(cat last_atk)))" -v atktime="$LA" 'BEGIN { exit !(latk != atktime) }' && ! grep -q -o 'txt smpl grey' "$TMP"/SRC && awk -v rhp="$(cat RHP)" -v enh="$(cat HP2)" 'BEGIN { exit !(rhp < enh) }' || awk -v latk="$(($(date +%s) - $(cat last_atk)))" -v atktime="$LA" 'BEGIN { exit !(latk != atktime) }' && ! grep -q -o 'txt smpl grey' "$TMP"/SRC && grep -q -o "$(cat CLAN)" "$TMP"/callies.txt; then
      (
        w3mc -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}$(cat ATKRND)" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
      ) </dev/null &>/dev/null &
      time_exit 17
      cf_access
      date +%s >last_atk
      #/attack
      sleep 0.3s
    elif awk -v latk="$(($(date +%s) - $(cat last_atk)))" -v atktime="$LA" 'BEGIN { exit !(latk > atktime) }'; then
      (
        w3mc -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}$(cat ATK)" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
      ) </dev/null &>/dev/null &
      time_exit 17
      cf_access
      date +%s >last_atk
    else
      (
        w3mc -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}/clanfight" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
      ) </dev/null &>/dev/null &
      time_exit 17
      cf_access
      sleep 1s
    fi
  done
  unset cf_access _random
  #/end
  func_unset
  echo_t "ClanFight" "${GREEN_BLACK}" "${COLOR_RESET}" "after" "✅\n"
  sleep 10s
  [ -t 1 ] && clear
}
clanfight_debug () {
    local debug_dir="${ACCOUNT_LOGS:-$TMP}"
    local debug_ts
    printf -v debug_ts '%(%Y%m%d_%H%M%S)T' -1
    local debug_file="${debug_dir}/clanfight_debug_${debug_ts}.log"

    local dir_ram
    if [ -d "/dev/shm" ]; then dir_ram="/dev/shm/"; else dir_ram="$PREFIX/tmp/"; fi
    mkdir -p "$dir_ram"
    local src_ram
    src_ram=$(mktemp -p "$dir_ram" cfdbg.XXXXXX)
    local full_ram
    full_ram=$(mktemp -p "$dir_ram" cfdbg.XXXXXX)
    local tmp_ram
    tmp_ram=$(mktemp -d -t twmcfdbg.XXXXXX)
    local _cfdbg_battle_history
    _cfdbg_battle_history=$(mktemp -p "$dir_ram" history.XXXXXX)
    cp -r "$TMP"/* "$tmp_ram" 2>/dev/null
    cd "$tmp_ram" || return 1

    local LA=4
    local HPER=48
    local RPER=15

    _cfdbg_page() {
        local label="$1"
        {
            printf '\n============================================================\n'
            printf '=  %s\n' "$label"
            printf '============================================================\n'
            printf 'Timestamp: %(%Y-%m-%d %H:%M:%S)T\n' -1
            printf '\n--- W3M RENDERED DUMP ---\n'
            w3m -dump -T text/html "$src_ram" 2>/dev/null
            printf '\n--- ACTION LINKS ---\n'
            printf 'ATK:    %s\n' "$(grep -o -E '/[a-z]+/[a-z]{0,4}at[a-z]{0,3}k/[?]r[=][0-9]+' "$src_ram" 2>/dev/null | head -1)"
            printf 'ATKRND: %s\n' "$(grep -o -E '/[a-z]+/at[a-z]{0,3}k[a-z]{3,6}/[?]r[=][0-9]+' "$src_ram" 2>/dev/null)"
            printf 'DODGE:  %s\n' "$(grep -o -E '/clanfight/dodge/[^A-Za-z0-9]r[^A-Za-z0-9][0-9]+' "$src_ram" 2>/dev/null)"
            printf 'HEAL:   %s\n' "$(grep -o -E '/clanfight/heal/[^A-Za-z0-9]r[^A-Za-z0-9][0-9]+' "$src_ram" 2>/dev/null)"
            printf 'GRASS:  %s\n' "$(grep -o -E '/clanfight/grass/[^A-Za-z0-9]r[^A-Za-z0-9][0-9]+' "$src_ram" 2>/dev/null)"
            printf '\n--- HP VALUES ---\n'
            printf 'Player HP: %s\n' "$(grep -o -E '(hp)[^A-Za-z0-9]{1,4}[0-9]{2,5}' "$src_ram" 2>/dev/null | grep -o -E '[0-9]{2,5}' | head -1)"
            printf 'Enemy HP%%: %s\n' "$(grep -o -E '(nbsp)[^A-Za-z0-9]{1,2}[0-9]{1,6}' "$src_ram" 2>/dev/null | sed -n 's,nbsp[;],,;s, ,,;1p')"
            printf '\n--- MARKERS ---\n'
            printf 'dodge:%s  grey:%s  rip:%s\n' \
                "$(grep -c '/dodge/' "$src_ram" 2>/dev/null)" \
                "$(grep -c 'txt smpl grey' "$src_ram" 2>/dev/null)" \
                "$(grep -c '\[rip\]' "$src_ram" 2>/dev/null)"
            printf '\n--- KEYWORD SEARCH ---\n'
            w3m -dump -T text/html "$src_ram" 2>/dev/null | \
                grep -i -E 'vit[oó]ria|victory|defeat|derrota|perdeu|ganhou|venceu' 2>/dev/null || true
        } >> "$debug_file"
    }

    _cfdbg_action() {
        local action_label="$1" ush_before="$2" enh_before="$3" ush_after="$4" enh_after="$5"
        local ts; printf -v ts '%(%H:%M:%S)T' -1
        {
            printf '[%s] #%d | %s\n' "$ts" "$_cfdbg_loop" "$action_label"
            printf '       HP: %s→%s  ENH: %s→%s  LA:%ss  HPER:%s%%  RPER:%s%%\n' \
                "$ush_before" "${ush_after:--}" "$enh_before" "${enh_after:--}" \
                "$LA" "$HPER" "$RPER"
        } >> "$debug_file"
    }

    local _cfdbg_USH _cfdbg_ENH _cfdbg_ATK _cfdbg_ATKRND
    local _cfdbg_DODGE _cfdbg_HEAL _cfdbg_GRASS _cfdbg_RHP _cfdbg_HLHP
    _cfdbg_extract() {
        _cfdbg_USH=$(grep -o -E '(hp)[^A-Za-z0-9]{1,4}[0-9]{2,5}' "$src_ram" | grep -o -E '[0-9]{2,5}' | sed 's, ,,g' | head -1)
        _cfdbg_ENH=$(grep -o -E '(nbsp)[^A-Za-z0-9]{1,2}[0-9]{1,6}' "$src_ram" | sed -n 's,nbsp[;],,;s, ,,;1p')
        _cfdbg_ATK=$(grep -o -E '/[a-z]+/[a-z]{0,4}at[a-z]{0,3}k/[^A-Za-z0-9]r[^A-Za-z0-9][0-9]+' "$src_ram" | head -1)
        _cfdbg_ATKRND=$(grep -o -E '/[a-z]+/at[a-z]{0,3}k[a-z]{3,6}/[^A-Za-z0-9]r[^A-Za-z0-9][0-9]+' "$src_ram")
        _cfdbg_DODGE=$(grep -o -E '/clanfight/dodge/[^A-Za-z0-9]r[^A-Za-z0-9][0-9]+' "$src_ram")
        _cfdbg_HEAL=$(grep -o -E '/clanfight/heal/[^A-Za-z0-9]r[^A-Za-z0-9][0-9]+' "$src_ram")
        _cfdbg_GRASS=$(grep -o -E '/clanfight/grass/[^A-Za-z0-9]r[^A-Za-z0-9][0-9]+' "$src_ram")
        _cfdbg_RHP=$(awk -v ush="${_cfdbg_USH:-0}" -v rper="$RPER" 'BEGIN { printf "%.0f", ush * rper / 100 + ush }')
        _cfdbg_HLHP=$(awk -v ush="${_cfdbg_maxhp:-0}" -v hper="$HPER" 'BEGIN { printf "%.0f", ush * hper / 100 }')
    }

    # ── Header ──────────────────────────────────────────────────────────────
    {
        printf 'ClanFight Debug Log - %(%Y-%m-%d %H:%M:%S)T\n' -1
        printf 'Server: %s  Account: %s\n' "$URL" "${ACCOUNT_ID:-unknown}"
        printf '\n--- CONFIG ---\n'
        printf 'LA=%ss  HPER=%s%%  RPER=%s%%\n' "$LA" "$HPER" "$RPER"
    } > "$debug_file"

    # ── Terminal panel ───────────────────────────────────────────────────────
    printf "\n  ${GOLD_BLACK}╔══════════════════════════════════════╗${COLOR_RESET}\n"
    printf "  ${GOLD_BLACK}║   CLANFIGHT  DEBUG  MODE  ⚔️           ║${COLOR_RESET}\n"
    printf "  ${GOLD_BLACK}╠══════════════════════════════════════╣${COLOR_RESET}\n"
    printf "  ${GOLD_BLACK}║ LA: %-5s  HPER: %-3d%%  RPER: %-3d%%      ║${COLOR_RESET}\n" "$LA" "$HPER" "$RPER"
    printf "  ${GOLD_BLACK}╚══════════════════════════════════════╝${COLOR_RESET}\n"

    # ── Max HP ───────────────────────────────────────────────────────────────
    (
        w3mc -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 \
            -debug -dump_source "$URL/train" \
            -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" | \
            grep -o -E '\(([0-9]+)\)' | sed 's/[()]//g' >"$full_ram"
    ) &
    time_exit 20
    local _cfdbg_maxhp
    _cfdbg_maxhp=$(cat "$full_ram" 2>/dev/null)
    [ -z "$_cfdbg_maxhp" ] && _cfdbg_maxhp=$(cat FULL 2>/dev/null)
    [ -z "$_cfdbg_maxhp" ] && _cfdbg_maxhp="30000"  # Fallback if extraction failed
    printf "  ${GRAY_BLACK}Max HP: %-6d${COLOR_RESET}\n" "$_cfdbg_maxhp"
    printf '\n--- MAX HP ---\nMax HP: %s\n' "$_cfdbg_maxhp" >> "$debug_file"

    # ── Graphics 0 ──────────────────────────────────────────────────────────
    (
        w3mc -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 \
            -debug "$URL/settings/graphics/0" \
            -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >/dev/null 2>&1
    ) </dev/null &>/dev/null &
    time_exit 17

    # ── Clear reward + enter game ────────────────────────────────────────────
    printf "  ${GOLD_BLACK}⚔️  Entering ClanFight...${COLOR_RESET}\n"
    (
        w3mc -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 \
            -debug -dump_source "$URL/clanfight/?close=reward" \
            -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$src_ram"
    ) </dev/null &>/dev/null &
    time_exit 17
    (
        w3mc -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 \
            -debug -dump_source "$URL/clanfight/enterFight" \
            -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$src_ram"
    ) </dev/null &>/dev/null &
    time_exit 17
    _cfdbg_page "STATE: ENTER FIGHT"

    # ── Wait for battle (dodge link = battle is live) ─────────────────────
    printf "  ${GOLD_BLACK}😴 Waiting for battle to start...${COLOR_RESET}\n"
    local _cfdbg_wait_start
    printf -v _cfdbg_wait_start '%(%s)T' -1
    local _cfdbg_wait_n=0
    until grep -q '/clanfight/dodge/' "$src_ram" 2>/dev/null; do
        local _cfdbg_wait_now
        printf -v _cfdbg_wait_now '%(%s)T' -1
        local _cfdbg_welapsed=$(( _cfdbg_wait_now - _cfdbg_wait_start ))
        if [ "$_cfdbg_welapsed" -gt 60 ]; then break; fi
        printf "\r\033[K  ${GOLD_BLACK}⏳ Waiting... [%02ds]${COLOR_RESET}" "$_cfdbg_welapsed"
        local _cfdbg_access
        _cfdbg_access=$(grep -o -E '(/clanfight(/[a-z]+/[^A-Za-z0-9]r[^A-Za-z0-9][0-9]+|/))' "$src_ram" | sed -n '1p')
        [ -z "$_cfdbg_access" ] && _cfdbg_access="/clanfight/"
        (
            w3mc -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 \
                -debug -dump_source "${URL}${_cfdbg_access}" \
                -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$src_ram"
        ) </dev/null &>/dev/null &
        time_exit 17
        _cfdbg_wait_n=$(( _cfdbg_wait_n + 1 ))
        _cfdbg_page "STATE: WAITING (poll #${_cfdbg_wait_n})"
        sleep 3s
    done
    printf '\n'

    if ! grep -q '/clanfight/dodge/' "$src_ram" 2>/dev/null; then
        printf "%b\n" "  ${RED_BLACK}(Timeout: battle did not start within 60s)${COLOR_RESET}"
        printf '\n(Timeout waiting for battle)\n' >> "$debug_file"
        rm -f "$src_ram" "$full_ram" "$_cfdbg_battle_history"
        cd - >/dev/null 2>&1; rm -rf "$tmp_ram"
        unset _cfdbg_page _cfdbg_action _cfdbg_extract
        return 1
    fi

    # ── Battle started ────────────────────────────────────────────────────
    local _cfdbg_battle_start
    printf -v _cfdbg_battle_start '%(%s)T' -1
    _cfdbg_extract

    local _cfdbg_team=""
    local _cfdbg_pfive
    _cfdbg_pfive=$(w3m -dump -T text/html "$src_ram" 2>/dev/null | head -n 5)
    if echo "$_cfdbg_pfive" | grep -q '\[1\]'; then _cfdbg_team="1"
    elif echo "$_cfdbg_pfive" | grep -q '\[0\]'; then _cfdbg_team="0"
    fi
    local _cfdbg_opponent
    _cfdbg_opponent=$(grep -o -E '([[:upper:]][[:lower:]]{0,20}( [[:upper:]][[:lower:]]{0,17})?)[[:space:]]\(' "$src_ram" | sed -n 's, [(],,;s, ,_,;2p')

    printf '\n'
    printf "  ${GREEN_BLACK}⚔️  CLANFIGHT vs %-16s [Team %s]${COLOR_RESET}\n" "${_cfdbg_opponent:-?}" "${_cfdbg_team:-?}"
    printf "  ${GRAY_BLACK}Max HP: %-6d  Enemy HP: %-6d${COLOR_RESET}\n" "$_cfdbg_maxhp" "$_cfdbg_ENH"
    {
        printf '\n============================================================\n'
        printf '=  BATTLE START\n'
        printf '============================================================\n'
        printf 'Timestamp: %(%Y-%m-%d %H:%M:%S)T\n' -1
        printf 'Opponent: %s  Team: [%s]  MaxHP: %s  EnemyHP: %s\n' \
            "${_cfdbg_opponent:-?}" "${_cfdbg_team:-?}" "${_cfdbg_maxhp:-?}" "${_cfdbg_ENH:-?}"
        printf '\n--- ACTION LOG ---\n'
        printf '%-10s %-4s %-38s %-14s %-14s\n' 'TIME' '#' 'ACTION' 'HP_before→after' 'ENH_before→after'
        printf '%s\n' '──────────────────────────────────────────────────────────────────────────'
    } >> "$debug_file"

    # ── Battle variables ─────────────────────────────────────────────────
    local _cfdbg_OLDHP="$_cfdbg_USH"
    local _cfdbg_last_heal=$(( _cfdbg_battle_start - 90 ))
    local _cfdbg_last_dodge=$(( _cfdbg_battle_start - 20 ))
    local _cfdbg_last_atk=$(( _cfdbg_battle_start - LA ))
    local _cfdbg_grass_used=0
    local _cfdbg_heals=0 _cfdbg_dodges=0 _cfdbg_atks=0 _cfdbg_atkrnds=0
    local _cfdbg_la_failures=0 _cfdbg_la_successes=0
    local _cfdbg_loop=0 _cfdbg_BREAK=0

    # ── Main battle loop ─────────────────────────────────────────────────
    while [ "$_cfdbg_BREAK" -eq 0 ]; do
        local _cfdbg_now
        printf -v _cfdbg_now '%(%s)T' -1
        local _cfdbg_elapsed=$(( _cfdbg_now - _cfdbg_battle_start ))
        local _cfdbg_min=$(( _cfdbg_elapsed / 60 ))
        local _cfdbg_sec=$(( _cfdbg_elapsed % 60 ))
        local _cfdbg_tsh=$(( _cfdbg_now - _cfdbg_last_heal ))
        local _cfdbg_tsd=$(( _cfdbg_now - _cfdbg_last_dodge ))
        local _cfdbg_tsa=$(( _cfdbg_now - _cfdbg_last_atk ))
        local _cfdbg_hp_before="$_cfdbg_USH"
        local _cfdbg_enh_before="$_cfdbg_ENH"
        local _cfdbg_action_label=""

        _cfdbg_loop=$(( _cfdbg_loop + 1 ))

        # Loop 10 full page dump
        if [ "$_cfdbg_loop" -eq 10 ]; then
            local _cfdbg_loop10_file="${debug_dir}/clanfight_debug_${debug_ts}_LOOP10_FULL_PAGE.txt"
            {
                printf '============================================================\n'
                printf '=  FULL PAGE DUMP AT LOOP 10\n'
                printf '============================================================\n'
                printf 'Timestamp: %(%Y-%m-%d %H:%M:%S)T\n' -1
                printf 'Loop: %d  |  Battle elapsed: %dm%ds\n\n' "$_cfdbg_loop" "$_cfdbg_min" "$_cfdbg_sec"
                printf '\n--- RENDERED HTML (w3m dump) ---\n'
                w3m -dump -T text/html "$src_ram" 2>/dev/null
                printf '\n--- RAW HTML SOURCE (first 3000 chars) ---\n'
                head -c 3000 "$src_ram" 2>/dev/null
            } > "$_cfdbg_loop10_file"
            printf "  ${GRAY_BLACK}[Loop 10 saved: %s]${COLOR_RESET}\n" "$_cfdbg_loop10_file" >&2
        fi

        # History capture every 3 loops
        if [ $(( _cfdbg_loop % 3 )) -eq 0 ]; then
            local _cfdbg_page_render
            local _cfdbg_hist_fmt
            printf -v _cfdbg_hist_fmt '%(%H:%M:%S)T' -1
            _cfdbg_page_render=$(w3m -dump -T text/html "$src_ram" 2>/dev/null)
            {
                printf '[Loop %d] %s\n' "$_cfdbg_loop" "$_cfdbg_hist_fmt"
                echo "$_cfdbg_page_render" | sed -n '/^Os participantes:/,/^A batalha já começou!/p' | \
                    grep -v '^$' | grep -v 'Os participantes:' | grep -v 'A batalha já começou'
            } >> "$_cfdbg_battle_history"
        fi

        # ── Extract values ──────────────────────────────────────────────────
        _cfdbg_extract

        # ── Detect hero death and revive (UNRIP) ─────────────────────────
        local _cfdbg_UNRIP
        _cfdbg_UNRIP=$(grep -o -E '/clanfight/unrip/[?]r[=][1-9][0-9]+' "$src_ram" 2>/dev/null | head -1)
        if [ -n "$_cfdbg_UNRIP" ] && [ "${_cfdbg_USH:-0}" -le 0 ]; then
            # Hero dead - revive and restart loop iteration
            (
                w3mc -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 \
                    -debug -dump_source "${URL}${_cfdbg_UNRIP}" \
                    -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$src_ram"
            ) </dev/null &>/dev/null &
            time_exit 17
            _cfdbg_extract
            _cfdbg_action "💀 UNRIP" "$_cfdbg_hp_before" "$_cfdbg_enh_before" \
                          "$_cfdbg_USH" "$_cfdbg_ENH"
            continue
        fi

        # ── Detect battle end (no dodge link) ────────────────────────────
        if ! grep -q '/clanfight/dodge/' "$src_ram" 2>/dev/null; then
            _cfdbg_BREAK=1; break
        fi

        # ── Priority 0: DODGE ────────────────────────────────────────────
        if ! grep -q 'txt smpl grey' "$src_ram" 2>/dev/null && \
           [ "$_cfdbg_tsd" -gt 20 ] && [ "$_cfdbg_tsd" -lt 300 ] && \
           awk -v ush="$_cfdbg_USH" -v old="$_cfdbg_OLDHP" 'BEGIN { exit !(ush+0 < old+0) }' && \
           [ -n "$_cfdbg_DODGE" ]; then
            (
                w3mc -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 \
                    -debug -dump_source "${URL}${_cfdbg_DODGE}" \
                    -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$src_ram"
            ) </dev/null &>/dev/null &
            time_exit 17
            _cfdbg_extract; _cfdbg_OLDHP="$_cfdbg_USH"; _cfdbg_last_dodge=$_cfdbg_now; _cfdbg_last_atk=$_cfdbg_now
            _cfdbg_dodges=$(( _cfdbg_dodges + 1 ))
            _cfdbg_action_label="🛡️ DODGE"

        # ── Priority 1: HEAL + GRASS ─────────────────────────────────────
        elif awk -v ush="${_cfdbg_USH:-0}" -v hlhp="$_cfdbg_HLHP" 'BEGIN { exit !(ush+0 < hlhp+0) }' && \
             [ "$_cfdbg_tsh" -gt 90 ] && [ "$_cfdbg_tsh" -lt 300 ] && [ -n "$_cfdbg_HEAL" ]; then
            (
                w3mc -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 \
                    -debug -dump_source "${URL}${_cfdbg_HEAL}" \
                    -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$src_ram"
            ) </dev/null &>/dev/null &
            time_exit 17
            sleep 0.3s
            if [ -n "$_cfdbg_GRASS" ] && [ "$_cfdbg_grass_used" -eq 0 ]; then
                (
                    w3mc -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 \
                        -debug -dump_source "${URL}${_cfdbg_GRASS}" \
                        -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$src_ram"
                ) </dev/null &>/dev/null &
                time_exit 17
                _cfdbg_grass_used=1
                _cfdbg_action_label="💚 HEAL + 🌿 GRASS"
            else
                _cfdbg_action_label="💚 HEAL"
            fi
            _cfdbg_extract; _cfdbg_last_heal=$_cfdbg_now; _cfdbg_last_atk=$_cfdbg_now
            _cfdbg_heals=$(( _cfdbg_heals + 1 ))

        # ── Priority 2: ATKRND ───────────────────────────────────────────
        elif awk -v t="$_cfdbg_tsa" -v la="${LA%%.*}" 'BEGIN { exit !(t+0 >= la+0) }' && \
             ! grep -q 'txt smpl grey' "$src_ram" 2>/dev/null && [ -n "$_cfdbg_ATKRND" ] && \
             { awk -v rhp="$_cfdbg_RHP" -v enh="${_cfdbg_ENH:-0}" 'BEGIN { exit !(rhp+0 < enh+0) }' || \
               grep -q "$(grep -o -E '([[:upper:]][[:lower:]]{0,20}( [[:upper:]][[:lower:]]{0,17})?)[[:space:]]\(' "$src_ram" | sed -n 's, [(],,;s, ,_,;1p')" "$tmp_ram/callies.txt" 2>/dev/null; }; then
            (
                w3mc -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 \
                    -debug -dump_source "${URL}${_cfdbg_ATKRND}" \
                    -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$src_ram"
            ) </dev/null &>/dev/null &
            time_exit 17
            _cfdbg_extract; _cfdbg_last_atk=$_cfdbg_now
            _cfdbg_atkrnds=$(( _cfdbg_atkrnds + 1 ))
            _cfdbg_action_label="🎲 ATKRND (ENH:${_cfdbg_enh_before}→${_cfdbg_ENH})"

        # ── Priority 3: ATK ──────────────────────────────────────────────
        elif awk -v t="$_cfdbg_tsa" -v la="${LA%%.*}" 'BEGIN { exit !(t+0 >= la+0) }' && \
             [ -n "$_cfdbg_ATK" ]; then
            local _cfdbg_prev_enh="$_cfdbg_ENH"
            local _cfdbg_prev_atk="$_cfdbg_ATK"
            (
                w3mc -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 \
                    -debug -dump_source "${URL}${_cfdbg_ATK}" \
                    -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$src_ram"
            ) </dev/null &>/dev/null &
            time_exit 17
            _cfdbg_extract; _cfdbg_last_atk=$_cfdbg_now

            local _cfdbg_rcheck
            _cfdbg_rcheck=$(w3m -dump -T text/html "$src_ram" 2>/dev/null | head -n 20)
            if echo "$_cfdbg_rcheck" | grep -q -i -E 'perdeu|falhou|failed|cooldown|too fast'; then
                _cfdbg_la_failures=$(( _cfdbg_la_failures + 1 ))
                _cfdbg_la_successes=0
                LA=$(awk -v la="$LA" 'BEGIN { printf "%.1f", la + 0.2 }')
                _cfdbg_action_label="⚔️ ATK → MISS ❌ (LA→${LA}s)"
            else
                _cfdbg_la_successes=$(( _cfdbg_la_successes + 1 ))
                _cfdbg_atks=$(( _cfdbg_atks + 1 ))
                _cfdbg_action_label="⚔️ ATK → HIT ✓ (ENH:${_cfdbg_prev_enh}→${_cfdbg_ENH})"
                if [ "$_cfdbg_la_successes" -ge 10 ] && \
                   awk -v la="$LA" 'BEGIN { exit !(la > 4.0) }'; then
                    LA=$(awk -v la="$LA" 'BEGIN { printf "%.1f", la - 0.1 }')
                    _cfdbg_action_label="${_cfdbg_action_label} LA↓${LA}s"
                    _cfdbg_la_successes=0
                fi
            fi

        # ── Priority 4: REFRESH ──────────────────────────────────────────
        else
            (
                w3mc -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 \
                    -debug -dump_source "${URL}/clanfight" \
                    -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$src_ram"
            ) </dev/null &>/dev/null &
            time_exit 17
            _cfdbg_extract
            _cfdbg_action_label="🔄 REFRESH"
            sleep 1s
        fi

        _cfdbg_action "$_cfdbg_action_label" "$_cfdbg_hp_before" "$_cfdbg_enh_before" \
                      "$_cfdbg_USH" "$_cfdbg_ENH"

        # ── Terminal display ─────────────────────────────────────────────
        local _cfdbg_hp_pct
        _cfdbg_hp_pct=$(awk -v c="${_cfdbg_USH:-0}" -v m="${_cfdbg_maxhp:-30000}" \
                        'BEGIN { m=(m+0>0)?m:30000; v=c/m*100; if(v<0)v=0; if(v>100)v=100; printf "%.0f", v }')
        local _cfdbg_bfill
        _cfdbg_bfill=$(awk -v p="$_cfdbg_hp_pct" 'BEGIN { v=int(p*16/100); if(v<0)v=0; if(v>16)v=16; print v }')
        local _cfdbg_bar="" _cfdbg_j
        for (( _cfdbg_j=0; _cfdbg_j<_cfdbg_bfill; _cfdbg_j++ )); do _cfdbg_bar+="█"; done
        for (( _cfdbg_j=0; _cfdbg_j<(16-_cfdbg_bfill); _cfdbg_j++ )); do _cfdbg_bar+="░"; done
        local _cfdbg_hcol
        if [ "$_cfdbg_hp_pct" -gt 60 ] 2>/dev/null; then _cfdbg_hcol="$GREEN_BLACK"
        elif [ "$_cfdbg_hp_pct" -gt 30 ] 2>/dev/null; then _cfdbg_hcol="$GOLD_BLACK"
        else _cfdbg_hcol="$RED_BLACK"; fi

        local _cfdbg_grass_st
        [ "$_cfdbg_grass_used" -eq 0 ] \
            && _cfdbg_grass_st="${GREEN_BLACK}READY${COLOR_RESET}" \
            || _cfdbg_grass_st="${GRAY_BLACK}USED${COLOR_RESET}"

        printf "\n  ${GOLD_BLACK}══ CLANFIGHT DEBUG ${_cfdbg_min}m${_cfdbg_sec}s (loop #${_cfdbg_loop}) ══${COLOR_RESET}\n"
        printf "  ${_cfdbg_hcol}HP: %-5d/%-5d${COLOR_RESET} [${_cfdbg_bar}] %-3d%%\n" "$_cfdbg_USH" "$_cfdbg_maxhp" "$_cfdbg_hp_pct"
        printf "  ${GRAY_BLACK}VS: %-16s  ENH: %-6d  Team:[%s]${COLOR_RESET}\n" "${_cfdbg_opponent:-?}" "$_cfdbg_ENH" "${_cfdbg_team:-?}"
        printf "  ${GRAY_BLACK}────────────────────────────────${COLOR_RESET}\n"
        printf "  ${_cfdbg_action_label}\n"
        local _cfdbg_heal_info
        if [ "$_cfdbg_tsh" -lt 90 ]; then
            _cfdbg_heal_info="${GOLD_BLACK}⏳$(( 90 - _cfdbg_tsh ))s${COLOR_RESET}"
        else
            _cfdbg_heal_info="${GREEN_BLACK}READY${COLOR_RESET}"
        fi
        printf "  ${GRAY_BLACK}LA: %-4s  HPER: %-2d%%  Heal: ${_cfdbg_heal_info}  Fails: %-2d${COLOR_RESET}\n" "$LA" "$HPER" "$_cfdbg_la_failures"
        printf "  ${GRAY_BLACK}────────────────────────────────${COLOR_RESET}\n"
        printf "  ${GREEN_BLACK}ATK: %-3d  RND: %-3d  DODGE: %-3d  HEAL: %-3d${COLOR_RESET}  🌿 Grass: ${_cfdbg_grass_st}\n" "$_cfdbg_atks" "$_cfdbg_atkrnds" "$_cfdbg_dodges" "$_cfdbg_heals"
        printf "  ${GRAY_BLACK}─── PARTICIPANTS ───${COLOR_RESET}\n"
        w3m -dump -T text/html "$src_ram" 2>/dev/null | \
            grep "Os participantes:" | \
            sed 's|\[0\]|🔴|g; s|\[1\]|🔵|g; s|\[health\]|🧡|g' | \
            while IFS= read -r logline; do printf "  ${GRAY_BLACK}%s${COLOR_RESET}\n" "$logline"; done
        printf "  ${GRAY_BLACK}─── BATTLE LOG ───${COLOR_RESET}\n"
        local _cfdbg_prender
        _cfdbg_prender=$(w3m -dump -T text/html "$src_ram" 2>/dev/null)
        echo "$_cfdbg_prender" | sed -n '/^Os participantes:/,/^A batalha já começou!/p' | \
            grep -v '^$' | grep -v 'Os participantes:' | grep -v 'A batalha já começou' | \
            sed 's|\[0\]|🔴|g; s|\[1\]|🔵|g; s|\[rip\]|💀|g; s|assassinou|💥|; s|perdeu|❌|; s|Você acertar|✓|; s|Você usou|⚡|' | \
            tail -n 8 | \
            while IFS= read -r logline; do printf "  ${GRAY_BLACK}%s${COLOR_RESET}\n" "$logline"; done
    done

    # ── Post-battle ──────────────────────────────────────────────────────
    local _cfdbg_end; printf -v _cfdbg_end '%(%s)T' -1
    local _cfdbg_dur=$(( _cfdbg_end - _cfdbg_battle_start ))
    local _cfdbg_dmin=$(( _cfdbg_dur / 60 )) _cfdbg_dsec=$(( _cfdbg_dur % 60 ))
    _cfdbg_page "STATE: POST-BATTLE"

    local _cfdbg_result="unknown"
    local _cfdbg_rend
    _cfdbg_rend=$(w3m -dump -T text/html "$src_ram" 2>/dev/null)
    if echo "$_cfdbg_rend" | grep -q -i -E 'vit[oó]ria|victory'; then _cfdbg_result="WIN"
    elif echo "$_cfdbg_rend" | grep -q -i -E 'derrota|defeat'; then _cfdbg_result="LOSS"
    fi

    printf "\n"
    printf "  ${GOLD_BLACK}╔══════════════════════════════════════════════════════════╗${COLOR_RESET}\n"
    printf "  ${GOLD_BLACK}║             CLANFIGHT BATTLE SUMMARY  ⚔️                 ║${COLOR_RESET}\n"
    printf "  ${GOLD_BLACK}╠══════════════════════════════════════════════════════════╣${COLOR_RESET}\n"
    if [ "$_cfdbg_result" = "WIN" ]; then
        printf "  ${GREEN_BLACK}║     ✅  VICTORY!                                       ║${COLOR_RESET}\n"
    elif [ "$_cfdbg_result" = "LOSS" ]; then
        printf "  ${RED_BLACK}║     ❌  DEFEAT                                         ║${COLOR_RESET}\n"
    else
        printf "  ${GOLD_BLACK}║     ❓  RESULT UNKNOWN                                 ║${COLOR_RESET}\n"
    fi
    printf "  ${GOLD_BLACK}╠══════════════════════════════════════════════════════════╣${COLOR_RESET}\n"
    printf "  ${GRAY_BLACK}║ Duration:${GOLD_BLACK} %-3dm%-3ds${GRAY_BLACK}  |  Loops:${GOLD_BLACK} %-5d${GRAY_BLACK}  |  Opponent:${GOLD_BLACK} %-14s${GRAY_BLACK}║${COLOR_RESET}\n" "$_cfdbg_dmin" "$_cfdbg_dsec" "$_cfdbg_loop" "${_cfdbg_opponent:-?}"
    printf "  ${GOLD_BLACK}╠══════════════════════════════════════════════════════════╣${COLOR_RESET}\n"
    printf "  ${GRAY_BLACK}║ ACTIONS:${COLOR_RESET}\n"
    printf "  ${GRAY_BLACK}║   ATK:${GREEN_BLACK}%-3d${GRAY_BLACK}  RND:${GREEN_BLACK}%-3d${GRAY_BLACK}  DODGE:${GREEN_BLACK}%-3d${GRAY_BLACK}  HEAL:${GREEN_BLACK}%-3d${GRAY_BLACK}  Grass:%d${COLOR_RESET}\n" "$_cfdbg_atks" "$_cfdbg_atkrnds" "$_cfdbg_dodges" "$_cfdbg_heals" "$_cfdbg_grass_used"
    printf "  ${GOLD_BLACK}╠══════════════════════════════════════════════════════════╣${COLOR_RESET}\n"
    printf "  ${GRAY_BLACK}║ LA: Start 4s  |  End: ${LA}s  |  Fails: ${RED_BLACK}%-2d${GRAY_BLACK}  |  HPER: %d%%${COLOR_RESET}\n" "$_cfdbg_la_failures" "$HPER"
    local _cfdbg_cfails=$(grep -c "perdeu" "$_cfdbg_battle_history" 2>/dev/null || echo "0")
    local _cfdbg_ckills=$(grep -c "assassinou" "$_cfdbg_battle_history" 2>/dev/null || echo "0")
    printf "  ${GRAY_BLACK}║   Fails from log:${RED_BLACK}%-2d${GRAY_BLACK}  |  Kills from log:${GREEN_BLACK}%-2d${COLOR_RESET}\n" "$_cfdbg_cfails" "$_cfdbg_ckills"
    printf "  ${GOLD_BLACK}╠══════════════════════════════════════════════════════════╣${COLOR_RESET}\n"
    printf "  ${GRAY_BLACK}║ Debug file: ${GOLD_BLACK}%-46s${GRAY_BLACK}║${COLOR_RESET}\n" "${debug_file##*/}"
    printf "  ${GOLD_BLACK}╚══════════════════════════════════════════════════════════╝${COLOR_RESET}\n"
    printf "\n  ${GRAY_BLACK}(closing in 10 seconds...)${COLOR_RESET}\n"
    sleep 10s

    {
        printf '\n============================================================\n'
        printf '=  BATTLE SUMMARY\n'
        printf '============================================================\n'
        printf 'Result: %s\n' "$_cfdbg_result"
        printf 'Duration: %dm %ds  |  Loops: %d\n' "$_cfdbg_dmin" "$_cfdbg_dsec" "$_cfdbg_loop"
        printf 'ATK:%d  RND:%d  DODGE:%d  HEAL:%d  Grass:%d\n' \
            "$_cfdbg_atks" "$_cfdbg_atkrnds" "$_cfdbg_dodges" "$_cfdbg_heals" "$_cfdbg_grass_used"
        printf 'ATK Fails:%d  LA Start:4  LA End:%s\n' "$_cfdbg_la_failures" "$LA"
        printf '\n--- BATTLE HISTORY (captured during battle) ---\n'
        if [ -f "$_cfdbg_battle_history" ] && [ -s "$_cfdbg_battle_history" ]; then
            cat "$_cfdbg_battle_history"
        else
            printf '(no history captured)\n'
        fi
        local _cfdbg_real_fails
        _cfdbg_real_fails=$(grep -c "perdeu" "$_cfdbg_battle_history" 2>/dev/null || echo "0")
        local _cfdbg_real_kills
        _cfdbg_real_kills=$(grep -c "assassinou" "$_cfdbg_battle_history" 2>/dev/null || echo "0")
        printf '\n--- ATTACK ANALYSIS ---\n'
        printf 'Você perdeu (fails detected): %d\n' "$_cfdbg_real_fails"
        printf 'Você assassinou (kills): %d\n' "$_cfdbg_real_kills"
        printf '\n--- DEBUG ARTIFACTS ---\n'
        printf 'Full page dump at Loop 10: clanfight_debug_%s_LOOP10_FULL_PAGE.txt\n' "$debug_ts"
    } >> "$debug_file"

    rm -f "$src_ram" "$full_ram" "$_cfdbg_battle_history"
    cd - >/dev/null 2>&1; rm -rf "$tmp_ram"
    unset _cfdbg_page _cfdbg_action _cfdbg_extract
    unset _cfdbg_USH _cfdbg_ENH _cfdbg_ATK _cfdbg_ATKRND _cfdbg_DODGE _cfdbg_HEAL _cfdbg_GRASS _cfdbg_RHP _cfdbg_HLHP
}
clanfight_start() {
  cd $TMP || exit
  case $(date +%H:%M) in
  10:5[5-9] | 18:5[5-9])
    (
      w3mc -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "$URL/train" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" | grep -o -E '\(([0-9]+)\)' | sed 's/[()]//g' >"$TMP"/FULL
    ) </dev/null &>/dev/null &
    time_exit 17
    (
      w3mc -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "$URL/clanfight/?close=reward" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
    ) </dev/null &>/dev/null &
    time_exit 17
    (
      w3mc -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "$URL/clanfight/enterFight" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
    ) </dev/null &>/dev/null &
    time_exit 17
    echo_t "The clan tournament will be started..." "${GOLD_BLACK}" "${COLOR_RESET}"
    while $(case $(date +%M:%S) in (59:[3-5][0-9]) exit 1 ;; esac) ; do
      sleep 3
    done
    (
      w3mc -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "$URL/clanfight/enterFight" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
    ) </dev/null &>/dev/null &
    time_exit 17
    #printf "\nClan fight\n$URL\n"
    grep -o -E '(/[a-z]+(/[a-z]+/[^A-Za-z0-9]r[^A-Za-z0-9][0-9]+|/))' "$TMP"/SRC | sed -n '1p' >ACCESS 2>/dev/null
    echo_t " Entering..." "" "\n" "before" " 👣"
    #/wait
    echo_t " Waiting..." "" "\n" "before" " 😴"
    local BREAK=$(($(date +%s) + 60))
    until grep -q -o 'clanfight/dodge/' ACCESS || [ "$(date +%s)" -gt "$BREAK" ]; do
      printf " 💤	...\n$(cat ACCESS)\n"
      (
        w3mc -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}/clanfight/" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
      ) </dev/null &>/dev/null &
      time_exit 17
      grep -o -E '(/clanfight(/[a-z]+/[^A-Za-z0-9]r[^A-Za-z0-9][0-9]+|/))' "$TMP"/SRC | sed -n '1p' >ACCESS 2>/dev/null
      sleep 3
    done
    clanfight_debug
    ;;
  esac
}
