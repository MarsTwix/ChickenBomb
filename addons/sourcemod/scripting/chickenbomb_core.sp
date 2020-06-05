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

    //float ColorTime = 2.0
    float time;
}

ConVar g_cExplodeTime = null;

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
    RegConsoleCmd("sm_spawnchicken", Command_SpawnChicken, "Spawns a chicken");
}

public OnMapStart()
{
    PrecacheSoundAny(SND_BOMB);
    PrecacheSoundAny(SND_BEEP);

    ResetAll();
}

public Action CS_OnTerminateRound()
{
    ResetAll();
}

Action Command_SpawnChicken(client, args)
{
    if (!g_iPlayer[client].HasChickenBomb)
    {
        int entity = CreateEntityByName("chicken");
        float origin[3];
        if (IsValidEntity(entity))
        {
            DataPack data;

            GetClientAbsOrigin(client, origin);
            DispatchKeyValue(entity, "targetname", "chickenbomb");
            DispatchKeyValue(entity, "ExplodeDamage", "500");
            DispatchKeyValue(entity, "ExplodeRadius", "500");
            DispatchSpawn(entity);
            SetEntProp(entity, Prop_Data, "m_takedamage", 2);

            g_iPlayer[client].ClientChickenBomb = entity;
            origin[0] += 20.0;
            TeleportEntity(entity, origin, NULL_VECTOR, NULL_VECTOR);

            g_iPlayer[client].HasChickenBomb = true;
            g_iPlayer[client].ChickenGotShot = true;

            g_iPlayer[client].chickenexplode = CreateDataTimer(g_iPlayer[client].time, Timer_ChickenExplode, data);
            data.WriteCell(entity);
            data.WriteCell(client);

            int numtime = RoundFloat(g_iPlayer[client].time);
            PrintToChatAll("%i second(s) left!", numtime);
            g_iPlayer[client].time -= 1.0;

            EmitAmbientSoundAny("weapons/c4/c4_beep1.wav", NULL_VECTOR, entity);
            DispatchKeyValue(entity, "rendercolor", "255, 255, 255");

            g_iPlayer[client].normalchicken = CreateTimer(0.5, Timer_NormalChicken, entity, TIMER_REPEAT);

            g_iPlayer[client].redchicken = CreateTimer(1.0, Timer_RedChicken, entity, TIMER_REPEAT);

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
        SetEntProp(explosionIndex, Prop_Data, "m_iRadiusOverride", 850);
        SetEntProp(explosionIndex, Prop_Data, "m_iMagnitude", 850);
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
        reset(client);
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
                reset(i);
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

void reset(int client)
{
    g_iPlayer[client].HasChickenBomb = false;
    g_iPlayer[client].ClientChickenBomb = 0;
    g_iPlayer[client].time = g_cExplodeTime.FloatValue;
    g_iPlayer[client].HasChickenBomb = false;
}

void ResetAll()
{
    LoopClients(i)
    {
        g_iPlayer[i].HasChickenBomb = false;
        g_iPlayer[i].ClientChickenBomb = 0;
        g_iPlayer[i].time = g_cExplodeTime.FloatValue;
        g_iPlayer[i].HasChickenBomb = false;
    }
}

void ClearTimers(int client)
{
    ClearTimer(g_iPlayer[client].chickenexplode);
    ClearTimer(g_iPlayer[client].normalchicken);
    ClearTimer(g_iPlayer[client].redchicken);
    ClearTimer(g_iPlayer[client].timeleft);
}