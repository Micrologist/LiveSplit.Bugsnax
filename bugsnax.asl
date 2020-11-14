state("Bugsnax", "1.03.55971")
{
    bool playing : 0x0065D6E8, 0x2A2;
    string150 map : 0x0065D6E8, 0x1C8, 0xA0, 0x0;
}

state("Bugsnax", "1.03.56017")
{
    bool playing: 0x00658368, 0x2A2;
    string150 map : 0x00658368, 0x1C8, 0xA0, 0x0;
}

startup
{
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

    vars.startAfterLoad = false;
    vars.splitNextLoad = false;
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
        default:
            version = "Unsupported - " + moduleSize.ToString();
            MessageBox.Show("This game version is currently not supported.", "LiveSplit Auto Splitter - Unsupported Game Version");
            break;
    }
}

isLoading
{
    return !current.playing;
}

update
{
    if(timer.CurrentPhase == TimerPhase.Running)
        vars.startAfterLoad = false;
    else
        vars.splitNextLoad = false;
    
    if(current.map != old.map)
        print("Map Transition: "+old.map+" -> "+current.map);
}

start
{
    if (current.map == "Content/Levels/Forest_Tutorial.irr" && old.map == "Content/Levels/MainScreen_Background.irr")
        vars.startAfterLoad = true;

    return ((!old.playing && current.playing) && vars.startAfterLoad);
}

split
{
    if(current.map != old.map)
        vars.splitNextLoad = true;

    if(!current.playing && old.playing && vars.splitNextLoad)
    {
        vars.splitNextLoad = false;
        return true;
    }
}
