func_proxy () {
	case "$UR" in
	'1'|'2'|'3'|4|6|7|9|'11'|'12')
# Set fallback proxy for UR values 1, 4, 6, 7, 9, 11, or 12
		PROXY="$(echo 'aHR0cDovLzEzOC4yMDEuMTc4LjE4Mzo4MA==' | base64 -d)"
		;;
	5)
# Set fallback proxy for UR value 5
		PROXY="$(echo 'aHR0cDovLzE0NC43Ni43Ny44Nzo4MA==' | base64 -d)"
		;;
	8|'13')
# Set fallback proxy for UR values 8 or 13
		PROXY="$(echo 'aHR0cDovLzE3Ni45LjIxLjIwOjgw' | base64 -d)"
		;;
	'10')
# Set fallback proxy for UR value 10
		PROXY="$(echo 'aHR0cDovLzE0OC4yNTEuMjQ0LjI3Ojgw' | base64 -d)"
		;;
	*)
# Handle invalid UR values by printing an error message
		echo "Invalid UR value"
		;;
	esac

# Print the server and proxy information to the console
	printf "${BLACK_GRAY} Server: ${URL}|${PROXY} ${COLOR_RESET}\n"
	sleep 2s
}