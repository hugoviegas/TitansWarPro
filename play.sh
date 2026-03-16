#!/bin/bash
# Supervisor for a single account.
# Usage:  play.sh <ACCOUNT_ID> [run_mode]
#   play.sh A1          → normal boot mode for account A1
#   play.sh A1 -cv      → cave mode
#   play.sh A1 -cl      → coliseum mode
#
# Use multi_runner.sh to run all accounts simultaneously.
# Use twm_control.sh (alias: twmsetup) as the main control panel.

if [ -z "$1" ]; then
  printf 'Usage: play.sh <ACCOUNT_ID> [run_mode]\n'
  printf 'Examples:\n'
  printf '  play.sh A1          — start account A1 in normal mode\n'
  printf '  play.sh A1 -cv      — start account A1 in cave mode\n'
  printf '  play.sh A1 -cl      — start account A1 in coliseum mode\n'
  printf '\nAvailable accounts:\n'
  _idx="$HOME/twm/accounts/index.json"
  if command -v jq >/dev/null 2>&1 && [ -f "$_idx" ]; then
    jq -r '.accounts[] | "  \(.id)  \(.alias // "")  (server: \(.ur // "?"))"' "$_idx" 2>/dev/null
  else
    printf '  (run twmsetup to configure accounts)\n'
  fi
  unset _idx
  exit 1
fi

export ACCOUNT_ID="$1"
RUN="${2:--boot}"
run_file="${ACCOUNT_RUN_FILE:-$HOME/twm/accounts/$ACCOUNT_ID/runmode_file}"
lock_file="$HOME/twm/accounts/$ACCOUNT_ID/.play.lock"
child_pid=""
should_exit=0

# Check if another instance is already running
if [ -f "$lock_file" ]; then
  existing_pid=$(cat "$lock_file" 2>/dev/null)
  is_stale=1  # Assume stale until proven otherwise

  # Check if PID is running
  if kill -0 "$existing_pid" 2>/dev/null; then
    # Process exists — it's genuinely running
    is_stale=0

    # If tmux is available, check if the existing process was started inside tmux.
    # Only flag as stale if: (1) its parent is tmux, AND (2) our expected session is gone.
    # This avoids incorrectly overriding a direct play.sh invocation (no tmux).
    if command -v tmux >/dev/null 2>&1; then
      session_name="twm_${ACCOUNT_ID}"
      existing_ppid=$(ps -o ppid= -p "$existing_pid" 2>/dev/null | tr -d ' ')
      existing_parent=$(ps -o comm= -p "$existing_ppid" 2>/dev/null | tr -d ' ')
      if [[ "$existing_parent" == *"tmux"* ]]; then
        # Process was started inside a tmux session — session should still exist
        if ! tmux has-session -t "$session_name" 2>/dev/null; then
          # Session gone but process still exists — orphaned, treat as stale
          is_stale=1
        fi
      fi
    fi
  fi

  if [ "$is_stale" -eq 0 ]; then
    # Process is genuinely running
    printf '\033[01;31mError: Account %s is already running (PID %s)\033[0m\n' "$ACCOUNT_ID" "$existing_pid"
    printf 'To stop it: kill %s\n' "$existing_pid"
    exit 1
  else
    # Stale lock file, remove it
    rm -f "$lock_file" 2>/dev/null
  fi
fi

# Create lock file
echo "$$" > "$lock_file" 2>/dev/null || {
  printf 'Error: Cannot write lock file to %s\n' "$(dirname "$lock_file")"
  exit 1
}

kill_child() {
  if [ -n "$child_pid" ] && kill -0 "$child_pid" 2>/dev/null; then
    # Signal the process group (kills all children in the group)
    kill -TERM "-$child_pid" 2>/dev/null || true
    # Always also send direct TERM — fallback when no separate process group exists
    # (non-interactive shells don't create a new process group for background jobs)
    kill -TERM "$child_pid" 2>/dev/null || true
    sleep 1s

    # If still alive, force kill both group and direct process
    if kill -0 "$child_pid" 2>/dev/null; then
      kill -9 "-$child_pid" 2>/dev/null || true
      kill -9 "$child_pid" 2>/dev/null || true
    fi

    wait "$child_pid" 2>/dev/null || true
  fi
  child_pid=""
}

cleanup() {
  should_exit=1
  rm -f "$lock_file" 2>/dev/null  # remove lock first so restart is possible immediately
  kill_child
  exit 0
}

trap 'cleanup' INT TERM EXIT

while [ "$should_exit" -eq 0 ]; do
  kill_child

  run_mode() {
    chmod +x "$HOME/twm/twm.sh"

    if echo "$RUN" | grep -q -E '[-]cl'; then
      echo '-cl' > "$run_file"
      "$HOME"/twm/twm.sh -cl < /dev/tty
    elif echo "$RUN" | grep -q -E '[-]cv'; then
      echo '-cv' > "$run_file"
      "$HOME"/twm/twm.sh -cv < /dev/tty
    else
      echo '-boot' > "$run_file"
      "$HOME"/twm/twm.sh -boot < /dev/tty
    fi
  }

  run_mode &
  child_pid=$!
  wait "$child_pid" 2>/dev/null
  wait_status=$?
  child_pid=""

  if [ "$wait_status" -eq 99 ] || [ "$wait_status" -eq 143 ] || [ "$wait_status" -eq 130 ]; then
    exit 0
  fi

  if [ "$should_exit" -eq 1 ]; then
    exit 0
  fi

  sleep 0.5s
done
