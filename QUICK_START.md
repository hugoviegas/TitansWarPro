# TWM Quick Start Guide

**First time using Titans War Macro?** Follow this guide to get started in 5 minutes!

## 🚀 Quick Setup (New Users)

### 1. Initial Installation & Setup

```bash
# Navigate to your twm directory
cd ~/twm

# Create your first account with interactive setup
./twm_setup.sh
```

This will ask you:
- Account name/ID (e.g., A1, MyAccount)
- Display name (e.g., Player1)
- Game server (select 1-13)
- Language preference
- Which allies to use in battles
- Auto-update preference

### 2. Start the Bot

```bash
# Option A: Start all accounts
./multi_runner.sh start

# Option B: Start using shortcut command (if configured)
play-twm -boot

# Option C: Start specific mode
./play.sh -boot                # Boot mode (all features)
./play.sh -cl                  # Coliseum mode
./play.sh -cv                  # Cave mode
```

### 3. Monitor Your Account

```bash
# Interactive monitor (switch between accounts)
./twm_monitor.sh

# Or simple log viewer
./twm_view.sh

# Or control panel
./twm_control.sh
```

---

## 📋 First Run - What to Expect

### Login Screen
When you start for the first time, you'll see:
```
Username: ___
Password: ___
```

**Enter your game credentials here!** These are securely stored in your account folder.

### Ally Configuration
After login, you might see:
```
1) Add/Update alliances (All Battles)
2) Add/Update just Herois alliances (Coliseum/King)
3) Add/Update just Clan alliances (Altars/Clan)
4) Do nothing
```

Select based on your preference. **This only happens once during setup.**

---

## 🎮 Running Multiple Accounts

### Create Second Account

```bash
./twm_setup.sh
# Create account A2, set different server, etc.
```

### Start All Accounts

```bash
./multi_runner.sh start       # Starts A1, A2, etc.
```

### Monitor Each Account

```bash
./twm_monitor.sh              # Switch with [N]ext/[P]revious keys
```

---

## 🛠️ Configuration & Settings

### Edit Account Settings

Once running:
```bash
./twm_control.sh
# Select option from menu to change configurations
```

Or directly edit config file:
```bash
nano ~/twm/accounts/A1/config.cfg
```

### Features You Can Configure

- Automatically collect relics (y/n)
- Use elixir before valleys (y/n)
- Auto-update scripts (y/n)
- Target league rank (1-999)
- Language preference
- Allies configuration
- Update channel (master/beta/beta2)

---

## 📝 File Organization

After setup, your account looks like:

```
~/twm/
├── accounts/
│   ├── A1/
│   │   ├── config.cfg           ← Your settings
│   │   ├── ur_file              ← Server selection
│   │   ├── runmode_file         ← Current mode
│   │   ├── w3m/
│   │   │   └── .w3m/            ← Cookies (isolated!)
│   │   ├── tmp/
│   │   │   └── .13/             ← Server-specific temp files
│   │   └── logs/
│   │       └── twm.log          ← Your logs
│   └── index.json               ← Account definitions
├── multi_runner.sh              ← Launch all accounts
├── twm_monitor.sh               ← Watch logs
├── twm_control.sh               ← Manage settings
├── twm_setup.sh                 ← Create new account
└── [other scripts...]
```

---

## ❓ Common Questions

### Q: It keeps asking for allies configuration!
**A:** This means `ALLIES` is not set in your config. Run `./twm_setup.sh` again or:
```bash
echo "ALLIES=1" >> ~/twm/accounts/A1/config.cfg
```

### Q: It says maximum login attempts reached
**A:** Your credentials were rejected 3 times. Check:
- Username is completely correct
- Password is completely correct
- Make sure you're not using special paste characters
- Try re-running: `./twm_setup.sh`

### Q: I want to change servers for my account
**A:** Edit the account config:
```bash
# Edit ur_file (server number 1-13)
echo "13" > ~/twm/accounts/A1/ur_file

# Then restart
./multi_runner.sh restart
```

### Q: My account keeps restarting
**A:** This is normal if set to `autoRestart: true` in `index.json`. It means the script exited and restarted. Check logs:
```bash
./twm_monitor.sh    # View what happened
tail -f ~/twm/accounts/A1/logs/twm.log  # Direct log access
```

### Q: How do I stop everything?
**A:**
```bash
./multi_runner.sh stop          # Stop all
./multi_runner.sh stop A1       # Stop specific account
Ctrl+C                          # Stop running session
```

---

## 🚦 Typical First Run Flow

1. **Install** → `./twm_setup.sh`
2. **Start** → `./multi_runner.sh start`
3. **Monitor** → `./twm_monitor.sh` (in another terminal)
4. **Login** → Enter username/password when prompted
5. **Configure allies** → Select 1-4
6. **Done!** → Bot runs automatically

---

## 📞 Need Help?

Check log files:
```bash
./twm_view.sh                   # Read logs for specific account
./twm_monitor.sh status         # Quick status overview
tail -f ~/twm/accounts/A1/logs/twm.log  # Live logs
```

Check configuration:
```bash
cat ~/twm/accounts/A1/config.cfg        # Current settings
./multi_runner.sh status                # Process status
```

---

**Ready?** Start with: `./twm_setup.sh` 🚀
