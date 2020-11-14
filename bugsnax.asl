state("Bugsnax", "1.03.55971")
{
    bool playing: 0x0065D6E8, 0x2A2;
}

state("Bugsnax", "1.03.56017")
{
    bool playing: 0x00658368, 0x2A2;
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
