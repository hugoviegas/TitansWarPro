#!/bin/bash
# Test script for do_missions function

# Set up minimal account context for testing
export ACCOUNT_ID="Gt"
export HOME="${HOME:-/c/Users/hugov}"
export ACCOUNT_ROOT="${HOME}/twm/accounts/${ACCOUNT_ID}"
export W3M_HOME="${ACCOUNT_ROOT}/w3m"
export TMP="${ACCOUNT_ROOT}/tmp/.1"
export CONFIG_FILE="${ACCOUNT_ROOT}/config.cfg"
export LANGUAGE="pt"

# Create TMP directory if missing
mkdir -p "$TMP" "$W3M_HOME"

# Source all required files in order
echo "Sourcing files..."
. ./colors.sh || { echo "ERROR: colors.sh not found"; exit 1; }
. ./requeriments.sh || { echo "ERROR: requeriments.sh not found"; exit 1; }
. ./info.sh || { echo "ERROR: info.sh not found"; exit 1; }
. ./check.sh || { echo "ERROR: check.sh not found"; exit 1; }
. ./missions.sh || { echo "ERROR: missions.sh not found"; exit 1; }

# Initialize colors
colors

# Test mission_debug function
echo ""
echo_t "Testing mission_debug()..." "$GOLD_BLACK" "$COLOR_RESET" "before" "📜"
echo ""

# Run mission_debug
mission_debug

echo ""
echo_t "Test complete!" "$GREEN_BLACK" "$COLOR_RESET" "after" "✅"
