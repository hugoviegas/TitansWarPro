# TitansWarPro

Automation macro for the browser game **Titans War**, with an optional **AI Engine** branch for self-improving battle strategies via Gemini.

---

## Branches

| Branch | Purpose |
|---|---|
| `master` | Stable production |
| `beta` | Beta features |
| `beta2` | Current development base |
| `ai-engine` | AI self-improvement (this guide covers both) |

---

## Quick Install (beta2 / master / beta)

```bash
curl -s https://raw.githubusercontent.com/hugoviegas/TitansWarPro/beta2/update.sh | bash
```

Or manually:

```bash
mkdir -p ~/twm && cd ~/twm
curl -sL https://raw.githubusercontent.com/hugoviegas/TitansWarPro/beta2/update.sh -o update.sh
chmod +x update.sh && ./update.sh
```

Select option `3` for Beta2.

---

## AI Engine Branch — Setup

The `ai-engine` branch adds a Python orchestrator that learns from your battle data and periodically improves battle parameters via the **Gemini API (free tier)**.

### Prerequisites

| Requirement | Version | Install |
|---|---|---|
| Bash | 4.0+ | Built-in (Linux/Cygwin/Termux) |
| Python | 3.9+ | `pkg install python` / `apt install python3` |
| pip | latest | `python3 -m ensurepip` |
| jq | any | `pkg install jq` / `apt install jq` |
| curl | any | `pkg install curl` |
| w3m | any | `pkg install w3m` |

### Step 1 — Install from AI Engine branch

```bash
curl -sL https://raw.githubusercontent.com/hugoviegas/TitansWarPro/beta2/update.sh | bash
# Select option 5 — AI Engine
```

Or if already on beta2:

```bash
cd ~/twm && ./update.sh
# Select 5
```

### Step 2 — Install Python dependencies

```bash
cd ~/twm
pip install -r ai/requirements.txt
```

Dependency installed: `google-generativeai >= 0.5.0`

### Step 3 — Set your Gemini API Key

Get a free key at [Google AI Studio](https://aistudio.google.com/app/apikey).

Create a `.env` file in `~/twm/`:

```bash
echo 'GEMINI_API_KEY=your_key_here' > ~/twm/.env
chmod 600 ~/twm/.env
```

> `.env` is in `.gitignore` and will never be committed.

### Step 4 — Run with AI Engine

```bash
cd ~/twm
bash run_ai.sh
```

This starts both the macro and the AI orchestrator together. The orchestrator runs in the background, monitors battle logs, and calls Gemini periodically to improve `data/configs/strategy_config.json`.

To run the macro only (no AI):

```bash
bash run.sh
```

---

## AI Engine — How it works

```
Bash macro (24/7)
  └─ reads   data/configs/strategy_config.json   (LA, HPER, RPER per mode)
  └─ writes  data/logs/game_events.jsonl          (one JSON line per battle)

Python AI Orchestrator (background)
  ├─ analyzer.py     computes winrate, avg LA, avg HPER per mode
  ├─ gemini_client.py  calls Gemini max 1x/15min, 90x/day (free tier safe)
  ├─ patcher.py      backup → apply → TESTING state → promote or rollback
  └─ orchestrator.py  main loop: collect → analyze → call → validate → patch
```

### Safety System

- Every config change backed up to `data/backups/strategy_TIMESTAMP.json`.
- New config tested for 30 battles before being promoted.
- If any mode's winrate drops >10%, **automatic rollback** to last backup.
- All experiments logged in `data/metrics/experiment_log.jsonl`.
- Gemini history passed back so the AI learns from failed experiments.

### Gemini Free Tier Limits

| Limit | Value | Our usage |
|---|---|---|
| Calls per minute | ~15 RPM | 1 call per 15 min max |
| Calls per day | ~1500 RPD | Max 90/day |
| Model | `gemini-2.0-flash` | Lightest free model |

---

## Switching branches

To **return to beta2** from AI Engine (safe rollback):

```bash
cd ~/twm && ./update.sh
# Select 3 — Beta2
```

This automatically removes AI Engine files and stops the orchestrator process.

To **upgrade back to AI Engine** from beta2:

```bash
cd ~/twm && ./update.sh
# Select 5 — AI Engine
```

---

## Battle modes controlled by AI

| Mode | AI tunable params |
|---|---|
| coliseum | la_start, hper, rper, priority |
| king | la_start, hper, rper |
| clancoliseum | la_start, hper, rper |
| altars | la_start, hper, rper |
| clanfight | la_start, hper, rper, use_stone, use_grass |
| clandmg | la_start, hper, rper, use_stone, use_grass |
| flagfight | la_start, hper, rper |
| undying | la_start, hper, rper, grass_hp_threshold |

> Routines, activities (arena, cave, career, missions, trade) and config scripts are **never modified** by AI.

---

## File structure (ai-engine)

```
~/twm/
├── run_ai.sh                   ← start macro + AI together
├── run.sh                      ← start macro only (no AI)
├── core/
│   └── helpers.sh               ← shared fetch, parser, logger
├── ai/
│   ├── orchestrator.py          ← main AI loop
│   ├── analyzer.py              ← metrics calculator
│   ├── gemini_client.py         ← rate-limited Gemini wrapper
│   ├── patcher.py               ← backup/apply/rollback
│   └── requirements.txt
├── data/
│   ├── configs/
│   │   └── strategy_config.json  ← AI writes here only
│   ├── logs/
│   │   ├── game_events.jsonl     ← battle log (not committed)
│   │   └── orchestrator.log      ← AI process log
│   ├── backups/                 ← auto backups (not committed)
│   └── metrics/
│       └── experiment_log.jsonl  ← learning history
├── .env                        ← GEMINI_API_KEY (not committed)
└── AI_ENGINE.md                ← full architecture docs
```

---

## License

MIT — see [LICENSE](LICENSE)
