#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>

int g_IsIncendiary[MAXPLAYERS + 1];

public Plugin myinfo = {
	name = "[L4D2] Grenades Fire",
	author = "KeithGDR",
	description = "Adds fire under where grenades land with the Grenade Launcher.",
	version = "1.0.0",
	url = "https://github.com/keithgdr"
};

public void OnPluginStart() {
	HookEvent("weapon_fire", Event_OnWeaponFire);
}

public void Event_OnWeaponFire(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (client < 1 || client > MaxClients) {
		return;
	}

	int primary = GetPlayerWeaponSlot(client, 0);

	if (!IsValidEntity(primary) || !IsClassname(primary, "weapon_grenade_launcher", false)) {
		return;
	}

	//Check if the last grenade was incendiary here since the weapon won't be once it hits.
	if ((L4D2_GetWeaponUpgrades(primary) & L4D2_WEPUPGFLAG_INCENDIARY) == L4D2_WEPUPGFLAG_INCENDIARY) {
		g_IsIncendiary[client]++;
	}
}

//Not working, left4dhooks is garbagio.
public void L4D2_GrenadeLauncher_Detonate_Post(int entity, int client) {
	//HandleLogic(entity, client);
}

public void OnEntityDestroyed(int entity) {
	if (IsClassname(entity, "grenade_launcher_projectile", false)) {
		int client = GetEntPropEnt(entity, Prop_Data, "m_hThrower");
		HandleLogic(entity, client);
	}
}

void HandleLogic(int entity, int client) {
	if (client < 0 || client > MaxClients || g_IsIncendiary[client] < 1) {
		return;
	}

	g_IsIncendiary[client]--;

	float origin[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);
	
	int molotov = L4D_MolotovPrj(client, origin, NULL_VECTOR);

	if (IsValidEntity(molotov)) {
		L4D_DetonateProjectile(molotov);
	}
}

public void OnClientDisconnect_Post(int client) {
	g_IsIncendiary[client] = 0;
}

bool IsClassname(int entity, const char[] classname, bool caseSensitive = true) {
	char class[64];
	GetEntityClassname(entity, class, sizeof(class));
	return StrEqual(class, classname, caseSensitive);
}