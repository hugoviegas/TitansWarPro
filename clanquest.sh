checkQuest() {
  quest_id="$*"
  clan_id

  if [ -n "${CLD}" ]; then
    fetch_page "/clan/${CLD}/quest/"
    FULL_URL="${URL}/clan/${CLD}/quest/take/${quest_id}/?r=[0-9]{8}"
    echo "Constructed URL: ${FULL_URL}"
    curl -I "${FULL_URL}"

    response=$(curl -s -o "$TMP/SRC" -w "%{http_code}" "${FULL_URL}")

    # Check the response code
    if [ "$response" -eq 200 ]; then
        echo "Successfully accessed the URL."
    else
        echo "Failed to access the URL. HTTP response code: $response"
    fi

    fetch_debug_page "/clan/${CLD}/quest/" "$TMP/debug_output.txt"
    click=$(grep -oE "/quest/(take|help|deleteHelp|end)/$quest_id/\?r=[0-9]{8}" "$TMP"/SRC | head -n 1)
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