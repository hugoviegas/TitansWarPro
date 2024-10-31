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
            # Remover espaços extras
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

    # Remover espaços extras no texto original
    text=$(echo "$text" | xargs)

    # Se o idioma for inglês, não traduzir e retornar o texto original
    if [ "$target_lang" = "en" ]; then
        echo "$text"
        return
    fi

    # Verificar se já existe a tradução usando o texto original
    if grep -q "^$text|" "$TRANSLATIONS_FILE"; then
        # Se a tradução existir, obtê-la do arquivo
        translated_text=$(grep "^$text|" "$TRANSLATIONS_FILE" | cut -d'|' -f2-)
        echo "$translated_text"
    else
        # Se não existe, traduzir
        translated_text=$(get_translation "$target_lang" "$text")

        # Verificar se a tradução foi bem-sucedida
        if [ -n "$translated_text" ]; then
            translations["$text"]="$translated_text"
            # Salvar no arquivo, removendo espaços
            echo "$text|$translated_text" >> "$TRANSLATIONS_FILE"
            echo "$translated_text"
        else
            echo "$text"  # Retornar o texto original se a tradução falhar
        fi
    fi
}

# Inicializar
load_translations

# Exemplo de uso
SOURCE="en"
#echo -e "$(translate_and_cache "pt" "Hello world!")"
#echo -e "$(translate_and_cache "pt" "Enter a command or type 'list'")"
#echo -e "$(translate_and_cache "pt" "No battles now, waiting 0s")"
#echo -e "$(translate_and_cache "pt" "No battles now, waiting 45s")"
