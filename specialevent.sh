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
        #echo "🎯 Current Event Link: $event_link, Name: $EVENT"
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
      *)
        echo " "
        return 1
      ;;
  esac

}