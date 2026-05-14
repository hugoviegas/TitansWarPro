# shellcheck disable=SC2148
# ============================================================================
# ALTARS BATTLE - TitansWarPro AI Engine v3.0
# Integrated: core/helpers.sh
# ============================================================================

source "$(dirname "${BASH_SOURCE[0]}")/core/helpers.sh" 2>/dev/null || true

_altars_load_config() {
    local la hper rper
    la=$(   _cfg_get "altars" "la_start" 2>/dev/null)
    hper=$( _cfg_get "altars" "hper"     2>/dev/null)
    rper=$( _cfg_get "altars" "rper"     2>/dev/null)
    ALTARS_LA="${la:-${ALTARS_LA:-5.0}}"
    ALTARS_HPER="${hper:-${ALTARS_HPER:-50}}"
    ALTARS_RPER="${rper:-${ALTARS_RPER:-5}}"
}

_altars_log_event() {
    _log_battle_event "altars" "${1:-unknown}" "${2:-0}" "${3:-0}" "${4:-0}" "${5:-0}" "${6:-0}" "${7:-0}"
}
