state("Bugsnax", "1.03.55971")
{
    int loading : 0x0065D6E8, 0x19C;
    string150 map : 0x0065D6E8, 0x1C8, 0xA0, 0x0;
}

state("Bugsnax", "1.03.56017")
{
    int loading: 0x00658368, 0x19C;
    string150 map : 0x00658368, 0x1C8, 0xA0, 0x0;
}

state("Bugsnax", "1.03.56076")
{
    int loading: 0x0065B3E8, 0x19C;
    string150 map : 0x0065B3E8, 0x1C8, 0xA0, 0x0;
}

state("Bugsnax", "1.04.56123")
{
    int loading: 0x0065C3E8, 0x19C;
    string150 map : 0x0065C3E8, 0x1C8, 0xA0, 0x0;
}


startup
{
    vars.startAfterLoad = false;
    vars.splitNextLoad = false;
    vars.sbVisited = false;
    vars.ignoreLoads = false;
    settings.Add("endSplit", true, "Split on beating the game");
    settings.Add("mapSplit", false, "Split on all map transitions");
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
    int moduleSize = modules.First().ModuleMemorySize;
    switch (moduleSize)
    {
        case 7200768:
            version = "1.03.55971";
            break;
        case 7180288:
            version = "1.03.56017";
            break;
        case 7192576:
            version = "1.03.56076";
            break;
        case 7196672:
            version = "1.04.56123";
            break;
        default:
            version = "Unsupported - " + moduleSize.ToString();
            MessageBox.Show("This game version is currently not supported.", "LiveSplit Auto Splitter - Unsupported Game Version");
            break;
    }
}

isLoading
{
    return ((current.loading > 0 && current.map != "Content/Levels/Beach_Inner_End.irr") || (current.loading > 1 && current.map == "Content/Levels/Beach_Inner_End.irr")) && !vars.ignoreLoads;
}

update
{
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

    if(current.map == "Content/Levels/Camp.irr" && !vars.sbVisited && current.loading == 1 && old.loading == 2)
    {
        vars.ignoreLoads = true;
        vars.sbVisited = true;
    }

    if(vars.ignoreLoads && current.loading == 0 && old.loading == 1)
        vars.ignoreLoads = false;
}

start
{
    if (current.map == "Content/Levels/Forest_Tutorial.irr" && old.map == "Content/Levels/MainScreen_Background.irr")
        vars.startAfterLoad = true;
    return ((old.loading > 0 && current.loading == 0) && vars.startAfterLoad);
}

split
{
    if(settings["endSplit"] && current.loading > 0 && current.map == "Content/Levels/Credits.irr")
        return true;

    if(settings["mapSplit"] && current.map != old.map && old.map != "Content/Levels/MainScreen_Background.irr" && current.map != "Content/Levels/MainScreen_Background.irr")
        vars.splitNextLoad = true;

    if(current.loading > 0 && old.loading == 0 && vars.splitNextLoad)
    {
        vars.splitNextLoad = false;
        return true;
    }
}

reset
{
    if((current.map == "Content/Levels/Forest_Tutorial.irr" && old.map == "Content/Levels/MainScreen_Background.irr"))
    {
        vars.startAfterLoad = true;
        return true;
    }
}
