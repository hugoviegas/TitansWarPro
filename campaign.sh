campaign_func() {
    echo -e "${GOLD_BLACK}Campaign ⛺${COLOR_RESET}"
    fetch_page "/campaign/"
    if grep -q -o -E '/campaign/(go|fight|attack|end)/[?]r[=][0-9]+' $TMP/SRC; then
        local CAMPAIGN
        CAMPAIGN=$(grep -o -E '/campaign/(go|fight|attack|end)/[?]r[=][0-9]+' $TMP/SRC | head -n 1)
        local BREAK=$(($(date +%s) + 90))
        while [ -n "$CAMPAIGN" ] && [ "$(date +%s)" -lt "$BREAK" ]; do
            case $CAMPAIGN in
            (*go* | *fight* | *attack* | *end*)
                fetch_page "$CAMPAIGN"
                
                RESULT=$(echo "$CAMPAIGN" | cut -d'/' -f3)
                echo " Campaign -> $RESULT !"
                CAMPAIGN=$(grep -o -E '/campaign/(go|fight|attack|end)/[?]r[=][0-9]+' $TMP/SRC | head -n 1)
                ;;
            esac
        done
    fi
    echo -e "${GREEN_BLACK}Campaign ✅${COLOR_RESET}\n"
}
