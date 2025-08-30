# Variável global para controlar a saída dos loops
EXIT_CONFIG="n"

# --- Compatibility shim -------------------------------------------------
# Provide sane defaults so beta/master mixed code paths don't fail when
# SHARE_DIR, INSTALL_DIR, TMP or CONFIG_FILE are not set.
: ${SHARE_DIR:="$HOME/twm"}
: ${INSTALL_DIR:="${INSTALL_DIR:-$SHARE_DIR}"}
: ${TMP:="${TMP:-$SHARE_DIR/tmp}"}
: ${CONFIG_FILE:="${CONFIG_FILE:-$SHARE_DIR/config.cfg}"}

# Backwards-compatible accessors for config values. Some beta changes
# removed get_config/set_config; provide minimal implementations so other
# scripts keep working until we refactor everything consistently.
get_config() {
    local key="$1"
    if [ -f "$CONFIG_FILE" ]; then
        # shellcheck disable=SC1090
        . "$CONFIG_FILE" 2>/dev/null || true
    fi
    # Print the variable value (may be empty)
    printf '%s' "${!key}"
}

set_config() {
    local key="$1"
    local value="$2"
    mkdir -p "$(dirname "$CONFIG_FILE")" 2>/dev/null || true
    # Remove any existing entry for the key (if file exists), then append
    if [ -f "$CONFIG_FILE" ]; then
        grep -v -E "^${key}=" "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" 2>/dev/null || true
        mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE" 2>/dev/null || true
    fi
    printf '%s=%s\n' "$key" "$value" >> "$CONFIG_FILE"
}

# ------------------------------------------------------------------------

update_config() {
    local key="$1"      # Nome da configuração a ser alterada
    local value="$2"    # Novo valor para a configuração

    # Verifica se a chave existe no arquivo config.cfg
    if grep -q "^${key}=" "$CONFIG_FILE"; then
        # Atualiza o valor no config.cfg usando sed para substituição
        sed -i "s/^${key}=.*/${key}=${value}/" "$CONFIG_FILE"
        echo "Configuração $key atualizada para $value."
    else
        echo "Configuração $key não encontrada no arquivo config.cfg."
        return 1  # Retorna um erro para indicar falha
    fi
}

# Função para solicitar chave e valor, e chamar update_config com validação
request_update() {
    local key value success=1  # Inicializa success com 1 (falha)

    while [ "$success" -ne 0 ]; do
        # Instruções para o usuário
        echo -e "  Configurações do macro, lista de alterações para modificar\n Digite o comando exatamente como escrito\n 1- reliquias\n 2- elixir\n sair"
        echo "Digite o nome da configuração que deseja alterar (ou digite ' ' ou 'sair' para sair): "
        read -r key

        case $key in
            (reliquias)
            echo "Deseja recolher as reliquias (s ou n):"
            read -r value
            key="FUNC_rewards"
            ;;
            (elixir)
            echo "Deseja usar elixir antes de todos os vales? (s ou n):"
            read -r value
            key="FUNC_elixir"
            ;;
            (sair|*)
            echo "Saindo do modo de atualização de configurações."
            EXIT_CONFIG="s"  # Sinaliza para sair de ambos os loops
            break
            ;;
        esac

        # Chama a função de atualização de configuração e captura o status
        update_config "$key" "$value"
        success=$?

        # Verifica se houve falha e notifica o usuário
        if [ "$success" -ne 0 ]; then
            echo "Chave inválida. Tente novamente."
        else
            echo "Configuração atualizada com sucesso!"
            config
            break
        fi
    done
}

# Função para carregar as configurações do arquivo config.cfg
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        . "$CONFIG_FILE"  # Carrega o arquivo de configuração
    else
        echo "Arquivo de configuração não encontrado. Criando config.cfg com valores padrão."
        
        # Define valores padrão
        FUNC_rewards="s"
        FUNC_elixir="s"
        FUNC_coliseum="n"
        SCRIPT_PAUSED="n"

        # Escreve o arquivo config.cfg com os valores padrão
        {
            echo "FUNC_rewards=$FUNC_rewards"
            echo "FUNC_elixir=$FUNC_elixir"
            echo "FUNC_coliseum=$FUNC_coliseum"
            echo "SCRIPT_PAUSED=$SCRIPT_PAUSED"
        } > "$CONFIG_FILE"
    fi
}

config() {
    # Carrega a configuração inicial
    CONFIG_FILE="$TMP/config.txt"
    load_config
    SCRIPT_PAUSED="s"

    # Loop principal do script
    while true; do
        # Verifica se o script está pausado ou se foi sinalizado para sair
        if [ "$SCRIPT_PAUSED" = "s" ] || [ "$EXIT_CONFIG" = "s" ]; then
            echo "Script pausado. Aguardando reativação..."
            sleep 2
            load_config  # Recarrega a configuração após o intervalo

            # Se EXIT_CONFIG estiver em "s", sai do loop principal
            if [ "$EXIT_CONFIG" = "s" ]; then
                echo "Saindo do modo de configuração..."
                EXIT_CONFIG="n"  # Reseta o sinal de saída para o próximo uso
                break
            fi

            # Prompt para alterar configurações durante a execução
            echo -e "\nDeseja alterar alguma configuração? (s/n)"
            read -r alterar
        fi

        if [ "$alterar" = "s" ]; then
            # Chama a função para solicitar atualização com verificação de chave
            request_update

            # Se EXIT_CONFIG estiver em "s", sai do loop principal
            if [ "$EXIT_CONFIG" = "s" ]; then
                echo "Saindo do modo de configuração..."
                EXIT_CONFIG="n"  # Reseta o sinal de saída para o próximo uso
                break
            fi

            # Recarrega as configurações após a atualização
            load_config
        else
            SCRIPT_PAUSED="n"
            break
        fi

        # Intervalo antes de reiniciar o loop
        sleep 30
    done
}

testColour() {
   echo -e "${BLACK_BLACK}BLACK_BLACK${COLOR_RESET}\n"
   echo -e "${BLACK_CYAN}BLACK_CYAN${COLOR_RESET}\n"
   echo -e "${BLACK_GREEN}BLACK_GREEN${COLOR_RESET}\n"
   echo -e "${BLACK_GRAY}BLACK_GRAY${COLOR_RESET}\n"
   echo -e "${BLACK_PINK}BLACK_PINK${COLOR_RESET}\n"
   echo -e "${BLACK_RED}BLACK_RED${COLOR_RESET}\n"
   echo -e "${CYAN_BLACK}CYAN_BLACK${COLOR_RESET}\n"
   echo -e "${BLACK_YELLOW}BLACK_YELLOW${COLOR_RESET}\n"
   echo -e "${CYAN_CYAN}CYAN_CYAN${COLOR_RESET}\n"
   echo -e "${GOLD_BLACK}GOLD_BLACK${COLOR_RESET}\n"
   echo -e "${GREEN_BLACK}GREEN_BLACK${COLOR_RESET}\n"
   echo -e "${PURPLEi_BLACK}PURPLEi_BLACK${COLOR_RESET}\n"
   echo -e "${PURPLEis_BLACK}PURPLEis_BLACK${COLOR_RESET}\n"
   echo -e "${WHITE_BLACK}WHITE_BLACK${COLOR_RESET}\n"
   echo -e "${WHITEb_BLACK}WHITEb_BLACK${COLOR_RESET}\n"
   echo -e "${RED_BLACK}RED_BLACK${COLOR_RESET}\n"
   echo -e "${BLUE_BLACK}BLUE_BLACK${COLOR_RESET}\n"
   sleep 30s
}
