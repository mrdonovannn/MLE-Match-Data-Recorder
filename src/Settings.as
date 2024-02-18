[Setting category="General" name="Enabled"]
bool S_Enabled = true;

[Setting category="General" name="Show Recording UI" description="Will show a window while recording when the openplanet interface is shown"]
bool S_ShowRecordingUI = true;

[Setting category="Game Modes" name="Record Teams mode?"]
bool S_RecordTeams = true;
[Setting category="Game Modes" name="Record KO mode?"]
bool S_RecordKO = false;
[Setting category="Game Modes" name="Record Cup mode?"]
bool S_RecordCup = false;
[Setting category="Game Modes" name="Record Rounds mode?"]
bool S_RecordRounds = false;

[Setting category="Autoprompt" name="Prompt for Teams mode?"]
bool S_AutoPromptForTeams = true;
[Setting category="Autoprompt" name="Prompt for KO mode?"]
bool S_AutoPromptForKO = false;
[Setting category="Autoprompt" name="Prompt for Cup mode?"]
bool S_AutoPromptForCup = false;
[Setting category="Autoprompt" name="Prompt for Rounds mode?"]
bool S_AutoPromptForRounds = false;

bool ShouldPromptWhenJoining(const string &in mode) {
    return S_AutoPromptForTeams && mode.StartsWith("TM_Teams")
        || S_AutoPromptForKO && mode.StartsWith("TM_Knockout")
        || S_AutoPromptForCup && mode.StartsWith("TM_Cup")
        || S_AutoPromptForRounds && mode.StartsWith("TM_Rounds")
     ;
}
