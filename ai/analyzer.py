#!/usr/bin/env python3
"""
analyzer.py — Reads game_events.jsonl and computes per-mode battle metrics.

Per-mode extra fields captured:
  coliseum   : kills, deaths, rank_change, opponent
  king       : immortal_king_killed, killer, damage_dealt
  arena      : rank_before, rank_after, rank_change
  cave       : floor_reached, boss_killed
  league     : score_gained, opponent_power
  clanfight  : personal_damage, clan_damage
  flagfight  : flags_captured, flags_lost
  undying    : waves_survived, final_wave

Performance rating per event:
  good / bad / ok  — written back to event and used by orchestrator
"""

import json
from pathlib import Path
from collections import defaultdict
from typing import Any

LOGS_PATH = Path(__file__).parent.parent / "data" / "logs" / "game_events.jsonl"


# ── Load ──────────────────────────────────────────────────────────────────────
def load_events(last_n: int = 500) -> list[dict]:
    if not LOGS_PATH.exists():
        return []
    lines = LOGS_PATH.read_text().strip().splitlines()
    events: list[dict] = []
    for line in lines[-last_n:]:
        try:
            events.append(json.loads(line))
        except json.JSONDecodeError:
            pass
    return events


# ── Performance rating ────────────────────────────────────────────────────────
def rate_performance(event: dict) -> str:
    """
    Returns 'good', 'bad', or 'ok' based on mode-specific thresholds.
    Falls back to result field when no specific logic applies.
    """
    mode   = event.get("mode", "")
    result = event.get("result", "")

    # King — primary KPI: did we kill or participate in killing the immortal king?
    if mode == "king":
        if event.get("immortal_king_killed"):
            return "good"
        if result == "win":
            return "good"
        if result == "loss":
            return "bad"
        return "ok"

    # Arena / Coliseum — win = good, loss = bad
    if mode in ("arena", "coliseum"):
        if result == "win":
            return "good"
        if result == "loss":
            # bonus: check if rank improved despite loss (coliseum specific)
            rc = event.get("rank_change", 0)
            try:
                if int(rc) > 0:
                    return "ok"
            except (ValueError, TypeError):
                pass
            return "bad"
        return "ok"

    # Cave — floor progress
    if mode == "cave":
        floor = event.get("floor_reached", 0)
        try:
            floor = int(floor)
        except (ValueError, TypeError):
            floor = 0
        if event.get("boss_killed"):
            return "good"
        if floor >= 5:
            return "good"
        if floor >= 3:
            return "ok"
        return "bad"

    # League — score gained
    if mode == "league":
        try:
            sg = float(event.get("score_gained", 0))
        except (ValueError, TypeError):
            sg = 0.0
        if sg > 0:
            return "good"
        if sg == 0:
            return "ok"
        return "bad"

    # Flagfight — flag capture ratio
    if mode == "flagfight":
        try:
            captured = int(event.get("flags_captured", 0))
            lost     = int(event.get("flags_lost",     0))
        except (ValueError, TypeError):
            captured, lost = 0, 0
        if captured > lost:
            return "good"
        if captured == lost:
            return "ok"
        return "bad"

    # Undying — waves survived
    if mode == "undying":
        try:
            waves = int(event.get("waves_survived", 0))
        except (ValueError, TypeError):
            waves = 0
        if waves >= 10:
            return "good"
        if waves >= 5:
            return "ok"
        return "bad"

    # Clanfight / clancoliseum — personal damage
    if mode in ("clanfight", "clancoliseum"):
        try:
            dmg = float(event.get("personal_damage", 0))
        except (ValueError, TypeError):
            dmg = 0.0
        if dmg > 0:
            return "good"
        return "ok"

    # Generic fallback
    if result == "win":
        return "good"
    if result == "loss":
        return "bad"
    return "ok"


# ── Compute metrics ───────────────────────────────────────────────────────────
def compute_metrics(events: list[dict], window: int = 30) -> dict[str, Any]:
    by_mode: dict[str, list] = defaultdict(list)
    for e in events:
        by_mode[e.get("mode", "unknown")].append(e)

    metrics: dict[str, Any] = {}
    for mode, evts in by_mode.items():
        recent = evts[-window:]
        total  = len(recent)
        if total == 0:
            continue

        wins   = sum(1 for e in recent if e.get("result") == "win")
        losses = sum(1 for e in recent if e.get("result") == "loss")
        winrate   = round(wins / total * 100, 1)
        avg_dur   = round(sum(e.get("dur", 0) for e in recent) / total, 1)
        avg_heals = round(sum(e.get("heals", 0) for e in recent) / total, 2)
        avg_la    = _safe_avg([float(e["la"])   for e in recent if e.get("la")])
        avg_hper  = _safe_avg([float(e["hper"])  for e in recent if e.get("hper")])

        good_count = sum(1 for e in recent if rate_performance(e) == "good")
        bad_count  = sum(1 for e in recent if rate_performance(e) == "bad")

        base = {
            "total"              : total,
            "wins"               : wins,
            "losses"             : losses,
            "winrate_pct"        : winrate,
            "avg_duration_sec"   : avg_dur,
            "avg_heals_per_battle": avg_heals,
            "avg_la"             : round(avg_la, 2),
            "avg_hper"           : round(avg_hper, 1),
            "good_count"         : good_count,
            "bad_count"          : bad_count,
            "performance_score"  : round(good_count / total * 100, 1),
        }

        # ── Mode-specific extras ──────────────────────────────────
        if mode == "king":
            kills = [e for e in recent if e.get("immortal_king_killed")]
            killers = [e.get("killer", "") for e in kills if e.get("killer")]
            base["immortal_king_kills"]  = len(kills)
            base["king_killers"]         = list(set(killers))
            base["avg_damage_dealt"]     = round(
                _safe_avg([float(e.get("damage_dealt", 0)) for e in recent if e.get("damage_dealt")]), 1
            )

        elif mode == "arena":
            rank_changes = [int(e.get("rank_change", 0)) for e in recent if e.get("rank_change") is not None]
            base["avg_rank_change"]      = round(_safe_avg([float(r) for r in rank_changes]), 1)
            base["rank_improvements"]    = sum(1 for r in rank_changes if r > 0)
            base["rank_drops"]           = sum(1 for r in rank_changes if r < 0)

        elif mode == "cave":
            floors = [int(e.get("floor_reached", 0)) for e in recent if e.get("floor_reached")]
            base["avg_floor_reached"]    = round(_safe_avg([float(f) for f in floors]), 1)
            base["boss_kills"]           = sum(1 for e in recent if e.get("boss_killed"))

        elif mode == "league":
            scores = [float(e.get("score_gained", 0)) for e in recent if e.get("score_gained") is not None]
            base["avg_score_gained"]     = round(_safe_avg(scores), 1)

        elif mode == "flagfight":
            base["avg_flags_captured"]   = round(
                _safe_avg([float(e.get("flags_captured", 0)) for e in recent]), 1
            )
            base["avg_flags_lost"]       = round(
                _safe_avg([float(e.get("flags_lost", 0)) for e in recent]), 1
            )

        elif mode == "undying":
            base["avg_waves_survived"]   = round(
                _safe_avg([float(e.get("waves_survived", 0)) for e in recent]), 1
            )

        elif mode in ("clanfight", "clancoliseum"):
            base["avg_personal_damage"]  = round(
                _safe_avg([float(e.get("personal_damage", 0)) for e in recent]), 1
            )

        metrics[mode] = base

    return metrics


# ── Summary string ────────────────────────────────────────────────────────────
def build_summary(metrics: dict, current_config: dict) -> str:
    lines = ["=== Battle Performance Summary ==="]
    for mode, m in metrics.items():
        cfg = current_config.get(mode, {})
        line = (
            f"[{mode}] winrate={m['winrate_pct']}% ({m['wins']}W/{m['losses']}L/{m['total']} total) "
            f"perf={m['performance_score']}% ({m['good_count']}good/{m['bad_count']}bad) "
            f"avg_dur={m['avg_duration_sec']}s avg_heals={m['avg_heals_per_battle']} "
            f"avg_la={m['avg_la']}s (cfg la_start={cfg.get('la_start','?')}) "
            f"avg_hper={m['avg_hper']}% (cfg hper={cfg.get('hper','?')})"
        )
        # mode-specific extras in summary
        if mode == "king" and m.get("king_killers"):
            line += f" king_killers={m['king_killers']}"
        if mode == "arena":
            line += f" avg_rank_change={m.get('avg_rank_change', 0)}"
        if mode == "cave":
            line += f" avg_floor={m.get('avg_floor_reached', 0)} boss_kills={m.get('boss_kills', 0)}"
        lines.append(line)
    return "\n".join(lines)


# ── Helpers ───────────────────────────────────────────────────────────────────
def _safe_avg(values: list[float]) -> float:
    return sum(values) / len(values) if values else 0.0


if __name__ == "__main__":
    evts = load_events()
    mets = compute_metrics(evts)
    print(build_summary(mets, {}))
    print(f"\nTotal events loaded: {len(evts)}")
    for e in evts[-5:]:
        perf = rate_performance(e)
        print(f"  {e.get('ts','')} [{e.get('mode','')}] result={e.get('result','')} → {perf}")
