requer_func() {
    # Clear the terminal screen
    clear

    # Function to display server options (in multiple languages)
    options_one() {
        clear
        # shellcheck disable=SC2059
        printf " 1)${BLACK_CYAN} English, Global: Titan's War online \033[00m\n"
        printf " 2)${BLACK_CYAN} Русский: Битва Титанов онлайн \033[00m\n"
        printf " 3)${BLACK_CYAN} Polski: Wojna Tytanów online \033[00m\n"
        printf " 4)${BLACK_CYAN} Deutsch: Krieg der Titanen online \033[00m\n"
        printf " 5)${BLACK_CYAN} Español: Guerra de Titanes online \033[00m\n"
        printf " 6)${BLACK_CYAN} Brasil, Português: Furia de Titãs online \033[00m\n"
        printf " 7)${BLACK_CYAN} Italiano: Guerra di Titani online \033[00m\n"
        printf " 8)${BLACK_CYAN} Français: Combat des Titans online \033[00m\n"
        printf " 9)${BLACK_CYAN} Română: Războiul Titanilor online \033[00m\n"
        printf "10)${BLACK_CYAN} 中文, Chinese: 泰坦之战 \033[00m\n"
        printf "11)${BLACK_CYAN} Indonesian: Titan's War Indonesia \033[00m\n"
        printf " C)${BLACK_YELLOW} ❌ Cancel \033[00m\n"
    }

    options_two() {
        clear
        # shellcheck disable=SC2059
        printf " ${BLACK_RED}1\033[00m)${BLACK_CYAN} English, Global: Titan's War online ${BLACK_GREEN}[ENTER]\033[00m\n"
        printf " 2)${CYAN_CYAN} Русский: Битва Титанов онлайн \033[00m\n"
        printf " 3)${CYAN_CYAN} Polski: Wojna Tytanów online \033[00m\n"
        printf " 4)${CYAN_CYAN} Deutsch: Krieg der Titanen online \033[00m\n"
        printf " 5)${CYAN_CYAN} Español: Guerra de Titanes online \033[00m\n"
        printf " 6)${CYAN_CYAN} Brazil, Português: Furia de Titãs online \033[00m\n"
        printf " 7)${CYAN_CYAN} Italiano: Guerra di Titani online \033[00m\n"
        printf " 8)${CYAN_CYAN} Français: Combat des Titans online \033[00m\n"
        printf " 9)${CYAN_CYAN} Română: Războiul Titanilor online \033[00m\n"
        printf "${BLACK_RED}1\033[00m${BLACK_GREEN}0\033[00m)${BLACK_CYAN} 中文, Chinese: 泰坦之战 \033[00m\n"
        printf "${BLACK_RED}1\033[00m${BLACK_GREEN}1\033[00m)${BLACK_CYAN} Indonesian: Titan's War Indonesia \033[00m\n"
        printf " C)${BLACK_YELLOW} ❌ Cancel \033[00m\n"
    }

    # Function to handle invalid input for the first menu
    invalid_one() {
        options_one
        printf "Select number Server [1 to 11]: \033[01;31m\033[01;07m$UR◄ invalid option\033[00m\n"
        sleep 0.2s
        menu_one
    }

    # Function to handle invalid input for the second menu
    invalid_two() {
        clear
        options_two
        printf "Select number Server [1 to 11]: \033[01;31m\033[01;07m1$UR◄ invalid option\033[00m\n"
        sleep 0.2s
        menu_two
    }

    # Function for the second menu of options
    menu_two() {
        options_two
        printf "Select number Server [1 to 11]: 1\n"  # Default selection shown to user
        read -n 1 UR  # Read user input without waiting for Enter

        # Process user input for server selection
        if [ "$UR" = $'\0' ]; then
            echo "1" >"$HOME/twm/ur_file"  # Default to server 1 if Enter is pressed
        elif [ "$UR" = '0' ]; then
            echo "10" >"$HOME/twm/ur_file"  # Select Chinese server if '0' is pressed
        elif [ "$UR" = '1' ]; then
            echo "11" >"$HOME/twm/ur_file"  # Select Indonesian server if '1' is pressed
        elif [ "$UR" = $'\177' ]; then
            menu_one  # Go back to the first menu if Backspace is pressed
        elif [ "$UR" = 'c' ] || [ "$UR" = 'C' ]; then
            # Kill any running play.sh script if 'c' is pressed and exit the script
            pidf=$(ps ax -o pid=,args= | grep "sh.*twm/play.sh" | grep -v 'grep' | head -n 1 | grep -o -E '([0-9]{3,5})')
            until [ -z "$pidf" ]; do
                kill -9 "$pidf" 2> /dev/null
                pidf=$(ps ax -o pid=,args= | grep "sh.*twm/play.sh" | grep -v 'grep' | head -n 1 | grep -o -E '([0-9]{3,5})')
                sleep 1s
            done
            kill -9 $$ 2> /dev/null  # Terminate the current script process
        else
            invalid_two  # Handle invalid input by calling the invalid function for menu two
        fi
    }

    # Function for the first menu of options
    menu_one() {
        options_one
        printf "Select number Server [1 to 11]: \n" 
        read -n 1 UR

        # Process user input for server selection in the first menu
        case "$UR" in 
            '1') menu_two ;;           # Go to second menu if '1' is selected 
            '2') echo "2" >"$HOME/twm/ur_file" ;; 
            '3') echo "3" >"$HOME/twm/ur_file" ;; 
            '4') echo "4" >"$HOME/twm/ur_file" ;; 
            '5') echo "5" >"$HOME/twm/ur_file" ;; 
            '6') echo "6" >"$HOME/twm/ur_file" ;; 
            '7') echo "7" >"$HOME/twm/ur_file" ;; 
            '8') echo "8" >"$HOME/twm/ur_file" ;; 
            '9') echo "9" >"$HOME/twm/ur_file" ;; 
            $'\177') menu_one ;;       # Go back if Backspace is pressed 
            'c'|'C')                     # If 'c' or 'C' is pressed, terminate play.sh and exit 
                pidf=$(ps ax -o pid=,args= | grep "sh.*twm/play.sh"|grep -v 'grep'|head -n 1|grep -o -E '([0-9]{3,5})')
                until [ -z "$pidf" ]; do 
                    kill -9 "$pidf" 2> /dev/null 
                    pidf=$(ps ax -o pid=,args=|grep "sh.*twm/play.sh"|grep -v 'grep'|head -n 1|grep -o -E '([0-9]{3,5})')
                    sleep 1s 
                done 
                kill -9 $$ 2> /dev/null 
                ;;
            *) invalid_one ;;          # Handle invalid input by calling the invalid function for menu one 
         esac  
     }

     # Check if ur_file exists and is not empty; if so, read from it; otherwise, show the first menu.
     if [ -f "$HOME/twm/ur_file" ] && [ -s "$HOME/twm/ur_file" ]; then  
         UR="$(cat "$HOME/twm/ur_file")"
     else  
         menu_one  
     fi  

     UR="$(cat "$HOME/twm/ur_file")"

     # Set URL and TMP variables based on user selection from ur_file.
     case $UR in  
         (1|s_en)
             URL=$(echo "dGl3YXIubmV0"|base64 -d)
             echo "1" >"$HOME/twm/ur_file"
             TMP="$HOME/twm/.1"
             export TZ="Europe/London"; ALLIES="_WORK";;
         (2|ru)
             URL=$(echo "dGl3YXIucnU="|base64 -d)
             echo "2" >"$HOME/twm/ur_file"
             TMP="$HOME/twm/.2"
             export TZ="Europe/Moscow"; ALLIES="_WORK";;
         (3|pl)
             URL=$(echo "dGl3YXIucGw="|base64 -d)
             echo "3" >"$HOME/twm/ur_file"
             TMP="$HOME/twm/.3"
             export TZ="Europe/Warsaw"; ALLIES="_WORK";;
         (4)
             URL=$(echo "dGl0YW5lbi5tb2Jp"|base64 -d)
             echo "4" >"$HOME/twm/ur_file"
             TMP="$HOME/twm/.4"
             export TZ="Europe/Berlin"; ALLIES="_WORK";;
         (5)
             URL=$(echo "Z3VlcnJhZGV0aXRhbmVzLm5ldA=="|base64 -d)
             echo "5" >"$HOME/twm/ur_file"
             TMP="$HOME/twm/.5"
             export TZ="America/Cancun"; ALLIES="_WORK";;
         (6|fu)
             URL=$(echo "ZnVyaWFkZXRpdGFzLm5ldA=="|base64 -d)
             echo "6" >"$HOME/twm/ur_file"
             TMP="$HOME/twm/.6"
             export TZ="America/Bahia"; ALLIES="_WORK";;
         (7)
             URL=$(echo "Z3VlcnJhZGl0aXRhbmkubmV0"|base64 -d)
             echo "7" >"$HOME/twm/ur_file"
             TMP="$HOME/twm/.7"
             export TZ="Europe/Rome"; ALLIES="_WORK";;
         (8|fr)
             URL=$(echo "dGl3YXIuZnI="|base64 -d)
             echo "8" >"$HOME/twm/ur_file"
             TMP="$HOME/twm/.8"
             export TZ="Europe/Paris"; ALLIES="_WORK";;
         (9|ro)
             URL=$(echo "dGl3YXIucm8="|base64 -d)
             echo "9" >"$HOME/twm/ur_file"
             TMP="$HOME/twm/.9"
             export TZ="Europe/Bucharest"; ALLIES="_WORK";;
         (10|s_cn)
             URL=$(echo "Y24udGl3YXIubmV0"|base64 -d)
             echo "10" >"$HOME/twm/ur_file"
             TMP="$HOME/twm/.10"
             export TZ="Asia/Shanghai"; ALLIES="_WORK";;
         (11|s_id)
             URL=$(echo "dGl3YXItaWQubmV0"|base64 -d)
             echo "11" >"$HOME/twm/ur_file"
             TMP="$HOME/twm/.11"
             export TZ="Asia/Jakarta"; ALLIES="_WORK";;
         (*)
              clear  
              if [ -n "$UR" ]; then  
                  printf "\n Invalid option: $(echo "$UR")\n"  
                  kill -9 $$  
              else  
                  printf "\n Time exceeded!\n"  
              fi  
              ;;
     esac  

     clear  

  # Check if URL is set; if not, exit the script
  if [ -z "$URL" ]; then
      exit
  fi

  # Create the temporary directory if it doesn't exist
  mkdir -p "$TMP"

  # Change to the temporary directory
  cd "$TMP" || exit

  # Reset and clear the terminal screen
  reset
  clear

  # Function to handle user agent selection and setup
  user_agent() {
    cd "$TMP" || exit
    clear

    # Display options for user agent selection
    printf "${BLACK_CYAN} Simulate your real or random device. \033[00m\n"
    printf "1)${BLACK_CYAN} Manual \033[00m\n"
    printf "2)${BLACK_CYAN} Automatic \033[00m\n"

    # Check if a user agent file exists and is not empty
    if [ -f "$HOME/twm/fileAgent.txt" ] && [ -s "$HOME/twm/fileAgent.txt" ]; then
        UA=$(cat "$HOME/twm/fileAgent.txt")  # Read existing user agent
    else
        printf "Set up User-Agent [1 to 2]: \n"
        read -n 1 UA  # Read user input for user agent selection
    fi

    # Handle user agent selection based on input
    case $UA in
        (0)
            clear
            echo "0" >"$HOME/twm/fileAgent.txt"  # Save selection to file
            # If no user agent file exists, write a default one
            if [ ! -e "$TMP/userAgent.txt" ] || [ -z "$UA" ]; then
                echo 'TW96aWxsYS81LjAgKFdpbmRvd3MgTlQgMTAuMDsgV2luNjQ7IHg2NCkgQXBwbGVXZWJLaXQvNTM3LjM2IChLSFRNTCwgbGlrZSBHZWNrbykgQ2hyb21lLzkxLjAuNDQ3Mi4xMjQgU2FmYXJpLzUzNy4zNgpNb3ppbGxhLzUuMCAoV2luZG93cyBOVCAxMC4wOyBXaW42NDsgeDY0KSBBcHBsZVdlYktpdC81MzcuMzYgKEtIVE1MLCBsaWtlIEdlY2tvKSBDaHJvbWUvOTIuMC40NTE1LjEwNyBTYWZhcmkvNTM3LjM2Ck1vemlsbGEvNS4wIChNYWNpbnRvc2g7IEludGVsIE1hYyBPUyBYIDEwXzE1XzcpIEFwcGxlV2ViS2l0LzUzNy4zNiAoS0hUTUwsIGxpa2UgR2Vja28pIENocm9tZS85MS4wLjQ0NzIuMTE0IFNhZmFyaS81MzcuMzYKTW96aWxsYS81LjAgKFdpbmRvd3MgTlQgMTAuMDsgV2luNjQ7IHg2NDsgcnY6OTAuMCkgR2Vja28vMjAxMDAxMDEgRmlyZWZveC85MC4wCk1vemlsbGEvNS4wIChXaW5kb3dzIE5UIDEwLjA7IFdpbjY0OyB4NjQpIEFwcGxlV2ViS2l0LzUzNy4zNiAoS0hUTUwsIGxpa2UgR2Vja28pIENocm9tZS85MS4wLjQ0NzIuMTY0IFNhZmFyaS81MzcuMzYKTW96aWxsYS81LjAgKE1hY2ludG9zaDsgSW50ZWwgTWFjIE9TIFggMTBfMTVfNykgQXBwbGVXZWJLaXQvNjA1LjEuMTUgKEtIVE1MLCBsaWtlIEdlY2tvKSBWZXJzaW9uLzE0LjEuMSBTYWZhcmkvNjA1LjEuMTUKTW96aWxsYS81LjAgKFdpbmRvd3MgTlQgMTAuMDsgV2luNjQ7IHg2NDsgcnY6ODkuMCkgR2Vja28vMjAxMDAxMDEgRmlyZWZveC84OS4wCk1vemlsbGEvNS4wIChNYWNpbnRvc2g7IEludGVsIE1hYyBPUyBYIDEwXzE1XzcpIEFwcGxlV2ViS2l0LzUzNy4zNiAoS0hUTUwsIGxpa2UgR2Vja28pIENocm9tZS85Mi4wLjQ1MTUuMTA3IFNhZmFyaS81MzcuMzYKTW96aWxsYS81LjAgKFdpbmRvd3MgTlQgMTAuMDsgV2luNjQ7IHg2NCkgQXBwbGVXZWJLaXQvNTM3LjM2IChLSFRNTCwgbGlrZSBHZWNrbykgQ2hyb21lLzkyLjAuNDUxNS4xMzEgU2FmYXJpLzUzNy4zNgpNb3ppbGxhLzUuMCAoV2luZG93cyBOVCAxMC4wOyBydjo3OC4wKSBHZWNrby8yMDEwMDEwMSBGaXJlZm94Lzc4LjAKTW96aWxsYS81LjAgKE1hY2ludG9zaDsgSW50ZWwgTWFjIE9TIFggMTBfMTVfNykgQXBwbGVXZWJLaXQvNTM3LjM2IChLSFRNTCwgbGlrZSBHZWNrbykgQ2hyb21lLzkxLjAuNDQ3Mi4xNjQgU2FmYXJpLzUzNy4zNgpNb3ppbGxhLzUuMCAoWDExOyBVYnVudHU7IExpbnV4IHg4Nl82NDsgcnY6OTAuMCkgR2Vja28vMjAxMDAxMDEgRmlyZWZveC85MC4wCk1vemlsbGEvNS4wIChNYWNpbnRvc2g7IEludGVsIE1hYyBPUyBYIDEwLjE1OyBydjo5MC4wKSBHZWNrby8yMDEwMDEwMSBGaXJlZm94LzkwLjAKTW96aWxsYS81LjAgKFgxMTsgTGludXggeDg2XzY0KSBBcHBsZVdlYktpdC81MzcuMzYgKEtIVE1MLCBsaWtlIEdlY2tvKSBDaHJvbWUvOTEuMC40NDcyLjExNCBTYWZhcmkvNTM3LjM2Ck1vemlsbGEvNS4wIChYMTE7IExpbnV4IHg4Nl82NDsgcnY6OTAuMCkgR2Vja28vMjAxMDAxMDEgRmlyZWZveC85MC4wCk1vemlsbGEvNS4wIChNYWNpbnRvc2g7IEludGVsIE1hYyBPUyBYIDEwLjE1OyBydjo4OS4wKSBHZWNrby8yMDEwMDEwMSBGaXJlZm94Lzg5LjAKTW96aWxsYS81LjAgKFdpbmRvd3MgTlQgMTAuMDsgV2luNjQ7IHg2NCkgQXBwbGVXZWJLaXQvNTM3LjM2IChLSFRNTCwgbGlrZSBHZWNrbykgQ2hyb21lLzkyLjAuNDUxNS4xMDcgU2FmYXJpLzUzNy4zNiBFZGcvOTIuMC45MDIuNTUKTW96aWxsYS81LjAgKFgxMTsgVWJ1bnR1OyBMaW51eCB4ODZfNjQ7IHJ2Ojg5LjApIEdlY2tvLzIwMTAwMTAxIEZpcmVmb3gvODkuMApNb3ppbGxhLzUuMCAoTWFjaW50b3NoOyBJbnRlbCBNYWMgT1MgWCAxMF8xNV83KSBBcHBsZVdlYktpdC82MDUuMS4xNSAoS0hUTUwsIGxpa2UgR2Vja28pIFZlcnNpb24vMTQuMS4yIFNhZmFyaS82MDUuMS4xNQpNb3ppbGxhLzUuMCAoV2luZG93cyBOVCAxMC4wOyBXaW42NDsgeDY0KSBBcHBsZVdlYktpdC81MzcuMzYgKEtIVE1MLCBsaWtlIEdlY2tvKSBDaHJvbWUvOTEuMC40NDcyLjEyNCBTYWZhcmkvNTM3LjM2IEVkZy85MS4wLjg2NC42NwpNb3ppbGxhLzUuMCAoV2luZG93cyBOVCAxMC4wOyBXaW42NDsgeDY0KSBBcHBsZVdlYktpdC81MzcuMzYgKEtIVE1MLCBsaWtlIEdlY2tvKSBDaHJvbWUvOTIuMC40NTE1LjEwNyBTYWZhcmkvNTM3LjM2IEVkZy85Mi4wLjkwMi42MgpNb3ppbGxhLzUuMCAoWDExOyBMaW51eCB4ODZfNjQpIEFwcGxlV2ViS2l0LzUzNy4zNiAoS0hUTUwsIGxpa2UgR2Vja28pIENocm9tZS85Mi4wLjQ1MTUuMTA3IFNhZmFyaS81MzcuMzYKTW96aWxsYS81LjAgKFgxMTsgTGludXggeDg2XzY0OyBydjo3OC4wKSBHZWNrby8yMDEwMDEwMSBGaXJlZm94Lzc4LjAKTW96aWxsYS81LjAgKFgxMTsgTGludXggeDg2XzY0OyBydjo4OS4wKSBHZWNrby8yMDEwMDEwMSBGaXJlZm94Lzg5LjAKTW96aWxsYS81LjAgKFdpbmRvd3MgTlQgMTAuMDsgV2luNjQ7IHg2NCkgQXBwbGVXZWJLaXQvNTM3LjM2IChLSFRNTCwgbGlrZSBHZWNrbykgQ2hyb21lLzkxLjAuNDQ3Mi4xMjQgU2FmYXJpLzUzNy4zNiBFZGcvOTEuMC44NjQuNjQKTW96aWxsYS81LjAgKFdpbmRvd3MgTlQgMTAuMDsgV2luNjQ7IHg2NCkgQXBwbGVXZWJLaXQvNTM3LjM2IChLSFRNTCwgbGlrZSBHZWNrbykgQ2hyb21lLzkxLjAuNDQ3Mi4xMTQgU2FmYXJpLzUzNy4zNgpNb3ppbGxhLzUuMCAoV2luZG93cyBOVCAxMC4wOyBXaW42NDsgeDY0KSBBcHBsZVdlYktpdC81MzcuMzYgKEtIVE1MLCBsaWtlIEdlY2tvKSBDaHJvbWUvOTEuMC40NDcyLjEyNCBTYWZhcmkvNTM3LjM2IEVkZy85MS4wLjg2NC43MApNb3ppbGxhLzUuMCAoTWFjaW50b3NoOyBJbnRlbCBNYWMgT1MgWCAxMF8xNV83KSBBcHBsZVdlYktpdC81MzcuMzYgKEtIVE1MLCBsaWtlIEdlY2tvKSBDaHJvbWUvOTIuMC40NTE1LjEzMSBTYWZhcmkvNTM3LjM2Ck1vemlsbGEvNS4wIChYMTE7IExpbnV4IHg4Nl82NCkgQXBwbGVXZWJLaXQvNTM3LjM2IChLSFRNTCwgbGlrZSBHZWNrbykgQ2hyb21lLzkxLjAuNDQ3Mi4xNjQgU2FmYXJpLzUzNy4zNgpNb3ppbGxhLzUuMCAoV2luZG93cyBOVCA2LjE7IFdpbjY0OyB4NjQpIEFwcGxlV2ViS2l0LzUzNy4zNiAoS0hUTUwsIGxpa2UgR2Vja28pIENocm9tZS85MS4wLjQ0NzIuMTI0IFNhZmFyaS81MzcuMzYKTW96aWxsYS81LjAgKFdpbmRvd3MgTlQgMTAuMDsgV2luNjQ7IHg2NCkgQXBwbGVXZWJLaXQvNTM3LjM2IChLSFRNTCwgbGlrZSBHZWNrbykgQ2hyb21lLzkxLjAuNDQ3Mi4xNjQgU2FmYXJpLzUzNy4zNiBFZGcvOTEuMC44NjQuNzEKTW96aWxsYS81LjAgKE1hY2ludG9zaDsgSW50ZWwgTWFjIE9TIFggMTBfMTVfNikgQXBwbGVXZWJLaXQvNjA1LjEuMTUgKEtIVE1MLCBsaWtlIEdlY2tvKSBWZXJzaW9uLzE0LjEuMSBTYWZhcmkvNjA1LjEuMTUKTW96aWxsYS81LjAgKFdpbmRvd3MgTlQgMTAuMDsgV2luNjQ7IHg2NCkgQXBwbGVXZWJLaXQvNTM3LjM2IChLSFRNTCwgbGlrZSBHZWNrbykgQ2hyb21lLzkyLjAuNDUxNS4xMTUgU2FmYXJpLzUzNy4zNgpNb3ppbGxhLzUuMCAoV2luZG93cyBOVCA2LjM7IFdpbjY0OyB4NjQpIEFwcGxlV2ViS2l0LzUzNy4zNiAoS0hUTUwsIGxpa2UgR2Vja28pIENocm9tZS85MS4wLjQ0NzIuMTI0IFNhZmFyaS81MzcuMzYKTW96aWxsYS81LjAgKE1hY2ludG9zaDsgSW50ZWwgTWFjIE9TIFggMTBfMTRfNikgQXBwbGVXZWJLaXQvNTM3LjM2IChLSFRNTCwgbGlrZSBHZWNrbykgQ2hyb21lLzkxLjAuNDQ3Mi4xMTQgU2FmYXJpLzUzNy4zNgpNb3ppbGxhLzUuMCAoTWFjaW50b3NoOyBJbnRlbCBNYWMgT1MgWCAxMF8xNV83KSBBcHBsZVdlYktpdC82MDUuMS4xNSAoS0hUTUwsIGxpa2UgR2Vja28pIFZlcnNpb24vMTQuMSBTYWZhcmkvNjA1LjEuMTUKTW96aWxsYS81LjAgKFdpbmRvd3MgTlQgNi4xOyBXaW42NDsgeDY0KSBBcHBsZVdlYktpdC81MzcuMzYgKEtIVE1MLCBsaWtlIEdlY2tvKSBDaHJvbWUvOTIuMC40NTE1LjEwNyBTYWZhcmkvNTM3LjM2Ck1vemlsbGEvNS4wIChXaW5kb3dzIE5UIDEwLjA7IFdpbjY0OyB4NjQ7IHJ2Ojc4LjApIEdlY2tvLzIwMTAwMTAxIEZpcmVmb3gvNzguMApNb3ppbGxhLzUuMCAoV2luZG93cyBOVCAxMC4wOyBXaW42NDsgeDY0KSBBcHBsZVdlYktpdC81MzcuMzYgKEtIVE1MLCBsaWtlIEdlY2tvKSBDaHJvbWUvOTEuMC40NDcyLjEyNCBTYWZhcmkvNTM3LjM2IE9QUi83Ny4wLjQwNTQuMjAzCk1vemlsbGEvNS4wIChNYWNpbnRvc2g7IEludGVsIE1hYyBPUyBYIDEwXzE1XzYpIEFwcGxlV2ViS2l0LzYwNS4xLjE1IChLSFRNTCwgbGlrZSBHZWNrbykgVmVyc2lvbi8xNC4wLjMgU2FmYXJpLzYwNS4xLjE1Ck1vemlsbGEvNS4wIChXaW5kb3dzIE5UIDEwLjA7IFdpbjY0OyB4NjQpIEFwcGxlV2ViS2l0LzUzNy4zNiAoS0hUTUwsIGxpa2UgR2Vja28pIENocm9tZS85MS4wLjQ0NzIuMTY0IFNhZmFyaS81MzcuMzYgT1BSLzc3LjAuNDA1NC4yNzcKTW96aWxsYS81LjAgKE1hY2ludG9zaDsgSW50ZWwgTWFjIE9TIFggMTBfMTVfNykgQXBwbGVXZWJLaXQvNTM3LjM2IChLSFRNTCwgbGlrZSBHZWNrbykgQ2hyb21lLzkxLjAuNDQ3Mi4xMjQgU2FmYXJpLzUzNy4zNgpNb3ppbGxhLzUuMCAoV2luZG93cyBOVCAxMC4wOyBXaW42NDsgeDY0KSBBcHBsZVdlYktpdC81MzcuMzYgKEtIVE1MLCBsaWtlIEdlY2tvKSBDaHJvbWUvOTEuMC40NDcyLjc3IFNhZmFyaS81MzcuMzYKTW96aWxsYS81LjAgKFdpbmRvd3MgTlQgMTAuMDsgV2luNjQ7IHg2NCkgQXBwbGVXZWJLaXQvNTM3LjM2IChLSFRNTCwgbGlrZSBHZWNrbykgQ2hyb21lLzc2LjAuMzgwOS4xMDAgU2FmYXJpLzUzNy4zNgpNb3ppbGxhLzUuMCAoV2luZG93cyBOVCA2LjE7IFdpbjY0OyB4NjQ7IHJ2OjkwLjApIEdlY2tvLzIwMTAwMTAxIEZpcmVmb3gvOTAuMApNb3ppbGxhLzUuMCAoV2luZG93cyBOVCAxMC4wOyBXT1c2NCkgQXBwbGVXZWJLaXQvNTM3LjM2IChLSFRNTCwgbGlrZSBHZWNrbykgQ2hyb21lLzkxLjAuNDQ3Mi4xMjQgU2FmYXJpLzUzNy4zNgpNb3ppbGxhLzUuMCAoTWFjaW50b3NoOyBJbnRlbCBNYWMgT1MgWCAxMF8xNV83KSBBcHBsZVdlYktpdC82MDUuMS4xNSAoS0hUTUwsIGxpa2UgR2Vja28pIFZlcnNpb24vMTUuMCBTYWZhcmkvNjA1LjEuMTUKTW96aWxsYS81LjAgKFdpbmRvd3MgTlQgMTAuMDsgV2luNjQ7IHg2NCkgQXBwbGVXZWJLaXQvNTM3LjM2IChLSFRNTCwgbGlrZSBHZWNrbykgQ2hyb21lLzkwLjAuNDQzMC45MyBTYWZhcmkvNTM3LjM2Ck1vemlsbGEvNS4wIChXaW5kb3dzIE5UIDEwLjA7IFdpbjY0OyB4NjQ7IHJ2OjkxLjApIEdlY2tvLzIwMTAwMTAxIEZpcmVmb3gvOTEuMApNb3ppbGxhLzUuMCAoTWFjaW50b3NoOyBJbnRlbCBNYWMgT1MgWCAxMF8xNV83KSBBcHBsZVdlYktpdC81MzcuMzYgKEtIVE1MLCBsaWtlIEdlY2tvKSBDaHJvbWUvOTEuMC40NDcyLjc3IFNhZmFyaS81MzcuMzYKTW96aWxsYS81LjAgKE1hY2ludG9zaDsgSW50ZWwgTWFjIE9TIFggMTBfMTRfNikgQXBwbGVXZWJLaXQvNTM3LjM2IChLSFRNTCwgbGlrZSBHZWNrbykgQ2hyb21lLzkyLjAuNDUxNS4xMDcgU2FmYXJpLzUzNy4zNgpNb3ppbGxhLzUuMCAoTWFjaW50b3NoOyBJbnRlbCBNYWMgT1MgWCAxMC4xNTsgcnY6OTEuMCkgR2Vja28vMjAxMDAxMDEgRmlyZWZveC85MS4wCk1vemlsbGEvNS4wIChNYWNpbnRvc2g7IEludGVsIE1hYyBPUyBYIDEwXzE1XzcpIEFwcGxlV2ViS2l0LzUzNy4zNiAoS0hUTUwsIGxpa2UgR2Vja28pIENocm9tZS85MS4wLjQ0NzIuMTA2IFNhZmFyaS81MzcuMzYKTW96aWxsYS81LjAgKFdpbmRvd3MgTlQgMTAuMDsgV2luNjQ7IHg2NCkgQXBwbGVXZWJLaXQvNTM3LjM2IChLSFRNTCwgbGlrZSBHZWNrbykgQ2hyb21lLzkxLjAuNDQ3Mi4xMDYgU2FmYXJpLzUzNy4zNgpNb3ppbGxhLzUuMCAoV2luZG93cyBOVCA2LjE7IFdpbjY0OyB4NjQ7IHJ2Ojg5LjApIEdlY2tvLzIwMTAwMTAxIEZpcmVmb3gvODkuMApNb3ppbGxhLzUuMCAoV2luZG93cyBOVCA2LjM7IFdpbjY0OyB4NjQpIEFwcGxlV2ViS2l0LzUzNy4zNiAoS0hUTUwsIGxpa2UgR2Vja28pIENocm9tZS85Mi4wLjQ1MTUuMTA3IFNhZmFyaS81MzcuMzYKTW96aWxsYS81LjAgKFgxMTsgRmVkb3JhOyBMaW51eCB4ODZfNjQ7IHJ2Ojg5LjApIEdlY2tvLzIwMTAwMTAxIEZpcmVmb3gvODkuMApNb3ppbGxhLzUuMCAoWDExOyBGZWRvcmE7IExpbnV4IHg4Nl82NDsgcnY6OTAuMCkgR2Vja28vMjAxMDAxMDEgRmlyZWZveC85MC4wCk1vemlsbGEvNS4wIChNYWNpbnRvc2g7IEludGVsIE1hYyBPUyBYIDEwXzEzXzYpIEFwcGxlV2ViS2l0LzYwNS4xLjE1IChLSFRNTCwgbGlrZSBHZWNrbykgVmVyc2lvbi8xMy4xLjIgU2FmYXJpLzYwNS4xLjE1Ck1vemlsbGEvNS4wIChNYWNpbnRvc2g7IEludGVsIE1hYyBPUyBYIDEwXzE1XzcpIEFwcGxlV2ViS2l0LzUzNy4zNiAoS0hUTUwsIGxpa2UgR2Vja28pIENocm9tZS85MC4wLjQ0MzAuMjEyIFNhZmFyaS81MzcuMzYKTW96aWxsYS81LjAgKFdpbmRvd3MgTlQgMTAuMDsgV2luNjQ7IHg2NCkgQXBwbGVXZWJLaXQvNTM3LjM2IChLSFRNTCwgbGlrZSBHZWNrbykgQ2hyb21lLzkxLjAuNDQ3Mi4xNjQgU2FmYXJpLzUzNy4zNiBPUFIvNzcuMC40MDU0LjI3NQpNb3ppbGxhLzUuMCAoV2luZG93cyBOVCA2LjE7IFdpbjY0OyB4NjQpIEFwcGxlV2ViS2l0LzUzNy4zNiAoS0hUTUwsIGxpa2UgR2Vja28pIENocm9tZS85Mi4wLjQ1MTUuMTMxIFNhZmFyaS81MzcuMzYKTW96aWxsYS81LjAgKFgxMTsgTGludXggeDg2XzY0KSBBcHBsZVdlYktpdC81MzcuMzYgKEtIVE1MLCBsaWtlIEdlY2tvKSBDaHJvbWUvOTAuMC40NDMwLjIxMiBTYWZhcmkvNTM3LjM2Ck1vemlsbGEvNS4wIChYMTE7IExpbnV4IHg4Nl82NCkgQXBwbGVXZWJLaXQvNTM3LjM2IChLSFRNTCwgbGlrZSBHZWNrbykgQ2hyb21lLzkwLjAuNDQzMC45MyBTYWZhcmkvNTM3LjM2Ck1vemlsbGEvNS4wIChYMTE7IExpbnV4IHg4Nl82NCkgQXBwbGVXZWJLaXQvNTM3LjM2IChLSFRNTCwgbGlrZSBHZWNrbykgQ2hyb21lLzkxLjAuNDQ3Mi4xMjQgU2FmYXJpLzUzNy4zNgpNb3ppbGxhLzUuMCAoWDExOyBMaW51eCB4ODZfNjQpIEFwcGxlV2ViS2l0LzUzNy4zNiAoS0hUTUwsIGxpa2UgR2Vja28pIENocm9tZS85MS4wLjQ0NzIuNzcgU2FmYXJpLzUzNy4zNgpNb3ppbGxhLzUuMCAoTWFjaW50b3NoOyBJbnRlbCBNYWMgT1MgWCAxMF8xNV83KSBBcHBsZVdlYktpdC82MDUuMS4xNSAoS0hUTUwsIGxpa2UgR2Vja28pIFZlcnNpb24vMTMuMS4zIFNhZmFyaS82MDUuMS4xNQpNb3ppbGxhLzUuMCAoV2luZG93cyBOVCAxMC4wOyBydjo5MS4wKSBHZWNrby8yMDEwMDEwMSBGaXJlZm94LzkxLjAKTW96aWxsYS81LjAgKFdpbmRvd3MgTlQgNi4xOyBXT1c2NCkgQXBwbGVXZWJLaXQvNTM3LjM2IChLSFRNTCwgbGlrZSBHZWNrbykgQ2hyb21lLzg2LjAuNDI0MC4xOTggU2FmYXJpLzUzNy4zNgpNb3ppbGxhLzUuMCAoV2luZG93cyBOVCA2LjM7IFdpbjY0OyB4NjQ7IHJ2OjkwLjApIEdlY2tvLzIwMTAwMTAxIEZpcmVmb3gvOTAuMAo=' | base64 -d >"$TMP/userAgent.txt"
            fi
            ;;
        (1)
            clear
            echo "0" >"$HOME/twm/fileAgent.txt"  # Save selection to file
            xdg-open "$(echo "aHR0cHM6Ly93d3cud2hhdHNteXVhLmluZm8=" | base64 -d)" &>/dev/null  # Open URL for manual entry
            printf "Copy and paste your User Agent here and press ENTER: \n"
            read -n 300 UA  # Read user input for custom user agent
            echo "$UA" >"$TMP/userAgent.txt"  # Save the custom user agent
            
            # If no valid user agent is provided, write a default one
            if [ ! -e "$TMP/userAgent.txt" ] || [ -z "$UA" ]; then
                printf " ...\n"
                echo 'TW96aWxsYS81LjAgKFdpbmRvd3MgTlQgMTAuMDsgV2luNjQ7IHg2NCkgQXBwbGVXZWJLaXQvNTM3LjM2IChLSFRNTCwgbGlrZSBHZWNrbykgQ2hyb21lLzkxLjAuNDQ3Mi4xMjQgU2FmYXJpLzUzNy4zNgpNb3ppbGxhLzUuMCAoV2luZG93cyBOVCAxMC4wOyBXaW42NDsgeDY0KSBBcHBsZVdlYktpdC81MzcuMzYgKEtIVE1MLCBsaWtlIEdlY2tvKSBDaHJvbWUvOTIuMC40NTE1LjEwNyBTYWZhcmkvNTM3LjM2Ck1vemlsbGEvNS4wIChNYWNpbnRvc2g7IEludGVsIE1hYyBPUyBYIDEwXzE1XzcpIEFwcGxlV2ViS2l0LzUzNy4zNiAoS0hUTUwsIGxpa2UgR2Vja28pIENocm9tZS85MS4wLjQ0NzIuMTE0IFNhZmFyaS81MzcuMzYKTW96aWxsYS81LjAgKFdpbmRvd3MgTlQgMTAuMDsgV2luNjQ7IHg2NDsgcnY6OTAuMCkgR2Vja28vMjAxMDAxMDEgRmlyZWZveC85MC4wCk1vemlsbGEvNS4wIChXaW5kb3dzIE5UIDEwLjA7IFdpbjY0OyB4NjQpIEFwcGxlV2ViS2l0LzUzNy4zNiAoS0hUTUwsIGxpa2UgR2Vja28pIENocm9tZS85MS4wLjQ0NzIuMTY0IFNhZmFyaS81MzcuMzYKTW96aWxsYS81LjAgKE1hY2ludG9zaDsgSW50ZWwgTWFjIE9TIFggMTBfMTVfNykgQXBwbGVXZWJLaXQvNjA1LjEuMTUgKEtIVE1MLCBsaWtlIEdlY2tvKSBWZXJzaW9uLzE0LjEuMSBTYWZhcmkvNjA1LjEuMTUKTW96aWxsYS81LjAgKFdpbmRvd3MgTlQgMTAuMDsgV2luNjQ7IHg2NDsgcnY6ODkuMCkgR2Vja28vMjAxMDAxMDEgRmlyZWZveC84OS4wCk1vemlsbGEvNS4wIChNYWNpbnRvc2g7IEludGVsIE1hYyBPUyBYIDEwXzE1XzcpIEFwcGxlV2ViS2l0LzUzNy4zNiAoS0hUTUwsIGxpa2UgR2Vja28pIENocm9tZS85Mi4wLjQ1MTUuMTA3IFNhZmFyaS81MzcuMzYKTW96aWxsYS81LjAgKFdpbmRvd3MgTlQgMTAuMDsgV2luNjQ7IHg2NCkgQXBwbGVXZWJLaXQvNTM3LjM2IChLSFRNTCwgbGlrZSBHZWNrbykgQ2hyb21lLzkyLjAuNDUxNS4xMzEgU2FmYXJpLzUzNy4zNgpNb3ppbGxhLzUuMCAoV2luZG93cyBOVCAxMC4wOyBydjo3OC4wKSBHZWNrby8yMDEwMDEwMSBGaXJlZm94Lzc4LjAKTW96aWxsYS81LjAgKE1hY2ludG9zaDsgSW50ZWwgTWFjIE9TIFggMTBfMTVfNykgQXBwbGVXZWJLaXQvNTM3LjM2IChLSFRNTCwgbGlrZSBHZWNrbykgQ2hyb21lLzkxLjAuNDQ3Mi4xNjQgU2FmYXJpLzUzNy4zNgpNb3ppbGxhLzUuMCAoWDExOyBVYnVudHU7IExpbnV4IHg4Nl82NDsgcnY6OTAuMCkgR2Vja28vMjAxMDAxMDEgRmlyZWZveC85MC4wCk1vemlsbGEvNS4wIChNYWNpbnRvc2g7IEludGVsIE1hYyBPUyBYIDEwLjE1OyBydjo5MC4wKSBHZWNrby8yMDEwMDEwMSBGaXJlZm94LzkwLjAKTW96aWxsYS81LjAgKFgxMTsgTGludXggeDg2XzY0KSBBcHBsZVdlYktpdC81MzcuMzYgKEtIVE1MLCBsaWtlIEdlY2tvKSBDaHJvbWUvOTEuMC40NDcyLjExNCBTYWZhcmkvNTM3LjM2Ck1vemlsbGEvNS4wIChYMTE7IExpbnV4IHg4Nl82NDsgcnY6OTAuMCkgR2Vja28vMjAxMDAxMDEgRmlyZWZveC85MC4wCk1vemlsbGEvNS4wIChNYWNpbnRvc2g7IEludGVsIE1hYyBPUyBYIDEwLjE1OyBydjo4OS4wKSBHZWNrby8yMDEwMDEwMSBGaXJlZm94Lzg5LjAKTW96aWxsYS81LjAgKFdpbmRvd3MgTlQgMTAuMDsgV2luNjQ7IHg2NCkgQXBwbGVXZWJLaXQvNTM3LjM2IChLSFRNTCwgbGlrZSBHZWNrbykgQ2hyb21lLzkyLjAuNDUxNS4xMDcgU2FmYXJpLzUzNy4zNiBFZGcvOTIuMC45MDIuNTUKTW96aWxsYS81LjAgKFgxMTsgVWJ1bnR1OyBMaW51eCB4ODZfNjQ7IHJ2Ojg5LjApIEdlY2tvLzIwMTAwMTAxIEZpcmVmb3gvODkuMApNb3ppbGxhLzUuMCAoTWFjaW50b3NoOyBJbnRlbCBNYWMgT1MgWCAxMF8xNV83KSBBcHBsZVdlYktpdC82MDUuMS4xNSAoS0hUTUwsIGxpa2UgR2Vja28pIFZlcnNpb24vMTQuMS4yIFNhZmFyaS82MDUuMS4xNQpNb3ppbGxhLzUuMCAoV2luZG93cyBOVCAxMC4wOyBXaW42NDsgeDY0KSBBcHBsZVdlYktpdC81MzcuMzYgKEtIVE1MLCBsaWtlIEdlY2tvKSBDaHJvbWUvOTEuMC40NDcyLjEyNCBTYWZhcmkvNTM3LjM2IEVkZy85MS4wLjg2NC42NwpNb3ppbGxhLzUuMCAoV2luZG93cyBOVCAxMC4wOyBXaW42NDsgeDY0KSBBcHBsZVdlYktpdC81MzcuMzYgKEtIVE1MLCBsaWtlIEdlY2tvKSBDaHJvbWUvOTIuMC40NTE1LjEwNyBTYWZhcmkvNTM3LjM2IEVkZy85Mi4wLjkwMi42MgpNb3ppbGxhLzUuMCAoWDExOyBMaW51eCB4ODZfNjQpIEFwcGxlV2ViS2l0LzUzNy4zNiAoS0hUTUwsIGxpa2UgR2Vja28pIENocm9tZS85Mi4wLjQ1MTUuMTA3IFNhZmFyaS81MzcuMzYKTW96aWxsYS81LjAgKFgxMTsgTGludXggeDg2XzY0OyBydjo3OC4wKSBHZWNrby8yMDEwMDEwMSBGaXJlZm94Lzc4LjAKTW96aWxsYS81LjAgKFgxMTsgTGludXggeDg2XzY0OyBydjo4OS4wKSBHZWNrby8yMDEwMDEwMSBGaXJlZm94Lzg5LjAKTW96aWxsYS81LjAgKFdpbmRvd3MgTlQgMTAuMDsgV2luNjQ7IHg2NCkgQXBwbGVXZWJLaXQvNTM3LjM2IChLSFRNTCwgbGlrZSBHZWNrbykgQ2hyb21lLzkxLjAuNDQ3Mi4xMjQgU2FmYXJpLzUzNy4zNiBFZGcvOTEuMC44NjQuNjQKTW96aWxsYS81LjAgKFdpbmRvd3MgTlQgMTAuMDsgV2luNjQ7IHg2NCkgQXBwbGVXZWJLaXQvNTM3LjM2IChLSFRNTCwgbGlrZSBHZWNrbykgQ2hyb21lLzkxLjAuNDQ3Mi4xMTQgU2FmYXJpLzUzNy4zNgpNb3ppbGxhLzUuMCAoV2luZG93cyBOVCAxMC4wOyBXaW42NDsgeDY0KSBBcHBsZVdlYktpdC81MzcuMzYgKEtIVE1MLCBsaWtlIEdlY2tvKSBDaHJvbWUvOTEuMC40NDcyLjEyNCBTYWZhcmkvNTM3LjM2IEVkZy85MS4wLjg2NC43MApNb3ppbGxhLzUuMCAoTWFjaW50b3NoOyBJbnRlbCBNYWMgT1MgWCAxMF8xNV83KSBBcHBsZVdlYktpdC81MzcuMzYgKEtIVE1MLCBsaWtlIEdlY2tvKSBDaHJvbWUvOTIuMC40NTE1LjEzMSBTYWZhcmkvNTM3LjM2Ck1vemlsbGEvNS4wIChYMTE7IExpbnV4IHg4Nl82NCkgQXBwbGVXZWJLaXQvNTM3LjM2IChLSFRNTCwgbGlrZSBHZWNrbykgQ2hyb21lLzkxLjAuNDQ3Mi4xNjQgU2FmYXJpLzUzNy4zNgpNb3ppbGxhLzUuMCAoV2luZG93cyBOVCA2LjE7IFdpbjY0OyB4NjQpIEFwcGxlV2ViS2l0LzUzNy4zNiAoS0hUTUwsIGxpa2UgR2Vja28pIENocm9tZS85MS4wLjQ0NzIuMTI0IFNhZmFyaS81MzcuMzYKTW96aWxsYS81LjAgKFdpbmRvd3MgTlQgMTAuMDsgV2luNjQ7IHg2NCkgQXBwbGVXZWJLaXQvNTM3LjM2IChLSFRNTCwgbGlrZSBHZWNrbykgQ2hyb21lLzkxLjAuNDQ3Mi4xNjQgU2FmYXJpLzUzNy4zNiBFZGcvOTEuMC44NjQuNzEKTW96aWxsYS81LjAgKE1hY2ludG9zaDsgSW50ZWwgTWFjIE9TIFggMTBfMTVfNikgQXBwbGVXZWJLaXQvNjA1LjEuMTUgKEtIVE1MLCBsaWtlIEdlY2tvKSBWZXJzaW9uLzE0LjEuMSBTYWZhcmkvNjA1LjEuMTUKTW96aWxsYS81LjAgKFdpbmRvd3MgTlQgMTAuMDsgV2luNjQ7IHg2NCkgQXBwbGVXZWJLaXQvNTM3LjM2IChLSFRNTCwgbGlrZSBHZWNrbykgQ2hyb21lLzkyLjAuNDUxNS4xMTUgU2FmYXJpLzUzNy4zNgpNb3ppbGxhLzUuMCAoV2luZG93cyBOVCA2LjM7IFdpbjY0OyB4NjQpIEFwcGxlV2ViS2l0LzUzNy4zNiAoS0hUTUwsIGxpa2UgR2Vja28pIENocm9tZS85MS4wLjQ0NzIuMTI0IFNhZmFyaS81MzcuMzYKTW96aWxsYS81LjAgKE1hY2ludG9zaDsgSW50ZWwgTWFjIE9TIFggMTBfMTRfNikgQXBwbGVXZWJLaXQvNTM3LjM2IChLSFRNTCwgbGlrZSBHZWNrbykgQ2hyb21lLzkxLjAuNDQ3Mi4xMTQgU2FmYXJpLzUzNy4zNgpNb3ppbGxhLzUuMCAoTWFjaW50b3NoOyBJbnRlbCBNYWMgT1MgWCAxMF8xNV83KSBBcHBsZVdlYktpdC82MDUuMS4xNSAoS0hUTUwsIGxpa2UgR2Vja28pIFZlcnNpb24vMTQuMSBTYWZhcmkvNjA1LjEuMTUKTW96aWxsYS81LjAgKFdpbmRvd3MgTlQgNi4xOyBXaW42NDsgeDY0KSBBcHBsZVdlYktpdC81MzcuMzYgKEtIVE1MLCBsaWtlIEdlY2tvKSBDaHJvbWUvOTIuMC40NTE1LjEwNyBTYWZhcmkvNTM3LjM2Ck1vemlsbGEvNS4wIChXaW5kb3dzIE5UIDEwLjA7IFdpbjY0OyB4NjQ7IHJ2Ojc4LjApIEdlY2tvLzIwMTAwMTAxIEZpcmVmb3gvNzguMApNb3ppbGxhLzUuMCAoV2luZG93cyBOVCAxMC4wOyBXaW42NDsgeDY0KSBBcHBsZVdlYktpdC81MzcuMzYgKEtIVE1MLCBsaWtlIEdlY2tvKSBDaHJvbWUvOTEuMC40NDcyLjEyNCBTYWZhcmkvNTM3LjM2IE9QUi83Ny4wLjQwNTQuMjAzCk1vemlsbGEvNS4wIChNYWNpbnRvc2g7IEludGVsIE1hYyBPUyBYIDEwXzE1XzYpIEFwcGxlV2ViS2l0LzYwNS4xLjE1IChLSFRNTCwgbGlrZSBHZWNrbykgVmVyc2lvbi8xNC4wLjMgU2FmYXJpLzYwNS4xLjE1Ck1vemlsbGEvNS4wIChXaW5kb3dzIE5UIDEwLjA7IFdpbjY0OyB4NjQpIEFwcGxlV2ViS2l0LzUzNy4zNiAoS0hUTUwsIGxpa2UgR2Vja28pIENocm9tZS85MS4wLjQ0NzIuMTY0IFNhZmFyaS81MzcuMzYgT1BSLzc3LjAuNDA1NC4yNzcKTW96aWxsYS81LjAgKE1hY2ludG9zaDsgSW50ZWwgTWFjIE9TIFggMTBfMTVfNykgQXBwbGVXZWJLaXQvNTM3LjM2IChLSFRNTCwgbGlrZSBHZWNrbykgQ2hyb21lLzkxLjAuNDQ3Mi4xMjQgU2FmYXJpLzUzNy4zNgpNb3ppbGxhLzUuMCAoV2luZG93cyBOVCAxMC4wOyBXaW42NDsgeDY0KSBBcHBsZVdlYktpdC81MzcuMzYgKEtIVE1MLCBsaWtlIEdlY2tvKSBDaHJvbWUvOTEuMC40NDcyLjc3IFNhZmFyaS81MzcuMzYKTW96aWxsYS81LjAgKFdpbmRvd3MgTlQgMTAuMDsgV2luNjQ7IHg2NCkgQXBwbGVXZWJLaXQvNTM3LjM2IChLSFRNTCwgbGlrZSBHZWNrbykgQ2hyb21lLzc2LjAuMzgwOS4xMDAgU2FmYXJpLzUzNy4zNgpNb3ppbGxhLzUuMCAoV2luZG93cyBOVCA2LjE7IFdpbjY0OyB4NjQ7IHJ2OjkwLjApIEdlY2tvLzIwMTAwMTAxIEZpcmVmb3gvOTAuMApNb3ppbGxhLzUuMCAoV2luZG93cyBOVCAxMC4wOyBXT1c2NCkgQXBwbGVXZWJLaXQvNTM3LjM2IChLSFRNTCwgbGlrZSBHZWNrbykgQ2hyb21lLzkxLjAuNDQ3Mi4xMjQgU2FmYXJpLzUzNy4zNgpNb3ppbGxhLzUuMCAoTWFjaW50b3NoOyBJbnRlbCBNYWMgT1MgWCAxMF8xNV83KSBBcHBsZVdlYktpdC82MDUuMS4xNSAoS0hUTUwsIGxpa2UgR2Vja28pIFZlcnNpb24vMTUuMCBTYWZhcmkvNjA1LjEuMTUKTW96aWxsYS81LjAgKFdpbmRvd3MgTlQgMTAuMDsgV2luNjQ7IHg2NCkgQXBwbGVXZWJLaXQvNTM3LjM2IChLSFRNTCwgbGlrZSBHZWNrbykgQ2hyb21lLzkwLjAuNDQzMC45MyBTYWZhcmkvNTM3LjM2Ck1vemlsbGEvNS4wIChXaW5kb3dzIE5UIDEwLjA7IFdpbjY0OyB4NjQ7IHJ2OjkxLjApIEdlY2tvLzIwMTAwMTAxIEZpcmVmb3gvOTEuMApNb3ppbGxhLzUuMCAoTWFjaW50b3NoOyBJbnRlbCBNYWMgT1MgWCAxMF8xNV83KSBBcHBsZVdlYktpdC81MzcuMzYgKEtIVE1MLCBsaWtlIEdlY2tvKSBDaHJvbWUvOTEuMC40NDcyLjc3IFNhZmFyaS81MzcuMzYKTW96aWxsYS81LjAgKE1hY2ludG9zaDsgSW50ZWwgTWFjIE9TIFggMTBfMTRfNikgQXBwbGVXZWJLaXQvNTM3LjM2IChLSFRNTCwgbGlrZSBHZWNrbykgQ2hyb21lLzkyLjAuNDUxNS4xMDcgU2FmYXJpLzUzNy4zNgpNb3ppbGxhLzUuMCAoTWFjaW50b3NoOyBJbnRlbCBNYWMgT1MgWCAxMC4xNTsgcnY6OTEuMCkgR2Vja28vMjAxMDAxMDEgRmlyZWZveC85MS4wCk1vemlsbGEvNS4wIChNYWNpbnRvc2g7IEludGVsIE1hYyBPUyBYIDEwXzE1XzcpIEFwcGxlV2ViS2l0LzUzNy4zNiAoS0hUTUwsIGxpa2UgR2Vja28pIENocm9tZS85MS4wLjQ0NzIuMTA2IFNhZmFyaS81MzcuMzYKTW96aWxsYS81LjAgKFdpbmRvd3MgTlQgMTAuMDsgV2luNjQ7IHg2NCkgQXBwbGVXZWJLaXQvNTM3LjM2IChLSFRNTCwgbGlrZSBHZWNrbykgQ2hyb21lLzkxLjAuNDQ3Mi4xMDYgU2FmYXJpLzUzNy4zNgpNb3ppbGxhLzUuMCAoV2luZG93cyBOVCA2LjE7IFdpbjY0OyB4NjQ7IHJ2Ojg5LjApIEdlY2tvLzIwMTAwMTAxIEZpcmVmb3gvODkuMApNb3ppbGxhLzUuMCAoV2luZG93cyBOVCA2LjM7IFdpbjY0OyB4NjQpIEFwcGxlV2ViS2l0LzUzNy4zNiAoS0hUTUwsIGxpa2UgR2Vja28pIENocm9tZS85Mi4wLjQ1MTUuMTA3IFNhZmFyaS81MzcuMzYKTW96aWxsYS81LjAgKFgxMTsgRmVkb3JhOyBMaW51eCB4ODZfNjQ7IHJ2Ojg5LjApIEdlY2tvLzIwMTAwMTAxIEZpcmVmb3gvODkuMApNb3ppbGxhLzUuMCAoWDExOyBGZWRvcmE7IExpbnV4IHg4Nl82NDsgcnY6OTAuMCkgR2Vja28vMjAxMDAxMDEgRmlyZWZveC85MC4wCk1vemlsbGEvNS4wIChNYWNpbnRvc2g7IEludGVsIE1hYyBPUyBYIDEwXzEzXzYpIEFwcGxlV2ViS2l0LzYwNS4xLjE1IChLSFRNTCwgbGlrZSBHZWNrbykgVmVyc2lvbi8xMy4xLjIgU2FmYXJpLzYwNS4xLjE1Ck1vemlsbGEvNS4wIChNYWNpbnRvc2g7IEludGVsIE1hYyBPUyBYIDEwXzE1XzcpIEFwcGxlV2ViS2l0LzUzNy4zNiAoS0hUTUwsIGxpa2UgR2Vja28pIENocm9tZS85MC4wLjQ0MzAuMjEyIFNhZmFyaS81MzcuMzYKTW96aWxsYS81LjAgKFdpbmRvd3MgTlQgMTAuMDsgV2luNjQ7IHg2NCkgQXBwbGVXZWJLaXQvNTM3LjM2IChLSFRNTCwgbGlrZSBHZWNrbykgQ2hyb21lLzkxLjAuNDQ3Mi4xNjQgU2FmYXJpLzUzNy4zNiBPUFIvNzcuMC40MDU0LjI3NQpNb3ppbGxhLzUuMCAoV2luZG93cyBOVCA2LjE7IFdpbjY0OyB4NjQpIEFwcGxlV2ViS2l0LzUzNy4zNiAoS0hUTUwsIGxpa2UgR2Vja28pIENocm9tZS85Mi4wLjQ1MTUuMTMxIFNhZmFyaS81MzcuMzYKTW96aWxsYS81LjAgKFgxMTsgTGludXggeDg2XzY0KSBBcHBsZVdlYktpdC81MzcuMzYgKEtIVE1MLCBsaWtlIEdlY2tvKSBDaHJvbWUvOTAuMC40NDMwLjIxMiBTYWZhcmkvNTM3LjM2Ck1vemlsbGEvNS4wIChYMTE7IExpbnV4IHg4Nl82NCkgQXBwbGVXZWJLaXQvNTM3LjM2IChLSFRNTCwgbGlrZSBHZWNrbykgQ2hyb21lLzkwLjAuNDQzMC45MyBTYWZhcmkvNTM3LjM2Ck1vemlsbGEvNS4wIChYMTE7IExpbnV4IHg4Nl82NCkgQXBwbGVXZWJLaXQvNTM3LjM2IChLSFRNTCwgbGlrZSBHZWNrbykgQ2hyb21lLzkxLjAuNDQ3Mi4xMjQgU2FmYXJpLzUzNy4zNgpNb3ppbGxhLzUuMCAoWDExOyBMaW51eCB4ODZfNjQpIEFwcGxlV2ViS2l0LzUzNy4zNiAoS0hUTUwsIGxpa2UgR2Vja28pIENocm9tZS85MS4wLjQ0NzIuNzcgU2FmYXJpLzUzNy4zNgpNb3ppbGxhLzUuMCAoTWFjaW50b3NoOyBJbnRlbCBNYWMgT1MgWCAxMF8xNV83KSBBcHBsZVdlYktpdC82MDUuMS4xNSAoS0hUTUwsIGxpa2UgR2Vja28pIFZlcnNpb24vMTMuMS4zIFNhZmFyaS82MDUuMS4xNQpNb3ppbGxhLzUuMCAoV2luZG93cyBOVCAxMC4wOyBydjo5MS4wKSBHZWNrby8yMDEwMDEwMSBGaXJlZm94LzkxLjAKTW96aWxsYS81LjAgKFdpbmRvd3MgTlQgNi4xOyBXT1c2NCkgQXBwbGVXZWJLaXQvNTM3LjM2IChLSFRNTCwgbGlrZSBHZWNrbykgQ2hyb21lLzg2LjAuNDI0MC4xOTggU2FmYXJpLzUzNy4zNgpNb3ppbGxhLzUuMCAoV2luZG93cyBOVCA2LjM7IFdpbjY0OyB4NjQ7IHJ2OjkwLjApIEdlY2tvLzIwMTAwMTAxIEZpcmVmb3gvOTAuMAo=' | base64 -d >"$TMP/userAgent.txt"
            fi
            ;;
        (2)
            printf " ...\n${BLACK_PINK}"
            echo 'TW96aWxsYS81LjAgKFdpbmRvd3MgTlQgMTAuMDsgV2luNjQ7IHg2NCkgQXBwbGVXZWJLaXQvNTM3LjM2IChLSFRNTCwgbGlrZSBHZWNrbykgQ2hyb21lLzkxLjAuNDQ3Mi4xMjQgU2FmYXJpLzUzNy4zNgpNb3ppbGxhLzUuMCAoV2luZG93cyBOVCAxMC4wOyBXaW42NDsgeDY0KSBBcHBsZVdlYktpdC81MzcuMzYgKEtIVE1MLCBsaWtlIEdlY2tvKSBDaHJvbWUvOTIuMC40NTE1LjEwNyBTYWZhcmkvNTM3LjM2Ck1vemlsbGEvNS4wIChNYWNpbnRvc2g7IEludGVsIE1hYyBPUyBYIDEwXzE1XzcpIEFwcGxlV2ViS2l0LzUzNy4zNiAoS0hUTUwsIGxpa2UgR2Vja28pIENocm9tZS85MS4wLjQ0NzIuMTE0IFNhZmFyaS81MzcuMzYKTW96aWxsYS81LjAgKFdpbmRvd3MgTlQgMTAuMDsgV2luNjQ7IHg2NDsgcnY6OTAuMCkgR2Vja28vMjAxMDAxMDEgRmlyZWZveC85MC4wCk1vemlsbGEvNS4wIChXaW5kb3dzIE5UIDEwLjA7IFdpbjY0OyB4NjQpIEFwcGxlV2ViS2l0LzUzNy4zNiAoS0hUTUwsIGxpa2UgR2Vja28pIENocm9tZS85MS4wLjQ0NzIuMTY0IFNhZmFyaS81MzcuMzYKTW96aWxsYS81LjAgKE1hY2ludG9zaDsgSW50ZWwgTWFjIE9TIFggMTBfMTVfNykgQXBwbGVXZWJLaXQvNjA1LjEuMTUgKEtIVE1MLCBsaWtlIEdlY2tvKSBWZXJzaW9uLzE0LjEuMSBTYWZhcmkvNjA1LjEuMTUKTW96aWxsYS81LjAgKFdpbmRvd3MgTlQgMTAuMDsgV2luNjQ7IHg2NDsgcnY6ODkuMCkgR2Vja28vMjAxMDAxMDEgRmlyZWZveC84OS4wCk1vemlsbGEvNS4wIChNYWNpbnRvc2g7IEludGVsIE1hYyBPUyBYIDEwXzE1XzcpIEFwcGxlV2ViS2l0LzUzNy4zNiAoS0hUTUwsIGxpa2UgR2Vja28pIENocm9tZS85Mi4wLjQ1MTUuMTA3IFNhZmFyaS81MzcuMzYKTW96aWxsYS81LjAgKFdpbmRvd3MgTlQgMTAuMDsgV2luNjQ7IHg2NCkgQXBwbGVXZWJLaXQvNTM3LjM2IChLSFRNTCwgbGlrZSBHZWNrbykgQ2hyb21lLzkyLjAuNDUxNS4xMzEgU2FmYXJpLzUzNy4zNgpNb3ppbGxhLzUuMCAoV2luZG93cyBOVCAxMC4wOyBydjo3OC4wKSBHZWNrby8yMDEwMDEwMSBGaXJlZm94Lzc4LjAKTW96aWxsYS81LjAgKE1hY2ludG9zaDsgSW50ZWwgTWFjIE9TIFggMTBfMTVfNykgQXBwbGVXZWJLaXQvNTM3LjM2IChLSFRNTCwgbGlrZSBHZWNrbykgQ2hyb21lLzkxLjAuNDQ3Mi4xNjQgU2FmYXJpLzUzNy4zNgpNb3ppbGxhLzUuMCAoWDExOyBVYnVudHU7IExpbnV4IHg4Nl82NDsgcnY6OTAuMCkgR2Vja28vMjAxMDAxMDEgRmlyZWZveC85MC4wCk1vemlsbGEvNS4wIChNYWNpbnRvc2g7IEludGVsIE1hYyBPUyBYIDEwLjE1OyBydjo5MC4wKSBHZWNrby8yMDEwMDEwMSBGaXJlZm94LzkwLjAKTW96aWxsYS81LjAgKFgxMTsgTGludXggeDg2XzY0KSBBcHBsZVdlYktpdC81MzcuMzYgKEtIVE1MLCBsaWtlIEdlY2tvKSBDaHJvbWUvOTEuMC40NDcyLjExNCBTYWZhcmkvNTM3LjM2Ck1vemlsbGEvNS4wIChYMTE7IExpbnV4IHg4Nl82NDsgcnY6OTAuMCkgR2Vja28vMjAxMDAxMDEgRmlyZWZveC85MC4wCk1vemlsbGEvNS4wIChNYWNpbnRvc2g7IEludGVsIE1hYyBPUyBYIDEwLjE1OyBydjo4OS4wKSBHZWNrby8yMDEwMDEwMSBGaXJlZm94Lzg5LjAKTW96aWxsYS81LjAgKFdpbmRvd3MgTlQgMTAuMDsgV2luNjQ7IHg2NCkgQXBwbGVXZWJLaXQvNTM3LjM2IChLSFRNTCwgbGlrZSBHZWNrbykgQ2hyb21lLzkyLjAuNDUxNS4xMDcgU2FmYXJpLzUzNy4zNiBFZGcvOTIuMC45MDIuNTUKTW96aWxsYS81LjAgKFgxMTsgVWJ1bnR1OyBMaW51eCB4ODZfNjQ7IHJ2Ojg5LjApIEdlY2tvLzIwMTAwMTAxIEZpcmVmb3gvODkuMApNb3ppbGxhLzUuMCAoTWFjaW50b3NoOyBJbnRlbCBNYWMgT1MgWCAxMF8xNV83KSBBcHBsZVdlYktpdC82MDUuMS4xNSAoS0hUTUwsIGxpa2UgR2Vja28pIFZlcnNpb24vMTQuMS4yIFNhZmFyaS82MDUuMS4xNQpNb3ppbGxhLzUuMCAoV2luZG93cyBOVCAxMC4wOyBXaW42NDsgeDY0KSBBcHBsZVdlYktpdC81MzcuMzYgKEtIVE1MLCBsaWtlIEdlY2tvKSBDaHJvbWUvOTEuMC40NDcyLjEyNCBTYWZhcmkvNTM3LjM2IEVkZy85MS4wLjg2NC42NwpNb3ppbGxhLzUuMCAoV2luZG93cyBOVCAxMC4wOyBXaW42NDsgeDY0KSBBcHBsZVdlYktpdC81MzcuMzYgKEtIVE1MLCBsaWtlIEdlY2tvKSBDaHJvbWUvOTIuMC40NTE1LjEwNyBTYWZhcmkvNTM3LjM2IEVkZy85Mi4wLjkwMi42MgpNb3ppbGxhLzUuMCAoWDExOyBMaW51eCB4ODZfNjQpIEFwcGxlV2ViS2l0LzUzNy4zNiAoS0hUTUwsIGxpa2UgR2Vja28pIENocm9tZS85Mi4wLjQ1MTUuMTA3IFNhZmFyaS81MzcuMzYKTW96aWxsYS81LjAgKFgxMTsgTGludXggeDg2XzY0OyBydjo3OC4wKSBHZWNrby8yMDEwMDEwMSBGaXJlZm94Lzc4LjAKTW96aWxsYS81LjAgKFgxMTsgTGludXggeDg2XzY0OyBydjo4OS4wKSBHZWNrby8yMDEwMDEwMSBGaXJlZm94Lzg5LjAKTW96aWxsYS81LjAgKFdpbmRvd3MgTlQgMTAuMDsgV2luNjQ7IHg2NCkgQXBwbGVXZWJLaXQvNTM3LjM2IChLSFRNTCwgbGlrZSBHZWNrbykgQ2hyb21lLzkxLjAuNDQ3Mi4xMjQgU2FmYXJpLzUzNy4zNiBFZGcvOTEuMC44NjQuNjQKTW96aWxsYS81LjAgKFdpbmRvd3MgTlQgMTAuMDsgV2luNjQ7IHg2NCkgQXBwbGVXZWJLaXQvNTM3LjM2IChLSFRNTCwgbGlrZSBHZWNrbykgQ2hyb21lLzkxLjAuNDQ3Mi4xMTQgU2FmYXJpLzUzNy4zNgpNb3ppbGxhLzUuMCAoV2luZG93cyBOVCAxMC4wOyBXaW42NDsgeDY0KSBBcHBsZVdlYktpdC81MzcuMzYgKEtIVE1MLCBsaWtlIEdlY2tvKSBDaHJvbWUvOTEuMC40NDcyLjEyNCBTYWZhcmkvNTM3LjM2IEVkZy85MS4wLjg2NC43MApNb3ppbGxhLzUuMCAoTWFjaW50b3NoOyBJbnRlbCBNYWMgT1MgWCAxMF8xNV83KSBBcHBsZVdlYktpdC81MzcuMzYgKEtIVE1MLCBsaWtlIEdlY2tvKSBDaHJvbWUvOTIuMC40NTE1LjEzMSBTYWZhcmkvNTM3LjM2Ck1vemlsbGEvNS4wIChYMTE7IExpbnV4IHg4Nl82NCkgQXBwbGVXZWJLaXQvNTM3LjM2IChLSFRNTCwgbGlrZSBHZWNrbykgQ2hyb21lLzkxLjAuNDQ3Mi4xNjQgU2FmYXJpLzUzNy4zNgpNb3ppbGxhLzUuMCAoV2luZG93cyBOVCA2LjE7IFdpbjY0OyB4NjQpIEFwcGxlV2ViS2l0LzUzNy4zNiAoS0hUTUwsIGxpa2UgR2Vja28pIENocm9tZS85MS4wLjQ0NzIuMTI0IFNhZmFyaS81MzcuMzYKTW96aWxsYS81LjAgKFdpbmRvd3MgTlQgMTAuMDsgV2luNjQ7IHg2NCkgQXBwbGVXZWJLaXQvNTM3LjM2IChLSFRNTCwgbGlrZSBHZWNrbykgQ2hyb21lLzkxLjAuNDQ3Mi4xNjQgU2FmYXJpLzUzNy4zNiBFZGcvOTEuMC44NjQuNzEKTW96aWxsYS81LjAgKE1hY2ludG9zaDsgSW50ZWwgTWFjIE9TIFggMTBfMTVfNikgQXBwbGVXZWJLaXQvNjA1LjEuMTUgKEtIVE1MLCBsaWtlIEdlY2tvKSBWZXJzaW9uLzE0LjEuMSBTYWZhcmkvNjA1LjEuMTUKTW96aWxsYS81LjAgKFdpbmRvd3MgTlQgMTAuMDsgV2luNjQ7IHg2NCkgQXBwbGVXZWJLaXQvNTM3LjM2IChLSFRNTCwgbGlrZSBHZWNrbykgQ2hyb21lLzkyLjAuNDUxNS4xMTUgU2FmYXJpLzUzNy4zNgpNb3ppbGxhLzUuMCAoV2luZG93cyBOVCA2LjM7IFdpbjY0OyB4NjQpIEFwcGxlV2ViS2l0LzUzNy4zNiAoS0hUTUwsIGxpa2UgR2Vja28pIENocm9tZS85MS4wLjQ0NzIuMTI0IFNhZmFyaS81MzcuMzYKTW96aWxsYS81LjAgKE1hY2ludG9zaDsgSW50ZWwgTWFjIE9TIFggMTBfMTRfNikgQXBwbGVXZWJLaXQvNTM3LjM2IChLSFRNTCwgbGlrZSBHZWNrbykgQ2hyb21lLzkxLjAuNDQ3Mi4xMTQgU2FmYXJpLzUzNy4zNgpNb3ppbGxhLzUuMCAoTWFjaW50b3NoOyBJbnRlbCBNYWMgT1MgWCAxMF8xNV83KSBBcHBsZVdlYktpdC82MDUuMS4xNSAoS0hUTUwsIGxpa2UgR2Vja28pIFZlcnNpb24vMTQuMSBTYWZhcmkvNjA1LjEuMTUKTW96aWxsYS81LjAgKFdpbmRvd3MgTlQgNi4xOyBXaW42NDsgeDY0KSBBcHBsZVdlYktpdC81MzcuMzYgKEtIVE1MLCBsaWtlIEdlY2tvKSBDaHJvbWUvOTIuMC40NTE1LjEwNyBTYWZhcmkvNTM3LjM2Ck1vemlsbGEvNS4wIChXaW5kb3dzIE5UIDEwLjA7IFdpbjY0OyB4NjQ7IHJ2Ojc4LjApIEdlY2tvLzIwMTAwMTAxIEZpcmVmb3gvNzguMApNb3ppbGxhLzUuMCAoV2luZG93cyBOVCAxMC4wOyBXaW42NDsgeDY0KSBBcHBsZVdlYktpdC81MzcuMzYgKEtIVE1MLCBsaWtlIEdlY2tvKSBDaHJvbWUvOTEuMC40NDcyLjEyNCBTYWZhcmkvNTM3LjM2IE9QUi83Ny4wLjQwNTQuMjAzCk1vemlsbGEvNS4wIChNYWNpbnRvc2g7IEludGVsIE1hYyBPUyBYIDEwXzE1XzYpIEFwcGxlV2ViS2l0LzYwNS4xLjE1IChLSFRNTCwgbGlrZSBHZWNrbykgVmVyc2lvbi8xNC4wLjMgU2FmYXJpLzYwNS4xLjE1Ck1vemlsbGEvNS4wIChXaW5kb3dzIE5UIDEwLjA7IFdpbjY0OyB4NjQpIEFwcGxlV2ViS2l0LzUzNy4zNiAoS0hUTUwsIGxpa2UgR2Vja28pIENocm9tZS85MS4wLjQ0NzIuMTY0IFNhZmFyaS81MzcuMzYgT1BSLzc3LjAuNDA1NC4yNzcKTW96aWxsYS81LjAgKE1hY2ludG9zaDsgSW50ZWwgTWFjIE9TIFggMTBfMTVfNykgQXBwbGVXZWJLaXQvNTM3LjM2IChLSFRNTCwgbGlrZSBHZWNrbykgQ2hyb21lLzkxLjAuNDQ3Mi4xMjQgU2FmYXJpLzUzNy4zNgpNb3ppbGxhLzUuMCAoV2luZG93cyBOVCAxMC4wOyBXaW42NDsgeDY0KSBBcHBsZVdlYktpdC81MzcuMzYgKEtIVE1MLCBsaWtlIEdlY2tvKSBDaHJvbWUvOTEuMC40NDcyLjc3IFNhZmFyaS81MzcuMzYKTW96aWxsYS81LjAgKFdpbmRvd3MgTlQgMTAuMDsgV2luNjQ7IHg2NCkgQXBwbGVXZWJLaXQvNTM3LjM2IChLSFRNTCwgbGlrZSBHZWNrbykgQ2hyb21lLzc2LjAuMzgwOS4xMDAgU2FmYXJpLzUzNy4zNgpNb3ppbGxhLzUuMCAoV2luZG93cyBOVCA2LjE7IFdpbjY0OyB4NjQ7IHJ2OjkwLjApIEdlY2tvLzIwMTAwMTAxIEZpcmVmb3gvOTAuMApNb3ppbGxhLzUuMCAoV2luZG93cyBOVCAxMC4wOyBXT1c2NCkgQXBwbGVXZWJLaXQvNTM3LjM2IChLSFRNTCwgbGlrZSBHZWNrbykgQ2hyb21lLzkxLjAuNDQ3Mi4xMjQgU2FmYXJpLzUzNy4zNgpNb3ppbGxhLzUuMCAoTWFjaW50b3NoOyBJbnRlbCBNYWMgT1MgWCAxMF8xNV83KSBBcHBsZVdlYktpdC82MDUuMS4xNSAoS0hUTUwsIGxpa2UgR2Vja28pIFZlcnNpb24vMTUuMCBTYWZhcmkvNjA1LjEuMTUKTW96aWxsYS81LjAgKFdpbmRvd3MgTlQgMTAuMDsgV2luNjQ7IHg2NCkgQXBwbGVXZWJLaXQvNTM3LjM2IChLSFRNTCwgbGlrZSBHZWNrbykgQ2hyb21lLzkwLjAuNDQzMC45MyBTYWZhcmkvNTM3LjM2Ck1vemlsbGEvNS4wIChXaW5kb3dzIE5UIDEwLjA7IFdpbjY0OyB4NjQ7IHJ2OjkxLjApIEdlY2tvLzIwMTAwMTAxIEZpcmVmb3gvOTEuMApNb3ppbGxhLzUuMCAoTWFjaW50b3NoOyBJbnRlbCBNYWMgT1MgWCAxMF8xNV83KSBBcHBsZVdlYktpdC81MzcuMzYgKEtIVE1MLCBsaWtlIEdlY2tvKSBDaHJvbWUvOTEuMC40NDcyLjc3IFNhZmFyaS81MzcuMzYKTW96aWxsYS81LjAgKE1hY2ludG9zaDsgSW50ZWwgTWFjIE9TIFggMTBfMTRfNikgQXBwbGVXZWJLaXQvNTM3LjM2IChLSFRNTCwgbGlrZSBHZWNrbykgQ2hyb21lLzkyLjAuNDUxNS4xMDcgU2FmYXJpLzUzNy4zNgpNb3ppbGxhLzUuMCAoTWFjaW50b3NoOyBJbnRlbCBNYWMgT1MgWCAxMC4xNTsgcnY6OTEuMCkgR2Vja28vMjAxMDAxMDEgRmlyZWZveC85MS4wCk1vemlsbGEvNS4wIChNYWNpbnRvc2g7IEludGVsIE1hYyBPUyBYIDEwXzE1XzcpIEFwcGxlV2ViS2l0LzUzNy4zNiAoS0hUTUwsIGxpa2UgR2Vja28pIENocm9tZS85MS4wLjQ0NzIuMTA2IFNhZmFyaS81MzcuMzYKTW96aWxsYS81LjAgKFdpbmRvd3MgTlQgMTAuMDsgV2luNjQ7IHg2NCkgQXBwbGVXZWJLaXQvNTM3LjM2IChLSFRNTCwgbGlrZSBHZWNrbykgQ2hyb21lLzkxLjAuNDQ3Mi4xMDYgU2FmYXJpLzUzNy4zNgpNb3ppbGxhLzUuMCAoV2luZG93cyBOVCA2LjE7IFdpbjY0OyB4NjQ7IHJ2Ojg5LjApIEdlY2tvLzIwMTAwMTAxIEZpcmVmb3gvODkuMApNb3ppbGxhLzUuMCAoV2luZG93cyBOVCA2LjM7IFdpbjY0OyB4NjQpIEFwcGxlV2ViS2l0LzUzNy4zNiAoS0hUTUwsIGxpa2UgR2Vja28pIENocm9tZS85Mi4wLjQ1MTUuMTA3IFNhZmFyaS81MzcuMzYKTW96aWxsYS81LjAgKFgxMTsgRmVkb3JhOyBMaW51eCB4ODZfNjQ7IHJ2Ojg5LjApIEdlY2tvLzIwMTAwMTAxIEZpcmVmb3gvODkuMApNb3ppbGxhLzUuMCAoWDExOyBGZWRvcmE7IExpbnV4IHg4Nl82NDsgcnY6OTAuMCkgR2Vja28vMjAxMDAxMDEgRmlyZWZveC85MC4wCk1vemlsbGEvNS4wIChNYWNpbnRvc2g7IEludGVsIE1hYyBPUyBYIDEwXzEzXzYpIEFwcGxlV2ViS2l0LzYwNS4xLjE1IChLSFRNTCwgbGlrZSBHZWNrbykgVmVyc2lvbi8xMy4xLjIgU2FmYXJpLzYwNS4xLjE1Ck1vemlsbGEvNS4wIChNYWNpbnRvc2g7IEludGVsIE1hYyBPUyBYIDEwXzE1XzcpIEFwcGxlV2ViS2l0LzUzNy4zNiAoS0hUTUwsIGxpa2UgR2Vja28pIENocm9tZS85MC4wLjQ0MzAuMjEyIFNhZmFyaS81MzcuMzYKTW96aWxsYS81LjAgKFdpbmRvd3MgTlQgMTAuMDsgV2luNjQ7IHg2NCkgQXBwbGVXZWJLaXQvNTM3LjM2IChLSFRNTCwgbGlrZSBHZWNrbykgQ2hyb21lLzkxLjAuNDQ3Mi4xNjQgU2FmYXJpLzUzNy4zNiBPUFIvNzcuMC40MDU0LjI3NQpNb3ppbGxhLzUuMCAoV2luZG93cyBOVCA2LjE7IFdpbjY0OyB4NjQpIEFwcGxlV2ViS2l0LzUzNy4zNiAoS0hUTUwsIGxpa2UgR2Vja28pIENocm9tZS85Mi4wLjQ1MTUuMTMxIFNhZmFyaS81MzcuMzYKTW96aWxsYS81LjAgKFgxMTsgTGludXggeDg2XzY0KSBBcHBsZVdlYktpdC81MzcuMzYgKEtIVE1MLCBsaWtlIEdlY2tvKSBDaHJvbWUvOTAuMC40NDMwLjIxMiBTYWZhcmkvNTM3LjM2Ck1vemlsbGEvNS4wIChYMTE7IExpbnV4IHg4Nl82NCkgQXBwbGVXZWJLaXQvNTM3LjM2IChLSFRNTCwgbGlrZSBHZWNrbykgQ2hyb21lLzkwLjAuNDQzMC45MyBTYWZhcmkvNTM3LjM2Ck1vemlsbGEvNS4wIChYMTE7IExpbnV4IHg4Nl82NCkgQXBwbGVXZWJLaXQvNTM3LjM2IChLSFRNTCwgbGlrZSBHZWNrbykgQ2hyb21lLzkxLjAuNDQ3Mi4xMjQgU2FmYXJpLzUzNy4zNgpNb3ppbGxhLzUuMCAoWDExOyBMaW51eCB4ODZfNjQpIEFwcGxlV2ViS2l0LzUzNy4zNiAoS0hUTUwsIGxpa2UgR2Vja28pIENocm9tZS85MS4wLjQ0NzIuNzcgU2FmYXJpLzUzNy4zNgpNb3ppbGxhLzUuMCAoTWFjaW50b3NoOyBJbnRlbCBNYWMgT1MgWCAxMF8xNV83KSBBcHBsZVdlYktpdC82MDUuMS4xNSAoS0hUTUwsIGxpa2UgR2Vja28pIFZlcnNpb24vMTMuMS4zIFNhZmFyaS82MDUuMS4xNQpNb3ppbGxhLzUuMCAoV2luZG93cyBOVCAxMC4wOyBydjo5MS4wKSBHZWNrby8yMDEwMDEwMSBGaXJlZm94LzkxLjAKTW96aWxsYS81LjAgKFdpbmRvd3MgTlQgNi4xOyBXT1c2NCkgQXBwbGVXZWJLaXQvNTM3LjM2IChLSFRNTCwgbGlrZSBHZWNrbykgQ2hyb21lLzg2LjAuNDI0MC4xOTggU2FmYXJpLzUzNy4zNgpNb3ppbGxhLzUuMCAoV2luZG93cyBOVCA2LjM7IFdpbjY0OyB4NjQ7IHJ2OjkwLjApIEdlY2tvLzIwMTAwMTAxIEZpcmVmb3gvOTAuMAo=' | base64 -d >"$TMP/userAgent.txt"
            echo "0" >"$HOME/twm/fileAgent.txt"  # Save selection to file
            printf "Automatic User Agent selected\n${COLOR_RESET}"
            ;;
        (*)
            clear  # Clear the screen for invalid input handling
            if [ -n "$UA" ]; then
                printf "\n Invalid option: $(echo "$UA")\n"
                kill -9 $$  # Terminate the script on invalid input
            else
                printf "\n Time exceeded!\n"
            fi
            ;;
    esac

    unset UA  # Clear the UA variable after use

  }

  # Check if the user agent file is missing or has an invalid size; if so, prompt for a new one.
  if [ ! -e "$TMP/userAgent.txt" ] || [ $(cat "$TMP/userAgent.txt" | wc -c) -lt 10 ] || [ $(cat "$TMP/userAgent.txt" | wc -c) -gt 65 ]; then
      user_agent  # Call function to set up user agent if conditions are met.
  else
      # Display a random user agent from the existing list.
      printf "${BLACK_PINK}\nUser-Agent: $(shuf -n 1 "$TMP/userAgent.txt")\n${COLOR_RESET}\n"
  fi

  # Convert DOS line endings to Unix format in the user agent file (if necessary)
  sed -i 's/^M$//g' "$TMP/userAgent.txt" &>/dev/null  # Remove carriage return characters (DOS)
  sed -i 's/\x0D$//g' "$TMP/userAgent.txt" &>/dev/null  # Another method to ensure line endings are clean

}
