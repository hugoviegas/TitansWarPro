# Tradução em TWM — como funciona, cache e uso em `printf_t`/`echo_t`

Este documento descreve como a tradução de strings é tratada no projeto, qual biblioteca/external API é usada, o formato de cache (`translations.po`), e como as funções `printf_t` e `echo_t` consomem a tradução.

Arquivos relevantes

- `language.sh` — implementação das funções de tradução: `get_translation`, `load_translations`, `translate_and_cache`.
- `info.sh` — contém `printf_t` e `echo_t` que chamam `translate_and_cache` antes de imprimir.
- `~/twm/translations.po` — arquivo de cache local de traduções (formato: original|translated).

Resumo do funcionamento

1. Quando um texto precisa ser exibido com tradução, os helpers chamam `translate_and_cache "$LANGUAGE" "$text"`.
2. `translate_and_cache` faz o seguinte:
   - Se `target_lang` for `en` (inglês), retorna imediatamente o texto original (sem tradução).
   - Remove espaços extras do texto (`xargs`).
   - Procura no arquivo `TRANSLATIONS_FILE` (`$HOME/twm/translations.po`) por uma linha que comece com `text|` (grep `^$text|`).
     - Se encontrar, retorna a tradução já armazenada.
     - Caso contrário, chama `get_translation(target, text)` para obter a tradução da API externa e, se obtiver sucesso, anexa `text|translated` ao `translations.po` e retorna a tradução.
3. `get_translation` usa a API pública em https://translate.disroot.org/translate enviando um POST JSON com `q`, `source`, `target` e recupera `.translatedText` com `jq`.
4. `load_translations` (executado na carga do `language.sh`) popula um array associativo `translations[]` lendo `translations.po`, mas a função `translate_and_cache` faz uma pesquisa direta via `grep` (ou seja, o array global é carregado mas não é necessariamente usado em todas as chamadas).

Formato do cache (`translations.po`)

- Cada linha tem o formato: ORIGINAL|TRADUÇÃO
- Exemplo:
  Olá|Hello
  "Password:"|"Senha:" # se quiser preservar aspas visualmente
- É uma lista simples separada por `|`. `translate_and_cache` usa `grep "^$text|"` para encontrar a última ocorrência.
- Local padrão: `TRANSLATIONS_FILE="$HOME/twm/translations.po"`.

Como `printf_t` e `echo_t` usam a tradução

- Ambas as funções estão em `info.sh`.
- Assinatura reduzida (pseudo):
  - printf_t(local_text, local_color_start, local_color_end, local_emoji_position, local_emoji)
  - echo_t(local_text, local_color_start, local_color_end, local_emoji_position, local_emoji)
- Fluxo interno:
  1. Chamam `translate_and_cache "$LANGUAGE" "$local_text"` e guardam o retorno em `local_translated_text`.
  2. Dependendo de `local_emoji_position` (`before` ou `after`) usam `printf` ou `echo` para exibir:
     - Se `before`: exibem emoji primeiro (`$local_emoji $local_translated_text`).
     - Se `after`: exibem texto traduzido seguido pelo emoji (`$local_translated_text $local_emoji`).
  3. Aplicam as cores passadas (`local_color_start` e `local_color_end`).
- Exemplos de uso no código:
  - `local prompt="$(translate_and_cache "$LANGUAGE" "Password: ")"` (login uses translated prompt)
  - `printf_t "Command execution was interrupted!" "$WHITEb_BLACK" "$COLOR_RESET" "before" "⚠️" >> "$TMP/ERROR_DEBUG"`

Dependências e requisitos

- Requer `curl` e `jq` para usar a API de tradução (`get_translation`). `language.sh` faz chamadas `curl` e parse com `jq`.
- `translate_and_cache` grava em `~/twm/translations.po` — o script precisa ter permissão de escrita nessa pasta.

Pontos importantes e riscos

- Rede/API:
  - `get_translation` depende de um serviço externo (translate.disroot.org). Problemas de rede, bloqueio ou rate limiting farão com que `translate_and_cache` retorne o texto original (o código trata o caso de fallback retornando o original se a tradução falhar).
  - Não há controle de rate-limit ou retry sofisticado; muitas chamadas podem levar a throttling.
- Concorrência/concorrência de escrita:
  - `translate_and_cache` faz `grep` e depois `echo "text|translation" >> translations.po` sem travas. Em casos de concorrência (duas instâncias do bot rodando com o mesmo file), o arquivo pode ficar com linhas duplicadas ou corrompido.
  - Recomenda-se usar um lock simples (ex.: `flock` ou `mkdir` lock) ao escrever `translations.po` para evitar race conditions.
- Segurança / privacidade:
  - As strings enviadas para a API podem incluir conteúdo sensível (embora tipicamente sejam mensagens da UI). Se isso for um problema, considerar manter `translations.po` completa offline.
- Formatação / variáveis nas strings:
  - Algumas strings do projeto incluem variáveis (ex.: "[Wait to *$ACC*... (${check}s) - press ENTER to change account]"). `translate_and_cache` trata a string inteira — ao traduzir modelos com placeholders dinâmicos é melhor usar strings com placeholders bem definidas ou traduzir partes fixas.

Boas práticas e recomendações

- Pré-popular `translations.po` para os idiomas que você usa frequentemente. Assim `translate_and_cache` não faz chamadas de rede na primeira execução.
- Adicionar lock ao escrever no `translations.po` (ex.: `flock`, `set -C` + `> file.tmp && mv` ou `mkdir /tmp/twm_trans_lock && ... && rmdir /tmp/twm_trans_lock`).
- Tornar a URL da API e chave configuráveis via variável de ambiente (ex.: `TWMT_TRANSLATE_URL`, `TWMT_TRANSLATE_KEY`) para flexibilidade.
- Implementar um modo "offline" que ignora tentativas de tradução (retorna original) quando não houver conectividade.
- Evitar traduzir strings com placeholders dinâmicos sem normalizar (por exemplo, traduzir uma "template" com `%s` ou `{name}` em vez de valores já interpolados).

Exemplos rápidos

- Entrada em código:
  printf_t "Please wait..." "\n"
- O que acontece: `printf_t` chama `translate_and_cache "$LANGUAGE" "Please wait..."` retornando, por exemplo, "Por favor, espere...". Em seguida `printf` executa com cores e emoji se fornecidos.

Como melhorar (pequeno patch sugerido)

1. Substituir a escrita direta por uma função segura:
   - lock -> re-check -> append -> unlock.
2. Usar o array associativo `translations[]` carregado por `load_translations` para lookup em memória rápido, e apenas persistir atualizações por append seguro.
3. Fazer o endpoint e o idioma-fonte (`SOURCE`) variáveis configuráveis via `config.cfg` ou variáveis de ambiente.

Arquivo gerado

- `docs/translation.md` (este arquivo) salvo no repositório.

Quer que eu também:

- Implemente um `translations_locked_write()` no `language.sh` para evitar races? (posso editar `language.sh` e adicionar flock-based append), ou
- Gere um `translations.po` inicial com traduções comuns em português (p.ex., "Please wait...", "Password:") para evitar chamadas à API no first-run?

Escolha uma opção e eu procedo.
