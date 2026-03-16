# shellcheck disable=SC2155
# shellcheck disable=SC2154

SILVER_SPENT_TOTAL=0
GOLD_SPENT_TOTAL=0

# funcoes auxiliares

read_boost_gold_cost() {
    BOOST_GOLD_COST=$(
        grep -o -E '/cave/chance/2/[?]r=[0-9]+' "$TMP/SRC" \
        | head -n1 \
        | grep -o -E "gold.png[^0-9]*[0-9][0-9,]*[KMB]?" "$TMP/SRC" \
        | grep -v -E '[KMB]' \
        | head -n1 \
        | sed -E 's/.*gold.png[^0-9]*([0-9][0-9,]*).*/\1/' \
        | tr -d "'"
    )

    # Fallback seguro
    BOOST_GOLD_COST=${BOOST_GOLD_COST:-0}

    # Debug
    # echo "DEBUG: BOOST_GOLD_COST = $BOOST_GOLD_COST"
}

read_speedup_silver_cost() {
    SPEEDUP_SILVER_COST=$(
        grep -o -E '/cave/speedUp/[^ ]+' "$TMP/SRC" \
        | head -n1 \
        | grep -o -E "silver.png[^0-9]*[0-9][0-9,]*[KMB]?" "$TMP/SRC" \
        | grep -v -E '[KMB]' \
        | head -n1 \
        | sed -E 's/.*silver.png[^0-9]*([0-9][0-9,]*).*/\1/' \
        | tr -d ','
    )

    # Fallback seguro
    SPEEDUP_SILVER_COST=${SPEEDUP_SILVER_COST:-0}

    # Debug
    # echo "DEBUG: SPEEDUP_SILVER_COST = $SPEEDUP_SILVER_COST"
}

check_cave_limits() {

  if [ "$CAVE_GOLD_LIMIT" -gt 0 ] && [ "$GOLD_SPENT_TOTAL" -ge "$CAVE_GOLD_LIMIT" ]; then
    echo_t "Gold limit reached (${GOLD_SPENT_TOTAL}/${CAVE_GOLD_LIMIT})" "" "" "after" "🚦"
    CAVE_SHOULD_STOP=1
    return
  fi

  if [ "$CAVE_SILVER_LIMIT" -gt 0 ] && [ "$SILVER_SPENT_TOTAL" -ge "$CAVE_SILVER_LIMIT" ]; then
    echo_t "Silver limit reached (${SILVER_SPENT_TOTAL}/${CAVE_SILVER_LIMIT})" "" "" "after" "🚦"
    CAVE_SHOULD_STOP=1
    return
  fi

}

set_cave_limits() {
  echo_t "Configure expenses in the Cave" "" "" "after" "💸"

  # ouro
  while true; do
    echo_t "Gold limit (0 = unlimited): " "$CAVE_GOLD_LIMIT"
    read -r input_gold

    if [[ -z "$input_gold" ]]; then
      echo_t "Value cannot be empty."
      continue
    fi

    if [[ "$input_gold" =~ ^[0-9]+$ ]]; then
      CAVE_GOLD_LIMIT="$input_gold"
      break
    fi

    echo_t "Invalid value. Please enter numbers only."
  done

  # prata
  while true; do
    echo_t "Silver limit (0 = unlimited): " "$CAVE_SILVER_LIMIT"
    read -r input_silver

    if [[ -z "$input_silver" ]]; then
      echo_t "Value cannot be empty."
      continue
    fi

    if [[ "$input_silver" =~ ^[0-9]+$ ]]; then
      CAVE_SILVER_LIMIT="$input_silver"
      break
    fi

    echo_t "Invalid value. Please enter numbers only."
  done

  echo_t "Defined limits!" "" "" "after" "✅"
  echo_t "Gold: ${CAVE_GOLD_LIMIT}"
  echo_t "Silver: ${CAVE_SILVER_LIMIT}"
  sleep 3s
}

check_cave_keypress() {

  local key
  read -r -t 0.1 -n 1 key 2>/dev/null

  if [ "$key" = "x" ] || [ "$key" = "X" ]; then
    echo_t "Exiting cave mode..." "" "" "after" "🔄"
    CAVE_SHOULD_STOP=1
  fi
}

# funcoes originais

# Map resource ID to name (IDs come from res/N.png in /cave/ HTML)
_cave_resource_name() {
    case "$1" in
        1) echo "Iron";;
        2) echo "Silver Ore";;
        3) echo "Gold Ore";;
        4) echo "Crystal";;
        5) echo "Diamond";;
        6) echo "Herb";;
        7) echo "Mushroom";;
        8) echo "Medicinal Root";;
        9) echo "Rare Herb";;
        *) echo "Resource $1";;
    esac
}

# Display resource probabilities from current SRC (call BEFORE clicking gather)
_cave_display_probabilities() {
    local log_file="${1:-}"
    local ts
    printf -v ts '%(%H:%M)T' -1

    echo_t "Resources found" "${GOLD_BLACK}" "${COLOR_RESET}" "after" "💎"

    # Extract all res/N.png + next percentage pairs from HTML
    # Use [^<]* to match anything except HTML tags (more reliable than [^%])
    grep -oE 'res/[0-9]+\.png[^<]*[0-9]+%' "$TMP/SRC" | while read -r match; do
        [ -z "$match" ] && continue

        # Extract resource ID from res/ID.png
        local id
        id=$(echo "$match" | grep -oE 'res/([0-9]+)' | grep -oE '[0-9]+')
        [ -z "$id" ] && continue

        # Extract percentage
        local pct
        pct=$(echo "$match" | grep -oE '[0-9]+%' | head -1 | tr -d '%')

        local name
        name=$(_cave_resource_name "$id")

        # Log this resource found (for final aggregation)
        echo "$id:$name" >> "$TMP/cave_resources_found.txt"

        echo_t "  ${name}${pct:+ (${pct}%)}" "${GRAY_BLACK}" "${COLOR_RESET}"
    done
}

# Aggregate and display total resources found during session
_cave_display_aggregated_resources() {
    local log_file="${1:-}"

    if [ ! -f "$TMP/cave_resources_found.txt" ]; then
        return
    fi

    echo_t "Resources found summary" "${GOLD_BLACK}" "${COLOR_RESET}" "after" "📊"

    # Sort and count each resource
    sort "$TMP/cave_resources_found.txt" | uniq -c | while read -r count id_name; do
        local name
        name=$(echo "$id_name" | cut -d: -f2)
        echo_t "  ${name}: ${count}" "${GRAY_BLACK}" "${COLOR_RESET}"

        if [ -n "$log_file" ]; then
            local ts
            printf -v ts '%(%H:%M)T' -1
            echo "  [$ts] Found: ${name} x${count}" >> "$log_file"
        fi
    done
}
_cave_is_extraction_page() {
    grep -qE 'res/[0-9]+\.png' "$TMP/SRC" && \
    grep -qiE 'color[^"<>]*green|color[^"<>]*red|class="(green|red)' "$TMP/SRC"
}

# Display extraction results from current SRC using color indicators (call AFTER clicking speedUp)
_cave_display_extraction_results() {
    local log_file="${1:-}"
    local ts
    printf -v ts '%(%H:%M)T' -1
    local extracted_count=0 not_extracted_count=0

    echo_t "Mining results" "${GOLD_BLACK}" "${COLOR_RESET}" "after" "⛏️"

    while IFS= read -r line_num; do
        [ -z "$line_num" ] && continue
        local id
        id=$(sed -n "${line_num}p" "$TMP/SRC" | grep -oE 'res/[0-9]+\.png' | grep -oE '[0-9]+' | head -1)
        [ -z "$id" ] && continue
        local name
        name=$(_cave_resource_name "$id")
        # Check next 8 lines for color indicator (green = extracted, else = not extracted)
        local context
        context=$(sed -n "${line_num},$((line_num + 8))p" "$TMP/SRC")
        local extracted=0
        if echo "$context" | grep -qiE 'color[^"<>]*green|class="green|style="[^"]*green'; then
            extracted=1
        fi

        if [ "$extracted" -eq 1 ]; then
            echo_t "  ${name}: Extracted" "${GREEN_BLACK}" "${COLOR_RESET}" "after" "✅"
            extracted_count=$((extracted_count + 1))
            [ -n "$log_file" ] && echo "  [$ts] ${name}: extracted" >> "$log_file"
        else
            echo_t "  ${name}: Not extracted" "${RED_BLACK}" "${COLOR_RESET}" "after" "❌"
            not_extracted_count=$((not_extracted_count + 1))
            [ -n "$log_file" ] && echo "  [$ts] ${name}: not extracted" >> "$log_file"
        fi
    done < <(grep -nE 'res/[0-9]+\.png' "$TMP/SRC" | cut -d: -f1)

    [ -n "$log_file" ] && echo "  [$ts] Mined: ${extracted_count} extracted, ${not_extracted_count} not extracted" >> "$log_file"
}

bottom_info(){
    echo -e "${GREENb_BLACK}🧡 HP $NOWHP - ${HPPER}% | 🔷 MP $NOWMP - ${MPPER}%${COLOR_RESET}" > "$TMP"/bottom_file
    printf " 👷‍♂️${ACC} | $(w3m -dump -T text/html $TMP/SRC | grep -o -E '(g [0-9]{1,3}[^0-9]{0,1}[0-9]{0,3}[A-Za-z]{0,1} \| s [0-9]{1,3}[^0-9]{0,1}[0-9]{0,3}[A-Za-z]{0,1})' | sed 's/g/🪙 g/g;s/s/🥈 s/g') | 🔨 Actions: ${action_count} \n" >> "$TMP/bottom_file"
    echo_t " ~ Press [x] to exit" >> "$TMP/bottom_file"
    cat "$TMP/bottom_file"
}

cave_log() {
  local log_dir="${ACCOUNT_LOGS:-$TMP/logs}"
  local cave_session_log="${log_dir}/cave_session.log"

  if [ ! -f "$cave_session_log" ]; then
      echo_t "No previous cave session log found." "${GRAY_BLACK}" "${COLOR_RESET}" "after" "📭"
      return
  fi

  echo_t "Last Cave Session" "${GOLD_BLACK}" "${COLOR_RESET}" "after" "📜"
  echo ""
  # Show last session only (from last "===" header onwards)
  local last_session
  last_session=$(awk '/^=== Cave Session:/{buf=""} {buf=buf $0 "\n"} END{printf "%s", buf}' "$cave_session_log")
  echo "$last_session"
  echo ""

  # Auto-close after 10s unless user interacts
  echo_t "Clearing log in 10s... Press [k] to keep or [d] to delete now" "${GRAY_BLACK}" "${COLOR_RESET}" "after" "⏱️"
  local choice
  read -r -t 10 -n 1 choice 2>/dev/null
  echo ""

  if [ "$choice" = "d" ] || [ "$choice" = "D" ]; then
      rm -f "$cave_session_log"
      echo_t "Log cleared." "${GREEN_BLACK}" "${COLOR_RESET}" "after" "🗑️"
  else
      echo_t "Log kept." "${GRAY_BLACK}" "${COLOR_RESET}" "after" "✅"
  fi
}

cave_start() {
  clan_id
  fetch_page "/cave/"

  # Ensure RUN is set to cave mode, otherwise set it
  if [[ ! "$RUN" =~ [-]cv ]]; then
    echo_t "Setting cave mode..." "" "" "before" "🔧"
    RUN="-cv"
  fi

  echo_t "Cave session PID: $$" "${GRAY_BLACK}" "${COLOR_RESET}" "after" "🔧"

  # Show previous session log if it exists, then ask to clear
  cave_log

  set_cave_limits

  # Ask about mining effect activation
  local MINING_EFFECT_ACTIVE=0
  {
    echo_t "Activate mining effect?" "" "" "after" "⛏️"
    local effect_choice
    read -r -t 5 -n 1 effect_choice 2>/dev/null

    if [ "$effect_choice" = "y" ] || [ "$effect_choice" = "Y" ]; then
      echo_t "Activating mining effect..." "" "" "after" "✨"
      fetch_page "/effshop/"

      local effect_link
      effect_link=$(grep -o -E '/effshop/12/\?r=[0-9]+' "$TMP/SRC" | head -n 1)

      if [ -n "$effect_link" ]; then
        fetch_page "$effect_link"
        echo_t "Mining effect activated!" "${GREEN_BLACK}" "${COLOR_RESET}" "after" "✅"
        MINING_EFFECT_ACTIVE=1
        sleep 1s
      else
        echo_t "Could not find mining effect" "${RED_BLACK}" "${COLOR_RESET}" "after" "❌"
      fi

      # Return to cave
      fetch_page "/cave/"
    fi
  }

  # Session log setup
  local log_dir="${ACCOUNT_LOGS:-$TMP/logs}"
  mkdir -p "$log_dir"
  local cave_session_log="${log_dir}/cave_session.log"

  # Initialize resource tracking file
  > "$TMP/cave_resources_found.txt"

  # Global timeout (2 hours max)
  local cave_start_time
  printf -v cave_start_time '%(%s)T' -1
  local cave_max_duration=7200
  local action_count=0
  CAVE_SHOULD_STOP=0

  # Write session header to log
  {
    echo ""
    echo "=== Cave Session: $(date '+%Y-%m-%d %H:%M') ==="
    echo "  Account: ${ACC:-unknown} | Gold limit: ${CAVE_GOLD_LIMIT} | Silver limit: ${CAVE_SILVER_LIMIT}"
    echo "  Mining effect: $([ "$MINING_EFFECT_ACTIVE" -eq 1 ] && echo "Active" || echo "Inactive")"
    echo "--- Actions ---"
  } >> "$cave_session_log"

  while [[ "$RUN" =~ [-]cv ]]; do

      # Check global timeout
      local now
      printf -v now '%(%s)T' -1
      local elapsed=$(( now - cave_start_time ))
      if [ "$elapsed" -gt "$cave_max_duration" ]; then
          echo_t "Cave session timeout (2h) - exiting" "${BLACK_RED}" "${COLOR_RESET}" "after" "⏰"
          break
      fi

      local CAVE
      CAVE=$(grep -o -E '/cave/(gather|down|attack|runaway|speedUp)/[?]r[=][0-9]+' "$TMP"/SRC | sed -n '1p')
      local RESULT
      RESULT=$(echo "$CAVE" | cut -d'/' -f3)

      # Retry if no action found (up to 5x with 2s delay)
      local retry_count=0
      while [ -z "$CAVE" ] && [ "$retry_count" -lt 5 ]; do
          retry_count=$((retry_count + 1))
          echo_t "No cave action (attempt ${retry_count}/5). Retrying..." "${GRAY_BLACK}" "${COLOR_RESET}" "after" "⏳"
          sleep 2s
          fetch_page "/cave/"
          CAVE=$(grep -o -E '/cave/(gather|down|attack|runaway|speedUp)/[?]r[=][0-9]+' "$TMP"/SRC | sed -n '1p')
          RESULT=$(echo "$CAVE" | cut -d'/' -f3)
      done

      if [ -z "$CAVE" ]; then
          echo_t "Failed to find cave action after 5 attempts. Exiting." "${RED_BLACK}" "${COLOR_RESET}" "after" "❌"
          break
      fi

      local RESOURCES
      RESOURCES=$(grep -o -E 'res/[0-9]+\.png' "$TMP/SRC" | sed 's/res\///;s/.png//')
      local MINERALS_FOUND
      MINERALS_FOUND=$(echo "$RESOURCES" | grep -cE '^[1-5]$')
      local HERBS_FOUND
      HERBS_FOUND=$(echo "$RESOURCES" | grep -cE '^(6|7|8|9)$')
      local BOOST_LINK
      BOOST_LINK=$(grep -o -E '/cave/chance/2/[?]r=[0-9]+' "$TMP/SRC" | head -n 1)

      local CAN_ATTACK_MONSTER=${CAN_ATTACK_MONSTER:-0}
      local MONSTER_ATTACK
      MONSTER_ATTACK=$(grep -o -E '/cave/attack/[?]r=[0-9]+' "$TMP/SRC" | head -n1)
      local MONSTER_RUNAWAY
      MONSTER_RUNAWAY=$(grep -o -E '/cave/runaway/[?]r=[0-9]+' "$TMP/SRC" | head -n1)

      check_cave_keypress
      [ "${CAVE_SHOULD_STOP:-0}" -eq 1 ] && break

      # Boost: 3 minerals and 0 herbs → increase herb chance
      if [ "$MINERALS_FOUND" -eq 3 ] && [ "$HERBS_FOUND" -eq 0 ] && [ -n "$BOOST_LINK" ]; then
          read_boost_gold_cost
          echo_t "3 ores detected! Increasing chance by 100%" "" "" "after" "✅"
          fetch_page "$BOOST_LINK"
          if [ "$BOOST_GOLD_COST" -gt 0 ]; then
              GOLD_SPENT_TOTAL=$(( GOLD_SPENT_TOTAL + BOOST_GOLD_COST ))
              CAN_ATTACK_MONSTER=1
          fi
      fi

      # Monster control
      if [ -n "$MONSTER_ATTACK" ] && [ -n "$MONSTER_RUNAWAY" ]; then
          if [ "$CAN_ATTACK_MONSTER" -eq 1 ]; then
              echo_t "Monster found - attacking (gold spent)" "" "" "after" "⚔️"
              fetch_page "$MONSTER_ATTACK"
          else
              echo_t "Monster found - running away (no gold spent)" "" "" "after" "💨"
              fetch_page "$MONSTER_RUNAWAY"
          fi
      fi

      # Before gather: show resource probabilities from current SRC
      if [ "$RESULT" = "gather" ]; then
          _cave_display_probabilities "$cave_session_log"
      fi

      read_speedup_silver_cost
      fetch_page "$CAVE"

      case $RESULT in
          down*)
              CAN_ATTACK_MONSTER=0
              echo_t "New search" "" "" "after" "🔍"
              ;;
          gather*)
              echo_t "Start mining" "" "" "after" "⛏️"
              ;;
          speedUp*)
              echo_t "Speeding up mining" "" "" "after" "⚡"
              if _cave_is_extraction_page; then
                  _cave_display_extraction_results "$cave_session_log"
              fi
              ;;
          attack*)
              echo_t "Attacking monster" "" "" "after" "⚔️"
              ;;
          runaway*)
              echo_t "Running from monster" "" "" "after" "💨"
              ;;
      esac

      if [ "$SPEEDUP_SILVER_COST" -gt 0 ]; then
          SILVER_SPENT_TOTAL=$(( SILVER_SPENT_TOTAL + SPEEDUP_SILVER_COST ))
      fi

      action_count=$((action_count + 1))
      bottom_info
      fetch_page "/cave/"

      check_cave_limits
      [ "${CAVE_SHOULD_STOP:-0}" -eq 1 ] && break

      unset ACCESS1 ACCESS2 ACTION DOWN MEGA
  done

  # Reset to normal game loop (prevents cave mode restart)
  RUN="-boot"

  # Display aggregated resources found during session
  _cave_display_aggregated_resources "$cave_session_log"

  # Calculate final elapsed time
  local end_time
  printf -v end_time '%(%s)T' -1
  local total_elapsed=$(( end_time - cave_start_time ))
  local elapsed_min=$(( total_elapsed / 60 ))
  local elapsed_sec=$(( total_elapsed % 60 ))

  # Write session footer to log
  {
    echo "--- Summary ---"
    echo "  Duration: ${elapsed_min}m ${elapsed_sec}s"
    echo "  Total actions: ${action_count}"
    echo "  Gold spent: ${GOLD_SPENT_TOTAL}/${CAVE_GOLD_LIMIT}"
    echo "  Silver spent: ${SILVER_SPENT_TOTAL}/${CAVE_SILVER_LIMIT}"
    echo "=== End of Session ==="
  } >> "$cave_session_log"

  echo_t "Cave Done" "${GREEN_BLACK}" "${COLOR_RESET}" "after" "✅\n"
  echo_t "Session Summary" "${GOLD_BLACK}" "${COLOR_RESET}" "after" "📊"
  echo_t "  Duration: ${elapsed_min}m ${elapsed_sec}s" "${GRAY_BLACK}" "${COLOR_RESET}" "after" "⏱️"
  echo_t "  Total actions: ${action_count}" "${GRAY_BLACK}" "${COLOR_RESET}" "after" "🔨"
  echo_t "  Gold spent: ${GOLD_SPENT_TOTAL}/${CAVE_GOLD_LIMIT}" "${GRAY_BLACK}" "${COLOR_RESET}" "after" "🪙"
  echo_t "  Silver spent: ${SILVER_SPENT_TOTAL}/${CAVE_SILVER_LIMIT}" "${GRAY_BLACK}" "${COLOR_RESET}" "after" "🥈"
  echo_t "  Log saved: ${cave_session_log}" "${GRAY_BLACK}" "${COLOR_RESET}" "after" "📄"

  # Cleanup temp resource tracking file
  rm -f "$TMP/cave_resources_found.txt"
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

      local RESOURCES=$(grep -o -E 'res/[0-9]+\.png' "$TMP/SRC" | sed 's/res\///;s/.png//')
      local MINERALS_FOUND=$(echo "$RESOURCES" | grep -E '^[1-5]$' | wc -l)
      local HERBS_FOUND=$(echo "$RESOURCES" | grep -E '^(6|7|8|9)$' | wc -l)
      local BOOST_LINK=$(grep -o -E '/cave/chance/2/[?]r=[0-9]+' "$TMP/SRC" | head -n 1)

      # se 3 minerios ou nenhuma erva forem encontrados, ativa o boost 100%
      if [ "$FUNC_cave_boost" = "y" ]; then
          if [ "$MINERALS_FOUND" -eq 3 ] && [ "$HERBS_FOUND" -eq 0 ] && [ -n "$BOOST_LINK" ]; then
              echo_t "3 ores detected! Increasing chance by 100%" "" "" "after" "✅"
              fetch_page "$BOOST_LINK"
          fi
      fi

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
