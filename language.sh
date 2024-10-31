#!/bin/bash

# Script Name: create_language_po.sh
# This script facilitates the creation of a .po file for translations using the Disroot API.

# Supported language codes and their names
declare -A LANGUAGES=(
    [de]="Deutsch" [en]="English" [es]="Español" [fr]="Français"
    [hi]="Hindi" [id]="Indonesian" [it]="Italiano" [pl]="Polski"
    [pt]="Português" [ro]="Română" [ru]="Русский" [sr]="Srpski" [zh]="中文"
)

SOURCE="en"  # Source language set to English
PO_FILE="$HOME/twm/LANGUAGE.po"

# Function to make API call and get translation
get_translation() {
    local text="$1" target="$2"
    local url="https://translate.disroot.org/translate"
    local data='{"q":"'"${text}"'","source":"'"${SOURCE}"'","target":"'"${target}"'","format":"text","alternatives":0,"api_key":""}'
    curl -s -X POST "$url" -H "Content-Type: application/json" -d "$data" | 
        jq -r '.translatedText // empty'
}

# Clear the terminal screen
clear

# Prompt user for input
read -p "Enter text in English: " TRANSLATE
TRANSLATE=${TRANSLATE:-'Hello world!'}  # Default if empty

# Translate to all target languages
TRANSLATIONS=""
for lang in "${!LANGUAGES[@]}"; do
    echo "Translating ${LANGUAGES[$lang]}"
    translation=$(get_translation "$TRANSLATE" "$lang")
    TRANSLATIONS+="${translation}|"
done

# Remove trailing pipe and display translations
echo -e "\n${TRANSLATIONS%|}"

# Prompt user for action
read -p $'\nSave to '"$PO_FILE"$'?\n(y) Save\n(n) Don\'t save\n(e) Edit manually\nChoice: ' -n 1 var

case ${var,,} in
    y|s) echo "${TRANSLATIONS%|}" >> "$PO_FILE" ;;
    e|m) nano "$PO_FILE" ;;
    *) exit 0 ;;
esac

# Function to get translation from PO file
gettext() {
    local lang="$1" text="$2"
    awk -v lang="$lang" -v text="$text" '
    BEGIN {FS=OFS="|"}
    NR==1 {
        for (i=1; i<=NF; i++) {
            idx[tolower($i)] = i
        }
    }
    NR>1 && $1 == text {
        print $(idx[lang])
        exit
    }
    ' "$PO_FILE"
}

# Example usage
echo -e "$(gettext "pt" "Installing TWM...")"