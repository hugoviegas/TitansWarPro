#!/bin/sh
# ===========================================================================
# run_ai.sh - TitansWarPro AI Engine launcher
# Starts the AI orchestrator + the macro (via play.sh) together.
# Watchdog auto-restarts macro if it crashes; orchestrator stays resident.
# Usage: ./run_ai.sh [account] [macro args]
#   e.g. ./run_ai.sh A1
#        ./run_ai.sh A1 -cv
#        ./run_ai.sh --all   (delegates to twm_control.sh start)
# ===========================================================================

TWM_ROOT="$(cd "$(dirname "$0")" && pwd)"
LOGS_DIR="$TWM_ROOT/data/logs"
PID_FILE="$LOGS_DIR/orchestrator.pid"
ORCH_LOG="$LOGS_DIR/orchestrator.log"
MACRO_LOG="$LOGS_DIR/macro.log"

mkdir -p "$LOGS_DIR"

# ── Colors ────────────────────────────────────────────────────────────────
GOLD='\033[33m' GREEN='\033[32m' RED='\033[31m' CYAN='\033[36m' RESET='\033[00m'
_info()  { printf "  ${CYAN}[AI]${RESET} %s\n" "$*"; }
_ok()    { printf "  ${GREEN}[AI]${RESET} %s\n" "$*"; }
_warn()  { printf "  ${GOLD}[AI]${RESET} %s\n" "$*"; }
_error() { printf "  ${RED}[AI]${RESET} %s\n" "$*"; }

# ── python3 detection ────────────────────────────────────────────────────
PYTHON="$(command -v python3 2>/dev/null || command -v python 2>/dev/null || true)"
if [ -z "$PYTHON" ]; then
  _error "python3 not found. Install it first."
  exit 1
fi

# ── Load .env ─────────────────────────────────────────────────────────────
[ -f "$TWM_ROOT/.env" ] && . "$TWM_ROOT/.env"

if [ -z "${GEMINI_API_KEY:-}" ]; then
  _error "GEMINI_API_KEY not set. Edit $TWM_ROOT/.env"
  exit 1
fi

# ── Check requests (only real dependency) ─────────────────────────────────
if ! "$PYTHON" -c "import requests" 2>/dev/null; then
  _warn "requests not found. Installing..."
  pip3 install requests --quiet --prefer-binary || pip install requests --quiet --prefer-binary || true
fi

# ── GEMINI_API_KEY validation (quick ping) ────────────────────────────────
_check_key() {
  STATUS=$("$PYTHON" - <<'PYEOF' 2>/dev/null
import os, sys
try:
    import requests
    key = os.environ.get("GEMINI_API_KEY", "")
    r = requests.get(
        f"https://generativelanguage.googleapis.com/v1beta/models?key={key}",
        timeout=5
    )
    print("ok" if r.status_code == 200 else "fail")
except Exception:
    print("skip")
PYEOF
  )
  case "$STATUS" in
    ok)   _ok "Gemini API key valid." ;;
    fail) _warn "Gemini API key invalid or quota exceeded. Check ~/.twm/.env" ;;
    *)    _warn "Gemini API check skipped (offline?)" ;;
  esac
}
_check_key

# ── Orchestrator ─────────────────────────────────────────────────────────
_start_orchestrator() {
  if [ -f "$PID_FILE" ]; then
    OLD=$(cat "$PID_FILE")
    if kill -0 "$OLD" 2>/dev/null; then
      _info "Orchestrator already running (PID $OLD)"
      return 0
    fi
    rm -f "$PID_FILE"
  fi
  _info "Starting AI Orchestrator..."
  GEMINI_API_KEY="${GEMINI_API_KEY}" nohup "$PYTHON" "$TWM_ROOT/ai/orchestrator.py" >> "$ORCH_LOG" 2>&1 &
  ORCH_PID=$!
  echo "$ORCH_PID" > "$PID_FILE"
  sleep 2
  if ! kill -0 "$ORCH_PID" 2>/dev/null; then
    _error "Orchestrator failed to start. Check: $ORCH_LOG"
    exit 1
  fi
  _ok "Orchestrator started (PID $ORCH_PID). Log: $ORCH_LOG"
}

_stop_orchestrator() {
  if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    kill "$PID" 2>/dev/null && _warn "Orchestrator stopped (PID $PID)"
    rm -f "$PID_FILE"
  fi
}

# ── Macro start ───────────────────────────────────────────────────────────
# Prefer play.sh; fallback to run.sh for compatibility
_pick_script() {
  if [ -f "$TWM_ROOT/play.sh" ]; then
    echo "$TWM_ROOT/play.sh"
  elif [ -f "$TWM_ROOT/run.sh" ]; then
    echo "$TWM_ROOT/run.sh"
  else
    echo ""
  fi
}

_start_macro() {
  SCRIPT="$(_pick_script)"
  if [ -z "$SCRIPT" ]; then
    _warn "play.sh not found at $TWM_ROOT. Orchestrator running standalone."
    return 1
  fi
  _info "Starting macro: $(basename $SCRIPT) $*"
  bash "$SCRIPT" "$@" >> "$MACRO_LOG" 2>&1 &
  MACRO_PID=$!
  _ok "Macro started (PID $MACRO_PID). Log: $MACRO_LOG"
  return 0
}

# ── Cleanup ───────────────────────────────────────────────────────────────
MACRO_PID=""
_cleanup() {
  _warn "Shutting down AI Engine..."
  [ -n "$MACRO_PID" ] && kill "$MACRO_PID" 2>/dev/null || true
  _stop_orchestrator
  exit 0
}
trap _cleanup INT TERM

# ── Main ──────────────────────────────────────────────────────────────────
printf "\n  ${GOLD}==============================${RESET}\n"
printf   "  ${GOLD}  TitansWarPro  AI Engine     ${RESET}\n"
printf   "  ${GOLD}==============================${RESET}\n\n"

# --all mode: delegate to twm_control.sh
if [ "${1:-}" = "--all" ]; then
  shift
  _start_orchestrator
  _info "Starting all accounts via twm_control.sh..."
  bash "$TWM_ROOT/twm_control.sh" start "$@"
  wait
  _cleanup
fi

# Default account A1 if none specified
ACCOUNT="${1:-A1}"
shift || true

_start_orchestrator

# Watchdog loop: macro is restarted if it exits; orchestrator is also watched
RESTART_DELAY=5
while true; do
  _start_macro "$ACCOUNT" "$@" || break

  # Wait for macro
  wait "$MACRO_PID" 2>/dev/null
  CODE=$?
  _warn "Macro exited (code $CODE). Restarting in ${RESTART_DELAY}s... (Ctrl+C to stop)"
  sleep "$RESTART_DELAY"

  # Restart orchestrator if it crashed
  if [ -f "$PID_FILE" ]; then
    OP=$(cat "$PID_FILE")
    if ! kill -0 "$OP" 2>/dev/null; then
      _warn "Orchestrator crashed. Restarting..."
      _start_orchestrator
    fi
  fi
done

_cleanup
