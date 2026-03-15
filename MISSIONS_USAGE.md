# TitansWarPro - Mission System Implementation Complete

## Summary of Changes

The missions system has been fully implemented and committed. It provides:

1. **mission_debug()** - Analyzes all 14 missions and their current states
2. **do_missions()** - Automatically executes available missions respecting game mechanics
3. **Configuration Option** - FUNC_do_missions (option 16) to enable/disable missions

## How to Use

### 1. Enable Mission Automation in Your Config

Run the configuration menu:

```bash
ACCOUNT_ID=Gt play.sh Gt
# In the config menu, select option 16 and set it to 'y'
```

Or manually add to your account config:

```bash
echo "FUNC_do_missions=y" >> ~/twm/accounts/Gt/config.cfg
```

### 2. Run Mission Debug (Optional)

To inspect current mission states:

```bash
cd ~/TitansWarPro
ACCOUNT_ID=Gt bash missions.sh
mission_debug
```

This will:

- Fetch 4 pages: /quest/, /arena/, /league/, /lab/alchemy/
- Analyze mission states (RESGATAR, DISPONÍVEL, TIMER, IGNORED)
- Save detailed log to: `accounts/Gt/logs/mission_debug_YYYYMMDD_HHMMSS.log`

### 3. Start Playing

```bash
ACCOUNT_ID=Gt play.sh Gt
```

The bot will automatically:

- Check for available missions during the game loop
- Execute missions in order: League → Campaign → Altars → Coliseum → Cave → Alchemy
- Collect mission rewards
- Skip weekend if FUNC_pause_weekends=y

## Supported Missions (14 total)

### Auto-Complete Missions (no action needed)

- ID 1: Só ganha! (10 consecutive arena wins)
- ID 3: Missões do Sábio
- ID 9: Eu quero sangue! (Undying valley)
- ID 16: Torneio

### Action-Required Missions

- ID 2: Busca de recursos (2 cave digs) via cave_routine
- ID 5: Campanha (3 battles) via campaign_func
- ID 6: Lutador (10 league fights) via league_play
- ID 7: Lutador lendário (5 league wins) via league_play
- ID 10: Altares antigos (enter + battle) via altars_fight
- ID 11: Gladiador (3 coliseum fights) via coliseum_fight
- ID 13: Alquimia (2 successful potions)

### Ignored Missions (gold purchase)

- ID 4: Eu preciso de ouro!
- ID 8: Ouro segredo
- ID 12: Ajude o seu Clã!

## Files Modified

- `missions.sh` - New file with all mission logic
- `function.sh` - Added option 16 for FUNC_do_missions
- `twm.sh` - Sources missions.sh
- `easyinstall.sh` - Includes missions.sh in sync list
- `info.sh` - Version bumped to 3.10.22
- `MEMORY.md` - Documented mission IDs and system

## Important Notes

1. **Weekend Pause**: If FUNC_pause_weekends=y, missions are skipped on Saturday/Sunday
2. **Timeouts**: Each mission has safeguards against infinite loops
3. **State Detection**: Uses regex patterns to detect mission availability
4. **Reward Collection**: Automatically collects rewards after mission completion

## Test the System

To verify everything works, use the helper script:

```bash
cd ~/TitansWarPro
bash test_missions.sh
```

This will source all dependencies and run mission_debug() to verify the system is functional.
