# TWM(Titans War Macro)

Scripts macros para titanswar.net em todos os servidores.

**Necessário level 16+ e 50 pontos de treinamento para entrar em algumas batalhas**

**_Recomendado para qualquer Android e Iphone_**

> 1 - No Android abra o app UserLAnd(https://f-droid.org/repo/tech.ula_2927098.apk), instale o Alpine com SSH e entre com a senha que foi criada.
>
> - No Iphone abra o app iSH(https://ish.app/).
>   Em seguida digite, ou copie e cole para atualizar as listas de pacotes

> Android(UserLAnd):

```bash
sudo apk update
```

> Iphone(iSH):

```bash
apk update
```

> 2 - Digite ou copie e cole este comando para baixar os pacotes necessários

> Android(UserLAnd):

```bash
sudo apk add curl ; apk add w3m ; apk add procps ; apk add coreutils ; apk add --no-cache tzdata
```

> Iphone(iSH):

```bash
apk add curl ; apk add w3m ; apk add procps ; apk add coreutils ; apk add --no-cache tzdata
```

> 3 - Copie e cole este comando para baixar o instalador do twm(O link faz parte do comando)

> Android(UserLAnd) and Iphone(iSH):

```bash
curl https://raw.githubusercontent.com/sharesourcecode/TitansWarMacro/master/easyinstall.sh -L -O
```

> 4 - Dê permissão de execução para o instalador

> Android(UserLAnd) and Iphone(iSH):

```bash
chmod +x easyinstall.sh
```

> 5 - Copie e cole este comando para instalar o twm

> Android(UserLAnd) and Iphone(iSH):

```bash
./easyinstall.sh
```

> 6 - Para executar o twm

> Android(UserLAnd) e Iphone(iSH):

```bash
./twm/play.sh
```

Executar em modo caverna no Android(UserLAnd) e Iphone(iSH):

```bash
./twm/play.sh -cv
```

Modo de prioridade coliseu no Android(UserLAnd) e Iphone(iSH):

```bash
./twm/play.sh -cl
```

- Para interromper `Ctrl c` ou force a parada dos Apps.

- Para desinstalar scripts em ambos sistemas:

```bash
rm -rf $HOME/twm
```

**_Alternativa para Android 7 ou superior_**

> 1 - Abra o app Termux(https://f-droid.org/repo/com.termux_118.apk) no Android e digite ou cole os comandos abaixo para atualizar os pacotes.

- Podem ocorrer questões.

- Para duas opções (Y/n) responda Y

- Para múltiplas opções (Y/I/N/O/D/Z) apenas pressione ENTER para prosseguir.

```bash
pkg update -y ; pkg upgrade
```

Também:

```bash
pkg install w3m termux-api procps coreutils ncurses-utils
```

> 2 - Copie e cole este comando para baixar o instalador do twm(O link faz parte do comando):

```bash
curl https://raw.githubusercontent.com/sharesourcecode/TitansWarMacro/master/easyinstall.sh -L -O
```

> 3 - Dê permissão de execução para o instalador:

```bash
chmod +x easyinstall.sh
```

> 4 - Copie e cole este comando para instalar o twm:

```bash
./easyinstall.sh
```

> 5 - Para executar o twm:

```bash
./twm/play.sh
```

Executar o modo Caverna:

```bash
./twm/play.sh -cv
```

Modo de prioridade Coliseum:

```bash
./twm/play.sh -cl
```

- Para interromper `Ctrl c` ou force a parada do App Termux.

- Para desinstalar scripts:

```bash
rm -rf $HOME/twm
```

- Remover atalho do Termux boot:

```bash
rm -rf $HOME/.termux/boot/play.sh
```

---

**_Windows com Cygwin_**

> 1 - Abra o progama Cygwin(https://www.cygwin.com/setup-x86_64.exe) ou (https://www.cygwin.com/setup-x86.exe) como adiministrador no Windows. Na instalação selecione qualquer link, a parti daí é só dá Next até concluir. Em sequida com adiministrador abra o Cygwin Terminal que foi instalado. Digite, ou copie e cole o comando abaixo para baixar o instalador do twm(O link faz parte do comando):

```bash
curl https://raw.githubusercontent.com/sharesourcecode/TitansWarMacro/master/easyinstall.sh -L -O
```

> 2 - Dê permissão de execução para o instalador:

```bash
chmod +x easyinstall.sh
```

> 3 - Copie e cole este comando para instalar o twm:

```bash
bash $HOME/easyinstall.sh
```

> 4 - Para executar o twm:

```bash
bash $HOME/twm/play.sh
```

Executar em modo caverna:

```bash
bash $HOME/twm/play.sh -cv
```

Modo de prioridade coliseu:

```bash
bash $HOME/twm/play.sh -cl
```

`Para interroper (CTRL c) ou feche o programa Cygwin`

---

**_Distribuição Alt Linux, ou base Debian e Ubuntu - Windows WSL_**

> 1 - No emulador de terminal digite, ou copie e cole para atualizar as listas de pacotes:

```bash
sudo apt-get update -y
```

> 2 - Digite ou copie e cole este comando para baixar os pacotes necessários:

```bash
sudo apt-get install curl w3m procps -y
```

Opcional:

```bash
sudo apt-get install coreutils dnsutils-y
```

> 3 - Copie e cole este comando para baixar o instalador do twm(O link faz parte do comando):

```bash
curl https://raw.githubusercontent.com/sharesourcecode/TitansWarMacro/master/easyinstall.sh -L -O
```

> 4 - Dê permissão de execução para o instalador:

```bash
chmod +x easyinstall.sh
```

> 5 - Copie e cole este comando para instalar o twm:

```bash
bash easyinstall.sh
```

> 6 - Comando para executar o twm:

```bash
bash twm/play.sh
```

Executar em modo caverna:

```bash
bash twm/play.sh -cv
```

Modo de prioridade coliseu:

```bash
bash twm/play.sh -cl
```

`Para interroper (CTRL c)`

---

## **☕ Donates/Doações:**

 <br>

---
