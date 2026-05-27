-- SoloCompass: suggestion engine
-- Reads live game APIs + Data tables, returns 2-4 suggestions per pillar.

SoloCompass.Suggestions = {}
local SS = SoloCompass.Suggestions
local D  = SoloCompass.Data

local MAX_PER_PILLAR = 4

-- Entry point: returns { housing={}, collector={}, quests={} }
function SS:Build()
    local interests = SoloCompassCharDB.interests
    return {
        housing   = interests.housing   and self:BuildHousing()   or {},
        collector = interests.collector and self:BuildCollector()  or {},
        quests    = interests.quests    and self:BuildQuests()     or {},
    }
end

-- Housing pillar ----------------------------------------------------------

function SS:BuildHousing()
    local results = {}
    for _, nudge in ipairs(D.HousingNudges) do
        if #results >= MAX_PER_PILLAR then break end
        -- TODO: gate "visit" nudge on C_PlayerHousing API when available
        table.insert(results, {
            pillar = "housing",
            id     = nudge.id,
            text   = nudge.text,
            icon   = "Interface\\Icons\\INV_Misc_House_01",
        })
    end
    return results
end

-- Collector pillar --------------------------------------------------------

function SS:BuildCollector()
    local results = {}

    -- Mounts
    for _, entry in ipairs(D.Mounts) do
        if #results >= MAX_PER_PILLAR then break end
        if not self:HasMount(entry.id) then
            table.insert(results, {
                pillar  = "collector",
                subtype = "mount",
                id      = entry.id,
                name    = entry.name,
                text    = entry.name .. " — " .. entry.source,
                icon    = C_MountJournal.GetMountInfoByID(entry.id) and
                          select(3, C_MountJournal.GetMountInfoByID(entry.id)) or
                          "Interface\\Icons\\Ability_Mount_Wyvern_01",
            })
        end
    end

    -- Pets (fill remaining slots)
    for _, entry in ipairs(D.Pets) do
        if #results >= MAX_PER_PILLAR then break end
        if not self:HasPet(entry.id) then
            table.insert(results, {
                pillar  = "collector",
                subtype = "pet",
                id      = entry.id,
                text    = entry.name .. " — " .. entry.source,
                icon    = "Interface\\Icons\\INV_Misc_MonsterHead_01",
            })
        end
    end

    -- Toys (fill remaining slots)
    for _, entry in ipairs(D.Toys) do
        if #results >= MAX_PER_PILLAR then break end
        if not self:HasToy(entry.id) then
            table.insert(results, {
                pillar  = "collector",
                subtype = "toy",
                id      = entry.id,
                text    = entry.name .. " — " .. entry.source,
                icon    = "Interface\\Icons\\INV_Misc_Toy_10",
            })
        end
    end

    return results
end

function SS:HasMount(mountID)
    local _, _, _, _, _, _, _, _, _, _, isCollected = C_MountJournal.GetMountInfoByID(mountID)
    return isCollected == true
end

function SS:HasPet(speciesID)
    local count = C_PetJournal.GetNumCollectedInfo(speciesID)
    return count and count > 0
end

function SS:HasToy(itemID)
    return PlayerHasToy(itemID)
end

-- Quests pillar -----------------------------------------------------------
-- Scans the full quest log for non-daily, non-task quests from older content
-- (level < 70 = pre-TWW) that are just sitting there unfinished.
-- Quests with completed objectives are surfaced first as easy wins.

local MAX_QUESTS = 3

-- TWW content begins at level 70. Anything below is pre-TWW.
local CURRENT_CONTENT_FLOOR = 70

function SS:BuildQuests()
    local readyToTurnIn = {}
    local stalled       = {}
    local currentZone   = ""
    local numEntries    = C_QuestLog.GetNumQuestLogEntries()

    for i = 1, numEntries do
        local info = C_QuestLog.GetInfo(i)
        if not info then break end

        if info.isHeader then
            currentZone = info.title or ""
        elseif self:IsAbandonedCandidate(info) then
            local suffix = info.isComplete and " (ready to turn in!)" or ""
            local entry = {
                pillar    = "quests",
                id        = info.questID,
                text      = info.title .. "  |  " .. currentZone .. suffix,
                icon      = "Interface\\Icons\\INV_Misc_Scroll_05",
                questName = info.title,
                zone      = currentZone,
            }
            if info.isComplete then
                table.insert(readyToTurnIn, entry)
            else
                table.insert(stalled, entry)
            end
        end
    end

    -- Merge: completed objectives first, then stalled, cap at MAX_QUESTS
    local results = {}
    for _, e in ipairs(readyToTurnIn) do
        if #results >= MAX_QUESTS then break end
        table.insert(results, e)
    end
    for _, e in ipairs(stalled) do
        if #results >= MAX_QUESTS then break end
        table.insert(results, e)
    end
    return results
end

-- Returns true if this quest log entry looks like abandoned older-content work.
function SS:IsAbandonedCandidate(info)
    if info.isHeader  then return false end
    if info.isHidden  then return false end
    if info.isTask    then return false end  -- world quests / tasks
    if info.isBounty  then return false end
    if info.frequency ~= 0 then return false end  -- 1=daily, 2=weekly
    -- Level below the TWW floor means this quest is from a previous expansion
    return info.level and info.level < CURRENT_CONTENT_FLOOR
end
