# Resumo rápido dos eventos do bot

Este arquivo é um apanhado rápido (compacto) do que cada evento/módulo faz no repositório. Use como referência para entender quando cada rotina roda, quais arquivos temporários são usados e riscos comuns.

- Arena (`arena.sh`): Duelo de arena, vende loot, modos especiais (fullmana, fault, collfight). Gatilho: loop principal. Usa `/arena/`, `/inv/bag/` e arquivos temporários ARENA/ATK1.
- Altars (`altars.sh`): Evento de altar — lutas com lógica heal/dodge/attack/random. Gatilho: janelas horárias via `case` em `date +%H:%M`. Usa `$TMP/src.html`, HP/HP2/FULL/RHP/HLHP.
- Campaign (`campaign.sh`): Sequência de passos de campanha (go/fight/attack/end). Gatilho: quando `/campaign/` expõe ações. Loop curto com timeout.
- Career (`career.sh`): Atividades repetíveis da carreira (attack/take). Gatilho: links em `/career/`. Loop curto (max ~60s).
- Cave (`cave.sh`): Mina/recursos — ações gather/down/runaway/speedUp. Pode rodar em modo interativo (`cave_start`) ou rotina (`cave_routine`). Usa `runmode_file` e pode forçar `-boot` ao atingir limites.
- Clan Coliseum (`clancoliseum.sh`): Lutas de clã no coliseu, mesma engine de combate com timers e thresholds. Gatilho: horários específicos.
- Clan Damage (`clandmg.sh`): Variante de clanfight focada em dano (clandmgfight). Gatilho: horários. Mesma lógica de parsing e timers.
- Clan Fight (`clanfight.sh`): Lutas de clã padrão. Gatilho: horários fixos. Usa arquivos TMP/SRC e controles `last_atk/heal/dodge`.
- Coliseum (`coliseum.sh`): Coliseu público — entra em fights que aguardam outros jogadores. Lógica: entrar, esperar início, executar combate e vender itens no fim.
- Flagfight (`flagfight.sh`): Luta de bandeira — itens extras (shield, stone, herb). Gatilho: horários. Saída formatada com emojis via `w3m -dump`.
- King (`king.sh`): King of the Immortals — modo com `kingatk` e ataques ao rei. Gatilho: janelas horárias (ex.: 12:25-12:29, 16:25-16:29, 22:25-22:29). Fluxo: enterGame → esperar `kingatk` → loop de combate com dodge/heal/kingatk/atk rnd/atk.
- League (`league.sh`): Rotinas da liga (duels, ranking) — similar à arena/campaign (verificar arquivo para detalhes específicos).
- Undying (`undying.sh`): Evento de sobrevivência/ondas — loop por ondas com decisões de cura/uso de itens.
- SpecialEvent (`specialevent.sh`): Handler central para eventos temporários. Pode delegar para módulos específicos (`apply_event`) ou executar ações próprias (coleta de recompensas, ativar boosts).

## Observações comuns

- Padrão de implementação: cada evento baixa páginas com `w3m` (ou `fetch_page`), extrai links com `grep`/`sed`, calcula thresholds (`HLHP`, `RHP`) e usa timers (`last_atk`, `last_heal`, `last_dodge`).
- Arquivos temporários: `$TMP/SRC`, `$TMP/*` (ATK, HEAL, DODGE, HP, FULL, ACCESS, etc.). Vários módulos dependem desses arquivos.
- Riscos: parsing HTML com regex é frágil; escrita concorrente em arquivos TMP (ou `translations.po`) pode causar corrupção; timeouts/sleeps podem precisar ajuste por latência.

Se quiser, gero agora documentos detalhados para `king.sh` e `coliseum.sh` — já criei os arquivos separados com detalhes.
