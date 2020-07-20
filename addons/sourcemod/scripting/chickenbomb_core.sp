#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

#include <emitsoundany>
#include <ttt>
#include <betterplacement>

#define SND_BOMB "training/firewerks_burst_02.wav"
#define SND_BEEP "weapons/c4/c4_beep1.wav"

enum struct PlayerData
{
    Handle chickenexplode;
    Handle normalchicken;
    Handle redchicken;
    Handle timeleft;

    bool ChickenExploded;
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
ConVar g_cExplosionDeathRadius = null;
ConVar g_cDeathRadiusEnabled = null;

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
    g_cExplodeTime = CreateConVar("ttt_chicken_bomb_explode_time", "5.0", "The amount of time until the chicken bomb will explode.");
    g_cNormalChickenTime = CreateConVar("ttt_chicken_bomb_normal_time", "0.5", "The amount of time that the chicken will be its normal color.");
    g_cRedChickenTime = CreateConVar("ttt_chicken_bomb_red_time", "0.5", "The amount of time that the chicken will be the red color.");
    g_cGrenadeDamage = CreateConVar("ttt_chicken_bomb_grenade_damage", "500", "The damage of the grenade the chicken will drop after being shot.");
    g_cGrenadeRadius = CreateConVar("ttt_chicken_bomb_grenade_radius", "500", "The radius of the grenade the chicken will drop after being shot.");
    g_cExplosionRadius = CreateConVar("ttt_chicken_bomb_explosion_radius", "1000", "The radius of the chicken that will explode.");
    g_cExplosionMagnitude = CreateConVar("ttt_chicken_bomb_explosion_magnitude", "1000", "The magnitude of the chicken that will explode.");
    g_cExplosionDeathRadius = CreateConVar("ttt_chicken_bomb_explosion_death_radius", "500.0", "The radius of the certain death of a player, so if the player is in radius he will certainly die.");
    g_cDeathRadiusEnabled = CreateConVar("ttt_chicken_bomb_death_radius_enabled", "1", "Sets whether the death radius is enabled.");

    HookEvent("weapon_fire", Event_WeaponFire);
    HookEvent("hegrenade_detonate", Event_HegrenadeDetonate);

    RegConsoleCmd("sm_spawnchicken", Command_SpawnChicken, "Spawns a chicken");
}

public void OnMapStart()
{
    PrecacheSoundAny(SND_BOMB);
    PrecacheSoundAny(SND_BEEP);
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
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
/*
public void CreateChicken(int client)
{
    if (!g_iPlayer[client].HasChickenBomb)
    {
        int entity = CreateEntityByName("chicken");
        if (IsValidEntity(entity))
        {
            DataPack data;

            char sGrenadeDamage[8];
            char sGrenadeRadius[8];

            IntToString(g_cGrenadeDamage.IntValue, sGrenadeDamage, sizeof(sGrenadeDamage));
            IntToString(g_cGrenadeRadius.IntValue, sGrenadeRadius, sizeof(sGrenadeRadius));

            float vPos[3];
            float ang[3];
            GetClientAbsOrigin(client, vPos);
            GetClientAbsAngles(client, ang);
            vPos[0] = (vPos[0]+(16*(Cosine(DegToRad(ang[1])))));

            int RandomNum = GetRandomInt(0, 5);
            SetEntProp(entity, Prop_Send, "m_nBody", RandomNum);
            DispatchKeyValue(entity, "targetname", "chickenbomb");
            DispatchKeyValue(entity, "ExplodeDamage", sGrenadeDamage);
            DispatchKeyValue(entity, "ExplodeRadius", sGrenadeRadius);
            DispatchSpawn(entity);
            SetEntProp(entity, Prop_Data, "m_takedamage", 2);

            g_iPlayer[client].ClientChickenBomb = entity;
            TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);

            g_iPlayer[client].HasChickenBomb = true;
            g_iPlayer[client].ChickenExploded = false;

            g_iPlayer[client].time = g_cExplodeTime.FloatValue;
            g_iPlayer[client].chickenexplode = CreateDataTimer(g_iPlayer[client].time, Timer_ChickenExplode, data);
            data.WriteCell(entity);
            data.WriteCell(client);

            int numtime = RoundFloat(g_iPlayer[client].time);
            PrintHintText(client, "%i second(s) left!", numtime);
            g_iPlayer[client].time -= 1.0;

            EmitAmbientSoundAny("weapons/c4/c4_beep1.wav", NULL_VECTOR, entity);
            DispatchKeyValue(entity, "rendercolor", "255, 255, 255");

            g_iPlayer[client].normalchicken = CreateTimer(g_cNormalChickenTime.FloatValue, Timer_NormalChicken, entity, TIMER_REPEAT);

            g_iPlayer[client].redchicken = CreateTimer(g_cNormalChickenTime.FloatValue + g_cRedChickenTime.FloatValue, Timer_RedChicken, entity, TIMER_REPEAT);

            g_iPlayer[client].timeleft = CreateTimer(1.0, Timer_TimeLeft, client, TIMER_REPEAT);
        }
        else{PrintToServer("Couldnt create entity \"chicken\".");}
    }
    else{PrintHintText(client, "You already have a chickenbomb!");}
}
*/

public void CreateChicken(int client)
{
    if (!g_iPlayer[client].HasChickenBomb)
    {
        BetterPlacement(client, "chicken", 2.0, 150);
    }
    else
    {
        PrintToChat(client, "You already have a chickenbomb!");
    }
}

public void PreEntitySpawn(int entity, int client)
{
    if (g_iPlayer[client].HasChickenBomb)
    {
        char sGrenadeDamage[8];
        char sGrenadeRadius[8];

        IntToString(g_cGrenadeDamage.IntValue, sGrenadeDamage, sizeof(sGrenadeDamage));
        IntToString(g_cGrenadeRadius.IntValue, sGrenadeRadius, sizeof(sGrenadeRadius));

        int RandomNum = GetRandomInt(0, 5);
        SetEntProp(entity, Prop_Send, "m_nBody", RandomNum);
        DispatchKeyValue(entity, "targetname", "chickenbomb");
        DispatchKeyValue(entity, "ExplodeDamage", sGrenadeDamage);
        DispatchKeyValue(entity, "ExplodeRadius", sGrenadeRadius);

        g_iPlayer[client].ClientChickenBomb = entity;
        g_iPlayer[client].HasChickenBomb = true;
        g_iPlayer[client].ChickenExploded = false;
    }
}

public void EntitySpawn(int entity, int client, float EntityPosition[3])
{
    if (g_iPlayer[client].HasChickenBomb)
    {
        DataPack data;

        g_iPlayer[client].time = g_cExplodeTime.FloatValue;  
        g_iPlayer[client].chickenexplode = CreateDataTimer(g_iPlayer[client].time, Timer_ChickenExplode, data);

        data.WriteCell(entity);
        data.WriteCell(client);
        int numtime = RoundFloat(g_iPlayer[client].time);
        PrintHintText(client, "%i second(s) left!", numtime);
        g_iPlayer[client].time -= 1.0;

        EmitAmbientSoundAny("weapons/c4/c4_beep1.wav", NULL_VECTOR, entity);
        DispatchKeyValue(entity, "rendercolor", "255, 0, 0");

        g_iPlayer[client].normalchicken = CreateTimer(g_cNormalChickenTime.FloatValue, Timer_NormalChicken, entity, TIMER_REPEAT);

        g_iPlayer[client].redchicken = CreateTimer(g_cNormalChickenTime.FloatValue + g_cRedChickenTime.FloatValue, Timer_RedChicken, entity, TIMER_REPEAT);

        g_iPlayer[client].timeleft = CreateTimer(1.0, Timer_TimeLeft, client, TIMER_REPEAT);
    }
}

public Action Timer_ChickenExplode(Handle timer, DataPack data)
{
    data.Reset();
    int entity = data.ReadCell();
    int client = data.ReadCell();

    float position[3];

    GetEntPropVector(entity, Prop_Send, "m_vecOrigin", position);

    g_iPlayer[client].ChickenExploded = true;
    SetEntPropEnt(entity, Prop_Send, "m_leader", -1);
    AcceptEntityInput(entity, "Kill");

    int ExplosionIndex = CreateEntityByName("env_explosion");
    int particleIndex = CreateEntityByName("info_particle_system");
    int shakeIndex = CreateEntityByName("env_shake");
    if (ExplosionIndex != -1 && particleIndex != -1 && shakeIndex != -1)
    {
        PrintHintText(client, "BOOM!");
        
        char sShakeRadius[8];
        IntToString(5000, sShakeRadius, sizeof(sShakeRadius));

        DispatchKeyValue(shakeIndex, "amplitude", "4");
        DispatchKeyValue(shakeIndex, "duration", "1");
        DispatchKeyValue(shakeIndex, "frequency", "2.5");
        DispatchKeyValue(shakeIndex, "radius", sShakeRadius);
        DispatchKeyValue(particleIndex, "effect_name", "explosion_c4_500");
        SetEntProp(ExplosionIndex, Prop_Data, "m_spawnflags", 16384);
        SetEntProp(ExplosionIndex, Prop_Data, "m_iRadiusOverride", g_cExplosionRadius.IntValue);
        SetEntProp(ExplosionIndex, Prop_Data, "m_iMagnitude", g_cExplosionMagnitude.IntValue);
        DispatchKeyValue(ExplosionIndex, "targetname", "c4");
        DispatchSpawn(particleIndex);
        DispatchSpawn(ExplosionIndex);
        DispatchSpawn(shakeIndex);
        ActivateEntity(shakeIndex);
        ActivateEntity(particleIndex);
        ActivateEntity(ExplosionIndex);
        TeleportEntity(particleIndex, position, NULL_VECTOR, NULL_VECTOR);
        TeleportEntity(ExplosionIndex, position, NULL_VECTOR, NULL_VECTOR);
        TeleportEntity(shakeIndex, position, NULL_VECTOR, NULL_VECTOR);
        SetEntPropEnt(ExplosionIndex, Prop_Send, "m_hOwnerEntity", client);
        AcceptEntityInput(entity, "Kill");
        AcceptEntityInput(ExplosionIndex, "Explode");
        AcceptEntityInput(particleIndex, "Start");
        AcceptEntityInput(shakeIndex, "StartShake");
        AcceptEntityInput(ExplosionIndex, "Kill");

        EmitAmbientSoundAny(SND_BOMB, position);

        
        ClearTimers(client);
        ClientReset(client);

        if (g_cDeathRadiusEnabled.BoolValue)
        {
            float ClientPosition[3];
            float EntityPosition[3];
            float distance;
            LoopValidClients(i)
            { 
                GetEntPropVector(entity, Prop_Send, "m_vecOrigin", EntityPosition);
                GetClientAbsOrigin(i, ClientPosition);
                distance = GetVectorDistance(EntityPosition, ClientPosition);
                if (distance <= g_cExplosionDeathRadius.FloatValue)
                {
                    ForcePlayerSuicide(i);
                }
            }
        }
    }
}

public Action Timer_TimeLeft(Handle timer, int client)
{
    int numtime = RoundFloat(g_iPlayer[client].time);
    PrintHintText(client, "%i second(s) left!", numtime);
    g_iPlayer[client].time -= 1.0;
}

public Action Event_WeaponFire(Event event, const char[] name, bool dontBroadcast)
{
    LoopValidClients(i)
    {
        if (g_iPlayer[i].HasChickenBomb)
        {
            SetEntPropEnt(g_iPlayer[i].ClientChickenBomb, Prop_Send, "m_leader", -1);
        }
    }
}

public Action Event_HegrenadeDetonate(Event event, const char[] name, bool dontBroadcast)
{
    LoopValidClients(i)
    {
        if (g_iPlayer[i].HasChickenBomb)
        {
            SetEntPropEnt(g_iPlayer[i].ClientChickenBomb, Prop_Send, "m_leader", -1);
        }
    }
}

public void OnEntityDestroyed(int entity)
{
    LoopValidClients(i)
    {
        if (entity == g_iPlayer[i].ClientChickenBomb)
        {
            if (g_iPlayer[i].ChickenExploded == false)
            {
                SetEntPropEnt(entity, Prop_Send, "m_leader", -1);
                if(g_iPlayer[i].ClientChickenBomb == entity)
                {
                    PrintHintText(i, "The chicken got shot and created a small explosion!");
                }
                ClearTimers(i);
                ClientReset(i);
            }
        }
    }
}

public void OnGameFrame()
{
    LoopValidClients(i)
    {
        if (g_iPlayer[i].HasChickenBomb == true)
        {
            int leader = ClosestClient(g_iPlayer[i].ClientChickenBomb);
            SetEntPropEnt(g_iPlayer[i].ClientChickenBomb, Prop_Send, "m_leader", leader);
        }
    }   
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
    g_iPlayer[client].HasChickenBomb = false;
}

void ClearTimers(int client)
{
    KillTimer(g_iPlayer[client].chickenexplode);
    KillTimer(g_iPlayer[client].normalchicken);
    KillTimer(g_iPlayer[client].redchicken);
    KillTimer(g_iPlayer[client].timeleft);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    CreateNative("CreateChicken", Native_CreateChicken);
    CreateNative("GetClientChicken", Native_GetClientChicken);
    
    RegPluginLibrary("chickenbomb_core");

    return APLRes_Success;
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

public int Native_GetClientChicken(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    if (g_iPlayer[client].HasChickenBomb == true)
    {
        return g_iPlayer[client].ClientChickenBomb;
    }
    return -1;
}
