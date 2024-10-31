# shellcheck disable=SC2148
login_logoff () {
 if [ -f "$TMP/cript_file" ]; then
  cat $TMP/cript_file | base64 -d > $TMP/cookie_file
  chmod 600 $TMP/cookie_file
  (
   w3m -cookie -o http_proxy=$PROXY -post $TMP/cookie_file -dump "$URL/?sign_in=1" -o user_agent="$(shuf -n1 $TMP/userAgent.txt)" &>/dev/null
  ) </dev/null &>/dev/null &
  time_exit 17
  echo -e "$(translate_and_cache "$LANGUAGE" "Setting session cookie...")"
  (
   w3m -cookie -o http_proxy=$PROXY -post $TMP/cookie_file -dump "$URL/?sign_in=1" -o user_agent="$(shuf -n1 $TMP/userAgent.txt)" &>/dev/null
  ) </dev/null &>/dev/null &
  time_exit 17
  echo -e "$(translate_and_cache "$LANGUAGE" "Session configured.")"
  rm $TMP/cookie_file &>/dev/null
 fi

 (
  w3m -cookie -o http_proxy=$PROXY -dump "$URL/user" -o user_agent="$(shuf -n1 $TMP/userAgent.txt)" | grep "\[level" | grep -o -E "[[:space:]][[:upper:]][[:lower:]]{0,15}[[:space:]]{0,1}[[:upper:]]{0,1}[[:lower:]]{0,14}[[:space:]]" > $TMP/acc_file
 ) </dev/null &>/dev/null &
 time_exit 17

 echo -e "$(translate_and_cache "$LANGUAGE" "Checking if user matches...")"
 sed -i 's/^[ \t]*//;s/[ \t]*$//' $TMP/acc_file
 ACC=$(cat $TMP/acc_file)

 if [ -n "$ACC" ] && [ -n "$URL" ]; then
  local check=3

  until [ "$check" -lt 1 ]; do
   clear
   echo -e "$(translate_and_cache "$LANGUAGE" "Please wait...")"
   echo -e "$(translate_and_cache "$LANGUAGE" "[Wait to *$ACC*... (${check}s) - press ENTER to change account]")"
   local check=$((check - 1))
   if read -t 1; then
    ACC=""
    unset FIXHP FIXMP STATUS NOWHP NOWMP HPPER MPPER
    break
   fi
  done
 fi

 clear
 echo -e "$(translate_and_cache "$LANGUAGE" "Please wait...")"

 while [ -z "$ACC" ] && [ -n "$URL" ]; do

  log_in () {
   #/logoff
   (
    w3m -cookie -o http_proxy=$PROXY -dump "$URL/?exit" -o user_agent="$(shuf -n1 $TMP/userAgent.txt)" &>/dev/null
   ) </dev/null &>/dev/null &
   time_exit 17
   echo -e "${BLACK_YELLOW}$(translate_and_cache "$LANGUAGE" "In case of error will repeat")${COLOR_RESET}"
   echo -e "$(translate_and_cache "$LANGUAGE" "Username: ")"
   read username
   local prompt="$(translate_and_cache "$LANGUAGE" "Password: ")"
   local charcount=0

   while read -p "$prompt" -r -s -n 1 char; do

    #/NULL - @ - accept password
    if [ "$char" = $'\0' ] || [ "$char" = $'\400' ]; then
     break &>/dev/null
    fi

    #/ESC - DEL
    if [ "$char" = $'\177' ] || [ "$char" = $'\577' ]; then

     if [ "$charcount" -gt 0 ]; then
      local charcount=$((charcount - 1))
      local prompt=$(echo -n $'\b \b')
      local password=$(echo "$password" | sed 's/.$//')
     else
      local prompt=$(echo -n '')
     fi

    else
     local charcount=$((charcount + 1))
     local prompt=$(echo -n '*')
     local password="${password}${char}"
    fi

   done

   echo -e "$(translate_and_cache "$LANGUAGE" "Please wait...")"

   #/cryptography
   if [ -z "$ACC" ]; then
    echo "login=$username&pass=$password" | base64 -w 0 > $TMP/cript_file
    chmod 600 $TMP/cript_file
    #/decryption
    cat $TMP/cript_file | base64 -d > $TMP/cookie_file
    chmod 600 $TMP/cookie_file
   else
    cat $TMP/cript_file | base64 -d > $TMP/cookie_file
    chmod 600 $TMP/cookie_file
   fi

   #/login2x
   unset username password
   (
    w3m -cookie -o http_proxy=$PROXY -post $TMP/cookie_file -dump "$URL/?sign_in=1" -o user_agent="$(shuf -n1 $TMP/userAgent.txt)" &>/dev/null
   ) </dev/null &>/dev/null &
   time_exit 17
   echo -e "$(translate_and_cache "$LANGUAGE" "Setting session cookie...")"
   (
    w3m -cookie -o http_proxy=$PROXY -post $TMP/cookie_file -dump "$URL/?sign_in=1" -o user_agent="$(shuf -n1 $TMP/userAgent.txt)" &>/dev/null
   ) </dev/null &>/dev/null &
   time_exit 17
   echo -e "$(translate_and_cache "$LANGUAGE" "Session configured.")"
   rm $TMP/cookie_file &>/dev/null
  }
  log_in

  clear
  echo -e "$(translate_and_cache "$LANGUAGE" "Please wait...")"
  (
   w3m -cookie -o http_proxy=$PROXY -debug "$URL/user" -o user_agent="$(shuf -n1 $TMP/userAgent.txt)" | grep "\[level" | grep -o -E "[[:space:]][[:upper:]][[:lower:]]{0,15}[[:space:]]{0,1}[[:upper:]]{0,1}[[:lower:]]{0,14}[[:space:]]" > $TMP/acc_file
  ) </dev/null &>/dev/null &
  time_exit 17
  echo -e "$(translate_and_cache "$LANGUAGE" "Checking if user matches...")"
  ACC=$(cat $TMP/acc_file)

  if [ -n "$ACC" ]; then
   break &>/dev/null
  fi

 done
 messages_info
 clan_id
 #start
}
