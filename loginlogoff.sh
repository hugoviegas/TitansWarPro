# shellcheck disable=SC2148
login_logoff () {
 if [ -f "$TMP/cript_file" ]; then
  cat $TMP/cript_file | base64 -d > $TMP/cookie_file
  chmod 600 $TMP/cookie_file
  (
   w3mc -cookie -o http_proxy=$PROXY -post $TMP/cookie_file -dump "$URL/?sign_in=1" -o user_agent="$(shuf -n1 $TMP/userAgent.txt)" &>/dev/null
  ) </dev/null &>/dev/null &
  time_exit 17
  echo_t "Setting session cookie..."
  (
   w3mc -cookie -o http_proxy=$PROXY -post $TMP/cookie_file -dump "$URL/?sign_in=1" -o user_agent="$(shuf -n1 $TMP/userAgent.txt)" &>/dev/null
  ) </dev/null &>/dev/null &
  time_exit 17
  echo_t "Session configured."
  rm $TMP/cookie_file &>/dev/null
 fi

 (
  w3mc -cookie -o http_proxy=$PROXY -dump "$URL/user" -o user_agent="$(shuf -n1 $TMP/userAgent.txt)" | grep "\[level" | grep -o -E "[[:space:]][[:upper:]][[:lower:]]{0,15}[[:space:]]{0,1}[[:upper:]]{0,1}[[:lower:]]{0,14}[[:space:]]" > $TMP/acc_file
 ) </dev/null &>/dev/null &
 time_exit 17

 echo_t "Checking if user matches..."
 sed -i 's/^[ \t]*//;s/[ \t]*$//' $TMP/acc_file
 ACC=$(cat $TMP/acc_file)

 if [ -n "$ACC" ] && [ -n "$URL" ]; then
    check=4

  until [ "$check" -lt 1 ]; do
   [ -t 1 ] && clear
   echo_t "Please wait..."
   echo -ne "${GOLD_BLACK}> [$ACC] ${COLOR_RESET}- "
   echo_t "To change your user account press the button" "" "${GOLD_BLACK} [ENTER] ${check}s ...${COLOR_RESET}"

    check=$((check - 1))
   if read -t 1; then
    ACC=""
    unset FIXHP FIXMP STATUS NOWHP NOWMP HPPER MPPER
    break
   fi
  done
 fi

 [ -t 1 ] && clear
 echo_t "Please wait..."

 # Add login attempt counter to prevent infinite loop
 LOGIN_ATTEMPTS=0
 MAX_LOGIN_ATTEMPTS=3

 while [ -z "$ACC" ] && [ -n "$URL" ] && [ "$LOGIN_ATTEMPTS" -lt "$MAX_LOGIN_ATTEMPTS" ]; do

  log_in () {
   #/logoff
   (
    w3mc -cookie -o http_proxy=$PROXY -dump "$URL/?exit" -o user_agent="$(shuf -n1 $TMP/userAgent.txt)" &>/dev/null
   ) </dev/null &>/dev/null &
   time_exit 17
   echo_t "In case of error will repeat" "${BLACK_YELLOW}" "${COLOR_RESET}"
   echo_t "Username: "
   read -r username

   # Check if username was read successfully
   if [ -z "$username" ]; then
    echo_t "ERROR: Could not read username. Input stream may be unavailable." "${RED_BLACK}" "${COLOR_RESET}"
    echo_t "Please run the script with a proper terminal (TTY)." "${RED_BLACK}" "${COLOR_RESET}"
    return 1
   fi

    prompt="$(translate_and_cache "$LANGUAGE" "Password: ")"
    charcount=0

   while read -p "$prompt" -r -s -n 1 char; do

    #/NULL - @ - accept password
    if [ "$char" = $'\0' ] || [ "$char" = $'\400' ]; then
     break &>/dev/null
    fi

    #/ESC - DEL
    if [ "$char" = $'\177' ] || [ "$char" = $'\577' ]; then

     if [ "$charcount" -gt 0 ]; then
    charcount=$((charcount - 1))
    prompt=$(echo -n $'\b \b')
    password=$(echo "$password" | sed 's/.$//')
     else
    prompt=$(echo -n '')
     fi

    else
    charcount=$((charcount + 1))
    prompt=$(echo -n '*')
    password="${password}${char}"
    fi

   done

   echo_t "Please wait..." "\n"

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
    w3mc -cookie -o http_proxy=$PROXY -post $TMP/cookie_file -dump "$URL/?sign_in=1" -o user_agent="$(shuf -n1 $TMP/userAgent.txt)" &>/dev/null
   ) </dev/null &>/dev/null &
   time_exit 17
   echo_t "Setting session cookie..."
   (
    w3mc -cookie -o http_proxy=$PROXY -post $TMP/cookie_file -dump "$URL/?sign_in=1" -o user_agent="$(shuf -n1 $TMP/userAgent.txt)" &>/dev/null
   ) </dev/null &>/dev/null &
   time_exit 17
   echo_t "Session configured."
   rm $TMP/cookie_file &>/dev/null
  }
  log_in || break

  [ -t 1 ] && clear
  echo_t "Please wait..."
  (
   w3mc -cookie -o http_proxy=$PROXY -debug "$URL/user" -o user_agent="$(shuf -n1 $TMP/userAgent.txt)" | grep "\[level" | grep -o -E "[[:space:]][[:upper:]][[:lower:]]{0,15}[[:space:]]{0,1}[[:upper:]]{0,1}[[:lower:]]{0,14}[[:space:]]" > $TMP/acc_file
  ) </dev/null &>/dev/null &
  time_exit 17
  echo_t "Checking if user matches..."
  ACC=$(cat $TMP/acc_file)

  if [ -z "$ACC" ]; then
   LOGIN_ATTEMPTS=$((LOGIN_ATTEMPTS + 1))
   if [ "$LOGIN_ATTEMPTS" -lt "$MAX_LOGIN_ATTEMPTS" ]; then
    echo_t "Login failed. Attempt $LOGIN_ATTEMPTS of $MAX_LOGIN_ATTEMPTS" "${RED_BLACK}" "${COLOR_RESET}"
    sleep 2
   fi
  fi

 done

 # If max attempts reached, show error and exit
 if [ "$LOGIN_ATTEMPTS" -ge "$MAX_LOGIN_ATTEMPTS" ] && [ -z "$ACC" ]; then
  echo_t "ERROR: Maximum login attempts ($MAX_LOGIN_ATTEMPTS) reached." "${RED_BLACK}" "${COLOR_RESET}"
  echo_t "Unable to authenticate. Exiting." "${RED_BLACK}" "${COLOR_RESET}"
  sleep 3
  exit 1
 fi

 messages_info
 clan_id
 #start
}
