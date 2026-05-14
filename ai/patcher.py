#!/usr/bin/env python3
"""
patcher.py — Applies, validates, backs up, and rolls back strategy_config.json.
States: STABLE → TESTING → STABLE (if ok) or ROLLBACK (if worse)
"""

import json
import shutil
import logging
from datetime import datetime, timezone
from pathlib import Path

logger = logging.getLogger("twm.patcher")

CFG_PATH     = Path(__file__).parent.parent / "data" / "configs" / "strategy_config.json"
BACKUPS_DIR  = Path(__file__).parent.parent / "data" / "backups"
EXP_LOG      = Path(__file__).parent.parent / "data" / "metrics" / "experiment_log.jsonl"
STATE_FILE   = Path(__file__).parent.parent / "data" / "metrics" / "patcher_state.json"

BACKUPS_DIR.mkdir(parents=True, exist_ok=True)
EXP_LOG.parent.mkdir(parents=True, exist_ok=True)

ALLOWED_KEYS = {
    "la_start", "la_min", "la_max", "hper", "rper",
    "heal_cooldown", "dodge_cooldown",
    "use_stone", "use_grass", "grass_hp_threshold", "priority"
}
LA_RANGE   = (2.0, 10.0)
HPER_RANGE = (10, 80)
RPER_RANGE = (0, 50)


class PatcherError(Exception):
    pass


def load_config() -> dict:
    return json.loads(CFG_PATH.read_text())


def save_config(cfg: dict):
    CFG_PATH.write_text(json.dumps(cfg, indent=2))


def backup_config(label: str = "") -> Path:
    ts = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    name = f"strategy_{ts}{'_' + label if label else ''}.json"
    dest = BACKUPS_DIR / name
    shutil.copy2(CFG_PATH, dest)
    logger.info("Backup saved: %s", dest)
    return dest


def validate_patch(current: dict, patch: dict) -> dict:
    """Validate patch: no new keys, values within safe ranges, gradual changes."""
    errors = []
    for mode, values in patch.items():
        if mode.startswith("_"):
            continue
        if mode not in current:
            errors.append(f"Unknown mode: {mode}")
            continue
        for key, val in values.items():
            if key not in ALLOWED_KEYS:
                errors.append(f"{mode}.{key}: key not allowed")
                continue
            orig = current[mode].get(key)
            if orig is None:
                errors.append(f"{mode}.{key}: key not in current config")
                continue
            # Numeric range checks
            if key in ("la_start", "la_min", "la_max") and isinstance(val, (int, float)):
                if not (LA_RANGE[0] <= val <= LA_RANGE[1]):
                    errors.append(f"{mode}.{key}={val} out of range {LA_RANGE}")
            if key == "hper" and isinstance(val, (int, float)):
                if not (HPER_RANGE[0] <= val <= HPER_RANGE[1]):
                    errors.append(f"{mode}.{key}={val} out of range {HPER_RANGE}")
            if key == "rper" and isinstance(val, (int, float)):
                if not (RPER_RANGE[0] <= val <= RPER_RANGE[1]):
                    errors.append(f"{mode}.{key}={val} out of range {RPER_RANGE}")
            # Gradual change: numeric values can't shift more than 20% per iteration
            if isinstance(orig, (int, float)) and isinstance(val, (int, float)) and orig != 0:
                delta_pct = abs(val - orig) / abs(orig) * 100
                if delta_pct > 20:
                    errors.append(f"{mode}.{key}: change {orig}→{val} is {delta_pct:.0f}% (max 20%)")
    if errors:
        raise PatcherError("Validation failed:\n" + "\n".join(errors))
    return patch


def apply_patch(patch: dict, experiment_id: str = "") -> Path:
    """Backup current config, apply patch, save, log experiment."""
    current = load_config()
    backup_path = backup_config(label=experiment_id or "pre_patch")

    # Deep merge: only update keys present in patch
    new_cfg = json.loads(json.dumps(current))  # deep copy
    for mode, values in patch.items():
        if mode.startswith("_"):
            continue
        if mode in new_cfg:
            new_cfg[mode].update(values)

    new_cfg["_last_updated"] = datetime.now(timezone.utc).isoformat()
    new_cfg["_updated_by"] = f"ai-engine:{experiment_id}"
    save_config(new_cfg)

    _save_patcher_state("TESTING", experiment_id, str(backup_path))
    logger.info("Patch applied. State: TESTING. Backup: %s", backup_path)
    return backup_path


def rollback(backup_path: str | None = None):
    """Restore last backup or specified backup file."""
    if backup_path is None:
        state = _load_patcher_state()
        backup_path = state.get("last_backup")
    if not backup_path or not Path(backup_path).exists():
        raise PatcherError(f"Backup not found: {backup_path}")
    shutil.copy2(backup_path, CFG_PATH)
    _save_patcher_state("ROLLBACK", "", backup_path)
    logger.warning("Rolled back to %s", backup_path)


def promote():
    """Mark current config as STABLE after successful test."""
    _save_patcher_state("STABLE", "", "")
    logger.info("Config promoted to STABLE")


def log_experiment(exp_id: str, old_metrics: dict, new_metrics: dict, outcome: str):
    entry = {
        "ts": datetime.now(timezone.utc).isoformat(),
        "experiment_id": exp_id,
        "outcome": outcome,
        "metrics_before": old_metrics,
        "metrics_after": new_metrics,
    }
    with EXP_LOG.open("a") as f:
        f.write(json.dumps(entry) + "\n")


def _load_patcher_state() -> dict:
    if STATE_FILE.exists():
        try:
            return json.loads(STATE_FILE.read_text())
        except Exception:
            pass
    return {"state": "STABLE", "experiment_id": "", "last_backup": ""}


def _save_patcher_state(state: str, exp_id: str, backup: str):
    STATE_FILE.write_text(json.dumps({
        "state": state,
        "experiment_id": exp_id,
        "last_backup": backup,
        "updated_at": datetime.now(timezone.utc).isoformat(),
    }, indent=2))
