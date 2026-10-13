SoloCompass.Suggestions = {}
local SS, SC, D = SoloCompass.Suggestions, SoloCompass, SoloCompass.Data
function SS:IsLocked(instanceID, difficultyID)
    if not instanceID or not GetNumSavedInstances or not GetSavedInstanceInfo then return false end
    for index = 1, GetNumSavedInstances() do
        local _, _, reset, difficulty, locked, _, _, _, _, _, _, _, _, savedID = GetSavedInstanceInfo(index)
        if savedID == instanceID and locked and reset and reset > 0
            and (not difficultyID or difficulty == difficultyID) then return true end
    end
    return false
end
function SS:BuildQuests(add)
    if not C_QuestLog then return end
    local zone = "Quest log"
    for index = 1, C_QuestLog.GetNumQuestLogEntries() do
        local info = C_QuestLog.GetInfo(index)
        if info then
            if info.isHeader then zone = info.title or zone
            elseif info.questID and info.questID > 0 and not info.isHidden and not info.isTask
                and not info.isBounty and (info.frequency == nil or info.frequency == 0)
                and (not info.suggestedGroup or info.suggestedGroup <= 1) then
                local complete = C_QuestLog.IsComplete(info.questID)
                add({ id = "quest:" .. info.questID, category = "quests", title = info.title,
                    detail = zone .. ". " .. (complete and "Objectives complete. Find the turn-in to clear a quest-log slot."
                        or "Finish one quest already in your log. Open its details to check the next objective."),
                    reason = complete and "Ready to turn in" or "Already in your quest log",
                    minutes = complete and 15 or 30, score = complete and 100 or (info.isOnMap and 85 or 70),
                    action = "quest", targetID = info.questID, icon = "Interface\\Icons\\INV_Misc_Scroll_05" })
            end
        end
    end
end
function SS:BuildMounts(add)
    if not C_MountJournal or not C_MountJournal.GetMountFromItem then return end
    for _, entry in ipairs(D.Mounts) do
        local mountID = C_MountJournal.GetMountFromItem(entry.itemID)
        if mountID then
            local name, _, icon, _, _, _, _, _, _, hidden, owned = C_MountJournal.GetMountInfoByID(mountID)
            if name and owned == false and not hidden and UnitLevel("player") >= entry.minLevel
                and not self:IsLocked(entry.instanceID, entry.difficultyID) then
                add({ id = "mount:" .. mountID, category = "mounts", title = name,
                    detail = entry.source .. ". " .. entry.step .. " Rare drop; travel adds time.",
                    reason = "Missing from your mount collection", minutes = entry.minutes, score = 65,
                    action = "mount", targetID = mountID, mapID = entry.mapID, icon = icon })
            end
        end
    end
end
function SS:BuildPets(add)
    if not C_PetJournal or not C_PetJournal.GetPetInfoBySpeciesID then return end
    for _, entry in ipairs(D.Pets) do
        local name, icon, _, _, source, _, _, _, _, _, obtainable = C_PetJournal.GetPetInfoBySpeciesID(entry.speciesID)
        local owned = C_PetJournal.GetNumCollectedInfo(entry.speciesID)
        if name and owned == 0 and obtainable ~= false and source and source ~= "" then
            add({ id = "pet:" .. entry.speciesID, category = "pets", title = name,
                detail = source, reason = "Missing from your pet collection; acquisition may cost gold",
                minutes = entry.minutes, score = 60, action = "pet", targetID = entry.speciesID, icon = icon })
        end
    end
end
function SS:BuildToys(add)
    if not PlayerHasToy then return end
    for _, entry in ipairs(D.Toys) do
        if not PlayerHasToy(entry.itemID) and UnitLevel("player") >= entry.minLevel then
            add({ id = "toy:" .. entry.itemID, category = "toys", title = entry.name,
                detail = entry.step, reason = "Missing from your toy box; rare drop",
                minutes = entry.minutes, score = 60, action = "toy", targetID = entry.itemID,
                mapID = entry.mapID, icon = "Interface\\Icons\\INV_Misc_Toy_10" })
        end
    end
end
function SS:BuildRaids(add)
    for _, entry in ipairs(D.Raids) do
        if UnitLevel("player") >= entry.minLevel and not self:IsLocked(entry.id) then
            add({ id = "raid:" .. entry.id, category = "raids", title = entry.title,
                detail = entry.detail .. " Check your saved instances before traveling.",
                reason = "A legacy outing; missing appearances are not checked",
                minutes = entry.minutes, score = 50, action = "map", mapID = entry.mapID,
                icon = "Interface\\Icons\\INV_Helmet_03" })
        end
    end
end
function SS:BuildActivities(add)
    local maxLevel = GetMaxLevelForLatestExpansion and GetMaxLevelForLatestExpansion()
    if maxLevel and UnitLevel("player") >= maxLevel then
        add({ id = "activity:delve", category = "delves", title = "Run one Delve",
            detail = "Find a Delve on your world map and choose a tier you can comfortably finish solo. Check rewards and keys in game.",
            reason = "A self-paced progression session", minutes = 30, score = 55, action = "map",
            icon = "Interface\\Icons\\INV_Misc_Map_01" })
        add({ id = "activity:lfr", category = "lfr", title = "Try a Raid Finder wing",
            detail = "Check the Raid Finder for an available wing and entry requirements. You queue alone but play with a group; queue time varies.",
            reason = "Optional matchmade progression", minutes = 60, score = 45, action = "lfr",
            icon = "Interface\\Icons\\INV_Misc_GroupLooking" })
    end
    add({ id = "activity:housing", category = "housing", title = "Make a small housing improvement",
        detail = "If you have housing unlocked, pick one corner to decorate or check your neighborhood's available endeavors.",
        reason = "A creative break; unlock and rewards are not checked", minutes = 15, score = 35, action = "info",
        icon = "Interface\\Icons\\INV_Misc_House_01" })
end
function SS:Build()
    local all, eligible = {}, {}
    local interests, budget = SoloCompassCharDB.interests, SoloCompassCharDB.minutes
    local function add(candidate)
        all[#all + 1] = candidate
        if interests[candidate.category] and candidate.minutes <= budget
            and not SC.skipped[candidate.id] and candidate.id ~= SoloCompassCharDB.goalID then
            eligible[#eligible + 1] = candidate
        end
    end
    self:BuildQuests(add); self:BuildMounts(add); self:BuildPets(add)
    self:BuildToys(add); self:BuildRaids(add); self:BuildActivities(add)
    table.sort(eligible, function(a, b)
        if a.score ~= b.score then return a.score > b.score end
        return a.id < b.id
    end)
    -- Round-robin categories prevents a long quest log or mount list taking every slot.
    local buckets, order = {}, {}
    for _, candidate in ipairs(eligible) do
        if not buckets[candidate.category] then
            buckets[candidate.category] = {}; order[#order + 1] = candidate.category
        end
        table.insert(buckets[candidate.category], candidate)
    end
    local result = {}
    if #order > 0 then
        for round = 1, #eligible do
            for index = 1, #order do
                local key = order[((index - 1 + SC.rotation) % #order) + 1]
                local bucket = buckets[key]
                if round <= #bucket then
                    result[#result + 1] = bucket[((round - 1 + SC.rotation) % #bucket) + 1]
                    if #result == 3 then return result, all end
                end
            end
        end
    end
    return result, all
end
function SS:IsGoalFinished(id)
    local kind, number = id:match("^(%a+):(%d+)$")
    number = tonumber(number)
    if not number then return false end
    if kind == "quest" and C_QuestLog then return C_QuestLog.IsQuestFlaggedCompleted(number)
    elseif kind == "mount" and C_MountJournal then return select(11, C_MountJournal.GetMountInfoByID(number)) == true
    elseif kind == "pet" and C_PetJournal then
        local count = C_PetJournal.GetNumCollectedInfo(number); return count and count > 0
    elseif kind == "toy" and PlayerHasToy then return PlayerHasToy(number) end
    return false
end
