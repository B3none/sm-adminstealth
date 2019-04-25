#include <sourcemod>
#include <cstrike>
#include <clientprefs>

#pragma semicolon 1
#pragma newdecls required

#define MESSAGE_PREFIX "[\x02AdminStealth\x01]"

Handle g_hCookieHidden;
bool hideTag[MAXPLAYERS + 1];

public Plugin myinfo =
{
    name = "[SM] Admin stealth",
    description = "Lets an admin toggle their clan tag whilst also managing clantags too.",
    author = "B3none",
    version = "1.2.0",
    url = "https://github.com/b3none"
}

public void OnPluginStart()
{
    HookEvent("round_start", OnRoundStartOrEnd);
    HookEvent("round_end", OnRoundStartOrEnd);
    HookEvent("player_spawn", OnPlayerSpawn);

    // Stealth commands.
    RegAdminCmd("sm_stealth", StealthCommand, ADMFLAG_GENERIC);

    // Unstealth commands.
    RegAdminCmd("sm_unstealth", RevealCommand, ADMFLAG_GENERIC);
    RegAdminCmd("sm_reveal", RevealCommand, ADMFLAG_GENERIC);

    g_hCookieHidden = RegClientCookie("sm_adminstealth_is_hidden", "", CookieAccess_Private);
}

public void OnClientCookiesCached(int client)
{
	char strCookie[8];
	GetClientCookie(client, g_hCookieHidden, strCookie, sizeof(strCookie));

	if (StringToInt(strCookie) == 0)
	{
		SetCookie(client, g_hCookieHidden, false);
	}

	GetClientCookie(client, g_hCookieHidden, strCookie, sizeof(strCookie));
	hideTag[client] = view_as<bool>(StringToInt(strCookie));
}

public void SetCookie(int client, Handle cookie, bool value)
{
	char strCookie[64];
	IntToString(value, strCookie, sizeof(strCookie));
	SetClientCookie(client, cookie, strCookie);
}

public void OnClientPostAdminCheck(int client)
{
	char strCookie[32];

	GetClientCookie(client, g_hCookieHidden, strCookie, sizeof(strCookie));
	hideTag[client] = view_as<bool>(StringToInt(strCookie));
}

public void OnClientDisconnect(int client)
{
    hideTag[client] = false;
}

public Action OnRoundStartOrEnd(Event event, const char[] name, bool dontBroadcast)
{
    CreateTimer(1.0, UpdateTags);
}

public Action OnPlayerSpawn(Handle event, char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));

    if (IsValidClient(client))
    {
        UpdateTag(client);
    }

    return Plugin_Continue;
}

public void OnClientSettingsChanged(int client)
{
    if (IsClientAuthorized(client)) 
    {
        UpdateTag(client);
    }
}

public Action StealthCommand(int client, int args)
{
    hideTag[client] = true;
    SetCookie(client, g_hCookieHidden, true);

    PrintToChat(client, "%s You've enabled stealth mode.", MESSAGE_PREFIX);
    UpdateTag(client);
}

public Action RevealCommand(int client, int args)
{
    hideTag[client] = false;
    SetCookie(client, g_hCookieHidden, false);

    PrintToChat(client, "%s You've disabled stealth mode.", MESSAGE_PREFIX);
    UpdateTag(client);
}

public Action UpdateTags(Handle timer)
{
    for (int clientId = 0; clientId <= MaxClients; clientId++) 
    {
        if (IsValidClient(clientId))
        {
            UpdateTag(clientId);
        }
    }
}

public void UpdateTag(int clientId)
{
    if (hideTag[clientId]) 
    {
        CS_SetClientClanTag(clientId, "");
    }
    else if (GetUserFlagBits(clientId) & ADMFLAG_ROOT)
    {
        CS_SetClientClanTag(clientId, "Developer |");
    }
    else if (GetUserFlagBits(clientId) & ADMFLAG_CHAT)
    {
        CS_SetClientClanTag(clientId, "Admin |");
    }
    else if (GetUserFlagBits(clientId) & ADMFLAG_GENERIC)
    {
        CS_SetClientClanTag(clientId, "Mod |");
    }
    else if (GetUserFlagBits(clientId) & ADMFLAG_CUSTOM6)
    {
        CS_SetClientClanTag(clientId, "VIP |");
    }
    else
    {
        CS_SetClientClanTag(clientId, "");
    }
}

stock bool IsValidClient(int clientId)
{
    return clientId > 0 && clientId <= MaxClients && IsClientConnected(clientId) && IsClientInGame(clientId);
}
