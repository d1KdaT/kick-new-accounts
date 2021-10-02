#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <SteamWorks>

#define API_URL "http://example.ru/check.php"
#define KICK_REASON "New Steam accounts not allowed (7 days)"

public Plugin myinfo =
{
	name		= "Kick New Steam Accounts",
	author		= "d1KdaT",
	version		= "1.0.0",
	url			= "https://d1kdat.me/"
};

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
	
	Handle hRequest = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, API_URL);

	SteamWorks_SetHTTPRequestNetworkActivityTimeout(hRequest, 10);
	SteamWorks_SetHTTPRequestGetOrPostParameter(hRequest, "account_id", szAccountID);
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
						KickClient(iClient, KICK_REASON);
						LogMessage("Client %N (ID: %i) kicked as new", iClient, iPlayerAccountID);
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
