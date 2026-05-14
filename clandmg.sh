# shellcheck disable=SC2148
# ============================================================================
# CLAN DMG - TitansWarPro AI Engine v3.0
# Integrated: core/helpers.sh
# ============================================================================

source "$(dirname "${BASH_SOURCE[0]}")/core/helpers.sh" 2>/dev/null || true

_clandmg_load_config() {
    local la hper rper
    la=$(   _cfg_get "clandmg" "la_start" 2>/dev/null)
    hper=$( _cfg_get "clandmg" "hper"     2>/dev/null)
    rper=$( _cfg_get "clandmg" "rper"     2>/dev/null)
    CDG_LA="${la:-${CDG_LA:-4.0}}"
    CDG_HPER="${hper:-${CDG_HPER:-35}}"
    CDG_RPER="${rper:-${CDG_RPER:-5}}"
}

_clandmg_log_event() {
    _log_battle_event "clandmg" "${1:-unknown}" "${2:-0}" "${3:-0}" "${4:-0}" "${5:-0}" "${6:-0}" "${7:-0}"
}
