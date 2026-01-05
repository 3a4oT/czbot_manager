# CZ Bot Manager

AMX Mod X plugin for Counter-Strike: Condition Zero that provides admin menu for dynamic bot management and game mode switching.

## Features

- **4 Game Modes:**
  - **Humans vs CT Bots** - Players join Terrorist team, bots fill CT
  - **Humans vs T Bots** - Players join CT team, bots fill Terrorist
  - **5v5 Mixed** - Bots fill both teams, players replace bots (auto-vacate)
  - **No Bots** - Disable all bots

- **Bot Difficulty Control:** Easy, Normal, Hard, Expert

- **Dynamic Bot Count:** Adjust number of bots (0-10) on the fly

- **Persistent Settings:** Settings saved via CVars

## Requirements

- Counter-Strike: Condition Zero dedicated server (HLDS)
- **MetaMod 1.21.1-am** - Download from [amxmodx.org](https://amxmodx.org/downloads.php), NOT from metamod.org (older versions cause segfaults with CZ bots)
- **AMX Mod X 1.8.2+** (recommended: 1.10.x)

## Installation

### Step 1: Compile the plugin

Using the AMX Mod X web compiler or local compiler:

```bash
# Using local compiler
amxxpc czbot_manager.sma -o czbot_manager.amxx
```

Or use the online compiler at: https://www.amxmodx.org/compiler.php

### Step 2: Install the plugin

1. Copy `czbot_manager.amxx` to:
   ```
   czero/addons/amxmodx/plugins/
   ```

2. Edit `czero/addons/amxmodx/configs/plugins.ini` and add:
   ```
   czbot_manager.amxx
   ```

   **Important:** The plugin must be listed AFTER `menufront.amxx` for the admin menu integration to work.

### Step 3: Configure server.cfg

Add these lines to your `czero/server.cfg`:

```
// CZ Bot Manager - Required settings
bot_join_after_player 0    // Prevents conflicts with plugin
bot_quota 0                // Let plugin control bot count
mp_autoteambalance 0       // Prevent auto team switching
mp_limitteams 0            // Allow unbalanced teams for vs modes
```

### Step 4: Restart server

Restart your CS:CZ server for changes to take effect.

## Usage

### Accessing the Menu

There are **two ways** to open Bot Manager:

1. **Via AMX Mod X Admin Menu (recommended)**
   - Type `amxmodmenu` in console (or press bound key)
   - Find **"Bot Manager"** in the list
   - Select it to open

2. **Direct console command**
   - Type `amx_botmenu` or `amx_bots` in console

**Access Level:** ADMIN_LEVEL_A (flag "m")

### Menu Position in amxmodmenu

The position of "Bot Manager" in the admin menu list depends on the **load order in plugins.ini**. Plugins loaded later appear lower in the menu.

To change position, move `czbot_manager.amxx` line in `plugins.ini`:
- **Higher in list** = appears earlier in menu
- **Lower in list** = appears later in menu

Example `plugins.ini` order:
```ini
; Standard plugins
admin.amxx
adminhelp.amxx
adminslots.amxx
multilingual.amxx
menufront.amxx         ; <-- MUST be before czbot_manager
admincmd.amxx
adminvote.amxx
; Custom plugins
czbot_manager.amxx     ; <-- Bot Manager appears after standard items
```

### Menu Navigation

1. Open menu via `amxmodmenu` or `amx_botmenu`
2. Select options using number keys:
   - **1** - Change Game Mode
   - **2** - Change Bot Difficulty
   - **3** - Increase Bot Count (+1)
   - **4** - Decrease Bot Count (-1)
   - **5** - Apply Changes Now

### CVars

| CVar | Default | Description |
|------|---------|-------------|
| `czbot_mode` | 0 | Game mode (0-3) |
| `czbot_count` | 6 | Number of bots |
| `czbot_difficulty` | 1 | Difficulty (0=Easy, 1=Normal, 2=Hard, 3=Expert) |

## Troubleshooting

### "Bot Manager" not showing in amxmodmenu

**Check:**
1. Ensure `menufront.amxx` is enabled in `plugins.ini`
2. Ensure `czbot_manager.amxx` is listed AFTER `menufront.amxx`
3. Check server logs for: `[CZ Bot Manager] Added to AMX Mod X admin menu`
4. If you see `WARNING: menufront.amxx not loaded`, enable menufront.amxx

**Note:** Even if menu integration fails, you can always use `amx_botmenu` command directly.

### Bots cause server crash (Segfault)

**Solution:** Use MetaMod 1.21.1-am from amxmodx.org, not the outdated version from metamod.org.

### Bots don't appear after applying settings

**Check:**
1. Ensure `bot_join_after_player 0` is set in server.cfg
2. Verify plugin is loaded: `amx_plugins` in console
3. Check server logs for errors

### Bots join wrong team

**Solution:** Ensure `mp_autoteambalance 0` is set in server.cfg

### Players can't join desired team

**Solution:** Set `mp_limitteams 0` in server.cfg

## File Structure

```
game-mode-cz/
├── czbot_manager.sma    # Plugin source code
├── README.md            # This file
└── .gitignore          # Git ignore rules
```

## Version History

- **1.0.0** - Initial release
  - 4 game modes
  - Bot difficulty control
  - Dynamic bot count
  - Admin menu integration

## License

Free to use and modify for your CS:CZ server.

## Credits

- CZ Bot system by Valve/Gearbox
- AMX Mod X by AlliedModders
- Research sources:
  - [CZ Bot Commands Guide](https://steamcommunity.com/sharedfiles/filedetails/?id=126699221)
  - [AMX Mod X Documentation](https://www.amxmodx.org/doc/)
  - [AlliedModders Forums](https://forums.alliedmods.net/)
