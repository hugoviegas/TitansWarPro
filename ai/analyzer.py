#!/usr/bin/env python3
"""
analyzer.py — Reads game_events.jsonl and computes battle performance metrics.
"""

import json
from pathlib import Path
from collections import defaultdict
from typing import Any

LOGS_PATH = Path(__file__).parent.parent / "data" / "logs" / "game_events.jsonl"


def load_events(last_n: int = 500) -> list[dict]:
    if not LOGS_PATH.exists():
        return []
    lines = LOGS_PATH.read_text().strip().splitlines()
    events = []
    for line in lines[-last_n:]:
        try:
            events.append(json.loads(line))
        except json.JSONDecodeError:
            pass
    return events


def compute_metrics(events: list[dict], window: int = 30) -> dict[str, Any]:
    by_mode: dict[str, list] = defaultdict(list)
    for e in events:
        by_mode[e.get("mode", "unknown")].append(e)

    metrics: dict[str, Any] = {}
    for mode, evts in by_mode.items():
        recent = evts[-window:]
        total = len(recent)
        if total == 0:
            continue
        wins = sum(1 for e in recent if e.get("result") == "win")
        losses = sum(1 for e in recent if e.get("result") == "loss")
        winrate = round(wins / total * 100, 1)
        avg_dur = round(sum(e.get("dur", 0) for e in recent) / total, 1)
        avg_heals = round(sum(e.get("heals", 0) for e in recent) / total, 2)
        avg_la = _safe_avg([float(e["la"]) for e in recent if e.get("la")])
        avg_hper = _safe_avg([float(e["hper"]) for e in recent if e.get("hper")])

        metrics[mode] = {
            "total": total,
            "wins": wins,
            "losses": losses,
            "winrate_pct": winrate,
            "avg_duration_sec": avg_dur,
            "avg_heals_per_battle": avg_heals,
            "avg_la": round(avg_la, 2),
            "avg_hper": round(avg_hper, 1),
        }
    return metrics


def build_summary(metrics: dict, current_config: dict) -> str:
    lines = ["=== Battle Performance Summary ==="]
    for mode, m in metrics.items():
        cfg = current_config.get(mode, {})
        lines.append(
            f"[{mode}] winrate={m['winrate_pct']}% ({m['wins']}W/{m['losses']}L/{m['total']} total) "
            f"avg_dur={m['avg_duration_sec']}s avg_heals={m['avg_heals_per_battle']} "
            f"avg_la={m['avg_la']}s (cfg la_start={cfg.get('la_start','?')}) "
            f"avg_hper={m['avg_hper']}% (cfg hper={cfg.get('hper','?')})"
        )
    return "\n".join(lines)


def _safe_avg(values: list[float]) -> float:
    return sum(values) / len(values) if values else 0.0
