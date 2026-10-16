local SC, UI = SoloCompass, SoloCompass.UI
local saved=SoloCompassCharDB
local count=0
local function test(name,fn) fn(); count=count+1; print("PASS " .. name) end
test("existing characters keep choices and open Ideas without onboarding",function()
    SoloCompassCharDB={minutes=60,interests={quests=false,pvp=true},showOnLogin=false}
    SC:InitializeDB(); SC:RefreshSuggestions(); UI:Show()
    assert(SoloCompassCharDB.onboardingComplete and SoloCompassCharDB.minutes==60)
    assert(SoloCompassCharDB.interests.pvp and not SoloCompassCharDB.interests.quests and not SoloCompassCharDB.showOnLogin)
    assert(UI.activeTab=="ideas" and UI.ideas:IsShown() and not UI.interests:IsShown())
end)
test("fresh characters start with a welcome and explicit interest choices",function()
    SoloCompassCharDB=nil; SC:InitializeDB(); SC:RefreshSuggestions(); UI:Show()
    assert(not SoloCompassCharDB.onboardingComplete and UI.activeTab=="interests")
    assert(UI.interests:IsShown() and not UI.ideas:IsShown() and UI.interestsTitle.textValue:find("Welcome"))
    for _,category in ipairs(SC.Data.Categories) do assert(not SoloCompassCharDB.interests[category.key]) end
    local history=SoloCompassCharDB.historyClock; UI:Show(); assert(SoloCompassCharDB.historyClock==history)
    UI:SelectTab("ideas"); assert(UI.activeTab=="interests")
    assert(not UI:FinishInterests() and UI.activeTab=="interests")
    local quests=UI.interestChecks.quests; quests:SetChecked(true); quests.scripts.OnClick(quests)
    assert(UI:FinishInterests() and SoloCompassCharDB.onboardingComplete and UI.activeTab=="ideas")
    assert(UI.ideas:IsShown() and not UI.interests:IsShown() and SoloCompassCharDB.interests.quests)
end)
test("unfinished onboarding resumes without wiping selections",function()
    SoloCompassCharDB=nil; SC:InitializeDB(); SoloCompassCharDB.interests.archaeology=true
    SC:InitializeDB(); SC:RefreshSuggestions(); UI:Show()
    assert(not SoloCompassCharDB.onboardingComplete and UI.activeTab=="interests")
    assert(UI.interestChecks.archaeology:GetChecked())
    UI:FinishInterests(); UI:Hide(); UI:Show(); assert(UI.activeTab=="ideas")
end)
test("tabs are exclusive and switching does not clear the current goal",function()
    SoloCompassCharDB.interests={quests=true}; SoloCompassCharDB.minutes=30
    SC:RefreshSuggestions(); local quest
    for _,s in ipairs(SC.candidates) do if s.id=="quest:12" then quest=s end end
    assert(quest)
    C_QuestLog.GetQuestObjectives=function() return {{text="A small objective: 0/3",finished=false}} end
    SC:SetGoal(quest); UI:Show()
    assert(UI.activeTab=="ideas" and UI.goalTitle.textValue==quest.title)
    assert(UI.goalObjectives[1].textValue:find("0/3") and UI.goalObjectives[1]:IsShown())
    UI:SelectTab("interests"); assert(UI.interests:IsShown() and not UI.ideas:IsShown())
    UI:SelectTab("preferences"); assert(UI.preferences:IsShown() and not UI.interests:IsShown() and not UI.ideas:IsShown())
    UI:SelectTab("ideas"); assert(not UI.preferences:IsShown() and not UI.interests:IsShown() and UI.ideas:IsShown())
    C_QuestLog.GetQuestObjectives=function() return {{text="A small objective: 2/3",finished=false}} end
    SC:RefreshSuggestions(); UI:PopulateCards(); assert(UI.goalObjectives[1].textValue:find("2/3"))
    assert(SC.goal and SC.goal.id==quest.id)
    SC:ClearGoal(); C_QuestLog.GetQuestObjectives=nil
end)
test("repeated tab switches reuse frames and Settings opens Preferences",function()
    local checks=UI.interestSlots
    for _=1,20 do UI:SelectTab("ideas"); UI:SelectTab("interests"); UI:ShowPreferences() end
    assert(UI.interestSlots==checks and #checks==#SC.Data.Categories)
    SlashCmdList.SOLOCOMPASS("settings"); assert(UI.activeTab=="preferences")
    UI:Hide(); UI:Show(); assert(UI.activeTab=="ideas")
end)
SC:ClearGoal(); UI:Hide(); SoloCompassCharDB=saved; SC:InitializeDB(); SC:RefreshSuggestions()
print(count .. " tab and onboarding tests passed")
