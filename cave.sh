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
    sleep 3s
    echo "-boot" > "$HOME/twm/runmode_file"
    "$HOME"/twm/twm.sh -boot
    exit 0
  fi

  if [ "$CAVE_SILVER_LIMIT" -gt 0 ] && [ "$SILVER_SPENT_TOTAL" -ge "$CAVE_SILVER_LIMIT" ]; then
    echo_t "Silver limit reached (${SILVER_SPENT_TOTAL}/${CAVE_SILVER_LIMIT})" "" "" "after" "🚦"
    sleep 3s
    echo "-boot" > "$HOME/twm/runmode_file"
    "$HOME"/twm/twm.sh -boot
    exit 0
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
    echo_t "Restarting in routine mode..." "" "" "after" "🔄"
    sleep 3s
    echo "-boot" > "$HOME/twm/runmode_file"
    "$HOME"/twm/twm.sh -boot
    exit 0
  fi
}

# funcoes originais

bottom_info(){
    echo -e "${GREENb_BLACK}🧡 HP $NOWHP - ${HPPER}% | 🔷 MP $NOWMP - ${MPPER}%${COLOR_RESET}" > "$TMP"/bottom_file
    printf " 👷‍♂️${ACC} | $(w3m -dump -T text/html $TMP/SRC | grep -o -E '(g [0-9]{1,3}[^0-9]{0,1}[0-9]{0,3}[A-Za-z]{0,1} \| s [0-9]{1,3}[^0-9]{0,1}[0-9]{0,3}[A-Za-z]{0,1})' | sed 's/g/🪙 g/g;s/s/🥈 s/g') \n" >> "$TMP/bottom_file"
    echo_t " ~ Press [x] to exit" >> "$TMP/bottom_file"
    # printf "\n" >> "$TMP/bottom_file"
    cat "$TMP/bottom_file"
}

cave_start() {
  clan_id
  fetch_page "/cave/"
  set_cave_limits

  while echo "$RUN" | grep -q -E '[-]cv'; do

      local CAVE=$(grep -o -E '/cave/(gather|down|speedUp)/[?]r[=][0-9]+' "$TMP"/SRC | sed -n '1p')
      local RESULT=$(echo "$CAVE" | cut -d'/' -f3)

      local RESOURCES=$(grep -o -E 'res/[0-9]+\.png' "$TMP/SRC" | sed 's/res\///;s/.png//')
      local MINERALS_FOUND=$(echo "$RESOURCES" | grep -E '^[1-5]$' | wc -l)
      local HERBS_FOUND=$(echo "$RESOURCES" | grep -E '^(6|7|8|9)$' | wc -l)
      local BOOST_LINK=$(grep -o -E '/cave/chance/2/[?]r=[0-9]+' "$TMP/SRC" | head -n 1)

      local CAN_ATTACK_MONSTER=${CAN_ATTACK_MONSTER:-0}
      local MONSTER_ATTACK=$(grep -o -E '/cave/attack/[?]r=[0-9]+' "$TMP/SRC" | head -n1)
      local MONSTER_RUNAWAY=$(grep -o -E '/cave/runaway/[?]r=[0-9]+' "$TMP/SRC" | head -n1)

      check_cave_keypress

      # se 3 minerios ou nenhuma erva forem encontrados, ativa o boost 100%
      if [ "$MINERALS_FOUND" -eq 3 ] && [ "$HERBS_FOUND" -eq 0 ] && [ -n "$BOOST_LINK" ]; then
          # faz a leitura do valor gasto em ouro
          read_boost_gold_cost
          echo_t "3 ores detected! Increasing chance by 100%" "" "" "after" "✅"
          fetch_page "$BOOST_LINK"

          # soma o valor gasto em ouro
          if [ "$BOOST_GOLD_COST" -gt 0 ]; then
            GOLD_SPENT_TOTAL=$(( GOLD_SPENT_TOTAL + BOOST_GOLD_COST ))
            # grava o consumo de ouro para proximo ataque no monstro
            CAN_ATTACK_MONSTER=1
          fi
      fi

      # controla ataque ou fuga do monstro
      if [ -n "$MONSTER_ATTACK" ] && [ -n "$MONSTER_RUNAWAY" ]; then

        if [ "$CAN_ATTACK_MONSTER" -eq 1 ]; then
          echo_t "Monster found - attacking (gold spent)" "" "" "after" "⚔️"
          fetch_page "$MONSTER_ATTACK"

        else
          echo_t "Monster found - running away (no gold spent)" "" "" "after" "💨"
          fetch_page "$MONSTER_RUNAWAY"
        fi

      fi

      # echo "DEBUG: CAN_ATTACK_MONSTER=$CAN_ATTACK_MONSTER"

      # faz a leitura do valor gasto em prata
      read_speedup_silver_cost

      fetch_page "$CAVE"

      case $RESULT in
        down*)
        echo_t "New search" "" "" "after" "🔍"
        # reseta consumo de ouro para proximo ataque no monstro
        CAN_ATTACK_MONSTER=0
        ;;
        gather*) echo_t "Start mining" "" "" "after" "⛏️";;
        speedUp*) echo_t "Speeding up mining" "" "" "after" "⚡";;
      esac

      # soma o valor gasto em prata
      if [ "$SPEEDUP_SILVER_COST" -gt 0 ]; then
        SILVER_SPENT_TOTAL=$(( SILVER_SPENT_TOTAL + SPEEDUP_SILVER_COST ))
      fi

      bottom_info
      fetch_page "/cave/"

      check_cave_limits
      
  done

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
