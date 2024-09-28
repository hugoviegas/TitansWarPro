career_func() {
  echo -e "${GOLD_BLACK}Career 🎖️${COLOR_RESET}"
  fetch_page "/career/"
  if grep -q -o -E '/career/attack/[?]r[=][0-9]+' "$TMP"/SRC; then

    checkQuest 6

    fetch_page "/career/"
    if grep -q -o -E '/career/(attack|take)/[?]r[=][0-9]+' "$TMP"/SRC; then
      #/'=\\\&apos
      local CAREER=$(grep -o -E '/career/(attack|take)/[?]r[=][0-9]+' "$TMP"/SRC)
      local BREAK=$(($(date +%s) + 60))
      while [ -n "$CAREER" ] && [ $(date +%s) -lt "$BREAK" ]; do
        case $CAREER in
        *attack*)
          fetch_page "$CAREER"
          RESULT=$(echo "$CAREER" | cut -d'/' -f3)
          echo " Career -> $RESULT !"
          local CAREER=$(grep -o -E '/career/(attack|take)/[?]r[=][0-9]+' "$TMP"/SRC | sed -n '1p')
          ;;
          *take*)
          fetch_page "$CAREER"
          RESULT=$(echo "$CAREER" | cut -d'/' -f3)
          echo " Career -> $RESULT !"
          break
          ;;
          
        esac
      done
    fi

    checkQuest 6

    echo -e "${GREEN_BLACK}Career ✅${COLOR_RESET}\n"
  else
    echo -e "${GREEN_BLACK}Career ✅${COLOR_RESET}\n"
  fi

}
