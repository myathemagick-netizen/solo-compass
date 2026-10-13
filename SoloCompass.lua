-- Solo Compass: choose one useful thing to do next.
SoloCompass = {}
local SC = SoloCompass
SC.skipped, SC.rotation = {}, 0
local defaults = {
    enabled = true, showOnLogin = true, minutes = 30,
    interests = { quests = true, mounts = true, pets = true, toys = true,
        raids = true, delves = true, lfr = false, housing = false },
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
    if type(SoloCompassCharDB) ~= "table" then SoloCompassCharDB = {} end
    local db = SoloCompassCharDB
    if type(db.interests) == "table" and db.interests.collector ~= nil then
        for _, key in ipairs({ "mounts", "pets", "toys" }) do
            if db.interests[key] == nil then db.interests[key] = db.interests.collector end
        end
    end
    if db.showOnLogin == nil and db.enabled ~= nil then db.showOnLogin = db.enabled end
    fillDefaults(db, defaults)
    if db.minutes ~= 15 and db.minutes ~= 30 and db.minutes ~= 60 then db.minutes = 30 end
    SoloCompassDB.version = 2
end
function SC:RefreshSuggestions()
    if SoloCompassCharDB.goalID and self.Suggestions:IsGoalFinished(SoloCompassCharDB.goalID) then
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
end
function SC:SetGoal(suggestion)
    SoloCompassCharDB.goalID = suggestion.id
    local snapshot = {}
    for _, key in ipairs({ "id", "title", "detail", "category", "minutes", "action", "targetID", "mapID", "icon" }) do
        snapshot[key] = suggestion[key]
    end
    SoloCompassCharDB.goalSnapshot = snapshot
    self:RefreshSuggestions(); self.UI:PopulateCards()
end
function SC:ClearGoal()
    SoloCompassCharDB.goalID, SoloCompassCharDB.goalSnapshot = nil, nil
    self:RefreshSuggestions(); self.UI:PopulateCards()
end
function SC:Skip(suggestion)
    self.skipped[suggestion.id] = true
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
        if self.UI.dashboard and self.UI.dashboard:IsShown() then
            self:RefreshSuggestions(); self.UI:PopulateCards()
        end
    end)
end
local events = CreateFrame("Frame")
for _, event in ipairs({ "ADDON_LOADED", "PLAYER_LOGIN", "QUEST_LOG_UPDATE", "UPDATE_INSTANCE_INFO",
    "NEW_MOUNT_ADDED", "PET_JOURNAL_LIST_UPDATE", "NEW_TOY_ADDED", "ZONE_CHANGED_NEW_AREA", "PLAYER_REGEN_ENABLED" }) do
    events:RegisterEvent(event)
end
events:SetScript("OnEvent", function(_, event, addonName)
    if event == "ADDON_LOADED" then
        if addonName == "SoloCompass" then SC:InitializeDB() end
    elseif event == "PLAYER_LOGIN" then
        SC.Minimap:Init()
        if RequestRaidInfo then RequestRaidInfo() end
        if SoloCompassCharDB.enabled and SoloCompassCharDB.showOnLogin then
            if InCombatLockdown() then SC.pendingLogin = true else SC:RefreshSuggestions(); SC.UI:Show() end
        end
    elseif event == "PLAYER_REGEN_ENABLED" and SC.pendingLogin then
        SC.pendingLogin = nil; SC:RefreshSuggestions(); SC.UI:Show()
    elseif SoloCompassCharDB then SC:ScheduleRefresh() end
end)
SLASH_SOLOCOMPASS1, SLASH_SOLOCOMPASS2 = "/solocompass", "/sc"
SlashCmdList.SOLOCOMPASS = function(message)
    if message and message:lower():match("^%s*settings%s*$") then
        SC:RefreshSuggestions(); SC.UI:Show(); SC.UI:ShowPreferences()
    else SC:Toggle() end
end
