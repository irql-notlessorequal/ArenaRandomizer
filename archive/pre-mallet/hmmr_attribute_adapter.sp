/**
 * Based upon FlamingSarge's "tf2attributes".
 * (https://github.com/FlaminSarge/tf2attributes/)
 * 
 * Very special thanks to "Malifox" on the AlliedModders Discord for help and a copy of a work-in-progress tf2attributes for x64.
 */

#include <sdktools>

#define _X64 1

Handle hSDKSetRuntimeValue = INVALID_HANDLE;
Handle hSDKGetAttributeDef = INVALID_HANDLE;
Handle hSDKGetAttributeDefByName = INVALID_HANDLE;
Handle hSDKGetAttributeList = INVALID_HANDLE;
Handle hSDKDestroyAllAttributes = INVALID_HANDLE;
Handle hSDKSchema = INVALID_HANDLE;

#if defined _X64
#include <port64>
#warning "Using Bottiger's sdktools64 branch, if you are not using it, things are about to explode!"

//CUtlVector offsets
enum m_Attributes_m_Memory // CUtlVector<CEconItemAttribute>
{
	Attributes_m_Memory_AttrIndex =	8,	//0x08
	Attributes_m_Memory_sizeof =	24,	//0x18
}

enum static_attrib_t64
{
	StaticAttrib_m_iAttributeDefinitionIndex =	0,	//0x00
	StaticAttrib_m_flValue =					4,	//0x04
	StaticAttrib_sizeof =						16,	//0x10
}

// CAttributeList offsets
enum CAttributeList64
{
	AL_CUtlVector_m_Attributes_m_Memory = 	8,	//0x08, CAttributeList.m_Attributes.m_Memory.m_pMemory
	AL_CUtlVector_m_Size =					24,	//0x18, 4 bytes padding after this
	AL_CUtlVector_pAttrElement =			32,	//0x20
	AL_m_pAttributeManager =				40,	//0x28
}

// CEconItemAttributeDefinition offsets
enum CEconItemAttributeDefinition64
{
	AttrDef_m_nDefIndex =			8,	//0x08
	AttrDef_m_pAttrType =			16,	//0x10
	AttrDef_m_bStoredAsInteger =	26,	//0x1A
}

/**
 * Sets this to entity address + the m_AttributeList offset.  This does not correspond to the CUtlVector instance
 * (which is offset by 0x08).
 */
void GetEntityAttributeList(any list[2], int entity)
{
#if defined _DISABLE
	int offsAttributeList = GetEntSendPropOffs(entity, "m_AttributeList", true);

	if (offsAttributeList <= 0) 
	{
		PrintToServer("[hmmr/attribute_adapter] GetEntityAttributeList: offsAttributeList was invalid for entity %i...", entity);
		return;
	}
	else
	{
		PrintToServer("[hmmr/attribute_adapter] GetEntityAttributeList: entity=%i, offsAttributeList=%i", entity, offsAttributeList);
		Port64_GetEntityAddress(entity, list, offsAttributeList);
	}
#else
	int address[2];

	/* Get our entity address. */
	Port64_GetEntityAddress(entity, address, 0);

	/* Call CEconEntity::GetAttributeList() and store the offset. */
	SDKCall(hSDKGetAttributeList, address, list);
#endif
}

void GetByID(any econ[2], int id)
{
	int pSchema[2];
	GetItemSchema(pSchema);

	if (!pSchema[0])
		return;

	SDKCall(hSDKGetAttributeDef, pSchema, econ, id);
}
#endif

public void hmmr_attribute_adapter_init() {
	PrintToServer("[hmmr/attribute_adapter] Loading ATTRIBUTE_ADAPTER.");
	Handle hGameConf = LoadGameConfigFile("tf2.hmmr_attributes");
	if (hGameConf == INVALID_HANDLE) {
		SetFailState("[hmmr/weapon_adapter] Failed to find the gamedata config handle!");
		return;
	}

	
#if defined _X64
	StartPrepSDKCall(SDKCall_Static);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "GEconItemSchema");
	PrepSDKCall_SetReturnInfo(SDKType_Pointer, SDKPass_Plain);	// Returns address of CEconItemSchema
	hSDKSchema = EndPrepSDKCall();
#else
    StartPrepSDKCall(SDKCall_Static);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "GEconItemSchema");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	hSDKSchema = EndPrepSDKCall();
#endif	
	if (hSDKSchema == INVALID_HANDLE)
	{
		SetFailState("[hmmr/attribute_adapter] Failed to hook into GEconItemSchema!")
		return;
	}

    /* This one is immune. */
    StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "CAttributeList::SetRuntimeAttributeValue");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	hSDKSetRuntimeValue = EndPrepSDKCall();
	
	if (hSDKSetRuntimeValue == INVALID_HANDLE)
	{
		SetFailState("[hmmr/attribute_adapter] Failed to hook into CAttributeList::SetRuntimeAttributeValue!")
		return;
	}

	
#if defined _X64
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "CEconItemSchema::GetAttributeDefinition");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_Pointer, SDKPass_Plain);	// Returns address of a CEconItemAttributeDefinition
	hSDKGetAttributeDef = EndPrepSDKCall();
#else
    StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "CEconItemSchema::GetAttributeDefinition");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	hSDKGetAttributeDef = EndPrepSDKCall();
#endif
	
	if (hSDKGetAttributeDef == INVALID_HANDLE)
	{
		SetFailState("[hmmr/attribute_adapter] Failed to hook into CEconItemSchema::GetAttributeDefinition!")
		return;
	}

	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "CEconItemSchema::GetAttributeDefinitionByName");
#if defined _X64
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_Pointer, SDKPass_Plain);	//Returns address of a CEconItemAttributeDefinition
#else
#error "TODO
#endif
	hSDKGetAttributeDefByName = EndPrepSDKCall();

	if (hSDKGetAttributeDefByName == INVALID_HANDLE)
	{
		SetFailState("Could not initialize call to CEconItemSchema::GetAttributeDefinitionByName");
		return;
	}
	
#if defined _X64
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "CEconEntity::GetAttributeList");
	PrepSDKCall_SetReturnInfo(SDKType_Pointer, SDKPass_Plain);
	hSDKGetAttributeList = EndPrepSDKCall();
#else
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "CEconEntity::GetAttributeList");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	hSDKGetAttributeList = EndPrepSDKCall();
#endif

	if (hSDKGetAttributeList == INVALID_HANDLE)
	{
		SetFailState("[hmmr/attribute_adapter] Failed to hook into CEconEntity::GetAttributeList!")
		return;
	}

	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "CAttributeList::DestroyAllAttributes");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	hSDKDestroyAllAttributes = EndPrepSDKCall();

	if (hSDKDestroyAllAttributes == INVALID_HANDLE)
	{
		SetFailState("[hmmr/attribute_adapter] Failed to hook into CAttributeList::DestroyAllAttributes!")
		return;
	}

	delete hGameConf;
}

public int DeleteAllAttributes(int iEntity)
{
	if (!IsValidEntity(iEntity))
	{
		return -1;
	}

#if defined _X64
	int pEntAttributeList[2];

	GetEntityAttributeList(pEntAttributeList, iEntity);

	PrintToServer("[hmmr/attribute_adapter] [DEBUG] DeleteAllAttributes()->SDKCall (iEntity=%i, pEntAttributeList=[%i, %i])", 
		iEntity, pEntAttributeList[0], pEntAttributeList[1]);
	SDKCall(hSDKDestroyAllAttributes, pEntAttributeList);
#else
	Address pEntAttributeList = GetEntityAttributeList(iEntity);
	if (pEntAttributeList == Address_Null) {
		PrintToServer("[hmmr/attribute_adapter] DeleteAllAttributes(): GetEntityAttributeList returned NULL.");
		return -1;
	}

	PrintToServer("[hmmr/attribute_adapter] [DEBUG] DeleteAllAttributes()->SDKCall (iEntity=%i, pEntAttributeList=%i)", iEntity, pEntAttributeList);
	SDKCall(hSDKDestroyAllAttributes, pEntAttributeList);
#endif
	return 1;
}

public bool SetAttribute(int iEntity, int iDefIndex, float flValue)
{
	if (!IsValidEntity(iEntity))
	{
		return false;
	}

#if defined _X64
	int pEntAttributeList[2];

	GetEntityAttributeList(pEntAttributeList, iEntity);

	if (!pEntAttributeList[0]) {
#else
	Address pEntAttributeList = GetEntityAttributeList(iEntity);
	if (pEntAttributeList == Address_Null) {
#endif
		PrintToServer("[hmmr/attribute_adapter] SetAttribute(): GetEntityAttributeList returned NULL.");
		return false;
	}

#if defined _X64
	int pEconItemAttributeDefinition[2];

	GetByID(pEconItemAttributeDefinition, iDefIndex);

	if (!pEconItemAttributeDefinition[0]) {
#else
	Address pAttribDef = GetAttributeDefinitionByID(iDefIndex);
	if (pAttribDef == Address_Null) {
#endif
		PrintToServer("[hmmr/attribute_adapter] SetAttribute(): GetAttributeDefinitionByID returned NULL.");
		return false;
	}

#if defined _X64
	PrintToServer("[hmmr/attribute_adapter] [DEBUG] SetAttribute()->SDKCall (iDefIndex=%i, pEntAttributeList=[%i, %i], pEconItemAttributeDefinition=[%i, %i], flValue=%f)", 
		iDefIndex, pEntAttributeList[0], pEntAttributeList[1], pEconItemAttributeDefinition[0], pEconItemAttributeDefinition[1], flValue);
	SDKCall(hSDKSetRuntimeValue, pEntAttributeList, pEconItemAttributeDefinition, flValue);
#else
	PrintToServer("[hmmr/attribute_adapter] [DEBUG] SetAttribute()->SDKCall (iDefIndex=%i, pEntAttributeList=%i, pAttribDef=%i, flValue=%f)", iDefIndex, pEntAttributeList, pAttribDef, flValue);
	SDKCall(hSDKSetRuntimeValue, pEntAttributeList, pAttribDef, flValue);
#endif
	return true;
}

#if defined _X64
void GetItemSchema(any pSchema[2]) {
	SDKCall(hSDKSchema, pSchema);
}
#else
static Address GetItemSchema() {
	return SDKCall(hSDKSchema);
}
#endif

#if !defined(_X64)
static Address GetAttributeDefinitionByID(int id) {
	Address pSchema = GetItemSchema();

	if (pSchema == Address_Null)
	{
		return Address_Null;
	} 
	else
	{
		return SDKCall(hSDKGetAttributeDef, pSchema, id);
	}	
}

/**
 * Returns the m_AttributeList offset.  This does not correspond to the CUtlVector instance
 * (which is offset by 0x04).
 */
static Address GetEntityAttributeList(int entity) {
	int offsAttributeList = GetEntSendPropOffs(entity, "m_AttributeList", true);
	if (offsAttributeList != -1)
	{
		return GetEntityAddress(entity) + view_as<Address>(offsAttributeList);
	}
	else
	{
		return Address_Null;
	}
}
#endif