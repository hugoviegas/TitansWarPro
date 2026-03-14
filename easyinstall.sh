#!/bin/sh

# ─── Bootstrap ────────────────────────────────────────────────────────────────
mkdir -p ~/twm ~/twm/accounts

VERSION="${1:-master}"
SERVER="https://raw.githubusercontent.com/hugoviegas/TitansWarPro/$VERSION/"

if [ ! -e "$HOME/twm/info.sh" ]; then
  curl "${SERVER}info.sh" -s -L -o "$HOME/twm/info.sh"
  chmod +x ~/twm/info.sh
fi

# shellcheck disable=SC1090
. ~/twm/info.sh
colors
script_slogan

cd ~/twm || exit

# ─── Platform setup ───────────────────────────────────────────────────────────
cd ~/ || exit

# Termux (Android)
if [ -d /data/data/com.termux/files/usr/share/doc ]; then
  termux-wake-lock
  grep -q "nameserver 1.1.1.1" "$PREFIX/etc/resolv.conf" 2>/dev/null || \
    printf "nameserver 1.1.1.1\nnameserver 1.0.0.1\n" >> "$PREFIX/etc/resolv.conf" 2>/dev/null
  grep -q "nameserver 8.8.8.8" "$PREFIX/etc/resolv.conf" 2>/dev/null || \
    printf "nameserver 8.8.8.8\n" >> "$PREFIX/etc/resolv.conf" 2>/dev/null

  rm -f ~/.termux/boot/play.sh 2>/dev/null
  mkdir -p ~/.termux/boot
  printf "IyEvZGF0YS9kYXRhL2NvbS50ZXJtdXgvZmlsZXMvdXNyL2Jpbi9zaApiYXNoICRIT01FL3R3bS90d20uc2ggLWJvb3QK" | base64 -d >~/.termux/boot/play.sh 2>/dev/null
  chmod +x ~/.termux/boot/play.sh 2>/dev/null

  printf "${BLACK_CYAN}  Checking Termux packages...${COLOR_RESET}\n"
  command -v w3m  >/dev/null 2>&1 || pkg install w3m -y
  command -v jq   >/dev/null 2>&1 || pkg install jq -y
  [ -d /data/data/com.termux/files/usr/share/doc/coreutils ] || pkg install coreutils ncurses-utils -y
  [ -d /data/data/com.termux/files/usr/share/doc/termux-api ] || pkg install termux-api -y
  [ -d /data/data/com.termux/files/usr/share/doc/procps    ] || pkg install procps ncurses-utils -y
fi

# Cygwin (Windows)
if uname | grep -q -i "cygwin"; then
  LS="/usr/share/doc"
  if [ ! -e /bin/apt-cyg ]; then
    curl -s -L -O "https://raw.githubusercontent.com/hugoviegas/TitansWarPro/beta/apt-cyg"
    install apt-cyg /bin
  fi
  [ -e "${LS}/w3m"          ] || apt-cyg install w3m -y
  [ -e "${LS}/ncurses-term" ] || apt-cyg install ncurses-term -y
  [ -e "${LS}/coreutils"    ] || apt-cyg install coreutils -y
  [ -e "${LS}/procps"       ] || apt-cyg install procps -y
  [ -e "${LS}/jq"           ] || apt-cyg install jq -y
  unset LS
fi

# iSH (iPhone) / UserLAnd / Generic Linux / WSL
APPISH=$(uname -a | grep -o "\-ish")
if [ "$SHELL" = "/bin/ash" ] && [ "$APPISH" = '-ish' ]; then
  printf "${BLACK_CYAN}Install the necessary packages for Alpine on app ISh (iPhone):${COLOR_RESET}\n"
  printf "  apk update\n  apk add curl; apk add w3m; apk add coreutils; apk add --no-cache tzdata\n\n"
  sleep 5s
elif [ "$APPISH" != '-ish' ] && uname -m | grep -q -E '(aarch64|armhf|armv7|mips64)' && [ ! -d /data/data/com.termux ]; then
  printf "${BLACK_CYAN}Install the necessary packages for Alpine on app UserLAnd (Android):${COLOR_RESET}\n"
  printf "  apk update\n  sudo apk add curl; sudo apk add w3m; sudo apk add coreutils; sudo apk add --no-cache tzdata\n\n"
  sleep 5s
elif [ "$APPISH" != '-ish' ] && uname -m | grep -q -E "(ppc64le|riscv64|s390x|x86|x86_64)" && [ ! -d /data/data/com.termux ]; then
  printf "${BLACK_CYAN}Install required packages for Linux or Windows WSL:${COLOR_RESET}\n"
  printf "  sudo apt update\n  sudo apt install curl coreutils ncurses-term procps w3m jq -y\n"
  sleep 5s
fi
unset APPISH

cd ~/twm || exit

# ─── Download helpers ─────────────────────────────────────────────────────────

sync_func() {
  SCRIPTS="allies.sh altars.sh arena.sh campaign.sh career.sh cave.sh check.sh \
clancoliseum.sh clandmg.sh clanfight.sh clanid.sh coliseum.sh crono.sh \
flagfight.sh function.sh king.sh language.sh league.sh loginlogoff.sh \
play.sh requeriments.sh run.sh svproxy.sh specialevent.sh trade.sh twm.sh \
undying.sh update_check.sh multi_runner.sh twm_view.sh twm_monitor.sh \
twm_control.sh twm_setup.sh"

  NUM_SCRIPTS=$(echo "$SCRIPTS" | wc -w)
  LEN=0 UPDATED=0 NEW=0 OK=0 FAILED=0

  printf "${BLACK_CYAN}  ⬇  Downloading scripts...${COLOR_RESET}\n\n"

  for script in $SCRIPTS; do
    LEN=$((LEN + 1))
    label=$(printf "[%02d/%02d]" "$LEN" "$NUM_SCRIPTS")
    existed=false
    [ -e ~/twm/"$script" ] && existed=true

    if curl "${SERVER}$script" -s -L -o ~/twm/"$script" 2>/dev/null; then
      if $existed; then
        printf "  🔽 %s %-32s ${GREENb_BLACK}updated${COLOR_RESET}\n" "$label" "$script"
        UPDATED=$((UPDATED + 1))
      else
        printf "  🆕 %s %-32s ${BLACK_YELLOW}new${COLOR_RESET}\n" "$label" "$script"
        NEW=$((NEW + 1))
      fi
    else
      printf "  ⚠️  %s %-32s ${BLACK_YELLOW}skipped${COLOR_RESET}\n" "$label" "$script"
      FAILED=$((FAILED + 1))
    fi
  done

  # DOS to Unix + permissions
  find ~/twm -type f -name '*.sh' -print0 | xargs -0 sed -i 's/\r$//' 2>/dev/null
  chmod +x ~/twm/*.sh

  # Account scaffold + docs
  mkdir -p ~/twm/accounts
  [ -f ~/twm/accounts/index.json ] || curl "${SERVER}accounts/index.json" -s -L -o ~/twm/accounts/index.json 2>/dev/null || true
  curl "${SERVER}HOW_TO_MONITOR.md" -s -L -o ~/twm/HOW_TO_MONITOR.md 2>/dev/null || true
  curl "${SERVER}QUICK_START.md" -s -L -o ~/twm/QUICK_START.md 2>/dev/null || true

  printf "\n${BLACK_CYAN}  Summary: 🔽 %d updated  🆕 %d new  ⚠️  %d skipped${COLOR_RESET}\n" \
    "$UPDATED" "$NEW" "$FAILED"
}

# ─── Merge sync (legacy single-file install) ──────────────────────────────────
sync_func_other() {
  SCRIPTS="requeriments.sh svproxy.sh loginlogoff.sh crono.sh check.sh run.sh \
clanid.sh allies.sh altars.sh arena.sh campaign.sh career.sh cave.sh \
clancoliseum.sh clandungeon.sh clandmg.sh clanfight.sh coliseum.sh \
flagfight.sh function.sh king.sh language.sh league.sh specialevent.sh \
trade.sh undying.sh update_check.sh multi_runner.sh twm_view.sh \
twm_monitor.sh twm_control.sh"

  printf "${BLACK_CYAN}  🔁 Merge mode (legacy single-file)${COLOR_RESET}\n\n"

  curl "${SERVER}play.sh" -s -L -O
  curl "${SERVER}info.sh" -s -L >twm.sh
  curl "${SERVER}twm.sh"  -s -L | sed -n '3,33p' >>twm.sh

  NUM_SCRIPTS=$(echo "$SCRIPTS" | wc -w)
  LEN=0

  for script in $SCRIPTS; do
    LEN=$((LEN + 1))
    label=$(printf "[%02d/%02d]" "$LEN" "$NUM_SCRIPTS")
    printf "  🔁 %s %s\n" "$label" "$script"
    curl "${SERVER}$script" -s -L >>twm.sh
    printf "\n#\n" >>twm.sh
  done

  curl "${SERVER}twm.sh" -s -L | sed -n '40,120p' >>twm.sh

  find ~/twm -type f -name '*.sh' -print0 | xargs -0 sed -i 's/\r$//' 2>/dev/null
  chmod +x ~/twm/*.sh

  mkdir -p ~/twm/accounts
  [ -f ~/twm/accounts/index.json ] || curl "${SERVER}accounts/index.json" -s -L -o ~/twm/accounts/index.json 2>/dev/null || true
  curl "${SERVER}HOW_TO_MONITOR.md" -s -L -o ~/twm/HOW_TO_MONITOR.md 2>/dev/null || true
  curl "${SERVER}QUICK_START.md" -s -L -o ~/twm/QUICK_START.md 2>/dev/null || true
}

#/merge
if echo "$@" | grep -q 'merge'; then
  sync_func_other
else
  sync_func
fi

# ─── Shell shortcut ───────────────────────────────────────────────────────────
check_if_exists() {
  grep -q 'play-twm' "$1" 2>/dev/null
}

shortcut_set() {
  function_definition='play-twm() { $HOME/twm/play.sh "$@"; }'

  case "$(uname)" in
    "Linux")
      if [ "$SHELL" = "/bin/ash" ] || [ -e /etc/alpine-release ]; then
        config_file="$HOME/.profile"
      elif [ -n "$ZSH_VERSION" ]; then
        config_file="$HOME/.zshrc"
      else
        config_file="$HOME/.bashrc"
      fi

      if check_if_exists "$config_file"; then
        printf "\n  ✅ Shortcut ${GOLD_BLACK}play-twm${COLOR_RESET} already set in %s\n" "$config_file"
      else
        printf '%s\n'       "$function_definition" >> "$config_file"
        printf 'export -f play-twm\n'              >> "$config_file"
        printf "\n  ✅ Shortcut ${GOLD_BLACK}play-twm${COLOR_RESET} added to %s\n" "$config_file"
        # shellcheck disable=SC1090
        . "$config_file" 2>/dev/null || true
      fi
      ;;
    *)
      printf "\n  ⚠️  Add manually to your shell config: %s\n" "$function_definition"
      ;;
  esac
}
shortcut_set

# iSH: rewrite shebang for compatibility
APPISH=$(uname -a | grep -o "\-ish")
if [ "$SHELL" = "/bin/ash" ] && [ "$APPISH" = '-ish' ]; then
  sed -i 's,#!/bin/bash,#!/bin/sh,g' "$HOME"/twm/*.sh
fi
unset APPISH

# ─── Done ─────────────────────────────────────────────────────────────────────
printf "\n${BLACK_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}\n"
printf "${GREENb_BLACK}  ✅  Installation complete!${COLOR_RESET}\n"
printf "${BLACK_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}\n\n"
printf "  Start bot:      ${GOLD_BLACK}play-twm${COLOR_RESET}\n"
printf "  Coliseum:       ${GOLD_BLACK}play-twm -cl${COLOR_RESET}\n"
printf "  Cave:           ${GOLD_BLACK}play-twm -cv${COLOR_RESET}\n"
printf "  Multi-account:  ${GOLD_BLACK}./twm/multi_runner.sh start${COLOR_RESET}\n"
printf "  Monitor:        ${GOLD_BLACK}./twm/twm_monitor.sh${COLOR_RESET}\n"
printf "  Setup account:  ${GOLD_BLACK}./twm/twm_setup.sh${COLOR_RESET}\n\n"
