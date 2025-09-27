Resumo: Instalação / Atualização / Login — TitansWarPro (TWM)

Objetivo

- Documentar, de forma estruturada, a configuração inicial do projeto: instalação, updates e fluxo de login.
- Fornecer referências diretas aos scripts que implementam cada etapa.

Arquivos principais analisados

- `update.sh` — instalador inicial / escolhe versão (Master/Beta) e invoca `easyinstall.sh`.
- `easyinstall.sh` — lógica de instalação, download/atualização de todos os scripts, configuração do atalho `play-twm`, tratamento de plataformas (Termux, iSH, UserLAnd, Cygwin, WSL).
- `update_check.sh` — rotina de verificação/atualização in-place (lista `SCRIPTS[]`, compara tamanho remoto x local, baixa arquivos quando necessário).
- `requeriments.sh` — seleção de servidor/idioma, definição de `URL`, `TMP` por servidor, configuração de User-Agent e timezone; cria `ur_file`.
- `loginlogoff.sh` — lógica de autenticação: criptografia local das credenciais, geração de cookie temporário, submissão via `w3m -post`, validação da conta.
- `play.sh` — gerenciador que garante apenas uma instância e chama `twm.sh` com modo (boot, -cv, -cl).
- `twm.sh` — script principal que carrega módulos, chama `requer_func`, `func_proxy`, `login_logoff`, e controla o loop principal do macro.
- `info.sh` — contém utilitários compartilhados: `fetch_page`, `time_exit`, `hpmp`, `messages_info`, parsing de páginas.
- `README.md` — instruções de instalação e uso (Termux, iSH, UserLAnd, Cygwin, WSL).

Fluxo de instalação (alto nível)

1. Usuário baixa `update.sh` (via curl) e torna executável.
2. Executa `bash update.sh`.
3. `update.sh` mostra opções de versão (Master/Beta), escolhe `version` e cria `~/twm`.
4. `update.sh` baixa `easyinstall.sh` e `info.sh`, executa `easyinstall.sh "$version"`.
5. `easyinstall.sh`:
   - Detecta plataforma e sugere/instala pacotes (w3m, curl, procps, coreutils, jq, tzdata) quando possível.
   - Cria `~/twm` e baixa a lista de scripts (`SCRIPTS`) do repositório raw do GitHub do branch selecionado.
   - Normaliza CRLF -> LF, `chmod +x` em `~/twm/*.sh`.
   - Cria atalho `play-twm` na shell rc apropriada (adiciona função e exporta).
   - Mata instâncias antigas (`play.sh`, `twm.sh`) e reinicia `~/twm/play.sh` com o runmode salvo, quando aplicável.

Comandos úteis (extraídos do README)

- Baixar instalador:

```bash
curl https://raw.githubusercontent.com/hugoviegas/TitansWarPro/master/update.sh -L -O
chmod +x update.sh
./update.sh
```

- Executar macro (ex.: modo caverna):

```bash
./twm/play.sh -cv
# ou
bash ~/twm/play.sh -cv
```

Fluxo de atualização (detalhado)

- `update_check.sh` e `update.sh` usam a mesma ideia: definem `SERVER` apontando para `https://raw.githubusercontent.com/hugoviegas/TitansWarPro/${version}/` e uma lista `SCRIPTS`.
- Para cada script: calculam `remote_count=$(curl -s -L "${SERVER}${script}" | wc -c)` e `local_count=$(wc -c <"$HOME/twm/$script")` (ou 0/1 se não existe).
- Se diferente, adicionam à lista `files_to_update`.
- Perguntam ao usuário (ou usam `FUNC_AUTO_UPDATE` para auto) se devem baixar; se sim, `curl -s -L "${SERVER}${file}" -o "$HOME/twm/$file"`.
- Após atualização: convertem CRLF -> LF, `chmod +x`, e reiniciam o script quando necessário.

Fluxo de seleção de servidor / configuração inicial

- `requeriments.sh::requer_func` apresenta um menu de servidores (1..13) e grava a escolha em `~/twm/accounts/<id>/ur_file`.
- Cada opção define `URL` (base64 nos scripts), `TMP` (p.ex. `~/twm/accounts/<id>/tmp/.1`, `~/twm/accounts/<id>/tmp/.13`), TZ, e chama `set_config "LANGUAGE" "xx"`.
- Cria `TMP` e muda para esse diretório antes de prosseguir com login/config.

Fluxo de login (detalhado)

- Arquivos usados: `$TMP/cript_file` (base64 com login=USER&pass=PASS), `$TMP/cookie_file` (decriptado temporário), `$TMP/acc_file` (resultado do fetch do /user para extrair o nick/level).
- `loginlogoff.sh::login_logoff`:
  - Se existe `$TMP/cript_file`, decodifica para `$TMP/cookie_file` e faz `w3m -cookie -o http_proxy=$PROXY -post $TMP/cookie_file -dump "$URL/?sign_in=1" -o user_agent="$(shuf -n1 $TMP/userAgent.txt)"` (duas vezes para confirmar cookie).
  - Faz fetch de `$URL/user` com `w3m -cookie -dump` e extrai o nome/nivel com `grep '\[level'` -> salva em `$TMP/acc_file`.
  - Se não existe `$TMP/cript_file` ou `ACC` vazio: pede username e senha; para senha usa função de leitura mascarada (read -p + -s -n 1 loop) e então cria `echo "login=...&pass=..." | base64 -w 0 > $TMP/cript_file`.
  - Submete o cookie decodificado como `-post` para `?sign_in=1` e espera via `time_exit`.
  - Remove `$TMP/cookie_file` após configuração da sessão.
- No `twm.sh` a chamada `login_logoff` é feita durante bootstrap, antes do loop principal.

Uso do w3m (resumo técnico)

- Flags recorrentes:

  - `-cookie` — manter cookies na sessão.
  - `-o http_proxy="$PROXY"` — usar proxy quando houver.
  - `-o user_agent="$(shuf -n1 $TMP/userAgent.txt)"` — usar User-Agent randômico.
  - `-dump` ou `-dump_source` — obter texto/HTML da página para parsing.
  - `-post $TMP/cookie_file -dump` — enviar POST (usado para login via form de `login=...&pass=...`).
  - `-debug` em algumas chamadas para extrair fontes quando necessário.

- Padrão de uso:
  - Chamam `w3m` em subshell background e usam `time_exit <n>` para limitar o tempo de execução e matar processos travados.
  - Exemplo: `w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}${relative_url}" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" > "$output_file"`

Parsing de páginas

- Padrões usados: `grep -o -E`, `sed`, `awk`, `tr -c -d '[:digit:]'` para extrair números (HP/MP, gold, etc.).
- Arquivos temporários: `$TMP/SRC`, `$TMP/TRAIN`, `$TMP/info_file`, `$TMP/msg_file`, `$TMP/acc_file`, `$TMP/cript_file`, `$TMP/cookie_file`.

Arquivos de configuração e persistência

- `~/twm/accounts/<id>/ur_file` — servidor selecionado (número) por conta.
- `~/twm/accounts/<id>/runmode_file` — runmode atual (-boot, -cv, -cl) por conta.
- `~/twm/accounts/<id>/fileAgent.txt` — modo de User-Agent salvo por conta.
- `~/twm/accounts/<id>/userAgent.txt` — lista de UAs (vem com repositório; modo legado mantém fallback em `~/twm/userAgent.txt`).
- `~/twm/accounts/<id>/config.cfg` e `$TMP/config.cfg` — chaves salvas (LANGUAGE, ALLIES, etc.).
- `~/twm/accounts/<id>/ads_file` — controle de abertura de anúncios/links por conta.

Contratos mínimos (inputs/outputs)

- Inputs: escolha de versão (update), escolha de servidor (requeriments), credenciais (username/password), confirmação de updates (opcional).
- Outputs: `~/twm` populado com scripts, diretórios `accounts/<id>/` com `ur_file`, `runmode_file`, `tmp/.<server>` com cookies/arquivos temporários, sessão válida no jogo (via cookie w3m).
- Critérios de sucesso:
  - `~/twm` contém a lista de scripts e são executáveis.
  - `login_logoff` obteve e validou `ACC` (nome do usuário) após login.
  - `play.sh` inicia `twm.sh` sem erros e entra no loop principal.

Edge cases / pontos a observar

- Falta de `w3m` ou `curl` na plataforma: `easyinstall.sh` tenta instalar pacotes em Termux/iSH/Alpine/Cygwin, mas em sistemas sem package manager o usuário precisa instalar manualmente.
- Requisies que demoram/caem: `time_exit` mata processo após timeout; pode gerar estado parcial em `$TMP`.
- CRLF em arquivos baixados (Windows): scripts usam `sed -i 's/\r$//'` para normalizar, mas quando usar Git no Windows, habilite autocrlf corretamente.
- Proxy / User-Agent: se `userAgent.txt` estiver ausente a seleção automática tenta preencher; proxy mal configurado pode quebrar logins.
- Senhas: são armazenadas localmente codificadas (base64) em `$TMP/cript_file`; isso não é forte criptografia — considerar usar gpg se for sensível.

O que salvei agora

- Arquivo criado: `twm_install_update_login.md` (este arquivo), na raiz do repositório, com o resumo acima.

Próximos passos recomendados (escolha uma):

1. Gerar um manifest JSON completo (arquivo `twm_manifest.json`) com todos caminhos, tamanhos e mtimes (posso gerar o comando PowerShell para você executar localmente — é rápido e seguro).
2. Extrair automaticamente um mapeamento "arquivo → responsabilidades" (JSON) usando os scripts já lidos e produzir um `twm_map.json` no repo.
3. Criar uma documentação mais detalhada por arquivo (explicando funções importantes em cada script) e testes de smoke (por exemplo, um script que valida que `w3m` e `curl` respondem corretamente com `-I`).

Sugestão imediata: se quer que eu gere o manifest completo agora, rode este comando no PowerShell (pwsh):

```powershell
Get-ChildItem -Path "C:\Users\hugov\OneDrive\Documentos\GitHub\TitansWarPro" -Recurse -File |
  Select-Object @{n='path';e={$_.FullName}}, @{n='size';e={$_.Length}}, @{n='mtime';e={$_.LastWriteTime}} |
  ConvertTo-Json -Depth 5 > "C:\Users\hugov\OneDrive\Documentos\GitHub\TitansWarPro\twm_manifest.json"
code "C:\Users\hugov\OneDrive\Documentos\GitHub\TitansWarPro\twm_manifest.json"
```

Se preferir, eu mesmo posso gerar um `twm_map.json` agora com os arquivos que li (resumido) e depois ampliar.

Resumo rápido do que eu fiz agora

- Li os scripts principais relacionados à instalação/atualização/login.
- Criei `twm_install_update_login.md` com um resumo técnico e orientações.

Diga qual próximo passo você prefere (1, 2 ou 3) ou peça outra ação específica e eu continuo imediatamente.
