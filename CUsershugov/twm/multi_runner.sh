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
  start            Start all accounts marked as active in accounts/index.json.
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

is_running() {
  local pid="$1"
  if [ -z "$pid" ]; then
    return 1
  fi
  if kill -0 "$pid" 2>/dev/null; then
    return 0
  fi
  return 1
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

start_account() {
  local account_id="$1"
  local account_alias="$2"
  local account_ur="$3"
  local account_runmode="$4"
  local account_timezone="$5"
  local account_autorestart="$6"

  local account_root="${ACCOUNTS_DIR}/${account_id}"
  local account_logs="${account_root}/logs"
  local account_run_file="${account_root}/runmode_file"
  local account_ur_file="${account_root}/ur_file"
  local log_file="${account_logs}/twm.log"
  local runner_script="${RUNTIME_DIR}/${account_id}_runner.sh"
  local pid_file="${PID_DIR}/${account_id}.pid"

  ensure_account_dirs "$account_root"
  mkdir -p "$PID_DIR" "$RUNTIME_DIR"

  if [ -n "$account_ur" ]; then
    if [ ! -f "$account_ur_file" ] || [ "$(cat "$account_ur_file" 2>/dev/null)" != "$account_ur" ]; then
      printf '%s\n' "$account_ur" > "$account_ur_file"
    fi
  fi

  if [ -n "$account_runmode" ]; then
    printf '%s\n' "$account_runmode" > "$account_run_file"
  fi

  if [ -f "$pid_file" ]; then
    local existing_pid
    existing_pid="$(cat "$pid_file" 2>/dev/null || true)"
    if is_running "$existing_pid"; then
      echo "[${account_id}] already running (pid $existing_pid)"
      return
    fi
  fi

  touch "$log_file"
  if [ -z "$account_autorestart" ]; then
    account_autorestart="true"
  fi

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
trap 'if [ -n "\$child_pid" ]; then kill "\$child_pid" 2>/dev/null; wait "\$child_pid" 2>/dev/null || true; fi; exit 0' INT TERM
while true; do
  echo "\$(date +'%Y-%m-%d %H:%M:%S') [\${ACCOUNT_ALIAS:-$account_id}] starting twm.sh" >> "\$LOG_FILE"
  "\${BASE_DIR}/twm.sh" >> "\$LOG_FILE" 2>&1 &
  child_pid=\$!
  wait "\$child_pid"
  exit_code=\$?
  child_pid=""
  echo "\$(date +'%Y-%m-%d %H:%M:%S') [\${ACCOUNT_ALIAS:-$account_id}] twm.sh exited with code \$exit_code" >> "\$LOG_FILE"
  if [ "\$AUTO_RESTART" != "true" ]; then
    exit "\$exit_code"
  fi
  sleep 5
done
EOF

  chmod +x "$runner_script"
  nohup "$runner_script" >/dev/null 2>&1 &
  local runner_pid=$!
  echo "$runner_pid" > "$pid_file"
  echo "[${account_id}] started (pid $runner_pid)"
}

start_accounts() {
  mkdir -p "$PID_DIR" "$RUNTIME_DIR"
  local have_accounts=false
  while IFS=$'\t' read -r id alias ur runmode timezone autorestart active_flag; do
    [ -n "$id" ] || continue
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
  mkdir -p "$PID_DIR"
  local ids_list=""
  if [ $# -gt 0 ]; then
    ids_list="$*"
  else
    for file in "$PID_DIR"/*.pid; do
      [ -e "$file" ] || continue
      ids_list="$ids_list $(basename "${file%.pid}")"
    done
  fi

  if [ -z "$ids_list" ]; then
    echo "No running account processes found."
    return
  fi

  for id in $ids_list; do
    local pid_file="${PID_DIR}/${id}.pid"
    if [ ! -f "$pid_file" ]; then
      echo "[${id}] no pid file; skipping"
      continue
    fi
    local pid
    pid="$(cat "$pid_file" 2>/dev/null || true)"
    if [ -n "$pid" ] && is_running "$pid"; then
      echo "[${id}] stopping pid $pid"
      kill "$pid" 2>/dev/null || true
      for _ in 1 2 3 4 5; do
        if ! is_running "$pid"; then
          break
        fi
        sleep 1
      done
      if is_running "$pid"; then
        kill -9 "$pid" 2>/dev/null || true
      fi
    else
      echo "[${id}] runner not active"
    fi
    rm -f "$pid_file"
  done
}

status_accounts() {
  require_index
  require_jq
  printf "%-8s %-10s %-8s %-8s %s\n" "ID" "State" "PID" "RunMode" "Alias"
  local lines
  lines="$(load_accounts all)"
  if [ -z "$lines" ]; then
    echo "(index is empty)"
    return
  fi
  while IFS=$'\t' read -r id alias ur runmode timezone autorestart active_flag; do
    [ -n "$id" ] || continue
    local pid_file="${PID_DIR}/${id}.pid"
    local run_file="${ACCOUNTS_DIR}/${id}/runmode_file"
    local run_value="-"
    if [ -f "$run_file" ]; then
      run_value="$(cat "$run_file" 2>/dev/null | tr -d '\r')"
      [ -n "$run_value" ] || run_value="-"
    fi
    local pid_value="-"
    local state="stopped"
    if [ "$active_flag" != "true" ]; then
      state="inactive"
    fi
    if [ -f "$pid_file" ]; then
      local pid
      pid="$(cat "$pid_file" 2>/dev/null || true)"
      if is_running "$pid"; then
        pid_value="$pid"
        state="running"
      elif [ "$pid" ]; then
        pid_value="$pid"
        [ "$state" = "inactive" ] || state="stale"
      fi
    fi
    printf "%-8s %-10s %-8s %-8s %s\n" "$id" "$state" "$pid_value" "$run_value" "$alias"
  done <<EOF
$lines
EOF
}

restart_accounts() {
  stop_accounts "$@"
  start_accounts
}

command="${1:-start}"
if [ $# -gt 0 ]; then
  shift
fi

case "$command" in
  start)
    start_accounts
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
