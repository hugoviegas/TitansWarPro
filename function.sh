#!/bin/bash
link()
{
  #echo "$1"
  (
    w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump "$URL/""$@" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" | tail -n0
  ) </dev/null &>/dev/null &
    time_exit 17
}

testColour()
{
   echo -e "${BLACK_BLACK}BLACK_BLACK${COLOR_RESET}\n"
   echo -e "${BLACK_CYAN}BLACK_CYAN${COLOR_RESET}\n"
   echo -e "${BLACK_GREEN}BLACK_GREEN${COLOR_RESET}\n"
   echo -e "${BLACK_GRAY}BLACK_GRAY${COLOR_RESET}\n"
   echo -e "${BLACK_PINK}BLACK_PINK${COLOR_RESET}\n"
   echo -e "${BLACK_RED}BLACK_RED${COLOR_RESET}\n"
   echo -e "${CYAN_BLACK}CYAN_BLACK${COLOR_RESET}\n"
   echo -e "${BLACK_YELLOW}BLACK_YELLOW${COLOR_RESET}\n"
   echo -e "${CYAN_CYAN}CYAN_CYAN${COLOR_RESET}\n"
   echo -e "${GOLD_BLACK}GOLD_BLACK${COLOR_RESET}\n"
   echo -e "${GREEN_BLACK}GREEN_BLACK${COLOR_RESET}\n"
   echo -e "${PURPLEi_BLACK}PURPLEi_BLACK${COLOR_RESET}\n"
   echo -e "${PURPLEis_BLACK}PURPLEis_BLACK${COLOR_RESET}\n"
   echo -e "${WHITE_BLACK}WHITE_BLACK${COLOR_RESET}\n"
   echo -e "${WHITEb_BLACK}WHITEb_BLACK${COLOR_RESET}\n"
}