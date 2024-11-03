# shellcheck disable=SC2155
# shellcheck disable=SC2154

bottom_info(){
    echo -e "${GREENb_BLACK}🧡 HP $NOWHP - ${HPPER}% | 🔷 MP $NOWMP - ${MPPER}%${COLOR_RESET}" > "$TMP"/bottom_file
    printf " 👷‍♂️${ACC} | $(w3m -dump -T text/html $TMP/SRC | grep -o -E '(g [0-9]{1,3}[^0-9]{0,1}[0-9]{0,3}[A-Za-z]{0,1} \| s [0-9]{1,3}[^0-9]{0,1}[0-9]{0,3}[A-Za-z]{0,1})' | sed 's/g/🪙 g/g;s/s/🥈 s/g')" >> "$TMP/bottom_file"
    printf "\n" >> "$TMP/bottom_file"
    cat "$TMP/bottom_file"
}
cave_start() {
  clan_id

  fetch_page "/cave/"
  local BREAK=$(($(date +%s) + 1800))
  local count=0
  while echo "$RUN" | grep -q -E '[-]cv' && [ "$(date +%s)" -lt "$BREAK" ]; do
      # Get the first cave action
      
      local CAVE=$(grep -o -E '/cave/(gather|down|runaway|speedUp)/[?]r[=][0-9]+' "$TMP"/SRC | sed -n '1p')
      local RESULT=$(echo "$CAVE" | cut -d'/' -f3)

      #echo -e "DEBUG: $BREAK .\n $CAVE .\n $count .\n$RESULT"
      #echo -e "$count and $RESULT .\n" 
      # Break the loop if speedUp is found and count is less than 8
      if [[ "$RESULT" == "speedUp" && "$count" -ge 20 ]]; then
        echo " Cave limit reached ⚡"
        "$HOME"/twm/twm.sh -boot  # Run in boot mode
        return 1
      fi

      # Process the current cave action
      case $RESULT in
        gather|down|runaway|speedUp)
          # Fetch page and process action
          fetch_page "$CAVE" 

          # Feedback based on the current action
          case $RESULT in
            down*)
                echo_t "New search" "" "" "after" "🔍"
                ((count++))  # Incrementar contador
                bottom_info
            ;;
            gather*)
                echo_t "Start mining" "" "" "after" "⛏️"
                bottom_info
            ;;
            runaway*)
                echo_t "Running away" "" "" "after" "💨"
                bottom_info
            ;;
            speedUp*)
                echo_t "Speeding up mining" "" "" "after" "⚡"
                bottom_info
            ;;
         esac
          ;;
      esac

      # Fetch new cave data
      fetch_page "/cave/"
    
        if awk -v smodplay="$RUN" -v rmodplay="-cv" 'BEGIN { exit !(smodplay != rmodplay) }'; then
        echo -e "\nYou can run ./twm/play.sh -cv"
        fi
        unset ACCESS1 ACCESS2 ACTION DOWN MEGA
    done
  echo -e "${GREEN_BLACK}Cave Done ✅${COLOR_RESET}\n"
  echo "-boot" > "$HOME/twm/runmode_file"  # Change the run mode and save to a file
  restart_script
}

cave_routine() {
  echo_t "Cave" "$GOLD_BLACK" "$COLOR_RESET" "after" "🪨"

  # Checking for available quests
  if checkQuest 5 apply; then
    count=0
    echo_t "Quests available speeding up mine to complete!"
  else
    count=8
  fi

  # Fetch initial cave data
  fetch_page "/cave/"

  # Check for available actions in the cave
    # Start the main loop
    while true; do
      # Get the first cave action
      local CAVE=$(grep -o -E '/cave/(gather|down|runaway|speedUp)/[?]r[=][0-9]+' "$TMP"/SRC | sed -n '1p')
      local RESULT=$(echo "$CAVE" | cut -d'/' -f3)

      #echo -e "$count and $RESULT .\n" 
      # Break the loop if speedUp is found and count is less than 8
        if [[ "$RESULT" == "speedUp" && "$count" -ge 8 ]]; then
            echo_t "Cave limit reached" "" "" "after" "⛏️"
        break
      fi

      # Process the current cave action
    case $RESULT in
        gather|down|runaway|speedUp)
        # Fetch page and process action
        fetch_page "$CAVE"

        # Feedback based on the current action
        case $RESULT in
            down*)
                echo_t "New search" "" "" "after" "🔍"
                count=$((count+1))  # Incrementar contador
            ;;
            gather*)
                echo_t "Start mining" "" "" "after" "⛏️"
            ;;
            runaway*)
                echo_t "Running away" "" "" "after" "💨"
            ;;
            speedUp*)
                echo_t "Speed up mining" "" "" "after" "⚡"
            ;;
        esac
        ;;
    esac

      # Fetch new cave data
      fetch_page "/cave/"
    done

    checkQuest 5 end

    echo_t "Cave" "${GREEN_BLACK}" "${COLOR_RESET}" "after" "✅\n"  
}
