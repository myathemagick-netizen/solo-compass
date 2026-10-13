-- Reusable fixed-size cards keep the dashboard calm and avoid growing off-screen.
SoloCompass.UI = {}
local UI, SC, D = SoloCompass.UI, SoloCompass, SoloCompass.Data
local W, H = 800, 620
local gold = { 0.91, 0.73, 0.39 }
local muted = { 0.66, 0.72, 0.77 }
local backdrop = { bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 }
local function panel(parent, width, height, r, g, b, name)
    local f = CreateFrame("Frame", name, parent, "BackdropTemplate")
    f:SetSize(width, height); f:SetBackdrop(backdrop)
    f:SetBackdropColor(r or 0.06, g or 0.09, b or 0.12, 0.98)
    f:SetBackdropBorderColor(0.22, 0.29, 0.34, 1)
    return f
end
local function label(parent, template, text, x, y, width, color)
    local fs = parent:CreateFontString(nil, "OVERLAY", template)
    fs:SetPoint("TOPLEFT", x, y); fs:SetWidth(width); fs:SetJustifyH("LEFT")
    fs:SetText(text or ""); fs:SetTextColor(unpack(color or { 0.92, 0.94, 0.95 }))
    return fs
end
local function button(parent, text, width, callback)
    local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
    b:SetSize(width, 26); b:SetBackdrop(backdrop)
    b:SetBackdropColor(0.13, 0.19, 0.24, 1); b:SetBackdropBorderColor(0.30, 0.39, 0.44, 1)
    local fs = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fs:SetPoint("CENTER"); fs:SetText(text); b.text = fs
    b:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(unpack(gold)) end)
    b:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(0.30, 0.39, 0.44, 1) end)
    b:SetScript("OnClick", callback)
    return b
end
local function tooltip(owner, title, detail)
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:SetText(title, 1, 0.85, 0.5)
    GameTooltip:AddLine(detail or "", 0.9, 0.92, 0.94, true); GameTooltip:Show()
end
local function checkbox(parent)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb.text = cb.text or cb.Text
    if not cb.text then
        cb.text = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        cb.text:SetPoint("LEFT", cb, "RIGHT", 2, 0)
    end
    return cb
end
local function plain(text)
    return (text or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
        :gsub("|H.-|h(.-)|h", "%1"):gsub("|T.-|t", ""):gsub("|n", " "):gsub("[\r\n]+", " ")
end
function UI:CreateCard(parent, index)
    local card = panel(parent, 546, 119, 0.09, 0.13, 0.17)
    card:SetPoint("TOPLEFT", 232, -196 - (index - 1) * 127)
    local stripe = card:CreateTexture(nil, "ARTWORK")
    stripe:SetColorTexture(0.32, 0.69, 0.65); stripe:SetWidth(3)
    stripe:SetPoint("TOPLEFT", 0, 0); stripe:SetPoint("BOTTOMLEFT", 0, 0)
    card.icon = card:CreateTexture(nil, "ARTWORK")
    card.icon:SetSize(34, 34); card.icon:SetPoint("TOPLEFT", 14, -15)
    card.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    card.meta = label(card, "GameFontNormalSmall", "", 60, -13, 466, gold)
    card.title = label(card, "GameFontHighlight", "", 60, -30, 466)
    card.title:SetHeight(18); card.title:SetWordWrap(false)
    card.detail = label(card, "GameFontHighlightSmall", "", 14, -56, 518, muted)
    card.detail:SetHeight(27); card.detail:SetWordWrap(true); card.detail:SetJustifyV("TOP")
    card.choose = button(card, "Make my goal", 112, function() if card.suggestion then SC:SetGoal(card.suggestion) end end)
    card.choose:SetPoint("BOTTOMLEFT", 14, 8)
    card.open = button(card, "Open", 118, function() if card.suggestion then UI:HandleCardClick(card.suggestion) end end)
    card.open:SetPoint("LEFT", card.choose, "RIGHT", 8, 0)
    card.skip = button(card, "Skip for now", 98, function() if card.suggestion then SC:Skip(card.suggestion) end end)
    card.skip:SetPoint("BOTTOMRIGHT", -14, 8)
    card:EnableMouse(true)
    card:SetScript("OnEnter", function(self)
        if self.suggestion then tooltip(self, self.suggestion.title, self.suggestion.reason .. "\n\n" .. self.suggestion.detail) end
    end)
    card:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return card
end
function UI:CreateDashboard()
    local f = panel(UIParent, W, H, nil, nil, nil, "SoloCompassFrame")
    f:SetScale(math.min(1, UIParent:GetWidth() / (W + 40), UIParent:GetHeight() / (H + 40)))
    f:SetPoint("CENTER"); f:SetClampedToScreen(true); f:SetFrameStrata("DIALOG")
    f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relativePoint, x, y = self:GetPoint()
        SoloCompassCharDB.position = { point = point, relativePoint = relativePoint, x = x, y = y }
    end)
    local position = SoloCompassCharDB.position
    if type(position) == "table" and position.point and position.relativePoint then
        f:ClearAllPoints(); f:SetPoint(position.point, UIParent, position.relativePoint, position.x or 0, position.y or 0)
    end
    tinsert(UISpecialFrames, "SoloCompassFrame")
    local edge = f:CreateTexture(nil, "ARTWORK")
    edge:SetColorTexture(unpack(gold)); edge:SetHeight(3)
    edge:SetPoint("TOPLEFT", 1, -1); edge:SetPoint("TOPRIGHT", -1, -1)
    local icon = f:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\Icons\\INV_Misc_Map_01"); icon:SetSize(40, 40); icon:SetPoint("TOPLEFT", 22, -24)
    label(f, "GameFontHighlightLarge", "SOLO COMPASS", 76, -25, 520, gold)
    label(f, "GameFontHighlightSmall", "A little direction for your next adventure.", 76, -49, 590, muted)
    local close = button(f, "Close", 60, function() UI:Hide() end)
    close:SetPoint("TOPRIGHT", -22, -25)
    local sidebar = panel(f, 192, 477, 0.075, 0.105, 0.14)
    sidebar:SetPoint("TOPLEFT", 20, -96)
    label(sidebar, "GameFontNormalSmall", "YOUR SESSION", 14, -15, 164, gold)
    self.timeButtons = {}
    for index, minutes in ipairs({ 15, 30, 60 }) do
        local b = button(sidebar, minutes .. "m", 50, function()
            SoloCompassCharDB.minutes = minutes; SC.rotation = 0
            SC:RefreshSuggestions(); UI:PopulateCards()
        end)
        b:SetPoint("TOPLEFT", 14 + (index - 1) * 56, -37)
        self.timeButtons[minutes] = b
    end
    label(sidebar, "GameFontNormalSmall", "WHAT SOUNDS GOOD?", 14, -87, 164, gold)
    self.interestChecks = {}
    for index, category in ipairs(D.Categories) do
        local cb = checkbox(sidebar)
        cb:SetSize(26, 26); cb:SetPoint("TOPLEFT", 10, -109 - (index - 1) * 33)
        cb.text:SetText(category.label); cb.text:SetFontObject(GameFontHighlightSmall)
        cb:SetScript("OnClick", function(self)
            SoloCompassCharDB.interests[category.key] = self:GetChecked() and true or false
            SC.rotation = 0; SC:RefreshSuggestions(); UI:PopulateCards()
        end)
        self.interestChecks[category.key] = cb
    end
    label(sidebar, "GameFontHighlightSmall", "Choose what you enjoy.\nOne goal is enough.", 14, -394, 164, muted)
    local settings = button(sidebar, "Preferences", 164, function() UI:ShowPreferences() end)
    settings:SetPoint("BOTTOMLEFT", 14, 14)
    self.goalPanel = panel(f, 546, 65, 0.13, 0.16, 0.16)
    self.goalPanel:SetPoint("TOPLEFT", 232, -96)
    self.goalLabel = label(self.goalPanel, "GameFontNormalSmall", "YOUR NEXT GOAL", 14, -11, 325, gold)
    self.goalTitle = label(self.goalPanel, "GameFontHighlight", "", 14, -31, 325)
    self.goalTitle:SetHeight(20); self.goalTitle:SetWordWrap(false)
    self.goalOpen = button(self.goalPanel, "Open", 96, function() if SC.goal then UI:HandleCardClick(SC.goal) end end)
    self.goalOpen:SetPoint("RIGHT", -58, 0)
    self.goalClear = button(self.goalPanel, "Clear", 44, function() SC:ClearGoal() end)
    self.goalClear:SetPoint("RIGHT", -8, 0)
    self.countLabel = label(f, "GameFontHighlightSmall", "", 232, -177, 546, muted)
    self.cards = {}
    for index = 1, 3 do self.cards[index] = self:CreateCard(f, index) end
    self.empty = label(f, "GameFontHighlight", "", 253, -251, 490, muted)
    self.empty:SetHeight(150); self.empty:SetJustifyV("TOP"); self.empty:SetWordWrap(true)
    local shuffle = button(f, "Other ideas", 112, function()
        SC.rotation = SC.rotation + 1; SC:RefreshSuggestions(); UI:PopulateCards()
    end)
    shuffle:SetPoint("BOTTOMLEFT", 232, 13)
    local refresh = button(f, "Refresh", 88, function()
        if RequestRaidInfo then RequestRaidInfo() end
        SC:RefreshSuggestions(); UI:PopulateCards()
    end)
    refresh:SetPoint("LEFT", shuffle, "RIGHT", 8, 0)
    local restore = button(f, "Reset skips", 96, function()
        SC.skipped = {}; SC.rotation = 0; SC:RefreshSuggestions(); UI:PopulateCards()
    end)
    restore:SetPoint("LEFT", refresh, "RIGHT", 8, 0)
    label(f, "GameFontDisableSmall", "Times are estimates.", 626, -589, 152, muted)
    f:Hide(); self.dashboard = f
end

local actionLabels = { quest = "Track quest", mount = "Mount Journal", pet = "Pet Journal",
    toy = "Toy Box", map = "Show map", lfr = "Raid Finder", info = "Next step" }
function UI:PopulateCards()
    if not self.dashboard then return end
    local db, items = SoloCompassCharDB, SC.currentSuggestions or {}
    for minutes, b in pairs(self.timeButtons) do
        if minutes == db.minutes then b:SetBackdropColor(0.30, 0.25, 0.15, 1); b.text:SetTextColor(unpack(gold))
        else b:SetBackdropColor(0.13, 0.19, 0.24, 1); b.text:SetTextColor(0.92, 0.94, 0.95) end
    end
    for key, cb in pairs(self.interestChecks) do cb:SetChecked(db.interests[key]) end
    self.goalTitle:SetText(SC.goal and SC.goal.title or "Choose an idea below to get started.")
    self.goalOpen:SetShown(SC.goal ~= nil); self.goalClear:SetShown(SC.goal ~= nil)
    self.countLabel:SetText(#items > 0 and "A FEW IDEAS FOR YOU  /  " .. db.minutes .. " MINUTE SESSION" or "ROOM FOR A NEW ADVENTURE")
    for index, card in ipairs(self.cards) do
        local s = items[index]; card.suggestion = s; card:SetShown(s ~= nil)
        if s then
            local categoryLabel = s.category
            for _, category in ipairs(D.Categories) do if category.key == s.category then categoryLabel = category.label; break end end
            card.icon:SetTexture(s.icon or "Interface\\Icons\\INV_Misc_Map_01")
            card.meta:SetText(categoryLabel:upper() .. "  /  ~" .. s.minutes .. " MIN")
            card.title:SetText(s.title); card.detail:SetText(plain(s.detail))
            card.open.text:SetText(actionLabels[s.action] or "Open")
        end
    end
    self.empty:SetShown(#items == 0)
    if #items == 0 then
        local any = false
        for _, category in ipairs(D.Categories) do if db.interests[category.key] then any = true; break end end
        self.empty:SetText(any and "No matching suggestions right now.\n\nTry more time, another interest, or Reset skips. The starter collection catalog is small; an empty list doesn't mean you've finished everything in WoW."
            or "What would you enjoy today?\n\nSelect an interest on the left to find a starting point.")
    end
end
function UI:ShowPreferences()
    if not self.preferences then
        local f = panel(self.dashboard, 546, 477, 0.08, 0.115, 0.15)
        f:SetPoint("TOPLEFT", 232, -96); f:SetFrameLevel(self.dashboard:GetFrameLevel() + 20); f:EnableMouse(true)
        label(f, "GameFontHighlightLarge", "Make this your compass", 22, -23, 480, gold)
        label(f, "GameFontHighlight", "Interests and session time are saved for this character.", 22, -63, 488, muted)
        local login = checkbox(f)
        login:SetPoint("TOPLEFT", 19, -102); login.text:SetText("Open when I log in")
        login:SetScript("OnClick", function(self) SoloCompassCharDB.showOnLogin = self:GetChecked() and true or false end)
        f.login = login
        local minimap = checkbox(f)
        minimap:SetPoint("TOPLEFT", 19, -143); minimap.text:SetText("Show minimap button (all characters)")
        minimap:SetScript("OnClick", function(self)
            SoloCompassDB.minimap.hide = not self:GetChecked()
            if SC.Minimap.icon then
                if SoloCompassDB.minimap.hide then SC.Minimap.icon:Hide("SoloCompass") else SC.Minimap.icon:Show("SoloCompass") end
            end
        end)
        f.minimap = minimap
        label(f, "GameFontHighlight", "A nudge, not a checklist", 22, -217, 480, gold)
        label(f, "GameFontHighlightSmall", "Pick one goal. It stays here between logins until you clear it or its collectible / quest is confirmed complete.\n\nSkip for now hides an idea until you reload or reset skips. Other ideas rotates the shortlist.\n\nCollection ownership and quest status are checked. Delve rewards, LFR eligibility, housing unlocks, and missing transmog are left for you to check in game.", 22, -246, 488, muted)
        local done = button(f, "Back to my ideas", 150, function() f:Hide() end)
        done:SetPoint("BOTTOMRIGHT", -22, 20)
        self.preferences = f
    end
    self.preferences.login:SetChecked(SoloCompassCharDB.showOnLogin)
    self.preferences.minimap:SetChecked(not SoloCompassDB.minimap.hide)
    self.preferences:Show()
end
function UI:OpenMap(mapID)
    if not WorldMapFrame and C_AddOns then C_AddOns.LoadAddOn("Blizzard_WorldMap") end
    if WorldMapFrame then
        ShowUIPanel(WorldMapFrame)
        if mapID and WorldMapFrame.SetMapID then WorldMapFrame:SetMapID(mapID) end
    end
end
function UI:OpenCollection(tab, suggestion)
    if not ToggleCollectionsJournal and C_AddOns then C_AddOns.LoadAddOn("Blizzard_Collections") end
    if not ToggleCollectionsJournal then return end
    if not CollectionsJournal or not CollectionsJournal:IsShown()
        or PanelTemplates_GetSelectedTab(CollectionsJournal) ~= tab then ToggleCollectionsJournal(tab) end
    if suggestion.action == "mount" then
        if MountJournal and MountJournal.searchBox then MountJournal.searchBox:SetText(suggestion.title)
        elseif C_MountJournal.SetSearch then C_MountJournal.SetSearch(suggestion.title) end
    elseif suggestion.action == "pet" then
        if PetJournal and PetJournal.searchBox then PetJournal.searchBox:SetText(suggestion.title)
        elseif C_PetJournal.SetSearchFilter then C_PetJournal.SetSearchFilter(suggestion.title) end
    elseif suggestion.action == "toy" then
        if ToyBox and ToyBox.searchBox then ToyBox.searchBox:SetText(suggestion.title)
        elseif C_ToyBox and C_ToyBox.SetFilterString then C_ToyBox.SetFilterString(suggestion.title) end
    end
end
function UI:HandleCardClick(s)
    if InCombatLockdown() then
        print("|cffe8bb64Solo Compass:|r Open this activity after combat."); return
    end
    if s.action == "quest" then
        if not C_QuestLog.GetLogIndexForQuestID(s.targetID) then
            print("|cffe8bb64Solo Compass:|r That quest is no longer in your log. Refresh your ideas."); return
        end
        C_QuestLog.AddQuestWatch(s.targetID); C_SuperTrack.SetSuperTrackedQuestID(s.targetID)
        if QuestMapFrame_OpenToQuestDetails then QuestMapFrame_OpenToQuestDetails(s.targetID) else self:OpenMap() end
    elseif s.action == "mount" then self:OpenCollection(COLLECTIONS_JOURNAL_TAB_INDEX_MOUNTS or 1, s)
    elseif s.action == "pet" then self:OpenCollection(COLLECTIONS_JOURNAL_TAB_INDEX_PETS or 2, s)
    elseif s.action == "toy" then self:OpenCollection(COLLECTIONS_JOURNAL_TAB_INDEX_TOYS or 3, s)
    elseif s.action == "map" then self:OpenMap(s.mapID)
    elseif s.action == "lfr" then
        if not PVEFrame_ShowFrame and C_AddOns then C_AddOns.LoadAddOn("Blizzard_GroupFinder") end
        if C_LFGInfo and C_LFGInfo.CanPlayerUseGroupFinder then
            local canUse = C_LFGInfo.CanPlayerUseGroupFinder()
            if not canUse then print("|cffe8bb64Solo Compass:|r Group Finder is unavailable for this character right now."); return end
        end
        if PVEFrame_ShowFrame then PVEFrame_ShowFrame("GroupFinderFrame", "RaidFinderFrame") end
    else print("|cffe8bb64Solo Compass:|r " .. plain(s.detail)) end
end
function UI:Show()
    if not self.dashboard then self:CreateDashboard() end
    self:PopulateCards(); self.dashboard:Show()
end
function UI:Hide()
    if self.preferences then self.preferences:Hide() end
    if self.dashboard then self.dashboard:Hide() end
end
