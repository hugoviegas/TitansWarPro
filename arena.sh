# shellcheck disable=SC2148
arena_fault() {
  (
    w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "$URL/fault" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
  ) </dev/null &>/dev/null &
  time_exit 17
    local BREAK=$(($(date +%s) + 10))
    while grep -q -o '/fault/attack' "$TMP"/SRC || [ "$(date +%s)" -lt "$BREAK" ]; do
    local ACCESS=$(grep -o -E '(/fault/attack/[^A-Za-z0-9]r[^A-Za-z0-9][0-9]+)' "$TMP"/SRC | sed -n '1p')
    (
      w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "$URL$ACCESS" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
    ) </dev/null &>/dev/null &
            time_exit 17
            echo "$ACCESS"
        sleep 1s
    done
    echo -e "fault (✔)\n"
}
arena_collFight() {
  (
    w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "$URL/collfight/enterFight" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
  ) </dev/null &>/dev/null &
  time_exit 17
  if grep -q -o '/collfight/' "$TMP"/SRC; then
    echo "collfight ..."
    echo "/collfight/enterFight"
    local ACCESS=$(cat "$TMP"/SRC | sed 's/href=/\n/g' | grep 'collfight/take' | head -n1 | awk -F\' '{ print $2 }')
    (
      w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "$URL$ACCESS" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" | tail -n0
    ) </dev/null &>/dev/null &
    time_exit 17
    echo "$ACCESS"
    (
      w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "$URL/collfight/enterFight" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" | tail -n0
    ) </dev/null &>/dev/null &
    time_exit 17
    echo "/collfight/enterFight"
    echo -e "collfight (✔)\n"
  fi
}

arena_duel() {
    # Exibe o título da Arena com emoji de espada e cor
    echo_t "Arena " "$GOLD_BLACK" "$COLOR_RESET" "after" "⚔️"

    checkQuest 3 apply
    checkQuest 4 apply

    # Fetch initial arena page
    fetch_page "/arena/"

    local BREAK=$(($(date +%s) + 60))
    local count=0

    # Loop até o link do laboratório de mago ser encontrado ou o tempo exceder o BREAK
    until grep -q -o 'lab/wizard' "$TMP"/SRC || [ "$(date +%s)" -gt "$BREAK" ]; do
        # Extrai o link de ataque da página da arena
        local ACCESS=$(grep -o -E '(/arena/attack/1/[?]r[=][0-9]+)' "$TMP"/SRC | sed -n '1p')

        # Fetch the attack page
        fetch_page "$ACCESS"
        
        count=$((count + 1))
        
        # Mostra o número do ataque
        echo_t "Attack $count" "" "" "before" "⚔"
        
        sleep 0.6s
    done

    # Fetch the bag inventory page after the duel
    fetch_page "/inv/bag/"

    # Extrai e executa a ação de vender todos os itens
    local SELL=$(grep -o -E '(/inv/bag/sellAll/1/[?]r[=][0-9]+)' "$TMP"/SRC | sed -n '1p')
    fetch_page "$SELL"
    
    checkQuest 3 end
    checkQuest 4 end
    
    # Exibe a confirmação de todos os itens vendidos
    echo_t "Sell all items " "" "" "after" "✅"
    
    # Exibe a confirmação da conclusão da Arena com emoji de check e cor verde
    echo_t "Arena " "$GREEN_BLACK" "$COLOR_RESET" "after" "✅"
    
    echo  # Linha em branco para separar
}


arena_fullmana() {
  echo "energy arena ...\n"
  (
    w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}"/arena/quit -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" | sed "s/href='/\n/g" | grep 'attack/1' | head -n1 | awk -F\/ '{ print $5 }' | tr -cd "[[:digit:]]" >ARENA
  ) </dev/null &>/dev/null &
    time_exit 17
  echo " ⚔ - 1 Attack..."
  (
    w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}/arena/attack/1/?r=$(cat ARENA)" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" | sed "s/href='/\n/g" | grep 'arena/lastPlayer' | head -n1 | awk -F\' '{ print $1 }' | tr -cd "[[:digit:]]" >ATK1
  ) </dev/null &>/dev/null &
    time_exit 17
    echo " ⚔ - Full Attack..."
  (
    w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump "${URL}/arena/lastPlayer/?r=$(cat ATK1)&fullmana=true" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" | head -n5 | tail -n4
  ) </dev/null &>/dev/null &
    time_exit 17
    
  echo -e "${GREEN_BLACK}Energy arena ✅${COLOR_RESET}\n"
}