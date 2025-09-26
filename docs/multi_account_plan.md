# Plano para suporte multi-conta simultâneo

## Objetivos

1. Permitir executar o bot com duas (ou mais) contas em paralelo a partir do mesmo terminal.
2. Adicionar à configuração inicial a possibilidade de cadastrar múltiplos perfis e alternar entre eles rapidamente (ex.: `A1`, `A2`).
3. Isolar cookies, cache, arquivos temporários e configurações por conta, evitando conflitos de sessão do `w3m`.
4. Criar um ambiente de testes seguro (branch `beta2` + script de prova de conceito) antes de incorporar as mudanças à versão principal.

## Limitações atuais

- O diretório `TMP` é global (`$HOME/twm/.{server}`) e compartilhado por toda execução. Isso inclui:
  - cookies criptografados (`$TMP/cript_file`), arquivos `SRC`, `FULL` etc.;
  - cache/arquivos do `w3m`, que usam o diretório padrão `~/.w3m` e sobrescrevem sessões anteriores.
- `translations.po`, `config.cfg`, `runmode_file` e `ur_file` são únicos por instalação.
- `play.sh` sempre derruba qualquer instância anterior de `twm.sh`, o que inviabiliza múltiplos processos simultâneos.
- A saída exibida em tela (`messages_info`) lê apenas os arquivos do `TMP` corrente.

## Arquitetura proposta

### 1. Perfis de conta

- Introduzir um diretório `~/twm/accounts/<id>/` para cada conta, contendo:
  - `config.cfg`, `translations.po`, `userAgent.txt`, `runmode_file`, `ur_file` específicos;
  - subdiretório `tmp/` para arquivos temporários (`SRC`, `FULL`, `last_*`, etc.);
  - subdiretório `logs/` para saídas e mensagens (`msg_file`, `ERROR_DEBUG`).
- Um arquivo central `~/twm/accounts/index.json` armazenará metadados: ID curto (A1, A2), apelido, servidor, idioma, `UR`.
- `function.sh` passa a oferecer comandos `add_account`, `select_account`, `list_accounts` reaproveitando o fluxo já existente.

### 2. Isolamento do w3m/cookies

- Para cada requisição, usar `w3m -cookie -o w3m_dir="${ACCOUNT_ROOT}/w3m"` ou exportar `W3M_HOME` antes de chamar o módulo; esse diretório conterá `cookie`, `history`, `cache` separados.
- Ajustar `loginlogoff.sh` para ler/escrever `cript_file` por conta (`$ACCOUNT_TMP/cript_file`).
- Traduzir caminhos absolutos: sempre derivar `TMP`, `HOME_TWM`, `ACCOUNT_ROOT` a partir do perfil selecionado.

### 3. Orquestrador multi-conta

- Criar script `multi_runner.sh`:
  1. Lê `accounts/index.json`.
  2. Para cada conta ativa, exporta variáveis específicas (`ACCOUNT_ID`, `TMP`, `W3M_HOME`, `CONFIG_PATH`) e inicia `twm.sh` em subshell (`nohup` ou `coproc`) gravando stdout/stderr em `logs/<id>/twm.log`.
  3. Gerencia ciclo de vida (reinício quando `twm.sh` termina, parada limpa por sinal).
- `play.sh` será atualizado para detectar se o usuário quer um perfil único (`play.sh -acct A1`) ou o gerenciador (`play.sh -multi`).
- Incluir um FIFO ou socket (`~/twm/accounts/console`) para receber comandos de troca. A interface principal lê esse FIFO e, ao receber `A1`, passa a tail -f do `msg_file` da conta correspondente.

### 4. Interface e mensagens

- `messages_info` passa a receber `ACCOUNT_TMP` como parâmetro, escrevendo em `logs/<id>/msg_file`.
- Criar comando `switch_account` que apenas aponta qual arquivo de mensagens deve ser exibido.
- Opção `info` do menu exibirá todas as contas com status (online/offline, último ping).

### 5. Configuração inicial

- Durante a instalação (`easyinstall.sh` ou `requeriments.sh`), adicionar prompt: “Deseja cadastrar nova conta agora?” e permitir criar `n` perfis.
- Manter uma conta padrão caso o usuário queira rodar no modo antigo.

## Plano de implementação por fases

1. **Preparação (branch `beta2`):**

   - Criar branch remota `beta2` a partir de `master`.
   - Atualizar `update_check.sh`/`easyinstall.sh` para aceitar `beta2` no menu (similar ao fluxo “beta”).
   - Adicionar script placeholder `scripts/multi_account_test.sh` que valida se duas pastas `accounts/A1` e `accounts/A2` existem e simulam requests com `curl` seco (sem logar ainda).

2. **Isolamento de diretórios:**

   - Refatorar `requeriments.sh` para aceitar argumento `ACCOUNT_ID` e construir caminhos relativos (`ACCOUNT_ROOT=$HOME/twm/accounts/$ACCOUNT_ID`).
   - Atualizar `language.sh`, `info.sh`, `loginlogoff.sh`, `run.sh`, `function.sh`, `twm.sh` para usar variáveis derivadas (`ACCOUNT_TMP`, `ACCOUNT_CONFIG`, `ACCOUNT_LOGS`).
   - Garantir que `translations.po` e `config.cfg` fiquem dentro do perfil.

3. **Orquestrador multi-conta:**

   - Implementar `multi_runner.sh` e alterar `play.sh` para não matar instâncias gerenciadas pelo orchestrator.
   - Cada instância de `twm.sh` deve receber `ACCOUNT_ID` via variável de ambiente para localizar seus diretórios.

4. **Console dinâmico:**

   - Criar FIFO `~/twm/accounts/console`.
   - Implementar script `console_ui.sh` que lê a FIFO, interpreta comandos (`A1`, `A2`, `status`, `quit`) e alterna a exibição (`tail -F logs/A1/msg_file`).
   - Atualizar `messages_info` para aceitar parâmetro de saída (permitir `messages_info "${ACCOUNT_TMP}"`).

5. **Configuração e UX:**

   - Ajustar `function.sh config` para listar contas, ativar/desativar, editar apelidos.
   - Atualizar documentação (`README.md`, docs existentes) com instruções multi-conta.

6. **Testes:**
   - `scripts/multi_account_test.sh`: simula dois perfis rodando em modo “dry run” (executa `/mail` e `/train` com w3m em cada diretório e verifica isolamento de cookies).
   - Logs comparativos: garantir que `cookie` de cada perfil contém apenas uma sessão.
   - Teste manual: iniciar orchestrator com duas contas (mesmo servidor) e confirmar que mensagens, chat e eventos rodam sem colisão.

## Impacto por arquivo (resumo)

- `easyinstall.sh`, `update.sh`, `update_check.sh`: adicionar branch `beta2`, gerar estrutura `accounts/` ao instalar.
- `play.sh`: novo modo `-multi` e suporte a `-acct <ID>` sem matar outras instâncias.
- `twm.sh`: ler `ACCOUNT_ID` e exportar caminhos específicos.
- `info.sh`, `language.sh`, `loginlogoff.sh`, `function.sh`, `crono.sh`, `run.sh`, módulos de eventos: parametrizar acesso à pasta TMP e logs por conta.
- Novos scripts: `multi_runner.sh`, `console_ui.sh`, `scripts/multi_account_test.sh`.
- Documentação: atualizar `README.md`, `docs/twm_loop_and_functions.md`, `docs/translation.md`, `docs/events_summary.md` com seção multi-conta.

## Riscos e mitigação

- **Sobrecarga de rede:** duas contas simultâneas dobram requests — considerar inserir offsets de agenda/polling por conta.
- **Concorrência de arquivos:** qualquer arquivo ainda global (ex.: `allies.txt`) precisa ser duplicado por conta ou protegido por lock.
- **Complexidade de manutenção:** manter compatibilidade com modo single-account (flag em config `MULTI_ACCOUNT=n` como padrão).
- **Interface:** garantir que alternância `A1/A2` não trave a FIFO; adicionar timeout e comando `reset`.

## Próximos passos imediatos

1. Criar branch `beta2` no repositório remoto (fora do escopo deste script, mas necessário antes de liberar update).
2. Atualizar `update_check.sh`/`easyinstall.sh` para listar `beta2` como opção de download/teste.
3. Implementar scaffolding de diretórios (`accounts/`, `accounts/index.json`) e script de teste básico.
4. Validar isolamento do `w3m` com dois perfis em paralelo antes de refatorar todo fluxo do bot.

## Checklist para conclusão (resumo)

- [ ] Branch `beta2` criada e disponibilizada no mecanismo de update.
- [ ] Estrutura de perfis e isolamento de diretórios implementados.
- [ ] Orquestrador e console dinâmico funcionando.
- [ ] Documentação atualizada.
- [ ] Testes (automáticos + manuais) aprovados.

Assim que a fase 1 (branch + estrutura básica) estiver pronta, podemos partir para implementação incremental dentro de `beta2`, reduzindo riscos para usuários da versão estável.
