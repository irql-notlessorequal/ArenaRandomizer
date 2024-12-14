/**
 * ArenaRandomizer.
 * 
 * This file purely provides defines and simple functions for the gamemode, to avoid cluttering the main file.
 */

#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>

#include <json>
#include <files>

#include <mallet>

#if !defined(_ARENA_RANDOMIZER_DEFINE)
#define _ARENA_RANDOMIZER_DEFINE 1

/* Map detection. */
#define MAP_DETECTION_UNAVAILABLE 0
#define MAP_DETECTION_MAP_CHOOSER_API 1

/* Audio related. */
#define ARENA_RANDOMIZER_ATTR_ROUND_START "round_start_audio"
#define ARENA_RANDOMIZER_ATTR_ROUND_END "round_end_audio"

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
#endif

enum ArenaRandomizerSpecialRoundLogic 
{
	DISABLED = 0,
	GENEVA_SUGGESTION = 1,
	BLEED_FOR_EIGHT_SECONDS = 2
};

bool ShouldCondCauseBleed(TFCond cond)
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

int GetRandomWeapon()
{
	/* TODO(rake) */
	return -1;
}

int GetRandomAttributeID()
{
	int candidate;
	do
	{
		/* There are more attributes but I can't be bothered to take a gap into account. */
		candidate = GetRandomInt(1, 881);

		/* These will crash players, re-roll instead. */
		if (candidate >= 554 && candidate <= 609)
		{
			continue;
		}

		break;
	} while (true);

	return candidate;
}

void SetHealthForAll(int health)
{
	for (int i = 1; i < MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			SetEntityHealth(i, health);
		}
	}
}

void SetAllPlayersClass(TFClassType class)
{
	for (int i = 1; i < MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			TF2_SetPlayerClass(i, class);
		}
	}
}

void SetAllPlayersTeam(TFClassType class, TFTeam team)
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