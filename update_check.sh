update() {
  if [ -z "$*" ]; then
    version="master"
  else
    # ./easyinstall.sh beta, or backup
    version="$*"
  fi

  SERVER="https://raw.githubusercontent.com/hugoviegas/TitansWarPro/${version}/"
  SCRIPTS=("info.sh" "easyinstall.sh" "allies.sh" "altars.sh" "arena.sh" "campaign.sh" "career.sh" "cave.sh"
           "check.sh" "clancoliseum.sh" "clanfight.sh" "clanid.sh" "coliseum.sh"
           "crono.sh" "function.sh" "king.sh" "language.sh" "league.sh"
           "loginlogoff.sh" "play.sh" "requeriments.sh" "run.sh" "svproxy.sh"
           "specialevent.sh" "trade.sh" "twm.sh" "undying.sh" "update.sh")
  NUM_SCRIPTS=${#SCRIPTS[@]}
  files_to_update=()
  cd ~/twm || exit
  . language.sh
  . info.sh
  # Display a loading message
  printf_t "Looking for new updates, please wait..."

  # Check each script
  for script in "${SCRIPTS[@]}"; do
    # Get the size of the remote file
    remote_count=$(curl -s -L "${SERVER}${script}" | wc -c)

    # Get the size of the local file, if it exists
    if [ -e "$HOME/twm/$script" ]; then
      local_count=$(wc -c <"$HOME/twm/$script")
    else
      local_count=0
    fi

    # Compare the file sizes
    if [ "$local_count" -ne "$remote_count" ]; then
      files_to_update+=("$script")  # Add to the list of files to be updated
    fi
  done

  while true; do
    # Ask the user if they want to update
    if [ ${#files_to_update[@]} -gt 0 ]; then
      printf_t "New updates available for: "

      for file in "${files_to_update[@]}"; do
        printf " - $file\n"
      done
      echo_t "Do you want to update these files? (y/n/s)"
      read -r choice
      if [[ "$choice" == "s" || "$choice" == "S" || "$choice" == "y" || "$choice" == "Y" ]]; then
        for file in "${files_to_update[@]}"; do
          curl -s -L "${SERVER}${file}" -o "$HOME/twm/$file"
          printf_t " Updated" "" "" "after" " ${file} ✅"
        done
      else
        printf_t "Update canceled."
        break
      fi
      printf_t "All files are updated, press CTRL + C to stop and run the code to apply."
      sleep 1
    else
      printf_t "All files are updated."
      sleep 1
      break
    fi
  done

  # Convert from DOS to Unix
  find "$HOME/twm" -type f -name '*.sh' -print0 | xargs -0 sed -i 's/\r$//' 2>/dev/null
  chmod +x "$HOME/twm/"*.sh &
}
