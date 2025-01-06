#!/bin/bash
# shellcheck disable=SC2034
# Function to define color codes for terminal output
colors() {
    # Font colors with formatting and background options
    BLACK_BLACK='\033[00;30m'       # Black text on default background
    BLACK_CYAN='\033[01;36m\033[01;07m'  # Bold cyan text with inverted colors
    BLACK_GREEN='\033[00;32m\033[01;07m' # Bold green text with inverted colors
    BLACK_GRAY='\033[01;30m\033[01;07m'  # Bold gray text with inverted colors
    BLACK_PINK='\033[01;35m\033[01;07m'  # Bold pink text with inverted colors
    BLACK_RED='\033[01;31m\033[01;07m'    # Bold red text with inverted colors
    BLACK_YELLOW='\033[00;33m\033[01;07m' # Bold yellow text with inverted colors
    CYAN_BLACK='\033[04;36m\033[02;04m'   # Underlined cyan text with dim background
    CYAN_CYAN='\033[01;36m\033[08;07m'     # Bright cyan text on dark background
    BLUE_BLACK='\033[0;34m'                # Blue text on default background
    COLOR_RESET='\033[00m'                 # Reset to default color
    GOLD_BLACK='\033[0;33m'                   # Gold text on default background
    GREEN_BLACK='\033[32m'                  # Green text on default background
    GREENb_BLACK='\033[1;32m'               # Bold green text on default background
    RED_BLACK='\033[0;31m'                  # Red text on default background
    PURPLEi_BLACK='\033[03;34m\033[02;03m'  # Dim purple text with additional formatting
    PURPLEis_BLACK='\033[03;34m\033[02;04m' # Bold purple text with additional formatting
    WHITE_BLACK='\033[37m'                  # White text on default background
    WHITEb_BLACK='\033[01;38m\033[05;01m'   # Bold white text with blinking effect
}

script_slogan() {
    colors="10 8 2 1 3 6 7"
    author="Hugo Viegas"
    #collaborator="collaborator: @_hviegas"
    versionNum="3.9.10" # to change the version number every time has an update!!!!!!!!!!!!!!

for i in $colors; do
clear
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
printf "\033[1;38;5;${i}mMod author: ${author}\n\033[02m"
printf "Version: ${versionNum}${COLOR_RESET}\n"
sleep 0.2s
done
}

language_setup() {
    LANGUAGE_FILE="$HOME/twm/language_file"  # Caminho para o arquivo de idioma
    
    # Verifica se o arquivo existe e se contém um idioma válido
    if [ -f "$LANGUAGE_FILE" ] && [ -s "$LANGUAGE_FILE" ]; then
        LANGUAGE=$(cat "$LANGUAGE_FILE")
    else
        LANGUAGE="en"  # Define o idioma para o padrão
        echo "$LANGUAGE" > "$LANGUAGE_FILE"  # Salva o idioma padrão no arquivo
    fi

    # Exporta a variável para torná-la disponível globalmente
    export LANGUAGE
}
language_setup

# Função para imprimir com printf, usando tradução e cores
printf_t() {
  local_text="$1"
  local_color_start="$2"
  local_color_end="$3"
  local_emoji_position="$4"  # "before" ou "after"
  local_emoji="$5"

  # Traduz o texto
  local_translated_text="$(translate_and_cache "$LANGUAGE" "$local_text")"

  # Adiciona o emoji conforme a posição especificada
  if [ "$local_emoji_position" = "before" ]; then
    printf "${local_color_start}%s %s${local_color_end}\n" "$local_emoji" "$local_translated_text"
  else
    printf "${local_color_start}%s %s${local_color_end}\n" "$local_translated_text" "$local_emoji"
  fi
}

# Função para imprimir com echo, usando tradução e cores
echo_t() {
  local_text="$1"
  local_color_start="$2"
  local_color_end="$3"
  local_emoji_position="$4"  # "before" ou "after"
  local_emoji="$5"

  # Traduz o texto
  local_translated_text="$(translate_and_cache "$LANGUAGE" "$local_text")"

  # Adiciona o emoji conforme a posição especificada
  if [ "$local_emoji_position" = "before" ]; then
    echo -ne "${local_color_start}${local_emoji} ${local_translated_text}${local_color_end}"
  else
    echo -e "${local_color_start}${local_translated_text} ${local_emoji}${local_color_end}"
  fi
}

time_exit() {
    # Function to monitor a background process and terminate it if it exceeds a specified timeout.
    (
        # Get the PID of the last background command
        local TEFPID
        local TELOOP
        TEFPID=$(echo "$!" | grep -o -E '([0-9]{2,6})')
        # Loop for the specified number of seconds, counting down
        # shellcheck disable=SC2034
        for TELOOP in $(seq "$1" -1 1); do
            sleep 1s  # Sleep for 1 second
            
            # Check if the process is still running
            if ! kill -0 "$TEFPID" 2>/dev/null; then
                return 0  # Process finished successfully
            fi
        done

        # If we reach this point, the timeout has been exceeded
        kill -s PIPE "$TEFPID" > /dev/null 2>&1
        kill -15 "$TEFPID" > /dev/null 2>&1
        
        # Notify the user that the command execution was interrupted
        #printf "${WHITEb_BLACK}%s${COLOR_RESET}\n" "$(translate_and_cache "$LANGUAGE" "Command execution was interrupted!")"
        printf_t "Command execution was interrupted!" "$WHITEb_BLACK" "$COLOR_RESET" "before" "⚠️" >> "$TMP/ERROR_DEBUG"

    )
}

#Access any page link
fetch_page() {
    local relative_url="$1"  # The specific part of the URL you want to fetch (e.g., "/quest/")
    local output_file="${2:-$TMP/SRC}"  # Use the second argument if provided, otherwise default to $TMP/SRC

    (
        w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}${relative_url}" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" > "$output_file"
    ) </dev/null > /dev/null 2>&1  # Run in background and suppress output

    time_exit 17  # Wait for the process to finish
}

hpmp() {
    # Options: -fix or -now

    # Check if the -fix option is provided
    if echo "$@" | grep -q '\-fix'; then
        # Fetch the train page to get HP and MP values
        (
            w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "$URL/train" -o user_agent="$(shuf -n1 userAgent.txt)" >"$TMP"/TRAIN
        ) </dev/null > /dev/null 2>&1 &
        time_exit 20
        #/Fixed HP and MP.
        #/Needs to run -fix at least once before
        FIXHP=$(grep -o -E '\(([0-9]+)\)' "$TMP"/TRAIN | sed 's/[()]//g')
        FIXMP=$(grep -o -E ': [0-9]+' "$TMP"/TRAIN | sed -n '5s/: //p')
    fi

    #/$NOW/HP|MP can be obtained from any SRC file
    NOWHP=$(grep -o -E "<img src[=]'/images/icon/health.png' alt[=]'hp'/> <span class[=]'(dred|white)'>[ ]?[0-9]{1,7}[ ]?</span> \| <img src[=]'/images/icon/mana.png' alt[=]'mp'/>" "$TMP"/SRC | tr -c -d '[:digit:]')
    NOWMP=$(grep -o -E "</span> \| <img src='/images/icon/mana.png' alt='mp'/>[ ]?[0-9]{1,7}[ ]?</span><div class='clr'></div></div>" "$TMP"/SRC | tr -c -d "[:digit:]")

    # Calculate percentage of HP and MP based on fixed values
    HPPER=$(awk -v nowhp="$NOWHP" -v fixhp="$FIXHP" 'BEGIN { printf "%.3f", nowhp / fixhp * 100 }' | awk '{printf "%.2f\n", $1}')
    MPPER=$(awk -v nowmp="$NOWMP" -v fixmp="$FIXMP" 'BEGIN { printf "%.3f", nowmp / fixmp * 100 }' | awk '{printf "%.2f\n", $1}')
}

messages_info() {
     echo " ⚔️ - Titans War Macro - ⚔️ V: $versionNum " > "$TMP"/msg_file
     printf " --------- 📩 MAIL 📩 ---------------\n" >> "$TMP"/msg_file
    (
          w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -dump "${URL}/mail" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" | tee "$TMP"/info_file | sed -n '/[|]\ mp/,/\[arrow\]/p' | sed '1,1d;$d;6q' >> "$TMP"/msg_file
    ) </dev/null > /dev/null 2>&1 &
    time_exit 17
     printf " --------- 💬 CHAT TITANS 🔱 ---------\n" >> "$TMP"/msg_file
    (
          w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -dump "${URL}/chat/titans/changeRoom" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" | sed -n '/\(\»\)/,/\[chat\]/p' | sed '$d;6q' >> "$TMP"/msg_file
    ) </dev/null > /dev/null 2>&1 &
    time_exit 17
     printf " --------- 💬 CHAT CLAN 🛡️ -----------\n" >> "$TMP"/msg_file
    (
          w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -dump "${URL}/chat/clan/changeRoom" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" | sed -n '/\[[^a-z]\]/,/\[chat\]/p' | sed '$d;8q' >> "$TMP"/msg_file
    ) </dev/null > /dev/null 2>&1 &
    time_exit 17
     sed -i 's/\[0\]/🔴/g;s/\[0-off\]/⭕/g;s/\[1\]/🔵/g;s/\[1-off\]/🔘/g;s/\[premium\]/👑/g;s/\[level\]/🔼/g;s/\[mail\]/📩/g;s/\[bot\]/⚫/g' "$TMP"/msg_file
     printf " --------------------------------------\n" >> "$TMP"/msg_file
    local_TRAIN="$HOME.${UR}/TRAIN"
     if [ ! -e "$local_TRAIN" ] || find "$local_TRAIN" -mmin +30 >/dev/null 2>&1; then
        hpmp -fix
    fi
     echo -e "${GREENb_BLACK}🧡 HP $NOWHP - ${HPPER}% | 🔷 MP $NOWMP - ${MPPER}%${COLOR_RESET}" >> "$TMP"/msg_file
     # sed :a;N;s/\n//g;ta |
     echo -e "${GREENb_BLACK}${ACC}$(grep -o -E '(lvl [0-9]{1,2} \| g [0-9]{1,3}[^0-9]{0,1}[0-9]{0,3}[A-Za-z]{0,1} \| s [0-9]{1,3}[^0-9]{0,1}[0-9]{0,3}[A-Za-z]{0,1})' "$TMP"/info_file | sed 's/lvl/\ lvl/g;s/g/\🪙 g/g;s/s/\🥈 s/g')${COLOR_RESET}" >>"$TMP"/msg_file
}

player_stats() {
    fetch_page "/train"

    # Print the raw content for debugging
    # echo "Raw content from /train:"
    # cat "$TMP"/TRAIN  # Check the raw output for stats

    # Extracting stats using grep and sed
    STRENGTH=$(grep -o -E ': [0-9]+' "$TMP"/SRC | sed -n '1s/: //p')
    HEALTH=$(grep -o -E '\(([0-9]+)\)' "$TMP"/SRC | sed '2s/: //p')
    AGILITY=$(grep -o -E ': [0-9]+' "$TMP"/SRC | sed -n '3s/: //p')
    PROTECTION=$(grep -o -E ': [0-9]+' "$TMP"/SRC | sed -n '4s/: //p')

    # Trim whitespace and ensure that STRENGTH only contains numbers
    PLAYER_STRENGTH=$(echo "$STRENGTH" | xargs)
    PLAYER_STRENGTH=${PLAYER_STRENGTH//[^0-9]/}

    echo "$PLAYER_STRENGTH"
}
