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
  command -v tmux >/dev/null 2>&1 || pkg install tmux -y
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
  [ -e "${LS}/tmux"         ] || apt-cyg install tmux -y
  unset LS
fi

# iSH (iPhone) / UserLAnd / Generic Linux / WSL
APPISH=$(uname -a | grep -o "\-ish")
if [ "$SHELL" = "/bin/ash" ] && [ "$APPISH" = '-ish' ]; then
  printf "${BLACK_CYAN}Install the necessary packages for Alpine on app ISh (iPhone):${COLOR_RESET}\n"
  printf "  apk update\n  apk add curl; apk add w3m; apk add tmux; apk add coreutils; apk add --no-cache tzdata\n\n"
  sleep 5s
elif [ "$APPISH" != '-ish' ] && uname -m | grep -q -E '(aarch64|armhf|armv7|mips64)' && [ ! -d /data/data/com.termux ]; then
  printf "${BLACK_CYAN}Install the necessary packages for Alpine on app UserLAnd (Android):${COLOR_RESET}\n"
  printf "  apk update\n  sudo apk add curl; sudo apk add w3m; sudo apk add tmux; sudo apk add coreutils; sudo apk add --no-cache tzdata\n\n"
  sleep 5s
elif [ "$APPISH" != '-ish' ] && uname -m | grep -q -E "(ppc64le|riscv64|s390x|x86|x86_64)" && [ ! -d /data/data/com.termux ]; then
  printf "${BLACK_CYAN}Install required packages for Linux or Windows WSL:${COLOR_RESET}\n"
  printf "  sudo apt update\n  sudo apt install curl coreutils ncurses-term procps w3m jq tmux -y\n"
  sleep 5s
fi
unset APPISH

cd ~/twm || exit

# ─── Download helpers ─────────────────────────────────────────────────────────

sync_func() {
  SCRIPTS="allies.sh altars.sh arena.sh campaign.sh career.sh cave.sh check.sh \
clancoliseum.sh clandmg.sh clanfight.sh clanid.sh coliseum.sh crono.sh \
flagfight.sh function.sh king.sh language.sh league.sh loginlogoff.sh \
missions.sh play.sh requeriments.sh run.sh svproxy.sh specialevent.sh trade.sh twm.sh \
undying.sh update_check.sh multi_runner.sh twm_view.sh twm_monitor.sh \
twm_control.sh twm_setup.sh"

  NUM_SCRIPTS=$(echo "$SCRIPTS" | wc -w)
  LEN=0 UPDATED=0 NEW=0 OK=0 FAILED=0 UNCHANGED=0

  printf "${BLACK_CYAN}  ⬇  Smart sync (comparing hashes)...${COLOR_RESET}\n\n"

  for script in $SCRIPTS; do
    LEN=$((LEN + 1))
    label=$(printf "[%02d/%02d]" "$LEN" "$NUM_SCRIPTS")
    local_file="$HOME/twm/$script"
    temp_file="$local_file.tmp.$$"

    if [ ! -e "$local_file" ]; then
      # New file — download unconditionally
      if curl "${SERVER}$script" -s -L -o "$local_file" 2>/dev/null; then
        printf "  🆕 %s %-32s ${BLACK_YELLOW}new${COLOR_RESET}\n" "$label" "$script"
        NEW=$((NEW + 1))
      else
        printf "  ⚠️  %s %-32s ${BLACK_YELLOW}skipped${COLOR_RESET}\n" "$label" "$script"
        FAILED=$((FAILED + 1))
      fi
    else
      # File exists — download to temp and compare hashes
      if curl "${SERVER}$script" -s -L -o "$temp_file" 2>/dev/null; then
        # Get hashes for comparison
        local_hash=$(sha256sum "$local_file" 2>/dev/null | awk '{print $1}')
        remote_hash=$(sha256sum "$temp_file" 2>/dev/null | awk '{print $1}')

        if [ "$remote_hash" = "$local_hash" ]; then
          # Content is identical — file is current
          rm -f "$temp_file"
          printf "  ✅ %s %-32s ${GRAY_BLACK}unchanged${COLOR_RESET}\n" "$label" "$script"
          UNCHANGED=$((UNCHANGED + 1))
        else
          # Content differs — replace with new version
          mv "$temp_file" "$local_file"
          printf "  🔽 %s %-32s ${GREENb_BLACK}updated${COLOR_RESET}\n" "$label" "$script"
          UPDATED=$((UPDATED + 1))
        fi
      else
        # Download failed
        rm -f "$temp_file"
        printf "  ⚠️  %s %-32s ${BLACK_YELLOW}skipped${COLOR_RESET}\n" "$label" "$script"
        FAILED=$((FAILED + 1))
      fi
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

  printf "\n${BLACK_CYAN}  Summary: 🔽 %d updated  🆕 %d new  ✅ %d unchanged  ⚠️  %d skipped${COLOR_RESET}\n" \
    "$UPDATED" "$NEW" "$UNCHANGED" "$FAILED"
}

# ─── Merge sync (legacy single-file install) ──────────────────────────────────
sync_func_other() {
  SCRIPTS="requeriments.sh svproxy.sh loginlogoff.sh crono.sh check.sh run.sh \
clanid.sh allies.sh altars.sh arena.sh campaign.sh career.sh cave.sh \
clancoliseum.sh clandungeon.sh clandmg.sh clanfight.sh coliseum.sh \
flagfight.sh function.sh king.sh language.sh league.sh missions.sh specialevent.sh \
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

# ─── Shell shortcuts ──────────────────────────────────────────────────────────
check_if_exists() {
  grep -q 'twmsetup' "$1" 2>/dev/null
}

shortcut_set() {
  # All shortcuts route through twm_control.sh
  defs='
play-twm()  { $HOME/twm/twm_control.sh "$@"; }
twmsetup()  { $HOME/twm/twm_control.sh "$@"; }
twmstart()  { $HOME/twm/twm_control.sh start; }
twmstop()   { $HOME/twm/twm_control.sh stop; }
twmview()   { $HOME/twm/twm_control.sh view; }
'

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
        printf "\n  ✅ Shortcuts already set in %s\n" "$config_file"
      else
        printf '%s\n' "$defs" >> "$config_file"
        printf 'export -f play-twm twmsetup twmstart twmstop twmview 2>/dev/null || true\n' >> "$config_file"
        printf "\n  ✅ Shortcuts added to %s\n" "$config_file"
        # shellcheck disable=SC1090
        . "$config_file" 2>/dev/null || true
      fi
      ;;
    *)
      printf "\n  ⚠️  Add manually to your shell config:\n%s\n" "$defs"
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
printf "${GREENb_BLACK}  ✅  Instalação completa / Installation complete!${COLOR_RESET}\n"
printf "${BLACK_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}\n\n"
printf "  ${GREENb_BLACK}Painel de controle / Control panel:${COLOR_RESET}\n"
printf "    ${GOLD_BLACK}twmsetup${COLOR_RESET}   ou   ${GOLD_BLACK}./twm/twm_control.sh${COLOR_RESET}\n\n"
printf "  ${GREENb_BLACK}Atalhos disponíveis / Available shortcuts:${COLOR_RESET}\n"
printf "    ${GOLD_BLACK}twmstart${COLOR_RESET}   — Iniciar todas as contas + monitor\n"
printf "    ${GOLD_BLACK}twmstop${COLOR_RESET}    — Parar todas as contas\n"
printf "    ${GOLD_BLACK}twmview${COLOR_RESET}    — Abrir monitor de logs\n"
printf "    ${GOLD_BLACK}twmsetup${COLOR_RESET}   — Abrir painel de controle\n\n"
printf "  ${GREENb_BLACK}Conta individual / Single account:${COLOR_RESET}\n"
printf "    ${GOLD_BLACK}play.sh A1${COLOR_RESET}     — Iniciar conta A1\n"
printf "    ${GOLD_BLACK}play.sh A1 -cv${COLOR_RESET} — Modo caverna\n\n"
printf "  ${GREENb_BLACK}Requer novo terminal ou:${COLOR_RESET} source ~/.bashrc\n\n"
