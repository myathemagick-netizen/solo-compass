-- SoloCompass: core init, event handling, SavedVariables

SoloCompass = {}
local SC = SoloCompass

-- Defaults applied on first login per character
local CHAR_DEFAULTS = {
    enabled = true,
    interests = {
        housing   = true,
        collector = true,
        quests    = true,
    },
    lastReset = 0,
    setupDone = false,
}

-- Account-wide defaults
local DB_DEFAULTS = {
    version = 1,
    minimap = { hide = false },  -- LibDBIcon reads/writes position state into this table
}

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")

frame:SetScript("OnEvent", function(self, event, ...)
    SC[event](SC, ...)
end)

function SC:ADDON_LOADED(addonName)
    if addonName ~= "SoloCompass" then return end

    -- Init account DB
    SoloCompassDB = SoloCompassDB or {}
    for k, v in pairs(DB_DEFAULTS) do
        if SoloCompassDB[k] == nil then SoloCompassDB[k] = v end
    end

    -- Init per-character DB
    SoloCompassCharDB = SoloCompassCharDB or {}
    for k, v in pairs(CHAR_DEFAULTS) do
        if SoloCompassCharDB[k] == nil then SoloCompassCharDB[k] = v end
    end
end

function SC:PLAYER_LOGIN()
    SC.Minimap:Init()

    if not SoloCompassCharDB.setupDone then
        SC.UI:ShowSetupWizard()
        return
    end

    if SoloCompassCharDB.enabled then
        SC:RefreshSuggestions()
        SC.UI:Show()
    end
end

function SC:ZONE_CHANGED_NEW_AREA()
    -- Future: surface zone-relevant tips
end

function SC:RefreshSuggestions()
    SC.currentSuggestions = SC.Suggestions:Build()
end

function SC:Toggle()
    if SC.UI.dashboard:IsShown() then
        SC.UI:Hide()
    else
        SC:RefreshSuggestions()
        SC.UI:Show()
    end
end

SLASH_SOLOCOMPASS1 = "/solocompass"
SLASH_SOLOCOMPASS2 = "/sc"
SlashCmdList["SOLOCOMPASS"] = function() SC:Toggle() end
