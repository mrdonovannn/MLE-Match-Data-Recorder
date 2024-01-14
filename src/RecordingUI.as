void RenderRecordingUI() {
    UI::SetNextWindowPos(Draw::GetWidth() * 8 / 10, Draw::GetHeight() * 1 / 10, UI::Cond::FirstUseEver);
    // int flags = UI::WindowFlags::NoTitleBar | UI::WindowFlags::AlwaysAutoResize;
    int flags = UI::WindowFlags::AlwaysAutoResize | UI::WindowFlags::NoCollapse;
    if (UI::Begin("Match Recorder##recordingui", flags)) {
        RenderRecordingUI_Inner();
    }
    UI::End();
}

void RenderRecordingUI_Inner() {
    if (!StillInServer(GetApp())) {
        UI::Text("Not in a server");
        if (currMatchLog !is null && lastInServerTime > 0) {
            if (lastInServerTime + 10000 > Time::Now) {
                UI::Text("Last log file name: " + string(currMatchLog['logName']));
                if (UI::Button("Open Log Folder")) {
                    OpenExplorerPath(IO::FromStorageFolder(""));
                }
            }
        } else {
            lastInServerTime = 0;
        }
        // if (UI::Button(""))
        return;
    }
    UI::Text("Server: " + currServerName);
    bool inAServer = currServerLogin.Length > 0;
    bool isRecording = inAServer && shouldKeepRecordingThisRound;
    bool canPause = isRecording && inAServer;
    bool canRecord = !isRecording && inAServer;
    bool canStop = currMatchLog !is null;

    UI::BeginDisabled(!canRecord);
    if (UI::Button("\\$f00" + Icons::Circle)) {
        StartRecordingIfDisabled();
    }
    UI::EndDisabled();

    UI::SameLine();
    UI::BeginDisabled(!canPause);
    if (UI::Button(Icons::Pause)) {
        PauseRecording();
    }
    UI::EndDisabled();
    AddSimpleTooltip("No data will be recorded while the recording is paused");

    UI::SameLine();
    UI::Dummy(vec2(20, 0));

    UI::SameLine();
    UI::BeginDisabled(!canStop);
    if (UI::Button(Icons::Stop + Icons::Trash)) {
        DisableRecordingForThisSession();
    }
    UI::EndDisabled();
    AddSimpleTooltip("The log will be deleted.");

    // UI::SameLine();
    // UI::SameLine();
    // UI::SameLine();

}
