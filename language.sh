#!/bin/bash

# Nome do arquivo de traduções
TRANSLATIONS_FILE="$HOME/twm/translations.po"

# Declarando os idiomas disponíveis para referência
# shellcheck disable=SC2034
declare -A LANGUAGES=(
    [de]="Deutsch" [en]="English" [es]="Español" [fr]="Français"
    [hi]="Hindi" [id]="Indonesian" [it]="Italiano" [pl]="Polski"
    [pt]="Português" [ro]="Română" [ru]="Русский" [sr]="Srpski" [zh]="中文"
)

# Função para traduzir usando a API
get_translation() {
    local target="$1" text="$2"
    local url="https://translate.disroot.org/translate"
    local data='{"q":"'"${text}"'","source":"'"${SOURCE}"'","target":"'"${target}"'","format":"text","alternatives":0,"api_key":""}'
    curl -s -X POST "$url" -H "Content-Type: application/json" -d "$data" | jq -r '.translatedText // empty'
}

# Função para carregar traduções do arquivo
load_translations() {
    declare -g -A translations  # Declarar um array associativo global

    if [ -f "$TRANSLATIONS_FILE" ]; then
        while IFS="|" read -r original translated; do
            original=$(echo "$original" | xargs)
            translated=$(echo "$translated" | xargs)
            translations["$original"]="$translated"
        done < "$TRANSLATIONS_FILE"
    fi
}

# Função para traduzir e armazenar em cache
translate_and_cache() {
    local target_lang="$1"
    local text="$2"

    text=$(echo "$text" | xargs)

    # DETECTAR SE É TEXTO DO function.sh
    is_func=""
    if [[ "$text" == __FUNC__* ]]; then
        is_func="yes"
        text="${text#__FUNC__ }"   # Remove o marcador
    fi

    # Se o idioma for inglês retorna sem traduzir
    if [ "$target_lang" = "en" ]; then
        echo "$text"
        return
    fi

    # DETECTAR PREFIXO EX: A- B- C- 0- X-
    prefix=""
    rest="$text"

    if [ "$is_func" = "yes" ]; then
        if [[ "$text" =~ ^([^[:space:]]+-)[[:space:]]*(.*)$ ]]; then
    prefix="${BASH_REMATCH[1]} "
    rest="$(echo "${BASH_REMATCH[2]}" | xargs)"
        fi
    fi

    #
    # TENTAR PEGAR DO CACHE
    #
    translated_text=$(grep "^${text}|" "$TRANSLATIONS_FILE" | tail -n 1 | cut -d'|' -f2-)

    if [ -n "$translated_text" ]; then
        echo "$translated_text"
        return
    fi

    #
    # REALIZAR TRADUÇÃO
    #
    if [ -n "$prefix" ]; then
        raw_translation=$(get_translation "$target_lang" "$rest")
        translated_text="${prefix}${raw_translation}"
    else
        translated_text=$(get_translation "$target_lang" "$text")
    fi

    #
    # SE FALHAR A TRADUÇÃO, RETORNA TEXTO ORIGINAL
    #
    if [ -z "$translated_text" ]; then
        echo "$text"
        return
    fi

    #
    # SALVAR NO CACHE
    #
    echo "${text}|${translated_text}" >> "$TRANSLATIONS_FILE"

    echo "$translated_text"
}

# Inicializar
load_translations

# Exemplo de uso
SOURCE="en"
#echo -e "$(translate_and_cache "$LANGUAGE" "Hello world!")"
#echo -e "$(translate_and_cache "$LANGUAGE" "Enter a command or type \*list\*:")"
#echo -e "$(translate_and_cache "$LANGUAGE" "No battles now, waiting 0s")"
#echo -e "$(translate_and_cache "$LANGUAGE" "No battles now, waiting 45s")"
#echo -e "${BLACK_YELLOW}$(translate_and_cache "$LANGUAGE" "[Wait to *$ACC*... (${check}s) - press ENTER to change account]")${COLOR_RESET}" //this is case we have variable and colour
