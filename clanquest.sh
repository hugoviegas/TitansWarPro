checkQuest() {
  quest_id="$@"
  (
    w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}/clan/${CLD}/quest/" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
  ) </dev/null &>/dev/null &
  time_exit 20
  clan_id
  if [ -n "${CLD}" ]; then
  local click=$(grep -r -q "/clan/${CLD}/quest/(take|help|deleteHelp|end)/$quest_id" "$TMP"/SRC  | sed -n '1p')
  echo "$click"
  grep -r -q "/clan/${CLD}/quest/(take|help|deleteHelp|end)/$quest_id" "$TMP"/SRC  | sed -n '1p'
  echo "click"
  sleep 2s
  if ! echo "$click" | grep -q -o "id=${quest_id}"; then
    (
      w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump "${URL}${click}" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" | tail -n0
    ) </dev/null &>/dev/null &
    time_exit 17
    echo " Quest $quest_id Check..."
  elif echo "$click" | grep -q -o "end"; then
  (
      w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump "${URL}${click}" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" | tail -n0
    ) </dev/null &>/dev/null &
    time_exit 17
    echo " Quest $quest_id Completed ✅"
  fi
  #done
    
  else
    (
      w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump "$URL/clanrating/wantedToClan" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" | tail -n 0
    ) </dev/null &>/dev/null &
    time_exit 17
  fi
}