#!/bin/sh
#create fold twm if does not exist
mkdir -p ~/twm

if [ -z "$*" ]; then
  version="master"
else
  # ./easyinstall.sh beta, or backup
  version="$*"
fi


if [ ! -e "$HOME/info.sh" ]; then
  curl https://raw.githubusercontent.com/hugoviegas/TitansWarPro/"$version"/info.sh -s -L >"$HOME"/twm/info.sh
  chmod +x ~/twm/info.sh
  sleep 0.5s
fi

# shellcheck disable=SC1090
. ~/twm/info.sh
colors
script_slogan

#access dir
cd ~/twm || exit

#

SERVER="https://raw.githubusercontent.com/hugoviegas/TitansWarPro/$version/"
remote_count=$(curl "${SERVER}"easyinstall.sh -s -L | wc -c)
if [ -e "easyinstall.sh" ]; then
  local_count=$(wc -c <"easyinstall.sh")
else
  local_count=1
fi

cd ~/ || exit
printf "${BLACK_CYAN} Installing TWM...\n⌛ Please wait...⌛${COLOR_RESET}"

#termux
if [ -d /data/data/com.termux/files/usr/share/doc ]; then
  termux-wake-lock
  if ! grep -q "nameserver 114.114.114.114" "$PREFIX"/etc/resolv.conf; then
    printf "nameserver 114.114.114.114\n" >> "$PREFIX"/etc/resolv.conf
  fi
  if ! grep -q "nameserver 8.8.8.8" "$PREFIX"/etc/resolv.conf; then
    printf "nameserver 8.8.8.8\n" >> "$PREFIX"/etc/resolv.conf
  fi
  LS="/data/data/com.termux/files/usr/share/doc"
  rm -rf ~/.termux/boot/play.sh 2>/dev/null
  mkdir -p ~/.termux/boot
  echo "IyEvZGF0YS9kYXRhL2NvbS50ZXJtdXgvZmlsZXMvdXNyL2Jpbi9zaApiYXNoICRIT01FL3R3bS90d20uc2ggLWJvb3QK" | base64 -d >~/.termux/boot/play.sh 2>/dev/null
  chmod +x ~/.termux/boot/play.sh 2>/dev/null
  if whereis -b w3m >/dev/null 2>&1; then
    :
  else
    pkg install w3m -y
  fi

  if whereis -b jq >/dev/null 2>&1; then
    :
  else
    pkg install jq -y
  fi

  if whereis -b coreutils >/dev/null 2>&1; then
    :
  else
    pkg install coreutils ncurses-utils -y
  fi

  if [ -e "${LS}/termux-api" ]; then
    :
  else
    pkg install termux-api -y
  fi

  if [ -e "${LS}/procps" ]; then
    :
  else
    pkg install procps ncurses-utils -y
  fi
fi

#/cygwin
if uname | grep -q -i "cygwin"; then
  LS="/usr/share/doc"
  if [ -e /bin/apt-cyg ]; then
    :
  else
    #/cygwin repository
    curl -s -L -O "https://raw.githubusercontent.com/hugoviegas/TitansWarPro/beta/apt-cyg" &
    : > /dev/null
    install apt-cyg /bin
  fi

  if [ -e "${LS}/w3m" ]; then
    :
  else
    apt-cyg install w3m -y &
    : > /dev/null
  fi

  if [ -e "${LS}/ncurses-term" ]; then
    :
  else
    apt-cyg install ncurses-term -y &
    : > /dev/null
  fi

  if [ -e "${LS}/coreutils" ]; then
    : > /dev/null
  else
    apt-cyg install coreutils -y &
  fi
  if [ -e "${LS}/procps" ]; then
    : > /dev/null
  else
    apt-cyg install procps -y &
  fi
  if [ -e "${LS}/jq" ]; then
      :> /dev/null
  else
      apt-cyg install jq -y &
  fi
  
  fi

#/ish Iphone
APPISH=$(uname -a | grep -o "\-ish")
if [ "$SHELL" = "/bin/ash" ] && [ "$APPISH" = '-ish' ]; then
  LS='/usr/share/doc'
  printf "${BLACK_CYAN}Install the necessary packages for Alpine on app ISh(Iphone):${COLOR_RESET}\n apk update\n apk add curl ; apk add w3m ; apk add coreutils ; apk add --no-cache tzdata\n\n"
  sleep 5s
#/UserLAnd Terminal
elif [ "$SHELL" != "/bin/ash" ] && [ "$APPISH" != '-ish' ] && uname -m | grep -q -E '(aarch64|armhf|armv7|mips64)' && [ ! -d /data/data/com.termux/files/usr/share/doc ]; then
  LS='/usr/share/doc'
  printf "${BLACK_CYAN}Install the necessary packages for Alpine on app UserLAnd(Android):${COLOR_RESET}\n apk update\n sudo apk add curl ; sudo apk add w3m ; sudo apk add coreutils ; sudo apk add --no-cache tzdata\n\n"
  sleep 5s
#/other linux
elif [ "$SHELL" != "/bin/ash" ] && [ "$APPISH" != '-ish' ] && uname -m | grep -q -E "(ppc64le|riscv64|s390x|x86|x86_64)" && [ ! -d /data/data/com.termux/files/usr/share/doc ]; then
  LS='/usr/share/doc'
  printf "${BLACK_CYAN}Install required packages for Linux or Windows WSL:${COLOR_RESET}\n sudo apt update\n sudo apt install curl coreutils ncurses-term procps w3m jq -y\n"
  sleep 5s
fi

#starting...
unset LS
cd ~/twm || exit
#script_slogan
printf "${BLACK_CYAN}\n ⌛ Wait downloading scripts...${COLOR_RESET}\n"

sync_func() {
  SCRIPTS="allies.sh altars.sh arena.sh campaign.sh career.sh cave.sh check.sh clancoliseum.sh clanfight.sh clanid.sh coliseum.sh crono.sh flagfight.sh function.sh king.sh language.sh league.sh loginlogoff.sh play.sh requeriments.sh run.sh svproxy.sh specialevent.sh trade.sh twm.sh undying.sh update_check.sh"
  NUM_SCRIPTS=$(echo "$SCRIPTS" | wc -w)
  LEN=0
  for script in $SCRIPTS; do
    LEN=$((LEN + 1))
    printf "Checking $LEN/$NUM_SCRIPTS $script\n"
    remote_count=$(curl "${SERVER}$script" -s -L | wc -c)

    if [ -e ~/twm/"$script" ]; then
      local_count=$(wc -c <"$script")
    else
      local_count=1
    fi

    if [ -e ~/twm/"$script" ] && [ "$remote_count" -eq "$local_count" ]; then
      printf "✅ ${BLACK_CYAN}Updated $script${COLOR_RESET}\n"
    elif [ -e ~/twm/"$script" ] && [ "$remote_count" -ne "$local_count" ]; then
      printf "🔁 ${BLACK_GREEN}Updating $script${COLOR_RESET}\n"
      curl "${SERVER}$script" -s -L >"$script"
    else
      printf "🔽 ${BLACK_YELLOW}Downloading $script${COLOR_RESET}\n"
      curl "${SERVER}$script" -s -L -O
    fi
    sleep 0.1s
  done
  #DOS to Unix
  find ~/twm -type f -name '*.sh' -print0 | xargs -0 sed -i 's/\r$//' 2>/dev/null
  chmod +x ~/twm/*.sh &
  : > /dev/null
}

sync_func_other() {
  SCRIPTS="requeriments.sh svproxy.sh loginlogoff.sh crono.sh check.sh run.sh clanid.sh allies.sh altars.sh arena.sh campaign.sh career.sh cave.sh clancoliseum.sh clandungeon.sh clanfight.sh coliseum.sh flagfight.sh function.sh king.sh language.sh league.sh specialevent.sh trade.sh undying.sh update_check.sh"
  curl "${SERVER}"play.sh -s -L -O
  curl "${SERVER}"info.sh -s -L >twm.sh
  curl "${SERVER}"twm.sh -s -L | sed -n '3,33p' >>twm.sh
  NUM_SCRIPTS=$(echo "$SCRIPTS" | wc -w)
  LEN=0

  for script in $SCRIPTS; do
    LEN=$((LEN + 1))
    printf "Checking $LEN/$NUM_SCRIPTS $script\n"
    printf "🔁 ${BLACK_GREEN}Updating $script${COLOR_RESET}\n"
    curl "${SERVER}$script" -s -L >>twm.sh
    printf "\n#\n" >>twm.sh
    sleep 0.1s
  done
  curl "${SERVER}"twm.sh -s -L | sed -n '40,120p' >>twm.sh

  #DOS to Unix
  find ~/twm -type f -name '*.sh' -print0 | xargs -0 sed -i 's/\r$//' 2>/dev/null
  chmod +x ~/twm/*.sh &
  : > /dev/null
}

#/merge
if echo "$@" | grep -q 'merge'; then
  sync_func_other
else
  sync_func
fi

check_if_exists() {
  config_file="$1"
  grep -q 'play-twm' "$config_file" 2>/dev/null
}

shortcut_set(){
  # Define a função play-twm e o comando a ser adicionado
  function_definition='play-twm() { $HOME/twm/play.sh "$@"; }'
 # Função para verificar se o atalho já está configurado

# Detecta o sistema operacional e adiciona o comando no arquivo correto
case "$(uname)" in
    "Linux")
        # Verifica a distribuição e o shell em uso
        if grep -qiE 'debian|ubuntu|mint' /etc/os-release; then
            config_file="$HOME/.bashrc"
        
        elif grep -qiE 'arch|manjaro' /etc/os-release; then
            config_file="$HOME/.bashrc"

        elif grep -qi 'fedora' /etc/os-release; then
            config_file="$HOME/.bashrc"

        elif grep -qi 'termux' /etc/os-release; then
            config_file="$HOME/.bashrc"
            
        elif [ "$SHELL" = "/bin/ash" ]; then
            config_file="$HOME/.profile"

        else
            # Se o shell for diferente (zsh, etc.), tenta adicionar no .zshrc
            if [ -n "$ZSH_VERSION" ]; then
                config_file="$HOME/.zshrc"
            else
                config_file="$HOME/.bashrc"
            fi
        fi

        # Verifica se a função já está presente no arquivo de configuração
        if check_if_exists "$config_file"; then
            echo "O atalho 'play-twm' já está configurado em $config_file. Pulando a configuração."
        else
            # Adiciona a função e exporta
            echo "$function_definition" >> "$config_file"
            echo 'export -f play-twm' >> "$config_file"
            echo "Atalho 'play-twm' configurado com sucesso em $config_file!"
            # Recarrega o arquivo de configuração para que a função fique disponível imediatamente
            # shellcheck disable=SC1090
            . "$config_file"
            source "${config_file}"
        fi
        ;;
    *)
        echo "Sistema operacional não suportado ou desconhecido."
        exit 1
        ;;
esac
}
shortcut_set

APPISH=$(uname -a | grep -o "\-ish")
if [ "$SHELL" = "/bin/ash" ] && [ "$APPISH" = '-ish' ]; then
  sed -i 's,#!/bin/bash,#!/bin/sh,g' "$HOME"/twm/*.sh
fi

script_slogan
printf "✅ ${BLACK_CYAN}Updated scripts!${COLOR_RESET}\n To execute run command: ${GOLD_BLACK}./twm/play.sh${COLOR_RESET}\n       For coliseum run: ${GOLD_BLACK}./twm/play.sh -cl${COLOR_RESET}\n           For cave run: ${GOLD_BLACK}./twm/play.sh -cv${COLOR_RESET}\n"
# shellcheck disable=SC2009
tipidf=$(ps ax -o pid=,args= | grep "sh.*twm/play.sh" | grep -v 'grep' | head -n 1 | grep -o -E '([0-9]{3,5})')
until [ -z "$tipidf" ]; do
  kill -9 "$tipidf" 2>/dev/null
  tipidf=$(ps ax -o pid=,args= | grep "sh.*twm/play.sh" | grep -v 'grep' | head -n 1 | grep -o -E '([0-9]{3,5})')
  sleep 1s
done
tipidf=$(ps ax -o pid=,args= | grep "sh.*twm/twm.sh" | grep -v 'grep' | head -n 1 | grep -o -E '([0-9]{3,5})')
until [ -z "$tipidf" ]; do
  kill -9 "$tipidf" 2>/dev/null
  tipidf=$(ps ax -o pid=,args= | grep "sh.*twm/twm.sh" | grep -v 'grep' | head -n 1 | grep -o -E '([0-9]{3,5})')
  sleep 1s
done
if [ -f ~/twm/runmode_file ]; then
  if awk -v arg="-cl" -v file="$(cat ~/twm/runmode_file)" 'BEGIN { exit !(arg == file) }'; then
    printf "${BLACK_GREEN}Automatically restarting in 3s after update...${COLOR_RESET}\n"
    sleep 3s
    ~/twm/play.sh -cl
  elif awk -v arg="-cv" -v file="$(cat ~/twm/runmode_file)" 'BEGIN { exit !(arg == file) }'; then
    printf "${BLACK_GREEN}Automatically restarting in 3s after update...${COLOR_RESET}\n"
    sleep 3s
    ~/twm/play.sh -cv
  else
    printf "${BLACK_GREEN}Automatically restarting in 3s after update...${COLOR_RESET}\n"
    sleep 3s
    ~/twm/play.sh -boot
  fi
fi
