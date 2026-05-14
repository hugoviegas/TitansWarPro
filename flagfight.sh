# shellcheck disable=SC2148
# ============================================================================
# FLAG FIGHT - TitansWarPro AI Engine v3.0
# Integrated: core/helpers.sh
# ============================================================================

source "$(dirname "${BASH_SOURCE[0]}")/core/helpers.sh" 2>/dev/null || true

_flagfight_load_config() {
    local la hper rper
    la=$(   _cfg_get "flagfight" "la_start" 2>/dev/null)
    hper=$( _cfg_get "flagfight" "hper"     2>/dev/null)
    rper=$( _cfg_get "flagfight" "rper"     2>/dev/null)
    FF_LA="${la:-${FF_LA:-5.0}}"
    FF_HPER="${hper:-${FF_HPER:-40}}"
    FF_RPER="${rper:-${FF_RPER:-5}}"
}

_flagfight_log_event() {
    _log_battle_event "flagfight" "${1:-unknown}" "${2:-0}" "${3:-0}" "${4:-0}" "${5:-0}" "${6:-0}" "${7:-0}"
}
