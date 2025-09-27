#
#/clandmgfight/dodge/?r=0
#/clandmgfight/attack/?r=0
#/clandmgfight/attackrandom/?r=0
#/clandmgfight/heal/?r=0
#/clandmgfight/stone/?r=0
#/clandmgfight/grass/?r=0
#/clandmgfight/?out_gate
clandmgfight_fight() {
  cd "$TMP" || exit
  #/enterFight
  local LA=4    # interval attack
  local HPER=48 # % to heal
  local RPER=15 # % to random
  awk -v ush="$(cat FULL)" -v hper="$HPER" 'BEGIN { printf "%.0f", ush * hper / 100 }' >HLHP
  cf_access() {
    grep -o -E '(/[a-z]+/[a-z]{0,4}at[a-z]{0,3}k/[^A-Za-z0-9]r[^A-Za-z0-9][0-9]+)' "$TMP"/SRC | sed -n '1p' >ATK 2>/dev/null
    grep -o -E '(/[a-z]+/at[a-z]{0,3}k[a-z]{3,6}/[^A-Za-z0-9]r[^A-Za-z0-9][0-9]+)' "$TMP"/SRC >ATKRND 2>/dev/null
    grep -o -E '(/clandmgfight/dodge/[^A-Za-z0-9]r[^A-Za-z0-9][0-9]+)' "$TMP"/SRC >DODGE 2>/dev/null
    grep -o -E '(/clandmgfight/heal/[^A-Za-z0-9]r[^A-Za-z0-9][0-9]+)' "$TMP"/SRC >HEAL 2>/dev/null
    grep -o -E '(/clandmgfight/grass/[^A-Za-z0-9]r[^A-Za-z0-9][0-9]+)' "$TMP"/SRC >GRASS 2>/dev/null
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
  : > BREAK_LOOP
  cat HP >old_HP
  echo $(($(date +%s) - 20)) >last_dodge
  echo $(($(date +%s) - 90)) >last_heal
  echo $(($(date +%s) - $LA)) >last_atk
  until [ -s "BREAK_LOOP" ]; do
    cf_access
    #/dodge/
    if ! grep -q -o 'txt smpl grey' "$TMP"/SRC && [ "$(($(date +%s) - $(cat last_dodge)))" -gt 20 -a "$(($(date +%s) - $(cat last_dodge)))" -lt 300 ] && awk -v ush="$(cat HP)" -v oldhp="$(cat old_HP)" 'BEGIN { exit !(ush < oldhp) }'; then
      (
        w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}$(cat DODGE)" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
      ) </dev/null &>/dev/null &
      time_exit 17
      cf_access
      cat HP >old_HP
      date +%s >last_dodge
    #/heal/
    elif awk -v ush="$(cat HP)" -v hlhp="$(cat HLHP)" 'BEGIN { exit !(ush < hlhp) }' && [ "$(($(date +%s) - $(cat last_heal)))" -gt 90 -a "$(($(date +%s) - $(cat last_heal)))" -lt 300 ]; then
      (
        w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}$(cat HEAL)" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
      ) </dev/null &>/dev/null &
      time_exit 17
      sleep 0.3s
      (
        w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}$(cat GRASS)" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
      ) </dev/null &>/dev/null &
      time_exit 17
      cf_access
      cat HP >FULL
      cat HP >old_HP
      date +%s >last_heal
    #/random
    elif awk -v latk="$(($(date +%s) - $(cat last_atk)))" -v atktime="$LA" 'BEGIN { exit !(latk != atktime) }' && ! grep -q -o 'txt smpl grey' "$TMP"/SRC && awk -v rhp="$(cat RHP)" -v enh="$(cat HP2)" 'BEGIN { exit !(rhp < enh) }' || awk -v latk="$(($(date +%s) - $(cat last_atk)))" -v atktime="$LA" 'BEGIN { exit !(latk != atktime) }' && ! grep -q -o 'txt smpl grey' "$TMP"/SRC && grep -q -o "$(cat CLAN)" "$TMP"/callies.txt; then
      (
        w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}$(cat ATKRND)" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
      ) </dev/null &>/dev/null &
      time_exit 17
      cf_access
      date +%s >last_atk
      #/attack
      sleep 0.3s
    elif awk -v latk="$(($(date +%s) - $(cat last_atk)))" -v atktime="$LA" 'BEGIN { exit !(latk > atktime) }'; then
      (
        w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}$(cat ATK)" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
      ) </dev/null &>/dev/null &
      time_exit 17
      cf_access
      date +%s >last_atk
    else
      (
        w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}/clandmgfight" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
      ) </dev/null &>/dev/null &
      time_exit 17
      cf_access
      sleep 1s
    fi
  done
  unset cf_access _random
  #/end
  func_unset
  echo_t "Clan duel" "${GREEN_BLACK}" "${COLOR_RESET}" "after" "✅\n"
  clear
}
clandmgfight_start() {
  cd "$TMP" || exit
  apply_event clandmgfight
  case $(date +%H:%M) in
  09:2[5-9] | 21:2[5-9])
    (
      w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "$URL/train" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" | grep -o -E '\(([0-9]+)\)' | sed 's/[()]//g' >"$TMP"/FULL
    ) </dev/null &>/dev/null &
    time_exit 17
    (
      w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "$URL/clandmgfight/?close=reward" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
    ) </dev/null &>/dev/null &
    time_exit 17
    (
      w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "$URL/clandmgfight/enterFight" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
    ) </dev/null &>/dev/null &
    time_exit 17
    echo_t "The clan duel will be started..." "${GOLD_BLACK}" "${COLOR_RESET}"
    while (case $(date +%M:%S) in (29:[3-5][0-9]) exit 1 ;; ([4-5][5-9]:[0-5][0-9]) return ;; esac) ; do
      sleep 3
    done
    (
      w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "$URL/clandmgfight/enterFight" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
    ) </dev/null &>/dev/null &
    time_exit 17
    #printf "\nClan fight\n$URL\n"
    grep -o -E '(/[a-z]+(/[a-z]+/[^A-Za-z0-9]r[^A-Za-z0-9][0-9]+|/))' "$TMP"/SRC | sed -n '1p' >ACCESS 2>/dev/null
    echo_t " Entering..." "" "\n" "before" " 👣"
    #/wait
    echo_t " Waiting..." "" "\n" "before" " 😴"
    local BREAK=$(($(date +%s) + 60))
    until grep -q -o 'clandmgfight/dodge/' ACCESS || [ "$(date +%s)" -gt "$BREAK" ]; do
      printf " 💤	...\n$(cat ACCESS)\n"
      (
        w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}/clandmgfight/" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
      ) </dev/null &>/dev/null &
      time_exit 17
      grep -o -E '(/clandmgfight(/[a-z]+/[^A-Za-z0-9]r[^A-Za-z0-9][0-9]+|/))' "$TMP"/SRC | sed -n '1p' >ACCESS 2>/dev/null
      sleep 3
    done
    clandmgfight_fight
    sleep 10s
    fetch_page /clandmgfight/enterFight
    clandmgfight_start
    ;;
    09:[3-4][0-9] | 21:[3-4][0-9])
    echo_t "The clan duel will be started..." "${GOLD_BLACK}" "${COLOR_RESET}"
    (
      w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "$URL/clandmgfight/enterFight" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
    ) </dev/null &>/dev/null &
    time_exit 17
    #printf "\nClan fight\n$URL\n"
    grep -o -E '(/[a-z]+(/[a-z]+/[^A-Za-z0-9]r[^A-Za-z0-9][0-9]+|/))' "$TMP"/SRC | sed -n '1p' >ACCESS 2>/dev/null
    echo_t " Entering..." "" "\n" "before" " 👣"
    #/wait
    echo_t " Waiting..." "" "\n" "before" " 😴"
    local BREAK=$(($(date +%s) + 60))
    until grep -q -o 'clandmgfight/dodge/' ACCESS || [ "$(date +%s)" -gt "$BREAK" ]; do
      printf " 💤	...\n$(cat ACCESS)\n"
      (
        w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}/clandmgfight/" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
      ) </dev/null &>/dev/null &
      time_exit 17
      grep -o -E '(/clandmgfight(/[a-z]+/[^A-Za-z0-9]r[^A-Za-z0-9][0-9]+|/))' "$TMP"/SRC | sed -n '1p' >ACCESS 2>/dev/null
      sleep 3
    done
    clandmgfight_fight
    sleep 10s
    fetch_page /clandmgfight/enterFight
    clandmgfight_start
    ;;
  esac
}
