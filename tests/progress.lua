local SC, P = SoloCompass, SoloCompass.Progress
local count = 0
local function test(name, fn) fn(); count=count+1; print("PASS " .. name) end
local function collect(method)
    local items={}; P[method](P,function(s) items[#items+1]=s end); return items
end
local originalInterests, originalMinutes = SoloCompassCharDB.interests, SoloCompassCharDB.minutes
local originalAfter, originalNow = C_Timer.After, GetServerTime
local pending, clock = {}, 2000000
C_Timer.After=function(_,fn) pending[#pending+1]=fn end
GetServerTime=function() return clock end
local function drain()
    local iterations=0
    while #pending > 0 do
        local fn=table.remove(pending,1); fn(); iterations=iterations+1
        assert(iterations<2000,"timer loop")
    end
end
local function only(category, minutes)
    SC:ClearGoal(); SC.UI:Hide(); SoloCompassCharDB.interests={[category]=true}
    SoloCompassCharDB.minutes=minutes or 30; SC.rotation=0; SC.skipped={}; SoloCompassCharDB.dismissals={}
    P.status={}; P.caches={}; drain()
end
test("LFR offers a named wing at 30 minutes with real eligibility and gear context", function()
    only("lfr")
    GetNumRFDungeons=function() return 2 end
    GetRFDungeonInfo=function(i) return i==1 and 100 or 99, i==1 and "Current wing" or "Old wing" end
    GetLFGDungeonInfo=function(id)
        local info={}; info[1]="Wing"; info[9]=id==100 and 11 or 9; info[11]="wing-icon"; info[20]=160
        return unpack(info,1,22)
    end
    IsLFGDungeonJoinable=function() return true,true,false end
    GetLFGDungeonNumEncounters=function() return 2 end
    GetLFGDungeonEncounterInfo=function(_,i) return "Boss",0,i==1 end
    GetAverageItemLevel=function() return 180,170 end
    local list=SC.Suggestions:Build()
    assert(#list==1 and list[1].id=="lfr:100" and list[1].minutes==30)
    assert(list[1].detail:find("170") and list[1].detail:find("160") and list[1].detail:find("1/2"))
    assert(list[1].timeLabel:find("QUEUE") and list[1].reason:find("not evaluated"))
end)
test("LFR offers preparation at 15 minutes and for locked requirements", function()
    SoloCompassCharDB.minutes=15; local list=SC.Suggestions:Build()
    assert(#list==1 and list[1].title:find("Prepare"))
    SoloCompassCharDB.minutes=30; IsLFGDungeonJoinable=function() return false,true,false end
    list=SC.Suggestions:Build(); assert(#list==1 and list[1].minutes==15)
    IsLFGDungeonJoinable=function() return true,true,false end
end)
test("under-level characters receive a leveling step instead of raid wings", function()
    local oldLevel,oldInfo=UnitLevel,GetLFGDungeonInfo
    UnitLevel=function() return 84 end
    GetLFGDungeonInfo=function(id)
        local values={oldInfo(id)}; values[4]=90; return unpack(values,1,22)
    end
    for _,minutes in ipairs({15,30,60}) do
        SoloCompassCharDB.minutes=minutes
        local list=SC.Suggestions:Build()
        assert(#list==1 and list[1].id=="prepare:lfrlevel" and list[1].action=="questlog")
        assert(list[1].detail:find("84") and list[1].detail:find("90"))
    end
    UnitLevel=function() return 90 end
    SoloCompassCharDB.minutes=30
    local list=SC.Suggestions:Build(); assert(#list==1 and list[1].id=="lfr:100")
    UnitLevel,GetLFGDungeonInfo=oldLevel,oldInfo
end)

test("fully looted LFR wings disappear and complete their tracked goal", function()
    local s=SC.Suggestions:Build()[1]; SC:SetGoal(s)
    GetLFGDungeonEncounterInfo=function() return "Boss",0,true end
    SC:RefreshSuggestions(); assert(not SC.goal and #SC.currentSuggestions==0)
    GetNumRFDungeons=function() return 0 end
    local list=SC.Suggestions:Build(); assert(list[1].id=="prepare:lfr")
    GetNumRFDungeons, GetRFDungeonInfo, GetLFGDungeonNumEncounters, GetLFGDungeonEncounterInfo, GetAverageItemLevel=nil,nil,nil,nil,nil
end)
test("Timewalking appears only for a live joinable Timewalking queue", function()
    only("timewalking")
    GetNumRandomDungeons=function() return 2 end
    GetLFGRandomDungeonInfo=function(i) return i==1 and 200 or 201,"Timewalking" end
    GetLFGDungeonInfo=function(id) local info={}; info[18]=id==200; return unpack(info,1,22) end
    IsLFGDungeonJoinable=function(id) return id==200 end
    local list=SC.Suggestions:Build(); assert(#list==1 and list[1].id=="timewalking:200")
    IsLFGDungeonJoinable=function() return false end
    list=SC.Suggestions:Build(); assert(#list==0 and P.status.timewalking:find("No available"))
    SC:RefreshSuggestions(); SC.UI:Show(); assert(SC.UI.empty.textValue:find("Timewalking") and SC.UI.availability:IsShown()); SC.UI:Hide()
    GetNumRandomDungeons,GetLFGRandomDungeonInfo,GetLFGDungeonInfo,IsLFGDungeonJoinable=nil,nil,nil,nil
end)
test("set scan searches the full catalog, not the completed-only usable list", function()
    only("transmog")
    local sets={{setID=10,name="Nearly done",validForCharacter=true},{setID=11,name="Started",validForCharacter=true},
        {setID=12,name="Done",validForCharacter=true,collected=true},{setID=13,name="Seasonal",validForCharacter=true,limitedTimeSet=true},
        {setID=14,name="Other class",validForCharacter=false},{setID=15,name="Not loaded",validForCharacter=true}}
    local gained=false
    local fullCatalogReads=0
    C_TransmogSets={GetAllSets=function() fullCatalogReads=fullCatalogReads+1; return sets end,
        GetUsableSets=function() error("completed-only sets must not be used to find unfinished collections") end,
        GetSetPrimaryAppearances=function(id)
            if id==15 then return end
            local result={}; for i=1,8 do result[i]={appearanceID=i,collected=(i <= (id==10 and (gained and 8 or 7) or 1))} end
            return result
        end, GetSetInfo=function() return {collected=false} end}
    assert(#collect("Transmog")==0); assert(P.caches.transmog.running); drain()
    local items=collect("Transmog"); assert(#items==2 and items[1].id=="set:10" and items[1].detail:find("7/8"))
    assert(fullCatalogReads==1, "completed scans should reuse the full-catalog result")
    SC:SetGoal(items[1]); gained=true; SC:RefreshSuggestions(); assert(not SC.goal)
    C_TransmogSets=nil
end)
test("catalog scanning yields and bounds retained recommendations", function()
    only("transmog")
    local inspected, index=0,0
    P:Scan("bounded",function() index=index+1; return index <= 200 and index or nil end,
        function(i) inspected=inspected+1; return {id=tostring(i),score=i} end)
    assert(inspected==0); table.remove(pending,1)(); assert(inspected==25)
    drain(); assert(#P.caches.bounded.items==60 and not P.caches.bounded.running)
end)
test("disabled catalog scans stop and explicit Refresh invalidates completed caches", function()
    only("transmog")
    local index=0
    P:Scan("transmog",function() index=index+1; return index <= 50 and index or nil end,function(i) return {id=tostring(i),score=i} end)
    SoloCompassCharDB.interests.transmog=false; drain()
    assert(index==0 and not P.caches.transmog.running and P.caches.transmog.dirty)
    P.caches.transmog={items={},updated=clock,dirty=false}
    P:RefreshCaches(); assert(P.caches.transmog.dirty and P.caches.transmog.updated==0)
end)
test("old profession skills get fixed milestones that survive refresh", function()
    only("professions")
    local skill=10
    C_TradeSkillUI={GetAllProfessionTradeSkillLines=function() return {171,2478,794} end,
        GetProfessionInfoBySkillLineID=function(id)
            return {professionID=id,professionName="Alchemy",expansionName="An older expansion",skillLevel=id==2478 and skill or 100,maxSkillLevel=100}
        end}
    local items=collect("Professions"); assert(#items==1 and items[1].progressTarget==15 and items[1].detail:find("older expansion"))
    SC:SetGoal(items[1]); skill=12; SC:RefreshSuggestions(); assert(SC.goal.progressTarget==15 and SC.goal.title:find("15"))
    skill=15; SC:RefreshSuggestions(); assert(not SC.goal)
    SoloCompassCharDB.minutes=15; items=collect("Professions"); assert(items[1].progressTarget==16)
    C_TradeSkillUI=nil
end)
test("Archaeology prioritizes already funded projects and handles untrained characters", function()
    only("archaeology")
    GetProfessions=function() return nil,nil,3 end
    GetNumArchaeologyRaces=function() return 2 end
    GetArchaeologyRaceInfo=function(i) return i==1 and "Dwarf" or "Fossil","arch-icon",0,i==1 and 45 or 1,35 end
    GetNumArtifactsByRace=function() return 1 end
    local list=SC.Suggestions:Build(); assert(list[1].id=="archaeology:1" and list[1].minutes==15)
    GetProfessions=function() end; list=SC.Suggestions:Build(); assert(list[1].id=="prepare:archaeology")
    GetProfessions,GetNumArchaeologyRaces,GetArchaeologyRaceInfo,GetNumArtifactsByRace=nil,nil,nil,nil
end)
test("achievement scan selects unfinished progress and excludes raid/feat categories", function()
    only("achievements")
    GetCategoryList=function() return {97,81,168} end
    GetCategoryInfo=function() return "Category",-1 end
    GetCategoryNumAchievements=function() return 3 end
    GetAchievementInfo=function(category,index)
        if not index then return category,"Nearly there",10,false end
        assert(category==97)
        return 900+index,"Explore somewhere",10,index==2,nil,nil,nil,"One more place",0,"achievement-icon",nil,index==3
    end
    GetAchievementNumCriteria=function() return 2 end
    GetAchievementCriteriaInfo=function(_,index) return index==1 and "Found first place" or "Find second place",0,index==1,0,1 end
    collect("Achievements"); drain(); local items=collect("Achievements")
    assert(#items==1 and items[1].id=="achievement:901" and items[1].detail:find("Find second place"))
    GetCategoryList,GetCategoryInfo,GetCategoryNumAchievements,GetAchievementInfo,GetAchievementNumCriteria,GetAchievementCriteriaInfo=nil,nil,nil,nil,nil,nil
end)
test("heirlooms respect ownership, source data, and the existing journal view", function()
    only("heirlooms")
    C_Heirloom={GetNumDisplayedHeirlooms=function() return 2 end,GetHeirloomItemIDFromDisplayedIndex=function(i) return 1000+i end,
        GetHeirloomInfo=function(id) return "Alt shoulders",0,false,"heirloom-icon",0,"Vendor: check price" end,
        PlayerHasHeirloom=function(id) return id==1002 end}
    local items=collect("Heirlooms"); assert(#items==1 and items[1].id=="heirloom:1001")
    C_Heirloom.PlayerHasHeirloom=function() return true end
    assert(#collect("Heirlooms")==0); C_Heirloom=nil
end)
test("missing campsite goals use client sources and clear on collection", function()
    only("campsites")
    local owned=false
    C_WarbandScene={SearchWarbandSceneEntries=function() return {1,2} end,
        GetWarbandSceneEntry=function(id) return {name="A quiet camp",source="Achievement: explore a region"} end,
        HasWarbandScene=function(id) return id==1 or owned end}
    local items=collect("Campsites"); assert(#items==1 and items[1].id=="campsite:2")
    SC:SetGoal(items[1]); owned=true; SC:RefreshSuggestions(); assert(not SC.goal)
    C_WarbandScene=nil
end)
test("Renown and older reputations exclude finished, locked, and hostile factions", function()
    only("reputation")
    C_MajorFactions={GetMajorFactionIDs=function() return {1,2,3} end,
        GetMajorFactionData=function(id) return {name="Renown faction",isUnlocked=id~=3,renownLevel=id==2 and 20 or 10,maxLevel=20,renownLevelThreshold=2500,renownReputationEarned=2200} end}
    C_Reputation={GetNumFactions=function() return 3 end,
        GetFactionDataByIndex=function(i) return {factionID=20+i,name="Old faction",reaction=i==1 and 5 or i==2 and 8 or 2,nextReactionThreshold=6000,currentStanding=5500,isWatched=true} end}
    local items=collect("Reputation"); assert(#items==2)
    local ids={}; for _,s in ipairs(items) do ids[s.id]=true end
    assert(ids["renown:1"] and ids["reputation:21"])
    C_MajorFactions,C_Reputation=nil,nil
end)
test("Legion appearances require known IDs and explicitly obtainable locked flags", function()
    only("artifacts"); SoloCompassCharDB.artifactAppearances={}
    C_ArtifactUI={GetArtifactInfo=function() return 123,nil,"My Legion weapon","artifact-icon" end,
        GetNumAppearanceSets=function() return 1 end,GetAppearanceSetInfo=function() return 1,"Set","Set details",3 end,
        GetAppearanceInfo=function(_,i) return 500+i end,
        GetAppearanceInfoByID=function(id) return 1,id,"Appearance",1,id==502,"Finish this requirement",0,nil,0,0,0,1,1,id~=503 end}
    local items=collect("Artifacts"); assert(#items==1 and items[1].id=="artifact:501")
    assert(SoloCompassCharDB.artifactAppearances[501].weapon=="My Legion weapon")
    C_ArtifactUI=nil; SoloCompassCharDB.artifactAppearances={}
end)
test("solo PvP stays opt-in and has a practice goal without promising a win", function()
    only("pvp"); UnitHonorLevel=function() return 23 end
    local list=SC.Suggestions:Build(); assert(list[1].detail:find("23") and list[1].detail:find("not required"))
    SoloCompassCharDB.minutes=15; list=SC.Suggestions:Build(); assert(list[1].title:find("Choose"))
    UnitHonorLevel=nil
end)
test("housing tracks one Endeavor task with live objectives and repeat/cycle identity", function()
    only("housing")
    local task={ID=41,taskName="Help the neighborhood",description="Contribute once",inProgress=true,timesCompleted=3,completed=false,
        requirementsList={{requirementText="Contributions: 0/2",completed=false}}}
    local info={isLoaded=true,initiativeID=10,currentCycleID=2,neighborhoodGUID="Home",tasks={task}}
    C_NeighborhoodInitiative={PlayerHasInitiativeAccess=function() return true end,IsViewingActiveNeighborhood=function() return true end,
        GetNeighborhoodInitiativeInfo=function() return info end,GetInitiativeTaskInfo=function() return task end}
    local items=collect("Housing"); assert(#items==1 and items[1].id=="endeavor:41" and items[1].progressTarget==4)
    SC:SetGoal(items[1]); SC.UI:Hide(); assert(SC.UI.tracker.objectiveRows[1].textValue:find("0/2"))
    task.requirementsList[1].requirementText="Contributions: 1/2"; SC:RefreshSuggestions()
    assert(SC.UI.tracker.objectiveRows[1].textValue:find("1/2"))
    task.timesCompleted=4; SC:RefreshSuggestions(); assert(not SC.goal)
    SC:SetGoal(collect("Housing")[1]); info.currentCycleID=3; task.timesCompleted=5; task.completed=true
    SC:RefreshSuggestions(); assert(SC.goal and SC.UI.tracker.objectiveRows[1].textValue:find("cycle"))
    SC:ClearGoal(); C_NeighborhoodInitiative=nil
end)
test("all interests are visible together on their own tab", function()
    SC.UI:Show(); local rows=SC.UI.interestSlots
    local seen={}
    SC.UI:SelectTab("interests")
    assert(SC.UI.interests:IsShown() and not SC.UI.ideas:IsShown())
    for _,row in ipairs(rows) do if row.category then seen[row.category.key]=true end end
    for _,category in ipairs(SC.Data.Categories) do assert(seen[category.key]) end
    assert(#rows==#SC.Data.Categories); SC.UI:Hide()
end)
test("new activity actions select panels without queueing, crafting, or purchases", function()
    local called={}
    JoinSingleLFG=function() error("must not queue") end
    RaidFinderQueueFrame_SetRaid=function(id) called.raid=id end
    LFDQueueFrame_SetType=function(id) called.dungeon=id end
    local original=PVEFrame_ShowFrame
    PVEFrame_ShowFrame=function(panel,tab) called.panel,called.tab=panel,tab end
    SC.UI:HandleCardClick({action="lfr",targetID=100}); assert(called.raid==100)
    SC.UI:HandleCardClick({action="timewalking",targetID=200}); assert(called.dungeon==200)
    SC.UI:HandleCardClick({action="pvp"}); assert(called.panel=="PVPUIFrame" and called.tab=="HonorFrame")
    PVEFrame_ShowFrame=original; JoinSingleLFG,RaidFinderQueueFrame_SetRaid,LFDQueueFrame_SetType=nil,nil,nil
end)
SC:ClearGoal(); SC.UI:Hide(); SoloCompassCharDB.interests=originalInterests; SoloCompassCharDB.minutes=originalMinutes
P.caches={}; P.status={}; drain(); C_Timer.After=originalAfter; GetServerTime=originalNow
SC:RefreshSuggestions()
print(count .. " progress-provider tests passed")
