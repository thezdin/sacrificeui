-- SacrificeUI Addon Dependency Checker
-- Checks that required and suggested addons are installed and enabled.
-- All addon references retain full credit to their original authors.

local REQUIRED_ADDONS = {
    { name = "BigWigs",            display = "BigWigs Boss Mods",     author = "BigWigs Team" },
    { name = "LittleWigs",         display = "Little Wigs",           author = "BigWigs Team" },
    { name = "MethodRaidTools",    display = "Method Raid Tools",     author = "Method / Nnogga" },
    { name = "ClickableRaidBuffs", display = "Clickable Raid Buffs",  author = "Various" },
    { name = "KhesycsILvl",       display = "Khesyc's iLvl",        author = "Khesyc" },
}

local SUGGESTED_ADDONS = {
    { name = "RaiderIO",              display = "RaiderIO",              author = "RaiderIO Team" },
    { name = "CursorTrail",           display = "Cursor Trail",          author = "Various" },
    { name = "WarpDeplete",           display = "WarpDeplete",           author = "Various" },
    { name = "PremadeGroupsFilter",   display = "Premade Group Filter",  author = "Various" },
}

local mainFrame = nil
local TAB_REQUIRED = 1
local TAB_SUGGESTED = 2
local activeTab = TAB_REQUIRED

local function IsAddonInstalled(addonName)
    for i = 1, C_AddOns.GetNumAddOns() do
        local name = C_AddOns.GetAddOnInfo(i)
        if name == addonName then
            return true, C_AddOns.IsAddOnLoaded(i)
        end
    end
    return false, false
end

local function AllRequiredLoaded()
    for _, addon in ipairs(REQUIRED_ADDONS) do
        local installed, loaded = IsAddonInstalled(addon.name)
        if not installed or not loaded then
            return false
        end
    end
    return true
end

local function CreateAddonRow(parent, addon, yOffset, isSuggested)
    local installed, loaded = IsAddonInstalled(addon.name)

    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(440, 28)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)

    -- Status icon
    local status = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    status:SetPoint("LEFT", row, "LEFT", 0, 0)
    if loaded then
        status:SetText("|cFF00FF00\226\156\147|r") -- green checkmark
    elseif installed then
        status:SetText("|cFFFFFF00\226\151\139|r") -- yellow circle (installed but not loaded)
    else
        status:SetText("|cFFFF0000\226\156\151|r") -- red X
    end

    -- Addon name
    local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameText:SetPoint("LEFT", status, "RIGHT", 8, 0)
    nameText:SetText(addon.display)

    -- Author credit
    local authorText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    authorText:SetPoint("LEFT", nameText, "RIGHT", 8, 0)
    authorText:SetTextColor(0.5, 0.5, 0.5)
    authorText:SetText("by " .. addon.author)

    -- Status label
    local statusLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    statusLabel:SetPoint("RIGHT", row, "RIGHT", -5, 0)
    if loaded then
        statusLabel:SetTextColor(0, 1, 0)
        statusLabel:SetText("Loaded")
    elseif installed then
        statusLabel:SetTextColor(1, 1, 0)
        statusLabel:SetText("Not Enabled")
    else
        statusLabel:SetTextColor(1, 0, 0)
        statusLabel:SetText("Not Installed")
    end

    return row
end

local function PopulateTab(contentFrame, tabIndex)
    -- Clear existing children
    local children = { contentFrame:GetChildren() }
    for _, child in ipairs(children) do
        child:Hide()
        child:SetParent(nil)
    end

    local addons = tabIndex == TAB_REQUIRED and REQUIRED_ADDONS or SUGGESTED_ADDONS
    local yOffset = -10

    for _, addon in ipairs(addons) do
        CreateAddonRow(contentFrame, addon, yOffset, tabIndex == TAB_SUGGESTED)
        yOffset = yOffset - 32
    end
end

local function CreateMainWindow()
    if mainFrame then
        return mainFrame
    end

    mainFrame = CreateFrame("Frame", "SacrificeUIMainFrame", UIParent, "BackdropTemplate")
    mainFrame:SetSize(500, 380)
    mainFrame:SetPoint("CENTER")
    mainFrame:SetMovable(true)
    mainFrame:EnableMouse(true)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetScript("OnDragStart", mainFrame.StartMoving)
    mainFrame:SetScript("OnDragStop", mainFrame.StopMovingOrSizing)
    mainFrame:SetFrameStrata("DIALOG")

    mainFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 },
    })

    -- Title
    local title = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", mainFrame, "TOP", 0, -16)
    title:SetText("|cFFFF8800SacrificeUI|r")

    -- Close button
    local closeBtn = CreateFrame("Button", nil, mainFrame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -4, -4)

    -- Tab buttons
    local tabRequired = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate")
    tabRequired:SetSize(120, 24)
    tabRequired:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 16, -44)
    tabRequired:SetText("Required")

    local tabSuggested = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate")
    tabSuggested:SetSize(120, 24)
    tabSuggested:SetPoint("LEFT", tabRequired, "RIGHT", 4, 0)
    tabSuggested:SetText("Suggested")

    -- Content area
    local content = CreateFrame("Frame", nil, mainFrame)
    content:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 16, -76)
    content:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -16, 50)
    mainFrame.content = content

    -- Reload UI button
    local reloadBtn = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate")
    reloadBtn:SetSize(120, 28)
    reloadBtn:SetPoint("BOTTOM", mainFrame, "BOTTOM", 0, 16)
    reloadBtn:SetText("Reload UI")
    reloadBtn:SetScript("OnClick", function() ReloadUI() end)

    -- Tab click handlers
    tabRequired:SetScript("OnClick", function()
        activeTab = TAB_REQUIRED
        PopulateTab(content, TAB_REQUIRED)
    end)
    tabSuggested:SetScript("OnClick", function()
        activeTab = TAB_SUGGESTED
        PopulateTab(content, TAB_SUGGESTED)
    end)

    -- Default to required tab
    PopulateTab(content, TAB_REQUIRED)

    tinsert(UISpecialFrames, "SacrificeUIMainFrame")
    return mainFrame
end

function SacrificeUI:ToggleMainWindow()
    local f = CreateMainWindow()
    if f:IsShown() then
        f:Hide()
    else
        PopulateTab(f.content, activeTab)
        f:Show()
    end
end

function SacrificeUI:CheckAddons()
    if AllRequiredLoaded() then
        if mainFrame and mainFrame:IsShown() then
            -- All good, can close
        end
    else
        -- Show the window if required addons are missing
        local f = CreateMainWindow()
        PopulateTab(f.content, TAB_REQUIRED)
        f:Show()
    end
end
