-- SacrificeUI Main Window
-- Sacrifice Guild <US-Hyjal>

local REQUIRED_ADDONS = {
    { name = "BigWigs",            display = "BigWigs Boss Mods",    author = "BigWigs Team"   },
    { name = "LittleWigs",         display = "Little Wigs",          author = "BigWigs Team"   },
    { name = "MethodRaidTools",    display = "Method Raid Tools",    author = "Method / Nnogga"},
    { name = "ClickableRaidBuffs", display = "Clickable Raid Buffs", author = "Various"        },
    { name = "Khesyc_iLvl",       display = "Khesyc's iLvl",       author = "Khesyc"         },
}

local SUGGESTED_ADDONS = {
    { name = "RaiderIO",            display = "RaiderIO",             author = "RaiderIO Team" },
    { name = "CursorTrail",         display = "Cursor Trail",         author = "Various"       },
    { name = "WarpDeplete",         display = "WarpDeplete",          author = "Various"       },
    { name = "PremadeGroupsFilter", display = "Premade Group Filter", author = "Various"       },
}


local NAV_ITEMS = { "Global Settings", "Addons", "Dungeons", "Raids", "Settings" }

-- Midnight Season 1 M+ dungeons (matches DungeonData.lua entries)
local MPLUS_DUNGEONS = {
    "Algeth'ar Academy",
    "Magister's Terrace",
    "Maisara Caverns",
    "Nexus Point Xenas",
    "Pit of Saron",
    "Seat of the Triumvirate",
    "Skyreach",
    "Windrunner Spire",
}

local FRAME_W   = 880
local FRAME_H   = 560
local SIDEBAR_W = 200
local BOTTOM_H  = 48

local C_INACTIVE = { 0.55, 0.55, 0.57, 1.0 }
local C_DIVIDER  = { 0.14, 0.14, 0.16, 1.0 }
local C_WHITE    = { 0.90, 0.90, 0.90, 1.0 }
local C_BORDER   = { 0.12, 0.12, 0.14, 1.0 }
local C_CRIMSON  = { 0.86, 0.08, 0.24, 1.0 }

local mainFrame     = nil
local logoText      = nil
local logoIcon      = nil
local vDivider      = nil
local closeButton   = nil
local doneButton    = nil
local perfFrame     = nil
local statsFrame    = nil
local reminderPopup = nil
local funnyFrame    = nil
local navButtons      = {}
local contentPanes    = {}
local accentToggles   = {}
local globalSettingsPane = nil
local activeNav      = "Global Settings"
local activeAddonTab = "Required"

-- ============================================================
-- Theme
-- ============================================================

local function GetAccentColor()
    if SacrificeUIDB and SacrificeUIDB.classColorEnabled then
        local _, className = UnitClass("player")
        if className then
            local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[className]
            if c then return { c.r, c.g, c.b, 1.0 } end
        end
    end
    return C_CRIMSON
end

local function AccentHex()
    local c = GetAccentColor()
    return string.format("|cFF%02X%02X%02X", c[1] * 255, c[2] * 255, c[3] * 255)
end

local function ApplyTheme()
    local c = GetAccentColor()

    if logoText    then logoText:SetText(AccentHex() .. "Sacrifice|r|cFFFFFFFFUI|r") end
    if logoIcon    then logoIcon:SetVertexColor(unpack(c)) end
    if mainFrame and mainFrame.borderLines then
        for _, line in ipairs(mainFrame.borderLines) do
            line:SetColorTexture(unpack(c))
        end
    end
    if vDivider    then vDivider:SetColorTexture(unpack(c)) end
    if closeButton then closeButton.xText:SetTextColor(unpack(c)) end
    if mainFrame and mainFrame.bottomSep then mainFrame.bottomSep:SetColorTexture(unpack(c)) end
    if doneButton then
        doneButton:SetBackdropBorderColor(unpack(c))
        doneButton.txt:SetTextColor(unpack(c))
    end

    for k, btn in pairs(navButtons) do
        btn.leftBar:SetColorTexture(unpack(c))
        if btn.bgHighlight then btn.bgHighlight:SetColorTexture(c[1], c[2], c[3], 0.12) end
        if k == activeNav then btn.text:SetTextColor(unpack(c)) end
    end

    if contentPanes["Addons"] then
        local pane = contentPanes["Addons"]
        for k, tab in pairs(pane.tabs) do
            tab.underline:SetColorTexture(unpack(c))
            if k == activeAddonTab then tab.text:SetTextColor(unpack(c)) end
        end
    end

    if globalSettingsPane then
        for k, tab in pairs(globalSettingsPane.subTabs) do
            tab.underline:SetColorTexture(unpack(c))
            if k == globalSettingsPane.activeSubTab then tab.text:SetTextColor(unpack(c)) end
        end
    end

    for _, t in ipairs(accentToggles) do t:RefreshColor() end
    if ApplyQuestTrackerTheme then ApplyQuestTrackerTheme() end
end

-- ============================================================
-- Helpers
-- ============================================================

local function IsAddonInstalled(addonName)
    for i = 1, C_AddOns.GetNumAddOns() do
        local name = C_AddOns.GetAddOnInfo(i)
        if name == addonName then return true, C_AddOns.IsAddOnLoaded(i) end
    end
    return false, false
end

local function AllRequiredLoaded()
    for _, addon in ipairs(REQUIRED_ADDONS) do
        local installed, loaded = IsAddonInstalled(addon.name)
        if not installed or not loaded then return false end
    end
    return true
end

local function HLine(parent, xLeft, xRight, y)
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1)
    line:SetColorTexture(unpack(C_DIVIDER))
    line:SetPoint("TOPLEFT",  parent, "TOPLEFT",  xLeft,  y)
    line:SetPoint("TOPRIGHT", parent, "TOPRIGHT", xRight, y)
    return line
end

local function TipBorder()
    return {
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    }
end

local function MainBorder()
    return {
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false, edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    }
end

-- ============================================================
-- Overlays
-- ============================================================

local function CreatePerfOverlay()
    if perfFrame then return perfFrame end
    perfFrame = CreateFrame("Frame", "SacrificeUIPerfOverlay", UIParent)
    perfFrame:SetSize(310, 22)
    local pos = SacrificeUIDB and SacrificeUIDB.perfPos
    if pos then
        perfFrame:SetPoint(pos.point, UIParent, pos.relPoint, pos.x, pos.y)
    else
        perfFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 10, -10)
    end
    perfFrame:SetMovable(true)
    perfFrame:EnableMouse(true)
    perfFrame:RegisterForDrag("LeftButton")
    perfFrame:SetScript("OnDragStart", perfFrame.StartMoving)
    perfFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relPoint, x, y = self:GetPoint()
        if SacrificeUIDB then SacrificeUIDB.perfPos = { point=point, relPoint=relPoint, x=x, y=y } end
    end)
    perfFrame:SetFrameStrata("HIGH")
    local txt = perfFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    txt:SetPoint("LEFT")
    perfFrame.txt = txt
    local elapsed = 0
    perfFrame:SetScript("OnUpdate", function(self, dt)
        elapsed = elapsed + dt
        if elapsed < 0.5 then return end
        elapsed = 0
        local c   = GetAccentColor()
        local hex = string.format("|cFF%02X%02X%02X", c[1]*255, c[2]*255, c[3]*255)
        local sep = " |cFFAAAAAA | |r "
        local fps = math.floor(GetFramerate())
        local _, _, homeLat, worldLat = GetNetStats()
        self.txt:SetText(
            fps .. " " .. hex .. "fps|r" .. sep ..
            worldLat .. " " .. hex .. "ms (world)|r" .. sep ..
            homeLat  .. " " .. hex .. "ms (local)|r"
        )
    end)
    return perfFrame
end

local function CreateStatsOverlay()
    if statsFrame then return statsFrame end
    statsFrame = CreateFrame("Frame", "SacrificeUIStatsOverlay", UIParent)
    statsFrame:SetSize(140, 110)
    local pos = SacrificeUIDB and SacrificeUIDB.statsPos
    if pos then
        statsFrame:SetPoint(pos.point, UIParent, pos.relPoint, pos.x, pos.y)
    else
        statsFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -10, -10)
    end
    statsFrame:SetMovable(true)
    statsFrame:EnableMouse(true)
    statsFrame:RegisterForDrag("LeftButton")
    statsFrame:SetScript("OnDragStart", statsFrame.StartMoving)
    statsFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relPoint, x, y = self:GetPoint()
        if SacrificeUIDB then SacrificeUIDB.statsPos = { point=point, relPoint=relPoint, x=x, y=y } end
    end)
    statsFrame:SetFrameStrata("HIGH")
    local txt = statsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    txt:SetPoint("TOPLEFT")
    txt:SetJustifyH("LEFT")
    statsFrame.txt = txt
    local function Update()
        local c   = GetAccentColor()
        local hex = string.format("|cFF%02X%02X%02X", c[1]*255, c[2]*255, c[3]*255)
        local cr  = string.format("%.2f", GetCritChance  and GetCritChance()  or 0)
        local ha  = string.format("%.2f", GetHaste       and GetHaste()       or 0)
        local ma  = string.format("%.2f", GetMastery     and GetMastery()     or 0)
        local ve  = string.format("%.2f", GetVersatility and GetVersatility() or 0)
        local le  = string.format("%.2f", GetLifesteal   and GetLifesteal()   or 0)
        local av  = string.format("%.2f", GetAvoidance   and GetAvoidance()   or 0)
        local rawSpeed = GetUnitSpeed and GetUnitSpeed("player") or 7.0
        local sp  = string.format("%.2f", math.max(0, (rawSpeed / 7.0 * 100) - 100))
        txt:SetText(
            hex .. "Crit:|r "       .. cr .. "%\n" ..
            hex .. "Haste:|r "      .. ha .. "%\n" ..
            hex .. "Mastery:|r "    .. ma .. "%\n" ..
            hex .. "Vers:|r "       .. ve .. "%\n" ..
            hex .. "Leech:|r "      .. le .. "%\n" ..
            hex .. "Avoidance:|r "  .. av .. "%\n" ..
            hex .. "Speed:|r "      .. sp .. "%"
        )
    end
    statsFrame:RegisterEvent("UNIT_STATS")
    statsFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    statsFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    statsFrame:SetScript("OnEvent", Update)
    Update()
    return statsFrame
end

-- ============================================================
-- Widgets
-- ============================================================

local function CreateToggle(parent, dbKey, cvarName, onChange)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(36, 20)
    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.15, 0.15, 0.18, 1.0)
    local fill = btn:CreateTexture(nil, "ARTWORK")
    fill:SetAllPoints()
    btn.fill = fill
    local function GetState()
        return SacrificeUIDB and SacrificeUIDB[dbKey] or false
    end
    local function RefreshColor()
        if GetState() then fill:SetColorTexture(unpack(GetAccentColor())); fill:Show()
        else fill:Hide() end
    end
    btn.RefreshColor = RefreshColor
    RefreshColor()
    btn:SetScript("OnClick", function()
        local new = not GetState()
        if SacrificeUIDB then SacrificeUIDB[dbKey] = new end
        if cvarName then SetCVar(cvarName, new and "1" or "0") end
        RefreshColor()
        if onChange then onChange(new) end
    end)
    tinsert(accentToggles, btn)
    return btn
end

local function CreateSettingRow(parent, labelStr, dbKey, cvarName, width, onChange)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(width or 460, 38)
    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.10, 0.10, 0.13, 0.55)
    local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lbl:SetPoint("LEFT", row, "LEFT", 12, 0)
    lbl:SetText(labelStr)
    lbl:SetTextColor(unpack(C_WHITE))
    local toggle = CreateToggle(row, dbKey, cvarName, onChange)
    toggle:SetPoint("RIGHT", row, "RIGHT", -12, 0)
    row.toggle = toggle
    return row
end

local function CreateSliderRow(parent, labelStr, minV, maxV, step, dbKey, cvarName, width)
    local con = CreateFrame("Frame", nil, parent)
    con:SetSize(width or 440, 34)
    local lbl = con:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lbl:SetPoint("LEFT", con, "LEFT", 0, 0)
    lbl:SetText(labelStr)
    lbl:SetTextColor(unpack(C_WHITE))
    local slider = CreateFrame("Slider", nil, con)
    slider:SetOrientation("HORIZONTAL")
    slider:SetSize((width or 440) - 110, 16)
    slider:SetPoint("RIGHT", con, "RIGHT", -48, 0)
    slider:SetMinMaxValues(minV, maxV)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    local track = slider:CreateTexture(nil, "BACKGROUND")
    track:SetAllPoints()
    track:SetColorTexture(0.20, 0.20, 0.24, 1.0)
    slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    local initVal = (dbKey and SacrificeUIDB and SacrificeUIDB[dbKey])
        or (cvarName and tonumber(GetCVar(cvarName)))
        or minV
    slider:SetValue(initVal)
    local valTxt = con:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    valTxt:SetPoint("LEFT", slider, "RIGHT", 8, 0)
    valTxt:SetText(string.format(step < 1 and "%.1f" or "%d", initVal))
    valTxt:SetTextColor(unpack(C_WHITE))
    valTxt:SetWidth(40)
    slider:SetScript("OnValueChanged", function(_, val)
        local fmt = step < 1 and "%.1f" or "%d"
        valTxt:SetText(string.format(fmt, val))
        if cvarName then SetCVar(cvarName, tostring(val)) end
        if dbKey and SacrificeUIDB then SacrificeUIDB[dbKey] = val end
    end)
    return con
end

local function CreateTabBar(parent, defs, TAB_Y, onSwitch)
    local tabs = {}
    for _, def in ipairs(defs) do
        local btn = CreateFrame("Button", nil, parent)
        btn:SetSize(def.w or 110, 26)
        btn:SetPoint("TOPLEFT", parent, "TOPLEFT", def.x, TAB_Y)
        local txt = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        txt:SetAllPoints(); txt:SetText(def.label)
        btn.text = txt
        local ul = btn:CreateTexture(nil, "ARTWORK")
        ul:SetHeight(2)
        ul:SetPoint("BOTTOMLEFT",  btn, "BOTTOMLEFT",  0, 0)
        ul:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)
        ul:SetColorTexture(unpack(GetAccentColor()))
        ul:Hide()
        btn.underline = ul
        btn:SetScript("OnClick", function() onSwitch(def.key) end)
        tabs[def.key] = btn
    end
    return tabs
end

-- ============================================================
-- Addons pane
-- ============================================================

local function RefreshAddonRows(pane, tabKey)
    if pane.rows then
        for _, r in ipairs(pane.rows) do r:Hide(); r:SetParent(nil) end
    end
    pane.rows = {}
    local list = tabKey == "Required" and REQUIRED_ADDONS or SUGGESTED_ADDONS
    local yOff = -10
    for _, addon in ipairs(list) do
        local installed, loaded = IsAddonInstalled(addon.name)
        local row = CreateFrame("Frame", nil, pane.scrollChild)
        row:SetSize(pane.scrollChild:GetWidth(), 34)
        row:SetPoint("TOPLEFT", pane.scrollChild, "TOPLEFT", 0, yOff)
        local rbg = row:CreateTexture(nil, "BACKGROUND")
        rbg:SetAllPoints(); rbg:SetColorTexture(0.10, 0.10, 0.13, 0.55)
        local bar = row:CreateTexture(nil, "ARTWORK")
        bar:SetSize(3, 18); bar:SetPoint("LEFT", row, "LEFT", 8, 0)
        if loaded then bar:SetColorTexture(0.05, 0.80, 0.25, 1)
        elseif installed then bar:SetColorTexture(1.0, 0.80, 0.0, 1)
        else bar:SetColorTexture(0.85, 0.15, 0.15, 1) end
        local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nameText:SetPoint("LEFT", bar, "RIGHT", 10, 2)
        nameText:SetText(addon.display); nameText:SetTextColor(unpack(C_WHITE))
        local authText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        authText:SetPoint("LEFT", nameText, "RIGHT", 6, 0)
        authText:SetText("by " .. addon.author); authText:SetTextColor(0.40, 0.40, 0.45)
        local stText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        stText:SetPoint("RIGHT", row, "RIGHT", -12, 0)
        if loaded then stText:SetText("Loaded"); stText:SetTextColor(0.05, 0.80, 0.25)
        elseif installed then stText:SetText("Not Enabled"); stText:SetTextColor(1.0, 0.80, 0.0)
        else stText:SetText("Not Installed"); stText:SetTextColor(0.85, 0.15, 0.15) end
        yOff = yOff - 38
        tinsert(pane.rows, row)
    end
    pane.scrollChild:SetHeight(math.abs(yOff) + 16)
end

local function SetAddonTab(pane, tabKey)
    activeAddonTab = tabKey
    local c = GetAccentColor()
    for key, tab in pairs(pane.tabs) do
        if key == tabKey then tab.text:SetTextColor(unpack(c)); tab.underline:Show()
        else tab.text:SetTextColor(unpack(C_INACTIVE)); tab.underline:Hide() end
    end
    RefreshAddonRows(pane, tabKey)
end

local function BuildAddonsPane(parent)
    local pane = CreateFrame("Frame", nil, parent)
    pane:SetAllPoints(parent); pane:Hide()
    local title = pane:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", pane, "TOPLEFT", 20, -18)
    title:SetFont("Fonts\\FRIZQT__.TTF", 22, "OUTLINE")
    title:SetText("Addons"); title:SetTextColor(unpack(C_WHITE))
    local sub = pane:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    sub:SetText("Required and suggested addons for Sacrifice."); sub:SetTextColor(0.40, 0.40, 0.45)
    local TAB_Y = -72
    pane.tabs = CreateTabBar(pane, {
        { key = "Required",  label = "Required",  x = 20,  w = 100 },
        { key = "Suggested", label = "Suggested", x = 130, w = 100 },
    }, TAB_Y, function(key) SetAddonTab(pane, key) end)
    HLine(pane, 14, -14, TAB_Y - 28)
    local scroll = CreateFrame("ScrollFrame", nil, pane, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",     pane, "TOPLEFT",     14, TAB_Y - 36)
    scroll:SetPoint("BOTTOMRIGHT", pane, "BOTTOMRIGHT", -30, 16)
    local sc = CreateFrame("Frame", nil, scroll)
    sc:SetWidth(490); sc:SetHeight(300)
    scroll:SetScrollChild(sc)
    pane.scrollChild = sc
    return pane
end

-- ============================================================
-- Global Settings sub-tabs
-- ============================================================

local function BuildGeneralTab(parent)
    local tab = CreateFrame("Frame", nil, parent)
    tab:SetAllPoints(parent); tab:Hide()

    local scroll = CreateFrame("ScrollFrame", nil, tab, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",     tab, "TOPLEFT",     0,   0)
    scroll:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT", -20, 0)

    local sc = CreateFrame("Frame", nil, scroll)
    local W = 440
    sc:SetWidth(W); sc:SetHeight(900)
    scroll:SetScrollChild(sc)

    local y = -8

    local function SH(text)  -- section header
        local h = sc:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        h:SetPoint("TOPLEFT", sc, "TOPLEFT", 0, y)
        h:SetText(text); h:SetTextColor(0.42, 0.42, 0.46)
        y = y - 22
    end

    local function Row(label, key, cvar, onChange)
        local r = CreateSettingRow(sc, label, key, cvar, W, onChange)
        r:SetPoint("TOPLEFT", sc, "TOPLEFT", 0, y); y = y - 42
        return r
    end

    local function Sep() HLine(sc, 0, 0, y + 4); y = y - 16 end

    -- DISPLAY
    SH("DISPLAY")
    Row("Show Performance", "showPerformance", nil, function(s)
        local f = CreatePerfOverlay(); if s then f:Show() else f:Hide() end
    end)
    Row("Show Stats", "showStats", nil, function(s)
        local f = CreateStatsOverlay(); if s then f:Show() else f:Hide() end
    end)
    Sep()

    -- M+ ENEMY FORCES
    SH("M+ ENEMY FORCES")
    Row("Show Enemy Forces %", "mythicCountEnabled", nil, function()
        SacrificeUI:RefreshMythicCount()
    end)

    local hint = sc:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hint:SetPoint("TOPLEFT", sc, "TOPLEFT", 6, y)
    hint:SetWidth(W - 12); hint:SetJustifyH("LEFT")
    hint:SetText("Shows each mob's enemy forces % on tooltips and nameplates. Populate NPC IDs in MythicCountData.lua.")
    hint:SetTextColor(0.38, 0.38, 0.42)
    y = y - (hint:GetStringHeight() + 8)

    sc:SetHeight(math.abs(y) + 20)
    return tab
end


local function BuildTalentRemindersTab(parent)
    local tab = CreateFrame("Frame", nil, parent)
    tab:SetAllPoints(parent); tab:Hide()
    local W = parent:GetWidth() - 20
    local halfW = math.floor((W - 8) / 2)

    -- Shared state
    local selDungeon  = nil   -- string
    local selSpecID   = nil   -- number
    local selSpecName = nil   -- string
    local selLoadout  = nil   -- string (name)

    -- ---- Reusable dropdown builder ----
    local function MakeDD(w, yOff, xOff, placeholder)
        local dd = CreateFrame("Frame", nil, tab, "BackdropTemplate")
        dd:SetSize(w, 30)
        dd:SetPoint("TOPLEFT", tab, "TOPLEFT", xOff, yOff)
        dd:SetBackdrop(TipBorder())
        dd:SetBackdropColor(0.10, 0.10, 0.13, 0.9)
        dd:SetBackdropBorderColor(unpack(C_BORDER))
        dd:EnableMouse(true)

        local lbl = dd:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetPoint("LEFT", dd, "LEFT", 10, 0)
        lbl:SetText(placeholder); lbl:SetTextColor(0.50, 0.50, 0.52)
        dd.label = lbl

        local arrow = dd:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        arrow:SetPoint("RIGHT", dd, "RIGHT", -8, 0)
        arrow:SetText("▼"); arrow:SetTextColor(0.45, 0.45, 0.48)

        local list = CreateFrame("Frame", nil, dd, "BackdropTemplate")
        list:SetBackdrop(TipBorder())
        list:SetBackdropColor(0.07, 0.07, 0.09, 0.98)
        list:SetBackdropBorderColor(unpack(C_BORDER))
        list:SetFrameStrata("TOOLTIP")
        list:SetWidth(w); list:Hide()
        dd.list = list
        dd.placeholder = placeholder

        function dd:Reset()
            lbl:SetText(placeholder); lbl:SetTextColor(0.50, 0.50, 0.52)
        end

        -- options = { { label, onSelect } }
        function dd:Open(options)
            local children = { list:GetChildren() }
            for _, ch in ipairs(children) do ch:Hide(); ch:SetParent(nil) end
            for i, opt in ipairs(options) do
                local btn = CreateFrame("Button", nil, list)
                btn:SetSize(w - 6, 24)
                btn:SetPoint("TOPLEFT", list, "TOPLEFT", 3, -3 - (i - 1) * 24)
                local t = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                t:SetAllPoints(); t:SetText(opt.label); t:SetTextColor(unpack(C_WHITE))
                btn:SetScript("OnEnter", function() t:SetTextColor(unpack(GetAccentColor())) end)
                btn:SetScript("OnLeave", function() t:SetTextColor(unpack(C_WHITE)) end)
                btn:SetScript("OnClick", function()
                    lbl:SetText(opt.label); lbl:SetTextColor(unpack(C_WHITE))
                    list:Hide()
                    if opt.onSelect then opt.onSelect() end
                end)
            end
            list:SetHeight(#options * 24 + 6)
            list:SetPoint("TOPLEFT", dd, "BOTTOMLEFT", 0, -2)
            list:Show()
        end

        dd:SetScript("OnMouseDown", function()
            if list:IsShown() then list:Hide()
            elseif dd.onOpen then dd:onOpen() end
        end)

        return dd
    end

    -- ---- Dungeon dropdown (left half) ----
    local dungeonDD = MakeDD(halfW, -8, 0, "Select Dungeon")
    dungeonDD.onOpen = function(self)
        local opts = {}
        for _, name in ipairs(MPLUS_DUNGEONS) do
            tinsert(opts, { label = name, onSelect = function()
                selDungeon = name
            end })
        end
        self:Open(opts)
    end

    -- ---- Spec dropdown (right half) ----
    local loadoutBox, loadoutTB, loadoutHint  -- forward-declared so specDD.onOpen can reference them

    local specDD = MakeDD(halfW, -8, halfW + 8, "Select Spec")
    specDD.onOpen = function(self)
        local opts = {}
        local n = GetNumSpecializations and GetNumSpecializations() or 0
        for i = 1, n do
            local specID, name = GetSpecializationInfo(i)
            tinsert(opts, { label = name, onSelect = function()
                selSpecID   = specID
                selSpecName = name
                selLoadout  = nil
                loadoutTB:SetText("")
                loadoutHint:Show()
                loadoutBox:Show()
                loadoutTB:SetFocus()
            end })
        end
        self:Open(opts)
    end

    -- ---- Loadout textbox (full width, shown after spec chosen) ----
    loadoutBox = CreateFrame("Frame", nil, tab, "BackdropTemplate")
    loadoutBox:SetSize(W, 30)
    loadoutBox:SetPoint("TOPLEFT", tab, "TOPLEFT", 0, -48)
    loadoutBox:SetBackdrop(TipBorder())
    loadoutBox:SetBackdropColor(0.10, 0.10, 0.13, 0.9)
    loadoutBox:SetBackdropBorderColor(unpack(C_BORDER))
    loadoutBox:Hide()

    loadoutTB = CreateFrame("EditBox", nil, loadoutBox)
    loadoutTB:SetPoint("LEFT", loadoutBox, "LEFT", 10, 0)
    loadoutTB:SetPoint("RIGHT", loadoutBox, "RIGHT", -10, 0)
    loadoutTB:SetHeight(20)
    loadoutTB:SetAutoFocus(false)
    loadoutTB:SetMaxLetters(128)
    loadoutTB:SetFontObject("GameFontNormal")
    loadoutTB:SetTextColor(unpack(C_WHITE))

    loadoutHint = loadoutBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    loadoutHint:SetPoint("LEFT", loadoutBox, "LEFT", 10, 0)
    loadoutHint:SetText("Type Talent Loadout Name...")
    loadoutHint:SetTextColor(0.50, 0.50, 0.52)

    loadoutTB:SetScript("OnTextChanged", function(self)
        local txt = strtrim(self:GetText())
        selLoadout = txt ~= "" and txt or nil
        if txt ~= "" then loadoutHint:Hide() else loadoutHint:Show() end
    end)
    loadoutTB:SetScript("OnEditFocusGained", function(self)
        if strtrim(self:GetText()) == "" then loadoutHint:Hide() end
    end)
    loadoutTB:SetScript("OnEditFocusLost", function(self)
        if strtrim(self:GetText()) == "" then loadoutHint:Show() end
    end)
    loadoutTB:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    loadoutTB:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    -- ---- Add Reminder button ----
    local addBtnY = -90
    local addBtn = CreateFrame("Button", nil, tab, "BackdropTemplate")
    addBtn:SetSize(160, 30)
    addBtn:SetPoint("TOPLEFT", tab, "TOPLEFT", math.floor((W - 160) / 2), addBtnY)
    addBtn:SetBackdrop(TipBorder())
    addBtn:SetBackdropColor(0.10, 0.10, 0.13, 0.9)
    addBtn:SetBackdropBorderColor(unpack(GetAccentColor()))
    addBtn:EnableMouse(true)
    local addBtnTxt = addBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    addBtnTxt:SetAllPoints(); addBtnTxt:SetText("Add Reminder")
    addBtnTxt:SetTextColor(unpack(GetAccentColor()))

    HLine(tab, 0, -10, addBtnY - 40)

    -- ---- Reminder list ----
    local scroll = CreateFrame("ScrollFrame", nil, tab, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",     tab, "TOPLEFT",     0, addBtnY - 48)
    scroll:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT", -20, 0)
    local sc = CreateFrame("Frame", nil, scroll)
    sc:SetWidth(W - 20); sc:SetHeight(200)
    scroll:SetScrollChild(sc)

    local function RefreshReminders()
        local children = { sc:GetChildren() }
        for _, ch in ipairs(children) do ch:Hide(); ch:SetParent(nil) end
        local regions = { sc:GetRegions() }
        for _, r in ipairs(regions) do r:Hide() end

        local reminders = SacrificeUIDB and SacrificeUIDB.talentReminders or {}
        if #reminders == 0 then
            local et = sc:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            et:SetPoint("TOP", sc, "TOP", 0, -20)
            et:SetText("No talent reminders configured"); et:SetTextColor(0.30, 0.30, 0.33)
            sc:SetHeight(60); return
        end
        local yOff = -8
        for i, rem in ipairs(reminders) do
            local row = CreateFrame("Frame", nil, sc)
            row:SetSize(W - 20, 30); row:SetPoint("TOPLEFT", sc, "TOPLEFT", 0, yOff)
            local rbg = row:CreateTexture(nil, "BACKGROUND")
            rbg:SetAllPoints(); rbg:SetColorTexture(0.10, 0.10, 0.13, 0.55)
            local bar = row:CreateTexture(nil, "ARTWORK")
            bar:SetSize(3, 16); bar:SetPoint("LEFT", row, "LEFT", 6, 0)
            bar:SetColorTexture(unpack(GetAccentColor()))
            local rt = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            rt:SetPoint("LEFT", bar, "RIGHT", 8, 0)
            rt:SetText(rem.dungeon .. "   |   " .. rem.specName .. "   -   " .. rem.loadoutName)
            rt:SetTextColor(unpack(C_WHITE))
            local delBtn = CreateFrame("Button", nil, row)
            delBtn:SetSize(20, 20); delBtn:SetPoint("RIGHT", row, "RIGHT", -6, 0)
            local delT = delBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            delT:SetAllPoints(); delT:SetText("×"); delT:SetTextColor(0.85, 0.15, 0.15)
            local idx = i
            delBtn:SetScript("OnClick", function()
                table.remove(SacrificeUIDB.talentReminders, idx)
                RefreshReminders()
            end)
            yOff = yOff - 34
        end
        sc:SetHeight(math.abs(yOff) + 16)
    end

    addBtn:SetScript("OnClick", function()
        if not selDungeon or not selSpecID or not selLoadout then return end
        if not SacrificeUIDB.talentReminders then SacrificeUIDB.talentReminders = {} end
        tinsert(SacrificeUIDB.talentReminders, {
            dungeon     = selDungeon,
            specID      = selSpecID,
            specName    = selSpecName,
            loadoutName = selLoadout,
        })
        selDungeon = nil; selSpecID = nil; selSpecName = nil; selLoadout = nil
        dungeonDD:Reset(); specDD:Reset()
        loadoutTB:SetText(""); loadoutHint:Show(); loadoutBox:Hide()
        RefreshReminders()
    end)

    tab:SetScript("OnShow", RefreshReminders)
    RefreshReminders()
    return tab
end

-- ============================================================
-- Talent reminder popup
-- ============================================================

local function ShowTalentReminderPopup(loadoutName, dungeonName)
    if not reminderPopup then
        reminderPopup = CreateFrame("Frame", "SacrificeUIReminderPopup", UIParent, "BackdropTemplate")
        reminderPopup:SetSize(320, 130)
        reminderPopup:SetPoint("CENTER")
        reminderPopup:SetBackdrop(MainBorder())
        reminderPopup:SetBackdropColor(0.07, 0.07, 0.08, 0.98)
        reminderPopup:SetFrameStrata("DIALOG")
        reminderPopup:SetMovable(true); reminderPopup:EnableMouse(true)
        reminderPopup:RegisterForDrag("LeftButton")
        reminderPopup:SetScript("OnDragStart", reminderPopup.StartMoving)
        reminderPopup:SetScript("OnDragStop",  reminderPopup.StopMovingOrSizing)

        local titleTxt = reminderPopup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        titleTxt:SetPoint("TOP", reminderPopup, "TOP", 0, -14)
        titleTxt:SetText("Talent Reminder")
        reminderPopup.titleTxt = titleTxt

        local msg = reminderPopup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        msg:SetPoint("CENTER", reminderPopup, "CENTER", 0, 10)
        msg:SetWidth(280); msg:SetJustifyH("CENTER")
        msg:SetTextColor(unpack(C_WHITE))
        reminderPopup.msg = msg

        local dismissBtn = CreateFrame("Button", nil, reminderPopup, "BackdropTemplate")
        dismissBtn:SetSize(100, 26)
        dismissBtn:SetPoint("BOTTOM", reminderPopup, "BOTTOM", 0, 12)
        dismissBtn:SetBackdrop(TipBorder())
        dismissBtn:SetBackdropColor(0.10, 0.10, 0.13, 0.9)
        local dismissTxt = dismissBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        dismissTxt:SetAllPoints(); dismissTxt:SetText("Dismiss")
        reminderPopup.dismissTxt = dismissTxt
        reminderPopup.dismissBtn = dismissBtn
        dismissBtn:SetScript("OnClick", function() reminderPopup:Hide() end)
    end

    local c = GetAccentColor()
    reminderPopup:SetBackdropBorderColor(unpack(c))
    reminderPopup.titleTxt:SetTextColor(unpack(c))
    reminderPopup.dismissTxt:SetTextColor(unpack(c))
    reminderPopup.dismissBtn:SetBackdropBorderColor(unpack(c))
    reminderPopup.msg:SetText(
        "Reminder to load\n" ..
        AccentHex() .. "\"" .. loadoutName .. "\"|r Talents\n" ..
        "in " .. dungeonName
    )
    reminderPopup:Show()
end

-- ============================================================
-- Logging tab (LoggerHead equivalent)
-- ============================================================

local function BuildLoggingTab(parent)
    local tab = CreateFrame("Frame", nil, parent)
    tab:SetAllPoints(parent); tab:Hide()

    local W = 440
    local STATUS_H = 34

    -- Status bar (fixed, does not scroll)
    local statusBg = tab:CreateTexture(nil, "BACKGROUND")
    statusBg:SetHeight(STATUS_H)
    statusBg:SetPoint("TOPLEFT",  tab, "TOPLEFT",  0,   0)
    statusBg:SetPoint("TOPRIGHT", tab, "TOPRIGHT", -20, 0)
    statusBg:SetColorTexture(0.08, 0.08, 0.10, 0.95)

    local statusLbl = tab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    statusLbl:SetPoint("TOPLEFT", tab, "TOPLEFT", 12, -9)
    statusLbl:SetText("Combat Log")
    statusLbl:SetTextColor(unpack(C_WHITE))

    -- "Enable" / "Disable" button - controls logEnabled (master feature toggle)
    local toggleBtn = CreateFrame("Button", nil, tab, "BackdropTemplate")
    toggleBtn:SetSize(100, 24)
    toggleBtn:SetPoint("TOPRIGHT", tab, "TOPRIGHT", -20, -5)
    toggleBtn:SetBackdrop(TipBorder())
    toggleBtn:SetBackdropColor(0.10, 0.10, 0.13, 0.9)
    toggleBtn:SetBackdropBorderColor(unpack(GetAccentColor()))
    local toggleTxt = toggleBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    toggleTxt:SetAllPoints()
    toggleTxt:SetTextColor(unpack(GetAccentColor()))
    tinsert(accentToggles, {
        RefreshColor = function()
            local c = GetAccentColor()
            toggleBtn:SetBackdropBorderColor(unpack(c))
            toggleTxt:SetTextColor(unpack(c))
        end
    })

    -- Scroll frame
    local scroll = CreateFrame("ScrollFrame", nil, tab, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",     tab, "TOPLEFT",     0,   -(STATUS_H + 6))
    scroll:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT", -20, 0)

    local sc = CreateFrame("Frame", nil, scroll)
    sc:SetWidth(W)
    scroll:SetScrollChild(sc)

    local y = -8

    local function SH(text)
        local h = sc:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        h:SetPoint("TOPLEFT", sc, "TOPLEFT", 0, y)
        h:SetText(text); h:SetTextColor(0.42, 0.42, 0.46)
        y = y - 22
    end

    local function Sep() HLine(sc, 0, 0, y + 4); y = y - 16 end

    -- Path note
    local pathNote = sc:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    pathNote:SetPoint("TOPLEFT", sc, "TOPLEFT", 0, y)
    pathNote:SetWidth(W); pathNote:SetJustifyH("LEFT")
    pathNote:SetText("Log file: WoW/_retail_/Logs/WoWCombatLog.txt")
    pathNote:SetTextColor(0.35, 0.35, 0.38)
    y = y - 22
    Sep()

    SH("AUTO-LOGGING")

    local allSubRows   = {}   -- enableAll row + 4 activity rows
    local activityRows = {}   -- just the 4 activity rows

    local ACTIVITIES = {
        { key = "logDungeons",      label = "Log in Dungeons (M+)" },
        { key = "logRaids",         label = "Log in Raids"         },
        { key = "logBattlegrounds", label = "Log in Battlegrounds"  },
        { key = "logArenas",        label = "Log in Arenas"        },
    }

    local function SetAllActivityKeys(val)
        if not SacrificeUIDB then return end
        for _, act in ipairs(ACTIVITIES) do SacrificeUIDB[act.key] = val end
    end

    local function RefreshAllToggles()
        for _, r in ipairs(allSubRows) do
            if r.toggle then r.toggle:RefreshColor() end
        end
    end

    -- Apply alpha and Enable/Disable state to all sub-rows based on DB
    local function UpdateSubState()
        local db = SacrificeUIDB
        local featureOn = db and db.logEnabled
        local allOn     = db and db.logEnableAll

        toggleTxt:SetText(featureOn and "Disable" or "Enable")

        -- "Enable All" row follows feature master
        local ear = allSubRows[1]
        if ear then
            ear:SetAlpha(featureOn and 1.0 or 0.4)
            if ear.toggle then
                if featureOn then ear.toggle:Enable() else ear.toggle:Disable() end
            end
        end

        -- Activity rows: disabled when feature off OR when Enable All is on
        for _, r in ipairs(activityRows) do
            if not featureOn then
                r:SetAlpha(0.4)
                if r.toggle then r.toggle:Disable() end
            elseif allOn then
                r:SetAlpha(0.6)
                if r.toggle then r.toggle:Disable() end
            else
                r:SetAlpha(1.0)
                if r.toggle then r.toggle:Enable() end
            end
        end
    end

    -- "Enable All" row: when checked, force-checks + disables activity rows;
    -- when unchecked, unchecks + re-enables them.
    local enableAllRow = CreateSettingRow(sc, "Enable All", "logEnableAll", nil, W,
        function(newState)
            SetAllActivityKeys(newState and true or false)
            RefreshAllToggles()
            UpdateSubState()
            SacrificeUI:UpdateCombatLogging()
        end)
    enableAllRow:SetPoint("TOPLEFT", sc, "TOPLEFT", 0, y); y = y - 42
    tinsert(allSubRows, enableAllRow)

    -- Individual activity rows
    for _, act in ipairs(ACTIVITIES) do
        local r = CreateSettingRow(sc, act.label, act.key, nil, W,
            function() SacrificeUI:UpdateCombatLogging() end)
        r:SetPoint("TOPLEFT", sc, "TOPLEFT", 0, y); y = y - 42
        tinsert(allSubRows, r)
        tinsert(activityRows, r)
    end

    sc:SetHeight(math.abs(y) + 20)

    -- Master enable/disable: toggling off unchecks everything and stops logging.
    toggleBtn:SetScript("OnClick", function()
        if not SacrificeUIDB then return end
        local newState = not SacrificeUIDB.logEnabled
        SacrificeUIDB.logEnabled = newState
        if not newState then
            SacrificeUIDB.logEnableAll = false
            SetAllActivityKeys(false)
            if LoggingCombat then LoggingCombat(0) end
            print("|cFFDC143CSacrificeUI|r Combat logging |cFF888888disabled|r.")
        end
        RefreshAllToggles()
        UpdateSubState()
    end)

    tab:SetScript("OnShow", function()
        RefreshAllToggles()
        UpdateSubState()
    end)

    return tab
end

local function BuildGlobalSettingsPane(parent)
    local pane = CreateFrame("Frame", nil, parent)
    pane:SetAllPoints(parent); pane:Hide()

    local title = pane:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", pane, "TOPLEFT", 20, -18)
    title:SetFont("Fonts\\FRIZQT__.TTF", 22, "OUTLINE")
    title:SetText("Global Settings"); title:SetTextColor(unpack(C_WHITE))
    local sub = pane:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    sub:SetText("General options and configuration."); sub:SetTextColor(0.40, 0.40, 0.45)

    local TAB_Y = -72
    local content = CreateFrame("Frame", nil, pane)
    content:SetPoint("TOPLEFT",     pane, "TOPLEFT",     20, TAB_Y - 36)
    content:SetPoint("BOTTOMRIGHT", pane, "BOTTOMRIGHT", -14, 10)

    local subPanes = {
        General         = BuildGeneralTab(content),
        TalentReminders = BuildTalentRemindersTab(content),
        Logging         = BuildLoggingTab(content),
    }

    local activeSubTab = "General"

    local function ShowSubTab(key)
        activeSubTab = key
        pane.activeSubTab = key
        local c = GetAccentColor()
        for k, sp in pairs(subPanes) do
            if k == key then sp:Show() else sp:Hide() end
        end
        for k, tab in pairs(pane.subTabs) do
            if k == key then tab.text:SetTextColor(unpack(c)); tab.underline:Show()
            else tab.text:SetTextColor(unpack(C_INACTIVE)); tab.underline:Hide() end
        end
    end

    pane.subTabs = CreateTabBar(pane, {
        { key = "General",         label = "General",          x = 20,  w = 80  },
        { key = "TalentReminders", label = "Talent Reminders", x = 108, w = 125 },
        { key = "Logging",         label = "Logging",          x = 241, w = 80  },
    }, TAB_Y, ShowSubTab)

    HLine(pane, 14, -14, TAB_Y - 28)

    pane.activeSubTab = activeSubTab
    globalSettingsPane = pane
    ShowSubTab("General")
    return pane
end

-- ============================================================
-- Settings pane
-- ============================================================

local function BuildSettingsPane(parent)
    local pane = CreateFrame("Frame", nil, parent)
    pane:SetAllPoints(parent); pane:Hide()

    local title = pane:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", pane, "TOPLEFT", 20, -18)
    title:SetFont("Fonts\\FRIZQT__.TTF", 22, "OUTLINE")
    title:SetText("Settings"); title:SetTextColor(unpack(C_WHITE))
    HLine(pane, 14, -14, -58)

    -- THEME
    local th = pane:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    th:SetPoint("TOPLEFT", pane, "TOPLEFT", 20, -72)
    th:SetText("THEME"); th:SetTextColor(0.42, 0.42, 0.46)
    local ccRow = CreateSettingRow(pane, "Class Color", "classColorEnabled", nil, 460, ApplyTheme)
    ccRow:SetPoint("TOPLEFT", pane, "TOPLEFT", 14, -88)

    -- GUILD MEMBERSHIP
    local gm = pane:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    gm:SetPoint("TOPLEFT", pane, "TOPLEFT", 20, -148)
    gm:SetText("GUILD MEMBERSHIP"); gm:SetTextColor(0.42, 0.42, 0.46)
    local desc = pane:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    desc:SetPoint("TOPLEFT", pane, "TOPLEFT", 20, -166)
    desc:SetText("Enter your API key to link this character to your Sacrifice roster profile.")
    desc:SetTextColor(0.40, 0.40, 0.45); desc:SetWidth(460); desc:SetJustifyH("LEFT")

    local apiBox = CreateFrame("Frame", nil, pane, "BackdropTemplate")
    apiBox:SetSize(460, 32)
    apiBox:SetPoint("TOPLEFT", pane, "TOPLEFT", 14, -192)
    apiBox:SetBackdrop(TipBorder())
    apiBox:SetBackdropColor(0.10, 0.10, 0.13, 0.9)
    apiBox:SetBackdropBorderColor(unpack(C_BORDER))

    local apiEB = CreateFrame("EditBox", "SacrificeUIAPIKey", apiBox)
    apiEB:SetPoint("TOPLEFT",     apiBox, "TOPLEFT",     10, -6)
    apiEB:SetPoint("BOTTOMRIGHT", apiBox, "BOTTOMRIGHT", -10, 6)
    apiEB:SetFontObject("GameFontNormal")
    apiEB:SetTextColor(unpack(C_WHITE))
    apiEB:SetAutoFocus(false)
    apiEB:SetMaxLetters(128)
    apiEB:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    apiEB:SetScript("OnEnterPressed",  function(self)
        if SacrificeUIDB then SacrificeUIDB.apiKey = self:GetText() end
        self:ClearFocus()
    end)
    apiEB:SetScript("OnEditFocusLost", function(self)
        if SacrificeUIDB then SacrificeUIDB.apiKey = self:GetText() end
    end)

    pane:SetScript("OnShow", function()
        apiEB:SetText(SacrificeUIDB and SacrificeUIDB.apiKey or "")
    end)

    return pane
end

-- ============================================================
-- Placeholder pane
-- ============================================================

local function BuildDungeonsPane(parent)
    local pane = CreateFrame("Frame", nil, parent)
    pane:SetAllPoints(parent); pane:Hide()

    -- Title
    local title = pane:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", pane, "TOPLEFT", 20, -18)
    title:SetFont("Fonts\\FRIZQT__.TTF", 22, "OUTLINE")
    title:SetText("Dungeons"); title:SetTextColor(unpack(C_WHITE))
    local sub = pane:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    sub:SetText("Season 1 M+ ability reference."); sub:SetTextColor(0.40, 0.40, 0.45)

    -- Dimensions: pane is the full content area (FRAME_W - SIDEBAR_W - 1 wide)
    -- Left dungeon list column
    local LIST_W   = 156
    local TOP_Y    = -72   -- top of list/detail area
    local COLHDR_H = 20    -- column header strip height above scroll
    -- The scroll inner width: pane width minus list column minus divider minus scrollbar minus border
    -- We compute dynamically in OnSizeChanged, but use approximate for initial render
    local SCROLL_RIGHT_PAD = 4
    local SCROLLBAR_W      = 20

    -- Vertical divider between list and detail
    local divLine = pane:CreateTexture(nil, "ARTWORK")
    divLine:SetWidth(1)
    divLine:SetPoint("TOPLEFT",    pane, "TOPLEFT",    LIST_W, TOP_Y)
    divLine:SetPoint("BOTTOMLEFT", pane, "BOTTOMLEFT", LIST_W, 8)
    divLine:SetColorTexture(unpack(GetAccentColor()))

    -- Column header strip (non-scrolling, matches DungeonHelper layout)
    local BADGE_W  = 38
    local N_BADGES = 4
    local colHdrBg = pane:CreateTexture(nil, "BACKGROUND", nil, -3)
    colHdrBg:SetHeight(COLHDR_H)
    colHdrBg:SetPoint("TOPLEFT",  pane, "TOPLEFT",  LIST_W + 1, TOP_Y)
    colHdrBg:SetPoint("TOPRIGHT", pane, "TOPRIGHT", -SCROLL_RIGHT_PAD, TOP_Y)
    colHdrBg:SetColorTexture(0.055, 0.055, 0.065, 0.98)

    local colHdrSep = pane:CreateTexture(nil, "ARTWORK")
    colHdrSep:SetHeight(1)
    colHdrSep:SetPoint("TOPLEFT",  pane, "TOPLEFT",  LIST_W + 1, TOP_Y - COLHDR_H)
    colHdrSep:SetPoint("TOPRIGHT", pane, "TOPRIGHT", -SCROLL_RIGHT_PAD, TOP_Y - COLHDR_H)
    colHdrSep:SetColorTexture(0.15, 0.15, 0.17, 1.0)

    local C_INT  = { 0.90, 0.20, 0.20, 1.0 }
    local C_DISP = { 0.25, 0.65, 1.00, 1.0 }
    local C_BUFF = { 0.20, 0.80, 0.30, 1.0 }
    local C_WARN = { 0.90, 0.55, 0.05, 1.0 }

    local function ColHeader(label, slot, color)
        local xRight = -SCROLL_RIGHT_PAD - SCROLLBAR_W - (BADGE_W * slot)
        local lbl = pane:CreateFontString(nil, "OVERLAY")
        lbl:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        lbl:SetSize(BADGE_W, COLHDR_H)
        lbl:SetPoint("TOPRIGHT", pane, "TOPRIGHT", xRight, TOP_Y)
        lbl:SetText(label)
        lbl:SetTextColor(unpack(color))
        lbl:SetJustifyH("CENTER"); lbl:SetJustifyV("MIDDLE")
    end
    ColHeader("WARN", 0, C_WARN)
    ColHeader("BUFF", 1, C_BUFF)
    ColHeader("DISP", 2, C_DISP)
    ColHeader("INT",  3, C_INT)

    -- Scroll frame for dungeon detail
    local scrollFrame = CreateFrame("ScrollFrame", nil, pane, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT",     pane, "TOPLEFT",  LIST_W + 1, TOP_Y - COLHDR_H - 1)
    scrollFrame:SetPoint("BOTTOMRIGHT", pane, "BOTTOMRIGHT", -SCROLL_RIGHT_PAD, 8)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(200); scrollChild:SetHeight(10)
    scrollFrame:SetScrollChild(scrollChild)

    -- Left dungeon list
    local activeDungeon = nil
    local listBtns = {}

    local function SelectDungeon(name)
        activeDungeon = name
        local c = GetAccentColor()
        for n, btn in pairs(listBtns) do
            if n == name then
                btn.txt:SetTextColor(unpack(c))
                btn.bar:Show()
                btn.highlight:SetColorTexture(c[1], c[2], c[3], 0.10)
                btn.highlight:Show()
            else
                btn.txt:SetTextColor(unpack(C_INACTIVE))
                btn.bar:Hide()
                btn.highlight:Hide()
            end
        end

        local data = SacrificeUI.DungeonDataByName and SacrificeUI.DungeonDataByName[name]
        if data and SacrificeUI.BuildDungeonRows and SacrificeUI.RenderDungeonTable then
            local _, playerClass = UnitClass("player")
            local rows = SacrificeUI.BuildDungeonRows(data, playerClass)
            -- Compute actual inner width from scroll frame size
            local sw = scrollFrame:GetWidth()
            local innerW = sw > 40 and (sw - SCROLLBAR_W) or 400
            scrollChild:SetWidth(innerW)
            SacrificeUI.RenderDungeonTable(scrollChild, rows, innerW)
        end
    end

    local btnY = TOP_Y
    for _, name in ipairs(MPLUS_DUNGEONS) do
        local btn = CreateFrame("Button", nil, pane)
        btn:SetSize(LIST_W, 36)
        btn:SetPoint("TOPLEFT", pane, "TOPLEFT", 0, btnY)

        local highlight = btn:CreateTexture(nil, "BACKGROUND")
        highlight:SetAllPoints()
        local hc = GetAccentColor()
        highlight:SetColorTexture(hc[1], hc[2], hc[3], 0.10)
        highlight:Hide()
        btn.highlight = highlight

        local bar = btn:CreateTexture(nil, "ARTWORK")
        bar:SetSize(2, 22); bar:SetPoint("LEFT", btn, "LEFT", 0, 0)
        bar:SetColorTexture(unpack(GetAccentColor())); bar:Hide()
        btn.bar = bar

        local txt = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        txt:SetPoint("LEFT",  btn, "LEFT",  10, 0)
        txt:SetPoint("RIGHT", btn, "RIGHT", -4, 0)
        txt:SetJustifyH("LEFT")
        txt:SetText(name)
        txt:SetTextColor(unpack(C_INACTIVE))
        btn.txt = txt

        btn:SetScript("OnEnter", function()
            if activeDungeon ~= name then txt:SetTextColor(unpack(C_WHITE)) end
        end)
        btn:SetScript("OnLeave", function()
            if activeDungeon ~= name then txt:SetTextColor(unpack(C_INACTIVE)) end
        end)
        btn:SetScript("OnClick", function() SelectDungeon(name) end)

        listBtns[name] = btn
        btnY = btnY - 36
    end

    HLine(pane, 14, -14, TOP_Y - 1)

    -- Select first dungeon once the pane is shown (data is ready by then)
    pane:SetScript("OnShow", function(self)
        self:SetScript("OnShow", nil)  -- only fire once
        if #MPLUS_DUNGEONS > 0 then
            SelectDungeon(MPLUS_DUNGEONS[1])
        end
    end)

    return pane
end

local function BuildPlaceholderPane(parent, label)
    local pane = CreateFrame("Frame", nil, parent)
    pane:SetAllPoints(parent); pane:Hide()
    local title = pane:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", pane, "TOPLEFT", 20, -18)
    title:SetFont("Fonts\\FRIZQT__.TTF", 22, "OUTLINE")
    title:SetText(label); title:SetTextColor(unpack(C_WHITE))
    HLine(pane, 14, -14, -58)
    local ph = pane:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ph:SetPoint("CENTER"); ph:SetText("Coming soon"); ph:SetTextColor(0.28, 0.28, 0.30)
    return pane
end

-- ============================================================
-- Navigation
-- ============================================================

local function ShowPane(key)
    activeNav = key
    local c = GetAccentColor()
    for k, pane in pairs(contentPanes) do
        if k == key then pane:Show() else pane:Hide() end
    end
    for k, btn in pairs(navButtons) do
        if k == key then
            btn.text:SetTextColor(unpack(c)); btn.leftBar:Show(); btn.bgHighlight:Show()
        else
            btn.text:SetTextColor(unpack(C_INACTIVE)); btn.leftBar:Hide(); btn.bgHighlight:Hide()
        end
    end
    if key == "Addons" and contentPanes["Addons"] then
        SetAddonTab(contentPanes["Addons"], activeAddonTab)
    end
end

-- ============================================================
-- Main window
-- ============================================================

local function CreateMainWindow()
    if mainFrame then return mainFrame end

    mainFrame = CreateFrame("Frame", "SacrificeUIMainFrame", UIParent, "BackdropTemplate")
    mainFrame:SetSize(FRAME_W, FRAME_H)
    mainFrame:SetPoint("CENTER")
    mainFrame:SetMovable(true); mainFrame:EnableMouse(true)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetScript("OnDragStart", mainFrame.StartMoving)
    mainFrame:SetScript("OnDragStop",  mainFrame.StopMovingOrSizing)
    mainFrame:SetFrameStrata("DIALOG")
    mainFrame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", tile = false })
    mainFrame:SetBackdropColor(0.07, 0.07, 0.08, 0.98)

    -- Explicit 1px accent border lines (OVERLAY so they paint over sidebar/content)
    local function BorderLine()
        local t = mainFrame:CreateTexture(nil, "OVERLAY")
        t:SetColorTexture(unpack(GetAccentColor()))
        return t
    end
    local bTop   = BorderLine(); bTop:SetHeight(1)
    bTop:SetPoint("TOPLEFT",    mainFrame, "TOPLEFT",    0, 0)
    bTop:SetPoint("TOPRIGHT",   mainFrame, "TOPRIGHT",   0, 0)
    local bBot   = BorderLine(); bBot:SetHeight(1)
    bBot:SetPoint("BOTTOMLEFT",  mainFrame, "BOTTOMLEFT",  0, 0)
    bBot:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", 0, 0)
    local bLeft  = BorderLine(); bLeft:SetWidth(1)
    bLeft:SetPoint("TOPLEFT",    mainFrame, "TOPLEFT",    0,  0)
    bLeft:SetPoint("BOTTOMLEFT", mainFrame, "BOTTOMLEFT", 0,  0)
    local bRight = BorderLine(); bRight:SetWidth(1)
    bRight:SetPoint("TOPRIGHT",    mainFrame, "TOPRIGHT",    0,  0)
    bRight:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", 0,  0)
    mainFrame.borderLines = { bTop, bBot, bLeft, bRight }

    -- Sidebar
    local sidebar = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
    sidebar:SetSize(SIDEBAR_W, FRAME_H)
    sidebar:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 0, 0)
    sidebar:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", tile = false })
    sidebar:SetBackdropColor(0.04, 0.04, 0.05, 0.98)

    -- Logo: icon + text side by side
    logoIcon = sidebar:CreateTexture(nil, "OVERLAY")
    logoIcon:SetSize(28, 28)
    logoIcon:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 12, -14)
    logoIcon:SetTexture("Interface\\ICONS\\Ability_Warrior_RampageAlt")
    logoIcon:SetVertexColor(unpack(GetAccentColor()))

    logoText = sidebar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    logoText:SetPoint("LEFT", logoIcon, "RIGHT", 8, 0)
    logoText:SetFont("Fonts\\MORPHEUS.TTF", 17, "OUTLINE")
    logoText:SetText(AccentHex() .. "Sacrifice|r|cFFFFFFFFUI|r")
    HLine(sidebar, 10, -10, -52)

    local c = GetAccentColor()
    local navY = -64
    for _, key in ipairs(NAV_ITEMS) do
        local btn = CreateFrame("Button", nil, sidebar)
        btn:SetSize(SIDEBAR_W, 40)
        btn:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 0, navY)
        local bgH = btn:CreateTexture(nil, "BACKGROUND")
        bgH:SetAllPoints(); bgH:SetColorTexture(c[1], c[2], c[3], 0.12); bgH:Hide()
        btn.bgHighlight = bgH
        local lbar = btn:CreateTexture(nil, "ARTWORK")
        lbar:SetSize(3, 22); lbar:SetPoint("LEFT", btn, "LEFT", 0, 0)
        lbar:SetColorTexture(unpack(c)); lbar:Hide()
        btn.leftBar = lbar
        local txt = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        txt:SetPoint("LEFT", btn, "LEFT", 20, 0); txt:SetText(key)
        txt:SetTextColor(unpack(C_INACTIVE))
        btn.text = txt
        btn:SetScript("OnEnter", function() if activeNav ~= key then txt:SetTextColor(unpack(C_WHITE)) end end)
        btn:SetScript("OnLeave", function() if activeNav ~= key then txt:SetTextColor(unpack(C_INACTIVE)) end end)
        btn:SetScript("OnClick", function() ShowPane(key) end)
        navButtons[key] = btn
        navY = navY - 42
    end

    local verTxt = sidebar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    verTxt:SetPoint("BOTTOMLEFT", sidebar, "BOTTOMLEFT", 16, 14)
    verTxt:SetText("v" .. SacrificeUI.version); verTxt:SetTextColor(0.26, 0.26, 0.28)

    vDivider = mainFrame:CreateTexture(nil, "ARTWORK")
    vDivider:SetWidth(1); vDivider:SetColorTexture(unpack(GetAccentColor()))
    vDivider:SetPoint("TOPLEFT",    mainFrame, "TOPLEFT",    SIDEBAR_W, 0)
    vDivider:SetPoint("BOTTOMLEFT", mainFrame, "BOTTOMLEFT", SIDEBAR_W, BOTTOM_H)

    local content = CreateFrame("Frame", nil, mainFrame)
    content:SetPoint("TOPLEFT",     mainFrame, "TOPLEFT",     SIDEBAR_W + 1, 0)
    content:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", 0, BOTTOM_H)

    -- Decorative ambient gradient in content area (top-right glow)
    local decoA = content:CreateTexture(nil, "BACKGROUND", nil, -6)
    decoA:SetSize(360, FRAME_H)
    decoA:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, 0)
    decoA:SetColorTexture(1, 1, 1)
    decoA:SetGradient("HORIZONTAL",
        CreateColor(0.0, 0.0, 0.0, 0),
        CreateColor(0.05, 0.02, 0.10, 0.30))
    local decoB = content:CreateTexture(nil, "BACKGROUND", nil, -5)
    decoB:SetSize(280, 160)
    decoB:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, 0)
    decoB:SetColorTexture(1, 1, 1)
    decoB:SetGradient("VERTICAL",
        CreateColor(0.06, 0.03, 0.12, 0.25),
        CreateColor(0.0,  0.0,  0.0,  0))

    contentPanes["Global Settings"] = BuildGlobalSettingsPane(content)
    contentPanes["Addons"]          = BuildAddonsPane(content)
    contentPanes["Dungeons"]        = BuildDungeonsPane(content)
    contentPanes["Raids"]           = BuildPlaceholderPane(content, "Raids")
    contentPanes["Settings"]        = BuildSettingsPane(content)

    -- Bottom action bar (content area only, above the window border)
    local bottomBar = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
    bottomBar:SetHeight(BOTTOM_H)
    bottomBar:SetPoint("BOTTOMLEFT",  mainFrame, "BOTTOMLEFT",  SIDEBAR_W + 1, 0)
    bottomBar:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", 0, 0)
    bottomBar:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", tile = false })
    bottomBar:SetBackdropColor(0.05, 0.05, 0.06, 0.98)

    -- Separator line at top of bottom bar
    local bottomSep = bottomBar:CreateTexture(nil, "ARTWORK")
    bottomSep:SetHeight(1)
    bottomSep:SetPoint("TOPLEFT",  bottomBar, "TOPLEFT",  0, 0)
    bottomSep:SetPoint("TOPRIGHT", bottomBar, "TOPRIGHT", 0, 0)
    bottomSep:SetColorTexture(unpack(GetAccentColor()))
    mainFrame.bottomSep = bottomSep

    -- "Close" button in bottom-right of action bar
    doneButton = CreateFrame("Button", nil, bottomBar, "BackdropTemplate")
    doneButton:SetSize(100, 28)
    doneButton:SetPoint("RIGHT", bottomBar, "RIGHT", -12, 0)
    doneButton:SetBackdrop(TipBorder())
    doneButton:SetBackdropColor(0.10, 0.10, 0.13, 0.95)
    doneButton:SetBackdropBorderColor(unpack(GetAccentColor()))
    local doneTxt = doneButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    doneTxt:SetAllPoints(); doneTxt:SetText("Close")
    doneTxt:SetTextColor(unpack(GetAccentColor()))
    doneButton.txt = doneTxt
    doneButton:SetScript("OnClick", function() mainFrame:Hide() end)
    doneButton:SetScript("OnEnter", function()
        local c = GetAccentColor()
        doneButton:SetBackdropColor(c[1] * 0.2, c[2] * 0.1, c[3] * 0.1, 0.95)
        doneButton:SetBackdropBorderColor(unpack(c))
    end)
    doneButton:SetScript("OnLeave", function()
        doneButton:SetBackdropColor(0.10, 0.10, 0.13, 0.95)
        doneButton:SetBackdropBorderColor(unpack(GetAccentColor()))
    end)

    closeButton = CreateFrame("Button", nil, mainFrame, "BackdropTemplate")
    closeButton:SetSize(28, 28)
    closeButton:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -8, -8)
    closeButton:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    closeButton:SetBackdropColor(0.10, 0.10, 0.13, 0.95)
    closeButton:SetBackdropBorderColor(unpack(C_BORDER))
    local xTxt = closeButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    xTxt:SetAllPoints(); xTxt:SetText("×")
    xTxt:SetFont("Fonts\\FRIZQT__.TTF", 16, "")
    xTxt:SetTextColor(unpack(GetAccentColor()))
    closeButton.xText = xTxt
    closeButton:SetScript("OnEnter", function()
        local c = GetAccentColor()
        closeButton:SetBackdropColor(c[1] * 0.2, c[2] * 0.1, c[3] * 0.1, 0.95)
        closeButton:SetBackdropBorderColor(unpack(c))
    end)
    closeButton:SetScript("OnLeave", function()
        closeButton:SetBackdropColor(0.10, 0.10, 0.13, 0.95)
        closeButton:SetBackdropBorderColor(unpack(C_BORDER))
    end)
    closeButton:SetScript("OnClick", function() mainFrame:Hide() end)

    tinsert(UISpecialFrames, "SacrificeUIMainFrame")
    ShowPane("Global Settings")
    mainFrame:Hide()  -- start hidden; ToggleMainWindow will show on first call
    return mainFrame
end

-- ============================================================
-- Public API
-- ============================================================

function SacrificeUI:ToggleMainWindow()
    local f = CreateMainWindow()
    if f:IsShown() then f:Hide()
    else ShowPane(activeNav); f:Show() end
end

function SacrificeUI:CheckAddons()
    if not AllRequiredLoaded() then
        local f = CreateMainWindow()
        ShowPane("Addons"); f:Show()
    end
end

function SacrificeUI:CheckTalentReminders()
    local reminders = SacrificeUIDB and SacrificeUIDB.talentReminders
    if not reminders or #reminders == 0 then return end

    local instanceName, instanceType = GetInstanceInfo()
    if instanceType ~= "party" then return end

    local specIndex = GetSpecialization and GetSpecialization()
    if not specIndex then return end
    local currentSpecID, currentSpecName = GetSpecializationInfo(specIndex)

    local activeConfigID = C_ClassTalents and C_ClassTalents.GetActiveConfigID and C_ClassTalents.GetActiveConfigID()
    local activeLoadout  = ""
    if activeConfigID then
        local info = C_ClassTalents.GetConfigInfo(activeConfigID)
        if info then activeLoadout = info.name or "" end
    end

    for _, rem in ipairs(reminders) do
        local dungeonMatch = rem.dungeon == instanceName
        if dungeonMatch and rem.specID == currentSpecID then
            if rem.loadoutName ~= activeLoadout then
                ShowTalentReminderPopup(rem.loadoutName, instanceName)
                return
            end
        end
    end
end

function SacrificeUI:ApplySettings()
    local db = SacrificeUIDB
    if not db then return end
    if db.showPerformance then CreatePerfOverlay():Show() end
    if db.showStats       then CreateStatsOverlay():Show() end
end

function SacrificeUI:UpdateCombatLogging()
    local db = SacrificeUIDB
    if not LoggingCombat then return end

    local function IsActive()
        if GetCVar then
            local v = GetCVar("CombatLogOn")
            if v ~= nil then return v == "1" end
        end
        local v = LoggingCombat()
        return v ~= nil and v ~= false and v ~= 0
    end

    if not db or not db.logEnabled then
        if IsActive() then
            LoggingCombat(0)
            print("|cFFDC143CSacrificeUI|r Combat logging |cFF888888stopped|r.")
        end
        return
    end

    local inInst, instType = IsInInstance()
    local shouldLog = false
    local activityName = nil

    if db.logEnableAll and inInst then
        shouldLog = true
        if     instType == "party"  then activityName = "Dungeons (M+)"
        elseif instType == "raid"   then activityName = "Raids"
        elseif instType == "pvp"    then activityName = "Battlegrounds"
        elseif instType == "arena"  then activityName = "Arenas"
        else                             activityName = "Instance" end
    elseif db.logDungeons      and inInst and instType == "party"  then
        shouldLog = true; activityName = "Dungeons (M+)"
    elseif db.logRaids         and inInst and instType == "raid"   then
        shouldLog = true; activityName = "Raids"
    elseif db.logBattlegrounds and inInst and instType == "pvp"    then
        shouldLog = true; activityName = "Battlegrounds"
    elseif db.logArenas        and inInst and instType == "arena"  then
        shouldLog = true; activityName = "Arenas"
    end

    if shouldLog == IsActive() then return end
    LoggingCombat(shouldLog and 1 or 0)
    if shouldLog then
        print("|cFFDC143CSacrificeUI|r Combat Log Enabled for |cFF44DD44" .. activityName .. "|r")
    else
        print("|cFFDC143CSacrificeUI|r Combat logging |cFF888888stopped|r.")
    end
end

-- ============================================================
-- Debug helper
-- ============================================================

function SacrificeUI:DebugFrames()
    local GROUPS = {
        { label = "STANCE BAR",  names = { "StanceBarFrame","ShapeShiftBarFrame","PossessBarFrame","MultiCastActionBarFrame","StanceBar" } },
        { label = "BAG BAR",     names = { "ContainerFrameCombinedBags","MainMenuBarBackpackButton","CharacterBag0Slot","CharacterBag1Slot","CharacterBag2Slot","CharacterBag3Slot","BagBarExpandToggle","KeyRingButton","MainMenuBarBagManager","BagsBar" } },
        { label = "MENU BAR",    names = { "MicroMenu","MicroButtonAndBagsBar","CharacterMicroButton","SpellbookMicroButton","TalentMicroButton","AchievementMicroButton","QuestLogMicroButton","GuildMicroButton","PVPMicroButton","LFDMicroButton","CollectionsMicroButton","EJMicroButton","StoreMicroButton","MainMenuMicroButton","HelpMicroButton","WorldMapMicroButton" } },
        { label = "BUFFS",       names = { "BuffFrame","DebuffFrame" } },
    }
    print("|cFFDC143CSacrificeUI Debug|r - Known frame visibility:")
    for _, g in ipairs(GROUPS) do
        local found = {}
        for _, name in ipairs(g.names) do
            local f = _G[name]
            if f and type(f) == "table" and f.IsShown then
                local shown = f:IsShown()
                tinsert(found, name .. "=" .. (shown and "|cFF44DD44shown|r" or "|cFFAAAAAAhidden|r"))
            end
        end
        if #found > 0 then
            print("|cFFFFAA00" .. g.label .. "|r  " .. table.concat(found, "  "))
        else
            print("|cFFFFAA00" .. g.label .. "|r  |cFFFF4444(none found - scanning...)|r")
        end
    end

    -- Scan _G for frames matching "bag" or "stance" patterns - helps find correct names in this WoW version
    print("|cFFDC143CSacrificeUI Debug|r - Scanning for bag/stance frames in _G:")
    local bagMatches, stanceMatches = {}, {}
    for name, val in pairs(_G) do
        if type(name) == "string" and type(val) == "table" and val.IsShown then
            local lower = strlower(name)
            if lower:find("bag") and not lower:find("container") then
                tinsert(bagMatches, name .. "=" .. (val:IsShown() and "|cFF44DD44shown|r" or "|cFFAAAAAAhidden|r"))
            elseif lower:find("stance") or lower:find("shapeshift") then
                tinsert(stanceMatches, name .. "=" .. (val:IsShown() and "|cFF44DD44shown|r" or "|cFFAAAAAAhidden|r"))
            end
        end
    end
    if #bagMatches > 0 then
        print("|cFFFFAA00BAG SCAN|r  " .. table.concat(bagMatches, "  "))
    else
        print("|cFFFFAA00BAG SCAN|r  |cFFFF4444nothing found|r")
    end
    if #stanceMatches > 0 then
        print("|cFFFFAA00STANCE SCAN|r  " .. table.concat(stanceMatches, "  "))
    else
        print("|cFFFFAA00STANCE SCAN|r  |cFFFF4444nothing found|r")
    end
end

-- ============================================================
-- Funny message (random quote, centered on screen)
-- ============================================================

function SacrificeUI:ShowFunnyMessage()
    local quotes = SacrificeUI.Quotes
    if not quotes or #quotes == 0 then return end
    local quote = quotes[math.random(#quotes)]

    if not funnyFrame then
        funnyFrame = CreateFrame("Frame", "SacrificeUIFunnyFrame", UIParent)
        funnyFrame:SetAllPoints(UIParent)
        funnyFrame:SetFrameStrata("TOOLTIP")
        funnyFrame:EnableMouse(false)

        local txt = funnyFrame:CreateFontString(nil, "OVERLAY")
        txt:SetFont("Fonts\\MORPHEUS.TTF", 42, "THICKOUTLINE")
        txt:SetPoint("CENTER", UIParent, "CENTER", 0, 80)
        txt:SetWidth(700)
        txt:SetJustifyH("CENTER")
        txt:SetShadowColor(0, 0, 0, 1)
        txt:SetShadowOffset(3, -3)
        funnyFrame.txt = txt
        funnyFrame:Hide()
    end

    -- Use the current accent color
    local c = GetAccentColor()
    local hex = string.format("|cFF%02X%02X%02X", c[1]*255, c[2]*255, c[3]*255)
    funnyFrame.txt:SetText(hex .. quote .. "|r")
    funnyFrame.txt:SetAlpha(1)
    funnyFrame:Show()

    -- Fade: hold 3 s then fade over 1.5 s
    local elapsed = 0
    funnyFrame:SetScript("OnUpdate", function(self, dt)
        elapsed = elapsed + dt
        if elapsed < 3.0 then
            self.txt:SetAlpha(1)
        elseif elapsed < 4.5 then
            self.txt:SetAlpha(1 - (elapsed - 3.0) / 1.5)
        else
            self.txt:SetAlpha(0)
            self:Hide()
            self:SetScript("OnUpdate", nil)
        end
    end)
end
