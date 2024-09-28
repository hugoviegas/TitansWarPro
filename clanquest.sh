checkQuest() {
  quest_id="$*"
  if [ -n "${CLD}" ]; then
    fetch_page "/clan/${CLD}/quest/"
    fetch_page "/clan/${CLD}/quest/" "$TMP/debug_output.txt"
    click=$(grep -o -E "/quest/(take|help|deleteHelp|end)/$quest_id/\?r=[0-9]{8}" "$TMP"/SRC | sed -n '1p')
    #echo "DEBUG CLICK: $click"
    
    # Find the click button
    if [ -n "$click" ]; then
      fetch_page "/clan/${CLD}$click"
      echo " Quest $quest_id Check... 🔎"
      return 0  # Success if found
    else
      echo " Quest ID: $quest_id not ready. 🔎"
      return 1  # Not found
    fi
  else
    fetch_page "/clanrating/wantedToClan"
    echo " Quest ID: $quest_id not ready. 🔎"
    return 1  # Fail in case CLD is empty
  fi
}
