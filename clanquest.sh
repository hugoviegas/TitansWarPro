checkQuest() {
  quest_id="$*"
  clan_id
  if [ -n "${CLD}" ]; then
    fetch_page "/clan/${CLD}/quest/"
    fetch_debug_page "/clan/${CLD}/quest/" "$TMP/debug_output.txt"
    click=$(grep -oE "/quest/(take|help|deleteHelp|end)/$quest_id/\?r=[0-9]{8}" "$TMP"/SRC | head -1)
    if [ -n "$click" ]; then
      echo "Found click action: $click"
    else
      echo "No click action found for quest ID: $quest_id"
    fi

    fetch_page "$click"
    echo " Quest $quest_id Check..."
    
  else
    fetch_page "/clanrating/wantedToClan"
  fi
}