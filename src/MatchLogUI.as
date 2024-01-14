/**
 * This is for the prompt when a match starts / the player joins a relevant server.
 */

// whether the window is currently showing (hidden if openplanet interface hidden)
bool showMatchLogUI = false;

void ShowMatchRecorderPrompt() {
    showMatchLogUI = true;
}

void RenderMatchLogUI() {
    if (!StillInServer(GetApp())) showMatchLogUI = false;
    if (!showMatchLogUI) return;

    int wwidth = 400;
    vec2 pos = vec2((Draw::GetWidth() - wwidth) >> 1, Draw::GetHeight() >> 1) / UI::GetScale();
    UI::SetNextWindowPos(pos.x, pos.y);
    UI::SetNextWindowSize(wwidth, -1, UI::Cond::Always);
    if (UI::Begin(PluginName + ": Current Match", showMatchLogUI)) {
        RenderMatchPromptUI_Inner();
    }
    UI::End();
}

void RenderMatchPromptUI_Inner() {
    if (currMatchLog is null) {
        UI::Text("No current log");
        return;
    }
    if (!currMatchLog.HasKey('name')) currMatchLog['name'] = currMatchLog['logName'];
    currMatchLog['name'] = UI::InputText("Custom Name", currMatchLog['name']);
    UI::Text("Log File Name: " + string(currMatchLog['logName']));
    if (UI::Button("Close & Record")) {
        showMatchLogUI = false;
    }
    UI::SameLine();
    UI::Dummy(vec2(165, 0));
    UI::SameLine();
    if (UI::Button("Don't Record")) {
        showMatchLogUI = false;
        DisableRecordingForThisSession();
    }
}

void DisableRecordingForThisSession() {
    // todo
    shouldKeepRecordingThisRound = false;
    if (currMatchLog !is null) {
        bool deleted = DB::RemoveAndDeleteMatchLogIfEmpty(currMatchLog['logName']);
        if (!deleted) warn("Failed to remove session match log: " + string(currMatchLog['logName']));
        else trace("Removed match session log: " + string(currMatchLog['logName']));
        @currMatchLog = null;
    }
}
