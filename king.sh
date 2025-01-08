# shellcheck disable=SC2148
king_fight() {
    # Configura o diretório temporário na memória, se disponível, para melhorar o desempenho
    if [ -d "/dev/shm" ]; then
        local dir_ram="/dev/shm/"
    else
        local dir_ram="$PREFIX/tmp/"
    fi

    # Cria diretórios temporários para uso durante a execução
    mkdir -p "$dir_ram"
    src_ram=$(mktemp -p "$dir_ram" data.XXXXXX)  # Arquivo temporário para salvar fontes
    full_ram=$(mktemp -p "$dir_ram" data.XXXXXX)  # Arquivo temporário para dados completos
    tmp_ram=$(mktemp -d -t twmdir.XXXXXX)  # Diretório temporário exclusivo
    cp -r "$TMP"/* "$tmp_ram"  # Copia os arquivos temporários para o novo diretório
    cd "$tmp_ram" || exit  # Altera para o diretório temporário ou sai se falhar

    # Faz a primeira requisição para a página de treino e extrai dados relevantes
    (
        w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "$URL/train" -o user_agent="$(shuf -n1 userAgent.txt)" | grep -o -E '\(([0-9]+)\)' | sed 's/[()]//g' >"$full_ram"
    ) &
    time_exit 20  # Limita o tempo de espera para a execução da requisição

    # Configurações gerais
    cd "$TMP" || exit  # Altera o diretório para $TMP; sai do script se falhar
    local LA=4  # Intervalo entre ataques (em segundos)
    local HPER="38"  # Porcentagem de HP para iniciar a cura
    local RPER=5  # Porcentagem para cálculo aleatório

    # Função para extrair URLs e informações do arquivo $TMP/SRC
    cl_access() {
        # Extrai URLs de ataque do inimigo
        grep -o -E '(/king/attack/[?]r[=][0-9]+)' "$TMP"/SRC | sed -n 1p >ATK 2>/dev/null
        
        # Extrai URL de ataque ao rei
        grep -o -E '(/king/kingatk/[?]r[=][0-9]+)' "$TMP"/SRC | sed -n 1p >KINGATK 2>/dev/null

        # Extrai URLs para trocar ataque
        grep -o -E '(/king/at[a-z]{0,3}k[a-z]{3,6}/[?]r[=][0-9]+)' "$TMP"/SRC >ATKRND 2>/dev/null

        # Extrai URLs de esquiva
        grep -o -E '(/king/dodge/[?]r[=][0-9]+)' "$TMP"/SRC >DODGE 2>/dev/null

        # Extrai URLs de pedra
        grep -o -E '(/king/stone/[?]r[=][0-9]+)' "$TMP"/SRC >STONE 2>/dev/null

        # Extrai URLs de ervas
        grep -o -E '(/king/grass/[?]r[=][0-9]+)' "$TMP"/SRC >GRASS 2>/dev/null

        # Extrai URLs de cura
        grep -o -E '(/king/heal/[?]r[=][0-9]+)' "$TMP"/SRC >HEAL 2>/dev/null

        # Formata e salva nomes de usuários
        grep -o -E '([[:upper:]][[:lower:]]{0,15}( [[:upper:]][[:lower:]]{0,13})?)[[:space:]][^[:alnum:][:space:]]' "$TMP"/SRC | sed -n 's,\ [<]s,,;s,\ ,_,;2p' >USER 2>/dev/null

        # Extrai o valor de HP do jogador
        grep -o -E "(hp)[^A-Za-z0-9_]{1,4}[0-9]{1,6}" "$TMP"/SRC | sed "s,hp[']\/[>],,;s,\ ,," >HP 2>/dev/null

        # Extrai a vida do inimigo
        grep -o -E "(nbsp)[^A-Za-z0-9_]{1,2}[0-9]{1,6}" "$TMP"/SRC | sed -n 's,nbsp[;],,;s,\ ,,;1p' >HP2 2>/dev/null

        # Calcula a saúde ajustada para ataque baseado no HP atual
        RHP=$(awk -v ush="$(cat HP)" -v rper="$RPER" 'BEGIN { printf "%.0f", ush * rper / 100 + ush }')

        # Calcula a saúde ajustada para cura baseado no HP total
        HLHP=$(awk -v ush="$(cat FULL)" -v hper="$HPER" 'BEGIN { printf "%.0f", ush * hper / 100 }')

        # Verifica se há URLs de esquiva
        if grep -q -o '/dodge/' "$TMP"/SRC ; then
            printf "\n     🙇‍ "  # Exibe emoji de esquiva
            w3m -dump -T text/html "$TMP/SRC" | head -n 18 | sed '0,/^\([a-z]\{2\}\)[[:space:]]\([0-9]\{1,6\}\)\([0-9]\{2\}\):\([0-9]\{2\}\)/s//\♥️\2 ⏰\3:\4/;s,\[0\],\🔴,g;s,\[1\]\ ,\🔵,g;s,\[king\],👑,g;s,\[stone\],\ 💪,;s,\[herb\],\ 🌿,;s,\[grass\],\ 🌿,g;s,\[potio\],\ 💊,;s,\ \[health\]\ ,\ 🧡,;s,\ \[icon\]\ ,\ 🐾,g;s,\[rip\]\ ,\ 💀,g'  # Formata a saída
        else
            # Faz a requisição para a página principal do rei
            fetch_page "/king" "$TMP/SRC"

            # Procura o link de ataque ao rei e processa a batalha
            grep -o -E '(/king/unrip/[^A-Za-z0-9_]r[^A-Za-z0-9_][0-9]+)' "$TMP"/SRC >UNRIP 2>/dev/null
            if grep -q -o -E '(/king/unrip/[^A-Za-z0-9_]r[^A-Za-z0-9_][0-9]+)' "$TMP"/SRC; then
                fetch_page "$(cat UNRIP)" "$TMP/SRC"
            else
                echo 1 >BREAK_LOOP
                echo_t "Battle is over!" "${RED_BLACK}" "${COLOR_RESET}" "after" "⚔️\n"
                sleep 3s
            fi
        fi
    }
# Executa a função cl_access para preparar os links necessários
cl_access

# Salva o HP atual no arquivo "old_HP" para comparação posterior
cat HP >old_HP

# Inicializa os timestamps para esquiva, cura e ataque com valores passados
echo $(( $(date +%s) - 20 )) >last_dodge
echo $(( $(date +%s) - 90 )) >last_heal
echo $(( $(date +%s) - LA )) >last_atk

# Cria ou limpa o arquivo BREAK_LOOP para controle do loop
: >BREAK_LOOP

# Loop principal até que o arquivo "BREAK_LOOP" contenha dados
until [ -s "BREAK_LOOP" ]; do
  : >BREAK_LOOP  # Limpa o arquivo BREAK_LOOP a cada iteração

    # Calcula o tempo restante para o próximo ataque e aguarda
    current_time=$(date +%s)
    last_attack_time=$(cat last_atk)
    sleep_time=$(( LA - (current_time - last_attack_time) ))
    if [ "$sleep_time" -gt 0 ]; then
        sleep "$sleep_time"
    fi

    # Verifica se o HP2 é menor ou igual a 3 para controlar os ataques ao rei
    if [ "${HP2:-0}" -le 3 ]; then
        while [ "${HP2:-0}" -gt 2 ]; do
            fetch_page "/king" "$TMP/SRC"
            cl_access
            sleep 1
        done
    fi

    # Verifica se é possível executar uma esquiva
    if ! grep -q -o 'txt smpl grey' "$TMP"/SRC && \
       [ "$(( $(date +%s) - $(cat last_dodge) ))" -gt 20 ] && \
       [ "$(( $(date +%s) - $(cat last_dodge) ))" -lt 300 ] && \
       awk -v ush="$(cat HP)" -v oldhp="$(cat old_HP)" 'BEGIN { exit !(ush < oldhp) }'; then
        # Realiza a esquiva
        fetch_page "$(cat DODGE)" "$TMP/SRC"
        cl_access
        cat HP >old_HP  # Atualiza o HP antigo
        date +%s >last_dodge  # Atualiza o tempo da última esquiva

    # Verifica se é possível executar uma cura
    elif awk -v ush="$(cat HP)" -v hlhp="$HLHP" 'BEGIN { exit !(ush < hlhp) }' && \
         [ "$(( $(date +%s) - $(cat last_heal) ))" -gt 90 ] && \
         [ "$(( $(date +%s) - $(cat last_heal) ))" -lt 300 ]; then
        # Realiza a cura
        fetch_page "$(cat HEAL)" "$TMP/SRC"
        cl_access
        cat HP >FULL  # Atualiza o HP total
        date +%s >last_heal  # Atualiza o tempo da última cura
        sleep 0.2s  # Pequena pausa antes de continuar

    # Verifica se é possível realizar um ataque
    elif awk -v latk="$(( $(date +%s) - $(cat last_atk) ))" -v atktime="$LA" 'BEGIN { exit !(latk > atktime) }'; then
        # Caso exista um link de ataque ao rei
        if grep -q -o -E '(king/kingatk/[^A-Za-z0-9_]r[^A-Za-z0-9_][0-9]+)' "$TMP"/SRC; then
            fetch_page "$(cat KINGATK)" "$TMP/SRC"
            cl_access

            # Verifica se deve usar pedra
            if awk -v ush="$(cat HP2)" 'BEGIN { exit !(ush < 25) }'; then
                fetch_page "$(cat STONE)" "$TMP/SRC"
                cl_access
            fi
        else
            # Realiza um ataque aleatório, se aplicável
            if awk -v latk="$(( $(date +%s) - $(cat last_atk) ))" -v atktime="$LA" 'BEGIN { exit !(latk != atktime) }' && \
               ! grep -q -o 'txt smpl grey' "$TMP"/SRC && \
               awk -v rhp="$RHP" -v enh="$(cat HP2)" 'BEGIN { exit !(rhp < enh) }' || \
               awk -v latk="$(( $(date +%s) - $(cat last_atk) ))" -v atktime="$LA" 'BEGIN { exit !(latk != atktime) }' && \
               ! grep -q -o 'txt smpl grey' "$TMP"/SRC && \
               grep -q -o "$(cat USER)" allies.txt; then
                fetch_page "$(cat ATKRND)" "$TMP/SRC"
                cl_access
                date +%s >last_atk  # Atualiza o tempo do último ataque
            fi
            # Realiza um ataque padrão
            fetch_page "$(cat ATK)" "$TMP/SRC"
            cl_access
        fi
        date +%s >last_atk  # Atualiza o tempo do último ataque

    # Atualiza a página do rei para verificar novos estados
    else
        fetch_page "/king" "$src_ram"
        cl_access
        sleep 1s  # Aguarda 1 segundo antes da próxima verificação
    fi
done

# Finaliza o loop principal, limpando e aplicando eventos
unset cl_access
func_unset
apply_event

# Mensagem final ao jogador
echo_t "King of the Immortals" "${RED_BLACK} 👑" "${COLOR_RESET}" "after" "✅"

# Pausa final antes de limpar a tela
sleep 10s
clear
}

king_start () {
 case $(date +%H:%M) in
 (12:2[5-9]|16:2[5-9]|22:2[5-9])
  (
   w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "$URL/train" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)"|grep -o -E '\(([0-9]+)\)'|sed 's/[()]//g' >"$TMP"/FULL
  ) </dev/null &>/dev/null &
  time_exit 17
  (
   w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "$URL/king/enterGame" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
  ) </dev/null &>/dev/null &
  time_exit 17
  echo_t "King of the Immortals will be started..." "${GOLD_BLACK}" "${COLOR_RESET}" "before" "👑"
  until (case $(date +%M) in (2[5-9]) exit 1 ;; esac) ; do
   sleep 2
  done
  (
   w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "$URL/king/enterGame" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
  ) </dev/null &>/dev/null &
  time_exit 17
  printf "\nKing\n$URL\n"
  grep -o -E '(/[a-z]+(/[a-z]+/[^A-Za-z0-9]r[^A-Za-z0-9][0-9]+|/))' "$TMP"/SRC | sed -n '1p' >ACCESS 2>/dev/null
  #cat "$TMP"/SRC|sed 's/href=/\n/g'|grep '/king/'|head -n 1|awk -F"[']" '{ print $2 }' >ACCESS 2> /dev/null
  printf_t " Entering..." "" "$(cat ACCESS)" "before" "👣"
  #/wait
  echo_t " Waiting..." "" "" "before" "💤"
  cat < "$TMP"/SRC|grep -o 'king/kingatk/' >EXIT 2> /dev/null
  local BREAK=$(( $(date +%s) + 30 ))
  until [ -s "EXIT" ] || [ "$(date +%s)" -gt "$BREAK" ] ; do
   printf " 💤	...\n$(cat ACCESS)\n"
   (
    w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}$(cat ACCESS)" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
   ) </dev/null &>/dev/null &
   time_exit 17
   cat < "$TMP"/SRC | sed 's/href=/\n/g'|grep '/king/'|head -n 1|awk -F"[']" '{ print $2 }' >ACCESS 2> /dev/null
   cat < "$TMP"/SRC | grep -o 'king/kingatk/' >EXIT 2> /dev/null
   sleep 2
  done
  king_fight
  ;;
 esac
}
