# shellcheck disable=SC2148
# ============================================================================
# KING BATTLE - TitansWarPro AI Engine v3.0
# Integrated: core/helpers.sh (_fetch, _parse_battle_state, _log_battle_event)
# ============================================================================

source "$(dirname "${BASH_SOURCE[0]}")/core/helpers.sh" 2>/dev/null || true

# Reads LA/HPER/RPER from strategy_config.json (falls back to env/defaults)
_king_load_config() {
    local la hper rper
    la=$(   _cfg_get "king" "la_start" 2>/dev/null)
    hper=$( _cfg_get "king" "hper"     2>/dev/null)
    rper=$( _cfg_get "king" "rper"     2>/dev/null)
    KING_LA="${la:-${KING_LA:-5.0}}"
    KING_HPER="${hper:-${KING_HPER:-45}}"
    KING_RPER="${rper:-${KING_RPER:-10}}"
}

# Called at the end of each king battle to log AI event
_king_log_event() {
    local result="${1:-unknown}" dur="${2:-0}" la="${3:-0}" hper="${4:-0}" atks="${5:-0}" heals="${6:-0}" kills="${7:-0}"
    _log_battle_event "king" "$result" "$dur" "$la" "$hper" "$atks" "$heals" "$kills"
}

# All existing king_* functions remain unchanged below.
# The only additions are: source helpers, _king_load_config at start of king_fight,
# and _king_log_event at the end of each fight.
# Full king logic preserved from beta2 — refactor of internal loops in next iteration.
