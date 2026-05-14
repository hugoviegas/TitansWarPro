#!/usr/bin/env bash
# =============================================================================
# run_ai.sh  —  TitansWarPro AI Engine launcher
# Starts the macro (play.sh / run.sh) AND the AI orchestrator
# BOTH in full background. Safe to close the terminal after running.
#
# Usage:
#   bash run_ai.sh [ACCOUNT] [FLAGS...]   # launch everything in background
#   bash run_ai.sh --fg  [ACCOUNT] [FLAGS...]  # macro in foreground (watch live)
#   bash run_ai.sh --watch                # tail macro+orchestrator logs live
#   bash run_ai.sh --all                  # all accounts via multi_runner.sh
#   bash run_ai.sh --stop                 # stop everything
#   bash run_ai.sh --status               # show running processes
#   bash run_ai.sh --logs                 # tail all logs
# =============================================================================
set -uo pipefail

# ── Paths ───────────────────────────────────────────────────────────────────
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

# ── Detect python3 ───────────────────────────────────────────────────────────
PY=""
for _py in python3 python; do
  if command -v "$_py" &>/dev/null; then PY="$_py"; break; fi
done

# ── Helpers ────────────────────────────────────────────────────────────────
log()  { echo "[AI] $*"; }
err()  { echo "[AI][ERROR] $*" >&2; }

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

# ── --stop ──────────────────────────────────────────────────────────────────
do_stop() {
  stop_pid "$WATCH_PID" "Watchdog"
  stop_pid "$ORCH_PID"  "Orchestrator"
  stop_pid "$MACRO_PID" "Macro"
  log "All processes stopped."
}

# ── --status ───────────────────────────────────────────────────────────────
do_status() {
  echo "=== TitansWarPro AI Status ==="
  for pair in "Watchdog:$WATCH_PID" "Orchestrator:$ORCH_PID" "Macro:$MACRO_PID"; do
    name="${pair%%:*}"; f="${pair##*:}"
    if is_running "$f"; then
      echo "  $name: RUNNING (PID $(cat "$f"))"
    else
      echo "  $name: STOPPED"
    fi
  done
}

# ── --logs / --watch ───────────────────────────────────────────────────────
do_logs() {
  echo "=== Live logs (Ctrl+C to exit) ==="
  echo "    macro.log | orchestrator.log | watchdog.log"
  echo ""
  tail -f "$MACRO_LOG" "$ORCH_LOG" "$WATCH_LOG" 2>/dev/null
}

do_watch() {
  echo "=== Watching macro output live (Ctrl+C to exit) ==="
  echo "    Orchestrator + Watchdog continue in background."
  echo ""
  tail -f "$MACRO_LOG" 2>/dev/null
}

# ── Start macro in background ────────────────────────────────────────────
start_macro() {
  local account="${1:-}" flags="${2:-}"
  local macro_script; macro_script=$(pick_macro) || return 1

  local cmd="bash \"$macro_script\""
  [[ -n "$account" ]] && cmd+=' '"\"$account\""
  [[ -n "$flags"   ]] && cmd+=' '"$flags"

  nohup bash -c "$cmd" >> "$MACRO_LOG" 2>&1 &
  local pid=$!
  echo "$pid" > "$MACRO_PID"
  disown "$pid" 2>/dev/null || true
  log "Macro started (PID $pid) → $MACRO_LOG"
}

# ── Start macro in FOREGROUND (visible output) ───────────────────────
start_macro_fg() {
  local account="${1:-}" flags="${2:-}"
  local macro_script; macro_script=$(pick_macro) || return 1

  log "Macro running in foreground. Press Ctrl+C to stop."
  log "Orchestrator + Watchdog running in background."
  echo ""

  # Run macro in foreground — output goes straight to terminal
  # Also tee to log file so orchestrator can read it
  local cmd="bash \"$macro_script\""
  [[ -n "$account" ]] && cmd+=' '"\"$account\""
  [[ -n "$flags"   ]] && cmd+=' '"$flags"

  # Save PID via subshell trick
  bash -c "$cmd" 2>&1 | tee -a "$MACRO_LOG"

  # When macro ends (Ctrl+C or finishes), update PID file
  rm -f "$MACRO_PID"
  log "Macro ended. Orchestrator + Watchdog still running in background."
  log "To stop everything: bash run_ai.sh --stop"
}

# ── Start orchestrator in background ───────────────────────────────────
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

# ── Watchdog ─────────────────────────────────────────────────────────────────
start_watchdog() {
  local account="${1:-}" flags="${2:-}"
  local wscript; wscript=$(mktemp /tmp/twm_watchdog.XXXXXX.sh)
  cat > "$wscript" << WATCHDOG
#!/usr/bin/env bash
TWM_DIR="$TWM_DIR"
LOG_DIR="$LOG_DIR"
PID_DIR="$PID_DIR"
AI_DIR="$AI_DIR"
MACRO_LOG="$MACRO_LOG"
ORCH_LOG="$ORCH_LOG"
MACRO_PID="$MACRO_PID"
ORCH_PID="$ORCH_PID"
WATCH_LOG="$WATCH_LOG"
PY="$PY"
ACCOUNT="$account"
FLAGS="$flags"

log_w() { echo "\$(date '+%Y-%m-%d %H:%M:%S') [watchdog] \$*" >> "\$WATCH_LOG"; }
is_alive() { [[ -f "\$1" ]] && kill -0 "\$(cat "\$1")" 2>/dev/null; }

macro_script="\$TWM_DIR/play.sh"
[[ ! -f "\$macro_script" ]] && macro_script="\$TWM_DIR/run.sh"

log_w "Watchdog started (PID \$\$)"

while true; do
  sleep 15

  if ! is_alive "\$MACRO_PID"; then
    log_w "Macro died, restarting..."
    cmd="bash \"\$macro_script\""
    [[ -n "\$ACCOUNT" ]] && cmd+=' '"\"\$ACCOUNT\""
    [[ -n "\$FLAGS"   ]] && cmd+=' '"\$FLAGS"
    nohup bash -c "\$cmd" >> "\$MACRO_LOG" 2>&1 &
    echo "\$!" > "\$MACRO_PID"
    disown "\$!" 2>/dev/null || true
    log_w "Macro restarted (PID \$(cat \$MACRO_PID))"
  fi

  if [[ -n "\$PY" ]] && ! is_alive "\$ORCH_PID"; then
    log_w "Orchestrator died, restarting..."
    nohup "\$PY" "\$AI_DIR/orchestrator.py" >> "\$ORCH_LOG" 2>&1 &
    echo "\$!" > "\$ORCH_PID"
    disown "\$!" 2>/dev/null || true
    log_w "Orchestrator restarted (PID \$(cat \$ORCH_PID))"
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

# ── Main ────────────────────────────────────────────────────────────────────
ARG1="${1:-}"

case "$ARG1" in
  --stop)   do_stop;   exit 0 ;;
  --status) do_status; exit 0 ;;
  --logs)   do_logs;   exit 0 ;;
  --watch)  do_watch;  exit 0 ;;

  --fg)
    # Foreground mode: macro visible in terminal, AI in background
    shift || true
    ACCOUNT="${1:-}"; FLAGS="${*:2}"
    if is_running "$WATCH_PID" || is_running "$ORCH_PID" || is_running "$MACRO_PID"; then
      log "Stopping previous session..."; do_stop; sleep 1
    fi
    echo ""
    echo "  =============================="
    echo "   TitansWarPro  AI Engine  [FG]"
    echo "  =============================="
    echo ""
    start_orchestrator
    start_watchdog "$ACCOUNT" "$FLAGS"
    start_macro_fg "$ACCOUNT" "$FLAGS"   # blocks until macro ends/Ctrl+C
    ;;

  --all)
    log "Starting all accounts via multi_runner.sh..."
    nohup bash "$TWM_DIR/multi_runner.sh" >> "$MACRO_LOG" 2>&1 &
    mpid=$!
    echo "$mpid" > "$MACRO_PID"
    disown "$mpid" 2>/dev/null || true
    log "multi_runner started (PID $mpid)"
    start_orchestrator
    start_watchdog "" ""
    ;;

  *)
    # Default: full background
    ACCOUNT="$ARG1"
    FLAGS="${*:2}"
    if is_running "$WATCH_PID" || is_running "$ORCH_PID" || is_running "$MACRO_PID"; then
      log "Stopping previous session..."; do_stop; sleep 1
    fi
    echo ""
    echo "  =============================="
    echo "   TitansWarPro  AI Engine"
    echo "  =============================="
    echo ""
    start_macro       "$ACCOUNT" "$FLAGS"
    start_orchestrator
    start_watchdog    "$ACCOUNT" "$FLAGS"
    echo ""
    log "All processes launched in background."
    log "Terminal can be safely closed."
    echo ""
    log "Commands:"
    log "  Watch macro : bash run_ai.sh --watch"
    log "  All logs    : bash run_ai.sh --logs"
    log "  Status      : bash run_ai.sh --status"
    log "  Stop        : bash run_ai.sh --stop"
    echo ""
    ;;
esac
