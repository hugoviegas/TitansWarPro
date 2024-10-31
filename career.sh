career_func() {
  echo_t "Career " "$GOLD_BLACK" "$COLOR_RESET" "after" " 🎖️"
    fetch_page "/career/"
    
    if grep -q -o -E '/career/attack/[?]r[=][0-9]+' "$TMP/SRC"; then
        checkQuest 6 apply
        
        fetch_page "/career/"
        
        if grep -q -o -E '/career/(attack|take)/[?]r[=][0-9]+' "$TMP/SRC"; then
            local CAREER
            CAREER=$(grep -o -E '/career/(attack|take)/[?]r[=][0-9]+' "$TMP/SRC")
            local BREAK=$(( $(date +%s) + 60 ))
            
            while [ -n "$CAREER" ] && [ "$(date +%s)" -lt "$BREAK" ]; do
                case $CAREER in
                    (*attack*|*take*)
                        fetch_page "$CAREER"
                        RESULT=$(echo "$CAREER" | cut -d'/' -f3)
                        echo_t "Career -> $RESULT !" "$COLOR_RESET" "" "before" ""
                        
                        sleep 0.5s
                        CAREER=$(grep -o -E '/career/(attack|take)/[?]r[=][0-9]+' "$TMP/SRC" | sed -n '1p')
                        ;;
                esac
            done
        fi

        checkQuest 6 end
    fi
    
    echo_t "Career " "$GREEN_BLACK" "$COLOR_RESET" "after" " ✅\n"
    return 0
}
