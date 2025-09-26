# King (king.sh) — documentação detalhada

## Propósito

Automatizar o evento "King of the Immortals" — entrar no mini-jogo, esperar o início (quando o servidor disponibiliza `kingatk`) e participar do combate coletivo contra o rei.

## Gatilho

- `king_start` é acionado pelo loop principal em horários específicos (ex.: 12:25-12:29, 16:25-16:29, 22:25-22:29). O script prepara o ambiente (obtém `FULL` e chama `enterGame`) e aguarda até aparecer `king/kingatk/` nos links da página.

## Fluxo principal (resumido)

1. Preparação:

   - Baixa `train` para obter `FULL` (valor de HP total) e grava em `$TMP/FULL`.
   - Acessa `king/enterGame` e guarda a primeira `ACCESS` link para entrar no evento.
   - Aguarda até que `king/kingatk/` apareça, com timeout curto (30s). Se apareceu, chama `king_fight`.

2. `king_fight` (loop de combate):

   - Define intervalos e thresholds: `LA` (delay entre ataques), `HPER` (percentual p/ curar), `RPER` (percentual p/ atacar random).
   - `cl_access()` (função local) analisa o `$TMP/SRC` e escreve arquivos temporários: `ATK`, `KINGATK`, `ATKRND`, `DODGE`, `STONE`, `HEAL`, `USER`, `HP`, `HP2`. Calcula `RHP` e `HLHP`.
   - Se `dodge` presente, mostra saída formatada (`w3m -dump`) com emojis (inclui `👑` para o rei). Caso contrário, tenta seguir `/king` e trata `unrip` (reanimar?) links.
   - Inicializa timers (`last_dodge`, `last_heal`, `last_atk`) e `old_HP`.
   - Entra no loop `until BREAK_LOOP` que repete até sinal de fim:
     - Dodge: se HP caiu desde `old_HP` e tempo desde `last_dodge` entre limites, faz GET em `DODGE`.
     - Heal: se HP abaixo de `HLHP` e tempo desde `last_heal` apropriado, faz GET em `HEAL` e atualiza `FULL`.
     - Attack_all / KingAtk: a cada `LA` segundos tenta executar `KINGATK` se disponível (ação 'kingatk' — ataque especial coletivo). Depois, pode usar `STONE` (item) se `HP2` baixo.
     - Random attacks: em certas condições tenta `ATKRND` (atacar aleatório) quando `RHP` < `HP2` ou alvo é aliado (verifica `USER` em `allies.txt`).
     - Attack: sempre executa `ATK` como ação padrão.
     - Caso não haja ações, recarrega `/king` e espera 1s.

3. Finalização:
   - Quando loop termina, limpa variáveis, chama `apply_event`, imprime status e dorme 10s.

## Arquivos temporários usados

- `$TMP/SRC` — HTML/dump da página atual do evento.
- `ATK`, `KINGATK`, `ATKRND`, `DODGE`, `STONE`, `HEAL` — links extraídos para agir.
- `HP`, `HP2`, `FULL`, `OLD_HP` — valores de vida / thresholds.
- `last_*` — timestamps para espaçar ações.
- `USER` e `allies.txt` — usados para decidir ataques randômicos em aliados.

## Pontos importantes e riscos

- Dependência pesada em regex/grep: mudanças no HTML podem quebrar extração de links.
- Uso de arquivos TMP sem locks: se múltiplas instâncias rodarem no mesmo `$TMP`, podem sobrescrever arquivos. Considere travas com `mkdir`/`flock` em gravações críticas.
- Timeouts: `time_exit` é usado para evitar travamentos de `w3m`, mas pode deixar estado parcial no `$TMP/SRC`.
- Itens/ações: o script tenta usar `STONE` automaticamente quando `HP2 < 25`; ajustar thresholds conforme necessidade.

## Sugestões de melhorias rápidas

- Adicionar locking simples para proteger `ALLIES`/`TMP` gravações.
- Centralizar `LA`, `HPER`, `RPER` em `function.sh` como configuráveis (já existe `FUNC_*`), para facilitar tuning por servidor.
- Substituir alguns `grep` complexos por `sed -n 's/.../.../p'` mais robustos ou um parser HTML leve se disponível.

## Trechos chave (pseudocódigo)

if time to start:
fetch /king/enterGame
wait until page contains kingatk or timeout
while not finished:
update ATK/HEAL/DODGE/HP values
if should_dodge: GET DODGE
elif should_heal: GET HEAL
elif should_kingatk: GET KINGATK
elif should_random: GET ATKRND
do GET ATK
sleep/refresh
