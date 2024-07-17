career_func() {
  printf "Career 🎖️... \n"
  (
    w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}/career/" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
  ) </dev/null &>/dev/null &
  time_exit 17
  if grep -q -o -E '/career/attack/[?]r[=][0-9]+' "$TMP"/SRC; then

    # checkQuest 6

    (
      w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}/career/" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
    ) </dev/null &>/dev/null &
    time_exit 20
    if grep -q -o -E '/career/(attack|take)/[?]r[=][0-9]+' "$TMP"/SRC; then
      #/'=\\\&apos
      local CAREER=$(grep -o -E '/career/(attack|take)/[?]r[=][0-9]+' "$TMP"/SRC)
      local BREAK=$(($(date +%s) + 60))
      while [ -n "$CAREER" ] && [ $(date +%s) -lt "$BREAK" ]; do
        case $CAREER in
        *attack*)
          (
            w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}$CAREER" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
          ) </dev/null &>/dev/null &
          time_exit 20
          RESULT=$(echo "$CAREER" | cut -d'/' -f3)
          echo " Career -> $RESULT !"
          local CAREER=$(grep -o -E '/career/(attack|take)/[?]r[=][0-9]+' "$TMP"/SRC | sed -n '1p')
          ;;
          *take*)
          (
            w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}$CAREER" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
          ) </dev/null &>/dev/null &
          time_exit 20
          RESULT=$(echo "$CAREER" | cut -d'/' -f3)
          echo " Career -> $RESULT !"
          break
          ;;
          
        esac
      done
    fi

    # checkQuest 6

    (
      w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}/quest/" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
    ) </dev/null &>/dev/null &
    time_exit 20
    local ENDQUEST=$(grep -o -E '/quest/end/16[?]r[=][A_z0-9]+' "$TMP"/SRC)
    (
      w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}${ENDQUEST}" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
    ) </dev/null &>/dev/null &
    time_exit 20
    echo -e "${GREEN_BLACK}Career ✅${COLOR_RESET}\n"
  else
    echo -e "${GREEN_BLACK}Career ✅${COLOR_RESET}\n"
  fi

}
