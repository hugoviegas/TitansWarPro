#!/bin/bash
specialEvent() {
  # Fetch the page and store the output in $TMP/SRC
  fetch_page
  
  # Check if "shb_text" is found in $TMP/SRC
  if grep -q "shb_text" "$TMP/SRC"; then
    # Extract the first link after "shb_text"
    local event_link
    event_link=$(grep -o -E "<div class='shb_text'><a href='[^']+'" "$TMP/SRC" | sed -E "s/^.*href='([^']+)'.*$/\1/" | sed -n '1p')
    
    # Check if a link was found
    if [ -n "$event_link" ]; then
        EVENT=$(echo "$event_link" | cut -d'/' -f2)
        echo "🎯 Current event name: $EVENT"
    fi
  fi

  case $EVENT in
    (questrnd)
      fetch_page "$event_link"
      echo -e "${GOLD_BLACK}Event Adventure 🎯${COLOR_RESET}"
      click=$(grep -o -E "/questrnd/take/\?r=[0-9]{8}" "$TMP"/SRC | sed -n '1p')
      if [ -n "$click" ]; then
        fetch_page "$click"
        echo -e " Claimed reward\n"
        return 0  # Success if found
      else
      echo " "
      return 1  # Not found
      fi
      ;;
    (fault)
        fetch_page "${event_link}"
        echo_t "Fault event fault" "${GOLD_BLACK}" "${COLOR_RESET}" "after" "😈"
        #click=$(grep -o -E "/fault/?group=2/\?r=[0-9]+" "$TMP"/SRC | sed -n '1p')
        click=$(grep -o -E "/fault/attack/\?r=[0-9]+" "$TMP"/SRC | sed -n '1p')
		    #echo "${click}"
        fetch_page "${click}"
        sleep 1s
        click=$(grep -o -E "/fault/attack/\?r=[0-9]+" "$TMP"/SRC | sed -n '1p')
        while true; do
          if [ -n "${click}" ]; then
            fetch_page "${click}"
            # Atualiza o valor de click após a nova página ser carregada
            click=$(grep -o -E "/fault/attack/\?r=[0-9]+" "$TMP"/SRC | sed -n '1p')
            echo_t " Attacking monster" "" "" "after" "⚔️"
          else
            echo_t "Event fault" "${GOLD_BLACK}" "${COLOR_RESET}" "after" "😈✅"
            break
          fi
        done
      ;;
      (clandmgfight)
        case $(date +%H:%M) in
          (09:2[5-9]|21:2[5-9])
            clandmgfight_start
            ;;
          (*)
            echo " "
            return 1
            ;;
        esac
        ;;
      (marathon)
          fetch_page "marathon/"
          echo_t "Marathon event" "${GOLD_BLACK}" "${COLOR_RESET}" "after" "🏆"
          click=$(grep -o -E "/marathon/take/\?r=[0-9]+" "$TMP"/SRC | sed -n '1p')
          fetch_page "${click}"
          echo_t " Claimed reward" "" "" "after" "🏆"
          # Show the page info using w3m -dump -T text/html "$TMP/SRC"
          w3m -dump -T text/html "$TMP/SRC" | head -n 18 | tail -n 16 

        ;;
      *)
        echo " "
        return 1
      ;;
  esac

}
