#include "arena_randomizer_utils.sp"

#pragma semicolon 1
#pragma newdecls required
#pragma dynamic 65536

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

static const char ARENA_RANDOMIZER_WORKAROUND_PERKS[][] = {
	"arena_perks"
};

static const char ARENA_RANDOMIZER_WORKAROUND_LAE[][] = {
	"arena_lumberyard_event"
};

static const char ARENA_RANDOMIZER_GAMEMODE_END[][] = {
	"hmmr/arena-randomizer/gamemode_end1.mp3",
	"hmmr/arena-randomizer/gamemode_end2.mp3",
	"hmmr/arena-randomizer/gamemode_end3.mp3",
	"hmmr/arena-randomizer/gamemode_end4.mp3"
};

public Plugin myinfo = 
{
	name = "Arena Randomizer",
	author = "IRQL_NOT_LESS_OR_EQUAL",
	description = "An improved re-implementation/remake of TF2TightRope's Project Ghost.",
	version = "0.0.54",
	url = "https://github.com/irql-notlessorequal/ArenaRandomizer"
}

static int HH_ExplodeDamage = 50;
static int HH_ExplodeRadius = 200;
/**
 * 0 = Unavailable.
 * 1 = Map Chooser (internal plugin)
 */
static int HasEnhancedMapDetectionSupport = MAP_DETECTION_UNAVAILABLE;
static ArenaRandomizerSpecialRoundLogic SpecialRoundLogic = DISABLED;
static ArenaRandomizerWorkaroundMethod WorkaroundMode = NO_WORKAROUND;
static bool IsArenaRandomizer = true;
static ArrayList CustomAssets;
/* i weep */
static ArrayStack EndRoundAudioQueue;
static ArrayList OnKillAudioList;
static Handle SuddenDeathTimer = INVALID_HANDLE;
static Handle SuddenDeathDrainTimer = INVALID_HANDLE;
static Handle AmmoRegenTimer = INVALID_HANDLE;

Handle GameTextHandle = INVALID_HANDLE;
Handle CON_VAR_ARENA_USE_QUEUE = INVALID_HANDLE;
JSON_Array DATA;

bool InitJsonData()
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

	JSON_Object tmp = json_decode(buffer);
	if (!tmp)
	{
		SetFailState("InitJsonData: json_decode returned NULL!");
		return false;		
	}

	if (!tmp.IsArray)
	{
		SetFailState("InitJsonData: Expected an array, got an object instead!");
		return false;			
	}

	DATA = view_as<JSON_Array>(tmp);
	PrintToServer("[ArenaRandomizer] InitJsonData: Loaded %i loadouts.", DATA.Length);
	return true;
}

/**
 * Iterate over the JSON object, check for "attributes" and pre-load anything that we might need to serve soon.
 */
bool PreProcessJsonData()
{
	PrintToServer("[ArenaRandomizer] Pre-processing loadout, this might lag the server!");
	
	if (CustomAssets == null)
	{
		CustomAssets = new ArrayList(.blocksize = ByteCountToCells(PLATFORM_MAX_PATH));
	}
	else
	{
		CustomAssets.Clear();
	}

	for (int idx = 0; idx < DATA.Length; idx++)
	{
		JSON_Object loadout = DATA.GetObject(idx);

		if (!JSON_CONTAINS_KEY(loadout, ARENA_RANDOMIZER_ATTR))
		{
			/* No pre-process required. */
			continue;
		}

		JSON_Object attributes = loadout.GetObject(ARENA_RANDOMIZER_ATTR);

		if (JSON_CONTAINS_KEY(attributes, ARENA_RANDOMIZER_ATTR_ROUND_START))
		{
			JSONCellType ct = attributes.GetType(ARENA_RANDOMIZER_ATTR_ROUND_START);

			switch (ct)
			{
				case JSON_Type_String:
				{
					char string[PLATFORM_MAX_PATH];

					if (!attributes.GetString(ARENA_RANDOMIZER_ATTR_ROUND_START, string, PLATFORM_MAX_PATH))
					{
						PrintToServer("[ArenaRandomizer::PreProcessJsonData] GetString() returned FALSE in 'round_start_audio' for index %i!", idx);
						return false;
					}

					CustomAssets.PushString(string);
				}

				case JSON_Type_Object:
				{
					JSON_Object round_start_obj = attributes.GetObject(ARENA_RANDOMIZER_ATTR_ROUND_START);
					if (!round_start_obj.IsArray)
					{
						PrintToServer("[ArenaRandomizer::PreProcessJsonData] IsArray returned FALSE in 'round_start_audio' for index %i!", idx);
						return false;
					}

					JSON_Array array = view_as<JSON_Array>(round_start_obj);

					for (int arr_idx = 0; arr_idx < array.Length; arr_idx++)
					{
						if (array.GetType(arr_idx) != JSON_Type_String)
						{
							PrintToServer("[ArenaRandomizer::PreProcessJsonData] Invalid contents in 'round_start_audio[]' for index %i!", idx);
							return false;
						}

						char string2[PLATFORM_MAX_PATH];
						if (!array.GetString(arr_idx, string2, PLATFORM_MAX_PATH))
						{
							PrintToServer("[ArenaRandomizer::PreProcessJsonData] GetString() returned FALSE in 'round_start_audio[]' for index %i!", idx);
							return false;
						}
						
						CustomAssets.PushString(string2);
					}
				}

				default:
				{
					PrintToServer("[ArenaRandomizer::PreProcessJsonData] Invalid cell type %s for index %i!", ct, idx);
					return false;
				}
			}
		}

		if (JSON_CONTAINS_KEY(attributes, ARENA_RANDOMIZER_ATTR_ROUND_END))
		{
			JSONCellType ct = attributes.GetType(ARENA_RANDOMIZER_ATTR_ROUND_END);

			switch (ct)
			{
				case JSON_Type_String:
				{
					char string[PLATFORM_MAX_PATH];

					if (!attributes.GetString(ARENA_RANDOMIZER_ATTR_ROUND_END, string, PLATFORM_MAX_PATH))
					{
						PrintToServer("[ArenaRandomizer::PreProcessJsonData] GetString() returned FALSE in 'round_end_audio' for index %i!", idx);
						return false;
					}

					CustomAssets.PushString(string);
				}

				case JSON_Type_Object:
				{
					JSON_Object round_end_obj = attributes.GetObject(ARENA_RANDOMIZER_ATTR_ROUND_END);
					if (!round_end_obj.IsArray)
					{
						PrintToServer("[ArenaRandomizer::PreProcessJsonData] IsArray returned FALSE in 'round_end_audio' for index %i!", idx);
						return false;
					}

					JSON_Array array = view_as<JSON_Array>(round_end_obj);
					for (int arr_idx = 0; arr_idx < array.Length; arr_idx++)
					{
						if (array.GetType(arr_idx) != JSON_Type_String)
						{
							PrintToServer("[ArenaRandomizer::PreProcessJsonData] Invalid contents in 'round_end_audio[]' for index %i!", idx);
							return false;
						}

						char string2[PLATFORM_MAX_PATH];
						if (!array.GetString(arr_idx, string2, PLATFORM_MAX_PATH))
						{
							PrintToServer("[ArenaRandomizer::PreProcessJsonData] GetString() returned FALSE in 'round_end_audio[]' for index %i!", idx);
							return false;
						}

						CustomAssets.PushString(string2);
					}
				}

				default:
				{
					PrintToServer("[ArenaRandomizer::PreProcessJsonData] Invalid cell type %s for index %i!", ct, idx);
					return false;
				}
			}
		}

		if (JSON_CONTAINS_KEY(attributes, ARENA_RANDOMIZER_ATTR_ON_KILL))
		{
			JSONCellType ct = attributes.GetType(ARENA_RANDOMIZER_ATTR_ON_KILL);

			switch (ct)
			{
				case JSON_Type_String:
				{
					char string[PLATFORM_MAX_PATH];

					if (!attributes.GetString(ARENA_RANDOMIZER_ATTR_ON_KILL, string, PLATFORM_MAX_PATH))
					{
						PrintToServer("[ArenaRandomizer::PreProcessJsonData] GetString() returned FALSE in 'kill_audio' for index %i!", idx);
						return false;
					}

					CustomAssets.PushString(string);
				}

				case JSON_Type_Object:
				{
					JSON_Object on_kill_obj = attributes.GetObject(ARENA_RANDOMIZER_ATTR_ON_KILL);
					if (!on_kill_obj.IsArray)
					{
						PrintToServer("[ArenaRandomizer::PreProcessJsonData] IsArray returned FALSE in 'kill_audio' for index %i!", idx);
						return false;
					}

					JSON_Array array = view_as<JSON_Array>(on_kill_obj);
					for (int arr_idx = 0; arr_idx < array.Length; arr_idx++)
					{
						if (array.GetType(arr_idx) != JSON_Type_String)
						{
							PrintToServer("[ArenaRandomizer::PreProcessJsonData] Invalid contents in 'kill_audio[]' for index %i!", idx);
							return false;
						}

						char string2[PLATFORM_MAX_PATH];
						if (!array.GetString(arr_idx, string2, PLATFORM_MAX_PATH))
						{
							PrintToServer("[ArenaRandomizer::PreProcessJsonData] GetString() returned FALSE in 'kill_audio[]' for index %i!", idx);
							return false;
						}

						CustomAssets.PushString(string2);
					}
				}

				default:
				{
					PrintToServer("[ArenaRandomizer::PreProcessJsonData] Invalid cell type %s for index %i!", ct, idx);
					return false;
				}
			}
		}
	}

	PrintToServer("[ArenaRandomizer] Pre-process complete.");
	return true;
}

public void OnPluginStart()
{
	if (!InitJsonData())
	{
		return;
	}

	if (!PreProcessJsonData())
	{
		SetFailState("PreProcessJsonData returned FALSE.");
		return;
	}

	EndRoundAudioQueue = new ArrayStack(.blocksize = ByteCountToCells(PLATFORM_MAX_PATH));
	OnKillAudioList = new ArrayList(.blocksize = ByteCountToCells(PLATFORM_MAX_PATH));

	if (HookEventEx("map_chooser_map_change", Event_MapChooser_MapLoaded, EventHookMode_PostNoCopy))
	{
		HasEnhancedMapDetectionSupport = MAP_DETECTION_MAP_CHOOSER_API;
	}

	RegAdminCmd("arena_randomizer_reload", ArenaRandomizerReload, ADMFLAG_ROOT, "Reloads the loadout config.");
	RegAdminCmd("arena_randomizer_running", ArenaRandomizerRunning, ADMFLAG_ROOT, "Prints Arena Randomizer's status.");

	HookEvent("arena_round_start", ArenaRoundStart, EventHookMode_PostNoCopy);
	HookEvent("teamplay_setup_finished", RoundStartAlternate, EventHookMode_PostNoCopy);
	HookEvent("arena_win_panel", RoundEndAudio, EventHookMode_PostNoCopy);
	HookEvent("teamplay_point_locked", RoundEndAlternate, EventHookMode_Post);
	HookEvent("teamplay_win_panel", RoundEndAlternate2, EventHookMode_PostNoCopy);
	/* Must be MODE_PRE otherwise the event object won't be copied over. */
	HookEvent("player_death", PlayerDeath, EventHookMode_Pre);

	CON_VAR_ARENA_USE_QUEUE = FindConVar("tf_arena_use_queue");
	if (CON_VAR_ARENA_USE_QUEUE == INVALID_HANDLE)
	{
		SetFailState("OnPluginStart: Failed to find 'tf_arena_use_queue'");
		return;
	}

	SetConVarInt(CON_VAR_ARENA_USE_QUEUE, 0);
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
}

public void OnMapInit(const char[] mapName)
{
	if (HasEnhancedMapDetectionSupport != MAP_DETECTION_UNAVAILABLE)
	{
		/* Not needed. */
		return;
	}

	if (StrContains(mapName, "arena_") != 0)
	{
		/* Not an arena map. */
		IsArenaRandomizer = false;
		return;
	}

	IsArenaRandomizer = true;
	PrintToServer("[ArenaRandomizer] Detected %s as an Arena Randomizer Map, pre-loading audio.", mapName);

	if (MapRequiresWorkaround(mapName))
	{
		PrintToServer("[ArenaRandomizer] Working around map issues.");
	}

	/* Pre-load the required assets to avoid console spam. */
	SendContentHint();

#if defined(STEAMWORKS)
	SteamWorks_SetGameDescription("Arena Randomizer");
#endif
}

bool MapRequiresWorkaround(const char[] mapName)
{
	for (int i = 0; i < sizeof (ARENA_RANDOMIZER_WORKAROUND_PERKS); i++)
	{
		if (strcmp(ARENA_RANDOMIZER_WORKAROUND_PERKS[i], mapName) == 0)
		{
			WorkaroundMode = WA_ARENA_PERKS;
			return true;
		}
	}

	for (int i = 0; i < sizeof (ARENA_RANDOMIZER_WORKAROUND_LAE); i++)
	{
		if (strcmp(ARENA_RANDOMIZER_WORKAROUND_LAE[i], mapName) == 0)
		{
			WorkaroundMode = WA_LUMBERYARD_EVENT;
			return true;
		}
	}	

	WorkaroundMode = NO_WORKAROUND;
	return false;
}

public Action ArenaRandomizerReload(int client, int args)
{
	PrintToServer("Reloading Arena Randomizer loadout...");

	delete DATA;
	if (!InitJsonData())
	{
		SetFailState("Failed to reload loadout. (data init failed)");
		return Plugin_Stop;
	}
	else
	{
		if (!PreProcessJsonData())
		{
			SetFailState("Failed to reload loadout. (pre-process failed)");
			return Plugin_Stop;
		}
		else
		{
			return Plugin_Handled;
		}
	}
}

public Action ArenaRandomizerRunning(int client, int args)
{
	PrintToConsole(client, "[ArenaRandomizer] Is Running: %b", IsArenaRandomizer);
	return Plugin_Handled;
}

void SendContentHint()
{
	PrecacheSound(TF2_COUNTDOWN_5SECS);
	PrecacheSound(TF2_COUNTDOWN_4SECS);
	PrecacheSound(TF2_COUNTDOWN_3SECS);
	PrecacheSound(TF2_COUNTDOWN_2SECS);
	PrecacheSound(TF2_COUNTDOWN_1SECS);

	PrecacheSound(PRE_ROUND_AUDIO);
	PrecacheSound(SUDDEN_DEATH_AUDIO);

	for (int idx = 0; idx < ARENA_RANDOMIZER_GAMEMODE_END_ARRAY_LENGTH; idx++)
	{
		PrecacheSound(ARENA_RANDOMIZER_GAMEMODE_END[idx]);
	}

	for (int idx = 0; idx < ARENA_RANDOMIZER_DEFAULT_AUDIO_ARRAY_LENGTH; idx++)
	{
		PrecacheSound(ARENA_RANDOMIZER_ROUND_START[idx]);
	}

	for (int idx = 0; idx < ARENA_RANDOMIZER_DEFAULT_AUDIO_ARRAY_LENGTH; idx++)
	{
		PrecacheSound(ARENA_RANDOMIZER_ROUND_START_SPECIAL[idx]);
	}

	if (CustomAssets != null)
	{
		for (int idx = 0; idx < CustomAssets.Length; idx++)
		{
			char path[PLATFORM_MAX_PATH];

			if (!CustomAssets.GetString(idx, path, PLATFORM_MAX_PATH))
			{
				PrintToServer("[ArenaRandomizer::SendContentHint] Failed to call PrecacheSound() for index %i!", idx);
				continue;
			}

			PrecacheSound(path);
		}
	}

	AddFileToDownloadsTable(PRE_ROUND_AUDIO_FULL);
	AddFileToDownloadsTable(SUDDEN_DEATH_AUDIO_FULL);

	for (int idx = 0; idx < ARENA_RANDOMIZER_GAMEMODE_END_ARRAY_LENGTH; idx++)
	{
		char str[PLATFORM_MAX_PATH];
		
		StrCat(str, PLATFORM_MAX_PATH, "sound/");
		StrCat(str, PLATFORM_MAX_PATH, ARENA_RANDOMIZER_GAMEMODE_END[idx]);

		AddFileToDownloadsTable(str);
	}

	if (CustomAssets != null)
	{
		for (int idx = 0; idx < CustomAssets.Length; idx++)
		{
			char path[PLATFORM_MAX_PATH];

			if (!CustomAssets.GetString(idx, path, PLATFORM_MAX_PATH))
			{
				PrintToServer("[ArenaRandomizer::SendContentHint] Failed to call AddFileToDownloadsTable() for index %i!", idx);
				continue;
			}

			char real_path[PLATFORM_MAX_PATH + 6];
			StrCat(real_path, sizeof(real_path), "sound/");
			StrCat(real_path, sizeof(real_path), path);

			AddFileToDownloadsTable(real_path);
		}
	}
}

int GetLoadoutIdx() {
	/* Don't go into below loop otherwise we will deadlock and die. */
	if (DATA.Length == 1)
	{
		return 0;
	}

	static int previous_roll = -1;

	int roll;
	for (;;)
	{
		/* Prevent rolling the same fucking thing. */
		roll = GetRandomInt(0, DATA.Length - 1);

		if (roll == previous_roll)
		{
			continue;
		}

		previous_roll = roll;
		break;
	}

	return roll;
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

	GameTextHandle = CreateTimer(duration, KillGameText, iEntity, TIMER_FLAG_NO_MAPCHANGE);
}

public Action KillGameText(Handle hTimer, any iEntityRef)
{
	int iEntity = EntRefToEntIndex(view_as<int>(iEntityRef));
	if ((iEntity > 0) && IsValidEntity(iEntity)) AcceptEntityInput(iEntity, "kill");
		
	GameTextHandle = INVALID_HANDLE;
		
	return Plugin_Stop;
}

bool __CONVERT_TO_COMPATIBLE_TYPE(const JSON_Object attribute, const char[] name, const JSONCellType ct, float &ret)
{
	switch (ct)
	{
		case JSON_Type_Int:
		{
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
		case JSON_Type_Float:
		{
			ret = attribute.GetFloat(name);
			return true;
		}
		case JSON_Type_Bool:
		{
			bool _temp = attribute.GetBool(name);
			ret = _temp ? 1.0 : 0.0;
			return true;
		}
		default:
		{
			PrintToServer("[hmmr/weapon_attribute_adapter] __CONVERT_TO_COMPATIBLE_TYPE: Unknown type: %i", ct);
			return false;
		}
	}
}

stock bool JSON_CONTAINS_KEY(const JSON_Object obj, const char[] key)
{
	return obj.GetIndex(key) != -1;
}

bool ApplyWeaponAttributes(int weapon, int client, JSON_Array attributes, bool printAttribs)
{
	if (weapon == -1)
	{
		return false;
	}

	if (attributes == null)
	{
		return false;
	}

	if (MalletIsWearable(weapon))
	{
		/* Applying attributes to a wearable causes crashes, apply it to the player instead. */
		weapon = GetEntPropEnt(weapon, Prop_Data, "m_hOwnerEntity");
	}

	for (int idx = 0; idx < attributes.Length; idx++)
	{
		JSON_Object attribute = attributes.GetObject(idx);

		int id = attribute.GetInt("id", -2);

		/* Do the check early since we will be overriding the value in a moment. */
		bool is_random = id == ARENA_RANDOMIZER_RANDOM_ATTRIBUTE;

		if (id <= -2)
		{
			PrintToServer("ApplyWeaponAttributes: 'attribute::id' was misconfigured.");
			return false;
		}

		float value;

		if (id == ARENA_RANDOMIZER_RANDOM_ATTRIBUTE)
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
			char attrStr[256];
			if (!MalletGetAttributeDescription(id, attrStr, sizeof (attrStr), mFloatAttribute, value))
			{
				PrintToConsole(client, "[unknown attribute (%i)]: %f", id, value);
			}
			else
			{
				PrintToConsole(client, "%s", attrStr);
			}
		}

	}

	return true;
}

bool GiveWeaponToAllWithAttributes(int weaponId, const char[] weaponName, int level, int quality, int weaponSlot, JSON_Array attributes)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			int weaponEntity = MalletCreateWeapon(i, weaponId, weaponName, level, quality, weaponSlot);

			if (weaponEntity <= 0)
			{
				return false;
			}

			if (!ApplyWeaponAttributes(weaponEntity, i, attributes, false))
			{
				return false;
			}

			/* MalletCreateWeapon automagically equips wearables for us, don't try to equip a wearable or we'll crash. */
			if (!MalletIsWearable(weaponEntity))
			{
				MalletSwapWeaponAndPurge(i, weaponEntity, weaponSlot);
			}
		}
	}
	return true;
}

bool GiveWeaponToTeamWithAttributes(TFTeam team, int weaponId, const char[] weaponName, int level, int quality, int weaponSlot, JSON_Array attributes)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			if (TF2_GetClientTeam(i) == team)
			{
				int weaponEntity = MalletCreateWeapon(i, weaponId, weaponName, level, quality, weaponSlot);

				if (weaponEntity <= 0)
				{
					return false;
				}

				if (!ApplyWeaponAttributes(weaponEntity, i, attributes, false))
				{
					return false;
				}

				/* MalletCreateWeapon automagically equips wearables for us, don't try to equip a wearable or we'll crash. */
				if (!MalletIsWearable(weaponEntity))
				{
					MalletSwapWeaponAndPurge(i, weaponEntity, weaponSlot);
				}
			}
		}
	}
	return true;
}


bool GiveWeaponToAll(int weaponId, const char[] weaponName, int level, int quality, int weaponSlot)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			int weaponEntity = MalletCreateWeapon(i, weaponId, weaponName, level, quality, weaponSlot);

			if (weaponEntity <= 0)
			{
				return false;
			}

			/* MalletCreateWeapon automagically equips wearables for us, don't try to equip a wearable or we'll crash. */
			if (!MalletIsWearable(weaponEntity))
			{
				MalletSwapWeaponAndPurge(i, weaponEntity, weaponSlot);
			}
		}
	}
	return true;
}

bool GiveWeaponToTeam(TFTeam team, int weaponId, const char[] weaponName, int level, int quality, int weaponSlot)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			if (TF2_GetClientTeam(i) == team)
			{
				int weaponEntity = MalletCreateWeapon(i, weaponId, weaponName, level, quality, weaponSlot);

				if (weaponEntity <= 0)
				{
					return false;
				}

				/* MalletCreateWeapon automagically equips wearables for us, don't try to equip a wearable or we'll crash. */
				if (!MalletIsWearable(weaponEntity))
				{
					MalletSwapWeaponAndPurge(i, weaponEntity, weaponSlot);
				}
			}
		}
	}
	return true;
}

void SetupAmmoRegen(int amount)
{
	if (AmmoRegenTimer != INVALID_HANDLE)
	{
		ThrowError("[ArenaRandomizer] AmmoRegenTimer already set? wtf");
	}
	else
	{
		AmmoRegenTimer = CreateTimer(5.0, DoAmmoRegen, amount, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action DoAmmoRegen(Handle timer, any data)
{
#if defined(DEBUG)
	PrintToServer("[ArenaRandomizer::DoAmmoRegen] [DEBUG] Giving ammo to players...");
#endif

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			for (int slot = TFWeaponSlot_Primary; slot < TFWeaponSlot_Melee; slot++)
			{
				int entity = GetPlayerWeaponSlot(i, slot);
				if (entity <= 0)
				{
					continue;
				}

				int ammoType = GetEntProp(entity, Prop_Send, "m_iPrimaryAmmoType");

				GivePlayerAmmo(i, view_as<int>(data), ammoType, true);
			}
		}
	}

	return Plugin_Continue;
}

public void RoundStartAlternate(Handle event, const char[] name, bool dontBroadcast)
{
	if (!IsArenaRandomizer)
		return;

	if (WorkaroundMode != WA_ARENA_PERKS && WorkaroundMode != WA_LUMBERYARD_EVENT)
		return;

	if (GameRules_GetProp("m_bInWaitingForPlayers"))
		return;

#if defined(DEBUG)
	PrintToServer("[ArenaRandomizer::RoundStartAlternate] [DEBUG] Redirecting `teamplay_round_active` to ArenaRandomizer...");
#endif
	
	switch (WorkaroundMode)
	{
		case WA_ARENA_PERKS:
		{
			/* We need to delay the call since the map is about to respawn everyone plus run a bonus timer. */
			CreateTimer(9.0, ArenaRoundDelayed);
		}
		case WA_LUMBERYARD_EVENT:
		{
			/* This map respawns players on round start, we need to delay for a second. */
			CreateTimer(1.67, ArenaRoundDelayed);			
		}
		default:
		{
			ArenaRound();
		}
	}
}

public void ArenaRoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	if (!IsArenaRandomizer)
		return;

	if (WorkaroundMode)
		return;

#if defined(DEBUG)
	PrintToServer("[ArenaRandomizer::ArenaRoundStart] [DEBUG] Redirecting `arena_round_start` to ArenaRandomizer...");
#endif
	ArenaRound();
}

public Action ArenaRoundDelayed(Handle timer, int serial)
{
	ArenaRound();
	return Plugin_Stop;
}

void ArenaRound()
{
	int idx = GetLoadoutIdx();
#if defined(DEBUG)
	PrintToServer("[ArenaRandomizer::ArenaRound] [DEBUG] Preparing loadout idx: %d", idx);
#endif
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

	if (JSON_CONTAINS_KEY(classes, ARENA_RANDOMIZER_CLASS_ALL)) {
		char _class[16];
		classes.GetString(ARENA_RANDOMIZER_CLASS_ALL, _class, sizeof(_class));

		if (strcmp(_class, ARENA_RANDOMIZER_CLASS_RANDOM) == 0)
		{
			SetAllPlayersRandomClass();
		}
		else if (strcmp(_class, ARENA_RANDOMIZER_CLASS_RANDOM_SHARED) == 0)
		{
			SetAllPlayersSharedRandomClass();
		}
		else
		{
			TFClassType class = view_as<TFClassType>(MalletConvertClassFromString(_class));
			if (class == TFClass_Unknown)
			{
				SetFailState("ArenaRound: Invalid formatted data object, requested an unknown class for ALL players.");
				return;
			}
			else
			{
				SetAllPlayersClass(class);
			}
		}
	} else if (JSON_CONTAINS_KEY(classes, ARENA_RANDOMIZER_CLASS_RED) && JSON_CONTAINS_KEY(classes, ARENA_RANDOMIZER_CLASS_BLUE))  {
		char _red[16];
		classes.GetString(ARENA_RANDOMIZER_CLASS_RED, _red, sizeof(_red));

		char _blue[16];
		classes.GetString(ARENA_RANDOMIZER_CLASS_BLUE, _blue, sizeof(_blue));

		TFClassType red;
		if (strcmp(_red, ARENA_RANDOMIZER_CLASS_RANDOM_SHARED) == 0)
		{
			red = view_as<TFClassType>(GetRandomInt(1, 9));
		}
		else
		{
			red = view_as<TFClassType>(MalletConvertClassFromString(_red));
		}

		if (red == TFClass_Unknown)
		{
			SetFailState("ArenaRound: Invalid formatted data object, requested an unknown class for RED players.");
			return;
		}

		TFClassType blue;
		if (strcmp(_blue, ARENA_RANDOMIZER_CLASS_RANDOM_SHARED) == 0)
		{
			blue = view_as<TFClassType>(GetRandomInt(1, 9));
		}
		else
		{
			blue = view_as<TFClassType>(MalletConvertClassFromString(_blue));
		}

		if (blue == TFClass_Unknown)
		{
			SetFailState("ArenaRound: Invalid formatted data object, requested an unknown class for BLU players.");
			return;
		}

		SetAllPlayersTeam(red, TFTeam_Red);
		SetAllPlayersTeam(blue, TFTeam_Blue);
	} else if (JSON_CONTAINS_KEY(classes, ARENA_RANDOMIZER_CLASS_KEEP)) {
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

		/**
		 * Iterate in reverse since we'll be equipping these weapons,
		 * and we want the first entries to be equipped on the player
		 * as the round starts.
		 */
		for (int weaponIdx = (weapons.Length - 1); weaponIdx >= 0; weaponIdx--)
		{
			JSON_Object weapon = weapons.GetObject(weaponIdx);

			if (!JSON_CONTAINS_KEY(weapon, "id"))
			{
				SetFailState("ArenaRound: Invalid formatted data object, 'weapons' is misconfigured.");
				return;
			}

			if (JSON_CONTAINS_KEY(weapon, "holiday"))
			{
				char holiday[32];
				if (!weapon.GetString("holiday", holiday, sizeof(holiday)))
				{
					SetFailState("ArenaRound: Invalid formatted data object, 'holiday' is misconfigured.");
					return;
				}

				if (!IsHolidayConditionMet(holiday))
				{
					/**
					 * Skip this weapon if the condition isn't met.
					 */
					continue;
				}
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

			if (weaponId == ARENA_RANDOMIZER_WEAPON_RANDOM)
			{
				weaponId = GetRandomWeapon();
			}
			
			/* TODO: Simplify this since we can safely pass NULL for 'attributes' */
			if (weaponId == ARENA_RANDOMIZER_WEAPON_KEEP)
			{
				/* Special value: Apply to current weapons. */

				if (JSON_CONTAINS_KEY(weapon, "attributes"))
				{
					JSON_Array attributes = view_as<JSON_Array>(weapon.GetObject("attributes"));

					for (int client = 1; client <= MaxClients; client++)
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

							if (!ApplyWeaponAttributes(weaponEntity, client, attributes, print_weapon_attribs))
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
					/* Allow providing "ARENA_RANDOMIZER_WEAPON_KEEP" without attributes. */
					continue;
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

					TFTeam team = view_as<TFTeam>(MalletConvertTeamFromString(_team));

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

					TFTeam team = view_as<TFTeam>(MalletConvertTeamFromString(_team));
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

	if (JSON_CONTAINS_KEY(entry, ARENA_RANDOMIZER_ATTR))
	{
		JSON_Object attributes = entry.GetObject(ARENA_RANDOMIZER_ATTR);

		if (JSON_CONTAINS_KEY(attributes, ARENA_RANDOMIZER_ATTR_MAX_PLAYER_HEALTH))
		{
			int health = attributes.GetInt(ARENA_RANDOMIZER_ATTR_MAX_PLAYER_HEALTH);

			if (health == -1)
			{
				SetFailState("ArenaRound: Invalid formatted data object, 'attributes' had an invalid HP value.");
				return;
			}

			SetMaxHealthForAll(health);
		}

		if (JSON_CONTAINS_KEY(attributes, ARENA_RANDOMIZER_ATTR_PLAYER_HEALTH))
		{
			int health = attributes.GetInt(ARENA_RANDOMIZER_ATTR_PLAYER_HEALTH);

			if (health == -1)
			{
				SetFailState("ArenaRound: Invalid formatted data object, 'attributes' had an invalid HP value.");
				return;
			}

			SetHealthForAll(health);
		}

		if (JSON_CONTAINS_KEY(attributes, ARENA_RANDOMIZER_ATTR_AMMO_REGENERATION))
		{
			int ammo = attributes.GetInt(ARENA_RANDOMIZER_ATTR_AMMO_REGENERATION);

			if (ammo == -1)
			{
				SetFailState("ArenaRound: Invalid formatted data object, 'attributes' had an invalid ammo regeneration value.");
				return;				
			}

			SetupAmmoRegen(ammo);
		}

		if (JSON_CONTAINS_KEY(attributes, ARENA_RANDOMIZER_ATTR_MOVEMENT_SPEED))
		{
			float movementSpeed = attributes.GetFloat(ARENA_RANDOMIZER_ATTR_MOVEMENT_SPEED);

			if (movementSpeed == -1.0)
			{
				SetFailState("ArenaRound: Invalid formatted data object, 'attributes' had an invalid movement speed value.");
				return;							
			}

			SetMovementSpeedForAll(movementSpeed);
		}

		if (JSON_CONTAINS_KEY(attributes, ARENA_RANDOMIZER_ATTR_MODEL_SCALE))
		{
			float modelScale = attributes.GetFloat(ARENA_RANDOMIZER_ATTR_MODEL_SCALE, 0.0);

			if (modelScale <= 0.0)
			{
				SetFailState("ArenaRound: Invalid formatted data object, 'attributes' had an invalid model scale value.");
				return;							
			}

			SetModelScaleForAll(modelScale);
		}

		if (JSON_CONTAINS_KEY(attributes, ARENA_RANDOMIZER_ATTR_ROUND_START))
		{
			JSON_Object roundStart = attributes.GetObject(ARENA_RANDOMIZER_ATTR_ROUND_START);

			char round_start_path[PLATFORM_MAX_PATH];
			if (roundStart != null && roundStart.IsArray)
			{
				JSON_Array roundStartArr = view_as<JSON_Array>(roundStart);

				int roundStartIdx = GetRandomInt(0, roundStartArr.Length - 1);
				if (!roundStartArr.GetString(roundStartIdx, round_start_path, PLATFORM_MAX_PATH))
				{
					PrintToServer("[WARNING] ArenaRound: Failed to read round_start_audio!");
				}
				else
				{
					CustomRoundStartMusic = true;
					EmitSoundToAll(round_start_path);
				}
			}
			else
			{
				if (!attributes.GetString(ARENA_RANDOMIZER_ATTR_ROUND_START, round_start_path, PLATFORM_MAX_PATH))
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

		if (JSON_CONTAINS_KEY(attributes, ARENA_RANDOMIZER_ATTR_ROUND_END))
		{
			JSON_Object roundEnd = attributes.GetObject(ARENA_RANDOMIZER_ATTR_ROUND_END);

			char round_end_path[PLATFORM_MAX_PATH];
			if (roundEnd != null && roundEnd.IsArray)
			{
				JSON_Array roundEndArr = view_as<JSON_Array>(roundEnd);

				int roundEndIdx = GetRandomInt(0, roundEndArr.Length - 1);
				if (!roundEndArr.GetString(roundEndIdx, round_end_path, PLATFORM_MAX_PATH))
				{
					PrintToServer("[WARNING] ArenaRound: Failed to read round_end_audio!");
				}
				else
				{
					EndRoundAudioQueue.PushString(round_end_path);
				}
			}
			else
			{
				if (!attributes.GetString(ARENA_RANDOMIZER_ATTR_ROUND_END, round_end_path, PLATFORM_MAX_PATH))
				{
					PrintToServer("[WARNING] ArenaRound: Failed to read round_end_audio!");
				}
				else
				{
					EndRoundAudioQueue.PushString(round_end_path);
				}
			}
		}

		if (JSON_CONTAINS_KEY(attributes, ARENA_RANDOMIZER_ATTR_ON_KILL))
		{
			JSON_Object onKill = attributes.GetObject(ARENA_RANDOMIZER_ATTR_ON_KILL);

			char on_kill_path[PLATFORM_MAX_PATH];
			if (onKill != null && onKill.IsArray)
			{
				JSON_Array onKillArr = view_as<JSON_Array>(onKill);

				for (int killIdx = 0; killIdx < onKillArr.Length; killIdx++)
				{
					if (!onKillArr.GetString(killIdx, on_kill_path, PLATFORM_MAX_PATH))
					{
						PrintToServer("[WARNING] ArenaRound: Failed to read kill_audio at index %i!", killIdx);
						continue;
					}

					OnKillAudioList.PushString(on_kill_path);
				}
			}
			else
			{
				if (!attributes.GetString(ARENA_RANDOMIZER_ATTR_ON_KILL, on_kill_path, PLATFORM_MAX_PATH))
				{
					PrintToServer("[WARNING] ArenaRound: Failed to read kill_audio!");
				}
				else
				{
					OnKillAudioList.PushString(on_kill_path);
				}
			}			
		}

		if (JSON_CONTAINS_KEY(attributes, ARENA_RANDOMIZER_ATTR_CONDITIONS))
		{
			JSON_Object conditions = attributes.GetObject(ARENA_RANDOMIZER_ATTR_CONDITIONS);

			if (conditions == null || !conditions.IsArray)
			{
				SetFailState("ArenaRound: Invalid formatted data object, 'conditions' is not an array.");
				return;				
			}

			JSON_Array conditionsArray = view_as<JSON_Array>(conditions);

			for (int condIdx = 0; condIdx < conditionsArray.Length; condIdx++)
			{
				JSON_Object conditionEntry = conditionsArray.GetObject(condIdx);

				int condition = conditionEntry.GetInt("id");
				if (condition == -1)
				{
					PrintToServer("[WARNING] ArenaRound: Invalid condition ID or missing!");
					continue;
				}

				float duration = conditionEntry.GetFloat("duration", -2.0);
				if (duration == -2.0)
				{
					PrintToServer("[WARNING] ArenaRound: Invalid condition duration or missing!");
					continue;
				}

				/**
				 * TODO(irql):
				 * Add a team filtering entry...
				 */
				for (int client = 1; client <= MaxClients; client++)
				{
					if (IsClientInGame(client) && IsPlayerAlive(client))
					{
						TF2_AddCondition(client, view_as<TFCond>(condition), duration);
					}
				}
			}
		}
	}

	bool IsSpecialRound = entry.GetBool("special_round");

	if (JSON_CONTAINS_KEY(entry, "special_round_code"))
	{
		/* It's Not My Problem(TM) if the user misconfigured the loadout JSON. */
		SpecialRoundLogic = view_as<ArenaRandomizerSpecialRoundLogic>(entry.GetInt("special_round_code", DISABLED));
	}
	else
	{
		SpecialRoundLogic = DISABLED;
	}

	if (SpecialRoundLogic != CLASS_WARFARE_LIKE)
	{
		ShowTextPrompt(_name, IsSpecialRound ? SPECIAL_ROUND_UI_ICON : DEFAULT_UI_ICON, 14.92);

		if (!CustomRoundStartMusic)
		{
			int music_idx = GetRandomInt(0, ARENA_RANDOMIZER_DEFAULT_AUDIO_ARRAY_LENGTH - 1);

			if (IsSpecialRound)
			{
				EmitSoundToAll(ARENA_RANDOMIZER_ROUND_START_SPECIAL[music_idx]);
			}
			else
			{
				EmitSoundToAll(ARENA_RANDOMIZER_ROUND_START[music_idx]);
			}
		}
	}
	else
	{
		/**
		 * Display a Class Warfare like HUD instead.
		 */

		SetHudTextParams(
			.x = -1.0,
			.y = 0.3,
			.holdTime = 10.0,
			.r = 255,
			.g = 255,
			.b = 255,
			.a = 255,
			.effect = 0,
			.fxTime = 0.0,
			.fadeIn = 0.0,
			.fadeOut = 0.0
		);

		int blueTeam = -1, redTeam = -1;
		char blue[16], red[16];

		/**
		 * We sadly have to iterate over the clients
		 * since I don't want to make the handler
		 * variables accessible to the rest of the function.
		 * 
		 * This sucks.
		 */
		for (int client = 1; client <= MaxClients; client++)
		{
			/* We're done. */
			if (blueTeam != -1 && redTeam != -1)
			{
				break;
			}

			if (!IsClientInGame(client))
			{
				continue;
			}

			if (!IsPlayerAlive(client))
			{
				continue;
			}

			if (blueTeam == -1 && GetClientTeam(client) == view_as<int>(TFTeam_Blue))
			{
				blueTeam = TF2_GetPlayerClass(client);
				continue;
			}

			if (redTeam == -1 && GetClientTeam(client) == view_as<int>(TFTeam_Red))
			{
				redTeam = TF2_GetPlayerClass(client);
				continue;
			}
		}

		GetTF2ClassName(blue, view_as<TFClassType>(blueTeam));
		GetTF2ClassName(red, view_as<TFClassType>(redTeam));

		for (int client = 1; client <= MaxClients; client++)
		{
			if (IsClientInGame(client))
			{
				/**
				 * TODO(irql):
				 * 
				 * Something is broken and it's only display for like
				 * a frame or two in most of the times, wtf Valve?
				 */
				ShowHudText(
					client,
					-3,
					"ROUND %d:\n%s %s versus %s %s",
					GetTotalRoundCount(), "BLU", blue, "RED", red
				);
			}
		}
	}

	/**
	 * Print the round loadout to chat regardless.
	 */
	MC_PrintToChatAll("[{springgreen}ArenaRandomizer{white}] This round's loadout is %s%s{default}", 
		(IsSpecialRound ? "{indianred}" : "{mediumturquoise}"), _name);

	if (SuddenDeathTimer != INVALID_HANDLE)
	{
		ThrowError("[ArenaRandomizer] Sudden death already active? wtf");
	}
	else
	{
		SuddenDeathTimer = CreateTimer(120.0, TriggerSuddenDeath, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public void RoundEndAudio(Handle event, const char[] name, bool dontBroadcast)
{
	if (!IsArenaRandomizer)
		return;

	if (WorkaroundMode)
		return;

	DoRoundEnd();
}

public void RoundEndAlternate(Handle event, const char[] name, bool dontBroadcast)
{
	if (!IsArenaRandomizer)
		return;
	
	if (WorkaroundMode != WA_ARENA_PERKS)
		return;

	if (GameRules_GetProp("m_bInWaitingForPlayers"))
		return;

	if (GameRules_GetProp("m_bInSetup"))
		return;

	int remainingBlue = GetAliveTeamCount(TFTeam_Blue);
	int remainingRed = GetAliveTeamCount(TFTeam_Red);

	/**
	 * FIXME(irql): Technically, this doesn't account for stalemates...
	 */
	bool killBasedWin = (remainingBlue != remainingRed) &&
		(remainingBlue == 0 || remainingRed == 0);

	int team = GetEventInt(event, "team", -1);

#if defined(DEBUG)
	PrintToServer("[ArenaRandomizer::RoundEndAlternate] [DEBUG] team=%d, remainingBlue=%d, remainingRed=%d, killBasedWin=%d",
		team, remainingBlue, remainingRed, killBasedWin);
#endif

	if (team == -1)
	{
		SetFailState("RoundEndAlternate: Failed to read the control point state!");
		return;
	}

	if (!killBasedWin && (team == view_as<int>(TFTeam_Spectator) || team == view_as<int>(TFTeam_Unassigned)))
	{
		return;
	}
	
	DoRoundEnd();
}

public void RoundEndAlternate2(Handle event, const char[] name, bool dontBroadcast)
{
	if (!IsArenaRandomizer)
		return;
	
	if (WorkaroundMode != WA_LUMBERYARD_EVENT)
		return;

	DoRoundEnd();
}

void DoRoundEnd()
{
	/* Stop the sudden death timer. */
	if (SuddenDeathTimer != INVALID_HANDLE)
	{
		delete SuddenDeathTimer;
	}

	/* Stop draining health from players. */
	if (SuddenDeathDrainTimer != INVALID_HANDLE)
	{
		delete SuddenDeathDrainTimer;
	}

	/* Stop giving players ammo if enabled by loadout. */
	if (AmmoRegenTimer != INVALID_HANDLE)
	{
		delete AmmoRegenTimer;
	}

	bool IsMapEnd = HasMapEnded();

	switch (WorkaroundMode)
	{
		/* Reset all attributes now, so anything won't explode next round. */
		case WA_ARENA_PERKS:
		{
			CreateTimer(1.00, ResetAllAttributes, _);

			if (IsMapEnd)
			{
				ThrowError("TODO");
			}
			else
			{
				CreateTimer(5.00, PlayRoundEndClip, _);				
			}
		}
		default:
		{
			CreateTimer(10.00, ResetAllAttributes, _);

			if (IsMapEnd)
			{
				/**
				 * 6.82 is also fine but at least let the
				 * tune go silent.
				 */
				CreateTimer(6.80, PlayGamemodeEndClip, _);
			}
			else
			{
				CreateTimer(14.92, PlayRoundEndClip, _);				
			}
		}
	}

	/* We somehow get "SpecialRoundLogic" desynchronized in rare cases, make sure that DOES NOT happen. */
	SpecialRoundLogic = DISABLED;

	/* Clear the kill audio queue. */
	OnKillAudioList.Clear();
}

public Action TriggerSuddenDeath(Handle timer)
{
	/* We've triggered the timer. Too late now. */
	SuddenDeathTimer = INVALID_HANDLE;

	/**
	 * Sadly we can't integrate Arena's capture point
	 * with Arena Randomizer, so roll out our own thing.
	 */
	CreateTimer(0.1, DoSuddenDeathPreAudio, 5, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(1.1, DoSuddenDeathPreAudio, 4, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(2.1, DoSuddenDeathPreAudio, 3, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(3.1, DoSuddenDeathPreAudio, 2, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(4.1, DoSuddenDeathPreAudio, 1, TIMER_FLAG_NO_MAPCHANGE);

	/* Play the sudden death sound. */
	CreateTimer(5.1, DoSuddenDeathPreAudio, 0, TIMER_FLAG_NO_MAPCHANGE);

	/* Trigger sudden death once the voiceline has been played. */
	CreateTimer(6.23, DoSuddenDeath, TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Stop;
}

public Action DoSuddenDeathPreAudio(Handle timer, any _data)
{
	switch (view_as<int>(_data))
	{
		case 5:
		{
			EmitSoundToAll(TF2_COUNTDOWN_5SECS);
		}

		case 4:
		{
			EmitSoundToAll(TF2_COUNTDOWN_4SECS);
		}

		case 3:
		{
			EmitSoundToAll(TF2_COUNTDOWN_3SECS);
		}

		case 2:
		{
			EmitSoundToAll(TF2_COUNTDOWN_2SECS);
		}

		case 1:
		{
			EmitSoundToAll(TF2_COUNTDOWN_1SECS);
		}

		case 0:
		{
			EmitSoundToAll(SUDDEN_DEATH_AUDIO);
		}
	}

	return Plugin_Stop;
}

public Action DoSuddenDeath(Handle timer)
{
	for (int client = 1; client < MaxClients; client++)
	{
		if (IsClientInGame(client) && IsPlayerAlive(client))
		{
			TF2_AddCondition(client, TFCond_MarkedForDeath, TFCondDuration_Infinite);
		}
	}

	/**
	 * Drain the players health during Sudden Death so
	 * that the round ends quicker.
	 */
	if (SuddenDeathDrainTimer != INVALID_HANDLE)
	{
		ThrowError("[ArenaRandomizer] SuddenDeathDrainTimer is non-NULL?");
	}
	else
	{
		SuddenDeathDrainTimer = CreateTimer(1.0, DoSuddenDeathHealthDrain, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}

	return Plugin_Stop;
}

public Action DoSuddenDeathHealthDrain(Handle timer)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && IsPlayerAlive(client))
		{
			TF2_MakeBleed(client, client, 1.0);
		}
	}

	return Plugin_Continue;
}

public Action ResetAllAttributes(Handle timer)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
		{
			continue;
		}

		for (int slot = 0; slot < 8; slot++)
		{
			int entity = GetPlayerWeaponSlot(client, slot);

			if (entity == -1)
			{
				continue;
			}

			MalletDeleteAllAttributes(entity);
		}

		/**
		 * Also do it on the client.
		 */
		MalletDeleteAllAttributes(client);
	}

	return Plugin_Stop;
}

public Action PlayGamemodeEndClip(Handle timer)
{
	int idx = GetRandomInt(0, ARENA_RANDOMIZER_GAMEMODE_END_ARRAY_LENGTH - 1);
	EmitSoundToAll(ARENA_RANDOMIZER_GAMEMODE_END[idx]);

	return Plugin_Stop;
}

public Action PlayRoundEndClip(Handle timer)
{
	if (!EndRoundAudioQueue.Empty)
	{
		char str[PLATFORM_MAX_PATH];
		EndRoundAudioQueue.PopString(str, PLATFORM_MAX_PATH);
		EmitSoundToAll(str);
	}
	else
	{
		EmitSoundToAll(PRE_ROUND_AUDIO);
	}

	return Plugin_Stop;
}

public Action PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (!IsArenaRandomizer)
	{
		return Plugin_Continue;
	}

	if (SpecialRoundLogic == HUNTSMAN_HELL)
	{
		int victim = GetEventInt(event, "victim_entindex");
		int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
		char weapon[64];
		GetEventString(event, "weapon", weapon, sizeof(weapon));

		if (StrEqual(weapon, HH_KILL_FLAMETHROWER) && attacker != victim)
		{
			SetEventString(event, "weapon", "huntsman");
			SetEventInt(event, "damagebits", (GetEventInt(event, "damagebits") & DMG_CRIT) | DMG_BURN | DMG_PREVENT_PHYSICS_FORCE);
			SetEventInt(event, "customkill", TF_CUSTOM_BURNING_ARROW);
		}

		if (StrEqual(weapon, HH_KILL_EXPLOSION))
		{
			SetEventString(event, "weapon", "tf_pumpkin_bomb");
			SetEventInt(event, "damagebits", (GetEventInt(event, "damagebits") & DMG_CRIT) | DMG_BLAST | DMG_RADIATION | DMG_POISON);
			SetEventInt(event, "customkill", TF_CUSTOM_PUMPKIN_BOMB);
		}
	
		return Plugin_Continue;
	}
	else
	{
		if (OnKillAudioList.Length == 0)
		{
			return Plugin_Continue;
		}

		int idx = GetRandomInt(0, OnKillAudioList.Length - 1);
		char path[PLATFORM_MAX_PATH];

		if (!OnKillAudioList.GetString(idx, path, PLATFORM_MAX_PATH))
		{
			return Plugin_Continue;
		}

		if (SpecialRoundLogic == BLEED_FOR_EIGHT_SECONDS)
		{
			/* Place the funnies at the point of death. */
			float position[3];

			/* Get the position of the victim, since the attacker position isn't always available. */
			int entity = GetClientOfUserId(GetEventInt(event, "userid"));
			if (entity)
			{
				GetEntPropVector(entity, Prop_Send, "m_vecOrigin", position);
			}

			/* SNDLEVEL_RAIDSIREN should cover the majority of the map? */
			EmitSoundToAll(.sample = path, .entity = SOUND_FROM_WORLD, .level = SNDLEVEL_RAIDSIREN, .origin = position);
		}
		else
		{
			EmitSoundToAll(path);
		}
	}
	
	return Plugin_Continue;
}

public Action Event_MapChooser_MapLoaded(Event event, const char[] name, bool dontBroadcast)
{
	char gamemode[64];
	event.GetString("gamemode", gamemode, 64, "UNKNOWN");

	IsArenaRandomizer = strcmp(gamemode, "Arena Randomizer") == 0;
	return Plugin_Continue;
}

public Action OnTakeDamageAlive(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon,
		float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (!IsArenaRandomizer)
	{
		return Plugin_Continue;
	}

	if (SpecialRoundLogic == BLEED_FOR_EIGHT_SECONDS)
	{
		/* TODO(rake): Allow fall damage and trigger_death as well. */

		/* Only allow bleed to be issued. */
		if (damagecustom == DAMAGE_CUSTOM_TYPE_BLEED)
		{
			return Plugin_Continue;
		}

		damage = 0.0;
		TF2_MakeBleed(victim, attacker, 8.0);
	}
	else if (SpecialRoundLogic == HUNTSMAN_HELL)
	{
		char classname[64];
		if (GetEntityClassname(inflictor, classname, sizeof(classname)) && StrEqual(classname, "env_explosion"))
		{
			int attackerTeam = GetClientTeam(attacker);
			int victimTeam = GetClientTeam(victim);

			if (victim != attacker && attackerTeam == victimTeam)
			{
				return Plugin_Continue;
			}

			TF2_IgnitePlayer(victim, attacker);
		}
	}

	return Plugin_Continue;
}

public void TF2_OnConditionAdded(int client, TFCond condition)
{
	if (!IsArenaRandomizer)
	{
		return;
	}

	/* Required for "The Geneva Suggestion". */
	if ((SpecialRoundLogic == GENEVA_SUGGESTION) && condition == TFCond_Gas)
	{
		IgniteEntity(client, 10.0);
	}

	/* Required for "On Hit: Bleed for 8 seconds." */
	if ((SpecialRoundLogic == BLEED_FOR_EIGHT_SECONDS) && ShouldCondCauseBleed(condition))
	{
		TF2_MakeBleed(client, client, 8.0);
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (!IsArenaRandomizer)
	{
		return;
	}

	if (SpecialRoundLogic != HUNTSMAN_HELL)
	{
		return;
	}

	if (!StrEqual(classname, "tf_projectile_arrow"))
	{
		return;
	}

	SDKHook(entity, SDKHook_StartTouchPost, HH_Arrow_Explode);
}

/**
 * Logic taken directly from Huntsman Hell 1.x
 * Created by Powerlord.
 * 
 * https://github.com/powerlord/sourcemod-huntsman-hell
 */
void HH_Arrow_Explode(int entity, int other)
{
	float origin[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);
	
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	int team = GetEntProp(entity, Prop_Send, "m_iTeamNum");
	int flags = GetEntityFlags(owner);
	
	int explosion = CreateEntityByName("env_explosion");
	if (!IsValidEntity(explosion))
	{
		return;
	}
	
	char teamString[2];
	char magnitudeString[6];
	char radiusString[5];
	IntToString(team, teamString, sizeof(teamString));
	
	IntToString(HH_ExplodeDamage, magnitudeString, sizeof (magnitudeString));
	IntToString(HH_ExplodeRadius, radiusString, sizeof (radiusString));
	
	DispatchKeyValue(explosion, "iMagnitude", magnitudeString);
	DispatchKeyValue(explosion, "iRadiusOverride", radiusString);
	DispatchKeyValue(explosion, "TeamNum", teamString);
	
	SetEntPropEnt(explosion, Prop_Data, "m_hOwnerEntity", owner);
	
	TeleportEntity(explosion, origin, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(explosion);
	
	AcceptEntityInput(explosion, "Explode");

	/**
	 * TODO(irql):
	 * We should check if the client is actually close to the arrow.
	 */
	if ((flags & FL_DUCKING))
	{
#define HH_ARROW_JUMP_FORCE 255
		float vecAng[3];
		GetClientEyeAngles(owner, vecAng);

		float vecVel[3];
		vecVel[0] = Cosine(DegToRad(vecAng[0])) * Cosine(DegToRad(vecAng[1])) * HH_ARROW_JUMP_FORCE;
		vecVel[1] = Cosine(DegToRad(vecAng[0])) * Sine(DegToRad(vecAng[1])) * HH_ARROW_JUMP_FORCE;
		vecVel[2] = (((vecAng[0]) * 1.5) + 90.0) * 4.0;

		TeleportEntity(owner, NULL_VECTOR, NULL_VECTOR, vecVel);

		SetEntProp(owner, Prop_Send, "m_bJumping", true);
		SetEntityFlags(owner, flags & ~FL_ONGROUND);
		TF2_AddCondition(owner, TFCond_BlastJumping);
	}
}