#!/usr/bin/env python3
"""
gemini_client.py — Gemini API client via REST (no google-generativeai SDK).
Exposes GeminiClient + RateLimitError for compatibility with orchestrator.py.
Works on Termux, Ubuntu, Cygwin — only requires `requests`.

Default model: gemini-3.1-flash-lite-preview
  - Free tier: 15 RPM, 250K TPM, 500 RPD
  - Override via GEMINI_MODEL env var or model= param
"""
import logging
import os
import time
from typing import Optional, Tuple

import requests

logger = logging.getLogger("twm.gemini")

GEMINI_API_BASE     = "https://generativelanguage.googleapis.com/v1beta"
DEFAULT_MODEL       = os.environ.get("GEMINI_MODEL", "gemini-3.1-flash-lite-preview")
REQUESTS_PER_MINUTE = 15
_INTERVAL_SEC       = 60.0 / REQUESTS_PER_MINUTE   # ~4s between calls


class RateLimitError(Exception):
    pass


class GeminiClient:
    """
    REST-only Gemini client.
    Interface compatible with orchestrator.py:
      - client.can_call()   → (bool, reason_str)
      - client.call(prompt) → str
      - client.test_connection() → bool
    """

    def __init__(
        self,
        api_key: Optional[str] = None,
        model: str = DEFAULT_MODEL,
    ):
        self.api_key       = api_key or os.environ.get("GEMINI_API_KEY", "")
        self.model         = model
        self._last_call    = 0.0
        self._call_count   = 0
        self._window_start = time.time()

    # ── Rate limit check ──────────────────────────────────────────────────────
    def can_call(self) -> Tuple[bool, str]:
        if not self.api_key:
            return False, "GEMINI_API_KEY not set"

        now = time.time()
        if now - self._window_start >= 60.0:
            self._call_count   = 0
            self._window_start = now

        if self._call_count >= REQUESTS_PER_MINUTE:
            wait = 60.0 - (now - self._window_start)
            return False, f"rate limit: wait {wait:.0f}s"

        elapsed = now - self._last_call
        if elapsed < _INTERVAL_SEC:
            return False, f"too soon: wait {_INTERVAL_SEC - elapsed:.1f}s"

        return True, ""

    # ── Main call ─────────────────────────────────────────────────────────────
    def call(
        self,
        prompt: str,
        temperature: float = 0.3,
        max_tokens: int = 1024,
        retries: int = 3,
    ) -> str:
        if not self.api_key:
            raise ValueError("GEMINI_API_KEY not set")

        url = (
            f"{GEMINI_API_BASE}/models/{self.model}"
            f":generateContent?key={self.api_key}"
        )
        payload = {
            "contents": [{"parts": [{"text": prompt}]}],
            "generationConfig": {
                "temperature": temperature,
                "maxOutputTokens": max_tokens,
            },
        }
        headers = {"Content-Type": "application/json"}

        for attempt in range(1, retries + 1):
            try:
                resp = requests.post(url, headers=headers, json=payload, timeout=30)

                if resp.status_code == 200:
                    self._last_call   = time.time()
                    self._call_count += 1
                    data = resp.json()
                    return (
                        data.get("candidates", [{}])[0]
                        .get("content", {})
                        .get("parts", [{}])[0]
                        .get("text", "")
                        .strip()
                    )

                if resp.status_code == 429:
                    raise RateLimitError(f"HTTP 429: {resp.text[:200]}")

                if resp.status_code in (500, 503):
                    logger.warning("Gemini server error %d (attempt %d/%d)", resp.status_code, attempt, retries)
                    time.sleep(5 * attempt)
                    continue

                raise Exception(f"Gemini HTTP {resp.status_code}: {resp.text[:300]}")

            except RateLimitError:
                raise
            except requests.exceptions.Timeout:
                logger.warning("Timeout attempt %d/%d", attempt, retries)
                time.sleep(5 * attempt)
            except requests.exceptions.ConnectionError:
                logger.warning("Connection error attempt %d/%d", attempt, retries)
                time.sleep(10)

        raise Exception(f"Gemini: all {retries} attempts failed")

    # ── generate() alias ──────────────────────────────────────────────────────
    def generate(
        self,
        prompt: str,
        temperature: float = 0.3,
        max_tokens: int = 1024,
    ) -> Optional[str]:
        try:
            return self.call(prompt, temperature=temperature, max_tokens=max_tokens)
        except Exception as exc:
            logger.error("generate() failed: %s", exc)
            return None

    # ── Connectivity test ─────────────────────────────────────────────────────
    def test_connection(self) -> bool:
        if not self.api_key:
            return False
        try:
            url = f"{GEMINI_API_BASE}/models?key={self.api_key}"
            resp = requests.get(url, timeout=10)
            return resp.status_code == 200
        except Exception:
            return False


# ── Module-level convenience ──────────────────────────────────────────────────
def generate(
    prompt: str,
    api_key: Optional[str] = None,
    model: str = DEFAULT_MODEL,
    temperature: float = 0.3,
    max_tokens: int = 1024,
) -> Optional[str]:
    return GeminiClient(api_key=api_key, model=model).generate(
        prompt, temperature=temperature, max_tokens=max_tokens
    )


def test_connection(api_key: Optional[str] = None) -> bool:
    return GeminiClient(api_key=api_key).test_connection()


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    c = GeminiClient()
    print(f"[gemini] Model : {c.model}")
    if c.test_connection():
        print("[gemini] Connection OK")
        ok, reason = c.can_call()
        if ok:
            result = c.call("Reply with one word: hello")
            print(f"[gemini] Response: {result}")
        else:
            print(f"[gemini] Cannot call yet: {reason}")
    else:
        print("[gemini] Connection FAILED — check GEMINI_API_KEY in .env")
