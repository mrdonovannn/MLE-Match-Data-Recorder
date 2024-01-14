void Main(){
    InitializeDb();
    startnew(MonitoringLoop);
    startnew(MonitorLastInServerTime);
}

string currServerName;
string currServerLogin;
string currGameMode;
string currMapUid;
string currMapName;
uint serverConnectStart;
string serverConnectStartStr;
bool isTeams;
bool isKO;
bool isCup;
bool isRounds;

// reset to true on server change
bool shouldKeepRecordingThisRound = true;

void MonitoringLoop() {
    auto app = GetApp();
    auto net = app.Network;
    auto si = cast<CTrackManiaNetworkServerInfo>(net.ServerInfo);
    while (true) {
        yield();
        if (!S_Enabled) continue;
        currServerLogin = si.ServerLogin;
        currServerName = si.ServerName;
        if (si.ServerLogin.Length == 0) continue;
        trace("Starting server login watch loop, login: " + currServerLogin + currServerLogin.Length);
        shouldKeepRecordingThisRound = currServerLogin.Length > 0;
        if (shouldKeepRecordingThisRound) startnew(OnJoinServer);
        while (si.ServerLogin == currServerLogin) {
            currGameMode = si.ModeName;
            isTeams = currGameMode.StartsWith("TM_Teams");
            isKO = currGameMode.StartsWith("TM_Knockout");
            isCup = currGameMode.StartsWith("TM_Cup");
            isRounds = currGameMode.StartsWith("TM_Rounds");
            bool isGoodMode = isTeams || isKO || isCup || isRounds;
            trace("Starting game mode watch loop");
            serverConnectStart = Time::Stamp;
            serverConnectStartStr = app.OSLocalDate.Replace("/", "-").Replace(":", "_");
            while (si.ServerLogin == currServerLogin && currGameMode == si.ModeName && shouldKeepRecordingThisRound) {
                if (isGoodMode) UpdateLoopInServer();
                yield();
            }

            while (!shouldKeepRecordingThisRound && si.ServerLogin == currServerLogin) yield();

            yield();
        }
    }
}

uint lastInServerTime;
void MonitorLastInServerTime() {
    auto app = GetApp();
    if (app.Network.ServerInfo is null) NotifyWarning("Network SI null!");
    while (app.Network.ServerInfo is null) yield();
    auto si = cast<CTrackManiaNetworkServerInfo>(app.Network.ServerInfo);
    while (true) {
        if (si.ServerLogin.Length > 0) lastInServerTime = Time::Now;
        yield();
    }
}

void StartRecordingIfDisabled() {
    shouldKeepRecordingThisRound = true;
    UpdateMatchLog();
}

void PauseRecording() {
    shouldKeepRecordingThisRound = false;
}

uint joinServerNonce;
void OnJoinServer() {
    if (!shouldKeepRecordingThisRound) return;
    uint myNonce = Math::Rand(0, 1000000000);
    joinServerNonce = myNonce;
    while (!StillInServer(GetApp())) yield();
    if (joinServerNonce != myNonce) return;
    isTeams = currGameMode.StartsWith("TM_Teams");
    isKO = currGameMode.StartsWith("TM_Knockout");
    isCup = currGameMode.StartsWith("TM_Cup");
    isRounds = currGameMode.StartsWith("TM_Rounds");

    if (ShouldPromptWhenJoining(currGameMode)) {
        trace('on join server should prompt');
        UpdateMatchLog();
        ShowMatchRecorderPrompt();
    }
}

void RenderInterface() {
    if (!S_Enabled) return;
    RenderMatchLogUI();
    if (S_ShowRecordingUI) RenderRecordingUI();
}

const string PluginName = Meta::ExecutingPlugin().Name;
const string MenuLabel = "\\$f28" + Icons::ListAlt + Icons::Circle + "\\$z " + Meta::ExecutingPlugin().Name;

/** Render function called every frame intended only for menu items in `UI`.
*/
void RenderMenu() {
    if (UI::BeginMenu(MenuLabel)) {
        if (UI::MenuItem("Enabled", "", S_Enabled)) {
            S_Enabled = !S_Enabled;
        }
        if (UI::MenuItem("Show Recording UI", "", S_ShowRecordingUI)) {
            S_ShowRecordingUI = !S_ShowRecordingUI;
        }
        if (UI::MenuItem("Open Log Folder", "", false)) {
            OpenExplorerPath(IO::FromStorageFolder(""));
        }
        UI::EndMenu();
    }
}

string GenerateMatchName() {
    return FileNameSafe(serverConnectStartStr + " - " + StripFormatCodes(currServerName));
}

// string FileNameSafe(const string &in filename) {
//     return filename.Replace("|", "")
//         .Replace(":", "")
//         .Replace("#", "")
//         .Replace("?", "")
//         .Replace("*", "")
//         .Replace(":", "")
//         .Replace("\"", "")
//         .Replace("<", "")
//         .Replace(">", "")
//         .Replace("/", "")
//         .Replace("\\", "");
// }

string FileNameSafe(const string &in filename) {
    auto x = filename.Replace("|", "").Replace(":", "").Replace("#", "");
    x = x.Replace("?", "").Replace("*", "").Replace(":", "");
    x = x.Replace('"', "").Replace("<", "").Replace(">", "");
    return x.Replace("/", "").Replace("\\", "");
}

void UpdateLoopInServer() {
    auto app = cast<CGameManiaPlanet>(GetApp());
    // early exit if things aren't available
    if (app.RootMap is null || IsLoadingScreenShowing(app)) return;
    auto cmap = app.Network.ClientManiaAppPlayground;
    if (cmap is null) return;
    if (app.CurrentPlayground is null) return;
    // nothing to do in most UI sequences
    if (IsPlayingOrFinish(cmap)) return;

    // // if the start time is > the end time then we are in warmup;
    // if (!IsStartTimeLTEndTime(app)) return;

    // update map details;
    currMapName = StripFormatCodes(app.RootMap.MapInfo.Name);
    currMapUid = app.RootMap.EdChallengeId;
    // don't save stuff if the warmup is active
    if (MLFeed::GetTeamsMMData_V1().WarmUpIsActive) return;
    // if we hit a reason to save stats, do that
    if (IsEndRoundOrUiInteraction(cmap)) UpdateMatchLog();
    // wait for the map to change, or a loading screen to be present, etc.
    while (StillInServer(app) && IsEndRoundOrUiInteraction(cmap)) yield();
    // if the next UI sequence is Podium, update and save podium results
    if (StillInServer(app) && IsPodium(cmap)) UpdateMatchLog();
    while (StillInServer(app) && IsPodium(cmap)) yield();
}

bool IsStartTimeLTEndTime(CGameCtnApp@ app) {
    if (app.CurrentPlayground is null) return false;
    auto cp = cast<CSmArenaClient>(app.CurrentPlayground);
    if (cp.Arena is null || cp.Arena.Rules is null) return false;
    return cp.Arena.Rules.RulesStateStartTime < cp.Arena.Rules.RulesStateEndTime;
}

bool StillInServer(CGameCtnApp@ app) {
    return app.RootMap !is null && app.Network.ClientManiaAppPlayground !is null && !IsLoadingScreenShowing(app);
}


bool IsLoadingScreenShowing(CGameCtnApp@ app) {
    return app.LoadProgress.State == NGameLoadProgress::EState::Displayed;
}

bool IsEndRoundOrUiInteraction(CGameManiaAppPlayground@ cmap) {
    if (cmap is null || cmap.UI is null) return false;
    auto seq = cmap.UI.UISequence;
    return seq == CGamePlaygroundUIConfig::EUISequence::EndRound || seq == CGamePlaygroundUIConfig::EUISequence::UIInteraction;
}

bool IsPlayingOrFinish(CGameManiaAppPlayground@ cmap) {
    if (cmap is null || cmap.UI is null) return false;
    auto seq = cmap.UI.UISequence;
    return seq == CGamePlaygroundUIConfig::EUISequence::Playing || seq == CGamePlaygroundUIConfig::EUISequence::Finish;
}

bool IsPodium(CGameManiaAppPlayground@ cmap) {
    if (cmap is null || cmap.UI is null) return false;
    auto seq = cmap.UI.UISequence;
    return seq == CGamePlaygroundUIConfig::EUISequence::Podium;
}
