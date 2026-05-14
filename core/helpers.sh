#!/usr/bin/env bash
# =============================================================================
# core/helpers.sh — Shared helpers for TitansWarPro battle scripts
# =============================================================================

# ── _log_battle_event ─────────────────────────────────────────────────────────
# Writes one JSON line to game_events.jsonl
# Usage:
#   _log_battle_event <mode> <result> <dur> <la> <hper> <atks> <heals> <kills> [extra_json_fields]
#
# The optional 9th argument is a raw JSON fragment appended inside the object:
#   e.g. '"immortal_king_killed":true,"killer":"PlayerX"'
#   e.g. '"rank_before":150,"rank_after":142,"rank_change":8'
# =============================================================================

_log_battle_event() {
    local mode="${1:-}"   result="${2:-}"  dur="${3:-0}"
    local la="${4:-0}"    hper="${5:-0}"   atks="${6:-0}"
    local heals="${7:-0}" kills="${8:-0}"  extra="${9:-}"

    local log_dir
    log_dir="${ACCOUNT_LOGS:-${TWM_DIR:-$(dirname "$(dirname "${BASH_SOURCE[0]}")")}/data/logs}"
    mkdir -p "$log_dir"

    local ts
    printf -v ts '%(%Y-%m-%dT%H:%M:%SZ)T' -1

    # Build JSON
    local json
    json="{\"ts\":\"$ts\",\"mode\":\"$mode\",\"result\":\"$result\",\"dur\":$dur,\"la\":\"$la\",\"hper\":$hper,\"atks\":$atks,\"heals\":$heals,\"kills\":$kills"
    [ -n "$extra" ] && json+=",$extra"
    json+="}"

    echo "$json" >> "$log_dir/game_events.jsonl"
}

# ── _parse_battle_state ───────────────────────────────────────────────────────
# Parses battle state from a w3m-dumped HTML source file.
# Extracts: USH ENH USER ATK ATKRND DODGE HEAL STONE GRASS RPER
_parse_battle_state() {
    local src="$1"
    USH=$(  grep -m1 -oP 'userhp=\K[0-9]+'         "$src" 2>/dev/null || echo "")
    ENH=$(  grep -m1 -oP 'enh=\K[0-9]+'            "$src" 2>/dev/null || echo "")
    USER=$( grep -m1 -oP 'user=\K[^&"]+(?=&|")'    "$src" 2>/dev/null || echo "")
    ATK=$(  grep -m1 -oP '/[a-z]+/atk\?[^"\s]+'    "$src" 2>/dev/null || echo "")
    ATKRND=$(grep -m1 -oP '/[a-z]+/atkrnd\?[^"\s]+' "$src" 2>/dev/null || echo "")
    DODGE=$(grep -m1 -oP '/[a-z]+/dodge\?[^"\s]+'  "$src" 2>/dev/null || echo "")
    HEAL=$( grep -m1 -oP '/[a-z]+/heal\?[^"\s]+'   "$src" 2>/dev/null || echo "")
    STONE=$(grep -m1 -oP '/[a-z]+/stone\?[^"\s]+'  "$src" 2>/dev/null || echo "")
    GRASS=$(grep -m1 -oP '/[a-z]+/grass\?[^"\s]+'  "$src" 2>/dev/null || echo "")
}

# ── _fetch ────────────────────────────────────────────────────────────────────
# Fetches a URL and saves raw HTML to a file.
# Usage: _fetch <path> [output_file] [timeout_sec]
_fetch() {
    local path="$1" out="${2:-/tmp/twm_fetch.html}" timeout="${3:-17}"
    local full_url="${URL}${path}"
    w3mc -cookie \
        -o http_proxy="$PROXY" \
        -o accept_encoding=UTF-8 \
        -debug -dump_source "$full_url" \
        -o user_agent="$(shuf -n1 "$TMP/userAgent.txt" 2>/dev/null || echo 'Mozilla/5.0')" \
        > "$out" 2>/dev/null &
    local pid=$!
    sleep "${timeout}s"
    kill "$pid" 2>/dev/null
    wait "$pid" 2>/dev/null
}

# ── _ram_dir ──────────────────────────────────────────────────────────────────
# Returns a fast temp dir (RAM-backed when available).
_ram_dir() {
    if [ -d /dev/shm ]; then echo "/dev/shm/twm"
    elif [ -d /tmp ]; then   echo "/tmp/twm"
    else                     echo "$TMP"
    fi
}

# ── _cfg_get ──────────────────────────────────────────────────────────────────
# Gets a value from strategy_config.json
# Usage: _cfg_get <mode> <key> [default]
_cfg_get() {
    local mode="$1" key="$2" default="${3:-}"
    local cfg_file="${TWM_DIR:-$(dirname "$(dirname "${BASH_SOURCE[0]}")")}/data/strategy_config.json"
    if [ -f "$cfg_file" ] && command -v python3 &>/dev/null; then
        python3 -c "
import json, sys
try:
    d = json.load(open('$cfg_file'))
    print(d.get('$mode', {}).get('$key', '$default'))
except Exception:
    print('$default')
" 2>/dev/null
    else
        echo "$default"
    fi
}

# ── echo_t ────────────────────────────────────────────────────────────────────
echo_t() {
    local msg="$1" color="${2:-}" reset="${3:-}" pos="${4:-before}" icon="${5:-}"
    if [ "$pos" = "after" ]; then
        printf '%b%s%b %s\n' "$color" "$msg" "$reset" "$icon"
    else
        printf '%s %b%s%b\n' "$icon" "$color" "$msg" "$reset"
    fi
}

# ── func_unset ────────────────────────────────────────────────────────────────
func_unset() {
    unset -f cl_access 2>/dev/null || true
}
