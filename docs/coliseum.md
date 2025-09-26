# Coliseum (coliseum.sh) — documentação detalhada

## Propósito

Automatizar lutas no Coliseu público: entrar na fila de batalha, esperar pelo início (outros jogadores), executar o combate e tratar ações de pós-batalha como vender loot.

## Gatilho

- `coliseum_start` é acionado pelo loop principal quando o horário e/ou links indicam que o coliseu pode ser iniciado. O módulo detecta a presença de `/coliseum/enterFight` e `?end_fight` para controlar o fluxo.

## Fluxo principal (resumido)

1. Preparação:

   - Define diretório temporário (`/dev/shm` se disponível) e cria `src_ram`, `full_ram`, `tmp_ram`.
   - Coleta informação inicial de `/train` (valor numérico para FULL) e armazena em `full_ram`.
   - Ajusta configurações gráficas (`/settings/graphics/0`) — provavelmente para garantir que páginas sejam renderizadas de forma previsível.
   - Baixa `/coliseum` para `$src_ram`.

2. Verificações iniciais:

   - Se o HTML tem `?end_fight`, o módulo lida com finalização (pode haver pequenas requests vazias para fechar o evento).
   - Extrai `access_link` e `go_stop` (link para `enterFight`). Se `go_stop` vazio, não há batalha iniciável.

3. Entrada e espera por outros jogadores:

   - Se `go_stop` existe, faz request para `enterFight` (entra na fila) e aguarda a batalha começar.
   - Usa um loop com `first_time` e checagens periódicas no `$TMP/SRC` para detectar sinais de que a batalha iniciou (p.ex. encontrar links de `attack` ou mudanças específicas no HTML).
   - Enquanto espera, exibe mensagens de status (preparando, esperando por outros, etc.).

4. Combate:

   - Quando a batalha começa, entra em um loop de ataque com timeout (ex.: `BREAK` baseado em timestamp).
   - Durante a batalha, extrai ações possíveis e executa sequências de requests a cada intervalo.
   - Aplica lógica de uso de itens ou decisões táticas conforme o HTML (semelhante aos módulos de fight: heal/dodge/attack/random).

5. Pós-batalha:
   - Ao fim da luta, acessa inventário `/inv/bag/` e executa `sellAll` (se aplicável) para vender loot.
   - Exibe confirmação e limpa arquivos temporários.

## Arquivos temporários usados

- `src_ram`, `full_ram`, `tmp_ram` — armazenamento temporário em memória quando disponível.
- `ACCESS`, `ARENA`, `ATK1`, `ATKRND` — arquivos que guardam links ou ids extraídos só para uso imediato.

## Pontos importantes e riscos

- Dependência em `w3m -dump`/`-dump_source` e regex: mudanças na estrutura da página podem interromper a detecção de `enterFight` ou do início da batalha.
- Espera ativa: o script entra em loops de polling para detectar início de batalha; ajustar intervalos e timeouts evita over-requests no servidor.
- Concorrência: se múltiplas instâncias tentarem usar os mesmos `tmp_ram` ou arquivos, podem sobrescrever dados; usar `/dev/shm` minimiza I/O, mas locks ainda são recomendáveis.
- Variações de latência: a espera por outros jogadores pode levar a long polls; proteger com timeouts e re-entradas garante que o script não trave indefinidamente.

## Melhorias práticas

- Centralizar timeouts e intervalos (por exemplo `COLISEUM_POLL=2s`, `COLISEUM_TIMEOUT=90s`) nas configurações globais para facilitar tuning.
- Implementar travas (locks) para `tmp_ram` e arquivos de sessão quando necessário.
- Adicionar logs mais detalhados em modo debug (`-v`), por exemplo gravar `ACCESS` histórico e timestamps para análise de falhas em partidas.

## Trecho-chave (pseudocódigo)

fetch /train -> full_ram
fetch /coliseum -> src_ram
if enterFight available:
GET enterFight
wait until battle starts or timeout
while battle not finished and within timeout:
parse actions and perform them
fetch /inv/bag/ and sellAll
