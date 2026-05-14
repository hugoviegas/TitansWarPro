# TitansWarPro — AI Engine (`ai-engine` branch)

## Overview

This branch adds a self-improving AI layer on top of the existing macro.
- **Battle scripts** (Bash) continue to run the 24/7 loop unchanged.
- **AI Orchestrator** (Python) runs alongside, learns from battle logs, and periodically updates `strategy_config.json` via Gemini.
- **Only battle modes** are tuned by AI: `coliseum`, `king`, `clancoliseum`, `altars`, `clanfight`, `clandmg`, `flagfight`, `undying`.
- **Routines, activities, and configuration scripts are never modified by AI.**

---

## Architecture

```
Bash macro (24/7 loop)
  └─ battle scripts read  data/configs/strategy_config.json
  └─ write battle events  data/logs/game_events.jsonl

Python AI engine (background)
  ├─ ai/orchestrator.py   ← main loop (runs every 60s)
  ├─ ai/analyzer.py       ← computes winrate, avg LA, avg HPER per mode
  ├─ ai/gemini_client.py  ← Gemini calls (max 1/15min, 90/day)
  └─ ai/patcher.py        ← backup → apply → test → promote/rollback
```

---

## Setup

```bash
# 1. Install Python dependencies
pip install -r ai/requirements.txt

# 2. Set your Gemini API key
export GEMINI_API_KEY="your_key_here"

# 3. Start the AI orchestrator in background
cd ai && python orchestrator.py &

# 4. Run the macro as normal
./run.sh
```

---

## Config scopes

| Category | AI can modify | Description |
|---|---|---|
| Batalhas | ✅ YES | coliseum, king, clancoliseum, altars, clanfight, clandmg, flagfight, undying |
| Atividades | ❌ NO | arena, cave, campaign, career, missions, trade |
| Rotinas | ❌ NO | run, crono, multi_runner, twm_control, loginlogoff |
| Configuração | ❌ NO | function, twm_setup, requeriments, update |

---

## Safety system

- Every config change is backed up to `data/backups/strategy_TIMESTAMP.json`.
- New config runs in **TESTING** state for 30 battles.
- If any mode's winrate drops >10%, **automatic rollback** to backup.
- All experiments logged in `data/metrics/experiment_log.jsonl`.
- Gemini history is passed back so the AI learns from past failed experiments.

---

## Branches

| Branch | Purpose |
|---|---|
| `master` | stable production |
| `beta` | beta features |
| `beta2` | current dev base |
| `ai-engine` | AI self-improvement (this branch) |
