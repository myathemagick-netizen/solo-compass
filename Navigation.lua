-- Use destinations supplied by the client rather than guessed coordinates.
SoloCompass.Navigation = {}
local N, SC = SoloCompass.Navigation, SoloCompass
local panelActions = {decorrecipe=true,houseupgrade=true,questlog=true,pet=true,petlevel=true,lfr=true,timewalking=true,transmog=true,profession=true,archaeology=true,achievement=true,
    pvp=true,heirloom=true,campsite=true,reputation=true,artifact=true,endeavor=true}
function N:Destination(s)
    if s.mapID and s.mapX and s.mapY then return s.mapID,s.mapX,s.mapY end
    if s.action=="archaeology" then return SC.Progress:ArchaeologyDestination() end
    if s.action == "quest" and C_QuestLog and C_QuestLog.GetNextWaypoint then
        return C_QuestLog.GetNextWaypoint(s.targetID)
    end
    if s.mapID and s.instanceID and C_EncounterJournal
        and C_EncounterJournal.GetInstanceForGameMap and C_EncounterJournal.GetDungeonEntrancesForMap then
        local journalID = C_EncounterJournal.GetInstanceForGameMap(s.instanceID)
        if journalID then
            for _, entrance in ipairs(C_EncounterJournal.GetDungeonEntrancesForMap(s.mapID) or {}) do
                if entrance.journalInstanceID == journalID and entrance.position then
                    local x, y = entrance.position:GetXY()
                    return s.mapID, x, y
                end
            end
        end
    end
    return s.mapID
end
function N:Describe(s)
    if s.action=="archaeology" then return "Show an active digsite reported by the client, preferring your current area. Fragment types are not identified by this map API; check the site before traveling." end
    if s.action=="reputation" then return s.mapID and "Open this faction's source zone. A verified quartermaster pin is not available." or "Open the world map. This faction does not yet have a verified source zone in Solo Compass; use the book for reputation details." end
    if s.action == "quest" then return "Follow the game's next quest waypoint. Completed quests point toward their turn-in when the client provides it." end
    if s.instanceID then return "Pin the dungeon or raid entrance when the client provides it. Otherwise open its zone map. Travel time is additional." end
    if s.mapID then return "Open the source zone. An exact source pin is not available for this idea." end
    if panelActions[s.action] then return "Open this activity's progress or collection panel to inspect its next step. A geographical destination has not been chosen yet." end
    return "Open the world map to choose a destination. This general activity has no specific destination yet."
end
function N:Go(s)
    if InCombatLockdown() then print("|cffe8bb64Solo Compass:|r Navigate after combat."); return end
    if s.action == "quest" then SC.UI:HandleCardClick(s); return end
    if not s.mapID and s.action~="archaeology" and s.action~="reputation" and panelActions[s.action] then SC.UI:HandleCardClick(s); return end
    local mapID, x, y = self:Destination(s)
    if s.action=="archaeology" then print("|cffe8bb64Solo Compass:|r "..(mapID and "Showing an active digsite; its fragment type is not verified." or "No active digsites were reported. Enable digsites on the world map and check your trained continents.")) end
    if mapID and x and y and x >= 0 and x <= 1 and y >= 0 and y <= 1
        and C_Map and C_Map.CanSetUserWaypointOnMap and C_Map.CanSetUserWaypointOnMap(mapID)
        and C_Map.SetUserWaypoint and UiMapPoint and UiMapPoint.CreateFromCoordinates then
        local wasSet = C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(mapID, x, y))
        if wasSet and C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then C_SuperTrack.SetSuperTrackedUserWaypoint(true) end
        if not wasSet then print("|cffe8bb64Solo Compass:|r The game could not place this entrance pin. Opening its zone map.") end
    else
        print("|cffe8bb64Solo Compass:|r " .. (mapID and "Opening the source zone; an exact pin is unavailable." or "Choose a destination on the world map for this activity."))
    end
    SC.UI:OpenMap(mapID)
    SC.UI:Hide()
end
