#!/usr/bin/env python3
"""
gemini_client.py — Gemini API wrapper with rate limiter.
Protects Gemini free tier: max 1 call per 15 min, max 90 calls/day.
"""

import os
import json
import time
import logging
from datetime import date
from pathlib import Path

logger = logging.getLogger("twm.gemini")

STATE_FILE = Path(__file__).parent.parent / "data" / "metrics" / "gemini_state.json"
STATE_FILE.parent.mkdir(parents=True, exist_ok=True)

MIN_INTERVAL_SEC = 900   # 15 min between calls
MAX_CALLS_DAY    = 90    # safety margin under free tier daily limit
MODEL            = "gemini-2.0-flash"  # lightweight, free tier friendly


class RateLimitError(Exception):
    pass


class GeminiClient:
    def __init__(self, api_key: str | None = None):
        self.api_key = api_key or os.environ.get("GEMINI_API_KEY", "")
        if not self.api_key:
            raise ValueError("GEMINI_API_KEY not set")
        self._state = self._load_state()

    # ── State persistence ──────────────────────────────────────────────────
    def _load_state(self) -> dict:
        if STATE_FILE.exists():
            try:
                return json.loads(STATE_FILE.read_text())
            except Exception:
                pass
        return {"last_call_ts": 0, "calls_today": 0, "last_date": ""}

    def _save_state(self):
        STATE_FILE.write_text(json.dumps(self._state, indent=2))

    def _reset_daily_if_needed(self):
        today = str(date.today())
        if self._state.get("last_date") != today:
            self._state["calls_today"] = 0
            self._state["last_date"] = today

    # ── Rate limit check ───────────────────────────────────────────────────
    def can_call(self) -> tuple[bool, str]:
        self._reset_daily_if_needed()
        elapsed = time.time() - self._state["last_call_ts"]
        if elapsed < MIN_INTERVAL_SEC:
            wait = int(MIN_INTERVAL_SEC - elapsed)
            return False, f"Rate limit: wait {wait}s more"
        if self._state["calls_today"] >= MAX_CALLS_DAY:
            return False, f"Daily limit reached ({MAX_CALLS_DAY} calls)"
        return True, "ok"

    # ── Main call ──────────────────────────────────────────────────────────
    def call(self, prompt: str) -> str:
        ok, reason = self.can_call()
        if not ok:
            raise RateLimitError(reason)

        try:
            import google.generativeai as genai
            genai.configure(api_key=self.api_key)
            model = genai.GenerativeModel(MODEL)
            response = model.generate_content(prompt)
            text = response.text.strip()
        except Exception as e:
            logger.error("Gemini call failed: %s", e)
            raise

        self._state["last_call_ts"] = time.time()
        self._state["calls_today"] = self._state.get("calls_today", 0) + 1
        self._save_state()
        logger.info("Gemini call #%d today OK", self._state["calls_today"])
        return text

    def status(self) -> dict:
        self._reset_daily_if_needed()
        elapsed = time.time() - self._state["last_call_ts"]
        return {
            "calls_today": self._state.get("calls_today", 0),
            "max_calls_day": MAX_CALLS_DAY,
            "seconds_since_last_call": int(elapsed),
            "min_interval_sec": MIN_INTERVAL_SEC,
            "ready": elapsed >= MIN_INTERVAL_SEC and self._state.get("calls_today", 0) < MAX_CALLS_DAY,
        }
