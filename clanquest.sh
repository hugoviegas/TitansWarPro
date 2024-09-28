checkQuest() {
  quest_id="$*"
  clan_id

  if [ -n "${CLD}" ]; then
    fetch_page "/clan/${CLD}/quest/"
    
    fetch_debug_page "/clan/${CLD}/quest/" "$TMP/debug_output.txt"
    click=$(grep -o -E "/quest/(take|help|deleteHelp|end)/$quest_id/\?r=[0-9]{8}" "$TMP"/SRC | sed -n '1p')
    # Fetch the page
    response=$(curl -s -o "$TMP/SRC" -w "%{http_code}" "${click}")

    # Check the response code
    if [ "$response" -eq 200 ]; then
        echo "Successfully accessed the quest."
    else
        echo "Failed to access the quest. HTTP response code: $response"
    fi
    # find click button
    if [ -n "$click" ]; then
      echo "Found click action: $click"
    else
      echo "No click action found for quest ID: $quest_id"
    fi

    fetch_page "${CLD}/$click"
    echo " Quest $quest_id Check..."
    
  else
    fetch_page "/clanrating/wantedToClan"
  fi
}