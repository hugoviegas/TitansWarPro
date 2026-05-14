# shellcheck disable=SC2148
# ============================================================================
# UNDYING BOSS - TitansWarPro AI Engine v3.0
# Integrated: core/helpers.sh
# ============================================================================

source "$(dirname "${BASH_SOURCE[0]}")/core/helpers.sh" 2>/dev/null || true

_undying_load_config() {
    local la hper rper
    la=$(   _cfg_get "undying" "la_start" 2>/dev/null)
    hper=$( _cfg_get "undying" "hper"     2>/dev/null)
    rper=$( _cfg_get "undying" "rper"     2>/dev/null)
    UD_LA="${la:-${UD_LA:-5.0}}"
    UD_HPER="${hper:-${UD_HPER:-50}}"
    UD_RPER="${rper:-${UD_RPER:-5}}"
}

_undying_log_event() {
    _log_battle_event "undying" "${1:-unknown}" "${2:-0}" "${3:-0}" "${4:-0}" "${5:-0}" "${6:-0}" "${7:-0}"
}
