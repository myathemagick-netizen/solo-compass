-- Solo Compass: choose one useful thing to do next.
SoloCompass = {}
local SC = SoloCompass
SC.skipped, SC.rotation, SC.justTurnedIn = {}, 0, {}
local defaults = {
    enabled = true, showOnLogin = true, minutes = 30, showTracker = true,
    dismissals = {}, history = {}, historyClock = 0,
    interests = { quests = true, mounts = true, pets = true, toys = true,
        raids = true, delves = true, lfr = false, housing = false,
        timewalking = false, transmog = false, professions = false, archaeology = false,
        achievements = false, pvp = false, heirlooms = false, campsites = false,
        reputation = false, artifacts = false },
    artifactAppearances = {},
}
local function fillDefaults(target, source)
    for key, value in pairs(source) do
        if type(value) == "table" then
            if type(target[key]) ~= "table" then target[key] = {} end
            fillDefaults(target[key], value)
        elseif target[key] == nil then target[key] = value end
    end
end
function SC:InitializeDB()
    if type(SoloCompassDB) ~= "table" then SoloCompassDB = {} end
    fillDefaults(SoloCompassDB, { version = 2, minimap = { hide = false } })
    local newCharacter = type(SoloCompassCharDB) ~= "table" or next(SoloCompassCharDB) == nil
    if type(SoloCompassCharDB) ~= "table" then SoloCompassCharDB = {} end
    local db = SoloCompassCharDB
    if type(db.interests) == "table" and db.interests.collector ~= nil then
        for _, key in ipairs({ "mounts", "pets", "toys" }) do
            if db.interests[key] == nil then db.interests[key] = db.interests.collector end
        end
    end
    if db.showOnLogin == nil and db.enabled ~= nil then db.showOnLogin = db.enabled end
    fillDefaults(db, defaults)
    if db.onboardingComplete == nil then db.onboardingComplete = not newCharacter end
    if newCharacter then
        for key in pairs(db.interests) do db.interests[key] = false end
    end
    self.historyBaseline = {}
    for id, stamp in pairs(db.history) do self.historyBaseline[id] = stamp end
    if db.minutes ~= 15 and db.minutes ~= 30 and db.minutes ~= 60 then db.minutes = 30 end
    SoloCompassDB.version = 2
end
function SC:RefreshSuggestions()
    if SoloCompassCharDB.goalID and self.Suggestions:IsGoalFinished(SoloCompassCharDB.goalID) then
        local finished = SoloCompassCharDB.goalSnapshot
        if finished and finished.title then print("|cffe8bb64Solo Compass:|r Goal reached: " .. finished.title) end
        SoloCompassCharDB.goalID, SoloCompassCharDB.goalSnapshot = nil, nil
    end
    self.currentSuggestions, self.candidates = self.Suggestions:Build()
    local goalID = SoloCompassCharDB.goalID
    self.goal = nil
    for _, candidate in ipairs(self.candidates) do
        if candidate.id == goalID then self.goal = candidate; break end
    end
    if goalID and not self.goal then
        if self.Suggestions:IsGoalFinished(goalID) then
            SoloCompassCharDB.goalID, SoloCompassCharDB.goalSnapshot = nil, nil
        else self.goal = SoloCompassCharDB.goalSnapshot end
    end
    -- Refreshing a chosen milestone must not move its target forward.
    if goalID and self.goal and SoloCompassCharDB.goalSnapshot and SoloCompassCharDB.goalSnapshot.progressTarget then
        self.goal = SoloCompassCharDB.goalSnapshot
    end
    if self.UI.UpdateTracker then self.UI:UpdateTracker() end
end
function SC:SetGoal(suggestion)
    if suggestion.action=="reputation" and C_Reputation and C_Reputation.SetWatchedFactionByID and not InCombatLockdown() then
        C_Reputation.SetWatchedFactionByID(suggestion.targetID)
    end
    SoloCompassCharDB.goalID = suggestion.id
    local snapshot = {}
    for _, key in ipairs({ "id", "title", "detail", "reason", "category", "minutes", "action", "targetID", "mapID", "mapX", "mapY", "icon", "atlas", "instanceID", "destinationName", "timeNote", "progressTarget", "progressStart", "houseGUID", "targetPetID", "searchName", "progressKind", "stepLabel", "initiativeID", "cycleID", "neighborhoodGUID" }) do
        snapshot[key] = suggestion[key]
    end
    SoloCompassCharDB.goalSnapshot = snapshot
    self:RefreshSuggestions(); self.UI:PopulateCards()
end
function SC:ClearGoal()
    SoloCompassCharDB.goalID, SoloCompassCharDB.goalSnapshot = nil, nil
    self:RefreshSuggestions(); self.UI:PopulateCards()
end
function SC:Now() return GetServerTime and GetServerTime() or time() end
function SC:IsDismissed(id)
    local untilTime = SoloCompassCharDB.dismissals[id]
    if untilTime == true then return true end
    if type(untilTime) == "number" then
        if untilTime > self:Now() then return true end
        SoloCompassCharDB.dismissals[id] = nil
    end
    return self.skipped[id] == true
end
function SC:Skip(suggestion, duration)
    if duration == "forever" then SoloCompassCharDB.dismissals[suggestion.id] = true
    elseif duration == "day" then SoloCompassCharDB.dismissals[suggestion.id] = self:Now() + 86400
    else self.skipped[suggestion.id] = true end
    self:RefreshSuggestions(); self.UI:PopulateCards()
end
function SC:RememberShown()
    local db = SoloCompassCharDB
    db.historyClock = db.historyClock + 1
    for _, s in ipairs(self.currentSuggestions or {}) do db.history[s.id] = db.historyClock end
    -- Keep saved history bounded as quests come and go.
    for id, stamp in pairs(db.history) do
        if stamp < db.historyClock - 200 then db.history[id] = nil end
    end
end
function SC:OtherIdeas()
    self:RememberShown()
    for id, stamp in pairs(SoloCompassCharDB.history) do self.historyBaseline[id] = stamp end
    self.rotation = self.rotation + 1
    self:RefreshSuggestions(); self.UI:PopulateCards()
end
function SC:Toggle()
    if self.UI.dashboard and self.UI.dashboard:IsShown() then self.UI:Hide()
    else self:RefreshSuggestions(); self.UI:Show() end
end
function SC:ScheduleRefresh()
    if self.refreshPending then return end
    self.refreshPending = true
    C_Timer.After(0.3, function()
        self.refreshPending = nil
        if SoloCompassCharDB.goalID or (self.UI.dashboard and self.UI.dashboard:IsShown()) then
            self:RefreshSuggestions(); self.UI:PopulateCards()
        end
    end)
end
function SC:QuestTurnedIn(questID)
    self.justTurnedIn[questID] = true
    self:ScheduleRefresh()
end
local events = CreateFrame("Frame")
for _, event in ipairs({ "ADDON_LOADED", "PLAYER_LOGIN", "QUEST_LOG_UPDATE", "UPDATE_INSTANCE_INFO",
    "NEW_MOUNT_ADDED", "PET_JOURNAL_LIST_UPDATE", "PET_BATTLE_LEVEL_CHANGED", "PET_JOURNAL_PET_DELETED", "NEW_TOY_ADDED", "TOYS_UPDATED", "CURRENCY_DISPLAY_UPDATE", "AREA_POIS_UPDATED", "ZONE_CHANGED_NEW_AREA", "PLAYER_REGEN_ENABLED",
    "LFG_UPDATE_RANDOM_INFO", "LFG_LOCK_INFO_RECEIVED", "SKILL_LINES_CHANGED", "TRADE_SKILL_LIST_UPDATE", "TRADE_SKILL_SHOW", "TRADE_SKILL_CLOSE", "UNIT_SPELLCAST_SUCCEEDED", "RESEARCH_ARTIFACT_DIG_SITE_UPDATED",
    "ACHIEVEMENT_EARNED", "CRITERIA_UPDATE", "UPDATE_FACTION", "TRANSMOG_COLLECTION_UPDATED",
    "HEIRLOOMS_UPDATED", "NEW_WARBAND_SCENE_ADDED", "ARTIFACT_UPDATE",
    "RESEARCH_ARTIFACT_UPDATE", "RESEARCH_ARTIFACT_COMPLETE", "MAJOR_FACTION_RENOWN_LEVEL_CHANGED",
    "QUEST_TURNED_IN", "QUEST_ACCEPTED", "NEIGHBORHOOD_INITIATIVE_UPDATED", "INITIATIVE_TASK_COMPLETED",
    "PLAYER_HOUSE_LIST_UPDATED", "HOUSE_LEVEL_FAVOR_UPDATED", "HOUSE_LEVEL_CHANGED", "INITIATIVE_TASKS_TRACKED_UPDATED" }) do
    events:RegisterEvent(event)
end
events:SetScript("OnEvent", function(_, event, addonName, arg2, arg3)
    if event=="UNIT_SPELLCAST_SUCCEEDED" and (not SoloCompassCharDB or not SoloCompassCharDB.goalSnapshot or SoloCompassCharDB.goalSnapshot.action~="decorrecipe") then return end
    if event == "ADDON_LOADED" then
        if addonName == "SoloCompass" then SC:InitializeDB() end
    elseif event == "PLAYER_LOGIN" then
        SC.Minimap:Init()
        SC:RefreshSuggestions()
        if RequestRaidInfo then RequestRaidInfo() end
        if SoloCompassCharDB.enabled and SoloCompassCharDB.showOnLogin then
            if InCombatLockdown() then SC.pendingLogin = true else SC:RefreshSuggestions(); SC.UI:Show() end
        end
    elseif event == "QUEST_TURNED_IN" and SoloCompassCharDB then SC:QuestTurnedIn(addonName)
    elseif event == "QUEST_ACCEPTED" and SoloCompassCharDB then
        SC.justTurnedIn[addonName] = nil; SC:ScheduleRefresh()
    elseif event == "PLAYER_REGEN_ENABLED" and SC.pendingLogin then
        SC.pendingLogin = nil; SC:RefreshSuggestions(); SC.UI:Show()
    elseif SoloCompassCharDB then
        if SC.Progress then SC.Progress:OnEvent(event, addonName, arg2, arg3) end
        SC:ScheduleRefresh()
    end
end)
SLASH_SOLOCOMPASS1, SLASH_SOLOCOMPASS2 = "/solocompass", "/sc"
SlashCmdList.SOLOCOMPASS = function(message)
    if message and message:lower():match("^%s*settings%s*$") then
        SC:RefreshSuggestions(); SC.UI:Show(); SC.UI:ShowPreferences()
    else SC:Toggle() end
end
