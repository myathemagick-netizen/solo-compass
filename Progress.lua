-- Read-only progress providers. No queues, purchases, crafts, or filter changes.
SoloCompass.Progress = { caches = {}, status = {} }
local P, SC = SoloCompass.Progress, SoloCompass
local function icon(name) return "Interface\\Icons\\" .. name end
local function budget() return SoloCompassCharDB.minutes end
local function stepSize() return budget() >= 60 and 10 or budget() >= 30 and 5 or 1 end
local function planning(category, title, detail, action, texture)
    return { id = "prepare:" .. category, category = category, title = title, detail = detail,
        reason = "A preparation step; no completion or reward is assumed", minutes = 15, score = 30,
        action = action, icon = icon(texture or "INV_Misc_Book_09"),
        timeNote = "A short planning step. Completing the activity itself may take much longer.", stepLabel = "Plan one next step" }
end

-- Large catalogs are scanned in small slices only when their interest is enabled.
-- Retain at most 60 candidates; cache for a minute and refresh on relevant events.
function P:Scan(kind, nextItem, inspect)
    local cache = self.caches[kind]
    if cache and (cache.running or not cache.dirty or SC:Now() < cache.updated + 60) then return cache.items end
    cache = { items = {}, running = true, updated = SC:Now(), count = 0 }
    self.caches[kind] = cache
    local function slice()
        if (kind == "transmog" or kind == "achievements" or kind == "pets" or kind == "decorrecipes" or kind == "mounts" or kind == "toys" or kind == "delves") and not SoloCompassCharDB.interests[kind=="decorrecipes" and "professions" or kind] then
            cache.running=false; cache.dirty=true; cache.updated=0; return
        end
        for _ = 1, 25 do
            local item = nextItem()
            if not item or cache.count >= 16000 then
                cache.running = false
                SC:ScheduleRefresh()
                return
            end
            cache.count = cache.count + 1
            local candidate = inspect(item)
            if candidate then
                cache.items[#cache.items + 1] = candidate
                table.sort(cache.items, function(a,b)
                    if a.score ~= b.score then return a.score > b.score end
                    return a.id < b.id
                end)
                if #cache.items > 60 then table.remove(cache.items) end
            end
        end
        C_Timer.After(0.03, slice)
    end
    C_Timer.After(0.03, slice)
    return cache.items
end
function P:RefreshCaches()
    self.toyIDs=nil
    for _, cache in pairs(self.caches) do
        if not cache.running then cache.dirty=true; cache.updated=0 end
    end
end
function P:UseCache(kind, add)
    local cache = self.caches[kind]
    if cache and (cache.running or not cache.dirty or SC:Now() < cache.updated + 60) then
        for _, s in ipairs(cache.items) do add(s) end
        self.status[kind] = cache.running and "Checking collection progress in small batches..."
            or "No matching unfinished progress found in the supported catalog. Check the game panel and Refresh if data has not loaded."
        return true
    end
    return false
end
function P:OnEvent(event, payload, arg2, arg3)
    local changed=({NEW_MOUNT_ADDED="mounts",NEW_TOY_ADDED="toys",TOYS_UPDATED="toys",AREA_POIS_UPDATED="delves"})[event]
    if changed and self.caches[changed] then self.caches[changed].dirty=true end
    if event=="UNIT_SPELLCAST_SUCCEEDED" and payload=="player" and arg3 then
        local goal=SoloCompassCharDB.goalSnapshot
        if goal and goal.action=="decorrecipe" and goal.targetID==arg3 then
            SoloCompassCharDB.craftCounts=SoloCompassCharDB.craftCounts or {}
            SoloCompassCharDB.craftCounts[arg3]=(SoloCompassCharDB.craftCounts[arg3] or 0)+1
        end
    elseif event=="TRADE_SKILL_LIST_UPDATE" or event=="TRADE_SKILL_SHOW" or event=="TRADE_SKILL_CLOSE" then
        self.caches.decorrecipes=nil
    end
    if event=="PLAYER_HOUSE_LIST_UPDATED" and type(payload)=="table" then
        self.ownedHouses=payload; self.houseFavor={}
        for _,house in ipairs(payload) do
            if house.houseGUID and C_Housing and C_Housing.GetCurrentHouseLevelFavor then C_Housing.GetCurrentHouseLevelFavor(house.houseGUID) end
        end
    elseif event=="HOUSE_LEVEL_FAVOR_UPDATED" and type(payload)=="table" and payload.houseGUID then
        self.houseFavor=self.houseFavor or {}; self.houseFavor[payload.houseGUID]=payload
    elseif event=="HOUSE_LEVEL_CHANGED" then
        self.houseRequestAt=nil; self.houseFavor={}
    end
    if event == "ACHIEVEMENT_EARNED" or event == "CRITERIA_UPDATE" then
        if self.caches.achievements then self.caches.achievements.dirty = true end
    elseif event == "PET_JOURNAL_LIST_UPDATE" or event == "PET_BATTLE_LEVEL_CHANGED" or event == "PET_JOURNAL_PET_DELETED" then
        if self.caches.pets then self.caches.pets.dirty=true end
    elseif event == "TRANSMOG_COLLECTION_UPDATED" then
        if self.caches.transmog then self.caches.transmog.dirty = true end
    elseif event == "ARTIFACT_UPDATE" or event == "ARTIFACT_APPEARANCE_CHANGED" then self:RememberArtifact()
    elseif event == "INITIATIVE_TASK_COMPLETED" and C_NeighborhoodInitiative and C_NeighborhoodInitiative.RequestNeighborhoodInitiativeInfo then
        if SoloCompassCharDB.interests.housing or (SC.goal and SC.goal.action == "endeavor") then
            C_NeighborhoodInitiative.RequestNeighborhoodInitiativeInfo()
        end
    end
end

-- Owned GUIDs are independent of journal filters; missing species follow its visible list.
function P:Mounts(add)
    local api=C_MountJournal
    if not api or not api.GetMountIDs or not api.GetMountInfoExtraByID then return end
    local blocked={}
    for _,entry in ipairs(SC.Data.Mounts) do
        local id=api.GetMountFromItem and api.GetMountFromItem(entry.itemID)
        if id and (UnitLevel("player")<entry.minLevel or SC.Suggestions:IsLocked(entry.instanceID,entry.difficultyID)) then blocked[id]=true end
    end
    if self:UseCache("mounts",function(item)
        if not blocked[item.targetID] and select(11,api.GetMountInfoByID(item.targetID))==false then add(item) end
    end) then return end
    local ids,index=api.GetMountIDs() or {},0
    self:Scan("mounts",function() index=index+1; return ids[index] end,function(id)
        local name,_,texture,_,_,sourceType,_,_,_,hidden,owned=api.GetMountInfoByID(id)
        if not name or owned~=false or hidden or not ({[1]=true,[2]=true,[3]=true,[4]=true,[5]=true})[sourceType] then return end
        local _,_,source=api.GetMountInfoExtraByID(id)
        if not source or source=="" then return end
        return {id="mount:"..id,category="mounts",title=name,detail=source,
            reason="Missing from your journal; investigate its listed source and current requirements",
            minutes=15,score=sourceType==1 and 63 or 54,action="mount",targetID=id,icon=texture,
            stepLabel="Check one acquisition source",timeNote="A source-planning step, not a guaranteed acquisition. Drops, costs, access and current availability must be checked; store and promotional sources are excluded."}
    end)
end
function P:Toys(add)
    local api=C_ToyBox
    if not api or not api.GetNumFilteredToys or not api.GetToyFromIndex or not api.GetToyInfo or not PlayerHasToy then return end
    if self:UseCache("toys",function(item) if not PlayerHasToy(item.targetID) then add(item) end end) then
        self.status.toys=self.caches.toys.running and "Checking missing toys in your journal view..." or "No missing toys found in the captured Toy Box list. Refresh clears filters and checks the full journal again."
        return
    end
    if not self.toyIDs then
        if C_ToyBoxInfo and C_ToyBoxInfo.SetDefaultFilters then C_ToyBoxInfo.SetDefaultFilters() end
        if api.SetAllSourceTypeFilters then api.SetAllSourceTypeFilters(true) end
        if api.SetAllExpansionTypeFilters then api.SetAllExpansionTypeFilters(true) end
        if api.SetCollectedShown then api.SetCollectedShown(true) end
        if api.SetUncollectedShown then api.SetUncollectedShown(true) end
        if api.SetFilterString then api.SetFilterString("") end
        if ToyBox then
            ToyBox.searchString=""
            if ToyBox.searchBox and ToyBox.searchBox.SetText then ToyBox.searchBox:SetText("") end
        end
        if api.ForceToyRefilter then api.ForceToyRefilter() end
        self.toyIDs={}
        for index=1,api.GetNumFilteredToys() do
            local id=api.GetToyFromIndex(index)
            if id then self.toyIDs[#self.toyIDs+1]=id end
        end
    end
    local ids,index=self.toyIDs,0
    self:Scan("toys",function() index=index+1; return ids[index] end,function(id)
        if PlayerHasToy(id) then return end
        local _,name,texture=api.GetToyInfo(id)
        if not name or name=="" then return end
        local detail="Open this toy's journal tooltip to inspect its source, then choose one next step."
        local tip=C_TooltipInfo and C_TooltipInfo.GetToyByItemID and C_TooltipInfo.GetToyByItemID(id)
        local lines={}
        for _,line in ipairs(tip and tip.lines or {}) do
            if line.leftText and line.leftText~="" and line.leftText~=name then lines[#lines+1]=line.leftText end
        end
        if #lines>0 then detail=table.concat(lines," "):sub(1,700) end
        return {id="toy:"..id,category="toys",title=name,detail=detail,
            reason="Missing from your toy collection; inspect its source before traveling",minutes=15,score=53,
            action="toy",targetID=id,icon=texture,stepLabel="Investigate one missing toy",
            timeNote="A source-planning step. Refresh resets journal filters to include all source and expansion categories. Availability and acquisition time are not inferred."}
    end)
end
function P:HasDelveCatalog()
    return C_AreaPoiInfo and C_AreaPoiInfo.GetDelvesForMap and C_AreaPoiInfo.GetAreaPOIInfo and C_Map and C_Map.GetMapChildrenInfo
end
function P:DelveKeys()
    local id=Constants and Constants.DelvesConsts and Constants.DelvesConsts.DELVES_NORMAL_KEY_CURRENCY_ID or 3028
    local info=C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo and C_CurrencyInfo.GetCurrencyInfo(id)
    return info and info.quantity,info and info.name
end
function P:Delves(add)
    if not self:HasDelveCatalog() then return end
    local minimum=C_DelvesUI and C_DelvesUI.GetDelvesMinRequiredLevel and C_DelvesUI.GetDelvesMinRequiredLevel()
    minimum=minimum or (GetMaxLevelForLatestExpansion and GetMaxLevelForLatestExpansion())
    if not minimum then self.status.delves="Delve level requirements have not loaded. Open the Delve map, then Refresh."; return end
    if UnitLevel("player")<minimum then
        local idea=planning("delves","A little leveling before your next Delve","Delves require level "..minimum.." for this character. Choose a leveling quest you enjoy, then check back.","questlog")
        add(idea); return
    end
    local function emit(candidate)
        local keys,name=self:DelveKeys()
        local keyText=keys and (" "..(name or "Restored Coffer Keys")..": "..keys..". "..(keys>0 and "You have a key; check the chest's requirements in game." or "No keys on hand for the keyed bonus chest; you can still consider a normal run.")) or " Key count is unavailable; check your currency tab before planning a bonus chest."
        local info=C_AreaPoiInfo.GetAreaPOIInfo(candidate.mapID,candidate.targetID)
        if not info or info.isLocked then return end
        candidate.title=info.name
        candidate.atlas=info.atlasName or "questlog-questtypeicon-delves"
        local bountiful=info.atlasName and info.atlasName:lower():find("bountiful",1,true)
        candidate.detail=(bountiful and "Currently marked Bountiful. " or "A named Delve on your world map. ").."Choose a tier you can comfortably complete."..keyText
        candidate.score=bountiful and (keys and keys>0 and 94 or 72) or 58
        candidate.stepLabel=bountiful and "Bountiful Delve" or "One named Delve"
        add(candidate)
    end
    if self:UseCache("delves",emit) then return end
    local maps=C_Map.GetMapChildrenInfo(947,nil,true) or {}
    local mi,pi,pois,seen=0,0,{},{}
    self:Scan("delves",function()
        if mi<#maps then mi=mi+1; return {map=maps[mi]} end
        pi=pi+1; return pois[pi]
    end,function(item)
        if item.map then
            local map=item.map
            if not map.mapType or map.mapType==3 then
                for _,id in ipairs(C_AreaPoiInfo.GetDelvesForMap(map.mapID) or {}) do
                    if not seen[id] then seen[id]=true; pois[#pois+1]={id=id,mapID=map.mapID} end
                end
            end
            return
        end
        local info=C_AreaPoiInfo.GetAreaPOIInfo(item.mapID,item.id)
        if not info or not info.name or info.isLocked then return end
        local x,y
        if info.position then x,y=info.position:GetXY() end
        local keys=self:DelveKeys()
        local bountiful=info.atlasName and info.atlasName:lower():find("bountiful",1,true)
        return {id="delve:"..item.id,category="delves",title=info.name,detail="Check the Delve entrance and select a comfortable tier.",
            reason="A Delve entrance currently reported by the client",minutes=30,score=bountiful and (keys and keys>0 and 94 or 72) or 58,
            action="map",targetID=item.id,mapID=item.mapID,mapX=x,mapY=y,atlas=info.atlasName or "questlog-questtypeicon-delves",
            icon=icon("INV_Misc_Map_01"),stepLabel=bountiful and "Bountiful Delve" or "One named Delve",
            timeNote="Run and travel times vary. Bountiful status follows the current map icon; key count does not guarantee tier access or a particular reward."}
    end)
end

function P:HasPetCatalog()
    local api=C_PetJournal
    return api and api.GetOwnedPetIDs and api.GetPetInfoTableByPetID and api.GetPetInfoTableBySpeciesID
end
function P:Pets(add)
    if not self:HasPetCatalog() then return end
    local api=C_PetJournal
    local cache=self.caches.pets
    if not cache or (cache.dirty and not cache.running and SC:Now() >= cache.updated+60) then
        local owned=api.GetOwnedPetIDs() or {}
        local total=api.GetNumPets and api.GetNumPets() or 0
        local index, phase, best, seen, key=0,1,{},{},nil
        self:Scan("pets",function()
            index=index+1
            if phase==1 then
                if owned[index] then return {petID=owned[index]} end
                phase=2; index=1
            end
            if phase==2 then
                if index<=total then return {index=index} end
                phase=3
            end
            key=next(best,key)
            if key then return {training=best[key]} end
        end,function(item)
            if item.petID then
                local info=api.GetPetInfoTableByPetID(item.petID)
                if info and info.speciesID and info.canBattle and info.petLevel then
                    local prior=best[info.speciesID]
                    if not prior or info.petLevel>prior.info.petLevel then best[info.speciesID]={info=info,petID=item.petID} end
                end
            elseif item.index and api.GetPetInfoByIndex then
                local _,species=api.GetPetInfoByIndex(item.index)
                if not species or seen[species] then return end
                seen[species]=true
                local info=api.GetPetInfoTableBySpeciesID(species)
                local collected=api.GetNumCollectedInfo and api.GetNumCollectedInfo(species)
                if info and collected==0 and info.obtainable==true and info.canBattle and info.name and info.sourceText and info.sourceText~="" then
                    return {id="pet:"..species,category="pets",title=info.name,detail=info.sourceText,
                        reason="Missing from your pet collection; check the source and its requirements",
                        minutes=15,score=info.isWild and 70 or 55,action="pet",targetID=species,icon=info.icon,
                        timeNote="Time to investigate or attempt the source. Travel, cost and capture or drop luck vary."}
                end
            elseif item.training then
                local info=item.training.info
                if info.petLevel<1 or info.petLevel>=25 or not info.name then return end
                return {id="petlevel:"..item.training.petID,category="pets",
                    title=(info.customName or info.name)..": reach level "..(info.petLevel+1),
                    detail="Level "..info.petLevel.." / 25. Choose a suitable pet battle or leveling method in your journal.",
                    reason="Your highest-level copy of this species still has room to grow",
                    minutes=15,score=50+info.petLevel,action="petlevel",targetID=info.speciesID,
                    targetPetID=item.training.petID,searchName=info.name,icon=info.icon,
                    progressStart=info.petLevel,progressTarget=info.petLevel+1,progressKind="petlevel",
                    stepLabel="Gain one pet level",timeNote="A small training goal; battle difficulty and leveling method affect the time."}
            end
        end)
        cache=self.caches.pets
    end
    self.status.pets=cache.running and "Checking your pet collection in small batches..." or "No matching pet goals. Missing pets follow your Pet Journal filters; enable uncollected pets and Refresh. Training skips species with a level-25 copy."
    if cache.running then return end
    for _,candidate in ipairs(cache.items) do
        local info=candidate.targetPetID and api.GetPetInfoTableByPetID(candidate.targetPetID)
        if candidate.action=="pet" then
            if api.GetNumCollectedInfo(candidate.targetID)==0 then add(candidate) end
        elseif info and info.petLevel and info.petLevel<candidate.progressTarget then add(candidate) end
    end
end

function P:HouseUpgrades(add)
    local api=C_Housing
    if not api or not api.GetPlayerOwnedHouses or not api.GetHouseLevelFavorForLevel or not api.GetMaxHouseLevel then return end
    if not self.houseRequestAt or SC:Now()-self.houseRequestAt>=60 then
        self.houseRequestAt=SC:Now(); api.GetPlayerOwnedHouses()
    end
    for _,house in ipairs(self.ownedHouses or {}) do
        local favor=self.houseFavor and self.houseFavor[house.houseGUID]
        if favor and favor.houseLevel and favor.houseFavor and favor.houseLevel<api.GetMaxHouseLevel() then
            local target=favor.houseLevel+1
            local needed=api.GetHouseLevelFavorForLevel(target)
            if needed and needed>0 and favor.houseFavor>=needed then
                local name=house.houseName or house.neighborhoodName or ("Plot "..(house.plotID or "?"))
                add({id="houseupgrade:"..house.houseGUID,category="housing",title="Your house is ready to upgrade!",
                    detail=name..": level "..favor.houseLevel.." -> "..target..". You have the required house XP. Visit this house and speak to its upgrade NPC to review the upgrade.",
                    reason="A house upgrade is ready to claim",minutes=15,score=100,priority=true,action="houseupgrade",
                    houseGUID=house.houseGUID,destinationName=name,progressStart=favor.houseLevel,progressTarget=target,
                    icon=icon("INV_Misc_Rune_01"),atlas="housing-dashboard-homestone-icon",stepLabel="Claim your house upgrade",
                    timeNote="Travel time is additional; check the game's upgrade requirements at your house."})
            end
        end
    end
end
function P:Housing(add)
    self:HouseUpgrades(add)
    local api = C_NeighborhoodInitiative
    local hasAccess = api and (not api.PlayerHasInitiativeAccess or api.PlayerHasInitiativeAccess())
    local ownNeighborhood = api and (not api.IsViewingActiveNeighborhood or api.IsViewingActiveNeighborhood())
    local info = api and api.GetNeighborhoodInitiativeInfo and api.GetNeighborhoodInitiativeInfo()
    local found = false
    if hasAccess and ownNeighborhood and info and info.isLoaded and info.initiativeID and info.initiativeID > 0 then
        local superseded = {}
        for _, task in ipairs(info.tasks or {}) do if task.supersedes and task.supersedes > 0 then superseded[task.supersedes] = true end end
        for _, task in ipairs(info.tasks or {}) do
            if not task.completed and not superseded[task.ID] then
                found = true
                local objectives = {}
                for _, requirement in ipairs(task.requirementsList or {}) do
                    if not requirement.completed then objectives[#objectives+1] = requirement.requirementText end
                end
                add({id="endeavor:" .. task.ID, category="housing", title="One Endeavor task: " .. task.taskName,
                    detail=#objectives > 0 and table.concat(objectives,"; ") or task.description,
                    reason="An unfinished task in your active neighborhood's Endeavor; choose a task whose requirements suit your play session",
                    minutes=15, score=task.inProgress and 79 or 61, action="endeavor", targetID=task.ID,
                    progressKind="endeavor", progressStart=task.timesCompleted or 0, progressTarget=(task.timesCompleted or 0)+1,
                    initiativeID=info.initiativeID, cycleID=info.currentCycleID, neighborhoodGUID=info.neighborhoodGUID,
                    atlas="housing-dashboard-homestone-icon", icon=icon("INV_Misc_Rune_01"), stepLabel="Complete one task, once",
                    timeNote="A next-task planning allowance. The live requirements determine the actual time; the whole neighborhood Endeavor is not a solo 15-minute goal."})
            end
        end
    elseif hasAccess and ownNeighborhood and api.RequestNeighborhoodInitiativeInfo
        and (not self.housingRequestedAt or SC:Now()-self.housingRequestedAt > 30) then
        self.housingRequestedAt=SC:Now(); api.RequestNeighborhoodInitiativeInfo()
    end
    if not found then
        add(planning("housing", "Choose one housing improvement", "Open Housing / Endeavors to load your active neighborhood's tasks. If no task fits, decorate one corner or choose one decor item to work toward.", "endeavor", "INV_Misc_Rune_01"))
    end
end

function P:ObjectiveLines(s)
    local lines = {}
    if s.action == "houseupgrade" then
        return {"Visit "..(s.destinationName or "your house").." and upgrade to level "..s.progressTarget.."."}
    elseif s.action == "petlevel" and self:HasPetCatalog() then
        local info=C_PetJournal.GetPetInfoTableByPetID(s.targetPetID)
        return {info and ("Level "..(info.petLevel or "?").." / "..s.progressTarget) or "Open the journal to check this pet."}
    elseif s.action=="reputation" then
        if s.progressKind=="renown" and C_MajorFactions and C_MajorFactions.GetMajorFactionData then
            local info=C_MajorFactions.GetMajorFactionData(s.targetID)
            if info then return {"Renown "..info.renownLevel.." / "..s.progressTarget,info.renownReputationEarned.." / "..info.renownLevelThreshold.." reputation"} end
        elseif C_Reputation and C_Reputation.GetFactionDataByID then
            local info=C_Reputation.GetFactionDataByID(s.targetID)
            if info then return {math.max(0,info.nextReactionThreshold-info.currentStanding).." reputation to the next standing."} end
        end
        return {"Open Reputation to check your progress."}
    elseif s.action == "quest" and C_QuestLog then
        if C_QuestLog.IsComplete and C_QuestLog.IsComplete(s.targetID) then return {"Ready to turn in. Navigate to the quest giver."} end
        for _, objective in ipairs(C_QuestLog.GetQuestObjectives and C_QuestLog.GetQuestObjectives(s.targetID) or {}) do
            if objective.text and objective.text ~= "" then
                lines[#lines+1] = (objective.finished and "[x] " or "[ ] ") .. objective.text
            end
        end
        if #lines == 0 then lines[1] = "Open quest details to check the next objective." end
    elseif s.action == "endeavor" and s.targetID and C_NeighborhoodInitiative and C_NeighborhoodInitiative.GetInitiativeTaskInfo then
        local current=C_NeighborhoodInitiative.GetNeighborhoodInitiativeInfo and C_NeighborhoodInitiative.GetNeighborhoodInitiativeInfo()
        if s.initiativeID and (not current or not current.isLoaded or current.initiativeID ~= s.initiativeID
            or current.currentCycleID ~= s.cycleID or current.neighborhoodGUID ~= s.neighborhoodGUID) then
            return {"Check this task's original neighborhood / cycle."}
        end
        local info = C_NeighborhoodInitiative.GetInitiativeTaskInfo(s.targetID)
        for _, requirement in ipairs(info and info.requirementsList or {}) do
            if requirement.requirementText then lines[#lines+1]=(requirement.completed and "[x] " or "[ ] ") .. requirement.requirementText end
        end
        if #lines == 0 then lines[1] = "Open Endeavors to check this task's requirements." end
    end
    return lines
end

function P:Queues(add)
    local interests = SoloCompassCharDB.interests
    if interests.lfr then
        local wings, latest = {}, -1
        if GetNumRFDungeons and GetRFDungeonInfo and GetLFGDungeonInfo then
            for i = 1, GetNumRFDungeons() do
                local id, name = GetRFDungeonInfo(i)
                if id and name then
                    local info = {GetLFGDungeonInfo(id)}
                    local available, toPlayer, hidden
                    if IsLFGDungeonJoinable then available, toPlayer, hidden = IsLFGDungeonJoinable(id) end
                    if available or toPlayer or not hidden then
                        local expansion = info[9] or -1
                        latest = math.max(latest, expansion)
                        wings[#wings + 1] = {id=id, name=name, info=info, available=available}
                    end
                end
            end
        end
        local level=UnitLevel("player")
        local requiredLevel
        for _,wing in ipairs(wings) do
            local minimum=wing.info[4]
            if (wing.info[9] or -1)==latest and minimum and minimum>0 then
                requiredLevel=requiredLevel and math.min(requiredLevel,minimum) or minimum
            end
        end
        local needsLevels=requiredLevel and level<requiredLevel
        if needsLevels then
            add({id="prepare:lfrlevel",category="lfr",title="Your next step toward Raid Finder",
                detail="Raid Finder in this list opens at level "..requiredLevel..". You're level "..level.."—a quest or two is a good next step. Pick a campaign or leveling quest you enjoy, then check back as you level.",
                reason="A little leveling now will bring these raid wings within reach",
                minutes=15,score=68,action="questlog",icon=icon("INV_Misc_Book_09"),
                stepLabel="Choose one leveling quest",timeNote="A short leveling step; reaching the required level may take several sessions."})
        end
        for _, wing in ipairs(wings) do
            if (wing.info[9] or -1) == latest and not needsLevels and (not wing.info[4] or level>=wing.info[4]) then
                local encounters, killed = GetLFGDungeonNumEncounters and GetLFGDungeonNumEncounters(wing.id) or 0, 0
                if GetLFGDungeonEncounterInfo then
                    for index = 1, encounters do if select(3, GetLFGDungeonEncounterInfo(wing.id, index)) then killed = killed + 1 end end
                end
                if encounters == 0 or killed < encounters then
                    local equipped
                    if GetAverageItemLevel then local _, value = GetAverageItemLevel(); equipped = value end
                    -- Minimum item level is an entry requirement, not the loot's level.
                    local gear = equipped and string.format(" Equipped item level %.0f.", equipped) or ""
                    if wing.info[20] and wing.info[20] > 0 then gear = gear .. " Required item level " .. wing.info[20] .. "." end
                    local prepare = budget() == 15 or not wing.available
                    add({id="lfr:" .. wing.id, category="lfr", title=(prepare and "Prepare for " or "Run ") .. wing.name,
                        detail=(encounters > 0 and (encounters-killed) .. "/" .. encounters .. " bosses still eligible for this week's loot. " or "Check boss loot eligibility in Raid Finder. ")
                            .. (prepare and "Review entry requirements and one boss's loot before you queue." or "Choose one wing; queue alone and play with a matchmade group.") .. gear,
                        reason=wing.available and "Available in the newest expansion represented in your Raid Finder list; loot upgrades are not evaluated"
                            or "This wing is listed, but you cannot currently queue; check its requirements",
                        minutes=prepare and 15 or 30, score=wing.available and 68 or 38, action="lfr", targetID=wing.id,
                        icon=wing.info[11] or icon("INV_Misc_GroupLooking"), stepLabel=prepare and "Check one wing" or "One raid wing",
                        timeLabel=prepare and "15 MIN PREP" or "30-60 MIN + QUEUE",
                        timeNote=prepare and "Preparation only; no queue or wing completion fits this allowance by promise."
                            or "Allow roughly 30-60 minutes for a wing, plus queue time. Group pace varies; no upgrade is guaranteed."})
                end
            end
        end
        if #wings == 0 then add(planning("lfr", "Check your Raid Finder options", "Open Raid Finder to load its available wings, level and gear requirements. Refresh Solo Compass afterward.", "lfr", "INV_Misc_GroupLooking")) end
        self.status.lfr = "No unlooted wings in the current list, or the list is still loading. Open Raid Finder and Refresh; try a preparation step at 15 minutes."
    end
    if interests.timewalking then
        local found = false
        if GetNumRandomDungeons and GetLFGRandomDungeonInfo and GetLFGDungeonInfo then
            for i = 1, GetNumRandomDungeons() do
                local id, name = GetLFGRandomDungeonInfo(i)
                if id then
                    local info = {GetLFGDungeonInfo(id)}
                    local available = IsLFGDungeonJoinable and IsLFGDungeonJoinable(id)
                    if info[18] and available then
                        found = true
                        local prepare = budget() == 15
                        add({id="timewalking:" .. id, category="timewalking", title=(prepare and "Plan " or "Run one ") .. (name or "Timewalking dungeon"),
                            detail=prepare and "This queue is available now. Check its reward and your role, then decide whether you have time for a dungeon."
                                or "Complete one dungeon from this currently available Timewalking queue. Check for an associated weekly quest before entering.",
                            reason="The client reports an available Timewalking queue for this character", minutes=prepare and 15 or 30,
                            score=70, action="timewalking", targetID=id, icon=info[11] or icon("Spell_Holy_BorrowedTime"),
                            stepLabel=prepare and "Choose a reward" or "One dungeon", timeNote="Dungeon runs and queue times vary. Weekly-quest progress and vendor purchases are not checked."})
                    end
                end
            end
        end
        if not found then self.status.timewalking = "No available Timewalking queue was reported for this character. It may be inactive, level-restricted, or still loading. Check Dungeon Finder / the calendar, then Refresh." end
    end
end

function P:Transmog(add)
    if not C_TransmogSets or not C_TransmogSets.GetAllSets or not C_TransmogSets.GetSetPrimaryAppearances then
        add(planning("transmog", "Open your appearance sets", "Open the wardrobe to load usable sets, then Refresh to find partially collected sets.", "transmog")); return
    end
    if self:UseCache("transmog", add) then return end
    -- GetUsableSets contains completed sets ready to apply at the transmogrifier.
    -- Search the full catalog for incomplete sets, independent of journal filters.
    local sets, index = C_TransmogSets.GetAllSets() or {}, 0
    local items = self:Scan("transmog", function() index=index+1; return sets[index] end, function(set)
        if set.collected or not set.validForCharacter or set.limitedTimeSet or set.hiddenUntilCollected then return end
        local appearances = C_TransmogSets.GetSetPrimaryAppearances(set.setID)
        if not appearances then return end
        local owned, total = 0, 0
        for _, appearance in ipairs(appearances) do total=total+1; if appearance.collected then owned=owned+1 end end
        if total == 0 or owned == 0 or owned == total then return end
        return {id="set:" .. set.setID, category="transmog", title="One piece closer: " .. set.name,
            detail=owned .. "/" .. total .. " appearances collected; " .. (total-owned) .. " missing. " .. (set.label or set.description or "Open the set")
                .. ". Inspect one missing piece's source before choosing a run or purchase.",
            reason="A usable, partially collected set; current source availability and soloability still need checking",
            minutes=15, score=55 + math.floor(owned/total*30), action="transmog", targetID=set.setID,
            progressKind="setpiece", progressStart=owned, progressTarget=owned+1,
            icon=icon("INV_Chest_Cloth_17"), stepLabel="Find one missing piece", timeNote="15 minutes to choose a piece and its source. Farming it may take longer and drops are not guaranteed."}
    end)
    for _, s in ipairs(items) do add(s) end
    self.status.transmog = self.caches.transmog.running and "Checking your usable appearance sets in small batches..." or "No partially collected, non-limited usable sets found. Open the wardrobe and Refresh if collection data has not loaded."
end

local parentSkills={ [164]=true,[165]=true,[171]=true,[182]=true,[186]=true,[197]=true,[202]=true,[333]=true,[393]=true,[755]=true,[773]=true,[185]=true,[356]=true }
local professionIcons={ [164]="Trade_BlackSmithing",[165]="Trade_LeatherWorking",[171]="Trade_Alchemy",[182]="Trade_Herbalism",[186]="Trade_Mining",[197]="Trade_Tailoring",[202]="Trade_Engineering",[333]="Trade_Engraving",[393]="INV_Misc_Pelt_Wolf_01",[755]="INV_Misc_Gem_01",[773]="INV_Inscription_Tradeskill01",[185]="INV_Misc_Food_15",[356]="Trade_Fishing" }
function P:Professions(add)
    if C_Housing and C_Housing.GetPlayerOwnedHouses and (not self.houseRequestAt or SC:Now()-self.houseRequestAt>=60) then
        self.houseRequestAt=SC:Now(); C_Housing.GetPlayerOwnedHouses()
    end
    local api=C_TradeSkillUI
    local metadata,lines,accepted={},{},{}
    if GetProfessions and GetProfessionInfo then
        local ids={GetProfessions()}
        for slot=1,5 do
            if ids[slot] and slot~=3 then
                local name,texture,_,_,_,_,skill=GetProfessionInfo(ids[slot])
                if skill then metadata[skill]={name=name,icon=texture,secondary=slot>=4} end
            end
        end
    end
    if api and api.GetAllProfessionTradeSkillLines and api.GetProfessionInfoBySkillLineID then
        for _,id in ipairs(api.GetAllProfessionTradeSkillLines() or {}) do lines[id]=api.GetProfessionInfoBySkillLineID(id) end
    end
    if api and api.GetChildProfessionInfos then
        for _,info in ipairs(api.GetChildProfessionInfos() or {}) do lines[info.professionID]=info end
    end
    for id,info in pairs(lines) do
        if info and not parentSkills[id] and info.professionID~=794 and info.parentProfessionID~=794
            and info.skillLevel and info.skillLevel>0 and info.maxSkillLevel and info.maxSkillLevel>0 then
            local base=info.parentProfessionID or info.professionID
            accepted[base]=true
            if info.skillLevel<info.maxSkillLevel then
                local target=math.min(info.skillLevel+stepSize(),info.maxSkillLevel)
                local texture=metadata[base] and metadata[base].icon
                    or (api.GetTradeSkillTexture and api.GetTradeSkillTexture(base)) or icon(professionIcons[base] or "INV_Misc_Book_09")
                local expansion=info.expansionName
                if expansion=="" or expansion=="Unknown" or expansion==UNKNOWN then expansion=nil end
                add({id="profession:"..id,category="professions",title=(info.professionName or "Profession")..": aim for "..target.." skill",
                    detail=info.skillLevel.."/"..info.maxSkillLevel.." skill"..(expansion and " ("..expansion..")" or "")..". Gain "..(target-info.skillLevel).." point(s). Check skill-up recipes or gathering options before buying materials.",
                    reason="An unfinished expansion skill line; parent profession totals are excluded",minutes=budget(),score=66,
                    action="profession",targetID=id,progressKind="skill",progressStart=info.skillLevel,progressTarget=target,
                    icon=texture,stepLabel="One skill milestone",timeNote="A chosen skill-point target, not a prediction. Skill-ups and material costs vary."})
            end
        end
    end
    for id,info in pairs(metadata) do
        if info.secondary and not accepted[id] then
            local suggestion=planning("professions", "Check "..info.name.." progress", "Open "..info.name.." and choose a learned expansion skill to work on, then Refresh. Parent totals are not used as an expansion's skill cap.","profession",professionIcons[id])
            suggestion.id="prepare:profession"..id; suggestion.targetID=id; add(suggestion)
            -- Secondary preparation cards need distinct IDs and the correct panel.
        end
    end
    self:DecorRecipes(add)
    if self.ownedHouses and #self.ownedHouses>0 then
        local s=planning("professions","Gather lumber for one decor project","Choose a decor recipe you know, check which lumber it needs, then gather a small batch in its source zone. Open the recipe first; this idea does not assume you know a particular recipe or lumber source.","profession","INV_Misc_Branch_01")
        s.id="prepare:lumber"; add(s)
    end
    self.status.professions="No unfinished expansion skills reported. Open Cooking, Fishing or a profession's expansion sections, then Refresh. Parent totals are excluded."
end
function P:DecorRecipes(add)
    local api=C_TradeSkillUI
    if not api or not api.GetFilteredRecipeIDs or not api.GetRecipeInfo or not api.GetRecipeOutputItemData
        or not C_HousingCatalog or not C_HousingCatalog.GetCatalogEntryInfoByItem then return end
    local ids=api.GetFilteredRecipeIDs() or {}
    -- This is the currently loaded recipe view, with its filters left intact.
    if #ids==0 then return end
    if self:UseCache("decorrecipes",function(candidate)
        local count=(SoloCompassCharDB.craftCounts or {})[candidate.targetID] or 0
        candidate.progressStart=count; candidate.progressTarget=count+1; add(candidate)
    end) then return end
    local index=0
    self:Scan("decorrecipes",function() index=index+1; return ids[index] end,function(id)
        local info=api.GetRecipeInfo(id)
        if not info or not info.learned or info.disabled or info.isRecraft or info.isDummyRecipe or info.isGatheringRecipe then return end
        local output=api.GetRecipeOutputItemData(id)
        local entry=output and output.itemID and C_HousingCatalog.GetCatalogEntryInfoByItem(output.itemID)
        if not entry then return end
        local count=api.GetCraftableCount and api.GetCraftableCount(id)
        return {id="decorrecipe:"..id,category="professions",title="Craft one: "..info.name,
            detail="A known decor recipe in your loaded profession. "..(count and count>0 and "The client reports materials for at least one craft; review them before crafting." or "Check its materials and any missing lumber before crafting."),
            reason="A learned recipe whose output is in the housing catalog",minutes=15,score=count and count>0 and 78 or 57,
            action="decorrecipe",targetID=id,icon=info.icon or output.icon,stepLabel="Craft one decor item",
            progressStart=(SoloCompassCharDB.craftCounts or {})[id] or 0,progressTarget=((SoloCompassCharDB.craftCounts or {})[id] or 0)+1,
            timeNote="Preparation and one craft; material gathering can take longer. Only recipes in your current profession view are checked."}
    end)
end

function P:Archaeology(add)
    if GetProfessions and not select(3, GetProfessions()) then
        add(planning("archaeology", "Learn Archaeology for a new collecting project", "This character has no learned Archaeology profession. Visit an Archaeology trainer, then choose a digsite from your world map.", "archaeology", "Trade_Archaeology")); return
    end
    local found = false
    if GetNumArchaeologyRaces and GetArchaeologyRaceInfo then
        for race = 1, GetNumArchaeologyRaces() do
            local name, texture, _, fragments, needed = GetArchaeologyRaceInfo(race, false)
            if name and fragments and needed and needed > 0 and (not GetNumArtifactsByRace or GetNumArtifactsByRace(race) > 0) then
                found = true
                local ready = fragments >= needed
                add({id="archaeology:" .. race, category="archaeology", title=(ready and "Solve a " or "Survey toward a ") .. name .. " project",
                    detail=fragments .. "/" .. needed .. " fragments. " .. (ready and "You have enough base fragments. Open Archaeology and confirm the project before solving."
                        or "Aim for one digsite session; " .. (needed-fragments) .. " more base fragments are needed for the current project."),
                    reason=ready and "A project you can finish with fragments already collected" or "Progress toward your current Archaeology project",
                    minutes=ready and 15 or 30, score=ready and 95 or 59, action="archaeology", targetID=race,
                    icon=texture or icon("Trade_Archaeology"), stepLabel=ready and "Solve one project" or "One digsite session",
                    timeNote="Travel and available digsites vary. Keystone reductions and race-specific digsite locations are not evaluated."})
            end
        end
    end
    if not found then add(planning("archaeology", "Check your Archaeology projects", "Open Archaeology to check training, active projects and fragments. If trained, choose one digsite shown on your world map.", "archaeology", "Trade_Archaeology")) end
end

function P:Achievements(add)
    if not GetCategoryList or not GetCategoryNumAchievements or not GetAchievementInfo or not GetAchievementNumCriteria or not GetAchievementCriteriaInfo then
        add(planning("achievements", "Choose an achievement to work toward", "Open Achievements and pick one unfinished criterion. Refresh after the achievement data loads.", "achievement", "Achievement_General")); return
    end
    if self:UseCache("achievements", add) then return end
    local categories, ci, ai, count = GetCategoryList() or {}, 1, 0, 0
    -- Quest, exploration, profession, and collection roots; skip raids, PvP,
    -- legacy and feats of strength instead of assuming all achievements are solo.
    local roots = {[96]=true,[97]=true,[169]=true,[170]=true,[15117]=true}
    local function allowed(category)
        local seen = {}
        for _ = 1, 10 do
            if roots[category] then return true end
            if not GetCategoryInfo or seen[category] then return false end
            seen[category] = true
            local _, parent = GetCategoryInfo(category)
            if not parent or parent <= 0 then return false end
            category = parent
        end
        return false
    end
    local function nextAchievement()
        while categories[ci] do
            if ai == 0 then count = allowed(categories[ci]) and GetCategoryNumAchievements(categories[ci]) or 0 end
            ai=ai+1
            if ai <= count then return {category=categories[ci], index=ai} end
            ci=ci+1; ai=0
        end
    end
    local items = self:Scan("achievements", nextAchievement, function(ref)
        local id, name, _, completed, _, _, _, description, _, texture, _, guild = GetAchievementInfo(ref.category, ref.index)
        if not id or completed or guild then return end
        local total, done, fractional, nextText = GetAchievementNumCriteria(id), 0, 0
        if not total or total == 0 then return end
        for i = 1, total do
            local text, _, complete, quantity, required = GetAchievementCriteriaInfo(id, i)
            if complete then done=done+1; fractional=fractional+1
            else
                if not nextText and text then nextText = text .. ((required and required > 1) and " (" .. (quantity or 0) .. "/" .. required .. ")" or "") end
                if required and required > 0 then fractional=fractional+math.min(1,(quantity or 0)/required) end
            end
        end
        if not nextText or fractional/total < 0.5 then return end
        return {id="achievement:" .. id, category="achievements", title="Next step: " .. name,
            detail=done .. "/" .. total .. " criteria complete. Next: " .. nextText .. ". " .. (description or ""),
            reason="At least halfway through its recorded criteria progress; requirements may still involve a longer project",
            minutes=15, score=55+math.floor(fractional/total*30), action="achievement", targetID=id,
            icon=texture or icon("Achievement_General"), stepLabel="One criterion toward a bigger win",
            timeNote="A short next-step planning allowance, not a guarantee that the criterion can be completed in 15 minutes. Check its requirements."}
    end)
    for _, s in ipairs(items) do add(s) end
    self.status.achievements = self.caches.achievements.running and "Checking quest, exploration, profession and collection achievements in small batches..."
        or "No halfway-finished achievements found in the supported solo-oriented categories. Fully complete, raid, PvP, legacy and feat categories are excluded."
end

function P:Heirlooms(add)
    local api, found, listed = C_Heirloom, false, 0
    if api and api.GetNumDisplayedHeirlooms and api.GetHeirloomItemIDFromDisplayedIndex and api.GetHeirloomInfo and api.PlayerHasHeirloom then
        listed = api.GetNumDisplayedHeirlooms()
        for i = 1, listed do
            local id = api.GetHeirloomItemIDFromDisplayedIndex(i)
            if id and not api.PlayerHasHeirloom(id) then
                local name, _, _, texture, _, source = api.GetHeirloomInfo(id)
                if name and source and source ~= "" then
                    found = true
                    add({id="heirloom:" .. id, category="heirlooms", title="Plan an alt's heirloom: " .. name,
                        detail=source .. " Choose this item only if it suits an alt; check its price and currency before buying.",
                        reason="Not collected in the current Heirloom Journal view; its existing filters are respected", minutes=15,
                        score=48, action="heirloom", targetID=id, icon=texture or icon("INV_Helmet_03"), stepLabel="Choose one alt item",
                        timeNote="Source planning only. Currency farming, purchases, and upgrade costs are not estimated."})
                end
            end
        end
    end
    if not found and listed == 0 then add(planning("heirlooms", "Review heirlooms for your next alt", "Open the Heirloom Journal and choose the intended class/spec and uncollected items, then Refresh. Existing filters may hide missing items.", "heirloom", "INV_Helmet_03")) end
    if not found then self.status.heirlooms = "No missing heirlooms with source information found in the current journal view. Existing class, spec and collected filters are respected." end
end

function P:Campsites(add)
    local api, found = C_WarbandScene, false
    if api and api.SearchWarbandSceneEntries and api.GetWarbandSceneEntry and api.HasWarbandScene then
        for _, id in ipairs(api.SearchWarbandSceneEntries({ownedOnly=false, favoritesOnly=false}) or {}) do
            local entry = api.GetWarbandSceneEntry(id)
            if entry and not api.HasWarbandScene(id) and entry.source and entry.source ~= "" then
                found = true
                add({id="campsite:" .. id, category="campsites", title="Work toward " .. entry.name,
                    detail=entry.source .. " Inspect this unlock's requirements and choose one next step.",
                    reason="A missing Warband background; source comes from the live collection, availability is not assumed",
                    minutes=15, score=46, action="campsite", targetID=id, atlas="campcollection-icon-camp", icon=icon("INV_Misc_Map_01"),
                    stepLabel="One unlock requirement", timeNote="A planning step toward the background. The full unlock may require multiple sessions or an unavailable source."})
            end
        end
    end
    if not found then self.status.campsites = "No missing backgrounds with source information were reported. Open the Warband Campsite collection and Refresh." end
end

local reputationAchievements={ [1106]=947,[1090]=1008,[1091]=1007,[1098]=1009,[1119]=2082,[1156]=4598,[609]=953,[942]=893,[576]=944,[749]=955,[59]=957,[270]=954,[529]=946,[910]=956,[1015]=898,[1031]=894,[978]=899,[941]=901,[932]=902,[934]=903,[935]=900 }
local goblinFactions={ [21]=true,[369]=true,[470]=true,[577]=true,[1133]=true }
local pvpFactions={ [509]=true,[510]=true,[729]=true,[730]=true,[889]=true,[890]=true }
function P:ReputationIcon(id,info)
    if info.textureKit and C_Texture and C_Texture.GetAtlasInfo then
        local atlas="majorfactions_icons_"..info.textureKit.."512"
        if C_Texture.GetAtlasInfo(atlas) then return nil,atlas end
    end
    if goblinFactions[id] and C_Texture and C_Texture.GetAtlasInfo("raceicon128-goblin-male") then return nil,"raceicon128-goblin-male" end
    local achievement=reputationAchievements[id]
    if achievement and GetAchievementInfo then
        local _,name,_,_,_,_,_,_,_,texture=GetAchievementInfo(achievement)
        if name and info.name and (name:lower():find(info.name:lower(),1,true) or info.name:lower():find(name:lower(),1,true)) and texture then return texture end
    end
    if pvpFactions[id] then return icon(({[509]=true,[730]=true,[890]=true})[id] and "Achievement_PVP_A_01" or "Achievement_PVP_H_01") end
    return icon("Achievement_Reputation_01")
end
local factionZones={ [2507]=2022,[2510]=2112,[2511]=2024,[2503]=2023,[2590]=2339,[2594]=2214,[2570]=2215,[2600]=2255,[72]=84,[76]=85 }
function P:ReputationContext(id, info, group)
    local mapID=factionZones[id]
    local zone=mapID and C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(mapID)
    local expansion=info.expansionID and _G["EXPANSION_NAME"..info.expansionID]
    local context=(expansion and expansion..". " or "")..(zone and zone.name..". " or "")
    if context=="" and group then context="Reputation group: "..group..". " end
    return context,mapID
end
function P:ArchaeologyDestination()
    if not C_ResearchInfo or not C_ResearchInfo.GetDigSitesForMap then return end
    local maps,seen={},{}
    local current=C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    for _=1,5 do
        if not current or seen[current] then break end
        maps[#maps+1]=current; seen[current]=true
        local info=C_Map.GetMapInfo and C_Map.GetMapInfo(current)
        current=info and info.parentMapID
    end
    for _,id in ipairs({13,12,101,113,424,572,619}) do if not seen[id] then maps[#maps+1]=id end end
    for _,id in ipairs(maps) do
        local sites=C_ResearchInfo.GetDigSitesForMap(id)
        if sites and sites[1] and sites[1].position then
            local x,y=sites[1].position:GetXY()
            return id,x,y,sites[1].name
        end
    end
end

function P:Reputation(add)
    local seen, found = {}, false
    if C_MajorFactions and C_MajorFactions.GetMajorFactionIDs and C_MajorFactions.GetMajorFactionData then
        for _, id in ipairs(C_MajorFactions.GetMajorFactionIDs() or {}) do
            seen[id]=true
            local info = C_MajorFactions.GetMajorFactionData(id)
            if info and info.isUnlocked and info.renownLevel < info.maxLevel then
                found = true
                local remaining = math.max(0, info.renownLevelThreshold-info.renownReputationEarned)
                local context,mapID=self:ReputationContext(id,info)
                local texture,atlas=self:ReputationIcon(id,info)
                add({id="renown:" .. id, category="reputation", title=info.name .. ": toward Renown " .. (info.renownLevel+1),
                    mapID=mapID,detail=context .. remaining .. " reputation to the next Renown level. Choose one available faction quest or activity; check its reward before traveling.",
                    reason="An unlocked, unfinished Renown track", minutes=15, score=60+(remaining <= 500 and 15 or 0),
                    action="reputation", targetID=id, progressKind="renown", progressStart=info.renownLevel, progressTarget=info.renownLevel+1,
                    icon=texture or icon("Achievement_Reputation_01"),atlas=atlas, stepLabel="One faction activity", timeNote="One next-step session, not a promise of a full Renown level. Quest availability and gains vary."})
            end
        end
    end
    if C_Reputation and C_Reputation.GetNumFactions and C_Reputation.GetFactionDataByIndex then
        local group
        for i = 1, C_Reputation.GetNumFactions() do
            local info = C_Reputation.GetFactionDataByIndex(i)
            if info and info.isHeader and not info.isHeaderWithRep then group=info.name end
            if info and not seen[info.factionID] and (not info.isHeader or info.isHeaderWithRep) and not info.atWarWith
                and info.reaction and info.reaction >= 4 and info.reaction < 8 and info.nextReactionThreshold > info.currentStanding then
                found = true
                local remaining = info.nextReactionThreshold-info.currentStanding
                local context,mapID=self:ReputationContext(info.factionID,info,group)
                local texture,atlas=self:ReputationIcon(info.factionID,info)
                add({id="reputation:" .. info.factionID, category="reputation", title="A little more reputation: " .. info.name,
                    mapID=mapID,detail=context .. remaining .. " reputation to the next standing. Choose one available quest, turn-in or dungeon source for this faction.",
                    reason="An unfinished known reputation" .. (info.isWatched and "; currently watched" or "; includes older factions visible in your reputation list"),
                    minutes=15, score=(info.isWatched and 72 or 51)+(remaining <= 500 and 10 or 0), action="reputation", targetID=info.factionID,
                    progressKind="reputation", progressStart=info.currentStanding, progressTarget=info.nextReactionThreshold,
                    icon=texture or icon("Achievement_Reputation_01"),atlas=atlas, stepLabel="One reputation activity", timeNote="A next-step session, not a prediction of reaching the next standing. Collapsed reputation headers are left unchanged."})
            end
        end
    end
    if not found then self.status.reputation = "No unfinished unlocked tracks were reported. Expand older factions in your Reputation panel and Refresh to include them." end
end

function P:RememberArtifact()
    local api = C_ArtifactUI
    if not SoloCompassCharDB or not api or not api.GetArtifactInfo or not api.GetNumAppearanceSets or not api.GetAppearanceSetInfo or not api.GetAppearanceInfo then return end
    local item, _, name, texture = api.GetArtifactInfo()
    if not item then return end
    for set = 1, api.GetNumAppearanceSets() do
        local _, _, _, count = api.GetAppearanceSetInfo(set)
        for index = 1, count or 0 do
            local id = api.GetAppearanceInfo(set,index)
            if id then SoloCompassCharDB.artifactAppearances[id]={weapon=name, icon=texture, itemID=item} end
        end
    end
end
function P:Artifacts(add)
    self:RememberArtifact()
    local api, known = C_ArtifactUI, false
    if api and api.GetAppearanceInfoByID then
        for id, weapon in pairs(SoloCompassCharDB.artifactAppearances) do
            local _, _, name, _, unlocked, requirement, _, _, _, _, _, _, _, obtainable = api.GetAppearanceInfoByID(id)
            if name then known=true end
            if name and unlocked == false and obtainable == true and requirement and requirement ~= "" then
                add({id="artifact:" .. id, category="artifacts", title=weapon.weapon .. ": " .. name,
                    detail=requirement .. " Choose one requirement to work on; open the appearance in your Legion artifact forge to inspect the full conditions.",
                    reason="The client reports a locked, obtainable appearance for an artifact you have inspected",
                    minutes=15, score=58, action="artifact", targetID=id, icon=weapon.icon or icon("INV_Sword_39"),
                    stepLabel="One appearance requirement", timeNote="A next-step allowance. Unlocks can span multiple sessions; unobtainable appearances are excluded."})
            end
        end
    end
    if not known then add(planning("artifacts", "Inspect a Legion artifact's appearances", "Visit your class hall's artifact forge with a Legion artifact. Open its appearances once so Solo Compass can remember the appearance IDs, then Refresh. It cannot inspect every class weapon remotely.", "artifact", "INV_Sword_39")) end
    self.status.artifacts = "Only inspected artifacts can be checked. Unlocked and explicitly unobtainable appearances are excluded."
end

function P:PvP(add)
    local level = UnitHonorLevel and UnitHonorLevel("player")
    local prepare = budget() == 15
    add({id="activity:pvp", category="pvp", title=prepare and "Choose a solo-queue PvP goal" or "Play one unranked battleground",
        detail=(level and "Honor level " .. level .. ". " or "") .. (prepare and "Review Honor rewards and choose one reward or practice goal before queueing."
            or "Queue on your own for one unranked battleground. Aim to practice one objective or earn some Honor; a win is not required for your session to count."),
        reason="Opt-in solo queue; the match itself is group PvP", minutes=prepare and 15 or 30, score=50, action="pvp",
        icon=icon("Achievement_PVP_A_01"), stepLabel=prepare and "Choose a practice goal" or "One match",
        timeNote="Queue and match length vary. Rated eligibility and reward upgrades are not inferred; the addon never queues or enables War Mode."})
end

function P:Build(add)
    self.status = {}
    self:Queues(add)
    local interests = SoloCompassCharDB.interests
    for category, method in pairs({mounts="Mounts",toys="Toys",delves="Delves",pets="Pets",housing="Housing",transmog="Transmog",professions="Professions",archaeology="Archaeology",achievements="Achievements",
        heirlooms="Heirlooms",campsites="Campsites",reputation="Reputation",artifacts="Artifacts",pvp="PvP"}) do
        if interests[category] then self[method](self, add) end
    end
end

function P:IsFinished(id)
    if id:match("^decorrecipe:") then
        local saved=SoloCompassCharDB.goalID==id and SoloCompassCharDB.goalSnapshot
        return saved and ((SoloCompassCharDB.craftCounts or {})[saved.targetID] or 0)>=saved.progressTarget or false
    end
    if id:match("^houseupgrade:") then
        local saved=SoloCompassCharDB.goalID==id and SoloCompassCharDB.goalSnapshot
        local favor=self.houseFavor and self.houseFavor[id:sub(14)]
        return saved and favor and favor.houseLevel>=saved.progressTarget or false
    end
    if id:match("^petlevel:") then
        local saved=SoloCompassCharDB.goalID==id and SoloCompassCharDB.goalSnapshot
        local info=self:HasPetCatalog() and C_PetJournal.GetPetInfoTableByPetID(id:sub(10))
        return info and info.petLevel and info.petLevel >= (saved and saved.progressTarget or 25) or false
    end
    local kind, number = id:match("^(%a+):(%d+)$"); number=tonumber(number)
    if not number then return false end
    if kind == "endeavor" and C_NeighborhoodInitiative and C_NeighborhoodInitiative.GetInitiativeTaskInfo then
        local saved = SoloCompassCharDB.goalID == id and SoloCompassCharDB.goalSnapshot
        if saved then
            local initiative = C_NeighborhoodInitiative.GetNeighborhoodInitiativeInfo and C_NeighborhoodInitiative.GetNeighborhoodInitiativeInfo()
            if not initiative or not initiative.isLoaded or initiative.initiativeID ~= saved.initiativeID
                or initiative.currentCycleID ~= saved.cycleID or initiative.neighborhoodGUID ~= saved.neighborhoodGUID then return false end
        end
        local task = C_NeighborhoodInitiative.GetInitiativeTaskInfo(number)
        return task and (task.completed == true or (saved and saved.progressTarget and (task.timesCompleted or 0) >= saved.progressTarget)) or false
    end
    if kind == "set" and C_TransmogSets and C_TransmogSets.GetSetInfo then
        local info=C_TransmogSets.GetSetInfo(number); if info and info.collected == true then return true end
    elseif kind == "achievement" and GetAchievementInfo then return select(4,GetAchievementInfo(number)) == true
    elseif kind == "heirloom" and C_Heirloom and C_Heirloom.PlayerHasHeirloom then return C_Heirloom.PlayerHasHeirloom(number)
    elseif kind == "campsite" and C_WarbandScene and C_WarbandScene.HasWarbandScene then return C_WarbandScene.HasWarbandScene(number)
    elseif kind == "artifact" and C_ArtifactUI and C_ArtifactUI.GetAppearanceInfoByID then return select(5,C_ArtifactUI.GetAppearanceInfoByID(number)) == true
    elseif kind == "lfr" and GetLFGDungeonNumEncounters and GetLFGDungeonEncounterInfo then
        local count = GetLFGDungeonNumEncounters(number)
        if count and count > 0 then
            for index=1,count do if not select(3,GetLFGDungeonEncounterInfo(number,index)) then return false end end
            return true
        end
    end
    local snapshot = SoloCompassCharDB.goalID == id and SoloCompassCharDB.goalSnapshot
    if snapshot and snapshot.progressTarget then
        if kind == "set" and snapshot.progressKind == "setpiece" and C_TransmogSets and C_TransmogSets.GetSetPrimaryAppearances then
            local appearances=C_TransmogSets.GetSetPrimaryAppearances(number)
            if not appearances then return false end
            local count=0; for _, appearance in ipairs(appearances) do if appearance.collected then count=count+1 end end
            return count >= snapshot.progressTarget
        elseif kind == "profession" and C_TradeSkillUI and C_TradeSkillUI.GetProfessionInfoBySkillLineID then
            local info=C_TradeSkillUI.GetProfessionInfoBySkillLineID(number)
            return info and info.skillLevel >= snapshot.progressTarget
        elseif kind == "renown" and C_MajorFactions and C_MajorFactions.GetMajorFactionData then
            local info=C_MajorFactions.GetMajorFactionData(number); return info and info.renownLevel >= snapshot.progressTarget
        elseif kind == "reputation" and C_Reputation and C_Reputation.GetFactionDataByID then
            local info=C_Reputation.GetFactionDataByID(number); return info and info.currentStanding >= snapshot.progressTarget
        end
    end
    return false
end
