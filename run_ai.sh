#!/bin/bash
# ===========================================================================
# run_ai.sh - TitansWarPro AI Engine launcher
# Starts the AI orchestrator + the macro together.
# Monitors both and auto-restarts if either crashes.
# Usage: ./run_ai.sh [macro args]
# ===========================================================================

set -e

TWM_ROOT="$(cd "$(dirname "$0")" && pwd)"
AI_DIR="$TWM_ROOT/ai"
LOGS_DIR="$TWM_ROOT/data/logs"
PID_FILE="$LOGS_DIR/orchestrator.pid"
ORCHESTRATOR_LOG="$LOGS_DIR/orchestrator.log"
MACRO_SCRIPT="$TWM_ROOT/run.sh"

mkdir -p "$LOGS_DIR"

# ── Colors ───────────────────────────────────────────────────────────────
GOLD='\033[33m'; GREEN='\033[32m'; RED='\033[31m'; CYAN='\033[36m'; RESET='\033[00m'

_info()  { printf "  ${CYAN}[AI]${RESET} %s\n" "$*"; }
_ok()    { printf "  ${GREEN}[AI]${RESET} %s\n" "$*"; }
_warn()  { printf "  ${GOLD}[AI]${RESET} %s\n" "$*"; }
_error() { printf "  ${RED}[AI]${RESET} %s\n" "$*"; }

# ── Validate requirements ───────────────────────────────────────────────
_check_requirements() {
    local ok=1

    if ! command -v python3 &>/dev/null; then
        _error "python3 not found. Install it first."; ok=0
    fi

    if ! python3 -c "import google.generativeai" &>/dev/null; then
        _warn "google-generativeai not installed. Running: pip install -r ai/requirements.txt"
        pip install -r "$AI_DIR/requirements.txt" --quiet && \
            _ok "Dependencies installed." || { _error "pip install failed."; ok=0; }
    fi

    if [ -z "${GEMINI_API_KEY:-}" ]; then
        # Try loading from .env
        [ -f "$TWM_ROOT/.env" ] && . "$TWM_ROOT/.env"
        if [ -z "${GEMINI_API_KEY:-}" ]; then
            _error "GEMINI_API_KEY not set."
            _error "Add it to $TWM_ROOT/.env: GEMINI_API_KEY=your_key_here"
            ok=0
        fi
    fi

    if ! command -v jq &>/dev/null; then
        _warn "jq not found - strategy_config reading will be disabled for bash scripts."
        _warn "Install: pkg install jq  (Cygwin) or  apt install jq  (Linux)"
    fi

    [ "$ok" -eq 1 ]
}

# ── Start orchestrator ──────────────────────────────────────────────────
_start_orchestrator() {
    if [ -f "$PID_FILE" ]; then
        local old_pid; old_pid=$(cat "$PID_FILE")
        if kill -0 "$old_pid" 2>/dev/null; then
            _info "Orchestrator already running (PID $old_pid)"
            return 0
        fi
    fi
    _info "Starting AI Orchestrator..."
    ( cd "$AI_DIR" && \
      GEMINI_API_KEY="${GEMINI_API_KEY}" \
      python3 orchestrator.py >> "$ORCHESTRATOR_LOG" 2>&1 ) &
    echo $! > "$PID_FILE"
    _ok "Orchestrator started (PID $!). Log: $ORCHESTRATOR_LOG"
}

# ── Stop orchestrator ──────────────────────────────────────────────────
_stop_orchestrator() {
    if [ -f "$PID_FILE" ]; then
        local pid; pid=$(cat "$PID_FILE")
        kill "$pid" 2>/dev/null && _warn "Orchestrator stopped (PID $pid)"
        rm -f "$PID_FILE"
    fi
}

# ── Watchdog: restart if either process dies ─────────────────────────────
_watchdog() {
    local macro_pid="$1"
    local restart_delay=10

    while true; do
        sleep 30

        # Check orchestrator
        if [ -f "$PID_FILE" ]; then
            local orch_pid; orch_pid=$(cat "$PID_FILE")
            if ! kill -0 "$orch_pid" 2>/dev/null; then
                _warn "Orchestrator crashed. Restarting..."
                _start_orchestrator
            fi
        fi

        # If macro ended normally, watchdog exits too
        if ! kill -0 "$macro_pid" 2>/dev/null; then
            _info "Macro process ended. Stopping orchestrator."
            _stop_orchestrator
            exit 0
        fi
    done
}

# ── Cleanup on exit ─────────────────────────────────────────────────────
_cleanup() {
    _warn "Shutting down AI Engine..."
    _stop_orchestrator
    kill "$MACRO_PID" 2>/dev/null
    exit 0
}
trap _cleanup INT TERM

# ── Main ────────────────────────────────────────────────────────────────
printf "\n  ${GOLD}==============================${RESET}\n"
printf   "  ${GOLD}  TitansWarPro  AI Engine     ${RESET}\n"
printf   "  ${GOLD}==============================${RESET}\n\n"

_check_requirements || { _error "Requirements not met. Aborting."; exit 1; }

# Load .env if exists
[ -f "$TWM_ROOT/.env" ] && . "$TWM_ROOT/.env"

_start_orchestrator

# Start the macro
if [ -f "$MACRO_SCRIPT" ]; then
    _info "Starting macro: $MACRO_SCRIPT $*"
    bash "$MACRO_SCRIPT" "$@" &
    MACRO_PID=$!
    _ok "Macro started (PID $MACRO_PID)"
else
    _warn "run.sh not found at $MACRO_SCRIPT"
    _warn "Starting orchestrator only (no macro)."
    MACRO_PID=$$
fi

# Start watchdog in background
_watchdog "$MACRO_PID" &

# Wait for macro
wait "$MACRO_PID" 2>/dev/null
_cleanup
