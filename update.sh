#!/bin/sh
# ===========================================================================
# update.sh - TitansWarPro
# Branches: 1-Master | 2-Beta | 3-Beta2 | 4-Other | 5-AI Engine
# Bidirectional clean: switching branches removes incompatible files
# ===========================================================================

clear

BLACK_CYAN='\033[01;36m\033[01;07m'
BLACK_GREEN='\033[00;32m\033[01;07m'
BLACK_YELLOW='\033[00;33m\033[01;07m'
GOLD_BLACK='\033[33m'
CYAN_BLACK='\033[36m'
RED_BLACK='\033[31m'
COLOR_RESET='\033[00m'

# ---------------------------------------------------------------------------
# Files EXCLUSIVE to ai-engine (not present in beta2/master/beta)
# Removing these on downgrade to beta2 ensures a clean slate
# ---------------------------------------------------------------------------
AI_ENGINE_FILES="
  core/helpers.sh
  ai/orchestrator.py
  ai/analyzer.py
  ai/patcher.py
  ai/gemini_client.py
  ai/requirements.txt
  data/configs/strategy_config.json
  AI_ENGINE.md
"

# Files EXCLUSIVE to beta2 that clash with ai-engine structure
# (none currently - ai-engine is additive)
# Kept as placeholder for future incompatible files
BETA2_EXCLUSIVE_FILES=""

# ---------------------------------------------------------------------------
# Branch cleanup logic
# $1 = target branch being installed
# ---------------------------------------------------------------------------
_clean_for_branch() {
    local target="$1"
    local twm_dir="$HOME/twm"

    case "$target" in
        beta2|master|beta)
            # Downgrading from ai-engine: remove ai-engine exclusive files
            _had_ai=0
            for f in $AI_ENGINE_FILES; do
                f=$(echo "$f" | sed 's/^[ \t]*//')
                [ -z "$f" ] && continue
                local full="$twm_dir/$f"
                if [ -e "$full" ]; then
                    rm -rf "$full"
                    printf "  ${RED_BLACK}🗑️  Removed ai-engine file: %s${COLOR_RESET}\n" "$f"
                    _had_ai=1
                fi
            done
            if [ "$_had_ai" -eq 1 ]; then
                printf "  ${BLACK_YELLOW}⚠️  AI Engine files removed. Returning to %s.${COLOR_RESET}\n" "$target"
            fi
            # Also stop orchestrator if running
            if command -v pkill >/dev/null 2>&1; then
                pkill -f "orchestrator.py" 2>/dev/null && \
                    printf "  ${BLACK_YELLOW}🛑  Stopped AI orchestrator process.${COLOR_RESET}\n"
            fi
            ;;

        ai-engine)
            # Upgrading to ai-engine: remove beta2-exclusive files if any conflict
            _had_beta=0
            for f in $BETA2_EXCLUSIVE_FILES; do
                f=$(echo "$f" | sed 's/^[ \t]*//')
                [ -z "$f" ] && continue
                local full="$twm_dir/$f"
                if [ -e "$full" ]; then
                    rm -rf "$full"
                    printf "  ${RED_BLACK}🗑️  Removed beta2-exclusive file: %s${COLOR_RESET}\n" "$f"
                    _had_beta=1
                fi
            done
            [ "$_had_beta" -eq 1 ] && \
                printf "  ${BLACK_YELLOW}⚠️  Cleaned beta2 exclusive files before AI Engine install.${COLOR_RESET}\n"
            ;;
    esac
}

# ---------------------------------------------------------------------------
# Version selection
# ---------------------------------------------------------------------------
if [ $# -eq 1 ]; then
    case $1 in
        1) VERSION="Master"    ;;
        2) VERSION="Beta"      ;;
        3) VERSION="Beta2"     ;;
        4) VERSION="Main"      ;;
        5) VERSION="Ai-engine" ;;
        *)
            echo "Invalid selection. Use 1-Master 2-Beta 3-Beta2 4-Other 5-AI."
            exit 1
            ;;
    esac
else
    printf "Versions\n 1- Master\n 2- Beta\n 3- Beta2\n 4- Other Macro (delete all)\n 5- AI Engine (self-improving)\n"
    printf "${CYAN_BLACK}Select the version:${COLOR_RESET} \n"
    stty raw
    VERSION=$(dd bs=1 count=1 2>/dev/null)
    stty -raw
    case $VERSION in
        1) VERSION="Master"    ;;
        2) VERSION="Beta"      ;;
        3) VERSION="Beta2"     ;;
        4)
            VERSION="Main"
            rm -rf ~/twm
            ;;
        5) VERSION="Ai-engine" ;;
        *)
            echo "Invalid selection. Exiting."
            exit 1
            ;;
    esac
fi

version=$(echo "$VERSION" | sed 's/[ \t]//g' | tr "[[:upper:]]" "[[:lower:]]")

printf "\n${CYAN_BLACK}🔧 Preparing${COLOR_RESET} ${GOLD_BLACK}$VERSION${COLOR_RESET} ${CYAN_BLACK}repository source...${COLOR_RESET}\n"

mkdir -p ~/twm
cd ~/twm || exit

# Run branch cleanup before downloading
_clean_for_branch "$version"

# ---------------------------------------------------------------------------
# Download easyinstall.sh + info.sh from target branch
# ---------------------------------------------------------------------------
SCRIPTS="easyinstall.sh info.sh"
rm -rf "${HOME}*/$SCRIPTS" "$SCRIPTS" 2>/dev/null
SERVER="https://raw.githubusercontent.com/hugoviegas/TitansWarPro/${version}/"
NUM_SCRIPTS=$(echo "$SCRIPTS" | wc -w)
LEN=0

for script in $SCRIPTS; do
    LEN=$((LEN + 1))
    label=$(printf "[%02d/%02d]" "$LEN" "$NUM_SCRIPTS")
    local_file="$HOME/twm/$script"
    temp_file="$local_file.tmp.$$"

    if [ ! -e "$local_file" ]; then
        if curl "${SERVER}${script}" -s -L -o "$local_file" 2>/dev/null; then
            printf "  🆕 %s %-32s ${BLACK_YELLOW}new${COLOR_RESET}\n" "$label" "$script"
        else
            printf "  ⚠️  %s %-32s ${BLACK_YELLOW}skipped${COLOR_RESET}\n" "$label" "$script"
        fi
    else
        if curl "${SERVER}${script}" -s -L -o "$temp_file" 2>/dev/null; then
            local_hash=$(sha256sum "$local_file" 2>/dev/null | awk '{print $1}')
            remote_hash=$(sha256sum "$temp_file" 2>/dev/null | awk '{print $1}')
            if [ "$remote_hash" = "$local_hash" ]; then
                rm -f "$temp_file"
                printf "  ✅ %s %-32s ${BLACK_CYAN}unchanged${COLOR_RESET}\n" "$label" "$script"
            else
                mv "$temp_file" "$local_file"
                printf "  🔽 %s %-32s ${BLACK_GREEN}updated${COLOR_RESET}\n" "$label" "$script"
            fi
        else
            rm -f "$temp_file"
            printf "  ⚠️  %s %-32s ${BLACK_YELLOW}skipped${COLOR_RESET}\n" "$label" "$script"
        fi
    fi

    chmod +x "$local_file"
    cp "$local_file" "$HOME/$script" 2>/dev/null
    sleep 0.1s
done

printf "\n${BLACK_GREEN}✅ Updated repository source${COLOR_RESET}\n\n${BLACK_CYAN}Starting ./easyinstall.sh $version ...${COLOR_RESET}\n"
sleep 2s
./easyinstall.sh "$version"
