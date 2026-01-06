# Bot Manager Plugins for AMX Mod X

AMX Mod X plugins for Counter-Strike 1.6 and Condition Zero that provide admin menu for dynamic bot management and game mode switching.

## Plugins

| Plugin | Game | Bot System |
|--------|------|------------|
| `czbot_manager.sma` | CS: Condition Zero | CZ Bots (built-in) |
| `yapb_manager.sma` | CS 1.6 | YaPB (Yet another POD-Bot) |

## Features

- **4 Game Modes:**
  - **Humans vs CT Bots** - Players join Terrorist team, bots fill CT
  - **Humans vs T Bots** - Players join CT team, bots fill Terrorist
  - **5v5 Mixed** - Bots fill both teams, players replace bots (auto-vacate)
  - **No Bots** - Disable all bots

- **Bot Difficulty Control:**
  - CZ: Easy, Normal, Hard, Expert, Mixed
  - YaPB: Newbie, Average, Normal, Professional, Godlike, Mixed

- **Dynamic Bot Count:** Adjust number of bots (0-10) on the fly

- **Persistent Settings:** Settings automatically saved and restored after map change/restart

- **Admin Menu Integration:** Appears in standard `amxmodmenu`

## Requirements

### For CS: Condition Zero (czbot_manager)
- Counter-Strike: Condition Zero dedicated server
- **MetaMod 1.21.1-am** from [amxmodx.org](https://amxmodx.org/downloads.php)
- **AMX Mod X 1.8.2+** (recommended: 1.10.x)

### For CS 1.6 (yapb_manager)
- Counter-Strike 1.6 dedicated server
- **MetaMod 1.21.1-am** from [amxmodx.org](https://amxmodx.org/downloads.php)
- **AMX Mod X 1.8.2+** (recommended: 1.10.x)
- **YaPB 4.x** from [yapb.github.io](https://yapb.github.io/)

## Installation

### Step 1: Compile the plugin

```bash
# For CZ
amxxpc czbot_manager.sma -o czbot_manager.amxx

# For CS 1.6
amxxpc yapb_manager.sma -o yapb_manager.amxx
```

Or use the online compiler at: https://www.amxmodx.org/webcompiler.cgi

### Step 2: Install the plugin

Copy compiled `.amxx` to:
```
# CZ
czero/addons/amxmodx/plugins/czbot_manager.amxx

# CS 1.6
cstrike/addons/amxmodx/plugins/yapb_manager.amxx
```

Edit `plugins.ini` and add the plugin name (after `menufront.amxx`).

### Step 3: Configure server.cfg

**For CZ:**
```
bot_join_after_player 0
bot_quota 0
mp_autoteambalance 0
mp_limitteams 0
```

**For CS 1.6 with YaPB:**
```
mp_autoteambalance 0
mp_limitteams 0
// YaPB settings controlled by plugin
```

### Step 4: Restart server

## Usage

### Accessing the Menu

1. **Via AMX Mod X Admin Menu:**
   - Type `amxmodmenu` in console
   - Select **"Bot Manager"** or **"YaPB Manager"**

2. **Direct console command:**
   - CZ: `amx_botmenu` or `amx_bots`
   - CS 1.6: `amx_yapbmenu` or `amx_yapb`

**Access Level:** ADMIN_LEVEL_A (flag "m")

### Menu Options

1. Change Game Mode
2. Change Bot Difficulty
3. Increase Bot Count (+1)
4. Decrease Bot Count (-1)
5. Apply Changes Now

### CVars

**CZ Bot Manager:**
| CVar | Default | Description |
|------|---------|-------------|
| `czbot_mode` | 0 | Game mode (0-3) |
| `czbot_count` | 6 | Number of bots |
| `czbot_difficulty` | 1 | Difficulty (0-4) |

**YaPB Manager:**
| CVar | Default | Description |
|------|---------|-------------|
| `yapb_manager_mode` | 0 | Game mode (0-3) |
| `yapb_manager_count` | 6 | Number of bots |
| `yapb_manager_difficulty` | 2 | Difficulty (0-5) |

### Settings Files

```
# CZ
addons/amxmodx/data/czbot_settings.ini

# CS 1.6
addons/amxmodx/data/yapb_settings.ini
```

## Troubleshooting

### Plugin not showing in amxmodmenu
- Ensure `menufront.amxx` is enabled
- Plugin must be listed AFTER `menufront.amxx` in `plugins.ini`

### CZ Bots cause server crash
- Use MetaMod 1.21.1-am from amxmodx.org

### YaPB bots not working
- Verify YaPB is installed: `addons/yapb/bin/yapb.so`
- Check `liblist.gam` points to MetaMod
- Check MetaMod `plugins.ini` includes YaPB

## File Structure

```
game-mode-cz/
├── czbot_manager.sma    # CZ Bot Manager source
├── czbot_manager.amxx   # CZ Bot Manager compiled
├── yapb_manager.sma     # YaPB Manager source
└── README.md
```

## Version History

### czbot_manager
- **1.1.0** - Mixed difficulty, persistent settings, auto team transfer
- **1.0.0** - Initial release

### yapb_manager
- **1.0.0** - Initial release for YaPB bots

## License

Free to use and modify.

## Credits

- CZ Bot system by Valve/Gearbox
- YaPB by jeefo
- AMX Mod X by AlliedModders
