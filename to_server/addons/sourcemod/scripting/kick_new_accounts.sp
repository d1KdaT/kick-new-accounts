#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <SteamWorks>

bool g_bEnableKick = true;
int g_iNeedleDays = 7;
char g_sApiUrl[64], g_sKickReason[64];

public Plugin myinfo =
{
	name		= "Kick New Steam Accounts",
	author		= "d1KdaT",
	version		= "1.0.3",
	url			= "https://d1kdat.me/"
};

public void OnPluginStart()
{
	ConVar Convar;

	(Convar = CreateConVar("sm_kna_api_url", "http://example.ru/check.php", "API PATH URL. Example: http://example.ru/check.php")).AddChangeHook(ChangeCvar_ApiUrl);
	ChangeCvar_ApiUrl(Convar, NULL_STRING, NULL_STRING);

	(Convar = CreateConVar("sm_kna_kick_reason", "New Steam accounts not allowed (7 days)", "Reason shows to kicked player")).AddChangeHook(ChangeCvar_KickReason);
	ChangeCvar_KickReason(Convar, NULL_STRING, NULL_STRING);

	(Convar = CreateConVar("sm_kna_needle_days", "7", "Required number of days from account creation to be able to connect to the server", _, true, 1.0, true, 90.0)).AddChangeHook(ChangeCvar_NeedleDays);
	ChangeCvar_NeedleDays(Convar, NULL_STRING, NULL_STRING);

	(Convar = CreateConVar("sm_kna_enable_kick", "1", "Kick players (1)? Or just make requests to API to collect data (0)", _, true, 0.0, true, 1.0)).AddChangeHook(ChangeCvar_EnableKick);
	ChangeCvar_EnableKick(Convar, NULL_STRING, NULL_STRING);

	AutoExecConfig(true, "kick_new_accounts");
}

void ChangeCvar_ApiUrl(ConVar Convar, const char[] oldValue, const char[] newValue)
{
	Convar.GetString(g_sApiUrl, sizeof(g_sApiUrl));
}

void ChangeCvar_KickReason(ConVar Convar, const char[] oldValue, const char[] newValue)
{
	Convar.GetString(g_sKickReason, sizeof(g_sKickReason));
}

void ChangeCvar_NeedleDays(ConVar Convar, const char[] oldValue, const char[] newValue)
{
	g_iNeedleDays = Convar.IntValue;
}

void ChangeCvar_EnableKick(ConVar Convar, const char[] oldValue, const char[] newValue)
{
	g_bEnableKick = Convar.BoolValue;
}

public void OnClientAuthorized(int iClient)
{
	if(!IsFakeClient(iClient) && !IsClientSourceTV(iClient))
	{
		int iPlayerAccountID = GetSteamAccountID(iClient, true);

		if(iPlayerAccountID)
		{
			SendHttpQuery(iClient, iPlayerAccountID);
		}
	}
}

void SendHttpQuery(int iClient, int iAccountID)
{
	char szAccountID[32];
	FormatEx(szAccountID, sizeof(szAccountID), "%i", iAccountID);

	char szNeedleDays[32];
	FormatEx(szNeedleDays, sizeof(szNeedleDays), "%i", g_iNeedleDays);
	
	Handle hRequest = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, g_sApiUrl);

	SteamWorks_SetHTTPRequestNetworkActivityTimeout(hRequest, 10);
	SteamWorks_SetHTTPRequestGetOrPostParameter(hRequest, "account_id", szAccountID);
	SteamWorks_SetHTTPRequestGetOrPostParameter(hRequest, "needle_days", szNeedleDays);
	SteamWorks_SetHTTPCallbacks(hRequest, HTTPRequestComplete);
	SteamWorks_SetHTTPRequestContextValue(hRequest, GetClientUserId(iClient));

	SteamWorks_SendHTTPRequest(hRequest);
}

public void HTTPRequestComplete(Handle hRequest, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode, any iUserID)
{
	delete hRequest;

	switch(eStatusCode)
	{
		case 200, 204:
		{
			int iClient = GetClientOfUserId(iUserID);
			if(iClient)
			{
				int iPlayerNewState = (eStatusCode == k_EHTTPStatusCode200OK ? 1 : 0);
				int iPlayerAccountID = GetSteamAccountID(iClient, true);

				if(iPlayerAccountID)
				{
					if(iPlayerNewState == 0)
					{
						if(g_bEnableKick)
						{
							KickClient(iClient, g_sKickReason);
							LogMessage("Client %N (ID: %i) kicked as new", iClient, iPlayerAccountID);
						}
					}
				}
				else
				{
					LogError("Client %N (ID: UNKNOWN) status: %i", iClient, iPlayerNewState);
				}
			}
		}
		case 400: LogError("Response: Invalid request parameters");
		case 500: LogError("Response: Internal error");
	}
}
