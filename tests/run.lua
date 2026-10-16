-- Run from the repository root with Lua 5.1+, or tests/run.py with lupa installed.
unpack = unpack or table.unpack
tinsert = table.insert
SlashCmdList, UISpecialFrames = {}, {}
local frames, timers, calls = {}, {}, {}
local methods = {}
local function widget(kind, name, parent)
    local w = { id = #frames + 1, kind = kind, name = name, parent = parent, shown = true, scripts = {}, points = {}, width = 100, height = 20 }
    setmetatable(w, { __index = methods }); frames[#frames + 1] = w
    return w
end
function methods:SetSize(w, h) self.width, self.height = w, h end
function methods:SetWidth(w) self.width = w end
function methods:SetHeight(h) self.height = h end
function methods:GetWidth() return self.width end
function methods:GetHeight() return self.height end
function methods:SetPoint(...) self.points[#self.points + 1] = { ... } end
function methods:GetPoint() return "CENTER", UIParent, "CENTER", 0, 0 end
function methods:ClearAllPoints() self.points = {} end
function methods:SetAllPoints() self.allPoints = true end
function methods:SetScript(event, fn) self.scripts[event] = fn end
function methods:CreateFontString(name, layer, template)
    local fs = widget("FontString", name, self); fs.template = template; return fs
end
function methods:CreateTexture(name, layer) return widget("Texture", name, self) end
function methods:SetText(text) self.textValue = text end
function methods:SetTexture(texture) self.texture = texture end
function methods:SetAtlas(atlas) self.atlas = atlas end
function methods:SetColorTexture(...) self.color = { ... } end
function methods:SetBackdropColor(...) self.background = { ... } end
function methods:SetTextColor(...) self.textColor = { ... } end
function methods:SetChecked(checked) self.checked = checked end
function methods:GetChecked() return self.checked end
function methods:IsShown() return self.shown end
function methods:Show() self.shown = true end
function methods:Hide() self.shown = false end
function methods:SetShown(shown) self.shown = shown end
function methods:GetFrameLevel() return 1 end
for _, method in ipairs({ "RegisterEvent", "SetBackdrop", "SetBackdropBorderColor", "SetFontObject",
    "SetJustifyH", "SetJustifyV", "SetWordWrap", "SetTexCoord", "SetScale", "SetClampedToScreen", "SetFrameStrata",
    "SetFrameLevel", "SetMovable", "EnableMouse", "RegisterForDrag", "StartMoving", "StopMovingOrSizing" }) do
    methods[method] = function() end
end
function CreateFrame(kind, name, parent, template)
    local f = widget(kind, name, parent)
    if name then _G[name] = f end
    if template == "UICheckButtonTemplate" then
        f.text = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        f.text:SetWidth(170); f.text:SetPoint("LEFT", f, "RIGHT", 2, 0)
    end
    return f
end
UIParent = widget("Frame", "UIParent"); UIParent:SetSize(1920, 1080)
C_Timer = { After = function(_, fn) timers[#timers + 1] = fn end }
local combat, level, locked = false, 90, {}
function InCombatLockdown() return combat end
function UnitLevel() return level end
function GetMaxLevelForLatestExpansion() return 90 end
function GetNumSavedInstances() return #locked end
function GetSavedInstanceInfo(i)
    local e = locked[i]; return "Raid", 1, e.reset or 3600, e.difficulty or 3, e.locked ~= false,
        false, 0, true, 10, "Normal", 1, 1, false, e.id
end
function RequestRaidInfo() end
local quests = {
    { isHeader = true, title = "Old adventures" },
    { questID = 11, title = "A ready quest", level = 80, frequency = 0 },
    { questID = 12, title = "One unfinished story", level = 80, frequency = 0 },
    { questID = 13, title = "A daily", frequency = 1 },
    { questID = 14, title = "A group quest", frequency = 0, suggestedGroup = 5 },
}
local completed, ownedMounts, ownedPets, ownedToys = {}, {}, {}, {}
C_QuestLog = {
    GetNumQuestLogEntries = function() return #quests end,
    GetInfo = function(i) return quests[i] end,
    IsComplete = function(id) return id == 11 end,
    IsQuestFlaggedCompleted = function(id) return completed[id] or false end,
    GetLogIndexForQuestID = function(id) for i, q in ipairs(quests) do if q.questID == id then return i end end end,
    AddQuestWatch = function(id) calls.quest = id end,
}
C_SuperTrack = { SetSuperTrackedQuestID = function(id) calls.tracked = id end }
function QuestMapFrame_OpenToQuestDetails(id) calls.details = id end
C_MountJournal = {
    GetMountFromItem = function(id) return id end,
    GetMountInfoByID = function(id)
        local names = { [13335] = "Rivendare's Deathcharger", [32768] = "Raven Lord", [32458] = "Ashes of Al'ar", [30480] = "Fiery Warhorse" }
        return names[id] or "Mount " .. id, 1, "mount-icon", false, true, 1, false, false, nil, false, ownedMounts[id] or false
    end,
    SetSearch = function(name) calls.mountSearch = name end,
}
C_PetJournal = {
    GetPetInfoBySpeciesID = function(id) return "Pet " .. id, "pet-icon", 1, 1, "Vendor: Example vendor", "Description", false, true, true, false, true end,
    GetNumCollectedInfo = function(id) return ownedPets[id] and 1 or 0 end,
    SetSearchFilter = function(name) calls.petSearch = name end,
}
function PlayerHasToy(id) return ownedToys[id] or false end
C_ToyBox = { SetFilterString = function(name) calls.toySearch = name end }
WorldMapFrame = widget("Frame", "WorldMapFrame")
function WorldMapFrame:SetMapID(id) calls.map = id end
function ShowUIPanel(frame) frame:Show() end
CollectionsJournal = widget("Frame", "CollectionsJournal"); CollectionsJournal:Hide()
function ToggleCollectionsJournal(tab) calls.tab = tab; CollectionsJournal:Show() end
function PanelTemplates_GetSelectedTab() return calls.tab end
function PVEFrame_ShowFrame(panel, selection) calls.pve, calls.pveSelection = panel, selection end
GameTooltip = { SetOwner = function() end, SetText = function() end, AddLine = function() end, Show = function() end, Hide = function() end }
for _, file in ipairs({ "SoloCompass.lua", "Data.lua", "Suggestions.lua", "Progress.lua", "Navigation.lua", "UI.lua" }) do dofile(file) end
local SC, SS = SoloCompass, SoloCompass.Suggestions
local passes = 0
local function test(name, fn)
    fn(); passes = passes + 1; print("PASS " .. name)
end
local function has(items, id) for _, s in ipairs(items) do if s.id == id then return true end end return false end
test("migrate old preferences and preserve false values", function()
    SoloCompassCharDB = { enabled = false, interests = { collector = false, quests = false, housing = true } }
    SC:InitializeDB()
    assert(not SoloCompassCharDB.interests.mounts and not SoloCompassCharDB.interests.pets and not SoloCompassCharDB.interests.toys)
    assert(not SoloCompassCharDB.showOnLogin and not SoloCompassCharDB.interests.quests)
    assert(SoloCompassCharDB.interests.housing)
end)
test("defaults do not alias across database initialization", function()
    SoloCompassCharDB = nil; SC:InitializeDB(); SoloCompassCharDB.interests.mounts = true
    SoloCompassCharDB = nil; SC:InitializeDB(); assert(not SoloCompassCharDB.interests.mounts)
end)
test("three diverse ideas with ready quest first", function()
    SoloCompassCharDB.interests={quests=true,mounts=true,pets=true,toys=true,raids=true,delves=true}
    SoloCompassCharDB.onboardingComplete=true
    local list = SS:Build(); assert(#list == 3 and list[1].id == "quest:11")
    assert(list[1].category ~= list[2].category and list[2].category ~= list[3].category)
    local _, all = SS:Build(); assert(not has(all, "quest:13") and not has(all, "quest:14"))
end)
test("fifteen minute budget excludes longer activities", function()
    SoloCompassCharDB.minutes = 15
    local list = SS:Build(); for _, s in ipairs(list) do assert(s.minutes <= 15) end
    assert(has(list, "quest:11")); SoloCompassCharDB.minutes = 30
end)
test("owned collections and locked raids are removed", function()
    ownedMounts[32458], ownedPets[39], ownedToys[86589] = true, true, true
    locked = { { id = 532 }, { id = 556, difficulty = 2 } }
    local _, all = SS:Build()
    for _, id in ipairs({ "mount:32458", "pet:39", "toy:86589", "raid:532", "mount:30480", "mount:32768" }) do assert(not has(all, id), id) end
    ownedMounts, ownedPets, ownedToys, locked = {}, {}, {}, {}
end)
test("expired or unrelated difficulty lockout does not block heroic dungeon", function()
    locked = { { id = 556, difficulty = 1 }, { id = 532, reset = 0 } }
    local _, all = SS:Build(); assert(has(all, "mount:32768") and has(all, "raid:532")); locked = {}
end)
test("skip and rotation change the shortlist", function()
    local before = SS:Build(); SC.skipped[before[1].id] = true
    local after = SS:Build(); assert(not has(after, before[1].id))
    SC.skipped = {}; SC.rotation = 1; local rotated = SS:Build(); assert(rotated[1].id ~= before[1].id); SC.rotation = 0
end)
test("empty interests and low-level characters", function()
    local saved = SoloCompassCharDB.interests; SoloCompassCharDB.interests = {}
    assert(#SS:Build() == 0); SoloCompassCharDB.interests = saved
    level = 20; local _, all = SS:Build(); assert(not has(all, "activity:delve") and not has(all, "raid:532")); level = 90
end)
test("goal persists across filters then clears on verified completion", function()
    SC.UI:Show(); local suggestion = SS:Build()[1]; SC:SetGoal(suggestion)
    SoloCompassCharDB.interests.quests = false; SC:RefreshSuggestions(); assert(SC.goal.id == suggestion.id)
    completed[11] = true; table.remove(quests, 2); SC:RefreshSuggestions(); assert(SoloCompassCharDB.goalID == nil)
    SoloCompassCharDB.interests.quests = true
end)
test("refresh reuses dashboard cards and preferences", function()
    SC:RefreshSuggestions(); SC.UI:Show(); SC.UI:ShowPreferences()
    local count = #frames
    for _ = 1, 30 do SC:RefreshSuggestions(); SC.UI:PopulateCards(); SC.UI:ShowPreferences() end
    assert(#frames == count); SC.UI.preferences:Hide()
end)
test("clicks open correct game panel and respect combat", function()
    SC.UI:HandleCardClick({ action = "quest", targetID = 12 }); assert(calls.quest == 12 and calls.details == 12)
    SC.UI:HandleCardClick({ action = "mount", title = "Mount" }); assert(calls.tab == 1 and calls.mountSearch == "Mount")
    SC.UI:HandleCardClick({ action = "pet", title = "Pet" }); assert(calls.tab == 2 and calls.petSearch == "Pet")
    SC.UI:HandleCardClick({ action = "toy", title = "Toy" }); assert(calls.tab == 3 and calls.toySearch == "Toy")
    SC.UI:HandleCardClick({ action = "map", mapID = 42 }); assert(calls.map == 42)
    SC.UI:HandleCardClick({ action = "lfr" }); assert(calls.pve == "GroupFinderFrame" and calls.pveSelection == "RaidFinderFrame")
    combat = true; SC.UI:HandleCardClick({ action = "map", mapID = 99 }); assert(calls.map == 42); combat = false
end)
test("event refresh is debounced", function()
    timers = {}; SC:ScheduleRefresh(); SC:ScheduleRefresh(); assert(#timers == 1); timers[1](); assert(not SC.refreshPending)
end)
test("missing collection data is not treated as a missing collectible", function()
    local mountInfo, petInfo = C_MountJournal.GetMountInfoByID, C_PetJournal.GetPetInfoBySpeciesID
    C_MountJournal.GetMountInfoByID = function() end; C_PetJournal.GetPetInfoBySpeciesID = function() end
    local _, all = SS:Build()
    for _, s in ipairs(all) do assert(s.category ~= "mounts" and s.category ~= "pets") end
    C_MountJournal.GetMountInfoByID, C_PetJournal.GetPetInfoBySpeciesID = mountInfo, petInfo
end)
test("active historical completion stays selected until a real turn-in", function()
    local list = SS:Build(); local quest
    for _, s in ipairs(list) do if s.id == "quest:12" then quest = s end end
    assert(quest); completed[12] = true; SC:SetGoal(quest); SC:RefreshSuggestions()
    assert(SC.goal and SC.goal.id == "quest:12")
    for _, f in ipairs(frames) do if f.scripts.OnEvent then f.scripts.OnEvent(f,"QUEST_TURNED_IN",12); break end end
    timers[#timers](); assert(SoloCompassCharDB.goalID == nil and SC.goal == nil)
    completed[12] = nil; SC.justTurnedIn[12] = nil
end)
test("duplicate quest log entries never duplicate cards at any rotation", function()
    quests[#quests + 1] = quests[2]
    local complete = C_QuestLog.IsComplete
    C_QuestLog.IsComplete = function() return true end
    local saved = SoloCompassCharDB.interests
    SoloCompassCharDB.interests = { quests=true, housing=true }; SoloCompassCharDB.minutes = 15
    for rotation = 0, 8 do
        SC.rotation = rotation
        local list = SS:Build(); local seen = {}; assert(#list == 2)
        for _, s in ipairs(list) do assert(not seen[s.id]); seen[s.id] = true end
    end
    table.remove(quests); C_QuestLog.IsComplete = complete
    SC.rotation = 0; SoloCompassCharDB.minutes = 30; SoloCompassCharDB.interests = saved
end)
test("dismissals survive initialization, expire, and can be restored", function()
    local now = 1000; GetServerTime = function() return now end
    local s = {id="mount:32768"}
    SC:Skip(s, "day"); assert(SC:IsDismissed(s.id))
    SC:InitializeDB(); assert(SC:IsDismissed(s.id))
    now = now + 86401; assert(not SC:IsDismissed(s.id))
    SC:Skip(s, "forever"); now = now + 999999; assert(SC:IsDismissed(s.id))
    SoloCompassCharDB.dismissals = {}; assert(not SC:IsDismissed(s.id))
end)
test("recent history favors unseen mounts and persists without refresh churn", function()
    SC:ClearGoal(); SC.skipped = {}; SC.rotation = 0
    local saved = SoloCompassCharDB.interests; SoloCompassCharDB.interests = {mounts=true}
    SC:RefreshSuggestions(); local first = SC.currentSuggestions[1].id
    SC:RememberShown(); SC:RefreshSuggestions(); assert(SC.currentSuggestions[1].id == first)
    SC:InitializeDB(); SC:RefreshSuggestions(); assert(SC.currentSuggestions[1].id ~= first)
    SoloCompassCharDB.interests = saved; SoloCompassCharDB.history = {}; SC.historyBaseline = {}
end)
test("live quest destinations and themed icons explain proximity", function()
    C_QuestLog.GetNextWaypoint = function() return 2022, 0.3, 0.4 end
    C_QuestLog.GetDistanceSqToQuest = function() return 10000 end
    C_QuestLog.GetQuestDetailsTheme = function() return {poiIcon="test-quest-theme"} end
    local _, all = SS:Build(); local quest
    for _, s in ipairs(all) do if s.id == "quest:12" then quest = s end end
    assert(quest and quest.atlas == "test-quest-theme" and quest.reason:find("500 yards"))
    local map, x, y = SC.Navigation:Destination(quest); assert(map == 2022 and x == 0.3 and y == 0.4)
    C_QuestLog.GetNextWaypoint, C_QuestLog.GetDistanceSqToQuest, C_QuestLog.GetQuestDetailsTheme = nil, nil, nil
end)
test("entrance navigation pins matching instances and respects combat", function()
    C_EncounterJournal = {
        GetInstanceForGameMap=function(id) assert(id == 532); return 745 end,
        GetDungeonEntrancesForMap=function() return {
            {journalInstanceID=999, position={GetXY=function() return 0.1, 0.1 end}},
            {journalInstanceID=745, position={GetXY=function() return 0.47, 0.75 end}},
        } end,
    }
    UiMapPoint = { CreateFromCoordinates=function(map, x, y) return {map=map,x=x,y=y} end }
    C_Map = {CanSetUserWaypointOnMap=function() return true end,
        SetUserWaypoint=function(point) calls.pin=point; return true end}
    C_SuperTrack.SetSuperTrackedUserWaypoint=function(value) calls.userTracked=value end
    SC.Navigation:Go({mapID=42, instanceID=532})
    assert(calls.pin.map == 42 and calls.pin.x == 0.47 and calls.userTracked)
    calls.pin=nil; combat=true; SC.Navigation:Go({mapID=42,instanceID=532}); assert(calls.pin == nil); combat=false
    C_EncounterJournal.GetDungeonEntrancesForMap=function() return {} end
    SC.Navigation:Go({mapID=42,instanceID=532}); assert(calls.pin == nil and calls.map == 42)
    C_Map, C_EncounterJournal, UiMapPoint = nil, nil, nil
end)
test("failed waypoint placement never tracks an unrelated existing pin", function()
    C_Map = {CanSetUserWaypointOnMap=function() return true end, SetUserWaypoint=function() return false end}
    UiMapPoint = {CreateFromCoordinates=function() return {} end}
    C_EncounterJournal = {GetInstanceForGameMap=function() return 1 end,
        GetDungeonEntrancesForMap=function() return {{journalInstanceID=1,position={GetXY=function() return 0.2,0.3 end}}} end}
    calls.userTracked=nil; SC.Navigation:Go({mapID=42,instanceID=532}); assert(calls.userTracked == nil)
    C_Map, C_EncounterJournal, UiMapPoint = nil, nil, nil
end)
test("compact tracker persists, moves, hides, and clears with a completed goal", function()
    SoloCompassCharDB.showTracker=true
    local _, all=SS:Build(); local quest
    for _, s in ipairs(all) do if s.id == "quest:12" then quest=s end end
    SC:SetGoal(quest); SC.UI:Hide(); assert(SC.UI.tracker:IsShown())
    SC.UI.tracker.scripts.OnDragStop(SC.UI.tracker); assert(SoloCompassCharDB.trackerPosition.point == "CENTER")
    SC:InitializeDB(); SC:RefreshSuggestions(); assert(SC.goal.id == quest.id and SC.UI.tracker:IsShown())
    SC.UI:Show(); assert(not SC.UI.tracker:IsShown())
    SC.UI.dashboard:Hide(); SC.UI.dashboard.scripts.OnHide(SC.UI.dashboard)
    assert(SC.UI.tracker:IsShown())
    SC:QuestTurnedIn(12); timers[#timers](); assert(not SC.UI.tracker:IsShown() and SC.goal == nil)
    completed[12]=nil; SC.justTurnedIn[12]=nil
end)
test("quest Track button keeps an active quest and updates visible objectives", function()
    local interests=SoloCompassCharDB.interests; SoloCompassCharDB.interests={quests=true}; SC.rotation=0
    completed[12]=true
    C_QuestLog.GetQuestObjectives=function() return {{text="Collect fragments: 1/4",finished=false},{text="Speak to the scout",finished=true}} end
    SC:RefreshSuggestions(); SC.UI:Show()
    local card=SC.UI.cards[1]; assert(card.suggestion.id=="quest:12")
    card.choose.scripts.OnClick()
    assert(SC.goal and SC.goal.id=="quest:12" and SC.UI.tracker:IsShown() and not SC.UI.dashboard:IsShown())
    assert(SC.UI.tracker.objectiveRows[1].textValue:find("1/4") and SC.UI.tracker.objectiveRows[2].textValue:find("%[x%]"))
    C_QuestLog.GetQuestObjectives=function() return {{text="Collect fragments: 2/4",finished=false}} end
    SC:ScheduleRefresh(); timers[#timers](); assert(SC.UI.tracker.objectiveRows[1].textValue:find("2/4"))
    local isComplete=C_QuestLog.IsComplete; C_QuestLog.IsComplete=function() return true end
    SC:RefreshSuggestions(); SC.UI:PopulateCards(); assert(SC.goal and SC.UI.tracker.objectiveRows[1].textValue:find("Ready to turn in"))
    SC.UI:Show(); assert(SC.UI.goalTitle.textValue==SC.goal.title)
    SC:QuestTurnedIn(12); timers[#timers](); assert(not SC.goal)
    SC.justTurnedIn[12]=nil; completed[12]=nil; C_QuestLog.IsComplete=isComplete; C_QuestLog.GetQuestObjectives=nil
    SoloCompassCharDB.interests=interests
end)
test("all categories carry visible icon data and honest timing notes", function()
    local _, all=SS:Build()
    for _, s in ipairs(all) do assert(s.icon or s.atlas); assert(s.timeNote and #s.timeNote > 10) end
    SC:RefreshSuggestions(); SC.UI:Show()
    for _, card in ipairs(SC.UI.cards) do
        if card.suggestion then
            assert(card.icon.shown and card.navigate and card.open and card.choose and card.skip)
            for _, action in ipairs({card.navigate,card.open,card.choose,card.skip}) do
                action.scripts.OnEnter(action); action.scripts.OnLeave(action)
            end
        end
    end
    local card=SC.UI.cards[1]; SC.UI:ShowDismissals(card); assert(SC.UI.dismissals:IsShown())
    SC.UI:ShowDismissals(card); assert(not SC.UI.dismissals:IsShown())
end)
print(passes .. " scenario tests passed")
-- Expose actual constructed UI objects to the optional layout renderer.
TEST_FRAMES = frames
