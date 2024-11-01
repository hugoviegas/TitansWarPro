# shellcheck disable=SC2155
# shellcheck disable=SC2154
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
            ;;
            gather*)
                echo_t "Start mining" "" "" "after" "⛏️"
            ;;
            runaway*)
                echo_t "Run away" "" "" "after" "💨"
            ;;
            speedUp*)
                echo_t "Speed up mining" "" "" "after" "⚡"
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
            ((count++))  # Incrementar contador
          ;;
        gather*)
            echo_t "Start mining" "" "" "after" "⛏️"
          ;;
        runaway*)
            echo_t "Run away" "" "" "after" "💨"
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

    echo_t "Cave" "${GREEN_BLACK}" "${COLOR_RESET}" "✅\n\n"  
}
