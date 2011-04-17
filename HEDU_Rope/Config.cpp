class CfgPatches
{
    class HEDU_Rope
    {
        units[] = { "HEDU_Rope" };
        requiredAddons[] = {};
        weapons[] = {};
        requiredVersion = 1.00;
    };
};

class CfgVehicleClasses
{
    class HEDU_Ropes
    {
        displayName = "HEDU_Ropes";
    };
};

class cfgVehicles
{
    class NonStrategic;
    
    class HEDU_Rope: NonStrategic
    {
        model = "\HEDU_Rope\HEDU_Rope.p3d";    // path to the object
        displayName =  "$STR_HEDU_Rope";       // entry in Stringtable.csv
                                               // Important are the $ and the capital STR_
        nameSound = "";                        
        mapSize = 8;                           // Size of the icon
        icon = "iconStaticObject";             // Path to the picture shown in the editor.
        accuracy = 1000;   
        scope = 2;                             // Display it in the editor? 1 = No, 2 = Yes
        
        vehicleClass = "HEDU_Ropes";
        weapons[]={};
        magazines[]={};
        
        animated = true;

        
        class  AnimationSources
        {
            class HEDU_Rope_Length             // the name used in model.cfg
            {
                source = "user";
                animPeriod = 0;
                initPhase = 0;
            };
        };
        
    };
};
