#!/bin/sh

# Main script to manage the execution of the twm.sh script based on the provided run mode.
# This supervisor process will respawn twm.sh if it exits unexpectedly.
# Send SIGTERM to stop and exit: kill $$
# Send SIGINT (Ctrl+C) to stop and exit.

RUN=$1
run_file="${ACCOUNT_RUN_FILE:-$HOME/twm/runmode_file}"
child_pid=""
should_exit=0

# Kills only the child twm.sh we previously spawned, not every instance
kill_child() {
  if [ -n "$child_pid" ] && kill -0 "$child_pid" 2>/dev/null; then
    kill -9 "$child_pid" 2>/dev/null
    wait "$child_pid" 2>/dev/null || true
  fi
  child_pid=""
}

# Signal handlers
cleanup() {
  should_exit=1
  kill_child
  exit 0
}

trap 'cleanup' INT TERM

while [ "$should_exit" -eq 0 ]; do
  kill_child   # Clean up any previous child before launching a new one

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

  run_mode &
  child_pid=$!
  wait "$child_pid" 2>/dev/null
  wait_status=$?
  child_pid=""

  # If signal 143 (SIGTERM) or 130 (SIGINT), exit gracefully
  if [ "$wait_status" -eq 143 ] || [ "$wait_status" -eq 130 ]; then
    exit 0
  fi

  # If should_exit flag was set, exit
  if [ "$should_exit" -eq 1 ]; then
    exit 0
  fi

  sleep 0.5s  # Wait before restarting to avoid tight loop
done