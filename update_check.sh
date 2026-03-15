update() {
  local version channel

  if [ -z "$*" ]; then
    if command -v get_config >/dev/null 2>&1; then
      channel=$(get_config "UPDATE_CHANNEL" 2>/dev/null)
    fi
    version=${channel:-master}
  else
    version="$*"
  fi

  case "$version" in
    master|Master)
      version="master"
      ;;
    beta|Beta)
      version="beta"
      ;;
    beta2|Beta2)
      version="beta2"
      ;;
    *)
      version="master"
      ;;
  esac

  SERVER="https://raw.githubusercontent.com/hugoviegas/TitansWarPro/${version}/"
  SCRIPTS=("info.sh" "easyinstall.sh" "allies.sh" "altars.sh" "arena.sh" "campaign.sh" "career.sh" "cave.sh"
           "check.sh" "clancoliseum.sh" "clandmg.sh" "clanfight.sh" "clanid.sh" "coliseum.sh"
           "crono.sh" "function.sh" "king.sh" "language.sh" "league.sh"
           "loginlogoff.sh" "play.sh" "requeriments.sh" "run.sh" "svproxy.sh"
           "specialevent.sh" "trade.sh" "twm.sh" "undying.sh" "update.sh" "update_check.sh")
  files_to_update=()
  cd ~/twm || exit
  . language.sh
  . info.sh
  load_config
  # Exibe a mensagem de loading
  echo_t "Looking for new updates, please wait..." "" "" "after" "🔍"
  echo_t "Update channel: ${version}" "" ""

  # Verifica cada script
  for script in "${SCRIPTS[@]}"; do
    local_file="$HOME/twm/$script"
    temp_file="$local_file.tmp.$$"

    # Download to temp file
    if ! curl -s -L "${SERVER}${script}" -o "$temp_file" 2>/dev/null; then
      rm -f "$temp_file"
      continue
    fi

    # Check if local file exists
    if [ ! -e "$local_file" ]; then
      # New file to download
      files_to_update+=("$script")
    else
      # Compare hashes
      local_hash=$(sha256sum "$local_file" 2>/dev/null | awk '{print $1}')
      remote_hash=$(sha256sum "$temp_file" 2>/dev/null | awk '{print $1}')

      if [ "$remote_hash" != "$local_hash" ]; then
        # Content differs — update needed
        files_to_update+=("$script")
      fi
    fi

    # Clean up temp file
    rm -f "$temp_file"
  done
while true; do
  # Pergunta ao usuário se deseja atualizar
  if [ ${#files_to_update[@]} -gt 0 ]; then
    echo_t "New updates available for: "
    
      for file in "${files_to_update[@]}"; do
        printf " - $file\n"
      done
      if [ "$FUNC_AUTO_UPDATE" = "y" ]; then
        choice="y"
      else
        echo_t "Do you want to update this files? (y/n) [The script will be restarted]"
        read -r -n 1 choice
        echo
      fi
      
      if [[ "$choice" == "s" || "$choice" == "S" || "$choice" == "y" || "$choice" == "Y" ]]; then
        for file in "${files_to_update[@]}"; do
          local_file="$HOME/twm/$file"
          temp_file="$local_file.tmp.$$"

          # Download to temp file
          if curl -s -L "${SERVER}${file}" -o "$temp_file" 2>/dev/null; then
            # Compare hashes if local file exists
            if [ -e "$local_file" ]; then
              local_hash=$(sha256sum "$local_file" 2>/dev/null | awk '{print $1}')
              remote_hash=$(sha256sum "$temp_file" 2>/dev/null | awk '{print $1}')

              if [ "$remote_hash" = "$local_hash" ]; then
                # File unchanged
                rm -f "$temp_file"
                echo_t " ✅ ${file} (unchanged)" "" "" "after"
              else
                # Update with new version
                mv "$temp_file" "$local_file"
                echo_t " 🔽 Updated: ${file} ✅" "" "" "after"
              fi
            else
              # New file
              mv "$temp_file" "$local_file"
              echo_t " 🆕 ${file} (new)" "" "" "after"
            fi

            # Make executable
            chmod +x "$local_file"
          else
            # Download failed
            rm -f "$temp_file"
            echo_t " ⚠️  ${file} (download failed)" "" "" "after"
          fi
        done
      else
        echo_t "Update canceled."
        break
      fi

    echo_t "All files are updated, the script will be restarted in 3 seconds." 
    sleep 3
    restart_script
    break
  else
    echo_t "All files are updated."
    sleep 1
    break
  fi
done
  # Converte de DOS para Unix
  find "$HOME/twm" -type f -name '*.sh' -print0 | xargs -0 sed -i 's/\r$//' 2>/dev/null
  chmod +x "$HOME/twm/"*.sh &
}
