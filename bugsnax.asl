state("Bugsnax") {}

startup
{
    vars.log = (Action<dynamic>) ((output) => print("[Bugsnax ASL] " + output));

    settings.Add("endSplit", true, "Split on beating the game");
    settings.Add("mapSplit", false, "Split on all map transitions");
    settings.Add("questSplit", false, "Split on last battle quests");

    vars.startReady = false;
    vars.splitNextLoad = false;
    vars.sbVisited = false;
    vars.ignoreLoads = false;
    vars.MENU = "Content/Levels/MainScreen_Background.irr";

    if (timer.CurrentTimingMethod == TimingMethod.RealTime)
    {
        var mbox = MessageBox.Show(
            "Removing loads from Bugsnax requires comparing against Game Time.\nWould you like to switch to it?",
            "LiveSplit | Bugsnax Autosplitter",
            MessageBoxButtons.YesNo);

        if (mbox == DialogResult.Yes) timer.CurrentTimingMethod = TimingMethod.GameTime;
    }

    vars.timerStart = (EventHandler) ((s, e) =>
    {
        vars.startReady = false;
    });

    vars.timerReset = (LiveSplit.Model.Input.EventHandlerT<TimerPhase>) ((s, e) =>
    {
        vars.splitNextLoad = false;
        vars.sbVisited = false;
        vars.ignoreLoads = false;
    });

    timer.OnStart += vars.timerStart;
    timer.OnReset += vars.timerReset;
}

init
{
    int memSize = game.MainModule.ModuleMemorySize;

    vars.cancelSource = new CancellationTokenSource();
    vars.scanThread = new Thread(() =>
    {
        var scanner = new SignatureScanner(game, game.MainModule.BaseAddress, memSize);
        IntPtr gameData = IntPtr.Zero, sceneData = IntPtr.Zero;
        SigScanTarget gdTrg = new SigScanTarget(3, "48 83 3D ???????? 00 4C 8B F9"), sdTrg = new SigScanTarget(3, "48 8B 0D ???????? 48 8B 81 ???????? 48 8B 50");

        foreach (var trg in new[] { gdTrg, sdTrg })
            trg.OnFound = (p, s, ptr) => ptr + 0x4 + p.ReadValue<int>(ptr);

        var token = vars.cancelSource.Token;
        while (!token.IsCancellationRequested)
        {
            if (gameData == IntPtr.Zero && (gameData = scanner.Scan(gdTrg)) != IntPtr.Zero)
                vars.log("Found GameData at 0x" + (gameData += 0x1).ToString("X") + ".");

            if (sceneData == IntPtr.Zero && (sceneData = scanner.Scan(sdTrg)) != IntPtr.Zero)
                vars.log("Found SceneData at 0x" + sceneData.ToString("X") + ".");

            if (new[] { gameData, sceneData }.All(ptr => ptr != IntPtr.Zero))
            {
                int currScene = memSize == 0x6E2000 ? 0x1C8 : 0x228, questArr = memSize == 0x6E2000 ? 0xF70 : 0xF68;

                vars.watchers = new MemoryWatcherList
                {
                    new MemoryWatcher<int>(new DeepPointer(sceneData, 0x19C)) { Name = "loadVal" },
                    new StringWatcher(new DeepPointer(sceneData, currScene, 0xA0, 0x0), 256) { Name = "mapFilePath" },
                    new StringWatcher(new DeepPointer(gameData, questArr, 0x528, 0x0, 0x0), 256) { Name = "quests[0]" }
                };

                break;
            }

            Thread.Sleep(2000);
        }
    });

    vars.scanThread.Start();

    vars.quests = new List<string>
    {
        "Help Shelda and Floofty!",
        "Help Chandlo and Snorpy!",
        "Help Beffica and Cromdo!",
        "Help Wiggle and Gramble!",
        "Help Wambus and Triffany!"
    };

    vars.lastQuest = "";
}

update
{
    if (vars.scanThread.IsAlive) return false;

    vars.watchers.UpdateAll(game);
    current.loadVal = vars.watchers["loadVal"].Current;
    current.quest1 = vars.watchers["quests[0]"].Current ?? "";
    current.map = System.Text.RegularExpressions.Regex.Matches(vars.watchers["mapFilePath"].Current ?? vars.MENU, @".+/(.+).irr")[0].Groups[1].Value;

    if (old.loadVal == 2 && current.loadVal == 1 && current.map == "Camp" && !vars.sbVisited)
    {
        vars.ignoreLoads = true;
        vars.sbVisited = true;
    }

    if (old.loadVal == 1 && current.loadVal == 0 && vars.ignoreLoads)
    {
        vars.ignoreLoads = false;
    }

    current.loading = !vars.ignoreLoads
                      && (current.loadVal > 0 && current.map != "Beach_Inner_End"
                          || current.loadVal > 1 && current.map == "Beach_Inner_End");
}

start
{
    if ((string.IsNullOrEmpty(old.map) || old.map == "MainScreen_Background") && current.map == "Forest_Tutorial")
        vars.startReady = true;

    return old.loadVal > 0 && current.loadVal == 0 && vars.startReady;
}

split
{
    if (settings["endSplit"] && current.loadVal > 0 && current.map == "Credits")
        return true;

    if (settings["mapSplit"] && old.map != current.map && current.map != "MainScreen_Background")
        vars.splitNextLoad = true;

    if (old.loadVal == 0 && current.loadVal > 0 && vars.splitNextLoad)
    {
        vars.splitNextLoad = false;
        return true;
    }

    if (current.map == "FinalBattle" && current.quest1 != vars.lastQuest && vars.quests.Contains(current.quest1))
    {
        vars.lastQuest = vars.quest1;
        return settings["questSplit"];
    }
}

reset
{
    return old.map != "MainScreen_Background" && current.map == "MainScreen_Background";
}

isLoading
{
    return current.loading;
}

exit
{
    vars.cancelSource.Cancel();
}

shutdown
{
    timer.OnStart += vars.timerStart;
    timer.OnReset += vars.timerReset;
    vars.cancelSource.Cancel();
}
