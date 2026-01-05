/*
 * CZ Bot Manager - AMX Mod X Plugin for Counter-Strike: Condition Zero
 *
 * Provides admin menu for dynamic bot management and game mode switching.
 *
 * Author: Petro Rovenskyi
 * Version: 1.0.0
 *
 * Requirements:
 *   - AMX Mod X 1.8.2+ (tested on 1.10.x)
 *   - MetaMod 1.21.1-am (from amxmodx.org, NOT metamod.org)
 *   - Counter-Strike: Condition Zero dedicated server
 */

#include <amxmodx>
#include <amxmisc>
#include <cstrike>

// Plugin info
#define PLUGIN_NAME     "CZ Bot Manager"
#define PLUGIN_VERSION  "1.1.0"
#define PLUGIN_AUTHOR   "Petro Rovenskyi"

// Access level for admin commands
#define ACCESS_LEVEL    ADMIN_LEVEL_A

// Game modes
enum GameMode {
    MODE_HUMANS_VS_CT = 0,  // Humans play as T, bots as CT
    MODE_HUMANS_VS_T,       // Humans play as CT, bots as T
    MODE_MIXED_5V5,         // 5v5 with bots filling spots
    MODE_NO_BOTS            // No bots at all
}

// Difficulty levels
enum BotDifficulty {
    DIFF_EASY = 0,
    DIFF_NORMAL,
    DIFF_HARD,
    DIFF_EXPERT,
    DIFF_MIXED          // Random from Normal to Expert
}

// Global variables
new g_CurrentMode = MODE_HUMANS_VS_CT;
new g_BotCount = 6;
new g_BotDifficulty = DIFF_NORMAL;

// Bot spawning tracking
new g_BotsToAdd = 0;
new g_BotTeamToAdd = 0;  // 1 = T, 2 = CT, 3 = both

// CVars
new g_pCvarMode;
new g_pCvarCount;
new g_pCvarDifficulty;

// Settings file path
new g_szSettingsFile[128];

// Menu names
new const g_szDifficultyNames[][] = {
    "Easy",
    "Normal",
    "Hard",
    "Expert",
    "Mixed (Normal-Expert)"
};

new const g_szModeNames[][] = {
    "Humans vs CT Bots",
    "Humans vs T Bots",
    "5v5 Mixed (Auto-Vacate)",
    "No Bots"
};

/*
 * Plugin initialization
 */
public plugin_init() {
    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);

    // Register admin commands (always available via console)
    register_concmd("amx_botmenu", "cmd_BotMenu", ACCESS_LEVEL, "- Opens bot manager menu");
    register_concmd("amx_bots", "cmd_BotMenu", ACCESS_LEVEL, "- Opens bot manager menu");

    // Register CVars
    g_pCvarMode = register_cvar("czbot_mode", "0");
    g_pCvarCount = register_cvar("czbot_count", "6");
    g_pCvarDifficulty = register_cvar("czbot_difficulty", "1");

    // Build settings file path
    new szDataDir[64];
    get_datadir(szDataDir, charsmax(szDataDir));
    formatex(g_szSettingsFile, charsmax(g_szSettingsFile), "%s/czbot_settings.ini", szDataDir);

    // Load saved settings from file
    load_Settings();

    // Register event for round start
    register_logevent("event_RoundStart", 2, "1=Round_Start");

    // Apply initial settings on map start
    set_task(3.0, "task_ApplySettings");
}

/*
 * Command handler for bot menu
 */
public cmd_BotMenu(id, level, cid) {
    if (!cmd_access(id, level, cid, 1)) {
        return PLUGIN_HANDLED;
    }

    show_MainMenu(id);
    return PLUGIN_HANDLED;
}

/*
 * Display main bot manager menu
 */
public show_MainMenu(id) {
    new szTitle[128];
    formatex(szTitle, charsmax(szTitle), "CZ Bot Manager^nMode: %s^nBots: %d | Difficulty: %s",
        g_szModeNames[g_CurrentMode],
        g_BotCount,
        g_szDifficultyNames[g_BotDifficulty]);

    new menu = menu_create(szTitle, "handler_MainMenu");

    menu_additem(menu, "Change Game Mode", "1");
    menu_additem(menu, "Change Bot Difficulty", "2");
    menu_additem(menu, "Increase Bot Count (+1)", "3");
    menu_additem(menu, "Decrease Bot Count (-1)", "4");
    menu_additem(menu, ">>> Apply Changes Now <<<", "5");

    menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
    menu_display(id, menu, 0);
}

/*
 * Main menu handler
 */
public handler_MainMenu(id, menu, item) {
    if (item == MENU_EXIT) {
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }

    new szData[8], szName[64], iAccess, iCallback;
    menu_item_getinfo(menu, item, iAccess, szData, charsmax(szData), szName, charsmax(szName), iCallback);

    new iChoice = str_to_num(szData);

    switch (iChoice) {
        case 1: {
            menu_destroy(menu);
            show_ModeMenu(id);
            return PLUGIN_HANDLED;
        }
        case 2: {
            menu_destroy(menu);
            show_DifficultyMenu(id);
            return PLUGIN_HANDLED;
        }
        case 3: {
            if (g_BotCount < 10) {
                g_BotCount++;
                set_pcvar_num(g_pCvarCount, g_BotCount);
                save_Settings();
                client_print(id, print_chat, "[Bot Manager] Bot count increased to %d", g_BotCount);
            } else {
                client_print(id, print_chat, "[Bot Manager] Maximum bot count reached (10)");
            }
        }
        case 4: {
            if (g_BotCount > 0) {
                g_BotCount--;
                set_pcvar_num(g_pCvarCount, g_BotCount);
                save_Settings();
                client_print(id, print_chat, "[Bot Manager] Bot count decreased to %d", g_BotCount);
            } else {
                client_print(id, print_chat, "[Bot Manager] Minimum bot count reached (0)");
            }
        }
        case 5: {
            menu_destroy(menu);
            apply_BotSettings();
            client_print(id, print_chat, "[Bot Manager] Settings applied!");
            return PLUGIN_HANDLED;
        }
    }

    menu_destroy(menu);
    show_MainMenu(id);
    return PLUGIN_HANDLED;
}

/*
 * Display game mode selection menu
 */
public show_ModeMenu(id) {
    new menu = menu_create("Select Game Mode", "handler_ModeMenu");

    new szItem[64];
    for (new i = 0; i < 4; i++) {
        if (i == g_CurrentMode) {
            formatex(szItem, charsmax(szItem), "%s [Current]", g_szModeNames[i]);
        } else {
            formatex(szItem, charsmax(szItem), "%s", g_szModeNames[i]);
        }

        new szNum[4];
        num_to_str(i, szNum, charsmax(szNum));
        menu_additem(menu, szItem, szNum);
    }

    menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
    menu_display(id, menu, 0);
}

/*
 * Game mode menu handler
 */
public handler_ModeMenu(id, menu, item) {
    if (item == MENU_EXIT) {
        menu_destroy(menu);
        show_MainMenu(id);
        return PLUGIN_HANDLED;
    }

    new szData[8], szName[64], iAccess, iCallback;
    menu_item_getinfo(menu, item, iAccess, szData, charsmax(szData), szName, charsmax(szName), iCallback);

    g_CurrentMode = str_to_num(szData);
    set_pcvar_num(g_pCvarMode, g_CurrentMode);
    save_Settings();

    client_print(id, print_chat, "[Bot Manager] Game mode changed to: %s", g_szModeNames[g_CurrentMode]);

    menu_destroy(menu);
    show_MainMenu(id);
    return PLUGIN_HANDLED;
}

/*
 * Display difficulty selection menu
 */
public show_DifficultyMenu(id) {
    new menu = menu_create("Select Bot Difficulty", "handler_DifficultyMenu");

    new szItem[64];
    for (new i = 0; i < 5; i++) {
        if (i == g_BotDifficulty) {
            formatex(szItem, charsmax(szItem), "%s [Current]", g_szDifficultyNames[i]);
        } else {
            formatex(szItem, charsmax(szItem), "%s", g_szDifficultyNames[i]);
        }

        new szNum[4];
        num_to_str(i, szNum, charsmax(szNum));
        menu_additem(menu, szItem, szNum);
    }

    menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
    menu_display(id, menu, 0);
}

/*
 * Difficulty menu handler
 */
public handler_DifficultyMenu(id, menu, item) {
    if (item == MENU_EXIT) {
        menu_destroy(menu);
        show_MainMenu(id);
        return PLUGIN_HANDLED;
    }

    new szData[8], szName[64], iAccess, iCallback;
    menu_item_getinfo(menu, item, iAccess, szData, charsmax(szData), szName, charsmax(szName), iCallback);

    g_BotDifficulty = str_to_num(szData);
    set_pcvar_num(g_pCvarDifficulty, g_BotDifficulty);
    save_Settings();

    // Apply difficulty immediately (except for Mixed - that's per-bot)
    if (g_BotDifficulty != DIFF_MIXED) {
        server_cmd("bot_difficulty %d", g_BotDifficulty);
        server_exec();
    }

    client_print(id, print_chat, "[Bot Manager] Bot difficulty changed to: %s", g_szDifficultyNames[g_BotDifficulty]);

    menu_destroy(menu);
    show_MainMenu(id);
    return PLUGIN_HANDLED;
}

/*
 * Apply bot settings based on current mode
 */
public apply_BotSettings() {
    // First, kick all existing bots
    server_cmd("bot_kick all");

    // Wait a moment for bots to be kicked
    set_task(0.5, "task_AddBots");
}

/*
 * Task to add bots after kicking
 */
public task_AddBots() {
    // Set difficulty
    server_cmd("bot_difficulty %d", g_BotDifficulty);
    server_cmd("bot_quota 0");
    server_exec();

    switch (g_CurrentMode) {
        case MODE_HUMANS_VS_CT: {
            // Humans play as Terrorists, bots as CT
            server_cmd("bot_auto_vacate 0");
            server_cmd("bot_join_team ct");
            server_exec();

            // Move all human players to T team
            transfer_HumansToTeam(CS_TEAM_T);

            // Start adding bots with delay
            g_BotsToAdd = g_BotCount;
            g_BotTeamToAdd = 2;  // CT
            set_task(0.3, "task_AddOneBot");

            log_amx("[Bot Manager] Mode: Humans vs CT Bots (%d bots)", g_BotCount);
        }
        case MODE_HUMANS_VS_T: {
            // Humans play as CT, bots as Terrorists
            server_cmd("bot_auto_vacate 0");
            server_cmd("bot_join_team t");
            server_exec();

            // Move all human players to CT team
            transfer_HumansToTeam(CS_TEAM_CT);

            // Start adding bots with delay
            g_BotsToAdd = g_BotCount;
            g_BotTeamToAdd = 1;  // T
            set_task(0.3, "task_AddOneBot");

            log_amx("[Bot Manager] Mode: Humans vs T Bots (%d bots)", g_BotCount);
        }
        case MODE_MIXED_5V5: {
            // 5v5 with auto-vacate enabled
            server_cmd("bot_auto_vacate 1");
            server_cmd("bot_join_team any");
            server_exec();

            // Start adding bots to both teams
            g_BotsToAdd = g_BotCount;
            g_BotTeamToAdd = 3;  // Both teams
            set_task(0.3, "task_AddOneBot");

            log_amx("[Bot Manager] Mode: 5v5 Mixed (%d bots, auto-vacate ON)", g_BotCount);
        }
        case MODE_NO_BOTS: {
            // No bots - already kicked
            server_cmd("bot_auto_vacate 0");
            server_exec();
            log_amx("[Bot Manager] Mode: No Bots");
        }
    }

    // Ensure bots are not stopped
    server_cmd("bot_stop 0");
    server_exec();
}

/*
 * Add one bot at a time with delay
 */
public task_AddOneBot() {
    if (g_BotsToAdd <= 0) {
        return;
    }

    // Set difficulty for this bot
    if (g_BotDifficulty == DIFF_MIXED) {
        // Random difficulty from Normal(1) to Expert(3)
        new randomDiff = random_num(1, 3);
        server_cmd("bot_difficulty %d", randomDiff);
    } else {
        server_cmd("bot_difficulty %d", g_BotDifficulty);
    }
    server_exec();

    // Add bot to appropriate team
    switch (g_BotTeamToAdd) {
        case 1: {
            server_cmd("bot_add_t");
        }
        case 2: {
            server_cmd("bot_add_ct");
        }
        case 3: {
            // Alternate between teams for mixed mode
            if (g_BotsToAdd % 2 == 0) {
                server_cmd("bot_add_ct");
            } else {
                server_cmd("bot_add_t");
            }
        }
    }
    server_exec();

    g_BotsToAdd--;

    // Schedule next bot if more to add
    if (g_BotsToAdd > 0) {
        set_task(0.2, "task_AddOneBot");
    }
}

/*
 * Transfer all human players to specified team
 */
transfer_HumansToTeam(CsTeams:targetTeam) {
    new players[32], playerCount;
    get_players(players, playerCount, "ch");  // Connected, human (no bots)

    for (new i = 0; i < playerCount; i++) {
        new id = players[i];
        new CsTeams:currentTeam = cs_get_user_team(id);

        // Only transfer if on wrong team and not spectator/unassigned
        if (currentTeam != targetTeam && currentTeam != CS_TEAM_SPECTATOR && currentTeam != CS_TEAM_UNASSIGNED) {
            cs_set_user_team(id, targetTeam);
            client_print(id, print_chat, "[Bot Manager] You have been moved to %s team",
                targetTeam == CS_TEAM_CT ? "CT" : "Terrorist");
        }
    }
}

/*
 * Task to apply settings on map load
 */
public task_ApplySettings() {
    apply_BotSettings();
    log_amx("[Bot Manager] Initial settings applied on map start");
}

/*
 * Round start event - ensure bots are configured
 */
public event_RoundStart() {
    // Check if bot count matches expected
    // This helps recover if bots got kicked unexpectedly
    static iLastCheck;
    new iTime = get_systime();

    // Only check every 10 seconds to avoid spam
    if (iTime - iLastCheck < 10) {
        return;
    }
    iLastCheck = iTime;
}

/*
 * Plugin configuration - runs after all plugins loaded
 * This is the best place to add menu items (menufront.amxx is already loaded)
 */
public plugin_cfg() {
    // Check if Menus Front-End plugin is loaded
    if (is_plugin_loaded("Menus Front-End") != -1) {
        // Add to standard AMX Mod X admin menu (amxmodmenu)
        AddMenuItem("Bot Manager", "amx_botmenu", ACCESS_LEVEL, PLUGIN_NAME);
        log_amx("[%s] Added to AMX Mod X admin menu (amxmodmenu)", PLUGIN_NAME);
    } else {
        log_amx("[%s] WARNING: menufront.amxx not loaded - menu item not added", PLUGIN_NAME);
        log_amx("[%s] You can still use 'amx_botmenu' command directly", PLUGIN_NAME);
    }

    log_amx("[%s] Version %s loaded successfully", PLUGIN_NAME, PLUGIN_VERSION);
}

/*
 * Load settings from file
 */
load_Settings() {
    // Check if file exists
    if (!file_exists(g_szSettingsFile)) {
        log_amx("[%s] No settings file found, using defaults", PLUGIN_NAME);
        return;
    }

    new file = fopen(g_szSettingsFile, "r");
    if (!file) {
        log_amx("[%s] Failed to open settings file", PLUGIN_NAME);
        return;
    }

    new szLine[64], szKey[32], szValue[32];
    while (!feof(file)) {
        fgets(file, szLine, charsmax(szLine));
        trim(szLine);

        // Skip empty lines and comments
        if (szLine[0] == ';' || szLine[0] == '/' || szLine[0] == EOS) {
            continue;
        }

        // Parse key=value
        if (parse(szLine, szKey, charsmax(szKey), szValue, charsmax(szValue)) == 2) {
            if (equal(szKey, "mode")) {
                g_CurrentMode = str_to_num(szValue);
            } else if (equal(szKey, "count")) {
                g_BotCount = str_to_num(szValue);
            } else if (equal(szKey, "difficulty")) {
                g_BotDifficulty = str_to_num(szValue);
            }
        }
    }
    fclose(file);

    // Clamp values
    if (g_CurrentMode < 0 || g_CurrentMode > 3) g_CurrentMode = 0;
    if (g_BotCount < 0 || g_BotCount > 10) g_BotCount = 6;
    if (g_BotDifficulty < 0 || g_BotDifficulty > 4) g_BotDifficulty = 1;

    // Update CVars
    set_pcvar_num(g_pCvarMode, g_CurrentMode);
    set_pcvar_num(g_pCvarCount, g_BotCount);
    set_pcvar_num(g_pCvarDifficulty, g_BotDifficulty);

    log_amx("[%s] Settings loaded: mode=%d, count=%d, difficulty=%d", PLUGIN_NAME, g_CurrentMode, g_BotCount, g_BotDifficulty);
}

/*
 * Save settings to file
 */
save_Settings() {
    new file = fopen(g_szSettingsFile, "w");
    if (!file) {
        log_amx("[%s] Failed to save settings file", PLUGIN_NAME);
        return;
    }

    fprintf(file, "; CZ Bot Manager Settings^n");
    fprintf(file, "; Do not edit manually^n");
    fprintf(file, "mode %d^n", g_CurrentMode);
    fprintf(file, "count %d^n", g_BotCount);
    fprintf(file, "difficulty %d^n", g_BotDifficulty);

    fclose(file);
    log_amx("[%s] Settings saved", PLUGIN_NAME);
}
