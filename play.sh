#!/bin/sh

# Main script to manage the execution of the twm.sh script based on the provided run mode
(
  RUN=$1  # Get the run mode from the first argument
  run_file="${ACCOUNT_RUN_FILE:-$HOME/twm/runmode_file}"

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
      echo '-cl' > "$run_file"  # Update run mode to coliseum
        "$HOME"/twm/twm.sh -cl  # Run in clan mode
      elif echo "$RUN" | grep -q -E '[-]cv'; then
      echo '-cv' > "$run_file"  # Update run mode to cave
        "$HOME"/twm/twm.sh -cv  # Run in cave mode
      elif echo "$RUN" | grep -q -E '[-]boot'; then
        echo '-boot' > "$run_file"  # Update run mode to boot
        "$HOME"/twm/twm.sh -boot  # Run in boot mode
      else
        echo '-boot' > "$run_file"  # Default to boot mode if no specific mode is set
        "$HOME"/twm/twm.sh -boot  # Run in boot mode
      fi
    }

    run_mode  # Call the function to execute the appropriate mode

    sleep 0.1s  # Brief pause before restarting the loop
  done
)