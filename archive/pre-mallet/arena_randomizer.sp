#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>

#include <json>
#include <files>

#include "hmmr_weapon_attribute_adapter.sp"

#pragma semicolon 1
#pragma newdecls required
#pragma dynamic 131072

#define FILE_LOCATION "cfg/hmmr/arena-randomizer/loadouts.json"
#define FILE_MAX_SIZE (1 * 1024 * 1024)

#define DEFAULT_UI_ICON "leaderboard_dominated"

public Plugin myinfo = 
{
	name = "Arena Randomizer",
	author = "CoolJosh3k, rake",
	description = "A improved re-implementation of TF2TightRope's Project Ghost, adapted for hmmr.tf",
	version = "1.0.0",
	url = "https://hmmr.tf/open"
}

JSON_Array DATA;

public bool InitJsonData()
{
	int bufferSize = FileSize(FILE_LOCATION);

	if (bufferSize <= 0) {
		SetFailState("InitJsonData: Got an invalid buffer size, you are probably missing a config file.");
		return false;
	}

	Handle file = OpenFile(FILE_LOCATION, "r");
	char[] buffer = new char[bufferSize];

	int read = ReadFileString(file, buffer, FILE_MAX_SIZE, -1);
	if (read != bufferSize) {
		CloseHandle(file);
		SetFailState("InitJsonData: Did not read the expected amount. (got: %i, wanted: %i)", read, bufferSize);
		return false;
	}

	CloseHandle(file);
	DATA = view_as<JSON_Array>(json_decode(buffer));

	PrintToServer("[ArenaRandomizer] InitJsonData: Loaded %i loadouts.", DATA.Length);
	return true;
}

Handle CON_VAR_ARENA_USE_QUEUE = INVALID_HANDLE;

public void OnPluginStart()
{
	hmmr_weapon_adapter_init();
	hmmr_attribute_adapter_init();

	if (!InitJsonData()) {
		return;
	}

	HookEvent("arena_round_start", ArenaRound, EventHookMode_PostNoCopy);

	CON_VAR_ARENA_USE_QUEUE = FindConVar("tf_arena_use_queue");
	if (CON_VAR_ARENA_USE_QUEUE == INVALID_HANDLE) {
		SetFailState("OnPluginStart: Failed to find 'tf_arena_use_queue'");
		return;
	}
	SetConVarInt(CON_VAR_ARENA_USE_QUEUE, 0);
}

public int GetLoadoutIdx() {
	return GetRandomInt(0, DATA.Length - 1);
}

public TFClassType ConvertClassFromString(const char[] strclass)
{
	if (StrEqual(strclass, "scout", false))
	{
		return TFClass_Scout;
	}
	else if (StrEqual(strclass, "soldier", false))
	{
		return TFClass_Soldier;
	}
	else if (StrEqual(strclass, "pyro", false))
	{
		return TFClass_Pyro;
	}
	else if (StrEqual(strclass, "demoman", false))
	{
		return TFClass_DemoMan;
	}
	else if (StrEqual(strclass, "heavy", false))
	{
		return TFClass_Heavy;
	}
	else if (StrEqual(strclass, "engineer", false))
	{
		return TFClass_Engineer;
	}
	else if (StrEqual(strclass, "medic", false))
	{
		return TFClass_Medic;
	}
	else if (StrEqual(strclass, "sniper", false))
	{
		return TFClass_Sniper;
	}
	else if (StrEqual(strclass, "spy", false))
	{
		return TFClass_Spy;
	}
	else
	{
		return TFClass_Unknown;
	}
}

public int ConvertSlotFromString(const char[] strclass)
{
	if (StrEqual(strclass, "primary", false))
	{
		return TFWeaponSlot_Primary;
	}
	else if (StrEqual(strclass, "secondary", false))
	{
		return TFWeaponSlot_Secondary;
	}
	else if (StrEqual(strclass, "melee", false))
	{
		return TFWeaponSlot_Melee;
	}
	else if (StrEqual(strclass, "grenade", false))
	{
		return TFWeaponSlot_Grenade;
	}
	else if (StrEqual(strclass, "building", false))
	{
		return TFWeaponSlot_Building;
	}
	else if (StrEqual(strclass, "pda", false))
	{
		return TFWeaponSlot_PDA;
	}
	else if (StrEqual(strclass, "item1", false))
	{
		return TFWeaponSlot_Item1;
	}
	else if (StrEqual(strclass, "item2", false))
	{
		return TFWeaponSlot_Item2;
	}
	else if (StrEqual(strclass, "any", false))
	{
		/* Special value */
		return -2;
	}
	else
	{
		return -1;
	}
}

public TFTeam ConvertTeamFromString(const char[] strclass)
{
	if (StrEqual(strclass, "red", false))
	{
		return TFTeam_Red;
	}
	else if (StrEqual(strclass, "blue", false))
	{
		return TFTeam_Blue;
	}
	else if (StrEqual(strclass, "spectator", false))
	{
		return TFTeam_Spectator;
	}
	else
	{
		return TFTeam_Unassigned;
	}
}

public void SetAllPlayersClass(TFClassType class)
{
	for (int i = 1; i < MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			TF2_SetPlayerClass(i, class);
		}
	}
}

public void SetAllPlayersTeam(TFClassType class, TFTeam team)
{
	for (int i = 1; i < MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			if (TF2_GetClientTeam(i) == team)
			{
				TF2_SetPlayerClass(i, class);
			}
		}
	}
}

Handle GameTextHandle = INVALID_HANDLE;

public void ShowTextPrompt(const char[] strMessage, const char[] strIcon, const float duration)
{
	if (GameTextHandle != INVALID_HANDLE) TriggerTimer(GameTextHandle);

	int iEntity = CreateEntityByName("game_text_tf");
    DispatchKeyValue(iEntity, "message", strMessage);
    DispatchKeyValue(iEntity, "display_to_team", "0");
    DispatchKeyValue(iEntity, "icon", strIcon);
    DispatchKeyValue(iEntity, "targetname", "game_text1");
    DispatchKeyValue(iEntity, "background", "0");
    DispatchSpawn(iEntity);
    AcceptEntityInput(iEntity, "Display", iEntity, iEntity);

	GameTextHandle = CreateTimer(duration, KillGameText, iEntity);
}

public Action KillGameText(Handle hTimer, any iEntityRef)
{
    int iEntity = EntRefToEntIndex(view_as<int>(iEntityRef));
    if ((iEntity > 0) && IsValidEntity(iEntity)) AcceptEntityInput(iEntity, "kill");
    
    GameTextHandle = INVALID_HANDLE;
    
    return Plugin_Stop;
}

public void SetHealthForAll(int health)
{
	for (int i = 1; i < MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			SetEntityHealth(i, health);
		}
	}
}

public bool JSON_CONTAINS_KEY(const JSON_Object obj, const char[] key) {
	return obj.GetIndex(key) != -1;
}

public void ArenaRound(Handle event, const char[] name, bool dontBroadcast)
{
	int idx = GetLoadoutIdx();
	JSON_Object entry = DATA.GetObject(idx);

	if (entry == null) {
		SetFailState("ArenaRound: Got NULL as the round object. (idx=%i)", idx);
		return;
	}

	char _name[128];
	if (!entry.GetString("name", _name, sizeof(_name))) {
		SetFailState("ArenaRound: Invalid formatted data object, a name for the loadout is missing.");
		return;
	}

	PrintToServer("ArenaRound: Loading the following loadout: %s", _name);

	JSON_Object classes = entry.GetObject("classes");

	if (JSON_CONTAINS_KEY(classes, "all")) {
		char _class[10];
		classes.GetString("all", _class, sizeof(_class));

		TFClassType class = ConvertClassFromString(_class);
		if (class == TFClass_Unknown) {
			SetFailState("ArenaRound: Invalid formatted data object, requested an unknown class for ALL players.");
			return;
		} else {
			SetAllPlayersClass(class);
		}
	} else if (JSON_CONTAINS_KEY(classes, "red") && JSON_CONTAINS_KEY(classes, "blue"))  {
		char _red[10];
		classes.GetString("red", _red, sizeof(_red));

		char _blue[10];
		classes.GetString("blue", _blue, sizeof(_blue));

		TFClassType red = ConvertClassFromString(_red);

		if (red == TFClass_Unknown) {
			SetFailState("ArenaRound: Invalid formatted data object, requested an unknown class for RED players.");
			return;
		}

		TFClassType blue = ConvertClassFromString(_blue);

		if (blue == TFClass_Unknown) {
			SetFailState("ArenaRound: Invalid formatted data object, requested an unknown class for BLU players.");
			return;
		}

		SetAllPlayersTeam(red, TFTeam_Red);
		SetAllPlayersTeam(blue, TFTeam_Blue);
	} else if (JSON_CONTAINS_KEY(classes, "keep")) {
		/* No action required. */
	} else {
		SetFailState("ArenaRound: Invalid formatted data object, 'classes' is misconfigured.");
		return;
	}

	if (JSON_CONTAINS_KEY(entry, "weapons")) {
		JSON_Array weapons = view_as<JSON_Array>(entry.GetObject("weapons"));
		
		if (!JSON_CONTAINS_KEY(entry, "keep_weapons")) {
			/* Workaround us removing weapons at this point. */
			RemoveAllWeaponsAll();
		}

		for (int weaponIdx = 0; weaponIdx < weapons.Length; weaponIdx++)
		{
			JSON_Object weapon = weapons.GetObject(weaponIdx);

			if (!JSON_CONTAINS_KEY(weapon, "id"))
			{
				SetFailState("ArenaRound: Invalid formatted data object, 'weapons' is misconfigured.");
				return;
			}

			char weaponName[64];
			if (!weapon.GetString("name", weaponName, sizeof(weaponName)))
			{
				SetFailState("ArenaRound: Invalid formatted data object, 'weapons' is misconfigured.");
				return;
			}

			char _slot[16];
			if (!weapon.GetString("slot", _slot, sizeof(_slot)))
			{
				SetFailState("ArenaRound: Invalid formatted data object, 'weapons' is misconfigured.");
				return;
			}

			int slot = ConvertSlotFromString(_slot);
			if (slot == -1)
			{
				SetFailState("ArenaRound: Invalid formatted data object, 'weapons' requested a non-existant slot.");
				return;
			}
			else if (slot == -2)
			{
				slot = weaponIdx;
			}

			int weaponId = weapon.GetInt("id", -3);
			if (weaponId < -3)
			{
				SetFailState("ArenaRound: Invalid formatted data object, 'weapons' requested a non-existant weapon.");
				return;
			}
			
			/* TODO: Simplify this since we can safely pass NULL for 'attributes' */
			if (weaponId == -2)
			{
				/* Special value: Apply to current weapons. */

				if (JSON_CONTAINS_KEY(weapon, "attributes"))
				{
					JSON_Array attributes = view_as<JSON_Array>(weapon.GetObject("attributes"));

					for (int client = 1; client < MaxClients; client++)
					{
						if (!IsClientInGame(client) || !IsPlayerAlive(client))
						{
							continue;
						}

						for (int weaponSlot = 0; weaponSlot < 8; weaponSlot++)
						{
							int weaponEntity = GetPlayerWeaponSlot(client, weaponSlot);
							if (weaponEntity == -1)
							{
								continue;
							}

							PrintToConsole(client, "%i: ", weaponSlot);
							SetWeaponAttributes(weaponEntity, client, attributes, true, true);
						}

						PrintToChat(client, "To reduce chat clutter, your weapon's attributes were printed in your game's console.");
					}
				}
				else
				{
					SetFailState("ArenaRound: Object set the special value KEEP_WEAPON without providing attributes...");
					return;
				}
			}
			else if (JSON_CONTAINS_KEY(weapon, "attributes"))
			{
				JSON_Array attributes = view_as<JSON_Array>(weapon.GetObject("attributes"));

				if (JSON_CONTAINS_KEY(weapon, "team"))
				{
					char _team[16];
					if (!weapon.GetString("team", _team, sizeof(_team)))
					{
						SetFailState("ArenaRound: Invalid formatted data object, 'weapons' is misconfigured.");
						return;
					}

					TFTeam team = ConvertTeamFromString(_team);
					if (!GiveWeaponToTeamWithAttributes(team, weaponId, weaponName, 1, 0, slot, attributes))
					{
						SetFailState("ArenaRound: GiveWeaponToTeam returned FALSE.");
						return;
					}
				}
				else
				{
					if (!GiveWeaponToAllWithAttributes(weaponId, weaponName, 1, 0, slot, attributes))
					{
						SetFailState("ArenaRound: GiveWeaponToAll returned FALSE.");
						return;
					}
				}
			}
			else
			{
				if (JSON_CONTAINS_KEY(weapon, "team"))
				{
					char _team[16];
					if (!weapon.GetString("team", _team, sizeof(_team)))
					{
						SetFailState("ArenaRound: Invalid formatted data object, 'weapons' is misconfigured.");
						return;
					}

					TFTeam team = ConvertTeamFromString(_team);
					if (!GiveWeaponToTeam(team, weaponId, weaponName, 1, 0, slot))
					{
						SetFailState("ArenaRound: GiveWeaponToTeam returned FALSE.");
						return;
					}
				}
				else
				{
					if (!GiveWeaponToAll(weaponId, weaponName, 1, 0, slot))
					{
						SetFailState("ArenaRound: GiveWeaponToAll returned FALSE.");
						return;
					}
				}
			}

			if (JSON_CONTAINS_KEY(weapon, "ammo_clip") || JSON_CONTAINS_KEY(weapon, "ammo_reserve"))
			{
				int ammo_clip = weapon.GetInt("ammo_clip", -2);
				int ammo_reserve = weapon.GetInt("ammo_reserve", -2);

				SetWeaponAmmoAll(ammo_clip, ammo_reserve);
			}
		}
	}

	if (JSON_CONTAINS_KEY(entry, "attributes"))
	{
		JSON_Object attributes = entry.GetObject("attributes");

		if (JSON_CONTAINS_KEY(attributes, "hp"))
		{
			int health = attributes.GetInt("hp");

			if (health == -1)
			{
				SetFailState("ArenaRound: Invalid formatted data object, 'attributes' had an invalid HP value.");
				return;
			}

			SetHealthForAll(health);
		}
	}

	ShowTextPrompt(_name, DEFAULT_UI_ICON, 12.0);
}