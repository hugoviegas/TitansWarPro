#!/bin/sh
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
child_pid=""
should_exit=0

kill_child() {
  if [ -n "$child_pid" ] && kill -0 "$child_pid" 2>/dev/null; then
    kill -9 "$child_pid" 2>/dev/null
    wait "$child_pid" 2>/dev/null || true
  fi
  child_pid=""
}

cleanup() {
  should_exit=1
  kill_child
  exit 0
}

trap 'cleanup' INT TERM

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
