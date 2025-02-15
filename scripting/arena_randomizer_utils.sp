/**
 * ArenaRandomizer.
 * 
 * This file purely provides defines and simple functions for the gamemode, to avoid cluttering the main file.
 */

#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>
#include <adt_array>

#include <json>
#include <files>

#include <mallet>

#if !defined(_ARENA_RANDOMIZER_DEFINE)
#define _ARENA_RANDOMIZER_DEFINE 1

/**
 * Keep the current weapon that is equipped.
 */
#define ARENA_RANDOMIZER_WEAPON_KEEP -2
/**
 * Gives a player a random weapon that Mallet is aware of.
 * (should be auto adjusted to appropriate class if necessary)
 */
#define ARENA_RANDOMIZER_WEAPON_RANDOM -1

#define ARENA_RANDOMIZER_RANDOM_ATTRIBUTE -1

#define ARENA_RANDOMIZER_CLASS_ALL "all"
#define ARENA_RANDOMIZER_CLASS_RED "red"
#define ARENA_RANDOMIZER_CLASS_BLUE "blue"
/**
 * Keeps the class that is currently set on the player.
 */
#define ARENA_RANDOMIZER_CLASS_KEEP "keep"
/**
 * Picks a random class for each player.
 */
#define ARENA_RANDOMIZER_CLASS_RANDOM "random"
/**
 * Picks a random class and sets it for ALL players.
 */
#define ARENA_RANDOMIZER_CLASS_RANDOM_SHARED "random-shared"

/* Map detection. */
#define MAP_DETECTION_UNAVAILABLE 0
#define MAP_DETECTION_MAP_CHOOSER_API 1

/* Audio related. */
#define ARENA_RANDOMIZER_ATTR_ROUND_START "round_start_audio"
#define ARENA_RANDOMIZER_ATTR_ROUND_END "round_end_audio"
#define ARENA_RANDOMIZER_ATTR_ON_KILL "kill_audio"

#define ARENA_RANDOMIZER_DEFAULT_AUDIO_ARRAY_LENGTH 3

#define PRE_ROUND_AUDIO "hmmr/arena-randomizer/round_start.mp3"
#define PRE_ROUND_AUDIO_FULL "sound/hmmr/arena-randomizer/round_start.mp3"

/* Misc. */
#define ARENA_RANDOMIZER_ATTR "attributes"
#define ARENA_RANDOMIZER_ATTR_PLAYER_HEALTH "hp"

#define FILE_LOCATION "cfg/hmmr/arena-randomizer/loadouts.json"
#define FILE_MAX_SIZE (1 * 1024 * 1024)

#define DEFAULT_UI_ICON "leaderboard_dominated"
#define SPECIAL_ROUND_UI_ICON "leaderboard_streak"

#define DAMAGE_CUSTOM_TYPE_BLEED 34
#endif

enum ArenaRandomizerSpecialRoundLogic 
{
	DISABLED = 0,
	GENEVA_SUGGESTION = 1,
	BLEED_FOR_EIGHT_SECONDS = 2,
	CLASS_WARFARE_LIKE = 3
};

enum ArenaRandomizerWorkaroundMethod
{
	NO_WORKAROUND = 0,
	/**
	 * Perks requires the following:
	 * - Alternate Event Hooks
	 * - Alternate Audio Timing
	 * - Delayed Loadout application
	 */
	WA_ARENA_PERKS = 1,
	/**
	 * Graveyard requires the following:
	 * - Alternate Event Hooks
	 * - Delayed Loadout application
	 */
	WA_LUMBERYARD_EVENT = 2
};

stock bool ShouldCondCauseBleed(TFCond cond)
{
	/**
	 * Apparently SourcePawn won't let me stack cases in a switch.
	 * Fugly code ahead!
	 */
	switch (cond)
	{
		case TFCond_Gas:
			return true;
		case TFCond_Milked:
			return true;
		case TFCond_Bonked:
			return true;
		case TFCond_MarkedForDeath:
			return true;
		case TFCond_SpeedBuffAlly:
			return true;
		case TFCond_DeadRingered:
			return true;
		case TFCond_Jarated:
			return true;
		case TFCond_Bleeding:
			/* Don't cause a paradox. */
			return false;
		default:
			/* In an ideal society, everything would bleed for 8 seconds. */
			return false;
	}
}

stock int GetRandomWeapon()
{
	/* TODO(rake) */
	return -1;
}

stock int GetRandomAttributeID()
{
	return MalletGetRandomAttribute(true);
}

stock void SetHealthForAll(int health)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			SetEntityHealth(i, health);
		}
	}
}

stock void InternalRegeneratePlayers()
{
	/* We need to loop again otherwise we regenerate too quickly and break players. */
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			TF2_RegeneratePlayer(i);
		}
	}
}

stock void SetAllPlayersRandomClass()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			TFClassType class = view_as<TFClassType>(GetRandomInt(1, 9));

			TF2_SetPlayerClass(.client = i, .classType = class, .persistent = false);
		}
	}

	InternalRegeneratePlayers();
}

stock void SetAllPlayersSharedRandomClass()
{
	TFClassType class = view_as<TFClassType>(GetRandomInt(1, 9));

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			TF2_SetPlayerClass(.client = i, .classType = class, .persistent = false);
		}
	}

	InternalRegeneratePlayers();
}

stock void SetAllPlayersClass(TFClassType class)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			TF2_SetPlayerClass(.client = i, .classType = class, .persistent = false);
		}
	}

	InternalRegeneratePlayers();
}

stock void SetAllPlayersTeam(TFClassType class, TFTeam team)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			if (TF2_GetClientTeam(i) == team)
			{
				TF2_SetPlayerClass(.client = i, .classType = class, .persistent = false);
			}
		}
	}

	InternalRegeneratePlayers();
}

stock int GetAliveTeamCount(int team)
{
	int number = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == team) 
			number++;
	}
	return number;
}