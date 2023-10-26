completeQuest() {
  clan_id
  if [ -n "$CLD" ]; then
  local BREAK=$(($(date +%s) + 5))
  while grep -q -o -E '/clan/$CLD/quest/(deleteHelp|end)/' "$TMP"/SRC || [ "$(date +%s)" -lt "$BREAK" ]; do
  local click
  click=$(grep -q -o -E '/clan/$CLD/quest/(deleteHelp|end)/' "$TMP"/SRC)
    (
      w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump "${URL}'$click'$*" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" | tail -n0
    ) </dev/null &>/dev/null &
    time_exit 17
    echo " Quest $* Check"
  done
  else
    (
      w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump "$URL/clanrating/wantedToClan" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" | tail -n 0
    ) </dev/null &>/dev/null &
    time_exit 17
  fi
}