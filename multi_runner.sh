#!/bin/bash
set -euo pipefail

BASE_DIR="${HOME}/twm"
ACCOUNTS_DIR="${BASE_DIR}/accounts"
INDEX_FILE="${ACCOUNTS_DIR}/index.json"
PID_DIR="${ACCOUNTS_DIR}/.pids"
RUNTIME_DIR="${ACCOUNTS_DIR}/.runtime"

usage() {
  cat <<'EOF'
Usage: ./multi_runner.sh [command]

Commands:
  start [ID]       Start all active accounts, or only the specified ID.
  stop [ID ...]    Stop all running accounts, or only the specified IDs.
  restart          Stop then start all active accounts.
  status           Show process status for every account defined in index.json.
  help             Show this message.
EOF
}

fatal() {
  echo "multi_runner: $*" >&2
  exit 1
}

require_index() {
  if [ ! -f "$INDEX_FILE" ]; then
    fatal "missing accounts/index.json (expected at $INDEX_FILE)"
  fi
}

require_jq() {
  if ! command -v jq >/dev/null 2>&1; then
    fatal "jq is required to parse accounts/index.json"
  fi
}

has_tmux() {
  command -v tmux >/dev/null 2>&1
}

session_name() {
  printf 'twm_%s' "$1"
}

is_running() {
  local pid="$1"
  [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null
}

load_accounts() {
  local scope="$1"
  require_index
  require_jq
  local jq_filter
  case "$scope" in
    active)
      jq_filter='.accounts[] | select((.active // true) == true)'
      ;;
    all)
      jq_filter='.accounts[]'
      ;;
    *)
      fatal "unknown scope: $scope"
      ;;
  esac
  jq -r "${jq_filter} | [.id, (.alias // \"\"), (.ur // \"\"), (.runMode // \"\"), (.timezone // \"\"), (.autoRestart // true), (.active // true)] | @tsv" "$INDEX_FILE"
}

ensure_account_dirs() {
  local account_root="$1"
  mkdir -p "$account_root" "$account_root/tmp" "$account_root/logs" "$account_root/w3m"
}

# ─── Write account config files (shared by both tmux and legacy modes) ────────
write_account_config() {
  local account_id="$1" account_ur="$2" account_runmode="$3"
  local account_ur_file="${ACCOUNTS_DIR}/${account_id}/ur_file"
  local account_run_file="${ACCOUNTS_DIR}/${account_id}/runmode_file"

  if [ -n "$account_ur" ]; then
    if [ ! -f "$account_ur_file" ] || [ "$(cat "$account_ur_file" 2>/dev/null)" != "$account_ur" ]; then
      printf '%s\n' "$account_ur" > "$account_ur_file"
    fi
  fi

  if [ -n "$account_runmode" ]; then
    printf '%s\n' "$account_runmode" > "$account_run_file"
  fi
}

# ─── tmux mode ────────────────────────────────────────────────────────────────
start_account_tmux() {
  local account_id="$1" account_alias="$2" account_ur="$3"
  local account_runmode="$4" account_timezone="$5"

  local account_root="${ACCOUNTS_DIR}/${account_id}"
  local sname
  sname=$(session_name "$account_id")

  ensure_account_dirs "$account_root"
  write_account_config "$account_id" "$account_ur" "$account_runmode"

  if tmux has-session -t "$sname" 2>/dev/null; then
    echo "[${account_id}] already running (tmux session: $sname)"
    return
  fi

  # Build the run command (inline env + play.sh + account id)
  local run_cmd="ACCOUNT_ID=$(printf '%q' "$account_id")"
  [ -n "$account_timezone" ] && run_cmd="TZ=$(printf '%q' "$account_timezone") $run_cmd"
  run_cmd="$run_cmd $(printf '%q' "$BASE_DIR/play.sh") $(printf '%q' "$account_id")"

  # Create the tmux session with a plain shell, then send the run command
  tmux new-session -d -s "$sname" -x 220 -y 50
  tmux send-keys -t "$sname" "$run_cmd" Enter
  echo "[${account_id}] started (tmux session: $sname)"
}

stop_account_tmux() {
  local id="$1"
  local sname
  sname=$(session_name "$id")

  if ! tmux has-session -t "$sname" 2>/dev/null; then
    echo "[${id}] no active tmux session"
    return
  fi

  echo "[${id}] stopping tmux session: $sname"
  # Send Ctrl+C for graceful shutdown (play.sh trap → cleanup → remove lock)
  tmux send-keys -t "$sname" C-c 2>/dev/null || true
  local i=0
  while tmux has-session -t "$sname" 2>/dev/null && [ $i -lt 5 ]; do
    sleep 1
    i=$((i + 1))
  done
  # Force-kill if still alive
  tmux kill-session -t "$sname" 2>/dev/null || true
  echo "[${id}] stopped"
}

# ─── Legacy mode (nohup + runner scripts) ─────────────────────────────────────
start_account_legacy() {
  local account_id="$1"
  local account_alias="$2"
  local account_ur="$3"
  local account_runmode="$4"
  local account_timezone="$5"
  local account_autorestart="$6"

  local account_root="${ACCOUNTS_DIR}/${account_id}"
  local account_logs="${account_root}/logs"
  local log_file="${account_logs}/twm.log"
  local runner_script="${RUNTIME_DIR}/${account_id}_runner.sh"
  local pid_file="${PID_DIR}/${account_id}.pid"

  ensure_account_dirs "$account_root"
  mkdir -p "$PID_DIR" "$RUNTIME_DIR"

  write_account_config "$account_id" "$account_ur" "$account_runmode"

  if [ -f "$pid_file" ]; then
    local existing_pid
    existing_pid="$(cat "$pid_file" 2>/dev/null || true)"
    if is_running "$existing_pid"; then
      echo "[${account_id}] already running (pid $existing_pid)"
      return
    fi
  fi

  touch "$log_file"
  [ -n "$account_autorestart" ] || account_autorestart="true"

  local id_literal alias_literal base_literal log_literal autorestart_literal timezone_literal
  printf -v id_literal '%q' "$account_id"
  printf -v alias_literal '%q' "$account_alias"
  printf -v base_literal '%q' "$BASE_DIR"
  printf -v log_literal '%q' "$log_file"
  printf -v autorestart_literal '%q' "$account_autorestart"
  printf -v timezone_literal '%q' "$account_timezone"

  cat > "$runner_script" <<EOF
#!/bin/bash
set -uo pipefail
export ACCOUNT_ID=$id_literal
EOF

  if [ -n "$account_timezone" ]; then
    cat >> "$runner_script" <<EOF
export TZ=$timezone_literal
EOF
  fi

  cat >> "$runner_script" <<EOF
LOG_FILE=$log_literal
BASE_DIR=$base_literal
ACCOUNT_ALIAS=$alias_literal
AUTO_RESTART=$autorestart_literal
ACCOUNT_LABEL=$id_literal
child_pid=""
restart_delay=5
trap 'if [ -n "\$child_pid" ]; then kill "\$child_pid" 2>/dev/null; wait "\$child_pid" 2>/dev/null || true; fi; exit 0' INT TERM
while true; do
  cd "\$BASE_DIR" || exit 1
  echo "\$(date +'%Y-%m-%d %H:%M:%S') [\${ACCOUNT_ALIAS:-$account_id}] starting twm.sh" >> "\$LOG_FILE"
  "\${BASE_DIR}/twm.sh" >> "\$LOG_FILE" 2>&1 &
  child_pid=\$!
  wait "\$child_pid"
  exit_code=\$?
  child_pid=""
  echo "\$(date +'%Y-%m-%d %H:%M:%S') [\${ACCOUNT_ALIAS:-$account_id}] twm.sh exited with code \$exit_code" >> "\$LOG_FILE"
  if [ "\$exit_code" -eq 99 ] || [ "\$exit_code" -eq 143 ] || [ "\$exit_code" -eq 130 ]; then
    exit 0
  fi
  if [ "\$AUTO_RESTART" != "true" ]; then
    exit "\$exit_code"
  fi
  if [ "\$exit_code" -eq 0 ]; then
    restart_delay=5
  fi
  sleep "\$restart_delay"
  restart_delay=\$(( restart_delay * 2 > 60 ? 60 : restart_delay * 2 ))
done
EOF

  chmod +x "$runner_script"
  nohup "$runner_script" >/dev/null 2>&1 &
  local runner_pid=$!
  echo "$runner_pid" > "$pid_file"
  echo "[${account_id}] started (pid $runner_pid)"
}

stop_account_legacy() {
  local id="$1"
  local pid_file="${PID_DIR}/${id}.pid"

  if [ ! -f "$pid_file" ]; then
    echo "[${id}] no pid file; skipping"
    return
  fi

  local pid
  pid="$(cat "$pid_file" 2>/dev/null || true)"
  if [ -n "$pid" ] && is_running "$pid"; then
    echo "[${id}] stopping pid $pid"
    kill "$pid" 2>/dev/null || true
    local i=0
    while is_running "$pid" && [ $i -lt 5 ]; do
      sleep 1
      i=$((i + 1))
    done
    is_running "$pid" && kill -9 "$pid" 2>/dev/null || true
  else
    echo "[${id}] runner not active"
  fi
  rm -f "$pid_file"
}

# ─── Public start/stop/status (dispatch to tmux or legacy) ───────────────────
start_account() {
  local account_id="$1" account_alias="$2" account_ur="$3"
  local account_runmode="$4" account_timezone="$5" account_autorestart="$6"

  if has_tmux; then
    start_account_tmux "$account_id" "$account_alias" "$account_ur" "$account_runmode" "$account_timezone"
  else
    start_account_legacy "$account_id" "$account_alias" "$account_ur" "$account_runmode" "$account_timezone" "$account_autorestart"
  fi
}

start_accounts() {
  local filter="${1:-}"  # optional: single account ID to start
  mkdir -p "$PID_DIR" "$RUNTIME_DIR"
  local have_accounts=false
  while IFS=$'\t' read -r id alias ur runmode timezone autorestart active_flag; do
    [ -n "$id" ] || continue
    # If a filter is given, skip accounts that don't match
    [ -z "$filter" ] || [ "$id" = "$filter" ] || continue
    have_accounts=true
    start_account "$id" "$alias" "$ur" "$runmode" "$timezone" "$autorestart"
  done <<EOF
$(load_accounts active)
EOF
  if [ "$have_accounts" = false ]; then
    echo "No active accounts found in $INDEX_FILE."
  fi
}

stop_accounts() {
  local ids_list="" pid_id

  if [ $# -gt 0 ]; then
    ids_list="$*"
  else
    # Collect from tmux sessions
    if has_tmux; then
      ids_list=$(tmux list-sessions -F '#{session_name}' 2>/dev/null | sed -n 's/^twm_//p' | tr '\n' ' ' || true)
    fi
    # Also collect from legacy PID files (handles migration / mixed mode)
    for file in "$PID_DIR"/*.pid; do
      [ -e "$file" ] || continue
      pid_id=$(basename "${file%.pid}")
      # Add only if not already in list
      case " $ids_list " in
        *" $pid_id "*) ;;
        *) ids_list="$ids_list $pid_id" ;;
      esac
    done
  fi

  if [ -z "$ids_list" ]; then
    echo "No running account processes found."
    return
  fi

  for id in $ids_list; do
    local sname
    sname=$(session_name "$id")
    local pid_file="${PID_DIR}/${id}.pid"

    if has_tmux && tmux has-session -t "$sname" 2>/dev/null; then
      stop_account_tmux "$id"
    elif [ -f "$pid_file" ]; then
      stop_account_legacy "$id"
    else
      echo "[${id}] not running"
    fi
  done
}

status_accounts() {
  require_index
  require_jq
  printf "%-8s %-10s %-20s %-8s %s\n" "ID" "State" "Session/PID" "RunMode" "Alias"
  local lines
  lines="$(load_accounts all)"
  if [ -z "$lines" ]; then
    echo "(index is empty)"
    return
  fi
  while IFS=$'\t' read -r id alias ur runmode timezone autorestart active_flag; do
    [ -n "$id" ] || continue
    local sname
    sname=$(session_name "$id")
    local run_file="${ACCOUNTS_DIR}/${id}/runmode_file"
    local run_value="-"
    [ -f "$run_file" ] && run_value="$(tr -d '\r' < "$run_file")"
    [ -n "$run_value" ] || run_value="-"

    local session_info="-" state="stopped"
    if [ "$active_flag" != "true" ]; then
      state="inactive"
    elif has_tmux && tmux has-session -t "$sname" 2>/dev/null; then
      state="running"
      session_info="$sname"
    elif [ -f "${PID_DIR}/${id}.pid" ]; then
      local pid
      pid="$(cat "${PID_DIR}/${id}.pid" 2>/dev/null || true)"
      if is_running "$pid"; then
        state="running"
        session_info="pid:$pid"
      elif [ -n "$pid" ]; then
        state="stale"
        session_info="pid:$pid"
      fi
    fi
    printf "%-8s %-10s %-20s %-8s %s\n" "$id" "$state" "$session_info" "$run_value" "$alias"
  done <<EOF
$lines
EOF
}

restart_accounts() {
  stop_accounts "$@"
  start_accounts
}

# ─── Entry point ──────────────────────────────────────────────────────────────
command="${1:-start}"
[ $# -gt 0 ] && shift

case "$command" in
  start)
    start_accounts "$@"
    ;;
  stop)
    stop_accounts "$@"
    ;;
  restart)
    restart_accounts "$@"
    ;;
  status)
    status_accounts
    ;;
  help|--help|-h)
    usage
    ;;
  *)
    fatal "unknown command: $command"
    ;;
esac
