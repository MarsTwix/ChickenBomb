#if defined chickenbomb_core_included
 #endinput
#endif

#define _chickenbomb_core_included

native void CreateChicken(int client);

public SharedPlugin __pl_chickenbomb_core = 
{
    name = "chickenbomb_core",
    file = "chickenbomb_core.smx",
#if defined REQUIRE_PLUGIN
    required = 1,
#else
    required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_chickenbomb_core_SetNTVOptional()
{
    MarkNativeAsOptional("CreateChicken");
}