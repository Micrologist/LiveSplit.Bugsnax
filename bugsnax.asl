state("Bugsnax"){}

startup
{
    vars.startAfterLoad = false;
    vars.splitNextLoad = false;
    vars.sbVisited = false;
    vars.ignoreLoads = false;
    settings.Add("endSplit", true, "Split on beating the game");
    settings.Add("mapSplit", false, "Split on all map transitions");
    settings.Add("questSplit", false, "Split on last battle quests");

    if (timer.CurrentTimingMethod == TimingMethod.RealTime)
    {
        var timingMessage = MessageBox.Show(
            "This game uses RTA w/o Loads as the main timing method.\n"
            + "LiveSplit is currently set to show Real Time (RTA).\n"
            + "Would you like to set the timing method to RTA w/o Loads",
            "Bugsnax | LiveSplit",
            MessageBoxButtons.YesNo, MessageBoxIcon.Question
        );
        if (timingMessage == DialogResult.Yes)
        {
            timer.CurrentTimingMethod = TimingMethod.GameTime;
        }
    }
}

init
{
    var scanner = new SignatureScanner(game, game.MainModule.BaseAddress, game.MainModule.ModuleMemorySize);

    // find a piece of code that will reference the game object
    var sigGameObjectFinder = new SigScanTarget(0, "488d0d????????e8????????488b0d????????84c0");
    var baseGameObjectFinder = scanner.Scan(sigGameObjectFinder);

    // reference is relative to RIP, so we need to do some math
    var relAdress = game.ReadBytes(baseGameObjectFinder + 3, 4);
    var relAddressVal = BitConverter.ToInt32(relAdress, 0);
    var baseGameObject = baseGameObjectFinder + relAddressVal + 7;

    // base_ will now hold the base for the pointers
    var base_ = baseGameObject + 0x178;

    // this will find the Screens object from data that exists before it
    var sigQuest1Base = new SigScanTarget(0x10,"FDF1D8FFCFA762FF854C0DFF00000000");
    var baseQuest1 = scanner.Scan(sigQuest1Base);

    vars.quests = new string[] {"Help Shelda and Floofty!", "Help Chandlo and Snorpy!", "Help Beffica and Cromdo!", "Help Wiggle and Gramble!", "Help Wambus and Triffany!"};

    vars.watchers = new MemoryWatcherList();
    vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(base_, 0x19C)) { Name = "loading" });
    vars.watchers.Add(new StringWatcher(new DeepPointer(base_,0x1C8, 0xA0, 0x0), 150) { Name = "map" });
    vars.watchers.Add(new StringWatcher(new DeepPointer(baseQuest1, 0x8, 0xab8, 0x30, 0x30, 0xf68, 0x548, 0x0), 30*2) { Name = "quest1" });
    vars.lastQuest = "";
}

isLoading
{
    return (
            (vars.watchers["loading"].Current > 0 && vars.watchers["map"].Current != "Content/Levels/Beach_Inner_End.irr") 
                || (vars.watchers["loading"].Current > 1 && vars.watchers["map"].Current == "Content/Levels/Beach_Inner_End.irr")
                ) && !vars.ignoreLoads;
}


update
{
    vars.watchers.UpdateAll(game);

    if(timer.CurrentPhase == TimerPhase.Running)
    {
        vars.startAfterLoad = false;
    }
    else
    {
        vars.splitNextLoad = false;
        vars.sbVisited = false;
        vars.ignoreLoads = false;
    }

    if(vars.watchers["map"].Current == "Content/Levels/Camp.irr" && !vars.sbVisited && vars.watchers["loading"].Current == 1 && vars.watchers["loading"].Old == 2)
    {
        vars.ignoreLoads = true;
        vars.sbVisited = true;
    }

    if(vars.ignoreLoads && vars.watchers["loading"].Current == 0 && vars.watchers["loading"].Old == 1)
        vars.ignoreLoads = false;


    vars.doQuestSplit = false;

    if (vars.watchers["map"].Current == "Content/Levels/FinalBattle.irr" && Array.IndexOf(vars.quests, vars.watchers["quest1"].Current) >= 0)
    {
        
        // print(vars.watchers["quest1"].Current + " - " + vars.lastQuest);

        if (vars.watchers["quest1"].Current != vars.lastQuest)
        {
            vars.doQuestSplit = true;
            vars.lastQuest = vars.watchers["quest1"].Current;
        }
    }  
}

start
{
    if (vars.watchers["map"].Current == "Content/Levels/Forest_Tutorial.irr" && (vars.watchers["map"].Old == "Content/Levels/MainScreen_Background.irr" || vars.watchers["map"].Old == null))
        vars.startAfterLoad = true;
    return ((vars.watchers["loading"].Old > 0 && vars.watchers["loading"].Current == 0) && vars.startAfterLoad);
}

split
{
    if(settings["endSplit"] && vars.watchers["loading"].Current > 0 && vars.watchers["map"].Current == "Content/Levels/Credits.irr")
        return true;

    if(settings["mapSplit"] && vars.watchers["map"].Current != vars.watchers["map"].Old && vars.watchers["map"].Old != "Content/Levels/MainScreen_Background.irr" && vars.watchers["map"].Current != "Content/Levels/MainScreen_Background.irr")
        vars.splitNextLoad = true;

    if(vars.watchers["loading"].Current > 0 && vars.watchers["loading"].Old == 0 && vars.splitNextLoad)
    {
        vars.splitNextLoad = false;
        return true;
    }

    if(settings["questSplit"] && vars.doQuestSplit)
        return true;
}


reset
{
    if((vars.watchers["map"].Current == "Content/Levels/Forest_Tutorial.irr" && vars.watchers["map"].Old == "Content/Levels/MainScreen_Background.irr"))
    {
        vars.startAfterLoad = true;
        return true;
    }
}
