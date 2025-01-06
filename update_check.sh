update() {
  if [ -z "$*" ]; then
  version="master"
  else
  # ./easyinstall.sh beta, or backup
  version="$*"
  fi
  
  SERVER="https://raw.githubusercontent.com/hugoviegas/TitansWarPro/${version}/"
  SCRIPTS=("info.sh" "easyinstall.sh" "allies.sh" "altars.sh" "altars.sh" "arena.sh" "campaign.sh" "career.sh" "cave.sh"
           "check.sh" "clancoliseum.sh" "clandmg.sh" "clanfight.sh" "clanid.sh" "coliseum.sh"
           "crono.sh" "function.sh" "king.sh" "language.sh" "league.sh"
           "loginlogoff.sh" "play.sh" "requeriments.sh" "run.sh" "svproxy.sh"
           "specialevent.sh" "trade.sh" "twm.sh" "undying.sh update.sh update_check.sh")
  NUM_SCRIPTS=${#SCRIPTS[@]}
  files_to_update=()
  cd ~/twm || exit
  . language.sh
  . info.sh
  # Exibe a mensagem de loading
  printf_t "Looking for new updates, please wait..."

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
    printf_t "New updates available for: "
    
      for file in "${files_to_update[@]}"; do
        printf " - $file\n"
      done
      echo_t "Do you want to update this files? (y/n)"
      read -r -n 1 choice
      if [[ "$choice" == "s" || "$choice" == "S" || "$choice" == "y" || "$choice" == "Y" ]]; then
        for file in "${files_to_update[@]}"; do
          curl -s -L "${SERVER}${file}" -o "$HOME/twm/$file"
          printf_t " Up-to-date" "" "" "after" " ${file} ✅"
        done
      else
        printf_t "Update canceled."
        break
      fi
    printf_t "All files are updated, press CTRL + C to stop and run the code to apply." 
    sleep 3
    break
  else
    printf_t "All files are updated."
    sleep 1
    break
  fi
done
  # Converte de DOS para Unix
  find "$HOME/twm" -type f -name '*.sh' -print0 | xargs -0 sed -i 's/\r$//' 2>/dev/null
  chmod +x "$HOME/twm/"*.sh &
}
