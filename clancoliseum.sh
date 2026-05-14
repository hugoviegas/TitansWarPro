# shellcheck disable=SC2148
# ============================================================================
# CLAN COLISEUM BATTLE - TitansWarPro AI Engine v3.0
# Integrated: core/helpers.sh
# ============================================================================

source "$(dirname "${BASH_SOURCE[0]}")/core/helpers.sh" 2>/dev/null || true

_clancoliseum_load_config() {
    local la hper rper
    la=$(   _cfg_get "clancoliseum" "la_start" 2>/dev/null)
    hper=$( _cfg_get "clancoliseum" "hper"     2>/dev/null)
    rper=$( _cfg_get "clancoliseum" "rper"     2>/dev/null)
    CC_LA="${la:-${CC_LA:-5.0}}"
    CC_HPER="${hper:-${CC_HPER:-40}}"
    CC_RPER="${rper:-${CC_RPER:-5}}"
}

_clancoliseum_log_event() {
    _log_battle_event "clancoliseum" "${1:-unknown}" "${2:-0}" "${3:-0}" "${4:-0}" "${5:-0}" "${6:-0}" "${7:-0}"
}
