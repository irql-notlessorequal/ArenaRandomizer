/**
 * Arena Randomizer, a remake of TF2TightRope's Project Ghost
 * Copyright (C) 2025  IRQL_NOT_LESS_OR_EQUAL
 * 
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, see
 * <https://www.gnu.org/licenses/>
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

#if defined(STEAMWORKS)
#include <SteamWorks>
#endif

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
#define ARENA_RANDOMIZER_GAMEMODE_END_ARRAY_LENGTH 4

#define PRE_ROUND_AUDIO "hmmr/arena-randomizer/round_start.mp3"
#define PRE_ROUND_AUDIO_FULL "sound/hmmr/arena-randomizer/round_start.mp3"

#define SUDDEN_DEATH_AUDIO "hmmr/arena-randomizer/sudden_death.mp3"
#define SUDDEN_DEATH_AUDIO_FULL "sound/hmmr/arena-randomizer/sudden_death.mp3"

#define TF2_COUNTDOWN_5SECS "vo/announcer_ends_5sec.mp3"
#define TF2_COUNTDOWN_4SECS "vo/announcer_ends_4sec.mp3"
#define TF2_COUNTDOWN_3SECS "vo/announcer_ends_3sec.mp3"
#define TF2_COUNTDOWN_2SECS "vo/announcer_ends_2sec.mp3"
#define TF2_COUNTDOWN_1SECS "vo/announcer_ends_1sec.mp3"

/* Misc. */
#define ARENA_RANDOMIZER_ATTR "attributes"
#define ARENA_RANDOMIZER_ATTR_PLAYER_HEALTH "hp"
#define ARENA_RANDOMIZER_ATTR_MAX_PLAYER_HEALTH "max_hp"
#define ARENA_RANDOMIZER_ATTR_AMMO_REGENERATION "ammo_regen"
#define ARENA_RANDOMIZER_ATTR_CONDITIONS "conditions"
#define ARENA_RANDOMIZER_ATTR_MOVEMENT_SPEED "movement_speed"
#define ARENA_RANDOMIZER_ATTR_MODEL_SCALE "model_scale"

#define FILE_LOCATION "cfg/hmmr/arena-randomizer/loadouts.json"
#define FILE_MAX_SIZE (1 * 1024 * 1024)

#define DEFAULT_UI_ICON "leaderboard_dominated"
#define SPECIAL_ROUND_UI_ICON "leaderboard_streak"

#define HH_KILL_FLAMETHROWER "flamethrower"
#define HH_KILL_EXPLOSION "env_explosion"

#define DAMAGE_CUSTOM_TYPE_BLEED 34

#define TF2_ATTRIBUTE_MOVEMENT_SPEED_BOOST 107
#define TF2_ATTRIBUTE_POSITIVE_MAX_HEALTH 26
#define TF2_ATTRIBUTE_NEGATIVE_MAX_HEALTH 125
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
				/**
				 * The attribute reduces the health by X, a negative value will break
				 * it so we need to convert it back to a positive value.
				 */
				MalletSetAttribute(i, TF2_ATTRIBUTE_NEGATIVE_MAX_HEALTH, float(-health));
			}
		}
	}
}

stock void SetMovementSpeedForAll(float value)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && IsPlayerAlive(client))
		{
			MalletSetAttribute(client, TF2_ATTRIBUTE_MOVEMENT_SPEED_BOOST, value);
		}
	}
}

stock void SetModelScaleForAll(float scale)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && IsPlayerAlive(client))
		{
			SetEntPropFloat(client, Prop_Send, "m_flModelScale", scale);
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

stock void SetWeaponAmmo(int client, int slot1, int slot2)
{
    int ActiveWeapon = GetEntDataEnt2(client, FindSendPropInfo("CTFPlayer", "m_hActiveWeapon"));

    if (IsValidEntity(ActiveWeapon))
	{
		if (slot1 != -2)
		{
			SetEntData(ActiveWeapon, FindSendPropInfo("CBaseCombatWeapon", "m_iClip1"), slot1, 4);
		}

        if (slot2 != -2)
		{
			SetEntData(client, FindSendPropInfo("CTFPlayer", "m_iAmmo") + 4, slot2, 4);
        	SetEntData(client, FindSendPropInfo("CTFPlayer", "m_iAmmo") + 8, slot2, 4);
		}
    }
}

stock void SetWeaponAmmoAll(int slot1, int slot2)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			SetWeaponAmmo(i, slot1, slot2);
		}
	}
}

stock void RemoveAllWeapons(int clientIdx)
{
    for (int weaponSlot = 0; weaponSlot <= 5; weaponSlot++)
	{
		TF2_RemoveWeaponSlot(clientIdx, weaponSlot);
	}
}

stock void RemoveAllWeaponsAll()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			RemoveAllWeapons(i);
		}
	}
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
	else if (strcmp(trueHoliday, "none") == 0)
	{
		return kHoliday_None;
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

stock int GetTotalRoundCount()
{
	/**
	 * This is really inaccurate but funny.
	 */

	int blue = GetTeamScore(view_as<int>(TFTeam_Blue));
	int red = GetTeamScore(view_as<int>(TFTeam_Red));

	return (blue + red + 1);
}

stock void GetTF2ClassName(char output[16], TFClassType classType)
{
	switch (classType)
	{
		case TFClass_Scout:
		{
			strcopy(output, sizeof (output), "Scout");
		}

		case TFClass_Soldier:
		{
			strcopy(output, sizeof (output), "Soldier");
		}

		case TFClass_Pyro:
		{
			strcopy(output, sizeof (output), "Pyro");
		}

		case TFClass_DemoMan:
		{
			strcopy(output, sizeof (output), "Demoman");
		}

		case TFClass_Heavy:
		{
			strcopy(output, sizeof (output), "Heavy");
		}

		case TFClass_Engineer:
		{
			strcopy(output, sizeof (output), "Engineer");
		}

		case TFClass_Medic:
		{
			strcopy(output, sizeof (output), "Medic");
		}

		case TFClass_Sniper:
		{
			strcopy(output, sizeof (output), "Sniper");
		}
		
		case TFClass_Spy:
		{
			strcopy(output, sizeof (output), "Spy");
		}
	}
}