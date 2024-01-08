const string StorageDir = IO::FromStorageFolder("");

void InitializeDb() {
    // scan files mb
}

namespace DB {
    dictionary loadedMatches;

    Json::Value@ GetMatchLog(const string &in logName) {
        if (!loadedMatches.Exists(logName)) {
            @loadedMatches[logName] = NewMatchLog(logName);
        }
        return cast<Json::Value>(loadedMatches[logName]);
    }

    Json::Value@ NewMatchLog(const string &in logName) {
        auto j = Json::Object();
        j['logName'] = logName + ".json";
        j['serverLogin'] = currServerLogin;
        j['gameMode'] = currGameMode;
        j['serverName'] = currServerName;
        j['maps'] = Json::Array();
        return j;
    }

    void SaveMatchLog(Json::Value@ j) {
        string fileName = j['logName'];
        auto path = IO::FromStorageFolder(fileName);
        print("Writing file: " + path);
        Json::ToFile(path, j);
    }
}

Json::Value@ GetMostRecentMapIfCurrentOrAddNew(Json::Value@ j) {
    auto maps = j['maps'];
    if (maps.Length == 0 || currMapUid != maps[maps.Length - 1]['uid']) {
        maps.Add(NewMatchMap());
    }
    return maps[maps.Length - 1];
}

Json::Value@ NewMatchMap() {
    auto j = Json::Object();
    j['uid'] = currMapUid;
    j['name'] = currMapName;
    j['rounds'] = Json::Array();
    return j;
}
