campaign_func() {
    echo -e "${GOLD_BLACK}Campaign ⛺${COLOR_RESET}"

    fetch_page "${URL}/campaign/"

    if grep -q -o -E '/campaign/(go|fight|attack|end)/[?]r[=][0-9]+' "$TMP/SRC"; then
        local CAMPAIGN=$(grep -o -E '/campaign/(go|fight|attack|end)/[?]r[=][0-9]+' "$TMP/SRC" | head -n 1)
        local BREAK=$(($(date +%s) + 60))

        while [ -n "$CAMPAIGN" ] && [ "$(date +%s)" -lt "$BREAK" ]; do
            case $CAMPAIGN in
            *go* | *fight* | *attack* | *end*)
                # Fetch the specific campaign action page
                fetch_page "${URL}$CAMPAIGN"

                RESULT=$(echo "$CAMPAIGN" | cut -d'/' -f3)
                echo " Campaign -> $RESULT !"

                # Fetch the next available campaign action link
                CAMPAIGN=$(grep -o -E '/campaign/(go|fight|attack|end)/[?]r[=][0-9]+' "$TMP/SRC" | head -n 1)
                ;;
            esac
        done
    fi
    echo -e "${GREEN_BLACK}Campaign ✅${COLOR_RESET}\n"
}
