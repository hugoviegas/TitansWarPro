# shellcheck disable=SC2148
king_fight () {

  #/enterFight
  cd "$TMP" || exit
  local LA=4 # interval attack
  local HPER="38" # % to heal
  local RPER=5 # % to random
  cl_access () {
  #  sed -n 's/.*\(\/[a-z]\{3,12\}\/[A-Za-z]\{3,12\}\/[^[:alnum:]][a-z]\{1,3\}[^[:alnum:]][0-9]\+\).*/\1/p'
  #  sed -n 's/.*\(\/king\/attack\/[^A-Za-z0-9_]r[^A-Za-z0-9_][0-9]\+\).*/\1/p' $TMP/SRC|sed -n 1p >ATK 2> /dev/null
  grep -o -E '(/king/attack/[?]r[=][0-9]+)' "$TMP"/SRC|sed -n 1p >ATK 2> /dev/null
  grep -o -E '(/king/kingatk/[?]r[=][0-9]+)' "$TMP"/SRC|sed -n 1p >KINGATK 2> /dev/null
  grep -o -E '(/king/at[a-z]{0,3}k[a-z]{3,6}/[?]r[=][0-9]+)' "$TMP"/SRC >ATKRND 2> /dev/null
  grep -o -E '(/king/dodge/[?]r[=][0-9]+)' "$TMP"/SRC >DODGE 2> /dev/null
  grep -o -E '(/king/stone/[?]r[=][0-9]+)' "$TMP"/SRC >STONE 2> /dev/null
  grep -o -E '(/king/heal/[?]r[=][0-9]+)' "$TMP"/SRC >HEAL 2> /dev/null
  # grep -o -E '(/king/grass/[?]r[=][0-9]+)' "$TMP"/SRC >GRASS 2> /dev/null
  grep -o -E '([[:upper:]][[:lower:]]{0,15}( [[:upper:]][[:lower:]]{0,13})?)[[:space:]][^[:alnum:][:space:]]' "$TMP"/SRC|sed -n 's,\ [<]s,,;s,\ ,_,;2p' >USER 2> /dev/null
#  grep -o -P "\p{Lu}{1}\p{Ll}{0,15}[\ ]{0,1}\p{L}{0,14}\s\Ws" $TMP/SRC|sed -n 's,\ [<]s,,;s,\ ,_,;2p' >USER 2> /dev/null
  grep -o -E "(hp)[^A-Za-z0-9_]{1,4}[0-9]{1,6}" "$TMP"/SRC|sed "s,hp[']\/[>],,;s,\ ,," >HP 2> /dev/null
  grep -o -E "(nbsp)[^A-Za-z0-9_]{1,2}[0-9]{1,6}" "$TMP"/SRC|sed -n 's,nbsp[;],,;s,\ ,,;1p' >HP2 2> /dev/null
  RHP=$(awk -v ush="$(cat HP)" -v rper="$RPER" 'BEGIN { printf "%.0f", ush * rper / 100 + ush }')
  HLHP=$(awk -v ush="$(cat FULL)" -v hper="$HPER" 'BEGIN { printf "%.0f", ush * hper / 100 }')
  if grep -q -o '/dodge/' "$TMP"/SRC ; then
   printf "\n     🙇‍ "
   w3m -dump -T text/html "$TMP/SRC"|head -n 18|sed '0,/^\([a-z]\{2\}\)[[:space:]]\([0-9]\{1,6\}\)\([0-9]\{2\}\):\([0-9]\{2\}\)/s//\♥️\2 ⏰\3:\4/;s,\[0\],\🔴,g;s,\[1\]\ ,\🔵,g;s,\[king\],👑,g;s,\[stone\],\ 💪,;s,\[herb\],\ 🌿,;s,\[grass\],\ 🌿,g;s,\[potio\],\ 💊,;s,\ \[health\]\ ,\ 🧡,;s,\ \[icon\]\ ,\ 🐾,g;s,\[rip\]\ ,\ 💀,g'
  else
   (
    w3mc -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}/king" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
   ) </dev/null &>/dev/null &
   time_exit 17
   #/king/unrip/?r=1682796653
   grep -o -E '(/king/unrip/[^A-Za-z0-9_]r[^A-Za-z0-9_][0-9]+)' "$TMP"/SRC >UNRIP 2> /dev/null
   if grep -q -o -E '(/king/unrip/[^A-Za-z0-9_]r[^A-Za-z0-9_][0-9]+)' "$TMP"/SRC ; then
    (
     w3mc -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}$(cat UNRIP)" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
    ) </dev/null &>/dev/null &
    time_exit 17
   else
    echo 1 >BREAK_LOOP
    echo -e "${RED_BLACK}Battle over.${COLOR_RESET}\n"
    sleep 3s
   fi
  fi
 }
 cl_access
 cat HP >old_HP
 echo $(( $(date +%s) - 20 )) >last_dodge
 echo $(( $(date +%s) - 90 )) >last_heal
 echo $(( $(date +%s) - LA )) >last_atk
 : >BREAK_LOOP
 until [ -s "BREAK_LOOP" ] ; do
 : >BREAK_LOOP
  #/dodge
  if ! grep -q -o 'txt smpl grey' "$TMP"/SRC && [ "$(( $(date +%s) - $(cat last_dodge) ))" -gt 20 ] && [ "$(( $(date +%s) - $(cat last_dodge) ))" -lt 300 ] && awk -v ush="$(cat HP)" -v oldhp="$(cat old_HP)" 'BEGIN { exit !(ush < oldhp) }' ; then
   (
    w3mc -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}$(cat DODGE)" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
   ) </dev/null &>/dev/null &
   time_exit 17
   cl_access
   cat HP >old_HP ; date +%s >last_dodge
  #/heal
  elif awk -v ush="$(cat HP)" -v hlhp="$HLHP" 'BEGIN { exit !(ush < hlhp) }' && [ "$(( $(date +%s) - $(cat last_heal) ))" -gt 90 ] && [ "$(( $(date +%s) - $(cat last_heal) ))" -lt 300 ] ; then
   (
    w3mc -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}$(cat HEAL)" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
   ) </dev/null &>/dev/null &
   time_exit 17
   cl_access
   cat HP >FULL ; date +%s >last_heal
  sleep 0.3s
  #/attack_all
  elif awk -v latk="$(( $(date +%s) - $(cat last_atk) ))" -v atktime="$LA" 'BEGIN { exit !(latk > atktime) }' ; then
   if grep -q -o -E '(king/kingatk/[^A-Za-z0-9_]r[^A-Za-z0-9_][0-9]+)' "$TMP"/SRC ; then  #kingatk...
    (
     w3mc -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}$(cat KINGATK)" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
    ) </dev/null &>/dev/null &
    time_exit 17
    cl_access
    #stone...
     if awk -v ush="$(cat HP2)" 'BEGIN { exit !(ush < 25) }' ; then
     (
      w3mc -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}$(cat STONE)" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
     ) </dev/null &>/dev/null &
     time_exit 17
     cl_access
    fi #...stone
   else #...kingatk
    #/random
    if awk -v latk="$(( $(date +%s) - $(cat last_atk) ))" -v atktime="$LA" 'BEGIN { exit !(latk != atktime) }' && ! grep -q -o 'txt smpl grey' "$TMP"/SRC && awk -v rhp="$RHP" -v enh="$(cat HP2)" 'BEGIN { exit !(rhp < enh) }' || awk -v latk="$(( $(date +%s) - $(cat last_atk) ))" -v atktime="$LA" 'BEGIN { exit !(latk != atktime) }' && ! grep -q -o 'txt smpl grey' "$TMP"/SRC && grep -q -o "$(cat USER)" allies.txt ; then
     (
      w3mc -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}$(cat ATKRND)" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
     ) </dev/null &>/dev/null &
     time_exit 17
     cl_access
     date +%s >last_atk
    fi
    #/atk...
    (
     w3mc -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}$(cat ATK)" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
    ) </dev/null &>/dev/null &
    time_exit 17
    cl_access
   fi #...atk
   date +%s >last_atk
  else #...attack_all
   (
  w3mc -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}/king" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
   ) </dev/null &>/dev/null &
   time_exit 17
   cl_access
   sleep 1s
  fi
 done
 unset cl_access
 func_unset
 apply_event
 echo -e "${RED_BLACK}👑King ✅${COLOR_RESET}"
 sleep 10s
 [ -t 1 ] && clear
}
king_debug () {
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
    local _kdbg_battle_history
    _kdbg_battle_history=$(mktemp -p "$dir_ram" history.XXXXXX)
    cp -r "$TMP"/* "$tmp_ram" 2>/dev/null
    cd "$tmp_ram" || return 1

    # Load config with defaults (no KING_LA yet; use COLISEUM_LA as fallback or 4)
    local LA="${KING_LA:-4}"
    local HPER="${KING_HPER:-38}"
    local RPER="${KING_RPER:-5}"

    # ── Helper: log a page state to debug file ───────────────────────────
    _kdbg_page() {
        local label="$1"
        {
            printf '\n============================================================\n'
            printf '=  %s\n' "$label"
            printf '============================================================\n'
            printf 'Timestamp: %(%Y-%m-%d %H:%M:%S)T\n' -1
            printf '\n--- W3M RENDERED DUMP ---\n'
            w3m -dump -T text/html "$src_ram" 2>/dev/null
            printf '\n--- EXTRACTED LINKS ---\n'
            grep -o -E '/king/[A-Za-z]+(/[?]r[=][0-9]+)?' "$src_ram" 2>/dev/null
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
            printf 'Enemy HP%%: %s\n' "$(grep -o -E '(nbsp)[^A-Za-z0-9]{1,2}[0-9]{1,6}' "$src_ram" 2>/dev/null | sed -n 's,nbsp[;],,;s, ,,;1p')"
            printf '\n--- MARKERS ---\n'
            printf 'dodge:%s  unrip:%s  grey:%s  rip:%s  kingatk:%s\n' \
                "$(grep -c '/dodge/' "$src_ram" 2>/dev/null)" \
                "$(grep -c '/king/unrip/' "$src_ram" 2>/dev/null)" \
                "$(grep -c 'txt smpl grey' "$src_ram" 2>/dev/null)" \
                "$(grep -c '\[rip\]' "$src_ram" 2>/dev/null)" \
                "$(grep -c 'king/kingatk/' "$src_ram" 2>/dev/null)"
            printf '\n--- KEYWORD SEARCH ---\n'
            w3m -dump -T text/html "$src_ram" 2>/dev/null | \
                grep -i -E 'vit[oó]ria|victory|defeat|derrota|perdeu|ganhou|venceu' 2>/dev/null || true
        } >> "$debug_file"
    }

    # ── Helper: log a battle action ──────────────────────────────────────
    _kdbg_action() {
        local action_label="$1" ush_before="$2" enh_before="$3" ush_after="$4" enh_after="$5"
        local ts
        printf -v ts '%(%H:%M:%S)T' -1
        {
            printf '[%s] #%d | %s\n' "$ts" "$_kdbg_loop" "$action_label"
            printf '       HP: %s→%s  ENH%%: %s→%s  LA:%ss  HPER:%s%%  RPER:%s%%\n' \
                "$ush_before" "${ush_after:--}" "$enh_before" "${enh_after:--}" \
                "$LA" "$HPER" "$RPER"
        } >> "$debug_file"
    }

    # ── Helper: extract current page data ────────────────────────────────
    local _kdbg_USH _kdbg_ENH _kdbg_ATK _kdbg_KINGATK _kdbg_ATKRND
    local _kdbg_DODGE _kdbg_STONE _kdbg_HEAL _kdbg_UNRIP _kdbg_RHP _kdbg_HLHP
    _kdbg_extract() {
        _kdbg_USH=$(grep -o -E '(hp)[^A-Za-z0-9]{1,4}[0-9]{2,5}' "$src_ram" | grep -o -E '[0-9]{2,5}' | sed 's, ,,g' | head -1)
        _kdbg_ENH=$(grep -o -E '(nbsp)[^A-Za-z0-9]{1,2}[0-9]{1,6}' "$src_ram" | sed -n 's,nbsp[;],,;s, ,,;1p')
        _kdbg_ATK=$(grep -o -E '/king/attack/[?]r[=][0-9]+' "$src_ram" | head -1)
        _kdbg_KINGATK=$(grep -o -E '/king/kingatk/[?]r[=][0-9]+' "$src_ram")
        _kdbg_ATKRND=$(grep -o -E '/king/at[a-z]{0,3}k[a-z]{3,6}/[?]r[=][0-9]+' "$src_ram")
        _kdbg_DODGE=$(grep -o -E '/king/dodge/[?]r[=][0-9]+' "$src_ram")
        _kdbg_STONE=$(grep -o -E '/king/stone/[?]r[=][0-9]+' "$src_ram")
        _kdbg_HEAL=$(grep -o -E '/king/heal/[?]r[=][0-9]+' "$src_ram")
        _kdbg_UNRIP=$(grep -o -E '/king/unrip/[^A-Za-z0-9_]r[^A-Za-z0-9_][0-9]+' "$src_ram")
        _kdbg_RHP=$(awk -v ush="${_kdbg_USH:-0}" -v rper="$RPER" 'BEGIN { printf "%.0f", ush * rper / 100 + ush }')
        _kdbg_HLHP=$(awk -v ush="${_kdbg_maxhp:-0}" -v hper="$HPER" 'BEGIN { printf "%.0f", ush * hper / 100 }')
    }

    # ── Write debug file header ───────────────────────────────────────────
    {
        printf 'King Debug Log - %(%Y-%m-%d %H:%M:%S)T\n' -1
        printf 'Server: %s  Account: %s\n' "$URL" "${ACCOUNT_ID:-unknown}"
        printf '\n--- CONFIG ---\n'
        printf 'LA=%ss  HPER=%s%%  RPER=%s%%\n' "$LA" "$HPER" "$RPER"
    } > "$debug_file"

    # ── Terminal pre-battle panel ─────────────────────────────────────────
    printf "\n  ${GOLD_BLACK}╔══════════════════════════════════════╗${COLOR_RESET}\n"
    printf "  ${GOLD_BLACK}║     KING  DEBUG  MODE  👑             ║${COLOR_RESET}\n"
    printf "  ${GOLD_BLACK}╠══════════════════════════════════════╣${COLOR_RESET}\n"
    printf "  ${GOLD_BLACK}║ LA: %-5s  HPER: %-3d%%  RPER: %-3d%%      ║${COLOR_RESET}\n" "$LA" "$HPER" "$RPER"
    printf "  ${GOLD_BLACK}╚══════════════════════════════════════╝${COLOR_RESET}\n"

    # ── Get max HP from /train ─────────────────────────────────────────────
    (
        w3mc -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 \
            -debug -dump_source "$URL/train" \
            -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" | \
            grep -o -E '\(([0-9]+)\)' | sed 's/[()]//g' >"$full_ram"
    ) &
    time_exit 20
    local _kdbg_maxhp
    _kdbg_maxhp=$(cat "$full_ram" 2>/dev/null)
    printf "  ${GRAY_BLACK}Max HP: %-6d${COLOR_RESET}\n" "$_kdbg_maxhp"
    printf '\n--- MAX HP ---\nMax HP: %s\n' "$_kdbg_maxhp" >> "$debug_file"

    # Set graphics to 0 for clean HTML
    (
        w3mc -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 \
            -debug "$URL/settings/graphics/0" \
            -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >>"$src_ram"
    ) </dev/null &>/dev/null &
    time_exit 17

    # ── Enter game ────────────────────────────────────────────────────────
    printf "  ${GOLD_BLACK}👑 Entering King of the Immortals...${COLOR_RESET}\n"
    (
        w3mc -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 \
            -debug -dump_source "$URL/king/enterGame" \
            -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$src_ram"
    ) </dev/null &>/dev/null &
    time_exit 17
    _kdbg_page "STATE: ENTER GAME"

    # Get access link for waiting
    local _kdbg_access
    _kdbg_access=$(grep -o -E '(/[a-z]+(/[a-z]+/[^A-Za-z0-9]r[^A-Za-z0-9][0-9]+|/))' "$src_ram" | sed -n '1p')
    [ -z "$_kdbg_access" ] && _kdbg_access="/king"

    # ── Wait for battle start (kingatk link = battle is live) ─────────────
    printf "  ${GOLD_BLACK}😴 Waiting for battle to start...${COLOR_RESET}\n"
    local _kdbg_wait_start
    _kdbg_wait_start=$(date +%s)
    local _kdbg_wait_n=0
    cat "$src_ram" | grep -o 'king/kingatk/' >/dev/null 2>&1 ; local _kdbg_has_kingatk=$?
    until [ "$_kdbg_has_kingatk" -eq 0 ] || [ $(( $(date +%s) - _kdbg_wait_start )) -gt 60 ]; do
        local _kdbg_welapsed=$(( $(date +%s) - _kdbg_wait_start ))
        printf "\r\033[K  ${GOLD_BLACK}⏳ Waiting... [%02ds]${COLOR_RESET}" "$_kdbg_welapsed"
        _kdbg_access=$(cat "$src_ram" | sed 's/href=/\n/g' | grep '/king/' | head -n 1 | awk -F"[']" '{ print $2 }')
        [ -z "$_kdbg_access" ] && _kdbg_access="/king"
        (
            w3mc -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 \
                -debug -dump_source "${URL}${_kdbg_access}" \
                -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$src_ram"
        ) </dev/null &>/dev/null &
        time_exit 17
        _kdbg_wait_n=$(( _kdbg_wait_n + 1 ))
        _kdbg_page "STATE: WAITING (poll #${_kdbg_wait_n})"
        cat "$src_ram" | grep -o 'king/kingatk/' >/dev/null 2>&1 ; _kdbg_has_kingatk=$?
        sleep 2s
    done
    printf '\n'

    if [ "$_kdbg_has_kingatk" -ne 0 ]; then
        printf "%b\n" "  ${RED_BLACK}(Timeout: battle did not start within 60s)${COLOR_RESET}"
        printf '\n(Timeout waiting for battle)\n' >> "$debug_file"
        rm -f "$src_ram" "$full_ram" "$_kdbg_battle_history"
        cd - >/dev/null 2>&1; rm -rf "$tmp_ram"
        unset _kdbg_page _kdbg_action _kdbg_extract
        return 1
    fi

    # ── Battle started ─────────────────────────────────────────────────────
    local _kdbg_battle_start
    _kdbg_battle_start=$(date +%s)
    _kdbg_extract

    # Detect team from rendered page
    local _kdbg_team=""
    local _kdbg_pfive
    _kdbg_pfive=$(w3m -dump -T text/html "$src_ram" 2>/dev/null | head -n 5)
    if echo "$_kdbg_pfive" | grep -q '\[1\]'; then
        _kdbg_team="1"
    elif echo "$_kdbg_pfive" | grep -q '\[0\]'; then
        _kdbg_team="0"
    fi
    local _kdbg_opponent
    _kdbg_opponent=$(grep -o -E '([[:upper:]][[:lower:]]{0,15}( [[:upper:]][[:lower:]]{0,13})?)[[:space:]][^[:alnum:][:space:]]' "$src_ram" | sed -n 's, [<]s,,;s, ,_,;2p')

    printf '\n'
    printf "  ${GREEN_BLACK}👑 KING BATTLE vs %-16s [Team %s]${COLOR_RESET}\n" "${_kdbg_opponent:-?}" "${_kdbg_team:-?}"
    printf "  ${GRAY_BLACK}Max HP: %-6d  Enemy HP%%: %-3d${COLOR_RESET}\n" "$_kdbg_maxhp" "$_kdbg_ENH"
    {
        printf '\n============================================================\n'
        printf '=  BATTLE START\n'
        printf '============================================================\n'
        printf 'Timestamp: %(%Y-%m-%d %H:%M:%S)T\n' -1
        printf 'Opponent: %s  Team: [%s]  MaxHP: %s  EnemyHP%%: %s\n' \
            "${_kdbg_opponent:-?}" "${_kdbg_team:-?}" "${_kdbg_maxhp:-?}" "${_kdbg_ENH:-?}"
        printf '\n--- ACTION LOG ---\n'
        printf '%-10s %-4s %-38s %-14s %-16s\n' \
            'TIME' '#' 'ACTION' 'HP_before→after' 'ENH%%_before→after'
        printf '%s\n' '──────────────────────────────────────────────────────────────────────────'
    } >> "$debug_file"

    # ── Battle variables ───────────────────────────────────────────────────
    local _kdbg_OLDHP="$_kdbg_USH"
    local _kdbg_last_heal=$(( _kdbg_battle_start - 90 ))
    local _kdbg_last_dodge=$(( _kdbg_battle_start - 20 ))
    local _kdbg_last_atk=$(( _kdbg_battle_start - LA ))
    local _kdbg_stone_used=0
    local _kdbg_heals=0 _kdbg_dodges=0 _kdbg_atks=0 _kdbg_atkrnds=0 _kdbg_kingatks=0
    local _kdbg_la_failures=0 _kdbg_la_successes=0
    local _kdbg_loop=0 _kdbg_BREAK=0

    # ── Main battle loop ───────────────────────────────────────────────────
    while [ "$_kdbg_BREAK" -eq 0 ]; do
        local _kdbg_now
        _kdbg_now=$(date +%s)
        local _kdbg_elapsed=$(( _kdbg_now - _kdbg_battle_start ))
        local _kdbg_min=$(( _kdbg_elapsed / 60 ))
        local _kdbg_sec=$(( _kdbg_elapsed % 60 ))
        local _kdbg_tsh=$(( _kdbg_now - _kdbg_last_heal ))
        local _kdbg_tsd=$(( _kdbg_now - _kdbg_last_dodge ))
        local _kdbg_tsa=$(( _kdbg_now - _kdbg_last_atk ))
        local _kdbg_hp_before="$_kdbg_USH"
        local _kdbg_enh_before="$_kdbg_ENH"
        local _kdbg_action_label=""

        _kdbg_loop=$(( _kdbg_loop + 1 ))

        # Save full page dump at loop 10 for analysis
        if [ "$_kdbg_loop" -eq 10 ]; then
            local _kdbg_loop10_file="${debug_dir}/king_debug_${debug_ts}_LOOP10_FULL_PAGE.txt"
            {
                printf '============================================================\n'
                printf '=  FULL PAGE DUMP AT LOOP 10\n'
                printf '============================================================\n'
                printf 'Timestamp: %s\n' "$(date +'%Y-%m-%d %H:%M:%S')"
                printf 'Loop: %d  |  Battle elapsed: %dm%ds\n\n' "$_kdbg_loop" "$_kdbg_min" "$_kdbg_sec"
                printf '--- RENDERED HTML (w3m dump) ---\n'
                w3m -dump -T text/html "$src_ram" 2>/dev/null
                printf '\n--- RAW HTML SOURCE (first 3000 chars) ---\n'
                head -c 3000 "$src_ram" 2>/dev/null
            } > "$_kdbg_loop10_file"
            printf "  ${GRAY_BLACK}[Loop 10 page saved: %s]${COLOR_RESET}\n" "$_kdbg_loop10_file" >&2
        fi

        # Save battle history every 3 loops
        if [ $(( _kdbg_loop % 3 )) -eq 0 ]; then
            local _kdbg_page_render
            _kdbg_page_render=$(w3m -dump -T text/html "$src_ram" 2>/dev/null)
            {
                printf '[Loop %d] %s\n' "$_kdbg_loop" "$(date +'%H:%M:%S')"
                echo "$_kdbg_page_render" | sed -n '/^Os participantes:/,/^A batalha já começou!/p' | \
                    grep -v '^$' | grep -v 'Os participantes:' | grep -v 'A batalha já começou'
            } >> "$_kdbg_battle_history"
        fi

        # Detect battle end: no attack/kingatk and no unrip = game over
        if [ -z "$_kdbg_KINGATK" ] && [ -z "$_kdbg_ATK" ] && [ -z "$_kdbg_UNRIP" ]; then
            _kdbg_BREAK=1
            break
        fi

        # ── Priority 0: DODGE ─────────────────────────────────────────────
        if ! grep -q 'txt smpl grey' "$src_ram" 2>/dev/null && \
           [ "$_kdbg_tsd" -gt 20 ] && [ "$_kdbg_tsd" -lt 300 ] && \
           awk -v ush="$_kdbg_USH" -v old="$_kdbg_OLDHP" 'BEGIN { exit !(ush+0 < old+0) }' && \
           [ -n "$_kdbg_DODGE" ]; then
            (
                w3mc -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 \
                    -debug -dump_source "${URL}${_kdbg_DODGE}" \
                    -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$src_ram"
            ) </dev/null &>/dev/null &
            time_exit 17
            _kdbg_extract; _kdbg_OLDHP="$_kdbg_USH"; _kdbg_last_dodge=$_kdbg_now; _kdbg_last_atk=$_kdbg_now
            _kdbg_dodges=$(( _kdbg_dodges + 1 ))
            _kdbg_action_label="🛡️ DODGE"

        # ── Priority 1: HEAL ──────────────────────────────────────────────
        elif awk -v ush="${_kdbg_USH:-0}" -v hlhp="$_kdbg_HLHP" 'BEGIN { exit !(ush+0 < hlhp+0) }' && \
             [ "$_kdbg_tsh" -gt 90 ] && [ "$_kdbg_tsh" -lt 300 ] && [ -n "$_kdbg_HEAL" ]; then
            (
                w3mc -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 \
                    -debug -dump_source "${URL}${_kdbg_HEAL}" \
                    -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$src_ram"
            ) </dev/null &>/dev/null &
            time_exit 17
            _kdbg_extract; _kdbg_last_heal=$_kdbg_now; _kdbg_last_atk=$_kdbg_now
            _kdbg_heals=$(( _kdbg_heals + 1 ))
            _kdbg_action_label="💚 HEAL → HP:${_kdbg_USH}"

        # ── Priority 2: ATTACK (timer check) ─────────────────────────────
        elif awk -v t="$_kdbg_tsa" -v la="${LA%%.*}" 'BEGIN { exit !(t+0 > la+0) }'; then

            if [ -n "$_kdbg_KINGATK" ]; then
                # ── 2a: KINGATK (all-target attack) ──────────────────────
                (
                    w3mc -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 \
                        -debug -dump_source "${URL}${_kdbg_KINGATK}" \
                        -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$src_ram"
                ) </dev/null &>/dev/null &
                time_exit 17
                _kdbg_extract; _kdbg_last_atk=$_kdbg_now
                _kdbg_kingatks=$(( _kdbg_kingatks + 1 ))
                _kdbg_action_label="👑 KINGATK (all-attack)"

                # ── 2b: STONE when enemy HP% < 25 ────────────────────────
                if awk -v enh="${_kdbg_ENH:-100}" 'BEGIN { exit !(enh+0 < 25) }' && [ -n "$_kdbg_STONE" ] && [ "$_kdbg_stone_used" -eq 0 ]; then
                    (
                        w3mc -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 \
                            -debug -dump_source "${URL}${_kdbg_STONE}" \
                            -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$src_ram"
                    ) </dev/null &>/dev/null &
                    time_exit 17
                    _kdbg_extract; _kdbg_stone_used=1
                    _kdbg_action_label="👑 KINGATK + 💪 STONE (ENH%:<25)"
                fi

            else
                # ── 2c: ATKRND (random target) ───────────────────────────
                if ! grep -q 'txt smpl grey' "$src_ram" 2>/dev/null && \
                   [ -n "$_kdbg_ATKRND" ] && \
                   { awk -v rhp="$_kdbg_RHP" -v enh="${_kdbg_ENH:-0}" 'BEGIN { exit !(rhp+0 < enh+0) }' || \
                     grep -q "$(grep -o -E '([[:upper:]][[:lower:]]{0,15}( [[:upper:]][[:lower:]]{0,13})?)[[:space:]][^[:alnum:][:space:]]' "$src_ram" | sed -n 's, [<]s,,;s, ,_,;2p')" "$tmp_ram/allies.txt" 2>/dev/null; }; then
                    (
                        w3mc -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 \
                            -debug -dump_source "${URL}${_kdbg_ATKRND}" \
                            -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$src_ram"
                    ) </dev/null &>/dev/null &
                    time_exit 17
                    _kdbg_extract; _kdbg_last_atk=$_kdbg_now
                    _kdbg_atkrnds=$(( _kdbg_atkrnds + 1 ))
                    _kdbg_action_label="🎲 ATKRND (ENH%%:${_kdbg_enh_before}→${_kdbg_ENH})"
                fi

                # ── 2d: ATK (direct attack) ───────────────────────────────
                if [ -n "$_kdbg_ATK" ]; then
                    local _kdbg_prev_enh="$_kdbg_ENH"
                    local _kdbg_prev_atk="$_kdbg_ATK"
                    (
                        w3mc -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 \
                            -debug -dump_source "${URL}${_kdbg_ATK}" \
                            -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$src_ram"
                    ) </dev/null &>/dev/null &
                    time_exit 17
                    _kdbg_extract; _kdbg_last_atk=$_kdbg_now

                    # Check attack success
                    local _kdbg_rcheck
                    _kdbg_rcheck=$(w3m -dump -T text/html "$src_ram" 2>/dev/null | head -n 20)
                    if echo "$_kdbg_rcheck" | grep -q -i -E 'perdeu|falhou|failed|cooldown|too fast'; then
                        _kdbg_la_failures=$(( _kdbg_la_failures + 1 ))
                        _kdbg_la_successes=0
                        LA=$(awk -v la="$LA" 'BEGIN { printf "%.1f", la + 0.2 }')
                        _kdbg_action_label="⚔️ ATK → MISS ❌ (LA→${LA}s)"
                    else
                        _kdbg_la_successes=$(( _kdbg_la_successes + 1 ))
                        _kdbg_atks=$(( _kdbg_atks + 1 ))
                        _kdbg_action_label="⚔️ ATK → HIT ✓ (ENH%%:${_kdbg_prev_enh}→${_kdbg_ENH})"
                        if [ "$_kdbg_la_successes" -ge 10 ] && \
                           awk -v la="$LA" 'BEGIN { exit !(la > 4.0) }'; then
                            LA=$(awk -v la="$LA" 'BEGIN { printf "%.1f", la - 0.1 }')
                            _kdbg_action_label="${_kdbg_action_label} LA↓${LA}s"
                            _kdbg_la_successes=0
                        fi
                    fi
                fi
            fi

        # ── Priority 3: REFRESH ───────────────────────────────────────────
        else
            (
                w3mc -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 \
                    -debug -dump_source "${URL}/king" \
                    -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$src_ram"
            ) </dev/null &>/dev/null &
            time_exit 17
            _kdbg_extract
            # Check unrip: if no kingatk/atk/unrip after refresh → battle over
            if [ -z "$_kdbg_KINGATK" ] && [ -z "$_kdbg_ATK" ]; then
                if [ -n "$_kdbg_UNRIP" ]; then
                    (
                        w3mc -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 \
                            -debug -dump_source "${URL}${_kdbg_UNRIP}" \
                            -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$src_ram"
                    ) </dev/null &>/dev/null &
                    time_exit 17
                    _kdbg_extract
                    _kdbg_action_label="🔄 REFRESH + UNRIP"
                else
                    _kdbg_action_label="🔄 REFRESH (no unrip → battle end)"
                    _kdbg_action "$_kdbg_action_label" "$_kdbg_hp_before" "$_kdbg_enh_before" "$_kdbg_USH" "$_kdbg_ENH"
                    _kdbg_BREAK=1
                    break
                fi
            else
                _kdbg_action_label="🔄 REFRESH"
            fi
            sleep 1s
        fi

        # ── Log action to file ────────────────────────────────────────────
        _kdbg_action "$_kdbg_action_label" "$_kdbg_hp_before" "$_kdbg_enh_before" \
                     "$_kdbg_USH" "$_kdbg_ENH"

        # ── Terminal display ──────────────────────────────────────────────
        local _kdbg_hp_pct
        _kdbg_hp_pct=$(awk -v c="${_kdbg_USH:-0}" -v m="${_kdbg_maxhp:-1}" \
                       'BEGIN { v=c/m*100; if(v>100)v=100; if(v<0)v=0; printf "%.0f", v }')
        local _kdbg_bfill
        _kdbg_bfill=$(awk -v p="$_kdbg_hp_pct" 'BEGIN { v=int(p*16/100); if(v<0)v=0; if(v>16)v=16; print v }')
        local _kdbg_bempty=$(( 16 - _kdbg_bfill ))
        local _kdbg_bar="" _kdbg_j
        for (( _kdbg_j=0; _kdbg_j<_kdbg_bfill; _kdbg_j++ )); do _kdbg_bar+="█"; done
        for (( _kdbg_j=0; _kdbg_j<_kdbg_bempty; _kdbg_j++ )); do _kdbg_bar+="░"; done
        local _kdbg_hcol
        if [ "$_kdbg_hp_pct" -gt 60 ] 2>/dev/null; then _kdbg_hcol="$GREEN_BLACK"
        elif [ "$_kdbg_hp_pct" -gt 30 ] 2>/dev/null; then _kdbg_hcol="$GOLD_BLACK"
        else _kdbg_hcol="$RED_BLACK"; fi

        local _kdbg_stone_st
        [ "$_kdbg_stone_used" -eq 0 ] \
            && _kdbg_stone_st="${GREEN_BLACK}READY${COLOR_RESET}" \
            || _kdbg_stone_st="${GRAY_BLACK}USED${COLOR_RESET}"

        printf "\n  ${GOLD_BLACK}══ KING DEBUG ${_kdbg_min}m${_kdbg_sec}s (loop #${_kdbg_loop}) ══${COLOR_RESET}\n"
        printf "  ${_kdbg_hcol}HP: %-5d/%-5d${COLOR_RESET} [${_kdbg_bar}] %-3d%%\n" "$_kdbg_USH" "$_kdbg_maxhp" "$_kdbg_hp_pct"
        printf "  ${GRAY_BLACK}VS: %-16s  ENH%%: %-3d  Team:[%s]${COLOR_RESET}\n" "${_kdbg_opponent:-?}" "$_kdbg_ENH" "${_kdbg_team:-?}"
        printf "  ${GRAY_BLACK}────────────────────────────────${COLOR_RESET}\n"
        printf "  ${_kdbg_action_label}\n"
        local _kdbg_heal_info
        if [ "$_kdbg_tsh" -lt 90 ]; then
            _kdbg_heal_info="${GOLD_BLACK}⏳$(( 90 - _kdbg_tsh ))s${COLOR_RESET}"
        else
            _kdbg_heal_info="${GREEN_BLACK}READY${COLOR_RESET}"
        fi
        printf "  ${GRAY_BLACK}LA: %-4s  HPER: %-2d%%  Heal: ${_kdbg_heal_info}  Fails: %-2d${COLOR_RESET}\n" "$LA" "$HPER" "$_kdbg_la_failures"
        printf "  ${GRAY_BLACK}────────────────────────────────${COLOR_RESET}\n"
        printf "  ${GREEN_BLACK}KINGATK: %-3d  ATK: %-3d  RND: %-3d  DODGE: %-3d  HEAL: %-3d${COLOR_RESET}\n" "$_kdbg_kingatks" "$_kdbg_atks" "$_kdbg_atkrnds" "$_kdbg_dodges" "$_kdbg_heals"
        printf "  💪 Stone: ${_kdbg_stone_st}\n"
        printf "  ${GRAY_BLACK}─── PARTICIPANTS ───${COLOR_RESET}\n"
        w3m -dump -T text/html "$src_ram" 2>/dev/null | \
            grep "Os participantes:" | \
            sed 's|\[0\]|🔴|g; s|\[1\]|🔵|g; s|\[health\]|🧡|g' | \
            while IFS= read -r logline; do
                printf "  ${GRAY_BLACK}%s${COLOR_RESET}\n" "$logline"
            done
        printf "  ${GRAY_BLACK}─── BATTLE LOG ───${COLOR_RESET}\n"
        local _kdbg_page_render
        _kdbg_page_render=$(w3m -dump -T text/html "$src_ram" 2>/dev/null)
        echo "$_kdbg_page_render" | sed -n '/^Os participantes:/,/^A batalha já começou!/p' | \
            grep -v '^$' | grep -v 'Os participantes:' | grep -v 'A batalha já começou' | \
            sed 's|\[0\]|🔴|g; s|\[1\]|🔵|g; s|\[rip\]|💀|g; s|assassinou|💥|; s|perdeu|❌|; s|Você acertar|✓|; s|Você usou|⚡|; s|\[king\]|👑|g' | \
            tail -n 8 | \
            while IFS= read -r logline; do
                printf "  ${GRAY_BLACK}%s${COLOR_RESET}\n" "$logline"
            done
    done

    # ── Post-battle ────────────────────────────────────────────────────────
    local _kdbg_dur=$(( $(date +%s) - _kdbg_battle_start ))
    local _kdbg_dmin=$(( _kdbg_dur / 60 )) _kdbg_dsec=$(( _kdbg_dur % 60 ))

    _kdbg_page "STATE: POST-BATTLE"

    # Parse result
    local _kdbg_result="unknown"
    local _kdbg_rend
    _kdbg_rend=$(w3m -dump -T text/html "$src_ram" 2>/dev/null)
    if echo "$_kdbg_rend" | grep -q -i -E 'vit[oó]ria|victory|victoire'; then
        _kdbg_result="WIN"
    elif echo "$_kdbg_rend" | grep -q -i -E 'derrota|defeat|defaite'; then
        _kdbg_result="LOSS"
    fi

    # ── Terminal post-match display ────────────────────────────────────────
    printf "\n"
    printf "  ${GOLD_BLACK}╔══════════════════════════════════════════════════════════╗${COLOR_RESET}\n"
    printf "  ${GOLD_BLACK}║               KING BATTLE SUMMARY  👑                   ║${COLOR_RESET}\n"
    printf "  ${GOLD_BLACK}╠══════════════════════════════════════════════════════════╣${COLOR_RESET}\n"
    if [ "$_kdbg_result" = "WIN" ]; then
        printf "  ${GREEN_BLACK}║     ✅  VICTORY!                                       ║${COLOR_RESET}\n"
    elif [ "$_kdbg_result" = "LOSS" ]; then
        printf "  ${RED_BLACK}║     ❌  DEFEAT                                         ║${COLOR_RESET}\n"
    else
        printf "  ${GOLD_BLACK}║     ❓  RESULT UNKNOWN                                 ║${COLOR_RESET}\n"
    fi
    printf "  ${GOLD_BLACK}╠══════════════════════════════════════════════════════════╣${COLOR_RESET}\n"
    printf "  ${GRAY_BLACK}║ Duration:${GOLD_BLACK} %-3dm%-3ds${GRAY_BLACK}  |  Loops:${GOLD_BLACK} %-5d${GRAY_BLACK}  |  Opponent:${GOLD_BLACK} %-14s${GRAY_BLACK}║${COLOR_RESET}\n" "$_kdbg_dmin" "$_kdbg_dsec" "$_kdbg_loop" "${_kdbg_opponent:-?}"
    printf "  ${GRAY_BLACK}║ Team: [${GOLD_BLACK}%s${GRAY_BLACK}]  |  Max HP:${GOLD_BLACK} %-6d${GRAY_BLACK}  |  Enemy HP%%:${GOLD_BLACK} %-5d${GRAY_BLACK}║${COLOR_RESET}\n" "${_kdbg_team:-?}" "$_kdbg_maxhp" "$_kdbg_ENH"
    printf "  ${GOLD_BLACK}╠══════════════════════════════════════════════════════════╣${COLOR_RESET}\n"
    printf "  ${GRAY_BLACK}║ ACTIONS:${COLOR_RESET}\n"
    printf "  ${GRAY_BLACK}║   KINGATK:${GREEN_BLACK}%-3d${GRAY_BLACK}  ATK:${GREEN_BLACK}%-3d${GRAY_BLACK}  RND:${GREEN_BLACK}%-3d${GRAY_BLACK}  DODGE:${GREEN_BLACK}%-3d${GRAY_BLACK}  HEAL:${GREEN_BLACK}%-3d${GRAY_BLACK}  Stone:%d${COLOR_RESET}\n" "$_kdbg_kingatks" "$_kdbg_atks" "$_kdbg_atkrnds" "$_kdbg_dodges" "$_kdbg_heals" "$_kdbg_stone_used"
    printf "  ${GOLD_BLACK}╠══════════════════════════════════════════════════════════╣${COLOR_RESET}\n"
    printf "  ${GRAY_BLACK}║ LA: Start ${KING_LA:-4}s  |  End: ${LA}s  |  Fails: ${RED_BLACK}%-2d${GRAY_BLACK}  |  HPER: %d%%${COLOR_RESET}\n" "$_kdbg_la_failures" "$HPER"
    local _kdbg_captured_fails=$(grep -c "perdeu" "$_kdbg_battle_history" 2>/dev/null || echo "0")
    local _kdbg_captured_kills=$(grep -c "assassinou" "$_kdbg_battle_history" 2>/dev/null || echo "0")
    printf "  ${GRAY_BLACK}║   Fails from log:${RED_BLACK}%-2d${GRAY_BLACK}  |  Kills from log:${GREEN_BLACK}%-2d${COLOR_RESET}\n" "$_kdbg_captured_fails" "$_kdbg_captured_kills"
    printf "  ${GOLD_BLACK}╠══════════════════════════════════════════════════════════╣${COLOR_RESET}\n"
    printf "  ${GRAY_BLACK}║ Debug file: ${GOLD_BLACK}%-46s${GRAY_BLACK}║${COLOR_RESET}\n" "${debug_file##*/}"
    printf "  ${GRAY_BLACK}║ Loop 10 page: ${GOLD_BLACK}king_debug_*_LOOP10_FULL_PAGE.txt${GRAY_BLACK}        ║${COLOR_RESET}\n"
    printf "  ${GOLD_BLACK}╚══════════════════════════════════════════════════════════╝${COLOR_RESET}\n"
    printf "\n  ${GRAY_BLACK}(closing in 10 seconds...)${COLOR_RESET}\n"
    sleep 10s

    # ── Write battle summary to debug file ────────────────────────────────
    {
        printf '\n============================================================\n'
        printf '=  BATTLE SUMMARY\n'
        printf '============================================================\n'
        printf 'Result: %s\n' "$_kdbg_result"
        printf 'Duration: %dm %ds  |  Loops: %d\n' "$_kdbg_dmin" "$_kdbg_dsec" "$_kdbg_loop"
        printf 'KINGATK:%d  ATK:%d  RND:%d  DODGE:%d  HEAL:%d  Stone:%d\n' \
            "$_kdbg_kingatks" "$_kdbg_atks" "$_kdbg_atkrnds" "$_kdbg_dodges" "$_kdbg_heals" "$_kdbg_stone_used"
        printf 'ATK Fails:%d  LA Start:%s  LA End:%s\n' \
            "$_kdbg_la_failures" "${KING_LA:-4}" "$LA"
        printf 'HPER Final:%s  RPER Final:%s\n' "$HPER" "$RPER"
        printf '\n--- BATTLE HISTORY (captured during battle) ---\n'
        if [ -f "$_kdbg_battle_history" ] && [ -s "$_kdbg_battle_history" ]; then
            cat "$_kdbg_battle_history"
        else
            printf '(no history captured)\n'
        fi
        local _kdbg_real_fails
        _kdbg_real_fails=$(grep -c "perdeu" "$_kdbg_battle_history" 2>/dev/null || echo "0")
        local _kdbg_real_kills
        _kdbg_real_kills=$(grep -c "assassinou" "$_kdbg_battle_history" 2>/dev/null || echo "0")
        printf '\n--- ATTACK ANALYSIS ---\n'
        printf 'Você perdeu (fails detected): %d\n' "$_kdbg_real_fails"
        printf 'Você assassinou (kills): %d\n' "$_kdbg_real_kills"
        printf '\n--- DEBUG ARTIFACTS ---\n'
        printf 'Full page dump at Loop 10: king_debug_%s_LOOP10_FULL_PAGE.txt\n' "$debug_ts"
    } >> "$debug_file"

    # ── Cleanup ────────────────────────────────────────────────────────────
    rm -f "$src_ram" "$full_ram" "$_kdbg_battle_history"
    cd - >/dev/null 2>&1
    rm -rf "$tmp_ram"
    unset _kdbg_page _kdbg_action _kdbg_extract
    unset _kdbg_USH _kdbg_ENH _kdbg_ATK _kdbg_KINGATK _kdbg_ATKRND
    unset _kdbg_DODGE _kdbg_STONE _kdbg_HEAL _kdbg_UNRIP _kdbg_RHP _kdbg_HLHP
}
king_start_debug () {
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
    printf "\n${GOLD_BLACK}👑 King Debug Mode — starting immediately${COLOR_RESET}\n"
    king_debug
}
king_start () {
 case $(date +%H:%M) in
 (12:2[5-9]|16:2[5-9]|22:2[5-9])
  cd "$TMP" || return
  (
   w3mc -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "$URL/train" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)"|grep -o -E '\(([0-9]+)\)'|sed 's/[()]//g' >"$TMP"/FULL
  ) </dev/null &>/dev/null &
  time_exit 17
  (
   w3mc -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "$URL/king/enterGame" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
  ) </dev/null &>/dev/null &
  time_exit 17
  echo -e "${GOLD_BLACK}👑King of the Immortals will be started...${COLOR_RESET}"
  until (case $(date +%M) in (2[5-9]) exit 1 ;; esac) ; do
   sleep 3
  done
  (
   w3mc -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "$URL/king/enterGame" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
  ) </dev/null &>/dev/null &
  time_exit 17
  printf "\nKing\n$URL\n"
  grep -o -E '(/[a-z]+(/[a-z]+/[^A-Za-z0-9]r[^A-Za-z0-9][0-9]+|/))' "$TMP"/SRC | sed -n '1p' >ACCESS 2>/dev/null
  #cat "$TMP"/SRC|sed 's/href=/\n/g'|grep '/king/'|head -n 1|awk -F"[']" '{ print $2 }' >ACCESS 2> /dev/null
  printf " 👣 Entering...\n$(cat ACCESS)\n"
  #/wait
  printf " 😴 Waiting...\n"
  cat < "$TMP"/SRC|grep -o 'king/kingatk/' >EXIT 2> /dev/null
  local BREAK=$(( $(date +%s) + 30 ))
  until [ -s "EXIT" ] || [ "$(date +%s)" -gt "$BREAK" ] ; do
   printf " 💤	...\n$(cat ACCESS)\n"
   (
    w3mc -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}$(cat ACCESS)" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
   ) </dev/null &>/dev/null &
   time_exit 17
   cat < "$TMP"/SRC | sed 's/href=/\n/g'|grep '/king/'|head -n 1|awk -F"[']" '{ print $2 }' >ACCESS 2> /dev/null
   cat < "$TMP"/SRC | grep -o 'king/kingatk/' >EXIT 2> /dev/null
   sleep 2
  done
  king_debug
  ;;
 esac
}