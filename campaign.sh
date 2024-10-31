campaign_func() {
    echo_t "Campaign " "$GOLD_BLACK" "$COLOR_RESET" "after" "⛺"
    fetch_page "/campaign/"

    if grep -q -o -E '/campaign/(go|fight|attack|end)/[?]r[=][0-9]+' "$TMP/SRC"; then
        local CAMPAIGN
        CAMPAIGN=$(grep -o -E '/campaign/(go|fight|attack|end)/[?]r[=][0-9]+' "$TMP/SRC" | head -n 1)
        local BREAK=$(( $(date +%s) + 90 ))

        while [ -n "$CAMPAIGN" ] && [ "$(date +%s)" -lt "$BREAK" ]; do
            case $CAMPAIGN in
                (*go* | *fight* | *attack* | *end*)
                    fetch_page "$CAMPAIGN"
                    
                    RESULT=$(echo "$CAMPAIGN" | cut -d'/' -f3)
                    echo_t "Campaign -> $RESULT !"
                    
                    CAMPAIGN=$(grep -o -E '/campaign/(go|fight|attack|end)/[?]r[=][0-9]+' "$TMP/SRC" | head -n 1)
                    ;;
            esac
        done
    fi
    echo_t "Campaign " "$GREEN_BLACK" "$COLOR_RESET" "after" "✅\n"
}
