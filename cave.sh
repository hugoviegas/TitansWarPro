# shellcheck disable=SC2148
cave_start() {
  (
    w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}/quest/" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
  ) </dev/null &>/dev/null &
  time_exit 20
  while grep -q -o -E '/cave/[?]quest_t[=]quest&quest_id[=]2&qz[=][a-z0-9]+' "$TMP"/SRC || echo "$RUN" | grep -q -E '[-]cv'; do
    echo -e "${GOLD_BLACK}Cave 🪨${COLOR_RESET}"
    clan_id
    if [ -n "$CLD" ]; then
      (
        w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -dump "${URL}/clan/${CLD}/quest/help/5" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" | tail -n 0
      ) </dev/null &>/dev/null &
      time_exit 17
      #printf "/clan/${CLD}/quest/help/5\n"
    fi
    condition_func() {
      (
        w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}/cave/" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
      ) </dev/null &>/dev/null &
      time_exit 17
      ACCESS1=$(cat "$TMP"/SRC | sed 's/href=/\n/g' | grep '/cave/' | head -n 1 | awk -F\' '{ print $2 }')
      DOWN=$(cat "$TMP"/SRC | sed 's/href=/\n/g' | grep '/cave/down' | awk -F\' '{ print $2 }')
      ACCESS2=$(cat "$TMP"/SRC | sed 's/href=/\n/g' | grep '/cave/' | head -n 2 | tail -n 1 | awk -F\' '{ print $2 }')
      ACTION=$(cat "$TMP"/SRC | sed 's/href=/\n/g' | grep '/cave/' | awk -F\' '{ print $2 }' | tr -cd "[[:alpha:]]")
      # shellcheck disable=SC2034
      MEGA=$(cat "$TMP"/SRC | sed 's/src=/\n/g' | grep '/images/icon/silver.png' | grep "'s'" | tail -n 1 | grep -o 'M')
    }
    condition_func
    local num=6
    local BREAK=$(($(date +%s) + 120))
    until [ $num -eq 0 ] && awk -v smodplay="$RUN" -v rmodplay="-cv" 'BEGIN { exit !(smodplay != rmodplay) }'; do
      if awk -v smodplay="$RUN" -v rmodplay="-cv" 'BEGIN { exit !(smodplay != rmodplay) }' && [ "$(date +%s)" -eq "$BREAK" ]; then
        break
      fi
      condition_func
      case $ACTION in
      cavechancercavegatherrcavedownr)
        (
          w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}${ACCESS2}" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
        ) </dev/null &>/dev/null &
        time_exit 17
        # shellcheck disable=SC2059
        echo -e "${CYAN_BLACK}${ACCESS2}${COLOR_RESET}\n$(w3m -dump -T text/html "$TMP"/SRC | grep -o -E '(g [0-9]{1,3}[^0-9]{0,1}[0-9]{0,3}[A-Za-z]{0,1} \| s [0-9]{1,3}[^0-9]{0,1}[0-9]{0,3}[A-Za-z]{0,1})' | sed 's/g/\ g/g;s/s/\ s/g')\n"
        local num=$((num - 1))
        ;;
      cavespeedUpr)
        (
          w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}${ACCESS2}" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
        ) </dev/null &>/dev/null &
        time_exit 17
        # shellcheck disable=SC2154
        # shellcheck disable=SC2059
        echo -e "${PURPLEis_BLACK}${ACCESS2}${COLOR_RESET}\n$(w3m -dump -T text/html "$TMP"/SRC | grep -o -E '(g [0-9]{1,3}[^0-9]{0,1}[0-9]{0,3}[A-Za-z]{0,1} \| s [0-9]{1,3}[^0-9]{0,1}[0-9]{0,3}[A-Za-z]{0,1})' | sed 's/g/\ g/g;s/s/\ s/g')\n"
        local num=$((num - 1))
        ;;
      cavedownr | cavedownrclanbuiltprivateUpgradetruerrefcave)
        local num=$((num - 1))
        (
          w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}${DOWN}" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
        ) </dev/null &>/dev/null &
        time_exit 17
        echo -e "${GREEN_BLACK}${DOWN}${COLOR_RESET}\n$(w3m -dump -T text/html "$TMP"/SRC | grep -o -E '(g [0-9]{1,3}[^0-9]{0,1}[0-9]{0,3}[A-Za-z]{0,1} \| s [0-9]{1,3}[^0-9]{0,1}[0-9]{0,3}[A-Za-z]{0,1})' | sed 's/g/\ g/g;s/s/\ s/g')\n"
        ;;
      caveattackrcaverunawayr)
        local num=$((num - 1))
        (
          w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}${ACCESS1}" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
        ) </dev/null &>/dev/null &
        time_exit 17
        echo -e "${GOLD_BLACK}${ACCESS1}${COLOR_RESET}\n$(w3m -dump -T text/html "$TMP"/SRC | grep -o -E '(g [0-9]{1,3}[^0-9]{0,1}[0-9]{0,3}[A-Za-z]{0,1} \| s [0-9]{1,3}[^0-9]{0,1}[0-9]{0,3}[A-Za-z]{0,1})' | sed 's/g/\ g/g;s/s/\ s/g')\n"
        (
          w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}/cave/runaway" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
        ) </dev/null &>/dev/null &
        time_exit 17
        echo -e "${WHITEb_BLACK}/cave/runaway${COLOR_RESET}\n"
        ;;
      *)
        local num=0
        ;;
      esac
    done
    if [ -n "$CLD" ]; then
      (
        w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug "${URL}/clan/${CLD}/quest/deleteHelp/5" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" | tail -n 0
      ) </dev/null &>/dev/null &
      time_exit 17
      printf "/clan/${CLD}/quest/deleteHelp/5\n"
    fi
    if awk -v smodplay="$RUN" -v rmodplay="-cv" 'BEGIN { exit !(smodplay != rmodplay) }'; then
      printf "\nYou can run ./twm/play.sh -cv\n"
    fi
    #/quest
    (
      w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}/quest/" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
    ) </dev/null &>/dev/null &
    time_exit 20
    local ENDQUEST=$(grep -o -E '/quest/end/2[?]r[=][A_z0-9]+' "$TMP"/SRC)
    if [ -n "$ENDQUEST" ]; then
      (
        w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}${ENDQUEST}" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
      ) </dev/null &>/dev/null &
      time_exit 20
    fi
    echo -e "${GREEN_BLACK}Cave Done✅${COLOR_RESET}\n"
    unset ACCESS1 ACCESS2 ACTION DOWN MEGA
  done
}

cave_routine() {
  echo -e "${GOLD_BLACK}Cave 🪨${COLOR_RESET}\n"
  # checkQuest 5
  (
    w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}/cave/" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
  ) </dev/null &>/dev/null &
  time_exit 20
  
  if grep -q -o -E '/cave/(gather|down|runaway)/[?]r[=][0-9]+' "$TMP"/SRC; then
    #/'=\\\&apos
    local CAVE=$(grep -o -E '/cave/(gather|down|runaway|speedUp)/[?]r[=][0-9]+' "$TMP"/SRC | sed -n '1p')
    local BREAK=$(($(date +%s) + 120))
    while [ -n "$CAVE" ] && [ "$(date +%s)" -lt "$BREAK" ]; do
      case $CAVE in
      (*gather* | *down* | *runaway* | *speedUp*)
        (
          w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}$CAVE" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
        ) </dev/null &>/dev/null &
        time_exit 20
        RESULT=$(echo "$CAVE" | cut -d'/' -f3)
        case $RESULT in
          *down*)
          tput cuu1
          tput el
          echo " Cave new search 🔍"
          #echo -e "${CAVE}"
          ;;
          *gather*)
          tput cuu1
          tput el
          echo " Cave start mining ⛏️"
          #echo -e "${CAVE}"
          ;;
          *speedUp*)
          tput cuu1
          tput el
          echo " Cave seepd up mining ⚡"
          #echo -e "${CAVE}"
          ;;
          *runaway*)
          tput cuu1
          tput el
          echo " Cave run away 💨"
          #echo -e "${CAVE}"
          #;;
          #*attack*)
          #tput cuu1
          #tput el
          #echo " Cave attack monster 🧌"
          ;;
        esac
        #echo "Cave $RESULT"
        #echo "\n"
        # shellcheck disable=SC2155
        (
          w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}/cave/" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
        ) </dev/null &>/dev/null &
        time_exit 20
        local CAVE=$(grep -o -E '/cave/(gather|down|runaway|attack|speedUp)/[?]r[=][0-9]+' "$TMP"/SRC | sed -n '1p')
        ;;
        (*attack*)
        NEWCAVE=$(echo "$CAVE" | sed 's/attack/runaway/') 
        (
          w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}$NEWCAVE" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
        ) </dev/null &>/dev/null &
        time_exit 20
        RESULT=$(echo "$NEWCAVE" | cut -d'/' -f3)
        tput cuu1
        tput el
        echo " Cave run away 💨"
        #echo -e "${NEWCAVE}"
        CAVE=$NEWCAVE
        ;;
      esac
    done
    if [ "$CAVE" != "speedUp" ]; then
      (
          w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}$CAVE" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
        ) </dev/null &>/dev/null &
        time_exit 20
    fi
  fi
  
  echo -e "${GREEN_BLACK}Cave Done✅${COLOR_RESET}\n"

}
