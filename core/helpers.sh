# shellcheck disable=SC2148
# ============================================================================
# CORE HELPERS - TitansWarPro AI Engine
# Shared fetch, parser, logger for all battle scripts
# ============================================================================

# ── Config paths ──────────────────────────────────────────────────────────────
TWM_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)"
STRATEGY_CFG="${TWM_ROOT}/data/configs/strategy_config.json"
GAME_LOGS="${TWM_ROOT}/data/logs"
BACKUPS_DIR="${TWM_ROOT}/data/backups"
mkdir -p "$GAME_LOGS" "$BACKUPS_DIR" "${TWM_ROOT}/data/configs" "${TWM_ROOT}/data/metrics"

# ── Unified fetch ────────────────────────────────────────────────────────────
# Usage: _fetch "/path" [dest_file] [timeout_sec]
_fetch() {
    local path="$1"
    local dest="${2:-${src_ram}}"
    local timeout="${3:-17}"
    (
        w3mc -cookie \
             -o http_proxy="$PROXY" \
             -o accept_encoding=UTF-8 \
             -debug -dump_source "${URL}${path}" \
             -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" \
             >"$dest"
    ) </dev/null &>/dev/null &
    time_exit "$timeout"
}

# ── Strategy config reader (requires jq) ─────────────────────────────────────
# Usage: _cfg_get "coliseum" "la_start"  → prints value
_cfg_get() {
    local mode="$1" key="$2"
    if [ -f "$STRATEGY_CFG" ] && command -v jq &>/dev/null; then
        jq -r --arg m "$mode" --arg k "$key" '.[$m][$k] // empty' "$STRATEGY_CFG" 2>/dev/null
    fi
}

# ── Unified battle state parser ───────────────────────────────────────────────
# Reads $src_ram, sets: USH ENH ATK ATKRND DODGE HEAL STONE GRASS
_parse_battle_state() {
    local src="${1:-${src_ram}}"
    USH=$(grep -m1 -oP '(?<=hp)[^A-Za-z0-9]{1,4}\K[0-9]{2,5}' "$src" 2>/dev/null)
    ENH=$(grep -m1 -oP '(?<=nbsp;)[0-9]{1,6}' "$src" 2>/dev/null)
    ATK=$(grep -m1 -oP '/[a-z]+/atk[^"]*' "$src" 2>/dev/null | head -1)
    ATKRND=$(grep -m1 -oP '/[a-z]+/atkrnd[^"]*' "$src" 2>/dev/null)
    DODGE=$(grep -m1 -oP '/[a-z]+/dodge[^"]*' "$src" 2>/dev/null)
    HEAL=$(grep -m1 -oP '/[a-z]+/heal[^"]*' "$src" 2>/dev/null)
    STONE=$(grep -m1 -oP '/[a-z]+/stone[^"]*' "$src" 2>/dev/null)
    GRASS=$(grep -m1 -oP '/[a-z]+/grass[^"]*' "$src" 2>/dev/null)
}

# ── Battle event logger ───────────────────────────────────────────────────────
# Usage: _log_battle_event "coliseum" "win" 120 4.5 38 15 3 2
# Args:  mode result duration la hper atks heals kills
_log_battle_event() {
    local mode="$1" result="$2" duration="$3"
    local la="${4:-0}" hper="${5:-0}" atks="${6:-0}" heals="${7:-0}" kills="${8:-0}"
    local ts
    ts=$(date -u +%FT%TZ)
    printf '{"ts":"%s","mode":"%s","result":"%s","dur":%d,"la":"%s","hper":%s,"atks":%d,"heals":%d,"kills":%d}\n' \
        "$ts" "$mode" "$result" "$duration" "$la" "$hper" "$atks" "$heals" "$kills" \
        >> "${GAME_LOGS}/game_events.jsonl"
}

# ── RAM temp dir helper ───────────────────────────────────────────────────────
_ram_dir() {
    if [ -d "/dev/shm" ]; then echo "/dev/shm/"; else echo "${PREFIX:-}/tmp/"; fi
}
