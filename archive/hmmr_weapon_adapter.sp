new g_PlayerVisibleWeapon[MAXPLAYERS + 1] = -1;
Handle hSDKEquipWearable = INVALID_HANDLE;

public void hmmr_weapon_adapter_init() {
	PrintToServer("[hmmr/weapon_adapter] Loading WEAPON_ADAPTER.");

	GameData gamedata = new GameData("sm-tf2.games");
	if (gamedata == INVALID_HANDLE)
	{
		SetFailState("[hmmr/weapon_adapter] Failed to find the game data handle!")
		return;
	}

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetVirtual(gamedata.GetOffset("RemoveWearable") - 1);
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);

	hSDKEquipWearable = EndPrepSDKCall();
	delete gamedata;

	if (hSDKEquipWearable == INVALID_HANDLE)
	{
		SetFailState("[hmmr/weapon_adapter] Failed to hook into CTFPlayer::EquipWearable!")
		return;
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

stock bool IsValidClient(iClient) {
    if (iClient <= 0) return false;
    if (iClient > MaxClients) return false;
    if (!IsClientConnected(iClient)) return false;
    return IsClientInGame(iClient);
}

SetClientSlot(client, slot)
{
	if (!IsValidClient(client) || !IsPlayerAlive(client))
	{
		return;
	}
	new weapon = GetPlayerWeaponSlot(client, slot);
	SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
}

public void SetWeaponAmmoAll(slot1, slot2) {
	for (int i = 1; i < MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			SetWeaponAmmo(i, slot1, slot2);
		}
	}
}

public void SetWeaponAmmo(client, slot1, slot2) {
    new ActiveWeapon = GetEntDataEnt2(client, FindSendPropOffs("CTFPlayer", "m_hActiveWeapon"));
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

Action SetWeaponState(client, bool input) {
    new ActiveWeapon = GetEntDataEnt2(client, FindSendPropOffs("CTFPlayer", "m_hActiveWeapon"));
    new iEntity = g_PlayerVisibleWeapon[client];
    if (IsValidEntity(ActiveWeapon)) {
        if (input == true) {
            SetEntityRenderColor(ActiveWeapon, 255, 255, 255, 255);
            SetEntityRenderMode(ActiveWeapon, RENDER_NORMAL);
            SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
        }
        else {
            SetEntityRenderColor(ActiveWeapon, 255, 255, 255, 0);
            SetEntityRenderMode(ActiveWeapon, RENDER_TRANSCOLOR);
            SetWeaponAmmo(client, 0, 0);
            SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0);
        }
    }

    if (iEntity > 0 && IsValidEntity(iEntity)) {
        if (input == true) {
            SetEntityRenderColor(iEntity, 255, 255, 255, 255);
            SetEntityRenderMode(iEntity, RENDER_NORMAL);
        }
        else {
            SetEntityRenderColor(iEntity, 255, 255, 255, 0);
            SetEntityRenderMode(iEntity, RENDER_TRANSCOLOR);
        }
    }
}

public void RemoveAllWeapons(int clientIdx)
{
    if (IsValidClient(clientIdx) && IsPlayerAlive(clientIdx)) {
        SetClientSlot(clientIdx, 0);
        for (new j = 0; j <= 5; j++) {
            TF2_RemoveWeaponSlot(clientIdx, j);
        }
        SetWeaponState(clientIdx, false);
    }
}

public bool GiveWeaponToAll(int weaponId, const char[] weaponName, int level, int quality, int weaponSlot)
{
	for (int i = 1; i < MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			if (!GiveWeapon(i, weaponId, weaponName, level, quality, weaponSlot))
			{
				return false;
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
				if (!GiveWeapon(i, weaponId, weaponName, level, quality, weaponSlot))
				{
					return false;
				}
			}
		}
	}
	return true;
}

bool GiveWearable(int clientIdx, int weaponId, const char[] weaponName)
{
	TF2_RemoveWeaponSlot(clientIdx, 1);

	int ent = CreateEntityByName(weaponName);
	if (ent == -1)
	{
		return false;
	}

	SetEntProp(ent, Prop_Send, "m_nModelIndexOverrides", PrecacheModel("models/weapons/c_models/c_persian_shield/c_persian_shield_all.mdl"));
	SetEntProp(ent, Prop_Send, "m_iItemDefinitionIndex", weaponId);
	
	if (!DispatchSpawn(ent))
	{
		return false;
	}

	SDKCall(hSDKEquipWearable, clientIdx, ent);
	return true;
}

public bool GetCompatibleSaxxyWeapon(const TFClassType type, char weaponName[24])
{
	if (type == TFClass_Scout)
	{
		strcopy(weaponName, sizeof weaponName, "tf_weapon_bat");
		return true;
	}
	else if (type == TFClass_Sniper)
	{
		strcopy(weaponName, sizeof weaponName, "tf_weapon_club");
		return true;
	}
	else if (type == TFClass_Soldier)
	{
		strcopy(weaponName, sizeof weaponName, "tf_weapon_shovel");
		return true;
	}
	else if (type == TFClass_DemoMan)
	{
		strcopy(weaponName, sizeof weaponName, "tf_weapon_bottle");
		return true;
	}
	else if (type == TFClass_Engineer)
	{
		strcopy(weaponName, sizeof weaponName, "tf_weapon_wrench");
		return true;
	}
	else if (type == TFClass_Pyro)
	{
		strcopy(weaponName, sizeof weaponName, "tf_weapon_fireaxe");
		return true;
	}
	else if (type == TFClass_Heavy)
	{
		/* I'm not sure that this is correct... */
		strcopy(weaponName, sizeof weaponName, "tf_weapon_fireaxe");
		return true;
	}
	else if (type == TFClass_Spy)
	{
		strcopy(weaponName, sizeof weaponName, "tf_weapon_knife");
		return true;
	}
	else if (type == TFClass_Medic)
	{
		strcopy(weaponName, sizeof weaponName, "tf_weapon_bonesaw");
		return true;
	}
	else
	{
		return false;
	}
}

public bool GiveWeapon(int clientIdx, int weaponId, const char[] weaponName, int level, int quality, int weaponSlot)
{
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

		return GiveWeapon(clientIdx, weaponId, newWeaponName, level, quality, weaponSlot);
	}

	int weapon = CreateEntityByName(weaponName);
	if (!IsValidEntity(weapon))
	{
		PrintToServer("[hmmr/weapon_adapter] GiveWeapon: IsValidEntity() returned FALSE.");
		return false;
	}

	char entclass[64];

	if (!GetEntityNetClass(weapon, entclass, sizeof(entclass)))
	{
		PrintToServer("[hmmr/weapon_adapter] GiveWeapon: GetEntityNetClass() returned FALSE.");
		return false;
	}

	SetEntData(weapon, FindSendPropInfo(entclass, "m_iItemDefinitionIndex"), weaponId);
	SetEntData(weapon, FindSendPropInfo(entclass, "m_bInitialized"), 1);
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
		PrintToServer("[hmmr/weapon_adapter] GiveWeapon: DispatchSpawn() returned FALSE.");
		return false;
	}
	else
	{
		EquipPlayerWeapon(clientIdx, weapon);
		return true;
	}
}