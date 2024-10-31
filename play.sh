#!/bin/sh

# Main script to manage the execution of the twm.sh script based on the provided run mode
(
  RUN=$1  # Get the run mode from the first argument
  echo "$RUN" > "$HOME/twm/runmode_file"  # Save the run mode to a file
  LANGUAGE_FILE="$HOME/twm/language_file"  # Caminho para o arquivo de idioma
  
  # Verifica se o arquivo existe e se contém um idioma válido
  if [ -f "$LANGUAGE_FILE" ] && [ -s "$LANGUAGE_FILE" ]; then
      LANGUAGE=$(cat "$LANGUAGE_FILE")
  else
      LANGUAGE="en"  # Define o idioma para o padrão
      echo "$LANGUAGE" > "$LANGUAGE_FILE"  # Salva o idioma padrão no arquivo
  fi

  # Exporta a variável para torná-la disponível globalmente
  export LANGUAGE

  while true; do
    # Get the PID of the running twm.sh script
    pidf=$(ps ax -o pid=,args= | grep "sh.*twm/twm.sh" | grep -v 'grep' | head -n 1 | grep -o -E '([0-9]{3,5})')

    # Loop until there are no more PIDs found
    until [ -z "${pidf}" ]; do
      kill -9 ${pidf} 2>/dev/null  # Forcefully kill the process if found
      pidf=$(ps ax -o pid=,args= | grep "sh.*twm/twm.sh" | grep -v 'grep' | head -n 1 | grep -o -E '([0-9]{3,5})')  # Update PID
      sleep 1s  # Wait for a second before checking again
    done

    # Function to determine which mode to run based on the RUN variable
    run_mode() {
      chmod +x "$HOME/twm/twm.sh"  # Ensure twm.sh is executable

      if echo "$RUN" | grep -q -E '[-]cl'; then
        $HOME/twm/twm.sh  # Run in clan mode
      elif echo "$RUN" | grep -q -E '[-]cv'; then
        $HOME/twm/twm.sh -cv  # Run in cave mode
      elif echo "$RUN" | grep -q -E '[-]boot'; then
        echo '-boot' > "$HOME/twm/runmode_file"  # Update run mode to boot
        $HOME/twm/twm.sh -boot  # Run in boot mode
      else
        echo '-boot' > "$HOME/twm/runmode_file"  # Default to boot mode if no specific mode is set
        $HOME/twm/twm.sh -boot  # Run in boot mode
      fi
    }

    run_mode  # Call the function to execute the appropriate mode

    sleep 0.1s  # Brief pause before restarting the loop
  done
)