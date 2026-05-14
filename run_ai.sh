#!/usr/bin/env bash
# =============================================================================
# run_ai.sh  —  TitansWarPro AI Engine launcher
#
# Usage:
#   bash run_ai.sh [ACCOUNT] [FLAGS...]   # full background
#   bash run_ai.sh --fg [ACCOUNT] [FLAGS] # macro foreground, AI background
#   bash run_ai.sh --watch                # tail macro log live
#   bash run_ai.sh --all                  # all accounts via multi_runner.sh
#   bash run_ai.sh --stop                 # stop everything
#   bash run_ai.sh --status               # show running processes
#   bash run_ai.sh --logs                 # tail all logs
# =============================================================================
set -uo pipefail

# ── Paths ────────────────────────────────────────────────────────────────────
TWM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$TWM_DIR/data/logs"
PID_DIR="$TWM_DIR/data/pids"
AI_DIR="$TWM_DIR/ai"

ORCH_LOG="$LOG_DIR/orchestrator.log"
MACRO_LOG="$LOG_DIR/macro.log"
WATCH_LOG="$LOG_DIR/watchdog.log"
ORCH_PID="$PID_DIR/orchestrator.pid"
MACRO_PID="$PID_DIR/macro.pid"
WATCH_PID="$PID_DIR/watchdog.pid"

mkdir -p "$LOG_DIR" "$PID_DIR"

# ── Detect python ─────────────────────────────────────────────────────────────
PY=""
for _py in python3 python; do
  if command -v "$_py" &>/dev/null; then PY="$_py"; break; fi
done

# ── Helpers ───────────────────────────────────────────────────────────────────
log() { echo "[AI] $*"; }
err() { echo "[AI][ERROR] $*" >&2; }

is_running() { local f="$1"; [[ -f "$f" ]] && kill -0 "$(cat "$f")" 2>/dev/null; }

stop_pid() {
  local f="$1" name="$2"
  if [[ -f "$f" ]]; then
    local pid; pid=$(cat "$f")
    if kill -0 "$pid" 2>/dev/null; then
      kill "$pid" 2>/dev/null
      log "$name stopped (PID $pid)"
    fi
    rm -f "$f"
  fi
}

pick_macro() {
  if   [[ -f "$TWM_DIR/play.sh" ]]; then echo "$TWM_DIR/play.sh"
  elif [[ -f "$TWM_DIR/run.sh"  ]]; then echo "$TWM_DIR/run.sh"
  else err "No macro script found (play.sh or run.sh)"; return 1
  fi
}

# ── Kill ALL stale watchdog processes (tmp scripts + previous PIDs) ──────────
kill_stale() {
  # kill any twm_watchdog scripts still alive from previous runs
  pkill -f "twm_watchdog" 2>/dev/null || true
  # stop via PID files
  stop_pid "$WATCH_PID" "Watchdog"
  stop_pid "$ORCH_PID"  "Orchestrator"
  stop_pid "$MACRO_PID" "Macro"
  # remove leftover tmp scripts
  rm -f /tmp/twm_watchdog.*.sh
  # wipe PID files
  rm -f "$PID_DIR"/*.pid
}

# ── --stop ────────────────────────────────────────────────────────────────────
do_stop() {
  pkill -f "$AI_DIR/orchestrator.py" 2>/dev/null || true
  pkill -f "$TWM_DIR/play.sh"        2>/dev/null || true
  pkill -f "$TWM_DIR/run.sh"         2>/dev/null || true
  kill_stale
  log "All processes stopped."
}

# ── --status ──────────────────────────────────────────────────────────────────
do_status() {
  echo "=== TitansWarPro AI Status ==="
  for pair in "Watchdog:$WATCH_PID" "Orchestrator:$ORCH_PID" "Macro:$MACRO_PID"; do
    name="${pair%%:*}"; f="${pair##*:}"
    if is_running "$f"; then
      echo "  $name : RUNNING (PID $(cat "$f"))"
    else
      echo "  $name : STOPPED"
    fi
  done
}

# ── --logs / --watch ──────────────────────────────────────────────────────────
do_logs()  { echo "=== All logs (Ctrl+C exits) ==="; tail -f "$MACRO_LOG" "$ORCH_LOG" "$WATCH_LOG" 2>/dev/null; }
do_watch() { echo "=== Macro live (Ctrl+C exits, macro keeps running) ==="; tail -f "$MACRO_LOG" 2>/dev/null; }

# ── Start macro (background) ─────────────────────────────────────────────────
start_macro() {
  local account="${1:-}" flags="${2:-}"
  local macro_script; macro_script=$(pick_macro) || return 1

  if [[ -n "$account" && ! -d "$TWM_DIR/accounts/$account" ]]; then
    err "Account '$account' not found in $TWM_DIR/accounts/"
    return 1
  fi

  local cmd="bash \"$macro_script\""
  [[ -n "$account" ]] && cmd+=" \"$account\""
  [[ -n "$flags"   ]] && cmd+=" $flags"

  nohup bash -c "$cmd" >> "$MACRO_LOG" 2>&1 &
  local pid=$!
  echo "$pid" > "$MACRO_PID"
  disown "$pid" 2>/dev/null || true
  log "Macro started (PID $pid) → $MACRO_LOG"
}

# ── Start macro (foreground — visible in terminal, tee to log) ───────────────
start_macro_fg() {
  local account="${1:-}" flags="${2:-}"
  local macro_script; macro_script=$(pick_macro) || return 1

  if [[ -n "$account" && ! -d "$TWM_DIR/accounts/$account" ]]; then
    err "Account '$account' not found in $TWM_DIR/accounts/"
    return 1
  fi

  local cmd="bash \"$macro_script\""
  [[ -n "$account" ]] && cmd+=" \"$account\""
  [[ -n "$flags"   ]] && cmd+=" $flags"

  log "Macro running in foreground  (Ctrl+C to stop macro only)"
  log "Orchestrator + Watchdog running in background"
  echo ""

  # Run macro with output mirrored to log
  bash -c "$cmd" 2>&1 | tee -a "$MACRO_LOG"
  rm -f "$MACRO_PID"

  echo ""
  log "Macro ended. AI still running in background."
  log "Stop all: bash run_ai.sh --stop"
}

# ── Start orchestrator ────────────────────────────────────────────────────────
start_orchestrator() {
  if [[ -z "$PY" ]]; then
    err "Python not found. Install python3 first."
    return 1
  fi
  nohup "$PY" "$AI_DIR/orchestrator.py" >> "$ORCH_LOG" 2>&1 &
  local pid=$!
  echo "$pid" > "$ORCH_PID"
  disown "$pid" 2>/dev/null || true
  log "Orchestrator started (PID $pid) → $ORCH_LOG"
}

# ── Start watchdog ────────────────────────────────────────────────────────────
# MODE:
#   bg  — restart macro automatically if it dies
#   fg  — do NOT restart macro (user controls it from terminal)
#   all — restart multi_runner instead
start_watchdog() {
  local account="${1:-}" flags="${2:-}" mode="${3:-bg}"
  local wscript; wscript=$(mktemp /tmp/twm_watchdog.XXXXXX.sh)

  cat > "$wscript" << WATCHDOG
#!/usr/bin/env bash
TWM_DIR="$TWM_DIR"
AI_DIR="$AI_DIR"
MACRO_LOG="$MACRO_LOG"
ORCH_LOG="$ORCH_LOG"
MACRO_PID="$MACRO_PID"
ORCH_PID="$ORCH_PID"
WATCH_LOG="$WATCH_LOG"
PY="$PY"
ACCOUNT="$account"
FLAGS="$flags"
MODE="$mode"

log_w() { echo "\$(date '+%Y-%m-%d %H:%M:%S') [watchdog] \$*" >> "\$WATCH_LOG"; }
is_alive() { [[ -f "\$1" ]] && kill -0 "\$(cat "\$1")" 2>/dev/null; }

macro_script="\$TWM_DIR/play.sh"
[[ ! -f "\$macro_script" ]] && macro_script="\$TWM_DIR/run.sh"

log_w "Watchdog started (PID \$\$) mode=\$MODE account='\$ACCOUNT'"

while true; do
  sleep 15

  # ── Restart macro if dead ────────────────────────────────────────────────
  if ! is_alive "\$MACRO_PID"; then
    if [[ "\$MODE" == "fg" ]]; then
      log_w "Foreground mode: macro exited, not auto-restarting."

    elif [[ -n "\$ACCOUNT" && ! -d "\$TWM_DIR/accounts/\$ACCOUNT" ]]; then
      log_w "Invalid account '\$ACCOUNT'; not restarting macro."

    else
      log_w "Macro died, restarting..."
      local_cmd="bash \"\$macro_script\""
      [[ -n "\$ACCOUNT" ]] && local_cmd+=" \"\$ACCOUNT\""
      [[ -n "\$FLAGS"   ]] && local_cmd+=" \$FLAGS"
      nohup bash -c "\$local_cmd" >> "\$MACRO_LOG" 2>&1 &
      echo "\$!" > "\$MACRO_PID"
      disown "\$!" 2>/dev/null || true
      log_w "Macro restarted (PID \$(cat "\$MACRO_PID"))"
    fi
  fi

  # ── Restart orchestrator if dead ─────────────────────────────────────────
  if [[ -n "\$PY" ]] && ! is_alive "\$ORCH_PID"; then
    log_w "Orchestrator died, restarting..."
    nohup "\$PY" "\$AI_DIR/orchestrator.py" >> "\$ORCH_LOG" 2>&1 &
    echo "\$!" > "\$ORCH_PID"
    disown "\$!" 2>/dev/null || true
    log_w "Orchestrator restarted (PID \$(cat "\$ORCH_PID"))"
  fi
done
WATCHDOG

  chmod +x "$wscript"
  nohup bash "$wscript" >> "$WATCH_LOG" 2>&1 &
  local pid=$!
  echo "$pid" > "$WATCH_PID"
  disown "$pid" 2>/dev/null || true
  log "Watchdog started (PID $pid) → $WATCH_LOG"
}

# ── Common startup banner ─────────────────────────────────────────────────────
banner() {
  echo ""
  echo "  =============================="
  echo "   TitansWarPro  AI Engine  $1"
  echo "  =============================="
  echo ""
}

# ── Main ──────────────────────────────────────────────────────────────────────
CMD="${1:-}"

case "$CMD" in
  --stop)   do_stop;   exit 0 ;;
  --status) do_status; exit 0 ;;
  --logs)   do_logs;   exit 0 ;;
  --watch)  do_watch;  exit 0 ;;

  --fg)
    # !! shift removes --fg so $1 becomes ACCOUNT !!
    shift
    ACCOUNT="${1:-}"
    FLAGS="${*:2}"

    log "Stopping any stale processes..."
    kill_stale
    sleep 1

    banner "[FG]"
    start_orchestrator
    start_watchdog "$ACCOUNT" "$FLAGS" "fg"
    start_macro_fg "$ACCOUNT" "$FLAGS"   # blocks until Ctrl+C or macro ends
    ;;

  --all)
    log "Stopping any stale processes..."
    kill_stale
    sleep 1

    banner "[ALL]"
    nohup bash "$TWM_DIR/multi_runner.sh" >> "$MACRO_LOG" 2>&1 &
    mpid=$!
    echo "$mpid" > "$MACRO_PID"
    disown "$mpid" 2>/dev/null || true
    log "multi_runner started (PID $mpid)"
    start_orchestrator
    start_watchdog "" "" "all"
    ;;

  *)
    ACCOUNT="$CMD"
    FLAGS="${*:2}"

    log "Stopping any stale processes..."
    kill_stale
    sleep 1

    banner ""
    start_macro        "$ACCOUNT" "$FLAGS" || exit 1
    start_orchestrator
    start_watchdog     "$ACCOUNT" "$FLAGS" "bg"

    echo ""
    log "All processes launched in background."
    log "Close terminal safely or use:"
    log "  Watch  : bash run_ai.sh --watch"
    log "  Status : bash run_ai.sh --status"
    log "  Stop   : bash run_ai.sh --stop"
    echo ""
    ;;
esac
