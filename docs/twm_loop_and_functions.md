# TWM — Loop principal, Cronograma e `function.sh` (configuração)

Objetivo

- Documentar, por arquivo, como o loop principal e o agendamento (cronograma) funcionam.
- Documentar `function.sh` (mecanismo de configuração persistente) e como os módulos consultam essas flags.
- Mapear principais funções, arquivos temporários, estados e interações para facilitar manutenção e testes.

Escopo

- Foco: fluxo de execução, agendamento, loops locais (cave/events) e configuração.
- Eventos específicos (detalhes de cada evento) ficam para um documento separado.

Sumário rápido

- Entrypoints: `play.sh` (launcher), `twm.sh` (bootstrap), `run.sh::twm_play` (agendador principal).
- Cronograma/Agendamento: implementado por `run.sh::twm_play` (case em `date +%H:%M`) + `crono.sh::start()` que agrega tarefas periódicas.
- Loops locais: cada módulo (ex.: `cave.sh::cave_start`, `specialevent.sh::specialEvent`) tem seu próprio loop de interação com o site, usando `fetch_page()` e `time_exit()`.
- Configuração runtime: `function.sh` (persistência em `$TMP/config.cfg`) define flags `FUNC_*`, `LANGUAGE`, `ALLIES`, etc., lidas por outros módulos.

Arquivos-chaves e responsabilidades

- `play.sh`

  - Controla uma única instância: mata processos antigos (`twm.sh`) e chama `twm.sh` com o modo (`-boot`, `-cv`, `-cl`).
  - Loop: while true kill any old twm.sh then call twm.sh in chosen mode.

- `twm.sh`

  - Carrega módulos: `language.sh`, `requeriments.sh`, `loginlogoff.sh`, `crono.sh`, `function.sh`, `info.sh`, etc.
  - Bootstrap: chama `load_config`, `requer_func` (seleção de servidor), `func_proxy`, `login_logoff`, `messages_info`, `conf_allies`.
  - Loop principal: chama `twm_start()` repetidamente, que decide entre `cave_start`, `twm_play` etc., conforme `RUN`.

- `run.sh` (agregador de jogo)

  - Função principal: `twm_play()` — salva `runmode_file`, verifica `CLD` (clan id), e decide ações com base em `date +%H:%M`.
  - Contém um grande `case` por horários (faixas e instantes) que chama funções específicas:
    - Coliseu: `coliseum_fight()` (00:55–03:55 pattern)
    - Meia-hora: `start()` — agrupa tarefas regulares (veja abaixo)
    - Eventos pontuais: `undying_start`, `king_start`, `flagfight_start`, `clancoliseum_start`, `clanfight_start`, `altars_start`, `specialEvent`
    - Default: se `RUN` é `-cl`, executa `arena_duel`, `coliseum_start` e `messages_info`; senão chama `func_sleep` e `func_crono`.
  - `restart_script()` — reinicia `twm.sh` em modo `-boot` quando necessário (mata PIDs e relança com nohup).

- `crono.sh`

  - `func_crono()` — lê hora (`HOUR`) e minuto (`MIN`), imprime cronograma/estado.
  - `start()` — função agregadora chamada por `run.sh` em horários programados; chama em sequência rotinas como:
    - `arena_duel`, `career_func`, `cave_routine`, `func_trade`, `campaign_func`, `clanDungeon`, `clan_statue`, `check_missions`, `check_rewards`, `specialEvent`, `clanQuests`, `messages_info`, `func_crono`, `func_sleep`.
  - `func_sleep()` — decide o intervalo `i` a ser usado entre ticks/mostras (p.ex. reduz intervalo próximo a minutos críticos, dispara coliseu no primeiro dia do mês).
  - `func_cat()` — exibe mensagem (`$TMP/msg_file`) e aguarda input do usuário com `read -t $i`, permitindo interação manual entre as execuções automáticas.

- `info.sh`

  - Utilitários centrais: `fetch_page(relative_url, outFile)` usa `w3m -cookie -dump_source` e grava em `$TMP/SRC`.
  - `time_exit(seconds)` — monitora PID do último comando em background; mata se exceder timeout (proteção contra travamentos de `w3m`).
  - `hpmp()` — coleta HP/MP e calcula percentuais usando `TRAIN` e `$TMP/SRC`.
  - `messages_info()` — preenche `$TMP/msg_file` com mail/chat e status do jogador.

- `cave.sh`

  - `cave_start()` — loop local para operar na caverna:
    - Fetch `/cave/`, extrai primeiro link de ação (`/cave/(gather|down|runaway|speedUp)/?r=...`).
    - Enquanto `RUN` for `-cv` e antes do tempo limite (BREAK = now + 1800s), executa cada ação via `fetch_page`, processa resultado (contadores, mensagens), e re-fetch `/cave/`.
    - Se atingir limites (speedUp count), força `twm.sh -boot` e retorna.
  - `cave_routine()` — versão mais curta usada em `start()` (não em loop infinito), usada para checagens rápidas.

- `specialevent.sh`

  - `specialEvent()` detecta eventos por presença de `shb_text` no HTML e extrai o `event_link`.
  - Discrimina por evento (`questrnd`, `fault`, `clandmgfight`, `marathon`, ...) e executa a rotina apropriada (claim, attack loop, apply).
  - Eventos que exigem looping (ex.: `fault`) repetem `fetch_page` / grep de links de ataque até não restarem mais.

- `check.sh`

  - Funções utilitárias chamadas pelo `start()` (ex.: `check_missions()`, `check_rewards()`, `apply_event()`, `use_elixir()`).
  - Faz fetchs e toma ações para coletar chests, completar quests, aplicar elixires, etc.

- `loginlogoff.sh`

  - `login_logoff()` — se encontra `$TMP/cript_file` (base64 login=...&pass=...) decodifica para `$TMP/cookie_file` e faz POST via `w3m -post $TMP/cookie_file -dump "$URL/?sign_in=1"` para obter cookie.
  - Em caso de login interativo pede username e senha com leitura mascarada; gera `$TMP/cript_file` com `base64 -w 0`.
  - Valida o login consultando `$URL/user` e extraindo `ACC` (nome/nivel) com `grep '\[level'`.

- `function.sh` (detalhado abaixo)

Flow de execução (simplificado)

1. `./play.sh -<mode>` é executado pelo usuário. `play.sh` garante que não existem instâncias antigas e chama `twm.sh <mode>`.
2. `twm.sh` carrega módulos, chama `load_config`, `requer_func` (escolha do servidor/URL/TMP), `func_proxy`, `login_logoff`.
3. `twm.sh` chama `messages_info` e então entra no loop principal chamando `twm_start()` repetidamente.
4. `twm_start()` (em `twm.sh`) decide entre `cave_start` (se `-cv`) ou `twm_play()` (modo padrão/coliseu/clan).
5. `run.sh::twm_play()` escolhe ações baseadas em `date +%H:%M` (agendamento). Em horários periódicos chama `start()` (crono.sh) que executa uma coleção de tarefas (checar missões, campanhas, eventos, cave routine, etc.).
6. Cada módulo que precisa interagir com o site chama `fetch_page()` para popular `$TMP/SRC` e então faz parsing com `grep/sed/awk` e possivelmente faz ações (POST/GET) repetidas até terminar. Sempre há `time_exit()` para não travar o loop global.

`function.sh` — configuração persistente (detalhes)

- Arquivo alvo: `$TMP/config.cfg` (criado por `default_config()` se não existir).
- Funções principais:
  - `load_config()` — carrega `$TMP/config.cfg` no ambiente.
  - `default_config()` — escreve valores padrão:
    - FUNC_check_rewards="y"
    - FUNC_use_elixir="n"
    - FUNC_coliseum="y"
    - FUNC_AUTO_UPDATE="y"
    - FUNC_play_league=999
    - FUNC_clan_figth="y"
    - LANGUAGE="en"
    - ALLIES=""
    - SCRIPT_PAUSED="n"
  - `get_config(KEY)` — recarrega config e retorna ${!KEY}.
  - `set_config(KEY, VALUE)` — remove linha anterior e adiciona `KEY=VALUE` ao arquivo.
  - `update_config(KEY, VALUE)` — valida se a chave existe e a atualiza com `sed -i`.
  - `request_update()` — UI interativa para solicitar mudanças (opções: relics, elixir, auto-update, league target, language, allies).
  - `config()` — loop que chama `request_update()` e permite ao usuário alterar flags; sinaliza saída com `EXIT_CONFIG`.

Como outros módulos usam `function.sh`

- Antes de rodar tarefas, `twm.sh` chama `load_config()` e os módulos chamam `get_config`/`get` diretamente ou referenciam variáveis carregadas (ex.: `if [ "$FUNC_check_rewards" = "n" ]; then return; fi` em `check.sh::check_rewards`).
- Flags controlam comportamento sem editar código: p.ex., `FUNC_use_elixir=n` impede `use_elixir()` de agir.

Arquivos temporários e configuração persistente

- `~/twm/ur_file` — servidor selecionado (1..13). Define `URL` e `TMP`.
- `~/twm/runmode_file` — runmode atual (-boot, -cv, -cl) para reinício automático.
- `$TMP/` — pasta temporária por servidor (p.ex. `~/.1`, `~/.13`). Contém:
  - `SRC` — último fetch da página (HTML dump)
  - `TRAIN` — dados de treino (HP/MP)
  - `msg_file`, `info_file`, `bottom_file` — mensagens e resumo
  - `cript_file`, `cookie_file` — para login
  - `config.cfg` — configuração persistente local
- `~/twm/userAgent.txt` e `$TMP/userAgent.txt` — User-Agent pool (usado por `fetch_page`)

Timeouts, travamentos e proteção

- `time_exit()` em `info.sh` monitora background PID e mata processo se exceder o timeout. Isso é crítico para manter o loop vivo quando `w3m` travar.
- Instâncias antigas são mortas por `play.sh`/`easyinstall.sh`/`restart_script()` para evitar concorrência não desejada.

Padrões de parsing e ação

- Todas as ações seguem o mesmo padrão:
  1. `fetch_page(<relative_url>)` -> atualiza `$TMP/SRC`.
  2. `grep -o -E` / `sed` / `awk` para extrair links de ação (p.ex. `/king/kingatk/...`, `/cave/gather/...?r=`).
  3. Se link encontrado, `fetch_page($link)` executa ação (POST/GET dependendo do link).
  4. Repeat until no more actions or condition met.

Pontos de falha comuns

- Falta de `w3m`/`curl` rompe todo o fluxo; `easyinstall.sh` tenta instalar, mas em sistemas sem package manager manualmente se faz necessário.
- Mudança no HTML do site que quebra os `grep/sed` — parsing frágil.
- Armazenamento da senha em base64 (`$TMP/cript_file`) não é seguro.
- `kill -9` é usado amplamente e pode deixar arquivos temporários em estados intermediários.

Anotações para manutenção e testes

- Testes smoke (recomendado):
  - `./twm/check_env.sh` — checa `curl`, `w3m`, permissão de `~/twm`, leitura/escrita em `$TMP`.
  - Teste de `fetch_page("/")` com `time_exit(10)` para validar que o site responde e `w3m` funciona.
- Logs: recomendo adicionar appending de log com timestamp em `$HOME/twm/log.txt` nas entradas principais do loop (`twm_play`, `cave_start`, `login_logoff`, `update`).

Próximos passos sugeridos

1. Criar `check_env.sh` e `smoke_tests.md` com checks rápidos (se quiser, eu posso adicionar esses arquivos).
2. Documentar eventos individualmente (marathon, fault, questrnd, etc.) em `docs/events/*` — você pediu para tratar eventos depois.
3. Substituir armazenamento base64 por gpg/openssl para proteger credenciais (opcional).

Se quiser, eu gero agora:

- Um arquivo `docs/flow.json` descrevendo em JSON o grafo de chamadas (nodes: funções; edges: chamadas).
- Ou crio `check_env.sh` com os checks smoke (recomendo executar localmente).

Diga qual desses dois prefere como próximo passo (flow.json ou check_env.sh) ou peça documentação adicional por arquivo.
