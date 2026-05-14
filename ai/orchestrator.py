#!/usr/bin/env python3
"""
orchestrator.py — Main AI learning loop for TitansWarPro.
Runs 24/7 alongside the Bash macro.
Cycle: collect → analyze → call Gemini → validate → backup → test → promote/rollback
"""

import json
import logging
import time
import hashlib
from datetime import datetime, timezone
from pathlib import Path

from gemini_client import GeminiClient, RateLimitError
from analyzer import load_events, compute_metrics, build_summary
from patcher import (
    load_config, validate_patch, apply_patch,
    rollback, promote, log_experiment, _load_patcher_state
)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(name)s] %(levelname)s: %(message)s",
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler(
            Path(__file__).parent.parent / "data" / "logs" / "orchestrator.log"
        ),
    ],
)
logger = logging.getLogger("twm.orchestrator")

MIN_BATTLES_TO_ANALYZE = 10   # minimum new battles before calling Gemini
TEST_WINDOW             = 30   # battles to evaluate after applying a patch
WINRATE_DROP_THRESHOLD  = 10   # % drop in winrate triggers rollback
LOOP_INTERVAL_SEC       = 60   # check every 60s (Gemini call guarded by its own limit)


# ── Prompt builder ─────────────────────────────────────────────────────────────
PROMPT_TEMPLATE = """
You are a battle strategy optimizer for a browser-based RPG bot called Titans War.
Your task: analyze battle performance and suggest parameter adjustments.

STRICT RULES:
1. Respond ONLY with valid JSON — no markdown, no explanation, no extra text.
2. Only include modes that need changes (omit modes performing well).
3. Do NOT add new keys. Do NOT remove existing keys.
4. Changes must be gradual: max ±20%% per iteration on numeric values.
5. la_start must be between 2.0 and 10.0
6. hper must be between 10 and 80
7. rper must be between 0 and 50
8. priority must only use existing actions: ["stone","heal","grass","dodge","atkrnd","atk"]

Current strategy_config:
{current_config}

Recent performance (last {window} battles per mode):
{summary}

Experiment history (last 5):
{history}

Respond with a JSON object containing ONLY the modes that need parameter changes.
Example format: {{"coliseum": {{"hper": 42, "la_start": 4.2}}}}
"""


def build_prompt(current_config: dict, metrics: dict, history: list) -> str:
    recent_history = history[-5:] if history else []
    history_text = json.dumps(recent_history, indent=2) if recent_history else "(no history yet)"
    return PROMPT_TEMPLATE.format(
        current_config=json.dumps(current_config, indent=2),
        summary=build_summary(metrics, current_config),
        window=TEST_WINDOW,
        history=history_text,
    )


def load_experiment_history() -> list:
    exp_log = Path(__file__).parent.parent / "data" / "metrics" / "experiment_log.jsonl"
    if not exp_log.exists():
        return []
    entries = []
    for line in exp_log.read_text().strip().splitlines():
        try:
            entries.append(json.loads(line))
        except Exception:
            pass
    return entries


def experiment_id() -> str:
    ts = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S")
    return f"exp_{ts}"


# ── Main orchestrator loop ─────────────────────────────────────────────────────
def run():
    client = GeminiClient()
    last_event_count = 0

    logger.info("TitansWarPro AI Orchestrator started")

    while True:
        try:
            patcher_state = _load_patcher_state()

            # ── Phase: evaluate running test ───────────────────────────────
            if patcher_state["state"] == "TESTING":
                events = load_events(last_n=200)
                metrics_now = compute_metrics(events, window=TEST_WINDOW)
                history = load_experiment_history()

                exp_entry = next(
                    (h for h in reversed(history)
                     if h.get("experiment_id") == patcher_state["experiment_id"]),
                    None
                )
                if exp_entry:
                    old_metrics = exp_entry.get("metrics_before", {})
                    # Check if any mode dropped more than threshold
                    should_rollback = False
                    for mode, m in metrics_now.items():
                        old_wr = old_metrics.get(mode, {}).get("winrate_pct", 50)
                        new_wr = m.get("winrate_pct", 50)
                        if (old_wr - new_wr) > WINRATE_DROP_THRESHOLD:
                            logger.warning(
                                "Mode %s winrate dropped %.1f%% → %.1f%%, rolling back",
                                mode, old_wr, new_wr
                            )
                            should_rollback = True
                    if should_rollback:
                        rollback()
                        log_experiment(
                            patcher_state["experiment_id"],
                            old_metrics, metrics_now, "ROLLBACK"
                        )
                    else:
                        total_battles_since = sum(m["total"] for m in metrics_now.values())
                        if total_battles_since >= TEST_WINDOW:
                            promote()
                            log_experiment(
                                patcher_state["experiment_id"],
                                old_metrics, metrics_now, "PROMOTED"
                            )
                            logger.info("Experiment %s promoted to STABLE", patcher_state["experiment_id"])

            # ── Phase: gather data and improve ─────────────────────────────
            elif patcher_state["state"] in ("STABLE", "ROLLBACK"):
                events = load_events(last_n=500)
                current_count = len(events)

                new_battles = current_count - last_event_count
                if new_battles < MIN_BATTLES_TO_ANALYZE:
                    logger.debug("Only %d new battles, waiting for %d", new_battles, MIN_BATTLES_TO_ANALYZE)
                    time.sleep(LOOP_INTERVAL_SEC)
                    continue

                last_event_count = current_count
                metrics = compute_metrics(events, window=TEST_WINDOW)
                if not metrics:
                    time.sleep(LOOP_INTERVAL_SEC)
                    continue

                current_config = load_config()
                history = load_experiment_history()
                prompt = build_prompt(current_config, metrics, history)

                # ── Call Gemini ────────────────────────────────────────────
                ok, reason = client.can_call()
                if not ok:
                    logger.debug("Gemini not ready: %s", reason)
                    time.sleep(LOOP_INTERVAL_SEC)
                    continue

                logger.info("Calling Gemini for strategy improvement...")
                try:
                    raw_response = client.call(prompt)
                except RateLimitError as e:
                    logger.warning("Rate limit: %s", e)
                    time.sleep(LOOP_INTERVAL_SEC)
                    continue
                except Exception as e:
                    logger.error("Gemini error: %s", e)
                    time.sleep(LOOP_INTERVAL_SEC)
                    continue

                # ── Parse and validate Gemini response ─────────────────────
                try:
                    # Strip potential markdown code blocks
                    clean = raw_response.strip()
                    if clean.startswith("```"):
                        clean = "\n".join(clean.split("\n")[1:-1])
                    patch = json.loads(clean)
                    validate_patch(current_config, patch)
                except Exception as e:
                    logger.error("Invalid Gemini response: %s\nRaw: %s", e, raw_response[:500])
                    time.sleep(LOOP_INTERVAL_SEC)
                    continue

                # ── Apply patch ────────────────────────────────────────────
                exp_id = experiment_id()
                backup = apply_patch(patch, experiment_id=exp_id)
                log_experiment(exp_id, metrics, {}, "TESTING")
                logger.info("Patch applied. Experiment %s started. Backup: %s", exp_id, backup)

        except KeyboardInterrupt:
            logger.info("Orchestrator stopped by user.")
            break
        except Exception as e:
            logger.error("Unexpected error in orchestrator loop: %s", e, exc_info=True)

        time.sleep(LOOP_INTERVAL_SEC)


if __name__ == "__main__":
    run()
