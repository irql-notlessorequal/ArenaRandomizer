#include <json>

#include "hmmr_attribute_adapter.sp"
#include "hmmr_weapon_adapter.sp"
#include "hmmr_attribute_db.sp"

#define FLOAT_MIN_VALUE -4294967295

public bool GiveWeaponToAllWithAttributes(int weaponId, const char[] weaponName, int level, int quality, int weaponSlot, JSON_Array attributes)
{
	for (int i = 1; i < MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			if (!GiveWeaponWithAttributes(i, weaponId, weaponName, level, quality, weaponSlot, attributes))
			{
				return false;
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
				if (!GiveWeaponWithAttributes(i, weaponId, weaponName, level, quality, weaponSlot, attributes))
				{
					return false;
				}
			}
		}
	}
	return true;
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

float __CONVERT_TO_COMPATIBLE_TYPE(const JSON_Object attribute, const char[] name, const JSONCellType ct)
{
	switch (ct) {
		case JSON_Type_Int: {
			return attribute.GetInt(name);
		}
		case JSON_Type_Float: {
			return attribute.GetFloat(name, FLOAT_MIN_VALUE);
		}
		case JSON_Type_Bool: {
			return view_as<int>(attribute.GetBool(name));
		}
		default: {
			PrintToServer("[hmmr/weapon_attribute_adapter] __CONVERT_TO_COMPATIBLE_TYPE: Unknown type: %i", ct);
			return FLOAT_MIN_VALUE;
		}
	}
}

public bool SetWeaponAttributes(int weapon, int client, JSON_Array attributes, bool deleteAttribs, bool printAttribs)
{
	if (attributes == null)
	{
		return false;
	}

	if (deleteAttribs)
	{
		if (DeleteAllAttributes(weapon) == -1)
		{
			PrintToServer("[hmmr/weapon_attribute_adapter] GiveWeaponWithAttributes: DeleteAllAttributes() returned -1.");
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
			PrintToServer("[hmmr/weapon_attribute_adapter] GiveWeaponWithAttributes: 'attribute::id' was misconfigured.");
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
			value = __CONVERT_TO_COMPATIBLE_TYPE(attribute, "value", ct);
		}

		if (value == FLOAT_MIN_VALUE)
		{
			PrintToServer("[hmmr/weapon_attribute_adapter] GiveWeaponWithAttributes: 'attribute::value' was misconfigured.");
			return false;
		}

		/* Ignore errors when we're using random attributes since our process is literal trial and error. */
		if (!SetAttribute(weapon, id, value) && !is_random)
		{
			PrintToServer("[hmmr/weapon_attribute_adapter] GiveWeaponWithAttributes: SetAttribute() returned FALSE.");
			return false;
		}

		if (printAttribs)
		{
			char attrStr[64];
			if (!GetAttributeValue(id, attrStr, sizeof attrStr))
			{
				PrintToConsole(client, "[unknown attribute]: %f", attrStr, value);
			}
			else
			{
				PrintToConsole(client, "%s: %f", attrStr, value);
			}
		}
	}

	return true;
}

public bool GiveWeaponWithAttributes(int clientIdx, int weaponId, const char[] weaponName, int level, int quality, int weaponSlot, JSON_Array attributes)
{
	/* (2024-06-27): TF2Attributes and TF2EconData is borked and not updated to 64-bit leaving me with the ugly way as the only option. */
	if (StrEqual(weaponName, "tf_wearable_demoshield", false))
	{
		return GiveWearable(clientIdx, weaponId, weaponName);
	}

	if (StrEqual(weaponName, "saxxy", false))
	{
		/* "saxxy" doesn't exist, convert to an actual weapon. */
		TFClassType classType = TF2_GetPlayerClass(clientIdx);
		
		char newWeaponName[24];
		GetCompatibleSaxxyWeapon(classType, newWeaponName);

		return GiveWeaponWithAttributes(clientIdx, weaponId, newWeaponName, level, quality, weaponSlot, attributes);
	}

	int weapon = CreateEntityByName(weaponName);
	if (!IsValidEntity(weapon))
	{
		PrintToServer("[hmmr/weapon_attribute_adapter] GiveWeaponWithAttributes: IsValidEntity() returned FALSE.");
		return false;
	}

	char entclass[64];

	if (!GetEntityNetClass(weapon, entclass, sizeof(entclass)))
	{
		PrintToServer("[hmmr/weapon_attribute_adapter] GiveWeaponWithAttributes: GetEntityNetClass() returned FALSE.");
		return false;
	}

	SetEntData(weapon, FindSendPropInfo(entclass, "m_iItemDefinitionIndex"), weaponId);
	SetEntData(weapon, FindSendPropInfo(entclass, "m_bInitialized"), 1);
	SetEntProp(weapon, Prop_Send, "m_iItemIDLow", -1);
    SetEntProp(weapon, Prop_Send, "m_iItemIDHigh", -1);
	SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityLevel"), level);
	SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityQuality"), quality);
	SetEntProp(weapon, Prop_Send, "m_bValidatedAttachedEntity", 1);
	SetEntProp(weapon, Prop_Send, "m_iAccountID", GetSteamAccountID(clientIdx));
	SetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity", clientIdx);

	if (StrEqual(weaponName, "tf_weapon_builder", false) || StrEqual(weaponName, "tf_weapon_sapper", false))
	{
		SetEntProp(weapon, Prop_Send, "m_iObjectType", 3);

		if (weaponSlot == TFWeaponSlot_Secondary)
		{
			SetEntProp(weapon, Prop_Data, "m_iSubType", 3);
			SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 0);
			SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 1);
			SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 2);
			SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 3);
		}
		else
		{
			SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 0);
			SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 1);
			SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 2);
			SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 3);
		}
	}
	
	if (!DispatchSpawn(weapon))
	{
		PrintToServer("[hmmr/weapon_attribute_adapter] GiveWeaponWithAttributes: DispatchSpawn() returned FALSE.");
		return false;
	}
	else
	{
		if (attributes != null)
		{
			if (!SetWeaponAttributes(weapon, clientIdx, attributes, false, false))
			{
				PrintToServer("[hmmr/weapon_attribute_adapter] GiveWeaponWithAttributes: SetWeaponAttributes() returned FALSE.");
				return false;
			}
		}

		EquipPlayerWeapon(clientIdx, weapon);
		return true;
	}
}