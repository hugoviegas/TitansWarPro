# TWM Multi-Runner Monitor Guide

Com a nova estrutura de múltiplas contas, existem duas formas de visualizar os logs:

## 1️⃣ `twm_view.sh` - Visualização Simples de Logs

Mostra o log em tempo real de uma conta específica.

### Uso básico:

```bash
# Menu interativo para escolher uma conta
./twm_view.sh

# Visualizar logs de uma conta específica
./twm_view.sh A1
./twm_view.sh A2
```

**Exemplo de saída:**
```
╔══════════════════════════════════════╗
║  TWM Log Viewer - Account: Player1   ║
║  (Press Ctrl+C to exit)              ║
╚══════════════════════════════════════╝

2026-03-14 12:15:45 [Player1] starting twm.sh
2026-03-14 12:16:02 [Player1] Checking if user matches...
2026-03-14 12:16:05 [Player1] Session configured.
2026-03-14 12:16:10 [Player1] Running in boot mode
...
```

**Sair:** `Ctrl+C`

---

## 2️⃣ `twm_monitor.sh` - Monitor Interativo

Monitor avançado com menu de navegação para trocar entre contas em tempo real.

### Uso básico:

```bash
# Inicia o monitor interativo
./twm_monitor.sh

# Ver status em tabela (sem monitor interativo)
./twm_monitor.sh status
```

### Navegação no Monitor:

| Comando | Descrição |
|---------|-----------|
| **[N]** | Próxima conta |
| **[P]** | Conta anterior |
| **[L]** | Ver lista de contas (escolher por número) |
| **[R]** | Atualizar display |
| **[1-9]** | Jump para conta (#) - quando em modo lista |
| **[Q]** | Sair |

**Exemplo de display:**
```
╔════════════════════════════════════════════════════╗
║  TWM Monitor - Account: Player1 (A1)              ║
╠════════════════════════════════════════════════════╣
║  Status: RUNNING  PID: 12345  Mode: -boot
║  Log: /home/user/twm/accounts/A1/logs/twm.log
╠════════════════════════════════════════════════════╣
║  Commands: [N]ext  [P]rev  [L]ist  [R]efresh  [Q]uit
╠════════════════════════════════════════════════════╣
║ 2026-03-14 12:16:05 [Player1] Session configured
║ 2026-03-14 12:16:10 [Player1] Running in boot mode
║ 2026-03-14 12:16:15 [Player1] Arena attack...
...
╚════════════════════════════════════════════════════╝
```

**Ver Status sem Monitor (tabela):**
```bash
./twm_monitor.sh status
```

Output:
```
ID       Status       PID      Alias
A1       RUNNING      12345    Player1
A2       RUNNING      12346    Player2
A3       STOPPED      -        Player3
```

---

## 3️⃣ Usando com `multi_runner.sh`

**Ver status de TODOS os runners:**
```bash
./multi_runner.sh status
```

**Exemplo:**
```
ID       State      PID      RunMode  Alias
A1       running    12345    -boot    Player1
A2       running    12346    -boot    Player2
A3       inactive   -        -        Player3
```

---

## Workflow Recomendado

### Iniciar tudo:
```bash
./multi_runner.sh start
```

### Monitorar em tempo real (melhor experiência):
```bash
./twm_monitor.sh        # Monitor interativo
# ou
./twm_view.sh          # Menu para escolher uma conta
```

### Verificar status rápido:
```bash
./twm_monitor.sh status
# ou
./multi_runner.sh status
```

### Parar contas:
```bash
./multi_runner.sh stop A1     # Parar A1
./multi_runner.sh stop A1 A2  # Parar A1 e A2
./multi_runner.sh stop        # Parar TODAS
```

---

## Dicas

- **Para logs persistentes:** Os logs de cada conta estão em:
  ```
  ~/twm/accounts/<ID>/logs/twm.log
  ```
  Você pode ler direto:
  ```bash
  tail -f ~/twm/accounts/A1/logs/twm.log
  ```

- **Ver múltiplas contas em abas diferentes:** Use múltiplos terminais:
  ```bash
  # Terminal 1
  ./twm_view.sh A1

  # Terminal 2
  ./twm_view.sh A2
  ```

- **Status em tempo real em loop:**
  ```bash
  watch -n 1 "./multi_runner.sh status"
  ```
