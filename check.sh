check_missions() {
  printf "Checking Missions...\n"
  (
    w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}/quest/" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
  ) </dev/null &>/dev/null &
  time_exit 20
  #open chests
  for i in {1..2}; do
    if grep -o -E "/quest/openChest/$i/[?]r=[0-9]+" "$TMP"/SRC; then
      click=$(grep -o -E "/quest/openChest/$i/[?]r=[0-9]+" "$TMP"/SRC)
      (
        w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}/$click" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
      ) </dev/null &>/dev/null &
      time_exit 20
      printf "${GREEN_BLACK}Chest opened (✔)${COLOR_RESET}\n"
    fi
  done
  #collect quests
  i=0
  for i in {0..15} ; do
  #while [ $i -lt 15 ]; do // /inv/chest/?quest_t=quest&quest_id=13&qz=01690126f2e5d7a75a31e6ee149c6cb2
  if grep -o -E "/inv/chest/?quest_t=quest&quest_id=13&[^A-Za-z0-9]+" "$TMP"/SRC; then
      (
        w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}/inv/chest/?quest_t=quest&quest_id=13&[^A-Za-z0-9]+" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
      ) </dev/null &>/dev/null &
      time_exit 20
      click=$(grep -o -E "/inv/chest/use/[0-9]+/1/[?]r=[0-9]+" "$TMP/SRC" | sed -n '3p')
      (
        w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}$click" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
      ) </dev/null &>/dev/null &
      time_exit 20
    fi
    if grep -o -E "/quest/end/${i}[?]r=[0-9]+" "$TMP"/SRC; then
      click=$(grep -o -E "/quest/end/${i}[?]r=[0-9]+" "$TMP"/SRC | sed -n '1p')
      (
        w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}${click}" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
      ) </dev/null &>/dev/null &
      time_exit 20
      echo $click
      printf "${GREEN_BLACK}Mission Completed (✔)${COLOR_RESET}\n"
    fi
    #i=$((i + 1))
  done
  #collect rewards
  (
    w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}/relic/reward/" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
  ) </dev/null &>/dev/null &
  time_exit 20
  i=0
  while [ $i -lt 11 ]; do
    if grep -o -E "/relic/reward/${i}/[?]r=[0-9]+" "$TMP"/SRC; then
      click=$(grep -o -E "/relic/reward/${i}/[?]r=[0-9]+" "$TMP"/SRC | sed -n '1p')
      (
        w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}${click}" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
      ) </dev/null &>/dev/null &
      time_exit 20
      printf "${GREEN_BLACK}Relic collected (✔)${COLOR_RESET}\n"
    fi
    i=$((i + 1))
  done
  #collect collections
  (
    w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}/collector/" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
  ) </dev/null &>/dev/null &
  time_exit 20
  if grep -o -E "/collector/reward/element/[?]r=[0-9]+" "$TMP"/SRC; then
    click=$(grep -o -E '/collector/reward/element/[?]r=[0-9]+' "$TMP"/SRC)
    (
      w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}${click}" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
    ) </dev/null &>/dev/null &
    time_exit 20
    printf "${GREEN_BLACK}Collection collected (✔)${COLOR_RESET}\n"
  fi
  printf "${GREEN_BLACK}Missions (✔)${COLOR_RESET}\n"
}

apply_event() {
  #/apply to fight
  event="$@"
  (
    w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}/$event/" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
  ) </dev/null &>/dev/null &
  time_exit 20
  if grep -o -E "/$event/enter(Game|Fight)/[?]r[=][0-9]+" "$TMP"/SRC; then
    APPLY=$(grep -o -E "/$event/enter(Game|Fight)/[?]r[=][0-9]+" "$TMP"/SRC)
    (
      w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}${APPLY}" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
    ) </dev/null &>/dev/null &
    time_exit 20
    printf "${BLACK_YELLOW}Applied for battle (✔)${COLOR_RESET}\n"
  fi
}
