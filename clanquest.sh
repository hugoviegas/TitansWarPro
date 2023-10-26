checkQuest() {
  quest_id="$*"
  clan_id
  if [ -n "${CLD}" ]; then
  (
    w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}/clan/${CLD}/quest/" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
  ) </dev/null &>/dev/null &
  time_exit 20
  click=$(grep -o "/quest/\(take\|help\|deleteHelp\|end\)/$*/[?]" "$TMP"/SRC | sed -n '1p')
<<<<<<< HEAD
  link=${click#"$*/[?]"}
=======
  link=${click#"$*/"}
>>>>>>> 4428848d13c75fe4d8752f871267ee8d91bf3232
  echo "$link"
  echo "$click"
  echo "$*"
  sleep 2s
    (
      w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump "${URL}$click" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" | tail -n0
    ) </dev/null &>/dev/null &
    time_exit 17
    echo " Quest $quest_id Check..."
  
  #done
    
  else
    (
      w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump "$URL/clanrating/wantedToClan" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" | tail -n 0
    ) </dev/null &>/dev/null &
    time_exit 17
  fi
}