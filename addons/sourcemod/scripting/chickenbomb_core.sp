#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <ttt>
#include <emitsoundany>

#define SND_BOMB "training/firewerks_burst_02.wav"
#define SND_BEEP "weapons/c4/c4_beep1.wav"

enum struct PlayerData
{
    Handle chickenexplode;
    Handle normalchicken;
    Handle redchicken;
    Handle timeleft;

    bool ChickenGotShot;
    bool HasChickenBomb;

    int ClientChickenBomb;

    float time;
}

ConVar g_cExplodeTime = null;

ConVar g_cNormalChickenTime = null;
ConVar g_cRedChickenTime = null;

ConVar g_cGrenadeDamage = null;
ConVar g_cGrenadeRadius = null;

ConVar g_cExplosionRadius = null;
ConVar g_cExplosionMagnitude = null;

PlayerData g_iPlayer[MAXPLAYERS + 1];

public Plugin myinfo =
{
    name = "Chicken bomb",
    author = "MarsTwix",
    description = "An chicken that can explode",
    version = "0.1.0",
    url = ""
};

public OnPluginStart()
{
    g_cExplodeTime = AutoExecConfig_CreateConVar("ttt_chicken_bomb_explode_time", "5.0", "The amount of time until the chicken bomb will explode.");
    g_cNormalChickenTime = AutoExecConfig_CreateConVar("ttt_chicken_bomb_normal_time", "0.5", "The amount of time that the chicken will be its normal color.");
    g_cRedChickenTime = AutoExecConfig_CreateConVar("ttt_chicken_bomb_red_time", "0.5", "The amount of time that the chicken will be the red color.");
    g_cGrenadeDamage = AutoExecConfig_CreateConVar("ttt_chicken_bomb_grenade_damage", "500", "The damage of the grenade the chicken will drop after being shot.");
    g_cGrenadeRadius = AutoExecConfig_CreateConVar("ttt_chicken_bomb_grenade_radius", "500", "The radius of the grenade the chicken will drop after being shot.");
    g_cExplosionRadius = AutoExecConfig_CreateConVar("ttt_chicken_bomb_explosion_radius", "850", "The radius of the chicken that will explode.");
    g_cExplosionMagnitude = AutoExecConfig_CreateConVar("ttt_chicken_bomb_explosion_magnitude", "850", "The magnitude of the chicken that will explode.");
    RegConsoleCmd("sm_spawnchicken", Command_SpawnChicken, "Spawns a chicken");
}

public void OnMapStart()
{
    PrecacheSoundAny(SND_BOMB);
    PrecacheSoundAny(SND_BEEP);

    LoopValidClients(i)
    {
        ClientReset(i);
    }
}

public void OnClientPutInServer(int client)
{
    g_iPlayer[client].chickenexplode = INVALID_HANDLE;
    g_iPlayer[client].normalchicken = INVALID_HANDLE;
    g_iPlayer[client].redchicken = INVALID_HANDLE;
    g_iPlayer[client].timeleft = INVALID_HANDLE;
}

Action Command_SpawnChicken(client, args)
{
    CreateChicken(client);
}

public void CreateChicken(int client)
{
    if (!g_iPlayer[client].HasChickenBomb)
    {
        int entity = CreateEntityByName("chicken");
        float origin[3];
        if (IsValidEntity(entity))
        {
            DataPack data;

            char sGrenadeDamage[8];
            char sGrenadeRadius[8];

            IntToString(g_cGrenadeDamage.IntValue, sGrenadeDamage, sizeof(sGrenadeDamage));
            IntToString(g_cGrenadeRadius.IntValue, sGrenadeRadius, sizeof(sGrenadeRadius));

            GetClientAbsOrigin(client, origin);
            DispatchKeyValue(entity, "targetname", "chickenbomb");
            DispatchKeyValue(entity, "ExplodeDamage", sGrenadeDamage);
            DispatchKeyValue(entity, "ExplodeRadius", sGrenadeRadius);
            DispatchSpawn(entity);
            SetEntProp(entity, Prop_Data, "m_takedamage", 2);

            g_iPlayer[client].ClientChickenBomb = entity;
            origin[0] += 20.0;
            TeleportEntity(entity, origin, NULL_VECTOR, NULL_VECTOR);

            g_iPlayer[client].HasChickenBomb = true;
            g_iPlayer[client].ChickenGotShot = true;

            int leader = ClosestClient(entity);
            SetEntPropEnt(entity, Prop_Send, "m_leader", leader);

            g_iPlayer[client].chickenexplode = CreateDataTimer(g_iPlayer[client].time, Timer_ChickenExplode, data);
            data.WriteCell(entity);
            data.WriteCell(client);

            int numtime = RoundFloat(g_iPlayer[client].time);
            PrintToChatAll("%i second(s) left!", numtime);
            g_iPlayer[client].time -= 1.0;

            EmitAmbientSoundAny("weapons/c4/c4_beep1.wav", NULL_VECTOR, entity);
            DispatchKeyValue(entity, "rendercolor", "255, 255, 255");

            g_iPlayer[client].normalchicken = CreateTimer(g_cNormalChickenTime.FloatValue, Timer_NormalChicken, entity, TIMER_REPEAT);

            g_iPlayer[client].redchicken = CreateTimer(g_cNormalChickenTime.FloatValue + g_cRedChickenTime.FloatValue, Timer_RedChicken, entity, TIMER_REPEAT);

            g_iPlayer[client].timeleft = CreateTimer(1.0, Timer_TimeLeft, client, TIMER_REPEAT);
        }
        else{PrintToServer("Couldnt create entity \"chicken\".");}
    }
    else{PrintToChat(client, "You already have a chickenbomb!");}
}

public Action Timer_ChickenExplode(Handle timer, DataPack data)
{
    data.Reset();
    int entity = data.ReadCell();
    int client = data.ReadCell();

    float position[3];

    GetEntPropVector(entity, Prop_Send, "m_vecOrigin", position);

    g_iPlayer[client].ChickenGotShot = false;

    AcceptEntityInput(entity, "Kill");

    int explosionIndex = CreateEntityByName("env_explosion");
    int particleIndex = CreateEntityByName("info_particle_system");
    int shakeIndex = CreateEntityByName("env_shake");
    if (explosionIndex != -1 && particleIndex != -1 && shakeIndex != -1)
    {
        PrintToChatAll("BOOM!");
        
        char sShakeRadius[8];
        IntToString(5000, sShakeRadius, sizeof(sShakeRadius));

        DispatchKeyValue(shakeIndex, "amplitude", "4");
        DispatchKeyValue(shakeIndex, "duration", "1");
        DispatchKeyValue(shakeIndex, "frequency", "2.5");
        DispatchKeyValue(shakeIndex, "radius", sShakeRadius);
        DispatchKeyValue(particleIndex, "effect_name", "explosion_c4_500");
        SetEntProp(explosionIndex, Prop_Data, "m_spawnflags", 16384);
        SetEntProp(explosionIndex, Prop_Data, "m_iRadiusOverride", g_cExplosionRadius.IntValue);
        SetEntProp(explosionIndex, Prop_Data, "m_iMagnitude", g_cExplosionMagnitude.IntValue);
        DispatchKeyValue(explosionIndex, "targetname", "c4");
        DispatchSpawn(particleIndex);
        DispatchSpawn(explosionIndex);
        DispatchSpawn(shakeIndex);
        ActivateEntity(shakeIndex);
        ActivateEntity(particleIndex);
        ActivateEntity(explosionIndex);
        TeleportEntity(particleIndex, position, NULL_VECTOR, NULL_VECTOR);
        TeleportEntity(explosionIndex, position, NULL_VECTOR, NULL_VECTOR);
        TeleportEntity(shakeIndex, position, NULL_VECTOR, NULL_VECTOR);
        AcceptEntityInput(entity, "Kill");
        AcceptEntityInput(explosionIndex, "Explode");
        AcceptEntityInput(particleIndex, "Start");
        AcceptEntityInput(shakeIndex, "StartShake");
        AcceptEntityInput(explosionIndex, "Kill");

        EmitAmbientSoundAny(SND_BOMB, position);
        ClearTimers(client);
        ClientReset(client);
    }
}

public Action Timer_TimeLeft(Handle timer, int client)
{
    int numtime = RoundFloat(g_iPlayer[client].time);
    PrintToChatAll("%i second(s) left!", numtime);
    g_iPlayer[client].time -= 1.0;
}

public void OnEntityDestroyed(entity)
{
    LoopValidClients(i)
    {
        if (entity == g_iPlayer[i].ClientChickenBomb)
        {
            if (g_iPlayer[i].ChickenGotShot == true)
            {
                PrintToChatAll("The chicken got shot and created a small explosion!");
                ClearTimers(i);
                ClientReset(i);
            }
        }
    }
}

Action Timer_NormalChicken(Handle timer, int entity)
{
	DispatchKeyValue(entity, "rendercolor", "255, 255, 255");
}

Action Timer_RedChicken(Handle timer, entity)
{
    float position[3];
    
    DispatchKeyValue(entity, "rendercolor", "255, 0, 0");
    GetEntPropVector(entity, Prop_Send, "m_vecOrigin", position);
    EmitAmbientSoundAny(SND_BEEP, position);
}

void ClientReset(int client)
{
    g_iPlayer[client].HasChickenBomb = false;
    g_iPlayer[client].ClientChickenBomb = 0;
    g_iPlayer[client].time = g_cExplodeTime.FloatValue;
    g_iPlayer[client].HasChickenBomb = false;
}

void ClearTimers(int client)
{
    ClearTimer(g_iPlayer[client].chickenexplode);
    ClearTimer(g_iPlayer[client].normalchicken);
    ClearTimer(g_iPlayer[client].redchicken);
    ClearTimer(g_iPlayer[client].timeleft);
}

int ClosestClient(int entity)
{
    int leader;
    float LeaderDistance = 0.0;
    float EntityPosition[3];
    float ClientPosition[3];
    float distance;
            
    LoopValidClients(i)
    {
        GetEntPropVector(entity, Prop_Send, "m_vecOrigin", EntityPosition);
        GetClientAbsOrigin(i, ClientPosition);
        distance = GetVectorDistance(EntityPosition, ClientPosition);
        if (distance > LeaderDistance)
        {
            LeaderDistance = distance;
            leader = i;
        }
    }

    return leader;
}

//A native so you can use this plugin in other plugin
public int Native_CreateChicken(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    if (!TTT_IsClientValid(client))
    {
        PrintToServer("Invalid client (%d)", client);
        return;
    }
    CreateChicken(client);
}