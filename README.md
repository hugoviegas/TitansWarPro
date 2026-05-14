# TitansWarPro — AI Engine Branch

> **Branch:** `ai-engine` — macro inteligente com IA auto-aprimorada (Gemini) para decisões de batalha.

---

## ⚡ Instalação rápida / Quick Install

### AI Engine (recomendado / recommended)

```bash
bash <(curl -s https://raw.githubusercontent.com/hugoviegas/TitansWarPro/ai-engine/easyinstall.sh) ai-engine
```

### Beta2 (macro clássico / classic macro)

```bash
bash <(curl -s https://raw.githubusercontent.com/hugoviegas/TitansWarPro/beta2/easyinstall.sh) beta2
```

---

## 🤖 AI Engine — Setup

Após a instalação, configure a chave do Gemini:

```bash
# 1. Editar o ficheiro .env
nano ~/twm/.env
# → GEMINI_API_KEY=a_tua_chave_aqui

# 2. Iniciar o AI Engine
bash ~/twm/run_ai.sh
# ou usar o atalho:
twmai
```

Obter uma chave gratuita: https://aistudio.google.com/app/apikey

---

## 🗂️ Estrutura da branch ai-engine

```
~/twm/
├── core/
│   └── helpers.sh            # _fetch(), _parse_battle_state(), _log_battle_event()
├── ai/
│   ├── gemini_client.py      # cliente Gemini com rate limiter
│   ├── analyzer.py           # análise de logs + padrões
│   ├── patcher.py            # aplica mudanças + backup/rollback
│   ├── orchestrator.py       # coordena ciclo de melhoria
│   └── requirements.txt      # dependências Python
├── data/
│   ├── configs/
│   │   └── strategy_config.json   # config dos 8 modos de batalha
│   ├── logs/
│   │   └── game_events.jsonl      # log de eventos (auto-gerado)
│   └── backups/                   # backups antes de cada patch
├── run_ai.sh                 # launcher: macro + orchestrator + watchdog
├── AI_ENGINE.md              # arquitetura completa
└── .env                      # GEMINI_API_KEY (não commitado)
```

---

## 🛡️ Scripts de Batalha (escopo IA)

| Script | Descrição | IA |
|--------|-----------|----|
| `coliseum.sh` | Coliseu individual | ✅ |
| `clancoliseum.sh` | Coliseu de clã | ✅ |
| `king.sh` | Rei dos Clãs | ✅ |
| `altars.sh` | Altares | ✅ |
| `clanfight.sh` | Batalha de clã | ✅ |
| `clandmg.sh` | Dano de clã | ✅ |
| `flagfight.sh` | Batalha de bandeira | ✅ |
| `undying.sh` | Boss Undying | ✅ |

---

## 🔄 Trocar de branch

Dentro do macro, usa `update.sh` → opção correspondente. A troca limpa automaticamente os ficheiros da outra branch para evitar conflitos.

---

## 📋 Atalhos de shell

| Comando | Ação |
|---------|------|
| `twmai` | Iniciar AI Engine |
| `twmstart` | Iniciar todas as contas |
| `twmstop` | Parar todas as contas |
| `twmview` | Monitor de logs |
| `twmsetup` | Painel de controle |

---

## 📄 Documentação adicional

- [AI_ENGINE.md](AI_ENGINE.md) — arquitetura, ciclo de melhoria, sistema de segurança
- [HOW_TO_MONITOR.md](HOW_TO_MONITOR.md) — como monitorizar o macro
- [QUICK_START.md](QUICK_START.md) — guia rápido de arranque
