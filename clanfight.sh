# shellcheck disable=SC2148
# ============================================================================
# CLAN FIGHT - TitansWarPro AI Engine v3.0
# Integrated: core/helpers.sh
# ============================================================================

source "$(dirname "${BASH_SOURCE[0]}")/core/helpers.sh" 2>/dev/null || true

_clanfight_load_config() {
    local la hper rper
    la=$(   _cfg_get "clanfight" "la_start" 2>/dev/null)
    hper=$( _cfg_get "clanfight" "hper"     2>/dev/null)
    rper=$( _cfg_get "clanfight" "rper"     2>/dev/null)
    CF_LA="${la:-${CF_LA:-4.0}}"
    CF_HPER="${hper:-${CF_HPER:-35}}"
    CF_RPER="${rper:-${CF_RPER:-5}}"
}

_clanfight_log_event() {
    _log_battle_event "clanfight" "${1:-unknown}" "${2:-0}" "${3:-0}" "${4:-0}" "${5:-0}" "${6:-0}" "${7:-0}"
}
