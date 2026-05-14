#!/usr/bin/env python3
"""
gemini_client.py - Gemini API client via REST (no google-generativeai SDK).
Works on Termux, Ubuntu, Cygwin and any env with only `requests` installed.
"""
import json
import logging
import os
import time
from typing import Optional

import requests

logger = logging.getLogger("twm.gemini")

GEMINI_API_BASE = "https://generativelanguage.googleapis.com/v1beta"
DEFAULT_MODEL   = "gemini-2.0-flash"

# Free-tier conservative limits
REQUESTS_PER_MINUTE = 15
_last_call_time: float = 0.0


def _rate_limit():
    global _last_call_time
    wait = (60.0 / REQUESTS_PER_MINUTE) - (time.time() - _last_call_time)
    if wait > 0:
        time.sleep(wait)
    _last_call_time = time.time()


def generate(
    prompt: str,
    api_key: Optional[str] = None,
    model: str = DEFAULT_MODEL,
    temperature: float = 0.3,
    max_tokens: int = 1024,
    retries: int = 3,
) -> Optional[str]:
    """
    Send a prompt to Gemini and return the text response.
    Returns None on failure after retries.
    """
    key = api_key or os.environ.get("GEMINI_API_KEY", "")
    if not key:
        logger.error("GEMINI_API_KEY not set.")
        return None

    url = f"{GEMINI_API_BASE}/models/{model}:generateContent?key={key}"
    payload = {
        "contents": [{"parts": [{"text": prompt}]}],
        "generationConfig": {
            "temperature": temperature,
            "maxOutputTokens": max_tokens,
        },
    }
    headers = {"Content-Type": "application/json"}

    for attempt in range(1, retries + 1):
        _rate_limit()
        try:
            resp = requests.post(url, headers=headers, json=payload, timeout=30)
            if resp.status_code == 200:
                data = resp.json()
                return (
                    data.get("candidates", [{}])[0]
                    .get("content", {})
                    .get("parts", [{}])[0]
                    .get("text", "")
                    .strip()
                )
            elif resp.status_code == 429:
                wait = 30 * attempt
                logger.warning("Rate limited. Waiting %ds...", wait)
                time.sleep(wait)
            elif resp.status_code in (500, 503):
                logger.warning("Server error %d. Retrying...", resp.status_code)
                time.sleep(5 * attempt)
            else:
                logger.error("Gemini error %d: %s", resp.status_code, resp.text[:200])
                return None
        except requests.exceptions.Timeout:
            logger.warning("Request timeout (attempt %d/%d)", attempt, retries)
            time.sleep(5)
        except requests.exceptions.ConnectionError:
            logger.warning("Connection error (attempt %d/%d)", attempt, retries)
            time.sleep(10)
        except Exception as exc:
            logger.error("Unexpected error: %s", exc)
            return None

    logger.error("All %d attempts failed.", retries)
    return None


def test_connection(api_key: Optional[str] = None) -> bool:
    """Quick connectivity check. Returns True if API key is valid."""
    key = api_key or os.environ.get("GEMINI_API_KEY", "")
    if not key:
        return False
    try:
        url = f"{GEMINI_API_BASE}/models?key={key}"
        resp = requests.get(url, timeout=10)
        return resp.status_code == 200
    except Exception:
        return False


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    if test_connection():
        print("[gemini] Connection OK")
        result = generate("Reply with one word: hello")
        print(f"[gemini] Response: {result}")
    else:
        print("[gemini] Connection FAILED - check GEMINI_API_KEY")
