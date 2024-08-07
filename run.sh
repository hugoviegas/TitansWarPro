twm_play () {
 restart_script () {
  # shellcheck disable=SC2317
  if [ "$RUN" != '-boot' ]; then
   pidf=$(ps ax -o pid=,args=|grep "sh.*twm/twm.sh"|grep -v 'grep'|head -n 1|grep -o -E '([0-9]{3,5})')
   until [ -z "$pidf" ]; do
    kill -9 $pidf 2> /dev/null
    pidf=$(ps ax -o pid=,args=|grep "sh.*twm/twm.sh"|grep -v 'grep'|head -n 1|grep -o -E '([0-9]{3,5})')
    sleep 1s
   done
  fi
 }
 if [ ! -s "$TMP/CLD" ]; then
  clan_id
 fi
 #/game time
 case $(date +%H:%M) in
  #/No events time with coliseum
  (00:[0-5]5|01:[0-5]5|02:[0-5]5|03:[0-5]5)
   coliseum_fight
   coliseum_start
  ;;
  (00:00|00:30|01:00|01:30|02:00|02:30|03:00|03:30|04:00|04:30|05:00|05:30|06:00|06:30|07:00|07:30|08:00|08:30|09:00|09:30|11:30|12:00|13:00|13:30|14:30|15:30|17:00|17:30|18:00|18:30|19:30|20:00|20:30|23:00|23:30)
   start
  ;;
  #/Valley of the Immortals 10:00:00 - 16:00:00 - 22:00:00
  (09:5[5-9]|15:5[5-9]|21:5[5-9])
   undying_start
   start
  ;;
  #/Flag Fight 10:15:00 - 16:15:00
  # (10:1[0-4]|16:1[0-4])
  # flagfight_start
  # start
  # ;;
  #/Clan coliseum 10:30:00 - 15:00:00
  (10:2[8-9]|14:5[8-9])
   if [ -n $CLD ]; then
    clancoliseum_start
   fi
   start
  ;;
  #/Clan tournament 11:00:00 - 19:00:00
  (10:5[5-9]|18:5[5-9])
   if [ -n $CLD ]; then
    clanfight_start
   fi
   start
  ;;
  #/King of the Immortals 12:30:00 - 16:30:00 - 22:30:00
  (12:2[5-9]|16:2[5-9]|22:2[5-9])
   king_start
   start
  ;;
  #/Ancient Altars 14:00:00 - 21:00:00
  (13:5[5-9]|20:5[5-9])
   if [ -n $CLD ]; then
    altars_start
   fi
   start
  ;;
  (21:30) #/Clan dmg  09:30:00 - 21:30:00
   #_clandmgfight
   start
  ;;
  (*)
   if echo "$RUN"|grep -q -E '[-]cl'; then
    echo -e "Running in coliseum mode: $RUN\n"
    sleep 5s
    arena_duel
    coliseum_start
    messages_info
   fi
   func_sleep
   func_crono
  ;;
 esac

}
