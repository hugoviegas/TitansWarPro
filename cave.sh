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
              echo " New search 🔍"
              ((count++))  # Increment count by 1
              ;;
            gather*)
              echo " Start mining ⛏️"
              ;;
            runaway*)
              echo " Run away 💨"
              ;;
            speedUp*)
              echo " Speed up mining ⚡"
              ;;
          esac
          ;;
      esac

      # Fetch new cave data
      fetch_page "/cave/"

    # checkQuest 5

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
  echo -e "${GOLD_BLACK}Cave 🪨${COLOR_RESET}"

  # Checking for available quests
  if checkQuest 5; then
    count=0
    echo "Quests available speeding up mine to complete!"
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
        tput cuu1; tput el; echo " Cave limit reached ⚡"
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
              tput cuu1; tput el; echo " New search 🔍"
              ((count++))  # Increment count by 1
              ;;
            gather*)
              tput cuu1; tput el; echo " Start mining ⛏️"
              ;;
            runaway*)
              tput cuu1; tput el; echo " Run away 💨"
              ;;
            speedUp*)
              tput cuu1; tput el; echo " Speed up mining ⚡"
              ;;
          esac
          ;;
      esac

      # Fetch new cave data
      fetch_page "/cave/"
    done

    checkQuest 5

  echo -e "${GREEN_BLACK}Cave Done ✅${COLOR_RESET}\n"
}
