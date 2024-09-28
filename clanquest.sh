checkQuest() {
  quest_id="$*"
  #clan_id
  if [ -n "${CLD}" ]; then
    fetch_page "/clan/${CLD}/quest/"
    fetch_page "/clan/${CLD}/quest/" "$TMP/debug_output.txt"
    click=$(grep -o -E "/quest/(take|help|deleteHelp|end)/$quest_id/\?r=[0-9]{8}" "$TMP"/SRC | sed -n '1p')
    echo "DEBUG CLICK: $click"
    
    # find click button
    if [ -n "$click" ]; then
      #echo "Found click action: ${URL}/clan/${CLD}$click"
      fetch_page "/clan/${CLD}$click"
      echo " Quest $quest_id Check... 🔎"
      return 0  # Return true (0) if click action is found
    else
      echo " Quest ID: $quest_id not ready. 🔎"
      return 1  # Return false (1) if click action is not found
    fi
  else
    fetch_page "/clanrating/wantedToClan"
    echo " Quest ID: $quest_id not ready. 🔎"
  fi
}