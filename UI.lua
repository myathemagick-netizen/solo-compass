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
local function setIcon(texture, suggestion)
    texture:SetTexCoord(0, 1, 0, 1)
    local atlas = suggestion.atlas
    if atlas and C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlas) then
        texture:SetAtlas(atlas)
    else
        local icon = suggestion.icon or "Interface\\Icons\\INV_Misc_Map_01"
        if texture:SetTexture(icon) == false then texture:SetTexture(134400) end
    end
    texture:Show()
end
local function iconButton(parent, icon, title, detail, callback)
    local b = button(parent, "", 28, callback)
    b:SetSize(28, 26)
    local texture = b:CreateTexture(nil, "ARTWORK")
    texture:SetSize(18, 18); texture:SetPoint("CENTER"); texture:SetTexture(icon)
    b:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(unpack(gold))
        tooltip(self, type(title) == "function" and title() or title, type(detail) == "function" and detail() or detail)
    end)
    b:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0.30, 0.39, 0.44, 1); GameTooltip:Hide()
    end)
    return b
end
local function checkbox(parent)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetSize(26,26)
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
    card.choose = iconButton(card, "Interface\\Icons\\Achievement_General", "Track this goal",
        "Save this idea and show a small movable tracker. Tracking a reputation also selects it for the game's watched reputation bar.", function()
            if card.suggestion then SoloCompassCharDB.showTracker = true; SC:SetGoal(card.suggestion); UI:Hide() end
        end)
    card.choose:SetPoint("BOTTOMLEFT", 14, 8)
    card.navigate = iconButton(card, "Interface\\Icons\\INV_Misc_Map_01", "Navigate",
        function() return card.suggestion and SC.Navigation:Describe(card.suggestion) end,
        function() if card.suggestion then SC.Navigation:Go(card.suggestion) end end)
    card.navigate:SetPoint("LEFT", card.choose, "RIGHT", 6, 0)
    card.open = iconButton(card, "Interface\\Icons\\INV_Misc_Book_09", "Open details",
        "Open the quest, collection journal, or activity panel for this idea.",
        function() if card.suggestion then UI:HandleCardClick(card.suggestion) end end)
    card.open:SetPoint("LEFT", card.navigate, "RIGHT", 6, 0)
    card.skip = iconButton(card, "Interface\\Buttons\\UI-GroupLoot-Pass-Up", "Dismiss idea",
        "Choose this session, 24 hours, or never. Restore hidden ideas in Preferences.",
        function() if card.suggestion then UI:ShowDismissals(card) end end)
    card.skip:SetPoint("BOTTOMRIGHT", -14, 8)
    card.time = label(card, "GameFontDisableSmall", "", 123, -94, 365, muted)
    card:EnableMouse(true)
    card:SetScript("OnEnter", function(self)
        if self.suggestion then tooltip(self, self.suggestion.title, (self.suggestion.reason or "Saved goal") .. "\n\n" .. self.suggestion.detail .. "\n\n" .. (self.suggestion.timeNote or "Times are estimates.")) end
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
    self.tabs = {}
    for index, tab in ipairs({{"ideas", "Ideas"}, {"interests", "Interests"}, {"preferences", "Preferences"}}) do
        local key = tab[1]
        local b = button(f, tab[2], 120, function() UI:SelectTab(key) end)
        b:SetPoint("TOPLEFT", 20+(index-1)*128, -84); self.tabs[key] = b
    end
    self.ideas = CreateFrame("Frame", nil, f)
    self.ideas:SetSize(W,H); self.ideas:SetPoint("TOPLEFT", 0, 0)
    -- Keep tab controls above their content without turning the content into an overlay.
    self.ideas:SetFrameLevel(f:GetFrameLevel()+1)
    self.interests = panel(f, 760, 441, 0.075, 0.105, 0.14)
    self.interests:SetPoint("TOPLEFT", 20, -132)
    self.interestsTitle = label(self.interests, "GameFontHighlightLarge", "Your interests", 22, -23, 710, gold)
    self.interestsIntro = label(self.interests, "GameFontHighlight", "", 22, -59, 710, muted)
    self.interestsIntro:SetHeight(30); self.interestsIntro:SetWordWrap(true)
    label(self.ideas, "GameFontNormalSmall", "TIME FOR THIS SESSION", 232, -147, 200, gold)
    self.timeButtons = {}
    for index, minutes in ipairs({ 15, 30, 60 }) do
        local b = button(self.ideas, minutes .. "m", 50, function()
            SoloCompassCharDB.minutes = minutes; SC.rotation = 0
            SC:RefreshSuggestions(); UI:PopulateCards()
        end)
        b:SetPoint("TOPLEFT", 602 + (index - 1) * 58, -138)
        self.timeButtons[minutes] = b
    end
    self.interestChecks, self.interestSlots = {}, {}
    for index, category in ipairs(D.Categories) do
        local cb = checkbox(self.interests)
        local column, row = math.floor((index-1)/6), (index-1)%6
        cb:SetSize(26, 26); cb:SetPoint("TOPLEFT", 20+column*240, -96-row*43)
        cb.text:SetFontObject(GameFontHighlight); cb.text:SetText(category.label); cb.text:SetWidth(198)
        cb.category = category
        cb:SetScript("OnClick", function(self)
            SoloCompassCharDB.interests[self.category.key] = self:GetChecked() and true or false
            SC.rotation = 0; SC:RefreshSuggestions(); UI:PopulateCards()
        end)
        cb:SetScript("OnEnter", function(self)
            tooltip(self, self.category.label, self.category.key == "pvp" and "Queue on your own for group PvP. Practice an objective or work toward an Honor reward. Queue time varies."
                or self.category.key == "lfr" and "Queue on your own for group raid wings. Ideas include preparation, entry requirements and remaining bosses; queue time varies."
                or "Include " .. self.category.label:lower() .. " when choosing ideas for this character. You can change this at any time.")
        end)
        cb:SetScript("OnLeave", function() GameTooltip:Hide() end)
        self.interestSlots[index] = cb
        self.interestChecks[category.key] = cb
    end
    self.interestSummary = label(self.interests, "GameFontHighlightSmall", "", 22, -365, 520, muted)
    self.interestsDone = button(self.interests, "Done - show my ideas", 180, function() UI:FinishInterests() end)
    self.interestsDone:SetPoint("BOTTOMRIGHT", -22, 18)
    self.goalPanel = panel(self.ideas, 192, 441, 0.13, 0.16, 0.16)
    self.goalPanel:SetPoint("TOPLEFT", 20, -132)
    self.goalLabel = label(self.goalPanel, "GameFontNormalSmall", "MY CURRENT IDEA", 14, -15, 164, gold)
    self.goalTitle = label(self.goalPanel, "GameFontHighlight", "", 14, -40, 164)
    self.goalTitle:SetHeight(54); self.goalTitle:SetWordWrap(true)
    self.goalObjectives = {}
    for index=1,6 do
        local row=label(self.goalPanel,"GameFontHighlightSmall","",14,-110-(index-1)*44,164,muted)
        row:SetHeight(38); row:SetWordWrap(true); row:Hide(); self.goalObjectives[index]=row
    end
    self.goalPanel:EnableMouse(true)
    self.goalPanel:SetScript("OnEnter", function(owner) if SC.goal then UI:GoalTooltip(owner) end end)
    self.goalPanel:SetScript("OnLeave", function() GameTooltip:Hide() end)
    self.goalOpen = button(self.goalPanel, "Open", 96, function() if SC.goal then UI:HandleCardClick(SC.goal) end end)
    self.goalOpen:SetPoint("BOTTOMLEFT", 14, 14)
    self.goalClear = button(self.goalPanel, "Clear", 44, function() SC:ClearGoal() end)
    self.goalClear:SetPoint("BOTTOMRIGHT", -14, 14)
    self.countLabel = label(self.ideas, "GameFontHighlightSmall", "", 232, -177, 546, muted)
    self.cards = {}
    for index = 1, 3 do self.cards[index] = self:CreateCard(self.ideas, index) end
    self.empty = label(self.ideas, "GameFontHighlight", "", 253, -251, 490, muted)
    self.empty:SetHeight(150); self.empty:SetJustifyV("TOP"); self.empty:SetWordWrap(true)
    self.availability = button(self.ideas, "Check availability", 164, function()
        local actions={housing="endeavor",lfr="lfr",timewalking="timewalking",transmog="transmog",professions="profession",archaeology="archaeology",
            achievements="achievement",pvp="pvp",heirlooms="heirloom",campsites="campsite",reputation="reputation",artifacts="artifact"}
        for _, category in ipairs(D.Categories) do
            if SoloCompassCharDB.interests[category.key] and actions[category.key] then UI:HandleCardClick({action=actions[category.key], detail="Open this activity's panel to check current progress."}); return end
        end
    end)
    self.availability:SetPoint("TOPLEFT", 253, -424); self.availability:Hide()
    local shuffle = button(self.ideas, "Other ideas", 112, function()
        SC:OtherIdeas()
    end)
    shuffle:SetPoint("BOTTOMLEFT", 232, 13)
    local refresh = button(self.ideas, "Refresh", 88, function()
        if RequestRaidInfo then RequestRaidInfo() end
        if SC.Progress then SC.Progress:RefreshCaches() end
        SC:RefreshSuggestions(); UI:PopulateCards()
    end)
    refresh:SetPoint("LEFT", shuffle, "RIGHT", 8, 0)
    local restore = button(self.ideas, "Reset skips", 96, function()
        SC.skipped = {}; SC.rotation = 0; SC:RefreshSuggestions(); UI:PopulateCards()
    end)
    restore:SetPoint("LEFT", refresh, "RIGHT", 8, 0)
    label(self.ideas, "GameFontDisableSmall", "Times are estimates.", 626, -589, 152, muted)
    self.dashboard = f
    f:SetScript("OnHide", function()
        if UI.preferences then UI.preferences:Hide() end
        if UI.dismissals then UI.dismissals:Hide() end
        UI:UpdateTracker()
    end)
    f:Hide()
end

function UI:ApplyTabVisibility()
    local tab=self.activeTab or "ideas"
    if not SoloCompassCharDB.onboardingComplete and tab == "ideas" then tab="interests"; self.activeTab=tab end
    self.ideas:SetShown(tab=="ideas"); self.interests:SetShown(tab=="interests")
    if tab~="ideas" and self.dismissals then self.dismissals:Hide() end
    if self.preferences then self.preferences:SetShown(tab=="preferences") end
    for key,b in pairs(self.tabs) do
        b:SetBackdropColor(unpack(key==tab and {0.30,0.25,0.15,1} or {0.13,0.19,0.24,1}))
        b.text:SetTextColor(unpack(key==tab and gold or {0.92,0.94,0.95}))
    end
end
function UI:SelectTab(tab)
    if tab == "preferences" then self:ShowPreferences(); return end
    self.activeTab=tab; self:PopulateCards()
end
function UI:FinishInterests()
    local selected=false
    for _,category in ipairs(D.Categories) do if SoloCompassCharDB.interests[category.key] then selected=true; break end end
    if not selected and not SoloCompassCharDB.onboardingComplete then
        self.interestSummary:SetText("Choose at least one interest to get started. You can change it later.")
        return false
    end
    SoloCompassCharDB.onboardingComplete=true
    SC.rotation=0; SC:RefreshSuggestions(); self:SelectTab("ideas")
    SC:RememberShown(); return true
end
function UI:GoalTooltip(owner)
    local goal=SC.goal; if not goal then return end
    local objectives=SC.Progress and SC.Progress:ObjectiveLines(goal) or {}
    local detail=(goal.action=="endeavor" and #objectives>0) and "" or (goal.detail or "")
    tooltip(owner,goal.title,(goal.reason or "Saved goal") .. (detail~="" and "\n\n"..detail or "")
        .. (#objectives>0 and "\n\n"..table.concat(objectives,"\n") or ""))
end
function UI:PopulateCards()
    self:UpdateTracker()
    if self.dismissals then self.dismissals:Hide() end
    if not self.dashboard then return end
    local db, items = SoloCompassCharDB, SC.currentSuggestions or {}
    for minutes, b in pairs(self.timeButtons) do
        if minutes == db.minutes then b:SetBackdropColor(0.30, 0.25, 0.15, 1); b.text:SetTextColor(unpack(gold))
        else b:SetBackdropColor(0.13, 0.19, 0.24, 1); b.text:SetTextColor(0.92, 0.94, 0.95) end
    end
    for index, cb in ipairs(self.interestSlots) do
        cb:SetChecked(db.interests[cb.category.key])
    end
    local selected = 0
    for _, category in ipairs(D.Categories) do if db.interests[category.key] then selected=selected+1 end end
    self.interestSummary:SetText(selected .. " interests selected. A few favorites are enough.")
    self.interestsTitle:SetText(db.onboardingComplete and "What sounds good?" or "Welcome to Solo Compass")
    self.interestsIntro:SetText(db.onboardingComplete and "Choose the kinds of things you enjoy. Your choices are saved for this character."
        or "Get a few useful ideas for your next session. Choose some interests below, then click Done.")
    self.goalTitle:SetText(SC.goal and SC.goal.title or "Choose Track on an idea to get started.")
    local objectives=SC.goal and SC.Progress and SC.Progress:ObjectiveLines(SC.goal) or {}
    for index,row in ipairs(self.goalObjectives) do
        row:SetHeight(#objectives==0 and index==1 and 260 or 38)
        row:SetShown(SC.goal ~= nil and (index<=#objectives or (#objectives==0 and index==1)))
        if SC.goal then row:SetText(plain(index==6 and #objectives>6 and ("+ " .. (#objectives-5) .. " more in details")
            or objectives[index] or (index==1 and SC.goal.detail or ""))) end
    end
    self.goalOpen:SetShown(SC.goal ~= nil); self.goalClear:SetShown(SC.goal ~= nil)
    self.countLabel:SetText(#items > 0 and "A FEW IDEAS FOR YOU  /  " .. db.minutes .. " MINUTE SESSION" or "ROOM FOR A NEW ADVENTURE")
    for index, card in ipairs(self.cards) do
        local s = items[index]; card.suggestion = s; card:SetShown(s ~= nil)
        if s then
            local categoryLabel = s.category
            for _, category in ipairs(D.Categories) do if category.key == s.category then categoryLabel = category.label; break end end
            setIcon(card.icon, s)
            card.meta:SetText(categoryLabel:upper() .. "  /  " .. (s.timeLabel or ("~" .. s.minutes .. " MIN")))
            card.title:SetText(s.title); card.detail:SetText(plain(s.detail))
            card.time:SetText(s.stepLabel or ((s.category == "lfr" or s.category == "timewalking") and "+ queue time" or "+ travel / preparation"))
        end
    end
    self.empty:SetShown(#items == 0)
    self.availability:SetShown(false)
    if #items == 0 then
        local any = false
        for _, category in ipairs(D.Categories) do if db.interests[category.key] then any = true; break end end
        self.empty:SetText(any and "No matching suggestions right now.\n\nTry more time, another interest, or Reset skips. For collection ideas, check your journal filters and Refresh after the data loads."
            or "What would you enjoy today?\n\nOpen Interests to choose a starting point.")
        local reasons = {}
        if SC.Progress then
            for _, category in ipairs(D.Categories) do
                if db.interests[category.key] and SC.Progress.status[category.key] then
                    reasons[#reasons+1] = SC.Progress.status[category.key]
                end
            end
        end
        local hasCandidate = false
        for _, candidate in ipairs(SC.candidates or {}) do
            if db.interests[candidate.category] then hasCandidate = true; break end
        end
        if #reasons > 0 and not hasCandidate then
            self.empty:SetText(table.concat(reasons, "\n\n", 1, math.min(2,#reasons)))
            self.availability:SetShown(true)
        end
    end
    self:ApplyTabVisibility()
end
function UI:ShowPreferences()
    if not self.dashboard then self:CreateDashboard() end
    if not self.preferences then
        local f = panel(self.dashboard, 760, 441, 0.08, 0.115, 0.15)
        f:SetPoint("TOPLEFT", 20, -132); f:EnableMouse(true)
        label(f, "GameFontHighlightLarge", "Preferences", 22, -23, 710, gold)
        label(f, "GameFontHighlight", "Make the compass comfortable for the way you play.", 22, -63, 710, muted)
        local login = checkbox(f)
        login:SetPoint("TOPLEFT", 19, -102); login.text:SetText("Open when I log in")
        login.text:SetWidth(650); login.text:SetJustifyH("LEFT")
        login:SetScript("OnClick", function(self) SoloCompassCharDB.showOnLogin = self:GetChecked() and true or false end)
        f.login = login
        local minimap = checkbox(f)
        minimap:SetPoint("TOPLEFT", 19, -143); minimap.text:SetText("Show minimap button (all characters)")
        minimap.text:SetWidth(650); minimap.text:SetJustifyH("LEFT")
        minimap:SetScript("OnClick", function(self)
            SoloCompassDB.minimap.hide = not self:GetChecked()
            if SC.Minimap.icon then
                if SoloCompassDB.minimap.hide then SC.Minimap.icon:Hide("SoloCompass") else SC.Minimap.icon:Show("SoloCompass") end
            end
        end)
        f.minimap = minimap
        local tracker = checkbox(f)
        tracker:SetPoint("TOPLEFT", 19, -184); tracker.text:SetText("Show compact goal tracker")
        tracker.text:SetWidth(650); tracker.text:SetJustifyH("LEFT")
        tracker:SetScript("OnClick", function(self)
            SoloCompassCharDB.showTracker = self:GetChecked() and true or false; UI:UpdateTracker()
        end)
        f.tracker = tracker
        label(f, "GameFontHighlight", "A nudge, not a checklist", 22, -228, 710, gold)
        local help=label(f, "GameFontHighlightSmall", "Interests and session time belong to this character. Minimap settings apply to all characters.\n\nUse Interests to change the kinds of ideas you see. Goals stay saved between logins; the tracker follows your current goal.", 22, -257, 710, muted)
        help:SetHeight(80); help:SetWordWrap(true)
        local restore = button(f, "Restore hidden ideas", 168, function()
            SoloCompassCharDB.dismissals = {}; SC.skipped = {}; SC.rotation = 0
            SC:RefreshSuggestions(); UI:PopulateCards()
        end)
        restore:SetPoint("BOTTOMLEFT", 22, 58)
        local reset = button(f, "Reset tracker position", 168, function()
            SoloCompassCharDB.trackerPosition = nil
            if UI.tracker then UI.tracker:ClearAllPoints(); UI.tracker:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 32, -220) end
        end)
        reset:SetPoint("LEFT", restore, "RIGHT", 10, 0)
        local done = button(f, "Back to my ideas", 150, function() UI:SelectTab("ideas") end)
        done:SetPoint("BOTTOMRIGHT", -22, 20)
        self.preferences = f
    end
    self.preferences.login:SetChecked(SoloCompassCharDB.showOnLogin)
    self.preferences.minimap:SetChecked(not SoloCompassDB.minimap.hide)
    self.preferences.tracker:SetChecked(SoloCompassCharDB.showTracker)
    self.activeTab="preferences"; self:ApplyTabVisibility()
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
    elseif suggestion.action == "pet" or suggestion.action == "petlevel" then
        if PetJournal and PetJournal.searchBox then PetJournal.searchBox:SetText(suggestion.searchName or suggestion.title)
        elseif C_PetJournal.SetSearchFilter then C_PetJournal.SetSearchFilter(suggestion.searchName or suggestion.title) end
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
    elseif s.action == "pet" or s.action == "petlevel" then self:OpenCollection(COLLECTIONS_JOURNAL_TAB_INDEX_PETS or 2, s)
    elseif s.action == "toy" then self:OpenCollection(COLLECTIONS_JOURNAL_TAB_INDEX_TOYS or 3, s)
    elseif s.action == "transmog" then
        self:OpenCollection(COLLECTIONS_JOURNAL_TAB_INDEX_APPEARANCES or 5, s)
        if WardrobeCollectionFrame and WardrobeCollectionFrame.SetTab then
            WardrobeCollectionFrame:SetTab(WARDROBE_TAB_SETS or 2)
            local sets=WardrobeCollectionFrame.SetsCollectionFrame
            if s.targetID and sets and sets.SelectSet then sets:SelectSet(s.targetID) end
        end
    elseif s.action == "heirloom" then self:OpenCollection(COLLECTIONS_JOURNAL_TAB_INDEX_HEIRLOOMS or 4, s)
    elseif s.action == "campsite" then self:OpenCollection(COLLECTIONS_JOURNAL_TAB_INDEX_WARBAND_SCENES or 6, s)
    elseif s.action == "decorrecipe" then
        if C_AddOns then C_AddOns.LoadAddOn("Blizzard_Professions") end
        if C_TradeSkillUI and C_TradeSkillUI.GetProfessionInfoByRecipeID then
            local info=C_TradeSkillUI.GetProfessionInfoByRecipeID(s.targetID)
            if info and OpenProfessionUIToSkillLine then OpenProfessionUIToSkillLine(info.parentProfessionID or info.professionID) end
        end
        if ProfessionsFrame and ProfessionsFrame.CraftingPage and C_TradeSkillUI and C_TradeSkillUI.GetRecipeInfo then
            local info=C_TradeSkillUI.GetRecipeInfo(s.targetID)
            if info and ProfessionsFrame.CraftingPage.SelectRecipe then ProfessionsFrame.CraftingPage:SelectRecipe(info) end
        elseif ToggleProfessionsBook then ToggleProfessionsBook() end
    elseif s.action == "profession" then
        if C_AddOns then C_AddOns.LoadAddOn("Blizzard_Professions") end
        if s.targetID and OpenProfessionUIToSkillLine then OpenProfessionUIToSkillLine(s.targetID)
        elseif s.targetID and C_TradeSkillUI and C_TradeSkillUI.OpenTradeSkill then C_TradeSkillUI.OpenTradeSkill(s.targetID)
        elseif ToggleProfessionsBook then ToggleProfessionsBook()
        else print("|cffe8bb64Solo Compass:|r Open your Professions panel, then Refresh to read its skill lines.") end
    elseif s.action == "archaeology" then
        if C_AddOns then C_AddOns.LoadAddOn("Blizzard_ArchaeologyUI") end
        if ArchaeologyFrame then ShowUIPanel(ArchaeologyFrame)
        elseif ArchaeologyFrame_Show then ArchaeologyFrame_Show()
        elseif ArchaeologyFrame_ToggleUI then ArchaeologyFrame_ToggleUI()
        else print("|cffe8bb64Solo Compass:|r Archaeology could not open. Check that this character has learned the profession.") end
    elseif s.action == "houseupgrade" then
        if C_AddOns then C_AddOns.LoadAddOn("Blizzard_HousingDashboard") end
        if HousingDashboardFrame then ShowUIPanel(HousingDashboardFrame) end
        print("|cffe8bb64Solo Compass:|r " .. plain(s.detail))
    elseif s.action == "endeavor" then
        if C_AddOns then C_AddOns.LoadAddOn("Blizzard_HousingDashboard") end
        if s.targetID and HousingFramesUtil and HousingFramesUtil.OpenFrameToTaskID then HousingFramesUtil.OpenFrameToTaskID(s.targetID)
        elseif HousingDashboardFrame then ShowUIPanel(HousingDashboardFrame)
        else print("|cffe8bb64Solo Compass:|r Open Housing and select Endeavors to check your active neighborhood's tasks.") end
    elseif s.action == "achievement" then
        if C_AddOns then C_AddOns.LoadAddOn("Blizzard_AchievementUI") end
        if s.targetID and ShowAchievementFrameForAchievement then ShowAchievementFrameForAchievement(s.targetID, false)
        else
            if AchievementFrame and not AchievementFrame:IsShown() then ShowUIPanel(AchievementFrame)
            elseif not AchievementFrame and ToggleAchievementFrame then ToggleAchievementFrame() end
            if s.targetID and AchievementFrame_SelectAchievement then AchievementFrame_SelectAchievement(s.targetID) end
        end
    elseif s.action == "reputation" then
        if C_AddOns then C_AddOns.LoadAddOn("Blizzard_UIPanels_Game") end
        if s.progressKind=="renown" and C_AddOns then C_AddOns.LoadAddOn("Blizzard_MajorFactions") end
        if s.progressKind=="renown" and not MajorFactionRenownFrame and MajorFactions_LoadUI then MajorFactions_LoadUI() end
        if s.progressKind=="renown" and MajorFactionRenownFrame and ToggleMajorFactionRenown then
            if not MajorFactionRenownFrame or not MajorFactionRenownFrame:IsShown() or MajorFactionRenownFrame:GetCurrentFactionID()~=s.targetID then ToggleMajorFactionRenown(s.targetID) end
        elseif ToggleCharacter then ToggleCharacter("ReputationFrame",true)
        elseif CharacterFrame then ShowUIPanel(CharacterFrame)
        else print("|cffe8bb64Solo Compass:|r Open Character > Reputation to inspect this faction.") end
    elseif s.action == "timewalking" or s.action == "pvp" then
        if not PVEFrame_ShowFrame and C_AddOns then C_AddOns.LoadAddOn("Blizzard_GroupFinder") end
        if PVEFrame_ShowFrame then
            if s.action == "pvp" then PVEFrame_ShowFrame("PVPUIFrame", "HonorFrame")
            else
                PVEFrame_ShowFrame("GroupFinderFrame", "LFDParentFrame")
                if s.targetID and LFDQueueFrame_SetType then LFDQueueFrame_SetType(s.targetID) end
            end
        end
    elseif s.action == "artifact" then
        print("|cffe8bb64Solo Compass:|r " .. plain(s.detail or "Visit your Legion class hall's artifact forge with the weapon to inspect its appearance requirements.")); return
    elseif s.action == "map" then self:OpenMap(s.mapID)
    elseif s.action == "questlog" then
        if ToggleQuestLog then ToggleQuestLog() end
    elseif s.action == "lfr" then
        if not PVEFrame_ShowFrame and C_AddOns then C_AddOns.LoadAddOn("Blizzard_GroupFinder") end
        if C_LFGInfo and C_LFGInfo.CanPlayerUseGroupFinder then
            local canUse = C_LFGInfo.CanPlayerUseGroupFinder()
            if not canUse then print("|cffe8bb64Solo Compass:|r Group Finder is unavailable for this character right now."); return end
        end
        if PVEFrame_ShowFrame then PVEFrame_ShowFrame("GroupFinderFrame", "RaidFinderFrame") end
        if s.targetID and RaidFinderQueueFrame_SetRaid then RaidFinderQueueFrame_SetRaid(s.targetID) end
    else print("|cffe8bb64Solo Compass:|r " .. plain(s.detail)); return end
    self:Hide()
end
function UI:Show()
    if not self.dashboard then self:CreateDashboard() end
    self.activeTab=SoloCompassCharDB.onboardingComplete and "ideas" or "interests"
    self:PopulateCards(); self.dashboard:Show()
    if self.activeTab == "ideas" then SC:RememberShown() end
    self:UpdateTracker()
end
function UI:Hide()
    if self.preferences then self.preferences:Hide() end
    if self.dashboard then self.dashboard:Hide() end
    if self.dismissals then self.dismissals:Hide() end
    self:UpdateTracker()
end

function UI:ShowDismissals(card)
    if not self.dismissals then
        local f = panel(self.dashboard, 196, 153, 0.07, 0.10, 0.13)
        f:SetFrameLevel(self.dashboard:GetFrameLevel() + 30); f:EnableMouse(true)
        label(f, "GameFontNormalSmall", "DISMISS THIS IDEA", 12, -10, 176, gold)
        for index, choice in ipairs({ {"This session", "session"}, {"For 24 hours", "day"}, {"Never suggest this", "forever"} }) do
            local duration = choice[2]
            local b = button(f, choice[1], 172, function()
                local s = f.suggestion; f:Hide(); if s then SC:Skip(s, duration) end
            end)
            b:SetPoint("TOPLEFT", 12, -28 - (index - 1) * 29)
        end
        local cancel = button(f, "Cancel", 172, function() f:Hide() end)
        cancel:SetPoint("BOTTOMLEFT", 12, 8)
        self.dismissals = f
    end
    local f = self.dismissals
    if f:IsShown() and f.suggestion == card.suggestion then f:Hide(); return end
    f.suggestion = card.suggestion; f:ClearAllPoints()
    f:SetPoint("TOPRIGHT", card, "TOPRIGHT", -8, -5); f:Show()
end

function UI:UpdateTracker()
    if not SoloCompassCharDB then return end
    if not SC.goal or not SoloCompassCharDB.showTracker then
        if self.tracker then self.tracker:Hide() end
        return
    end
    if not self.tracker then
        local f = panel(UIParent, 290, 112, 0.07, 0.10, 0.13, "SoloCompassGoalTracker")
        f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 32, -220)
        f:SetScale(math.min(1, UIParent:GetWidth() / 360, UIParent:GetHeight() / 280))
        f:SetClampedToScreen(true); f:SetFrameStrata("MEDIUM"); f:SetMovable(true)
        f:EnableMouse(true); f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", f.StartMoving)
        f:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            local point, _, relativePoint, x, y = self:GetPoint()
            SoloCompassCharDB.trackerPosition = {point=point, relativePoint=relativePoint, x=x, y=y}
        end)
        local p = SoloCompassCharDB.trackerPosition
        if type(p) == "table" and p.point and p.relativePoint then
            f:ClearAllPoints(); f:SetPoint(p.point, UIParent, p.relativePoint, p.x or 0, p.y or 0)
        end
        f.icon = f:CreateTexture(nil, "ARTWORK"); f.icon:SetSize(30, 30); f.icon:SetPoint("TOPLEFT", 12, -12)
        label(f, "GameFontNormalSmall", "MY NEXT ADVENTURE", 52, -12, 194, gold)
        f.title = label(f, "GameFontHighlight", "", 52, -30, 218)
        f.title:SetHeight(32); f.title:SetWordWrap(true)
        f.objectiveRows = {}
        for index=1,6 do
            local row=label(f, "GameFontHighlightSmall", "", 12, -68-(index-1)*16, 266, muted)
            row:SetHeight(14); row:SetWordWrap(false); row:Hide()
            f.objectiveRows[index]=row
        end
        local nav = iconButton(f, "Interface\\Icons\\INV_Misc_Map_01", "Navigate", function() return SC.goal and SC.Navigation:Describe(SC.goal) end,
            function() if SC.goal then SC.Navigation:Go(SC.goal) end end)
        nav:SetPoint("BOTTOMLEFT", 12, 10)
        local open = iconButton(f, "Interface\\Icons\\INV_Misc_Book_09", "Open details", "Open the quest, journal, or activity panel.",
            function() if SC.goal then UI:HandleCardClick(SC.goal) end end)
        open:SetPoint("LEFT", nav, "RIGHT", 6, 0)
        local ideas = button(f, "My ideas", 78, function() SC:RefreshSuggestions(); UI:Show() end)
        ideas:SetPoint("LEFT", open, "RIGHT", 8, 0)
        local done = button(f, "Clear goal", 90, function() SC:ClearGoal() end)
        done:SetPoint("BOTTOMRIGHT", -12, 10)
        f:SetScript("OnEnter", function(self)
            if SC.goal then UI:GoalTooltip(self); GameTooltip:AddLine("\nDrag to move this tracker.",0.7,0.75,0.8); GameTooltip:Show() end
        end)
        f:SetScript("OnLeave", function() GameTooltip:Hide() end)
        self.tracker = f
    end
    setIcon(self.tracker.icon, SC.goal); self.tracker.title:SetText(SC.goal.title)
    local objectives=SC.Progress and SC.Progress:ObjectiveLines(SC.goal) or {}
    local visible=math.min(#objectives,6)
    for index,row in ipairs(self.tracker.objectiveRows) do
        row:SetShown(index <= visible)
        if index <= visible then
            row:SetText(plain(index == 6 and #objectives > 6 and ("+ " .. (#objectives-5) .. " more in details") or objectives[index]))
        end
    end
    self.tracker:SetHeight(112+(visible > 0 and visible*16+8 or 0))
    self.tracker:SetShown(not (self.dashboard and self.dashboard:IsShown()))
end
