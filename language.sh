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
    local SOURCE="en"  # Source language set to English
    local target="$1" text="$2"
    local url="https://translate.disroot.org/translate"
    local data='{"q":"'"${text}"'","source":"'"${SOURCE}"'","target":"'"${target}"'","format":"text","alternatives":0,"api_key":""}'
    curl -s -X POST "$url" -H "Content-Type: application/json" -d "$data" | 
        jq -r '.translatedText // empty'
}

# Function to prompt user for text input
get_user_input() {
    clear
    read -r -p "Enter text in English: " TRANSLATE
    TRANSLATE=${TRANSLATE:-'Hello world!'}  # Default if empty
}

# Function to perform translations for all target languages
translate_text() {
    TRANSLATIONS=""
    for lang in "${!LANGUAGES[@]}"; do
        echo "Translating ${LANGUAGES[$lang]}"
        translation=$(get_translation "$lang" "$TRANSLATE")
        TRANSLATIONS+="${translation}|"
    done
    echo -e "\n${TRANSLATIONS%|}"  # Display translations without trailing pipe
}

# Function to save translations to the .po file or edit manually
save_or_edit_translations() {
    read -p $'\nSave to '"$PO_FILE"$'?\n(y) Save\n(n) Don\'t save\n(e) Edit manually\nChoice: ' -n 1 var
    case ${var,,} in
        y|s) echo "${TRANSLATIONS%|}" >> "$PO_FILE" ;;
        e|m) nano "$PO_FILE" ;;
        *) exit 0 ;;
    esac
}

# Function to get translation from the .po file
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

# Main function to run the full script process
main() {
    get_user_input       # Step 1: Get user text input
    translate_text       # Step 2: Translate text to all languages
    echo -e "$(get_translation "pt" "Installing TWM...")"
    save_or_edit_translations  # Step 3: Save or edit translations
    # Example usage for gettext function (optional, for testing)
    echo -e "$(gettext "pt" "Installing TWM...")"
    
}

# Run the main function
#main
