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
    # Obtém o tamanho do arquivo remoto
    remote_count=$(curl -s -L "${SERVER}${script}" | wc -c)

    # Obtém o tamanho do arquivo local, se existir
    if [ -e "$HOME/twm/$script" ]; then
      local_count=$(wc -c <"$HOME/twm/$script")
    else
      local_count=0
    fi

    # Compara os tamanhos dos arquivos
    if [ "$local_count" -ne "$remote_count" ]; then
      files_to_update+=("$script")  # Adiciona à lista de arquivos a serem atualizados
    fi
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
          curl -s -L "${SERVER}${file}" -o "$HOME/twm/$file"
          echo_t " Updated: " "" "" "after" " ${file} ✅"
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
