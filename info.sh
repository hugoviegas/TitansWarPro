#!/bin/bash
#/Colors - font(formatting)_background
colors() {
     BLACK_BLACK='\033[00;30m'
     BLACK_CYAN='\033[01;36m\033[01;07m'
     BLACK_GREEN='\033[00;32m\033[01;07m'
     BLACK_GRAY='\033[01;30m\033[01;07m'
     BLACK_PINK='\033[01;35m\033[01;07m'
     BLACK_RED='\033[01;31m\033[01;07m'
     BLACK_YELLOW='\033[00;33m\033[01;07m'
     CYAN_BLACK='\033[04;36m\033[02;04m'
     CYAN_CYAN='\033[01;36m\033[08;07m'
     BLUE_BLACK='\033[0;34m'
     COLOR_RESET='\033[00m'
     GOLD_BLACK='\033[33m'
     GREEN_BLACK='\033[32m'
     GREENb_BLACK='\033[1;32m'  # Bold green
     RED_BLACK='\033[0;31m'
     PURPLEi_BLACK='\033[03;34m\033[02;03m'
     PURPLEis_BLACK='\033[03;34m\033[02;04m'
     WHITE_BLACK='\033[37m'
     WHITEb_BLACK='\033[01;38m\033[05;01m'
}

script_slogan() {
colors="10 9 8 2 1 5 4 3 6 7"
t=339
w=59
m=89
author="author: Hugo Viegas"
#collaborator="collaborator: @_hviegas"
versionNum="3.4.16 (beta)"
for i in $colors; do
     clear
     t=$((t - 27))
     w=$((w + 1))
     m=$((m - 2))
     
# shellcheck disable=SC2059
printf "\033[1;38;5;${i}m

████████╗██╗████████╗ █████╗ ███╗   ██╗███████╗  
╚══██╔══╝██║╚══██╔══╝██╔══██╗████╗  ██║██╔════╝  
   ██║   ██║   ██║   ███████║██╔██╗ ██║███████╗ 
   ██║   ██║   ██║   ██╔══██║██║╚██╗██║╚════██║ 
   ██║   ██║   ██║   ██║  ██║██║ ╚████║███████║  
   ╚═╝   ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝  

██╗    ██╗ █████╗ ██████╗   
██║    ██║██╔══██╗██╔══██╗  
██║ █╗ ██║███████║██████╔╝  
██║███╗██║██╔══██║██╔══██╗  
╚███╔███╔╝██║  ██║██║  ██║  
 ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝  

██████╗ ██████╗  ██████╗ 
██╔══██╗██╔══██╗██╔═══██╗    
██████╔╝██████╔╝██║   ██║
██╔═══╝ ██╔══██╗██║   ██║
██║     ██║  ██║╚██████╔╝
╚═╝     ╚═╝  ╚═╝ ╚═════╝ 
"
printf "\033[1;38;5;${i}m${author}\n\033[02m${versionNum}${COLOR_RESET}\n"
sleep 0.2s
done
}

time_exit() {
     (
          local TEFPID=$(echo "$!" | grep -o -E '([0-9]{2,6})')
          for TELOOP in $(seq "$@" -1 0); do
               local TERPID=$(ps ax -o pid= | grep -o "$TEFPID")
               if [ -z "$TERPID" ]; then
                    local TELOOP=0
                    break &>/dev/null
               elif [ "$TELOOP" -lt 1 ]; then
                    kill -s PIPE $TEFPID &>/dev/null
                    kill -15 $TEFPID &>/dev/null
                    printf "${WHITEb_BLACK}Command execution was interrupted!${COLOR_RESET}\n"
                    local TELOOP=0
                    break &>/dev/null
               fi
               sleep 1s
          done
     )
}

link() {
     (
          w3m -cookie -o http_proxy=$PROXY -o accept_encoding=UTF-8 -debug -dump_source "$URL/$1" -o user_agent="$(shuf -n1 userAgent.txt)" >$2
     ) </dev/null &>/dev/null &
     time_exit 20
}

hpmp() {
     #/options: -fix or -now

     #/Go to /train page
     if echo "$@" | grep -q '\-fix'; then
          (
               w3m -cookie -o http_proxy=$PROXY -o accept_encoding=UTF-8 -debug -dump_source "$URL/train" -o user_agent="$(shuf -n1 userAgent.txt)" >$TMP/TRAIN
          ) </dev/null &>/dev/null &
          time_exit 20
          #/Fixed HP and MP.
          #/Needs to run -fix at least once before
          FIXHP=$(grep -o -E '\(([0-9]+)\)' $TMP/TRAIN | sed 's/[()]//g')
          FIXMP=$(grep -o -E ': [0-9]+' $TMP/TRAIN | sed -n '5s/: //p')
     fi

     #/$NOW/HP|MP can be obtained from any SRC file
     NOWHP=$(grep -o -E "<img src[=]'/images/icon/health.png' alt[=]'hp'/> <span class[=]'(dred|white)'>[ ]?[0-9]{1,7}[ ]?</span> \| <img src[=]'/images/icon/mana.png' alt[=]'mp'/>" $TMP/SRC | tr -c -d "[[:digit:]]")
     NOWMP=$(grep -o -E "</span> \| <img src='/images/icon/mana.png' alt='mp'/>[ ]?[0-9]{1,7}[ ]?</span><div class='clr'></div></div>" $TMP/SRC | tr -c -d "[[:digit:]]")

     #/Calculates percentage of HP and MP.
     #/Needs to run -fix at least once before
     HPPER=$(awk -v nowhp="$NOWHP" -v fixhp="$FIXHP" 'BEGIN { printf "%.3f", nowhp / fixhp * 100 }' | awk '{printf "%.2f\n", $1}')
     MPPER=$(awk -v nowmp="$NOWMP" -v fixmp="$FIXMP" 'BEGIN { printf "%.3f", nowmp / fixmp * 100 }' | awk '{printf "%.2f\n", $1}')
     #/e.g.
     #/printf %b "HP ❤️ $NOWHP - $(printf "%.2f" "${HPPER}")% | MP Ⓜ️ $NOWMP - $(printf "%.2f" "${MPPER}")%\n"
}

messages_info() {
     echo " ⚔️ - Titans War Macro - ⚔️ V: $versionNum " >$TMP/msg_file
     printf " --------- 📩 MAIL 📩 ---------------\n" >>$TMP/msg_file
     (
          w3m -cookie -o http_proxy=$PROXY -o accept_encoding=UTF-8 -dump "${URL}/mail" -o user_agent="$(shuf -n1 $TMP/userAgent.txt)" | tee $TMP/info_file | sed -n '/[|]\ mp/,/\[arrow\]/p' | sed '1,1d;$d;6q' >>$TMP/msg_file
     ) </dev/null &>/dev/null &
     time_exit 17
     printf " --------- 💬 CHAT TITANS 🔱 ---------\n" >>$TMP/msg_file
     (
          w3m -cookie -o http_proxy=$PROXY -o accept_encoding=UTF-8 -dump "${URL}/chat/titans/changeRoom" -o user_agent="$(shuf -n1 $TMP/userAgent.txt)" | sed -n '/\(\»\)/,/\[chat\]/p' | sed '$d;6q' >>$TMP/msg_file
     ) </dev/null &>/dev/null &
     time_exit 17
     printf " --------- 💬 CHAT CLAN 🛡️ -----------\n" >>$TMP/msg_file
     (
          w3m -cookie -o http_proxy=$PROXY -o accept_encoding=UTF-8 -dump "${URL}/chat/clan/changeRoom" -o user_agent="$(shuf -n1 $TMP/userAgent.txt)" | sed -ne '/\[[^a-z]\]/,/\[chat\]/p' | sed '$d;8q' >>$TMP/msg_file
     ) </dev/null &>/dev/null &
     time_exit 17
     sed -i 's/\[0\]/🔴/g;s/\[0-off\]/⭕/g;s/\[1\]/🔵/g;s/\[1-off\]/🔘/g;s/\[premium\]/👑/g;s/\[level\]/🔼/g;s/\[mail\]/📩/g;s/\[bot\]/⚫/g' msg_file >>$TMP/msg_file
     printf " --------------------------------------\n" >>$TMP/msg_file
     local TRAIN="~/twm/.${UR}/TRAIN"
     if [ ! -e "~/twm/.${UR}/TRAIN" ] || find "$TRAIN" -mmin +30 >/dev/null 2>&1; then
          hpmp -fix
     fi
     echo -e "${GREENb_BLACK}🧡 HP $NOWHP - ${HPPER}% | 🔷 MP $NOWMP - ${MPPER}%${COLOR_RESET}" >>"$TMP"/msg_file
     # sed :a;N;s/\n//g;ta |
     echo -e "${GREENb_BLACK}${ACC}$(grep -o -E '(lvl [0-9]{1,2} \| g [0-9]{1,3}[^0-9]{0,1}[0-9]{0,3}[A-Za-z]{0,1} \| s [0-9]{1,3}[^0-9]{0,1}[0-9]{0,3}[A-Za-z]{0,1})' "$TMP"/info_file | sed 's/lvl/\ lvl/g;s/g/\🪙 g/g;s/s/\🥈 s/g')${COLOR_RESET}" >>"$TMP"/msg_file
}
