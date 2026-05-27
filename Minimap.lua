-- SoloCompass: minimap button via LibDBIcon-1.0

SoloCompass.Minimap = {}
local MM = SoloCompass.Minimap
local SC = SoloCompass

local ICON = "Interface\\Icons\\INV_Misc_Map_01"

function MM:Init()
    local LDB     = LibStub("LibDataBroker-1.1")
    local LDBIcon = LibStub("LibDBIcon-1.0")

    local launcher = LDB:NewDataObject("SoloCompass", {
        type  = "launcher",
        icon  = ICON,
        label = "SoloCompass",
        OnClick = function(_, button)
            if button == "LeftButton" then
                SC:Toggle()
            end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:SetText("SoloCompass", 1, 1, 1)
            tooltip:AddLine("Click to toggle dashboard", 0.8, 0.8, 0.8)
            tooltip:Show()
        end,
    })

    -- SoloCompassDB.minimap persists position and hide state across sessions
    LDBIcon:Register("SoloCompass", launcher, SoloCompassDB.minimap)
    self.icon = LDBIcon
end
