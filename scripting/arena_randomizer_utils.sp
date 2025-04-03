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
#include <morecolors>

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

#define SUDDEN_DEATH_AUDIO "hmmr/arena-randomizer/sudden_death.mp3"
#define SUDDEN_DEATH_AUDIO_FULL "sound/hmmr/arena-randomizer/sudden_death.mp3"

#define GAMEMODE_END_AUDIO "hmmr/arena-randomizer/gamemode_end_rare.mp3"
#define GAMEMODE_END_AUDIO_FULL "sound/hmmr/arena-randomizer/gamemode_end_rare.mp3"

#define TF2_COUNTDOWN_5SECS "vo/announcer_ends_5sec.mp3"
#define TF2_COUNTDOWN_4SECS "vo/announcer_ends_4sec.mp3"
#define TF2_COUNTDOWN_3SECS "vo/announcer_ends_3sec.mp3"
#define TF2_COUNTDOWN_2SECS "vo/announcer_ends_2sec.mp3"
#define TF2_COUNTDOWN_1SECS "vo/announcer_ends_1sec.mp3"

/* Misc. */
#define ARENA_RANDOMIZER_ATTR "attributes"
#define ARENA_RANDOMIZER_ATTR_PLAYER_HEALTH "hp"
#define ARENA_RANDOMIZER_ATTR_MAX_PLAYER_HEALTH "max_hp"

#define FILE_LOCATION "cfg/hmmr/arena-randomizer/loadouts.json"
#define FILE_MAX_SIZE (1 * 1024 * 1024)

#define DEFAULT_UI_ICON "leaderboard_dominated"
#define SPECIAL_ROUND_UI_ICON "leaderboard_streak"

#define HH_KILL_FLAMETHROWER "flamethrower"
#define HH_KILL_EXPLOSION "env_explosion"

#define DAMAGE_CUSTOM_TYPE_BLEED 34
#endif

enum ArenaRandomizerSpecialRoundLogic 
{
	DISABLED = 0,
	GENEVA_SUGGESTION = 1,
	BLEED_FOR_EIGHT_SECONDS = 2,
	CLASS_WARFARE_LIKE = 3,
	HUNTSMAN_HELL = 4,
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

#define TF2_ATTRIBUTE_POSITIVE_MAX_HEALTH 26
#define TF2_ATTRIBUTE_NEGATIVE_MAX_HEALTH 125

stock void SetMaxHealthForAll(int health)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			if (health)
			{
				MalletSetAttribute(i, TF2_ATTRIBUTE_POSITIVE_MAX_HEALTH, float(health));
			}
			else
			{
				MalletSetAttribute(i, TF2_ATTRIBUTE_NEGATIVE_MAX_HEALTH, float(health));
			}
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

stock bool HasMapEnded()
{
	int timeLeft = -1;
	
	/**
	 * We first need to fetch the map time limit, otherwise
	 * everything will go horribly wrong.
	 */
	if (!GetMapTimeLimit(timeLeft))
	{
		return false;
	}

#if defined(DEBUG)
	PrintToServer("[ArenaRandomizer::HasMapEnded] [DEBUG] { mapLimit=%d }", timeLeft);
#endif

	/**
	 * If we don't have a map time limit, we're either:
	 * - Without one.
	 * - Have the server in hibernation.
	 */
	if (timeLeft <= 0)
	{
		return false;
	}

	/**
	 * Now finally get the remaining map time.
	 */
	if (!GetMapTimeLeft(timeLeft))
	{
		return false;
	}

#if defined(DEBUG)
	PrintToServer("[ArenaRandomizer::HasMapEnded] [DEBUG] { timeLeft=%d }", timeLeft);
#endif
	return timeLeft < 15;	
}

stock void String_Trim(const char[] str, char[] output, size, const char[] chars=" \t\r\n")
{
	int x = 0;
	while (str[x] != '\0' && FindCharInString(chars, str[x]) != -1)
	{
		x++;
	}

	x = strcopy(output, size, str[x]);
	x--;

	while (x >= 0 && FindCharInString(chars, output[x]) != -1)
	{
		x--;
	}

	output[++x] = '\0';
}

stock int HolidayFromString(const char trueHoliday[32])
{
	if (strcmp(trueHoliday, "christmas") == 0)
	{
		return kHoliday_Christmas;
	}
	else if (strcmp(trueHoliday, "halloween") == 0)
	{
		return kHoliday_Halloween;
	}
	else if (strcmp(trueHoliday, "full_moon") == 0)
	{
		return kHoliday_FullMoon;
	}
	else if (strcmp(trueHoliday, "april_fools") == 0)
	{
		return kHoliday_AprilFools;
	}
	else
	{
		ThrowError("Unknown holiday encountered");
		return -1;
	}
}

stock bool IsHolidayConditionMet(const char holiday[32])
{
	bool isNegated = (holiday[0] == '!');

	char trueHoliday[32];
	if (isNegated)
	{
		String_Trim(holiday, trueHoliday, sizeof (holiday), "!");
	}
	else
	{
		trueHoliday = holiday;
	}

	bool value = view_as<bool>(MalletIsHolidayActive(HolidayFromString(trueHoliday)));
	if (isNegated)
	{
		return !value;
	}
	else
	{
		return value;
	}
}