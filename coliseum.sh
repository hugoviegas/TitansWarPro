# shellcheck disable=SC2155
coliseum_fight() {
    if [ -d "/dev/shm" ]; then
        local dir_ram="/dev/shm/"
    else
        local dir_ram="$PREFIX/tmp/"
    fi
    mkdir -p "$dir_ram"
    src_ram=$(mktemp -p "$dir_ram" data.XXXXXX)
    full_ram=$(mktemp -p "$dir_ram" data.XXXXXX)
    tmp_ram=$(mktemp -d -t twmdir.XXXXXX)
    cp -r "$TMP"/* "$tmp_ram"
    cd "$tmp_ram" || exit
    (
        w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "$URL/train" -o user_agent="$(shuf -n1 userAgent.txt)" | grep -o -E '\(([0-9]+)\)' | sed 's/[()]//g' >"$full_ram"
    ) &
    time_exit 20
    #/enterFight
    local LA=4    #2.Interval attack
    local HPER=38 #3.HPER % to heal
    local RPER=5  #4.RPER % to random
    echo_t "Coliseum" "${GOLD_BLACK}" "${COLOR_RESET}" "after" "🧱"
    (
        w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug "$URL"/settings/graphics/0 -o user_agent="$(shuf -n1 userAgent.txt)" >"$src_ram"
    ) </dev/null &>/dev/null &
    time_exit 17
    # printf "/settings/graphics/0\n"
    (
        w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "$URL/coliseum" -o user_agent="$(shuf -n1 userAgent.txt)" >"$src_ram"
    ) </dev/null &>/dev/null &
    time_exit 17
    if grep -q -o '?end_fight' "$src_ram"; then
        (
            w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug "$URL/coliseum/?end_fight=true" -o user_agent="$(shuf -n1 userAgent.txt)" | head -n 11 | tail -n 7 | sed "/\[2hit/d;/\[str/d;/combat/d"
        ) </dev/null &>/dev/null &
        time_exit 17
        # printf "/coliseum/?end_fight=true\n"
        (
            w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "$URL/coliseum" -o user_agent="$(shuf -n1 userAgent.txt)" >"$src_ram"
        ) </dev/null &>/dev/null &
        time_exit 17
    fi
    
    local access_link=$(grep -o -E '/coliseum(/[A-Za-z]+/[?]r[=][0-9]+|/)' "$src_ram" | sed -n '1p' | cat -)
    local go_stop=$(grep -o -E '/coliseum/enterFight/[?]r[=][0-9]+' "$src_ram" | cat -)
    if [ -n "$go_stop" ]; then
        echo_t "  Entering..." "" "\n" "before" "🤺"
        (
            w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}${go_stop}" -o user_agent="$(shuf -n1 userAgent.txt)" >"$src_ram"
        ) </dev/null &>/dev/null &
        time_exit 17
        local access_link=$(grep -o -E '/coliseum(/[A-Za-z]+/[?]r[=][0-9]+|/)' "$src_ram" | grep -v 'dodge' | sed -n 1p | cat -)
        #/wait
        echo_t " Preparing for battle, waiting for other players..." "" "\n" "before" "😠"


        local first_time=$(date +%s) #6
        until grep -q -o 'coliseum/dodge/' "$src_ram" || awk -v ltime="(($(date +%s) - $first_time))" 'BEGIN { exit !(ltime > 30) }'; do
            (
                w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}$access_link" -o user_agent="$(shuf -n1 userAgent.txt)" >"$src_ram"
            ) </dev/null &>/dev/null &
            time_exit 17
            local access_link=$(grep -o -E '/(coliseum/[A-Za-z]+/[?]r[=][0-9]+|coliseum)' "$src_ram" | grep -v 'dodge' | sed -n 1p) #5
            echo_t " 	Preparing..." "" "\n" "before" "😡"
            sleep 3s
        done
        cl_access() {
            last_heal=$(($(date +%s) - 90)) 
            last_dodge=$(($(date +%s) - 20)) # 9.last_dodge
            last_atk=$(($(date +%s) - LA)) # 10.last_atk
            USH=$(grep -o -E '(hp)[^A-z0-9]{1,4}[0-9]{2,5}' "$src_ram" | grep -o -E '[0-9]{2,5}' | sed 's,\ ,,g') #11.USH
            ENH=$(grep -o -E '(nbsp)[^A-Za-z0-9]{1,2}[0-9]{1,6}' "$src_ram" | sed -n 's,nbsp[;],,;s,\ ,,;1p') #12.ENH
            USER=$(grep -o -E '([[:upper:]][[:lower:]]{0,15}( [[:upper:]][[:lower:]]{0,13})?)[[:space:]][^[:alnum:]]s' "$src_ram" | sed -n 's,\ [<]s,,;s,\ ,_,;2p') #13.USER
            ATK=$(grep -o -E '/coliseum/atk/[?]r[=][0-9]+' "$src_ram" | sed -n 1p) #14.ATK
            ATKRND=$(grep -o -E '/coliseum/atkrnd/[?]r[=][0-9]+' "$src_ram") #15.ATKRND
            DODGE=$(grep -o -E '/coliseum/dodge/[?]r[=][0-9]+' "$src_ram") #16.DODGE
            HEAL=$(grep -o -E '/coliseum/heal/[?]r[=][0-9]+' "$src_ram") #17.HEAL
            RHP=$(awk -v ush="$USH" -v rper="$RPER" 'BEGIN { printf "%.0f", ush * rper / 100 + ush }')
            HLHP=$(awk -v ush="$(cat "$full_ram")" -v hper="$HPER" 'BEGIN { printf "%.0f", ush * hper / 100 }')
            if grep -q -o '/dodge/' "$src_ram"; then # Exibe batalha se houver link de esquiva...
                printf "\n     🤺‍ "
                w3m -dump -T text/html "$src_ram" | head -n 18 | sed '0,/^\([a-z]\{2\}\)[[:space:]]\([0-9]\{2,5\}\)\([0-9]\{2\}\):\([0-9]\{2\}\)/s//\♥️\2 ⏰\3:\4/;s,\[0\]\ ,\🔴,g;s,\[1\]\ ,\🔵,g;s,\[stone\],\ \n🪨,;s,\[herb\],\ 🌿,;s,\[grass\],\ 🌿,g;s,\[potio\],\ 💊,;s,\ \[health\]\ ,\ 🧡,;s,\ \[icon\]\ ,\ 🐾,g;s,\[rip\],\ 💀,g'
                #    time_exit 17
            else #...exibiu || aguarda ou finaliza...
                if grep -q -o '?end_fight=true' "$src_ram"; then # aguarda como expectador...
                    if awk -v ltime="(($(date +%s) - $first_time))" 'BEGIN { exit !(ltime < 300) }'; then # se passar 300s...
                        (
                            w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}/coliseum" -o user_agent="$(shuf -n1 userAgent.txt)" >"$src_ram"
                        ) </dev/null &>/dev/null &
                        time_exit 17
                        printf "\n     🤺‍ "
                        w3m -dump -T text/html "$src_ram" | head -n 18 | sed '0,/^\([a-z]\{2\}\)[[:space:]]\([0-9]\{2,5\}\)\([0-9]\{2\}\):\([0-9]\{2\}\)/s//\♥️\2 ⏰\3:\4/;s,\[0\]\ ,\🔴,g;s,\[1\]\ ,\🔵,g;s,\[stone\],\ \n🪨,;s,\[herb\],\ 🌿,;s,\[grass\],\ 🌿,g;s,\[potio\],\ 💊,;s,\ \[health\]\ ,\ 🧡,;s,\ \[icon\]\ ,\ 🐾,g;s,\[rip\],\ 💀,g'
                        #      time_exit 17
                    fi #...passou 300s
                else   #...cessa espera || finaliza...
                    BREAK_LOOP=1
                    echo_t "Battle over." "${RED_BLACK}" "${COLOR_RESET}"
                    sleep 2s
                fi #...finalizou a batalha
            fi     #...cessou procura por esquiva
        }          #...fecha a função
        cl_access
        local OLDHP=$USH #18.OLDHP
        BREAK_LOOP=""
        local first_time=$(date +%s) #7.last_time
    until [[ -n "$BREAK_LOOP" ]]; do
    # Calcular os tempos desde o último heal, dodge e ataque
    now=$(date +%s)
    time_since_last_heal=$((now - last_heal))
    time_since_last_dodge=$((now - last_dodge))
    time_since_last_atk=$((now - last_atk))

    # Verificar se pode curar
    if awk -v ush="$USH" -v hlhp="$HLHP" 'BEGIN { exit !(ush < hlhp) }' && [[ "$time_since_last_heal" -gt 90 && "$time_since_last_heal" -lt 300 ]]; then
        (
            w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}$HEAL" -o user_agent="$(shuf -n1 userAgent.txt)" >"$src_ram"
        ) </dev/null &>/dev/null &
        time_exit 17
        cl_access
        echo "$USH" >"$full_ram" # 1.FULL
        last_heal=$now  # Atualizar o tempo do último heal
        last_atk=$now   # Atualizar o tempo do último ataque

    # Verificar se pode desviar
    elif ! grep -q -o 'txt smpl grey' "$src_ram" && [[ "$time_since_last_dodge" -gt 20 && "$time_since_last_dodge" -lt 300 ]] && awk -v ush="$USH" -v oldhp="$OLDHP" 'BEGIN { exit !(ush < oldhp) }'; then
        (
            w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}$DODGE" -o user_agent="$(shuf -n1 userAgent.txt)" >"$src_ram"
        ) </dev/null &>/dev/null &
        time_exit 17
        cl_access
        OLDHP=$USH  # 18.OLDHP
        last_dodge=$now  # Atualizar o tempo do último dodge
        last_atk=$now    # Atualizar o tempo do último ataque

    # Verificar se pode atacar aleatoriamente
    elif awk -v latk="$time_since_last_atk" -v atktime="$LA" 'BEGIN { exit !(latk != atktime) }' && ! grep -q -o 'txt smpl grey' "$src_ram" && awk -v rhp="$RHP" -v enh="$ENH" 'BEGIN { exit !(rhp < enh) }' || awk -v latk="$time_since_last_atk" -v atktime="$LA" 'BEGIN { exit !(latk != atktime) }' && ! grep -q -o 'txt smpl grey' "$src_ram" && grep -q -o "$USER" allies.txt; then
        (
            w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}$ATKRND" -o user_agent="$(shuf -n1 userAgent.txt)" >"$src_ram"
        ) </dev/null &>/dev/null &
        time_exit 17
        cl_access
        last_atk=$now  # Atualizar o tempo do último ataque

    # Verificar se pode atacar normalmente
    elif awk -v latk="$time_since_last_atk" -v atktime="$LA" 'BEGIN { exit !(latk > atktime) }'; then
        (
            w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}$ATK" -o user_agent="$(shuf -n1 userAgent.txt)" >"$src_ram"
        ) </dev/null &>/dev/null &
        time_exit 17
        cl_access
        last_atk=$now  # Atualizar o tempo do último ataque

    # Se não puder fazer nada, esperar
    else
        (
            w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}/coliseum" -o user_agent="$(shuf -n1 userAgent.txt)" >"$src_ram"
        ) </dev/null &>/dev/null &
        time_exit 17
        cl_access
        sleep 1s
    fi
done

        rm "$src_ram" "$full_ram"
        unset last_heal last_dodge last_atk USH ENH USER ATK ATKRND DODGE HEAL BREAK_LOOP cl_access
        #/end
        func_unset
        if awk -v smodplay="$RUN" -v rmodplay="-cl" 'BEGIN { exit !(smodplay != rmodplay) }'; then printf "\nYou can run ./twm/play.sh -cl\n"; fi
        echo_t "The battle is over!" "${RED_BLACK}" "${COLOR_RESET}" "after" "⚔️\n"
    else
        # shellcheck disable=SC2154
        echo_t "It was not possible to start the battle at this time." "${WHITEb_BLACK}" "${COLOR_RESET}"
    fi
}
coliseum_start() {
    if [ "$FUNC_coliseum" = "n" ]; then
        return
    fi
    if case $(date +%H:%M ) in
    (09:2[4-9] | 9:5[4-9] | 10:1[0-4] | 10:2[4-9] | 10:5[4-9] | 12:2[4-9] | 13:5[4-9] | 14:5[4-9] | 15:5[4-9] | 16:1[0-4] | 16:2[4-9] | 18:5[4-9] | 20:5[4-9] | 21:2[4-9] | 21:5[4-9] | 22:2[4-9])
        exit 1
        ;;
    esac  then
        if echo "$RUN" | grep -q -E '[-]boot'; then
            (
                w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}/quest/" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
            ) </dev/null &>/dev/null &
            time_exit 20
            while grep -q -o -E '/coliseum/[?]quest_t[=]quest&quest_id[=]11&qz[=][a-z0-9]+' "$TMP"/SRC; do
                coliseum_fight
                (
                    w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}/quest/" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
                ) </dev/null &>/dev/null &
                time_exit 20
                local ENDQUEST=$(grep -o -E '/quest/end/11[?]r[=][A_z0-9]+' "$TMP"/SRC)
                if [ -n "$ENDQUEST" ]; then
                    (
                        w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump_source "${URL}${ENDQUEST}" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" >"$TMP"/SRC
                    ) </dev/null &>/dev/null &
                    time_exit 20
                fi
            done
        elif echo "$RUN" | grep -q -E '[-]cl'; then
            coliseum_fight
        fi
    else
        echo_t "Battle or event time..."
        sleep 5s
    fi
}