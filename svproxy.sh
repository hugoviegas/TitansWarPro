func_proxy() {
    # Use drill to get the IP address of the specified URL and format it as a proxy
    SPROXY=$(drill "${URL}" 2>/dev/null | grep -o -E "([0-9]{1,3}\.){3}[0-9]{1,3}" | sed -n 's/^.*$/&:80/;1p')
    
    # Set the PROXY variable using the retrieved IP address
    PROXY="http://$SPROXY"

    # Check if the server proxy is one of the known values or if SPROXY is empty
    if echo "$SVPROXY" | grep -q '8.8.8.8:80' || echo "$SVPROXY" | grep -q '1.1.1.1:80' || [ -z "$SPROXY" ]; then
        # Set PROXY based on the value of UR
        if [ "$UR" -eq '1' ] || echo "$UR" | grep -q '3'; then
            PROXY="http://176.9.21.20:80"  # Fallback proxy for UR 1 or 3
        elif [ "$UR" -ge 4 ]; then
            PROXY="http://138.201.178.183:80"  # Fallback proxy for UR 4 or higher
        elif echo "$UR" | grep -q "2"; then
            PROXY="http://148.251.244.27:80"  # Fallback proxy for UR 2
        fi
    fi

    # Print the server and proxy information to the console
    printf "${BLACK_GRAY} Server: ${URL}|${PROXY} ${COLOR_RESET}\n"
    
    # Unset SVPROXY to clean up the environment
    unset SVPROXY
}