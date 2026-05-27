-- SoloCompass: dashboard frame, tabs, suggestion cards

SoloCompass.UI = {}
local UI = SoloCompass.UI
local SC = SoloCompass

local PILLARS = {
    { key = "housing",   label = "Housing",   color = { 0.4, 0.8, 1.0 } },
    { key = "collector", label = "Collector", color = { 1.0, 0.75, 0.2 } },
    { key = "quests",    label = "Quests",    color = { 0.6, 1.0, 0.5 } },
}

local CARD_HEIGHT  = 52
local CARD_PADDING = 6
local PANEL_W      = 420
local PANEL_H      = 520

-- Dashboard ---------------------------------------------------------------

function UI:CreateDashboard()
    local f = CreateFrame("Frame", "SoloCompassFrame", UIParent, "BackdropTemplate")
    f:SetSize(PANEL_W, PANEL_H)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop",  f.StopMovingOrSizing)

    f:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })

    -- Title bar
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOP", 0, -16)
    title:SetText("SoloCompass")

    -- Subtitle
    local sub = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sub:SetPoint("TOP", title, "BOTTOM", 0, -4)
    sub:SetTextColor(0.7, 0.7, 0.7)
    sub:SetText("Here's what to do today")

    -- Close button
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -4, -4)
    closeBtn:SetScript("OnClick", function() UI:Hide() end)

    -- Refresh button
    local refreshBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    refreshBtn:SetSize(80, 22)
    refreshBtn:SetPoint("BOTTOMRIGHT", -16, 14)
    refreshBtn:SetText("Refresh")
    refreshBtn:SetScript("OnClick", function()
        SC:RefreshSuggestions()
        UI:PopulateCards()
    end)

    -- Pillar tabs
    local tabY = -60
    self.tabFrames = {}
    for i, pillar in ipairs(PILLARS) do
        local tab = self:CreatePillarSection(f, pillar, i)
        tab:SetPoint("TOPLEFT", 16, tabY)
        tabY = tabY - tab:GetHeight() - 10
        self.tabFrames[pillar.key] = tab
    end

    f:Hide()
    self.dashboard = f
end

function UI:CreatePillarSection(parent, pillar, index)
    local section = CreateFrame("Frame", nil, parent)
    section:SetSize(PANEL_W - 32, 10) -- height grows with cards

    -- Section header
    local header = section:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header:SetPoint("TOPLEFT", 0, 0)
    header:SetTextColor(pillar.color[1], pillar.color[2], pillar.color[3])
    header:SetText(pillar.label)

    -- Divider
    local divider = section:CreateTexture(nil, "BACKGROUND")
    divider:SetHeight(1)
    divider:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -3)
    divider:SetPoint("RIGHT", section, "RIGHT", 0, 0)
    divider:SetColorTexture(pillar.color[1], pillar.color[2], pillar.color[3], 0.4)

    section.header  = header
    section.divider = divider
    section.cards   = {}
    section.pillarKey = pillar.key
    section.pillarColor = pillar.color

    return section
end

function UI:CreateSuggestionCard(parent, suggestion, yOffset)
    local card = CreateFrame("Button", nil, parent, "BackdropTemplate")
    card:SetSize(PANEL_W - 48, CARD_HEIGHT)
    card:SetPoint("TOPLEFT", 0, yOffset)

    card:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    card:SetBackdropColor(0.1, 0.1, 0.1, 0.85)

    -- Hover highlight
    local hl = card:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(1, 1, 1, 0.06)

    -- Icon
    local icon = card:CreateTexture(nil, "ARTWORK")
    icon:SetSize(36, 36)
    icon:SetPoint("LEFT", 8, 0)
    icon:SetTexture(suggestion.icon)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    -- Text
    local text = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetPoint("LEFT", icon, "RIGHT", 8, 0)
    text:SetPoint("RIGHT", card, "RIGHT", -8, 0)
    text:SetJustifyH("LEFT")
    text:SetWordWrap(true)
    text:SetText(suggestion.text)

    card:SetScript("OnClick", function()
        UI:HandleCardClick(suggestion)
    end)

    return card
end

function UI:HandleCardClick(suggestion)
    if suggestion.pillar == "quests" then
        C_QuestLog.AddQuestWatch(suggestion.id)
        C_SuperTrack.SetSuperTrackedQuestID(suggestion.id)
        if QuestMapFrame_OpenToQuestDetails then
            QuestMapFrame_OpenToQuestDetails(suggestion.id)
        else
            OpenWorldMap()
        end
        UI:Hide()

    elseif suggestion.pillar == "collector" and suggestion.subtype == "mount" then
        local tab = COLLECTIONS_JOURNAL_TAB_INDEX_MOUNTS or 1
        ToggleCollectionsJournal(tab)
        -- Drive the search through the journal's own searchBox so its full filter
        -- pipeline fires (OnTextChanged → MountJournal_OnSearchTextChanged → data
        -- provider update), rather than calling C_MountJournal.SetSearch directly.
        if MountJournal and MountJournal.searchBox then
            MountJournal.searchBox:SetText(suggestion.name or "")
            if MountJournal_OnSearchTextChanged then
                MountJournal_OnSearchTextChanged(MountJournal.searchBox)
            end
        elseif C_MountJournal and C_MountJournal.SetSearch then
            C_MountJournal.SetSearch(suggestion.name or "")
        end
        -- Defer 0.1s: ScrollBox data provider needs one update cycle after the search
        local mountName = suggestion.name
        C_Timer.After(0.1, function()
            local dp = MountJournal
                       and MountJournal.ScrollBox
                       and MountJournal.ScrollBox:GetDataProvider()
            -- dp.collection is the raw array of element tables
            local mountID
            if dp and dp.collection then
                for _, element in ipairs(dp.collection) do
                    local id = (element.mountID)
                            or (element.data and element.data.mountID)
                    if id then
                        mountID = id
                        break
                    end
                end
            end
            if mountID then
                MountJournal.selectedMountID = mountID
                if MountJournal_UpdateMountDisplay then
                    MountJournal_UpdateMountDisplay()
                end
                return
            end
            -- Fallback: filter is active, player can click the result themselves
            print("|cff00ccffSoloCompass:|r Showing \"|cffffffff" .. (mountName or "mount") .. "|r\" in your Mount Journal.")
        end)

    elseif suggestion.pillar == "housing" then
        if suggestion.id == "warband_visit" then
            if C_PlayerHousing and C_PlayerHousing.OpenNeighborhoodBrowser then
                C_PlayerHousing.OpenNeighborhoodBrowser()
            else
                print("|cff00ccffSoloCompass:|r Open your Warband Neighborhood via the Warband menu to visit a neighbor's house.")
            end
        elseif suggestion.id == "neighborhood_end" then
            if C_PlayerHousing and C_PlayerHousing.OpenNeighborhoodBrowser then
                C_PlayerHousing.OpenNeighborhoodBrowser()
            else
                print("|cff00ccffSoloCompass:|r Visit your Neighborhood board to pick up today's endeavors.")
            end
        end
        -- decoration nudge is informational only — no action needed
    end
end

function UI:PopulateCards()
    local suggestions = SC.currentSuggestions
    if not suggestions then return end

    for _, pillar in ipairs(PILLARS) do
        local section = self.tabFrames[pillar.key]
        if section then
            -- Clear old cards
            for _, card in ipairs(section.cards) do
                card:Hide()
                card:SetParent(nil)
            end
            section.cards = {}

            local items = suggestions[pillar.key] or {}
            local yOff  = -20  -- below header + divider

            for _, s in ipairs(items) do
                local card = self:CreateSuggestionCard(section, s, yOff)
                table.insert(section.cards, card)
                yOff = yOff - CARD_HEIGHT - CARD_PADDING
            end

            if #items == 0 then
                local empty = section:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
                empty:SetPoint("TOPLEFT", 0, -24)
                empty:SetText("Nothing to do here today!")
                table.insert(section.cards, empty)
                yOff = yOff - 20
            end

            section:SetHeight(math.abs(yOff) + 4)
        end
    end

    -- Restack sections
    local stackY = -60
    for _, pillar in ipairs(PILLARS) do
        local section = self.tabFrames[pillar.key]
        if section then
            section:ClearAllPoints()
            section:SetPoint("TOPLEFT", self.dashboard, "TOPLEFT", 16, stackY)
            stackY = stackY - section:GetHeight() - 10
        end
    end

    -- Resize dashboard to fit content
    local totalH = math.abs(stackY) + 40
    self.dashboard:SetHeight(math.max(totalH, 200))
end

-- Setup wizard ------------------------------------------------------------

function UI:ShowSetupWizard()
    local wiz = CreateFrame("Frame", "SoloCompassWizard", UIParent, "BackdropTemplate")
    wiz:SetSize(360, 280)
    wiz:SetPoint("CENTER")
    wiz:SetFrameStrata("DIALOG")
    wiz:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })

    local title = wiz:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOP", 0, -20)
    title:SetText("Welcome to SoloCompass!")

    local sub = wiz:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sub:SetPoint("TOP", title, "BOTTOM", 0, -8)
    sub:SetText("What are you into? (pick all that apply)")
    sub:SetTextColor(0.8, 0.8, 0.8)

    local checks = {}
    local checkY = -80
    for _, pillar in ipairs(PILLARS) do
        local cb = CreateFrame("CheckButton", nil, wiz, "UICheckButtonTemplate")
        cb:SetPoint("LEFT", 40, 0)
        cb:SetPoint("TOP", wiz, "TOP", 0, checkY)
        cb:SetChecked(SoloCompassCharDB.interests[pillar.key])

        local lbl = wiz:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetPoint("LEFT", cb, "RIGHT", 4, 0)
        lbl:SetText(pillar.label)
        lbl:SetTextColor(pillar.color[1], pillar.color[2], pillar.color[3])

        checks[pillar.key] = cb
        checkY = checkY - 36
    end

    local doneBtn = CreateFrame("Button", nil, wiz, "UIPanelButtonTemplate")
    doneBtn:SetSize(120, 28)
    doneBtn:SetPoint("BOTTOM", 0, 20)
    doneBtn:SetText("Let's go!")
    doneBtn:SetScript("OnClick", function()
        for _, pillar in ipairs(PILLARS) do
            SoloCompassCharDB.interests[pillar.key] = checks[pillar.key]:GetChecked() and true or false
        end
        SoloCompassCharDB.setupDone = true
        wiz:Hide()
        SC:RefreshSuggestions()
        UI:Show()
    end)

    self.wizard = wiz
end

-- Public show/hide --------------------------------------------------------

function UI:Show()
    if not self.dashboard then
        self:CreateDashboard()
    end
    self:PopulateCards()
    self.dashboard:Show()
end

function UI:Hide()
    if self.dashboard then
        self.dashboard:Hide()
    end
end
