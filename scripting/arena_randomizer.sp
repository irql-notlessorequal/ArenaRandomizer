#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>

#include <json>
#include <files>

#include <mallet>

#pragma semicolon 1
#pragma newdecls required
#pragma dynamic 65536

#define PRE_ROUND_AUDIO "hmmr/arena-randomizer/round_start.mp3"
#define PRE_ROUND_AUDIO_FULL "sound/hmmr/arena-randomizer/round_start.mp3"

#define SPECIAL_ROUND_AUDIO_BLEED "hmmr/arena-randomizer/on_hit.mp3"
#define SPECIAL_ROUND_AUDIO_BLEED_FULL "sound/hmmr/arena-randomizer/on_hit.mp3"

#define FILE_LOCATION "cfg/hmmr/arena-randomizer/loadouts.json"
#define FILE_MAX_SIZE (1 * 1024 * 1024)

#define DEFAULT_UI_ICON "leaderboard_dominated"
#define SPECIAL_ROUND_UI_ICON "leaderboard_streak"

static const char ARENA_RANDOMIZER_ROUND_START[][] = {
	"ui/tv_tune.wav",
	"ui/tv_tune2.wav",
	"ui/tv_tune3.wav"
};

static const char ARENA_RANDOMIZER_ROUND_START_SPECIAL[][] = {
	"ui/duel_event.wav",
	"ui/duel_challenge.wav",
	"ui/duel_score_behind.wav"
};

public Plugin myinfo = 
{
	name = "Arena Randomizer",
	author = "CoolJosh3k, rake",
	description = "An improved re-implementation of TF2TightRope's Project Ghost, adapted for hmmr.tf",
	version = "1.0.0",
	url = "https://hmmr.tf/open"
}

Handle GameTextHandle = INVALID_HANDLE;
Handle CON_VAR_ARENA_USE_QUEUE = INVALID_HANDLE;
int g_PlayerVisibleWeapon[MAXPLAYERS + 1] = -1;
bool IsArenaRandomizer = true; /* TODO(rake): Put this back to false once we support multiple map change APIs and are done with testing */
bool GenevaConventionSuggestion = false;
JSON_Array DATA;

public bool InitJsonData()
{
	int bufferSize = FileSize(FILE_LOCATION);

	if (bufferSize <= 0)
	{
		SetFailState("InitJsonData: Got an invalid buffer size, you are probably missing a config file.");
		return false;
	}

	Handle file = OpenFile(FILE_LOCATION, "r");
	char[] buffer = new char[bufferSize];

	int read = ReadFileString(file, buffer, FILE_MAX_SIZE, -1);
	if (read != bufferSize)
	{
		CloseHandle(file);
		SetFailState("InitJsonData: Did not read the expected amount. (got: %i, wanted: %i)", read, bufferSize);
		return false;
	}

	CloseHandle(file);
	DATA = view_as<JSON_Array>(json_decode(buffer));

	PrintToServer("[ArenaRandomizer] InitJsonData: Loaded %i loadouts.", DATA.Length);
	return true;
}

public void OnPluginStart()
{
	if (!InitJsonData())
	{
		return;
	}

	PrecacheSound(PRE_ROUND_AUDIO);
	PrecacheSound(SPECIAL_ROUND_AUDIO_BLEED);

	/* TODO(rake): We'll probably want to hard-code this into a define. */
	for (int idx = 0; idx < 3; idx++)
	{
		PrecacheSound(ARENA_RANDOMIZER_ROUND_START[idx]);
	}

	for (int idx = 0; idx < 3; idx++)
	{
		PrecacheSound(ARENA_RANDOMIZER_ROUND_START_SPECIAL[idx]);
	}

	AddFileToDownloadsTable(PRE_ROUND_AUDIO_FULL);
	AddFileToDownloadsTable(SPECIAL_ROUND_AUDIO_BLEED_FULL);

	if (!HookEventEx("map_chooser_map_change", Event_MapChooser_MapLoaded, EventHookMode_PostNoCopy))
	{
		PrintToServer("[ArenaRandomizer] [WARNING] Failed to hook into MapChooser, this might break things!");
	}

	RegAdminCmd("arena_randomizer_reload", ArenaRandomizerReload, ADMFLAG_ROOT, "Reloads the loadout config.");

	HookEvent("arena_round_start", ArenaRound, EventHookMode_PostNoCopy);
	HookEvent("arena_win_panel", RoundEndAudio, EventHookMode_PostNoCopy);

	CON_VAR_ARENA_USE_QUEUE = FindConVar("tf_arena_use_queue");
	if (CON_VAR_ARENA_USE_QUEUE == INVALID_HANDLE)
	{
		SetFailState("OnPluginStart: Failed to find 'tf_arena_use_queue'");
		return;
	}

	SetConVarInt(CON_VAR_ARENA_USE_QUEUE, 0);
}

public Action ArenaRandomizerReload(int client, int args)
{
	PrintToServer("Reloading Arena Randomizer loadout...");

	delete DATA;
	if (!InitJsonData())
	{
		SetFailState("Failed to reload loadout.");
		return Plugin_Stop;
	}
	else
	{
		return Plugin_Handled;
	}
}

public int GetLoadoutIdx() {
	/* Don't go into below loop otherwise we will deadlock and die. */
	if (DATA.Length == 1)
	{
		return 0;
	}

	static int previous_roll = -1;

	int roll;
	do {
		/* Prevent rolling the same fucking thing. */
		roll = GetRandomInt(0, DATA.Length - 1);

		if (roll == previous_roll)
		{
			continue;
		}

		previous_roll = roll;
		break;
	} while (true);

	return roll;
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

int GetRandomWeapon()
{
	/* TODO(rake) */
	return -1;
}

int GetRandomAttributeID()
{
	/* There are more attributes but I can be bothered to take a gap into account. */
	int _attribute = GetRandomInt(1, 881);
	
	/* These will crash players, re-roll instead. */
	if (_attribute >= 554 && _attribute <= 609)
	{
		return GetRandomAttributeID();
	} 
	else
	{
		return _attribute;
	}
}

bool __CONVERT_TO_COMPATIBLE_TYPE(const JSON_Object attribute, const char[] name, const JSONCellType ct, float &ret)
{
	switch (ct) {
		case JSON_Type_Int: {
			int _val;
			if (!attribute.GetValue(name, _val))
			{
				PrintToServer("[hmmr/weapon_attribute_adapter] __CONVERT_TO_COMPATIBLE_TYPE: GetValue returned FALSE.");
				return false;
			}
			else
			{
				ret = float(_val);
				return true;
			}
		}
		case JSON_Type_Float: {
			ret = attribute.GetFloat(name);
			return true;
		}
		case JSON_Type_Bool: {
			bool _temp = attribute.GetBool(name);
			ret = _temp ? 1.0 : 0.0;
			return true;
		}
		default: {
			PrintToServer("[hmmr/weapon_attribute_adapter] __CONVERT_TO_COMPATIBLE_TYPE: Unknown type: %i", ct);
			return false;
		}
	}
}

stock bool IsValidClient(int client) {
    return (client >= 1 && client <= MaxClients
		&& IsClientConnected(client) && IsClientInGame(client)
		&& !IsClientSourceTV(client));
}

public bool JSON_CONTAINS_KEY(const JSON_Object obj, const char[] key) {
	return obj.GetIndex(key) != -1;
}

void SetClientSlot(int client, int slot)
{
	if (!IsValidClient(client) || !IsPlayerAlive(client))
	{
		return;
	}

	int weapon = GetPlayerWeaponSlot(client, slot);
	SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
}

public void RemoveAllWeapons(int clientIdx)
{
    for (int weaponSlot = 0; weaponSlot <= 5; weaponSlot++)
	{
		TF2_RemoveWeaponSlot(clientIdx, weaponSlot);
	}
}

Action SetWeaponState(int client, bool input) {
    int ActiveWeapon = GetEntDataEnt2(client, FindSendPropOffs("CTFPlayer", "m_hActiveWeapon"));
    int iEntity = g_PlayerVisibleWeapon[client];
    if (IsValidEntity(ActiveWeapon))
	{
        if (input == true)
		{
            SetEntityRenderColor(ActiveWeapon, 255, 255, 255, 255);
            SetEntityRenderMode(ActiveWeapon, RENDER_NORMAL);
            SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
        }
		else
		{
            SetEntityRenderColor(ActiveWeapon, 255, 255, 255, 0);
            SetEntityRenderMode(ActiveWeapon, RENDER_TRANSCOLOR);
            SetWeaponAmmo(client, 0, 0);
            SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0);
        }
    }

    if (iEntity > 0 && IsValidEntity(iEntity))
	{
        if (input == true)
		{
            SetEntityRenderColor(iEntity, 255, 255, 255, 255);
            SetEntityRenderMode(iEntity, RENDER_NORMAL);
        }
        else
		{
            SetEntityRenderColor(iEntity, 255, 255, 255, 0);
            SetEntityRenderMode(iEntity, RENDER_TRANSCOLOR);
        }
    }
}

public void RemoveAllWeaponsAll()
{
	for (int i = 1; i < MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			RemoveAllWeapons(i);
		}
	}
	
}

public void SetWeaponAmmoAll(int slot1, int slot2) {
	for (int i = 1; i < MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			SetWeaponAmmo(i, slot1, slot2);
		}
	}
}

public void SetWeaponAmmo(int client, int slot1, int slot2) {
    int ActiveWeapon = GetEntDataEnt2(client, FindSendPropOffs("CTFPlayer", "m_hActiveWeapon"));
    if (IsValidEntity(ActiveWeapon)) {
		if (slot1 != -2) {
			SetEntData(ActiveWeapon, FindSendPropOffs("CBaseCombatWeapon", "m_iClip1"), slot1, 4);
		}
        if (slot2 != -2) {
			SetEntData(client, FindSendPropOffs("CTFPlayer", "m_iAmmo") + 4, slot2, 4);
        	SetEntData(client, FindSendPropOffs("CTFPlayer", "m_iAmmo") + 8, slot2, 4);
		}
    }
}

bool ApplyWeaponAttributes(int weapon, int client, JSON_Array attributes, bool deleteAttribs, bool printAttribs)
{
	if (attributes == null)
	{
		return false;
	}

	if (MalletIsWearable(weapon))
	{
		/* Applying attributes to a wearable causes crashes, apply it to the player instead. */
		weapon = GetEntPropEnt(weapon, Prop_Data, "m_hOwnerEntity");
	}

	/* Make sure we are clearing the attribute of the weapon not the wearable. */
	if (deleteAttribs)
	{
		if (MalletDeleteAllAttributes(weapon) == -1)
		{
			PrintToServer("ApplyWeaponAttributes: DeleteAllAttributes() returned -1.");
			return false;
		}
	}

	for (int idx = 0; idx < attributes.Length; idx++)
	{
		JSON_Object attribute = attributes.GetObject(idx);

		int id = attribute.GetInt("id", -2);

		/* Do the check early since we will be overriding the value in a moment. */
		bool is_random = id == -1;

		if (id <= -2)
		{
			PrintToServer("ApplyWeaponAttributes: 'attribute::id' was misconfigured.");
			return false;
		}

		float value;

		if (id == -1)
		{
			/* Treat this as a special value to generate a random attribute. */
			id = GetRandomAttributeID();
			value = GetRandomFloat(-10.0, 10.0);
		}
		else
		{
			JSONCellType ct = attribute.GetType("value");
			if (!__CONVERT_TO_COMPATIBLE_TYPE(attribute, "value", ct, value))
			{
				PrintToServer("ApplyWeaponAttributes: 'attribute::value' was misconfigured, got %f.", value);
				return false;
			}
		}

		/* Ignore errors when we're using random attributes since our process is literal trial and error. */
		int ret = MalletSetAttribute(weapon, id, value);

		if (ret <= 0 && !is_random)
		{
			PrintToServer("ApplyWeaponAttributes: SetAttribute() returned %i.", ret);
			return false;
		}

		if (printAttribs)
		{
			char attrStr[128];
			if (!MalletGetAttributeLocalization(id, attrStr, sizeof attrStr))
			{
				PrintToConsole(client, "[unknown attribute (%i)]: %f", id, value);
			}
			else
			{
				PrintToConsole(client, "%s: %f", attrStr, value);
			}
		}

	}

	return true;
}

public bool GiveWeaponToAllWithAttributes(int weaponId, const char[] weaponName, int level, int quality, int weaponSlot, JSON_Array attributes)
{
	for (int i = 1; i < MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			int weaponEntity = MalletCreateWeaponDumb(i, weaponId, weaponName, level, quality, weaponSlot);

			if (weaponEntity <= 0)
			{
				return false;
			}

			if (!ApplyWeaponAttributes(weaponEntity, i, attributes, false, false))
			{
				return false;
			}

			/* MalletCreateWeaponDumb automagically equips wearables for us, don't try to equip a wearable or we'll crash. */
			if (!MalletIsWearable(weaponEntity))
			{
				EquipPlayerWeapon(i, weaponEntity);
			}
		}
	}
	return true;
}

public bool GiveWeaponToTeamWithAttributes(TFTeam team, int weaponId, const char[] weaponName, int level, int quality, int weaponSlot, JSON_Array attributes)
{
	for (int i = 1; i < MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			if (TF2_GetClientTeam(i) == team)
			{
				int weaponEntity = MalletCreateWeaponDumb(i, weaponId, weaponName, level, quality, weaponSlot);

				if (weaponEntity <= 0)
				{
					return false;
				}

				if (!ApplyWeaponAttributes(weaponEntity, i, attributes, false, false))
				{
					return false;
				}

				/* MalletCreateWeaponDumb automagically equips wearables for us, don't try to equip a wearable or we'll crash. */
				if (!MalletIsWearable(weaponEntity))
				{
					EquipPlayerWeapon(i, weaponEntity);
				}
			}
		}
	}
	return true;
}


public bool GiveWeaponToAll(int weaponId, const char[] weaponName, int level, int quality, int weaponSlot)
{
	for (int i = 1; i < MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			int weaponEntity = MalletCreateWeaponDumb(i, weaponId, weaponName, level, quality, weaponSlot);

			if (weaponEntity <= 0)
			{
				return false;
			}

			/* MalletCreateWeaponDumb automagically equips wearables for us, don't try to equip a wearable or we'll crash. */
			if (!MalletIsWearable(weaponEntity))
			{
				EquipPlayerWeapon(i, weaponEntity);
			}
		}
	}
	return true;
}

public bool GiveWeaponToTeam(TFTeam team, int weaponId, const char[] weaponName, int level, int quality, int weaponSlot)
{
	for (int i = 1; i < MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			if (TF2_GetClientTeam(i) == team)
			{
				int weaponEntity = MalletCreateWeaponDumb(i, weaponId, weaponName, level, quality, weaponSlot);

				if (weaponEntity <= 0)
				{
					return false;
				}

				/* MalletCreateWeaponDumb automagically equips wearables for us, don't try to equip a wearable or we'll crash. */
				if (!MalletIsWearable(weaponEntity))
				{
					EquipPlayerWeapon(i, weaponEntity);
				}
			}
		}
	}
	return true;
}

public void ArenaRound(Handle event, const char[] name, bool dontBroadcast)
{
	if (!IsArenaRandomizer)
		return;

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

		TFClassType class = MalletConvertClassFromString(_class);
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

		TFClassType red = MalletConvertClassFromString(_red);

		if (red == TFClass_Unknown) {
			SetFailState("ArenaRound: Invalid formatted data object, requested an unknown class for RED players.");
			return;
		}

		TFClassType blue = MalletConvertClassFromString(_blue);

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
		bool keep_weapons = entry.GetBool("keep_weapons");
		bool print_weapon_attribs = entry.GetBool("print_attribs");
		
		if (keep_weapons) {
			PrintToServer("[ArenaRandomizer] Keeping player weapons, this might break future rounds...");
		} else {
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

			int slot = MalletConvertSlotFromString(_slot);
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

			if (weaponId == -1)
			{
				/* TODO */
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

							if (print_weapon_attribs)
							{
								PrintToConsole(client, "slot %i: ", weaponSlot);
							}

							if (!ApplyWeaponAttributes(weaponEntity, client, attributes, true, print_weapon_attribs))
							{
								SetFailState("ArenaRound: ApplyWeaponAttributes() returned FALSE.");
								return;
							}
						}

						if (print_weapon_attribs) 
						{
							PrintToChat(client, "To reduce chat clutter, your weapon's attributes were printed in your game's console.");
						}
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

					TFTeam team = MalletConvertTeamFromString(_team);

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

					TFTeam team = MalletConvertTeamFromString(_team);
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

	bool CustomRoundStartMusic = false;

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

		if (JSON_CONTAINS_KEY(attributes, "round_start_audio"))
		{
			char round_start_path[256];

			if (!attributes.GetString("round_start_audio", round_start_path, 256))
			{
				PrintToServer("[WARNING] ArenaRound: Failed to read round_start_audio!");
			}
			else
			{
				CustomRoundStartMusic = true;
				EmitSoundToAll(round_start_path);
			}
		}
	}

	bool IsSpecialRound = entry.GetBool("special_round", false);
	
	ShowTextPrompt(_name, IsSpecialRound ? SPECIAL_ROUND_UI_ICON : DEFAULT_UI_ICON, 12.0);

	GenevaConventionSuggestion = IsSpecialRound && strcmp(_name, "The Geneva Suggestion") == 0;

	if (!CustomRoundStartMusic)
	{
		if (IsSpecialRound)
		{
			int idx = GetRandomInt(0, 2);
			EmitSoundToAll(ARENA_RANDOMIZER_ROUND_START_SPECIAL[idx]);
		}
		else
		{
			int idx = GetRandomInt(0, 2);
			EmitSoundToAll(ARENA_RANDOMIZER_ROUND_START[idx]);
		}
	}
}

public void RoundEndAudio(Handle event, const char[] name, bool dontBroadcast)
{
	if (!IsArenaRandomizer)
		return;

	CreateTimer(14.92, PlayRoundEndClip, _);
}

public Action PlayRoundEndClip(Handle timer)
{
	EmitSoundToAll(PRE_ROUND_AUDIO);

	return Plugin_Stop;
}

public Action Event_MapChooser_MapLoaded(Event event, const char[] name, bool dontBroadcast)
{
	char gamemode[64];
	event.GetString("gamemode", gamemode, 64, "UNKNOWN");

	IsArenaRandomizer = strcmp(gamemode, "Arena Randomizer") == 0;
	return Plugin_Continue;
}

public void TF2_OnConditionAdded(int client, TFCond condition)
{
	/* Required for that very special round, I love commiting warcrimes. */
	if (IsArenaRandomizer && GenevaConventionSuggestion && condition == TFCond_Gas)
	{
		IgniteEntity(client, 10.0);
	}
}