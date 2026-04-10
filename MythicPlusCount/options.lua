-- MythicPlusCount - Options Panel
-- Modern tabbed settings UI with dark theme, configurable nameplate
-- positioning, lock/unlock, color picker, and all addon settings.
local ADDON_NAME, NS = ...
local MPC = NS.MPC

local Options = {}
MPC.Options = Options

local optionsFrame = nil
local activeTab = nil
local tabFrames = {}

-- Color constants for the modern dark UI
local C = {
    bg         = { 0.08, 0.08, 0.10, 0.95 },
    bgCard     = { 0.12, 0.12, 0.14, 1.0 },
    border     = { 0.25, 0.25, 0.30, 1.0 },
    accent     = { 0.30, 0.70, 1.00, 1.0 },  -- blue accent
    accentDim  = { 0.20, 0.50, 0.80, 0.6 },
    textNormal = { 0.85, 0.85, 0.85, 1.0 },
    textBright = { 1.00, 1.00, 1.00, 1.0 },
    textDim    = { 0.55, 0.55, 0.60, 1.0 },
    green      = { 0.30, 0.85, 0.40, 1.0 },
    red        = { 0.90, 0.35, 0.35, 1.0 },
    yellow     = { 1.00, 0.82, 0.00, 1.0 },
    tabBg      = { 0.10, 0.10, 0.12, 1.0 },
    tabActive  = { 0.18, 0.18, 0.22, 1.0 },
    tabHover   = { 0.14, 0.14, 0.18, 1.0 },
}

function Options:Init()
    -- Nothing needed at init; panel is created on demand
end

function Options:Toggle()
    if optionsFrame and optionsFrame:IsShown() then
        optionsFrame:Hide()
    else
        self:Show()
    end
end

function Options:Show()
    if not optionsFrame then
        self:CreatePanel()
    end
    optionsFrame:Show()
end

local function CreateCard(parent, width, height)
    local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    card:SetSize(width, height)
    card:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    card:SetBackdropColor(unpack(C.bgCard))
    card:SetBackdropBorderColor(unpack(C.border))
    return card
end

local function CreateSectionHeader(parent, text, xOffset, yOffset)
    local header = parent:CreateFontString(nil, "OVERLAY")
    header:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    header:SetTextColor(unpack(C.accent))
    header:SetPoint("TOPLEFT", xOffset, yOffset)
    header:SetText(text)

    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1)
    line:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -3)
    line:SetPoint("RIGHT", parent, "RIGHT", -12, 0)
    line:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.3)

    return header
end

local function CreateCheckbox(parent, label, x, y, getter, setter)
    local cb = CreateFrame("CheckButton", nil, parent)
    cb:SetSize(18, 18)
    cb:SetPoint("TOPLEFT", x, y)
    cb:SetNormalTexture("Interface\\Buttons\\WHITE8X8")
    cb:GetNormalTexture():SetVertexColor(0.15, 0.15, 0.18, 1)
    cb:SetHighlightTexture("Interface\\Buttons\\WHITE8X8")
    cb:GetHighlightTexture():SetVertexColor(0.3, 0.6, 1.0, 0.2)

    local check = cb:CreateTexture(nil, "OVERLAY")
    check:SetSize(12, 12)
    check:SetPoint("CENTER")
    check:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 1)
    cb.checkTex = check

    local border = cb:CreateTexture(nil, "OVERLAY", nil, 1)
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)
    border:SetColorTexture(0, 0, 0, 0)
    local borderFrame = CreateFrame("Frame", nil, cb, "BackdropTemplate")
    borderFrame:SetAllPoints()
    borderFrame:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    borderFrame:SetBackdropBorderColor(unpack(C.border))

    local text = cb:CreateFontString(nil, "OVERLAY")
    text:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    text:SetPoint("LEFT", cb, "RIGHT", 6, 0)
    text:SetTextColor(unpack(C.textNormal))
    text:SetText(label)
    cb.label = text

    local function UpdateVisual()
        if cb:GetChecked() then
            check:Show()
            borderFrame:SetBackdropBorderColor(unpack(C.accent))
        else
            check:Hide()
            borderFrame:SetBackdropBorderColor(unpack(C.border))
        end
    end

    cb:SetChecked(getter())
    UpdateVisual()

    cb:SetScript("OnClick", function(self)
        setter(self:GetChecked())
        UpdateVisual()
    end)

    return cb, text
end

local function CreateSlider(parent, label, x, y, minVal, maxVal, step, getter, setter)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(260, 36)
    frame:SetPoint("TOPLEFT", x, y)

    local lbl = frame:CreateFontString(nil, "OVERLAY")
    lbl:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    lbl:SetPoint("TOPLEFT", 0, 0)
    lbl:SetTextColor(unpack(C.textNormal))
    lbl:SetText(label)

    local valText = frame:CreateFontString(nil, "OVERLAY")
    valText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    valText:SetPoint("TOPRIGHT", 0, 0)
    valText:SetTextColor(unpack(C.accent))

    local slider = CreateFrame("Slider", nil, frame, "MinimalSliderTemplate")
    if not slider.SetMinMaxValues then
        slider = CreateFrame("Slider", nil, frame)
        slider:SetObeyStepOnDrag(true)
    end
    slider:SetSize(260, 14)
    slider:SetPoint("TOPLEFT", 0, -16)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    slider:SetValue(getter())

    local trackBg = slider:CreateTexture(nil, "BACKGROUND")
    trackBg:SetHeight(4)
    trackBg:SetPoint("LEFT", 0, 0)
    trackBg:SetPoint("RIGHT", 0, 0)
    trackBg:SetColorTexture(0.2, 0.2, 0.24, 1)

    local thumb = slider:CreateTexture(nil, "OVERLAY")
    thumb:SetSize(12, 12)
    thumb:SetColorTexture(unpack(C.accent))
    slider:SetThumbTexture(thumb)

    valText:SetText(tostring(getter()))

    slider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value / step + 0.5) * step
        setter(value)
        valText:SetText(tostring(value))
    end)

    return frame
end

local function CreateDropdown(parent, label, x, y, options, getter, setter)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(260, 36)
    frame:SetPoint("TOPLEFT", x, y)

    local lbl = frame:CreateFontString(nil, "OVERLAY")
    lbl:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    lbl:SetPoint("TOPLEFT", 0, 0)
    lbl:SetTextColor(unpack(C.textNormal))
    lbl:SetText(label)

    local btn = CreateFrame("Button", nil, frame, "BackdropTemplate")
    btn:SetSize(180, 22)
    btn:SetPoint("TOPLEFT", 0, -14)
    btn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    btn:SetBackdropColor(0.15, 0.15, 0.18, 1)
    btn:SetBackdropBorderColor(unpack(C.border))

    local btnText = btn:CreateFontString(nil, "OVERLAY")
    btnText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    btnText:SetPoint("LEFT", 8, 0)
    btnText:SetTextColor(unpack(C.textBright))
    btnText:SetText(getter())

    local arrow = btn:CreateFontString(nil, "OVERLAY")
    arrow:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    arrow:SetPoint("RIGHT", -8, 0)
    arrow:SetTextColor(unpack(C.textDim))
    arrow:SetText("v")

    local MAX_VISIBLE = 10
    local ITEM_HEIGHT = 22
    local totalHeight = #options * ITEM_HEIGHT + 4
    local menuHeight = math.min(totalHeight, MAX_VISIBLE * ITEM_HEIGHT + 4)
    local needsScroll = #options > MAX_VISIBLE

    local menu = CreateFrame("Frame", nil, btn, "BackdropTemplate")
    menu:SetPoint("TOPLEFT", btn, "BOTTOMLEFT", 0, -2)
    menu:SetSize(180, menuHeight)
    menu:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    menu:SetBackdropColor(0.10, 0.10, 0.12, 0.98)
    menu:SetBackdropBorderColor(unpack(C.border))
    menu:SetFrameStrata("TOOLTIP")
    menu:Hide()

    local scrollFrame, content
    if needsScroll then
        scrollFrame = CreateFrame("ScrollFrame", nil, menu)
        scrollFrame:SetPoint("TOPLEFT", 0, -2)
        scrollFrame:SetPoint("BOTTOMRIGHT", -2, 2)
        scrollFrame:EnableMouseWheel(true)
        scrollFrame:SetScript("OnMouseWheel", function(self, delta)
            local cur = self:GetVerticalScroll()
            local range = self:GetVerticalScrollRange()
            self:SetVerticalScroll(math.max(0, math.min(range, cur - delta * ITEM_HEIGHT * 2)))
        end)
        content = CreateFrame("Frame", nil, scrollFrame)
        content:SetSize(176, totalHeight)
        scrollFrame:SetScrollChild(content)
    else
        content = menu
    end

    for i, opt in ipairs(options) do
        local item = CreateFrame("Button", nil, content)
        item:SetSize(needsScroll and 172 or 176, 20)
        item:SetPoint("TOPLEFT", 2, -(i - 1) * ITEM_HEIGHT - 2)

        local itemBg = item:CreateTexture(nil, "BACKGROUND")
        itemBg:SetAllPoints()
        itemBg:SetColorTexture(0, 0, 0, 0)

        local itemText = item:CreateFontString(nil, "OVERLAY")
        itemText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        itemText:SetPoint("LEFT", 8, 0)
        itemText:SetTextColor(unpack(C.textNormal))
        itemText:SetText(opt)

        item:SetScript("OnEnter", function()
            itemBg:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.2)
        end)
        item:SetScript("OnLeave", function()
            itemBg:SetColorTexture(0, 0, 0, 0)
        end)
        item:SetScript("OnClick", function()
            setter(opt)
            btnText:SetText(opt)
            menu:Hide()
        end)
    end

    btn:SetScript("OnClick", function()
        if menu:IsShown() then
            menu:Hide()
        else
            menu:Show()
        end
    end)

    menu:SetScript("OnShow", function()
        menu:SetPropagateKeyboardInput(false)
    end)

    return frame, btnText
end

local function CreateActionButton(parent, label, x, y, width, onClick, colorKey)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(width or 140, 24)
    btn:SetPoint("TOPLEFT", x, y)
    btn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })

    local clr = colorKey or C.accent
    btn:SetBackdropColor(clr[1] * 0.4, clr[2] * 0.4, clr[3] * 0.4, 0.8)
    btn:SetBackdropBorderColor(clr[1], clr[2], clr[3], 0.6)

    local text = btn:CreateFontString(nil, "OVERLAY")
    text:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    text:SetPoint("CENTER")
    text:SetTextColor(unpack(C.textBright))
    text:SetText(label)
    btn.label = text

    btn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(clr[1] * 0.6, clr[2] * 0.6, clr[3] * 0.6, 1)
    end)
    btn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(clr[1] * 0.4, clr[2] * 0.4, clr[3] * 0.4, 0.8)
    end)
    btn:SetScript("OnClick", onClick)

    return btn
end

function Options:CreatePanel()
    local db = MPC.db

    optionsFrame = CreateFrame("Frame", "MythicPlusCountOptions", UIParent, "BackdropTemplate")
    optionsFrame:SetSize(520, 540)
    optionsFrame:SetPoint("CENTER")
    optionsFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    optionsFrame:SetBackdropColor(unpack(C.bg))
    optionsFrame:SetBackdropBorderColor(unpack(C.border))
    optionsFrame:SetMovable(true)
    optionsFrame:EnableMouse(true)
    optionsFrame:SetClampedToScreen(true)
    optionsFrame:RegisterForDrag("LeftButton")
    optionsFrame:SetScript("OnDragStart", optionsFrame.StartMoving)
    optionsFrame:SetScript("OnDragStop", optionsFrame.StopMovingOrSizing)
    optionsFrame:SetFrameStrata("DIALOG")

    local titleBar = CreateFrame("Frame", nil, optionsFrame, "BackdropTemplate")
    titleBar:SetHeight(36)
    titleBar:SetPoint("TOPLEFT", 0, 0)
    titleBar:SetPoint("TOPRIGHT", 0, 0)
    titleBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
    })
    titleBar:SetBackdropColor(0.06, 0.06, 0.08, 1)

    local title = titleBar:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
    title:SetPoint("LEFT", 14, 0)
    title:SetTextColor(unpack(C.textBright))
    title:SetText("MythicPlusCount")

    local credit = titleBar:CreateFontString(nil, "OVERLAY")
    credit:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    credit:SetPoint("LEFT", title, "RIGHT", 8, 0)
    credit:SetText("|cFF666666by |r|cFFA330C9Noobheartx|r")

    local closeBtn = CreateFrame("Button", nil, titleBar)
    closeBtn:SetSize(36, 36)
    closeBtn:SetPoint("TOPRIGHT")
    local closeText = closeBtn:CreateFontString(nil, "OVERLAY")
    closeText:SetFont("Fonts\\FRIZQT__.TTF", 16, "")
    closeText:SetPoint("CENTER", 0, 0)
    closeText:SetTextColor(unpack(C.textDim))
    closeText:SetText("x")
    closeBtn:SetScript("OnEnter", function() closeText:SetTextColor(unpack(C.red)) end)
    closeBtn:SetScript("OnLeave", function() closeText:SetTextColor(unpack(C.textDim)) end)
    closeBtn:SetScript("OnClick", function() optionsFrame:Hide() end)

    local sidebar = CreateFrame("Frame", nil, optionsFrame, "BackdropTemplate")
    sidebar:SetWidth(110)
    sidebar:SetPoint("TOPLEFT", 0, -36)
    sidebar:SetPoint("BOTTOMLEFT", 0, 0)
    sidebar:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    sidebar:SetBackdropColor(unpack(C.tabBg))

    -- A slider inside a scaled frame creates a feedback loop, so we
    -- use discrete +/- buttons instead: each click = +/-10% scale
    local currentScale = db.optionsPanelScale or 100

    local scaleLabel = sidebar:CreateFontString(nil, "OVERLAY")
    scaleLabel:SetFont("Fonts\\FRIZQT__.TTF", 8, "")
    scaleLabel:SetPoint("BOTTOMLEFT", 8, 34)
    scaleLabel:SetTextColor(unpack(C.textDim))
    scaleLabel:SetText("Panel Scale")

    local scaleValText = sidebar:CreateFontString(nil, "OVERLAY")
    scaleValText:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    scaleValText:SetPoint("BOTTOM", sidebar, "BOTTOM", 0, 18)
    scaleValText:SetTextColor(unpack(C.accent))
    scaleValText:SetText(currentScale .. "%")

    local function ApplyScale(newVal)
        newVal = math.max(60, math.min(150, newVal))
        db.optionsPanelScale = newVal
        scaleValText:SetText(newVal .. "%")
        optionsFrame:SetScale(newVal / 100)
        optionsFrame:ClearAllPoints()
        optionsFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end

    local function MakeScaleBtn(label, xOffset, delta)
        local btn = CreateFrame("Button", nil, sidebar, "BackdropTemplate")
        btn:SetSize(24, 16)
        btn:SetPoint("BOTTOM", sidebar, "BOTTOM", xOffset, 14)
        btn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        btn:SetBackdropColor(0.15, 0.15, 0.18, 1)
        btn:SetBackdropBorderColor(unpack(C.border))
        local txt = btn:CreateFontString(nil, "OVERLAY")
        txt:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        txt:SetPoint("CENTER", 0, 1)
        txt:SetTextColor(unpack(C.textBright))
        txt:SetText(label)
        btn:SetScript("OnClick", function()
            ApplyScale((db.optionsPanelScale or 100) + delta)
        end)
        btn:SetScript("OnEnter", function(self)
            self:SetBackdropColor(C.accent[1]*0.3, C.accent[2]*0.3, C.accent[3]*0.3, 1)
        end)
        btn:SetScript("OnLeave", function(self)
            self:SetBackdropColor(0.15, 0.15, 0.18, 1)
        end)
        return btn
    end

    MakeScaleBtn("-", -32, -10)
    MakeScaleBtn("+",  32,  10)

    optionsFrame:SetScale(currentScale / 100)

    local contentArea = CreateFrame("Frame", nil, optionsFrame)
    contentArea:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 0, 0)
    contentArea:SetPoint("BOTTOMRIGHT", 0, 0)

    local TAB_DEFS = {
        { key = "general",    label = "General" },
        { key = "tooltip",    label = "Tooltip" },
        { key = "nameplates", label = "Nameplates" },
        { key = "bars",       label = "UI" },
        { key = "frames",     label = "Layout" },
        { key = "extras",     label = "Extras" },
        { key = "autoqueue",  label = "Auto Queue",  visCheck = function() return MPC.Extras:IsEnabled("autoqueue") end },
        { key = "debug",      label = "Debug",        visCheck = function() return db.developerMode end },
    }

    local tabButtons = {}

    local function SelectTab(key)
        activeTab = key
        for _, tf in pairs(tabFrames) do tf:Hide() end
        if tabFrames[key] then tabFrames[key]:Show() end
        for _, tb in ipairs(tabButtons) do
            if tb.key == key then
                tb:SetBackdropColor(unpack(C.tabActive))
                tb.indicator:Show()
                tb.label:SetTextColor(unpack(C.textBright))
            else
                tb:SetBackdropColor(0, 0, 0, 0)
                tb.indicator:Hide()
                tb.label:SetTextColor(unpack(C.textDim))
            end
        end
    end

    for _, def in ipairs(TAB_DEFS) do
        local tb = CreateFrame("Button", nil, sidebar, "BackdropTemplate")
        tb:SetSize(110, 30)
        tb:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
        tb:SetBackdropColor(0, 0, 0, 0)
        tb.key = def.key
        tb.visCheck = def.visCheck  -- optional visibility check function

        local indicator = tb:CreateTexture(nil, "OVERLAY")
        indicator:SetSize(3, 22)
        indicator:SetPoint("LEFT", 0, 0)
        indicator:SetColorTexture(unpack(C.accent))
        indicator:Hide()
        tb.indicator = indicator

        local label = tb:CreateFontString(nil, "OVERLAY")
        label:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        label:SetPoint("LEFT", 14, 0)
        label:SetTextColor(unpack(C.textDim))
        label:SetText(def.label)
        tb.label = label

        tb:SetScript("OnEnter", function(self)
            if self.key ~= activeTab then
                self:SetBackdropColor(unpack(C.tabHover))
            end
        end)
        tb:SetScript("OnLeave", function(self)
            if self.key ~= activeTab then
                self:SetBackdropColor(0, 0, 0, 0)
            end
        end)
        tb:SetScript("OnClick", function() SelectTab(def.key) end)

        tabButtons[#tabButtons + 1] = tb
    end

    local function RefreshTabVisibility()
        local yPos = 0
        for _, tb in ipairs(tabButtons) do
            local visible = true
            if tb.visCheck then
                visible = tb.visCheck()
            end
            if visible then
                tb:ClearAllPoints()
                tb:SetPoint("TOPLEFT", 0, -yPos)
                tb:Show()
                yPos = yPos + 30
            else
                tb:Hide()
                -- If this hidden tab was active, switch to general
                if activeTab == tb.key then
                    SelectTab("general")
                end
            end
        end
    end
    Options.RefreshTabVisibility = RefreshTabVisibility
    RefreshTabVisibility()

    local function MakeTabFrame(key)
        local f = CreateFrame("ScrollFrame", nil, contentArea)
        f:SetPoint("TOPLEFT", 4, -4)
        f:SetPoint("BOTTOMRIGHT", -10, 4)

        local content = CreateFrame("Frame", nil, f)
        content:SetWidth(380)
        content:SetHeight(800)
        f:SetScrollChild(content)

        local trackWidth = 4
        local track = CreateFrame("Frame", nil, f, "BackdropTemplate")
        track:SetWidth(trackWidth)
        track:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
        track:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
        track:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
        track:SetBackdropColor(0.15, 0.15, 0.18, 0.5)

        local thumb = CreateFrame("Frame", nil, track, "BackdropTemplate")
        thumb:SetWidth(trackWidth)
        thumb:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
        thumb:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 0.5)
        thumb:SetHeight(40)
        thumb:SetPoint("TOP", track, "TOP", 0, 0)

        local function UpdateThumb()
            local scrollRange = f:GetVerticalScrollRange()
            if scrollRange <= 0 then
                thumb:Hide()
                track:Hide()
                return
            end
            track:Show()
            thumb:Show()
            local trackH = track:GetHeight()
            local thumbH = math.max(20, trackH * (trackH / (trackH + scrollRange)))
            thumb:SetHeight(thumbH)
            local scrollPos = f:GetVerticalScroll()
            local ratio = scrollPos / scrollRange
            local travel = trackH - thumbH
            thumb:ClearAllPoints()
            thumb:SetPoint("TOP", track, "TOP", 0, -(ratio * travel))
        end

        f:SetScript("OnScrollRangeChanged", function() UpdateThumb() end)
        f:SetScript("OnVerticalScroll", function() UpdateThumb() end)

        f:EnableMouseWheel(true)
        f:SetScript("OnMouseWheel", function(self, delta)
            local current = self:GetVerticalScroll()
            local range = self:GetVerticalScrollRange()
            local step = 30
            local new = math.max(0, math.min(range, current - delta * step))
            self:SetVerticalScroll(new)
        end)

        f:Hide()
        tabFrames[key] = f
        return content
    end

    local gen = MakeTabFrame("general")
    do
        local y = -10
        CreateSectionHeader(gen, "MythicPlusCount", 12, y)
        y = y - 28

        local info = gen:CreateFontString(nil, "OVERLAY")
        info:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        info:SetPoint("TOPLEFT", 12, y)
        info:SetWidth(360)
        info:SetJustifyH("LEFT")
        info:SetTextColor(unpack(C.textNormal))
        info:SetText("Enemy forces tracker for Mythic+ dungeons.\nShows per-mob %, pull totals, and predicted completion.")
        y = y - 40

        CreateCheckbox(gen, "Only show in Mythic+ dungeons", 16, y,
            function() return db.nameplates.onlyInMythicPlus end,
            function(v)
                db.nameplates.onlyInMythicPlus = v
                MPC.Nameplates:RefreshAll()
                MPC.ProgressBar:Update()
                MPC.PullTracker:UpdateDisplay()
            end)
        y = y - 32

        CreateSectionHeader(gen, "Slash Commands", 12, y)
        y = y - 28

        local cmds = {
            { "/mpc", "Open settings panel" },
            { "/mpc teach", "Teach a mob (target first)" },
            { "/mpc mobs", "List known/unknown mobs" },
            { "/mpc lock / unlock", "Lock or unlock frames" },
            { "/mpc reset", "Reset frame positions" },
        }
        for _, cmd in ipairs(cmds) do
            local cmdLine = gen:CreateFontString(nil, "OVERLAY")
            cmdLine:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
            cmdLine:SetPoint("TOPLEFT", 16, y)
            cmdLine:SetTextColor(unpack(C.textNormal))
            local r, g, b = unpack(C.accent)
            cmdLine:SetText(string.format("|cFF%02x%02x%02x%s|r  %s",
                r * 255, g * 255, b * 255, cmd[1], cmd[2]))
            y = y - 18
        end
        y = y - 14

        CreateSectionHeader(gen, "Season Data", 12, y)
        y = y - 24

        local dungeonCount = 0
        local mobCount = 0
        for _, dungeon in pairs(MPC.Data.dungeons) do
            dungeonCount = dungeonCount + 1
            for _ in pairs(dungeon.mobs) do mobCount = mobCount + 1 end
        end

        local dataInfo = gen:CreateFontString(nil, "OVERLAY")
        dataInfo:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        dataInfo:SetPoint("TOPLEFT", 16, y)
        dataInfo:SetWidth(360)
        dataInfo:SetJustifyH("LEFT")
        dataInfo:SetTextColor(unpack(C.textNormal))
        dataInfo:SetText(string.format("Loaded |cFF%02x%02x%02x%d|r dungeons with |cFF%02x%02x%02x%d|r mob entries.",
            C.accent[1]*255, C.accent[2]*255, C.accent[3]*255, dungeonCount,
            C.accent[1]*255, C.accent[2]*255, C.accent[3]*255, mobCount))
        y = y - 22

        for mapID, dungeon in pairs(MPC.Data.dungeons) do
            local dLine = gen:CreateFontString(nil, "OVERLAY")
            dLine:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
            dLine:SetPoint("TOPLEFT", 24, y)
            dLine:SetTextColor(unpack(C.textDim))

            local mCount = 0
            for _ in pairs(dungeon.mobs) do mCount = mCount + 1 end
            dLine:SetText(string.format("%s  (ID: %d, Forces: %d, Mobs: %d)",
                dungeon.name, mapID, dungeon.totalForces, mCount))
            y = y - 16
        end

        gen:SetHeight(math.abs(y) + 20)
    end

    local tt = MakeTabFrame("tooltip")
    do
        local y = -10
        CreateSectionHeader(tt, "Tooltip Settings", 12, y)
        y = y - 28

        -- Preview (defined first so controls can call UpdatePreview)
        local previewY = y  -- will position preview after controls
        local preview = tt:CreateFontString(nil, "OVERLAY")
        preview:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
        preview:SetTextColor(unpack(C.textNormal))

        local function UpdatePreview()
            if not db.tooltip.enabled then
                preview:SetText("|cFF666666(disabled)|r")
                return
            end
            local parts = {}
            if db.tooltip.showCount then parts[#parts + 1] = "6" end
            if db.tooltip.showPercent then
                local pct = string.format("%." .. db.tooltip.decimals .. "f%%", 2.3076923077)
                if db.tooltip.showCount then
                    parts[#parts + 1] = "(" .. pct .. ")"
                else
                    parts[#parts + 1] = pct
                end
            end
            preview:SetText("|cFF33FF99Mythic+ Forces:|r " .. table.concat(parts, " "))
        end

        CreateCheckbox(tt, "Enable forces on tooltip", 16, y,
            function() return db.tooltip.enabled end,
            function(v) db.tooltip.enabled = v; UpdatePreview() end)
        y = y - 28

        CreateCheckbox(tt, "Show force count (e.g. 6)", 16, y,
            function() return db.tooltip.showCount end,
            function(v) db.tooltip.showCount = v; UpdatePreview() end)
        y = y - 28

        CreateCheckbox(tt, "Show force percent (e.g. 2.31%)", 16, y,
            function() return db.tooltip.showPercent end,
            function(v) db.tooltip.showPercent = v; UpdatePreview() end)
        y = y - 32

        CreateSlider(tt, "Decimal Places", 16, y, 0, 4, 1,
            function() return db.tooltip.decimals end,
            function(v) db.tooltip.decimals = v; UpdatePreview() end)
        y = y - 50

        CreateSectionHeader(tt, "Preview", 12, y)
        y = y - 28
        preview:SetPoint("TOPLEFT", 16, y)

        UpdatePreview()
        tabFrames["tooltip"]:SetScript("OnShow", function() UpdatePreview() end)

        tt:SetHeight(math.abs(y) + 40)
    end

    local np = MakeTabFrame("nameplates")
    do
        local y = -10
        CreateSectionHeader(np, "Nameplate Display", 12, y)
        y = y - 28

        CreateCheckbox(np, "Enable forces on nameplates", 16, y,
            function() return db.nameplates.enabled end,
            function(v)
                db.nameplates.enabled = v
                MPC.Nameplates:RefreshAll()
            end)
        y = y - 28

        CreateCheckbox(np, "Show force count", 16, y,
            function() return db.nameplates.showCount end,
            function(v)
                db.nameplates.showCount = v
                MPC.Nameplates:RefreshAll()
            end)
        y = y - 28

        CreateCheckbox(np, "Show force percent", 16, y,
            function() return db.nameplates.showPercent end,
            function(v)
                db.nameplates.showPercent = v
                MPC.Nameplates:RefreshAll()
            end)
        y = y - 28

        y = y - 8

        CreateSectionHeader(np, "Nameplate Provider", 12, y)
        y = y - 28

        CreateDropdown(np, "Provider", 16, y,
            { "auto", "blizzard", "plater", "elvui", "platynator", "ryoui", "threatplates" },
            function() return db.nameplates.provider end,
            function(v)
                db.nameplates.provider = v
                MPC.Nameplates:DetectAdapter()
            end)
        y = y - 48

        local adapterNote = np:CreateFontString(nil, "OVERLAY")
        adapterNote:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
        adapterNote:SetPoint("TOPLEFT", 16, y)
        adapterNote:SetWidth(360)
        adapterNote:SetJustifyH("LEFT")
        adapterNote:SetTextColor(unpack(C.textDim))
        adapterNote:SetText("\"auto\" detects Plater/ElvUI/Platynator/RyoUI/ThreatPlates and falls back to Blizzard.\nActive adapter: " .. MPC.Nameplates:GetActiveAdapterName())
        y = y - 36

        CreateSectionHeader(np, "Text Position (click to set anchor)", 12, y)
        y = y - 24

        local previewContainer = CreateFrame("Frame", nil, np)
        previewContainer:SetSize(370, 70)
        previewContainer:SetPoint("TOPLEFT", 16, y)

        local mockBar = CreateFrame("Frame", nil, previewContainer, "BackdropTemplate")
        mockBar:SetSize(140, 14)
        mockBar:SetPoint("CENTER", previewContainer, "CENTER", 0, -4)
        mockBar:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        mockBar:SetBackdropColor(0.8, 0.15, 0.15, 0.8)
        mockBar:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

        local mockName = previewContainer:CreateFontString(nil, "OVERLAY")
        mockName:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        mockName:SetPoint("BOTTOM", mockBar, "TOP", 0, 3)
        mockName:SetTextColor(0.9, 0.2, 0.2, 1)
        mockName:SetText("Venture Co. Patron")

        local mockForces = previewContainer:CreateFontString(nil, "OVERLAY")
        pcall(mockForces.SetFont, mockForces, MPC.Nameplates:GetFont(), db.nameplates.fontSize or 9, "OUTLINE")
        local fc = db.nameplates.fontColor
        mockForces:SetTextColor(fc.r, fc.g, fc.b, fc.a)
        mockForces:SetText("3 | 0.51%")

        local PREVIEW_ANCHORS = {
            ["TOP"]         = { point = "BOTTOM",      relPoint = "TOP",         xMul = 0,  yMul = 1  },
            ["BOTTOM"]      = { point = "TOP",         relPoint = "BOTTOM",      xMul = 0,  yMul = -1 },
            ["LEFT"]        = { point = "RIGHT",       relPoint = "LEFT",        xMul = -1, yMul = 0  },
            ["RIGHT"]       = { point = "LEFT",        relPoint = "RIGHT",       xMul = 1,  yMul = 0  },
            ["TOPLEFT"]     = { point = "BOTTOMRIGHT", relPoint = "TOPLEFT",     xMul = -1, yMul = 1  },
            ["TOPRIGHT"]    = { point = "BOTTOMLEFT",  relPoint = "TOPRIGHT",    xMul = 1,  yMul = 1  },
            ["BOTTOMLEFT"]  = { point = "TOPRIGHT",    relPoint = "BOTTOMLEFT",  xMul = -1, yMul = -1 },
            ["BOTTOMRIGHT"] = { point = "TOPLEFT",     relPoint = "BOTTOMRIGHT", xMul = 1,  yMul = -1 },
            ["CENTER"]      = { point = "CENTER",      relPoint = "CENTER",      xMul = 0,  yMul = 0  },
        }

        local function UpdateMockPosition()
            mockForces:ClearAllPoints()
            local key = db.nameplates.anchor or "BOTTOM"
            local a = PREVIEW_ANCHORS[key] or PREVIEW_ANCHORS["BOTTOM"]
            local ox = (db.nameplates.offsetX or 0) + a.xMul * 2
            local oy = (db.nameplates.offsetY or 2) + a.yMul * 2
            mockForces:SetPoint(a.point, mockBar, a.relPoint, ox, oy)

            pcall(mockForces.SetFont, mockForces, MPC.Nameplates:GetFont(), db.nameplates.fontSize or 9, "OUTLINE")
            local c = db.nameplates.fontColor
            mockForces:SetTextColor(c.r, c.g, c.b, c.a)

            if db.nameplates.showCount and db.nameplates.showPercent then
                mockForces:SetText("3 | 0.51%")
            elseif db.nameplates.showCount then
                mockForces:SetText("3")
            else
                mockForces:SetText("0.51%")
            end
        end

        local POSITIONS = {
            { key = "TOPLEFT",     col = 1, row = 1, label = "TL" },
            { key = "TOP",         col = 2, row = 1, label = "T"  },
            { key = "TOPRIGHT",    col = 3, row = 1, label = "TR" },
            { key = "LEFT",        col = 1, row = 2, label = "L"  },
            { key = "CENTER",      col = 2, row = 2, label = "C"  },
            { key = "RIGHT",       col = 3, row = 2, label = "R"  },
            { key = "BOTTOMLEFT",  col = 1, row = 3, label = "BL" },
            { key = "BOTTOM",      col = 2, row = 3, label = "B"  },
            { key = "BOTTOMRIGHT", col = 3, row = 3, label = "BR" },
        }

        y = y - 76  -- space past the preview container

        local gridLabel = np:CreateFontString(nil, "OVERLAY")
        gridLabel:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
        gridLabel:SetPoint("TOPLEFT", 16, y)
        gridLabel:SetTextColor(unpack(C.textDim))
        gridLabel:SetText("Anchor position:")
        y = y - 16

        local anchorButtons = {}
        local gridStartX = 16
        local gridStartY = y

        for _, pos in ipairs(POSITIONS) do
            local btn = CreateFrame("Button", nil, np, "BackdropTemplate")
            btn:SetSize(30, 20)
            btn:SetPoint("TOPLEFT", gridStartX + (pos.col - 1) * 32, gridStartY - (pos.row - 1) * 22)
            btn:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8X8",
                edgeFile = "Interface\\Buttons\\WHITE8X8",
                edgeSize = 1,
            })
            btn:SetBackdropBorderColor(unpack(C.border))

            local isActive = (db.nameplates.anchor == pos.key)
            if isActive then
                btn:SetBackdropColor(C.accent[1] * 0.5, C.accent[2] * 0.5, C.accent[3] * 0.5, 1)
            else
                btn:SetBackdropColor(0.15, 0.15, 0.18, 1)
            end

            local lbl = btn:CreateFontString(nil, "OVERLAY")
            lbl:SetFont("Fonts\\FRIZQT__.TTF", 8, "")
            lbl:SetPoint("CENTER")
            lbl:SetTextColor(unpack(isActive and C.textBright or C.textDim))
            lbl:SetText(pos.label)
            btn.lbl = lbl
            btn.key = pos.key

            btn:SetScript("OnEnter", function(self)
                if db.nameplates.anchor ~= self.key then
                    self:SetBackdropColor(C.accent[1] * 0.3, C.accent[2] * 0.3, C.accent[3] * 0.3, 1)
                end
            end)
            btn:SetScript("OnLeave", function(self)
                if db.nameplates.anchor ~= self.key then
                    self:SetBackdropColor(0.15, 0.15, 0.18, 1)
                end
            end)
            btn:SetScript("OnClick", function(self)
                db.nameplates.anchor = self.key
                for _, b in ipairs(anchorButtons) do
                    local active = (db.nameplates.anchor == b.key)
                    if active then
                        b:SetBackdropColor(C.accent[1] * 0.5, C.accent[2] * 0.5, C.accent[3] * 0.5, 1)
                        b.lbl:SetTextColor(unpack(C.textBright))
                    else
                        b:SetBackdropColor(0.15, 0.15, 0.18, 1)
                        b.lbl:SetTextColor(unpack(C.textDim))
                    end
                end
                UpdateMockPosition()
                MPC.Nameplates:RefreshAll()
            end)

            anchorButtons[#anchorButtons + 1] = btn
        end

        UpdateMockPosition()
        y = gridStartY - (3 * 22) - 10  -- past the 3 rows of grid buttons

        CreateSlider(np, "Horizontal Offset", 16, y, -200, 200, 1,
            function() return db.nameplates.offsetX end,
            function(v)
                db.nameplates.offsetX = v
                UpdateMockPosition()
                MPC.Nameplates:RefreshAll()
            end)
        y = y - 44

        CreateSlider(np, "Vertical Offset", 16, y, -200, 200, 1,
            function() return db.nameplates.offsetY end,
            function(v)
                db.nameplates.offsetY = v
                UpdateMockPosition()
                MPC.Nameplates:RefreshAll()
            end)
        y = y - 50

        CreateSectionHeader(np, "Text Appearance", 12, y)
        y = y - 28

        CreateSlider(np, "Font Size", 16, y, 6, 18, 1,
            function() return db.nameplates.fontSize end,
            function(v)
                db.nameplates.fontSize = v
                UpdateMockPosition()
                MPC.Nameplates:RefreshAll()
            end)
        y = y - 44

        -- Font dropdown — shows fonts in their own typeface when expanded
        local fontOptions = {}
        for _, f in ipairs(MPC.Nameplates.FONTS) do
            fontOptions[#fontOptions + 1] = f.label
        end
        CreateDropdown(np, "Font", 16, y, fontOptions,
            function() return db.nameplates.font or "Friz Quadrata TT" end,
            function(v)
                db.nameplates.font = v
                local ok = pcall(mockForces.SetFont, mockForces, MPC.Nameplates:GetFont(), db.nameplates.fontSize or 9, "OUTLINE")
                if not ok then mockForces:SetFont("Fonts\\FRIZQT__.TTF", db.nameplates.fontSize or 9, "OUTLINE") end
                MPC.Nameplates:RefreshAll()
            end)
        y = y - 48

        local colorLabel = np:CreateFontString(nil, "OVERLAY")
        colorLabel:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        colorLabel:SetPoint("TOPLEFT", 16, y)
        colorLabel:SetTextColor(unpack(C.textNormal))
        colorLabel:SetText("Text Color")

        local colorSwatch = CreateFrame("Button", nil, np, "BackdropTemplate")
        colorSwatch:SetSize(22, 22)
        colorSwatch:SetPoint("LEFT", colorLabel, "RIGHT", 10, 0)
        colorSwatch:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        local fc2 = db.nameplates.fontColor
        colorSwatch:SetBackdropColor(fc2.r, fc2.g, fc2.b, fc2.a)
        colorSwatch:SetBackdropBorderColor(unpack(C.border))

        colorSwatch:SetScript("OnClick", function()
            local cur = db.nameplates.fontColor
            ColorPickerFrame:SetupColorPickerAndShow({
                r = cur.r, g = cur.g, b = cur.b,
                opacity = cur.a,
                hasOpacity = false, -- skip alpha complexity, just use RGB
                swatchFunc = function()
                    local r, g, b = ColorPickerFrame:GetColorRGB()
                    db.nameplates.fontColor = { r = r, g = g, b = b, a = 1 }
                    colorSwatch:SetBackdropColor(r, g, b, 1)
                    UpdateMockPosition()
                    MPC.Nameplates:RefreshAll()
                end,
                cancelFunc = function(prev)
                    db.nameplates.fontColor = { r = prev.r, g = prev.g, b = prev.b, a = 1 }
                    colorSwatch:SetBackdropColor(prev.r, prev.g, prev.b, 1)
                    UpdateMockPosition()
                    MPC.Nameplates:RefreshAll()
                end,
            })
        end)

        y = y - 36

        np:SetHeight(math.abs(y) + 20)
    end

    local bars = MakeTabFrame("bars")
    do
        local y = -10

        -- Progress Bar section
        CreateSectionHeader(bars, "Progress Bar", 12, y)
        y = y - 28

        CreateCheckbox(bars, "Enable progress bar", 16, y,
            function() return db.progressBar.enabled end,
            function(v)
                db.progressBar.enabled = v
                MPC.ProgressBar:Update()
            end)
        y = y - 28

        CreateCheckbox(bars, "Show text overlay", 16, y,
            function() return db.progressBar.showText end,
            function(v)
                db.progressBar.showText = v
                MPC.ProgressBar:Update()
            end)
        y = y - 28

        CreateCheckbox(bars, "Show overflow indicator (> 100%)", 16, y,
            function() return db.progressBar.showOverflow end,
            function(v)
                db.progressBar.showOverflow = v
                MPC.ProgressBar:Update()
            end)
        y = y - 32

        CreateSlider(bars, "Bar Width", 16, y, 100, 400, 10,
            function() return db.progressBar.width end,
            function(v)
                db.progressBar.width = v
                MPC.ProgressBar:ApplySize()
            end)
        y = y - 44

        CreateSlider(bars, "Bar Height", 16, y, 12, 40, 2,
            function() return db.progressBar.height end,
            function(v)
                db.progressBar.height = v
                MPC.ProgressBar:ApplySize()
            end)
        y = y - 44

        CreateSlider(bars, "Font Size", 16, y, 7, 30, 1,
            function() return db.progressBar.fontSize or 10 end,
            function(v)
                db.progressBar.fontSize = v
                MPC.ProgressBar:ApplyStyle()
            end)
        y = y - 44

        local fontOptions = {}
        for _, f in ipairs(MPC.Nameplates.FONTS) do
            fontOptions[#fontOptions + 1] = f.label
        end
        CreateDropdown(bars, "Font", 16, y, fontOptions,
            function() return db.progressBar.font or "Friz Quadrata TT" end,
            function(v)
                db.progressBar.font = v
                MPC.ProgressBar:ApplyStyle()
                MPC.PullTracker:ApplySize()
            end)
        y = y - 48

        local barTexOptions = {}
        for _, t in ipairs(MPC.ProgressBar:GetBarTextures()) do
            barTexOptions[#barTexOptions + 1] = t.label
        end
        CreateDropdown(bars, "Bar Texture", 16, y, barTexOptions,
            function() return db.progressBar.barTexture or "Blizzard" end,
            function(v)
                db.progressBar.barTexture = v
                MPC.ProgressBar:ApplyStyle()
            end)
        y = y - 48

        CreateSectionHeader(bars, "Pull Counter", 12, y)
        y = y - 28

        CreateCheckbox(bars, "Enable pull tracking", 16, y,
            function() return db.pull.enabled end,
            function(v)
                db.pull.enabled = v
                MPC.PullTracker:UpdateDisplay()
            end)
        y = y - 28

        CreateCheckbox(bars, "Show pull counter on screen", 16, y,
            function() return db.pull.showFrame end,
            function(v)
                db.pull.showFrame = v
                MPC.PullTracker:UpdateDisplay()
            end)
        y = y - 28

        CreateCheckbox(bars, "Show background", 16, y,
            function() return db.pull.showBackground end,
            function(v)
                db.pull.showBackground = v
                MPC.PullTracker:ApplyBackground()
            end)
        y = y - 32

        CreateSlider(bars, "Decimal Places", 16, y, 0, 4, 1,
            function() return db.pull.decimals end,
            function(v) db.pull.decimals = v end)
        y = y - 44

        CreateSlider(bars, "Pull Frame Width", 16, y, 80, 300, 10,
            function() return db.pull.width or 160 end,
            function(v)
                db.pull.width = v
                MPC.PullTracker:ApplySize()
            end)
        y = y - 44

        CreateSlider(bars, "Pull Frame Height", 16, y, 14, 40, 2,
            function() return db.pull.height or 24 end,
            function(v)
                db.pull.height = v
                MPC.PullTracker:ApplySize()
            end)
        y = y - 44

        CreateSlider(bars, "Pull Font Size", 16, y, 7, 30, 1,
            function() return db.pull.fontSize or 11 end,
            function(v)
                db.pull.fontSize = v
                MPC.PullTracker:ApplySize()
            end)
        y = y - 48

        -- Bar Colors section
        CreateSectionHeader(bars, "Bar Colors (Progress Bar)", 12, y)
        y = y - 24

        local function MakeColorPicker(parent, label, xPos, yPos, getter, setter)
            local lbl = parent:CreateFontString(nil, "OVERLAY")
            lbl:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
            lbl:SetPoint("TOPLEFT", xPos, yPos)
            lbl:SetTextColor(unpack(C.textNormal))
            lbl:SetText(label)

            local swatch = CreateFrame("Button", nil, parent, "BackdropTemplate")
            swatch:SetSize(22, 22)
            swatch:SetPoint("LEFT", lbl, "RIGHT", 8, 0)
            swatch:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8X8",
                edgeFile = "Interface\\Buttons\\WHITE8X8",
                edgeSize = 1,
            })
            local clr = getter()
            swatch:SetBackdropColor(clr.r, clr.g, clr.b, 1)
            swatch:SetBackdropBorderColor(unpack(C.border))

            swatch:SetScript("OnClick", function()
                local cur = getter()
                ColorPickerFrame:SetupColorPickerAndShow({
                    r = cur.r, g = cur.g, b = cur.b,
                    hasOpacity = false,
                    swatchFunc = function()
                        local r, g, b = ColorPickerFrame:GetColorRGB()
                        setter({ r = r, g = g, b = b })
                        swatch:SetBackdropColor(r, g, b, 1)
                        MPC.ProgressBar:ApplyStyle()
                    end,
                    cancelFunc = function(prev)
                        setter({ r = prev.r, g = prev.g, b = prev.b })
                        swatch:SetBackdropColor(prev.r, prev.g, prev.b, 1)
                        MPC.ProgressBar:ApplyStyle()
                    end,
                })
            end)
            return swatch
        end

        MakeColorPicker(bars, "Completed", 16, y,
            function() return db.progressBar.greenColor or { r = 0.1, g = 0.7, b = 0.1 } end,
            function(c) db.progressBar.greenColor = c end)
        y = y - 28

        MakeColorPicker(bars, "Current Pull", 16, y,
            function() return db.progressBar.yellowColor or { r = 0.9, g = 0.8, b = 0.1 } end,
            function(c) db.progressBar.yellowColor = c end)
        y = y - 28

        MakeColorPicker(bars, "Overflow", 16, y,
            function() return db.progressBar.overflowColor or { r = 0.9, g = 0.2, b = 0.2 } end,
            function(c) db.progressBar.overflowColor = c end)
        y = y - 36

        -- Border section
        CreateSectionHeader(bars, "Border", 12, y)
        y = y - 28

        CreateCheckbox(bars, "Show border", 16, y,
            function() return db.progressBar.borderEnabled end,
            function(v)
                db.progressBar.borderEnabled = v
                MPC.ProgressBar:ApplyBorder()
            end)
        y = y - 28

        MakeColorPicker(bars, "Border Color", 16, y,
            function() return db.progressBar.borderColor or { r = 0.3, g = 0.3, b = 0.3 } end,
            function(c) db.progressBar.borderColor = c; MPC.ProgressBar:ApplyBorder() end)
        y = y - 28

        local borderTexOptions = {}
        for _, t in ipairs(MPC.ProgressBar:GetBorderTextures()) do
            borderTexOptions[#borderTexOptions + 1] = t.label
        end
        CreateDropdown(bars, "Border Texture", 16, y, borderTexOptions,
            function() return db.progressBar.borderTexture or "Blizzard Tooltip" end,
            function(v)
                db.progressBar.borderTexture = v
                MPC.ProgressBar:ApplyBorder()
            end)
        y = y - 48

        -- Milestones section
        CreateSectionHeader(bars, "Milestones", 12, y)
        y = y - 24

        local msInfo = bars:CreateFontString(nil, "OVERLAY")
        msInfo:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
        msInfo:SetPoint("TOPLEFT", 16, y)
        msInfo:SetWidth(360)
        msInfo:SetJustifyH("LEFT")
        msInfo:SetTextColor(unpack(C.textDim))
        msInfo:SetText("Vertical marker lines on the progress bar at specific % values per dungeon. Useful to see if you have enough count before a boss.")
        y = y - 32

        CreateCheckbox(bars, "Enable milestone markers", 16, y,
            function() return db.progressBar.milestones.enabled end,
            function(v)
                db.progressBar.milestones.enabled = v
                MPC.ProgressBar:Update()
            end)
        y = y - 28

        CreateCheckbox(bars, "Show default milestones (last boss checkpoints)", 16, y,
            function() return db.progressBar.milestones.showDefaults end,
            function(v)
                db.progressBar.milestones.showDefaults = v
                MPC.ProgressBar:Update()
            end)
        y = y - 28

        CreateCheckbox(bars, "Show labels above markers", 16, y,
            function() return db.progressBar.milestones.showLabels end,
            function(v)
                db.progressBar.milestones.showLabels = v
                MPC.ProgressBar:Update()
            end)
        y = y - 28

        CreateCheckbox(bars, "Display % in labels", 16, y,
            function() return db.progressBar.milestones.showPercent end,
            function(v)
                db.progressBar.milestones.showPercent = v
                MPC.ProgressBar:Update()
            end)
        y = y - 32

        CreateSlider(bars, "Label Font Size", 16, y, 6, 16, 1,
            function() return db.progressBar.milestones.labelFontSize or 7 end,
            function(v)
                db.progressBar.milestones.labelFontSize = v
                MPC.ProgressBar:Update()
            end)
        y = y - 44

        MakeColorPicker(bars, "Label Color", 16, y,
            function() return db.progressBar.milestones.labelColor or { r = 1, g = 1, b = 1, a = 0.9 } end,
            function(c) c.a = 0.9; db.progressBar.milestones.labelColor = c end)
        y = y - 28

        local msLabelFontOptions = {}
        for _, f in ipairs(MPC.Nameplates.FONTS) do
            msLabelFontOptions[#msLabelFontOptions + 1] = f.label
        end
        CreateDropdown(bars, "Label Font", 16, y, msLabelFontOptions,
            function() return db.progressBar.milestones.labelFont or "Friz Quadrata TT" end,
            function(v)
                db.progressBar.milestones.labelFont = v
                MPC.ProgressBar:Update()
            end)
        y = y - 48

        MakeColorPicker(bars, "Line Color", 16, y,
            function() return db.progressBar.milestones.color or { r = 1, g = 1, b = 1, a = 0.8 } end,
            function(c) c.a = 0.8; db.progressBar.milestones.color = c end)
        y = y - 28

        MakeColorPicker(bars, "Completion Color", 16, y,
            function() return db.progressBar.milestones.completionColor or { r = 0.3, g = 0.85, b = 0.4, a = 0.8 } end,
            function(c) c.a = 0.8; db.progressBar.milestones.completionColor = c end)
        y = y - 36

        -- Build sorted dungeon list for dropdown
        local msDungeonList = {}
        for mapID, dungeon in pairs(MPC.Data.dungeons) do
            msDungeonList[#msDungeonList + 1] = { name = dungeon.name, mapID = mapID }
        end
        table.sort(msDungeonList, function(a, b) return a.name < b.name end)
        local msDungeonNames = {}
        local msDungeonMapIDs = {}
        for i, d in ipairs(msDungeonList) do
            msDungeonNames[i] = d.name
            msDungeonMapIDs[d.name] = d.mapID
        end

        -- Pre-select current dungeon if in one
        local msSelectedName = msDungeonList[1] and msDungeonList[1].name or ""
        local msSelectedMapID = msDungeonMapIDs[msSelectedName]
        local curMapID = MPC.Util:GetCurrentMapID()
        if curMapID then
            for _, d in ipairs(msDungeonList) do
                if d.mapID == curMapID then
                    msSelectedName = d.name
                    msSelectedMapID = d.mapID
                    break
                end
            end
        end

        local RebuildMilestoneRows  -- forward declaration (defined after UI creation)

        CreateDropdown(bars, "Dungeon", 16, y, msDungeonNames,
            function() return msSelectedName end,
            function(v)
                msSelectedName = v
                msSelectedMapID = msDungeonMapIDs[v]
                RebuildMilestoneRows()
            end)
        y = y - 48

        -- Milestone list container
        local msContainer = CreateFrame("Frame", nil, bars)
        msContainer:SetPoint("TOPLEFT", bars, "TOPLEFT", 16, y)
        msContainer:SetSize(350, 280)

        local MS_MAX_ROWS = 10
        local msRows = {}
        local msPctBox, msLabelBox, msAddBtn

        local function GetMilestonesForSelected()
            if not msSelectedMapID then return {} end
            if not db.progressBar.milestones.dungeons then
                db.progressBar.milestones.dungeons = {}
            end
            if not db.progressBar.milestones.dungeons[msSelectedMapID] then
                db.progressBar.milestones.dungeons[msSelectedMapID] = {}
            end
            return db.progressBar.milestones.dungeons[msSelectedMapID]
        end

        RebuildMilestoneRows = function()
            local milestones = GetMilestonesForSelected()
            local rowY = 0
            for i = 1, MS_MAX_ROWS do
                local row = msRows[i]
                if row then
                    if i <= #milestones then
                        local ms = milestones[i]
                        local txt = string.format("|cFFFFFFFF%g%%|r", ms.pct)
                        if ms.label and ms.label ~= "" then
                            txt = txt .. "  -  " .. ms.label
                        end
                        row.text:SetText(txt)
                        row:ClearAllPoints()
                        row:SetPoint("TOPLEFT", msContainer, "TOPLEFT", 0, -rowY)
                        row:Show()
                        rowY = rowY + 24
                    else
                        row:Hide()
                    end
                end
            end
            -- Position add controls below visible rows
            if msPctBox then
                msPctBox:ClearAllPoints()
                msPctBox:SetPoint("TOPLEFT", msContainer, "TOPLEFT", 0, -(rowY + 6))
                msLabelBox:ClearAllPoints()
                msLabelBox:SetPoint("LEFT", msPctBox, "RIGHT", 6, 0)
                msAddBtn:ClearAllPoints()
                msAddBtn:SetPoint("LEFT", msLabelBox, "RIGHT", 6, 0)
                local canAdd = #milestones < MS_MAX_ROWS
                msPctBox:SetShown(canAdd)
                msLabelBox:SetShown(canAdd)
                msAddBtn:SetShown(canAdd)
            end
        end

        -- Pre-create milestone row slots
        for i = 1, MS_MAX_ROWS do
            local row = CreateFrame("Frame", nil, msContainer, "BackdropTemplate")
            row:SetSize(340, 22)
            row:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
            row:SetBackdropColor(0.15, 0.15, 0.18, 0.6)

            local txt = row:CreateFontString(nil, "OVERLAY")
            txt:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
            txt:SetPoint("LEFT", 8, 0)
            txt:SetTextColor(unpack(C.textNormal))
            row.text = txt

            local del = CreateFrame("Button", nil, row, "BackdropTemplate")
            del:SetSize(18, 18)
            del:SetPoint("RIGHT", -4, 0)
            del:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8X8",
                edgeFile = "Interface\\Buttons\\WHITE8X8",
                edgeSize = 1,
            })
            del:SetBackdropColor(0.5, 0.15, 0.15, 0.6)
            del:SetBackdropBorderColor(0.6, 0.2, 0.2, 0.4)
            local delTxt = del:CreateFontString(nil, "OVERLAY")
            delTxt:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
            delTxt:SetPoint("CENTER")
            delTxt:SetTextColor(0.9, 0.4, 0.4)
            delTxt:SetText("x")
            del:SetScript("OnEnter", function(self) self:SetBackdropColor(0.7, 0.2, 0.2, 0.8) end)
            del:SetScript("OnLeave", function(self) self:SetBackdropColor(0.5, 0.15, 0.15, 0.6) end)
            del:SetScript("OnClick", function()
                local milestones = GetMilestonesForSelected()
                table.remove(milestones, i)
                RebuildMilestoneRows()
                MPC.ProgressBar:Update()
            end)

            row:Hide()
            msRows[i] = row
        end

        -- Add milestone input controls
        msPctBox = CreateFrame("EditBox", nil, msContainer, "BackdropTemplate")
        msPctBox:SetSize(60, 22)
        msPctBox:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        msPctBox:SetBackdropColor(0.15, 0.15, 0.18, 1)
        msPctBox:SetBackdropBorderColor(unpack(C.border))
        msPctBox:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        msPctBox:SetTextColor(unpack(C.textBright))
        msPctBox:SetTextInsets(6, 6, 0, 0)
        msPctBox:SetAutoFocus(false)
        msPctBox:SetMaxLetters(5)
        local pctPH = msPctBox:CreateFontString(nil, "OVERLAY")
        pctPH:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
        pctPH:SetPoint("LEFT", 6, 0)
        pctPH:SetTextColor(0.4, 0.4, 0.4, 1)
        pctPH:SetText("%")
        msPctBox:SetScript("OnTextChanged", function(self) pctPH:SetShown(self:GetText() == "") end)
        msPctBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

        msLabelBox = CreateFrame("EditBox", nil, msContainer, "BackdropTemplate")
        msLabelBox:SetSize(180, 22)
        msLabelBox:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        msLabelBox:SetBackdropColor(0.15, 0.15, 0.18, 1)
        msLabelBox:SetBackdropBorderColor(unpack(C.border))
        msLabelBox:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        msLabelBox:SetTextColor(unpack(C.textBright))
        msLabelBox:SetTextInsets(6, 6, 0, 0)
        msLabelBox:SetAutoFocus(false)
        msLabelBox:SetMaxLetters(30)
        local lblPH = msLabelBox:CreateFontString(nil, "OVERLAY")
        lblPH:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
        lblPH:SetPoint("LEFT", 6, 0)
        lblPH:SetTextColor(0.4, 0.4, 0.4, 1)
        lblPH:SetText("Label (optional)")
        msLabelBox:SetScript("OnTextChanged", function(self) lblPH:SetShown(self:GetText() == "") end)
        msLabelBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

        msAddBtn = CreateFrame("Button", nil, msContainer, "BackdropTemplate")
        msAddBtn:SetSize(50, 22)
        msAddBtn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        msAddBtn:SetBackdropColor(C.green[1] * 0.4, C.green[2] * 0.4, C.green[3] * 0.4, 0.8)
        msAddBtn:SetBackdropBorderColor(C.green[1], C.green[2], C.green[3], 0.6)
        local addTxt = msAddBtn:CreateFontString(nil, "OVERLAY")
        addTxt:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        addTxt:SetPoint("CENTER")
        addTxt:SetTextColor(unpack(C.textBright))
        addTxt:SetText("Add")
        msAddBtn:SetScript("OnEnter", function(self)
            self:SetBackdropColor(C.green[1] * 0.6, C.green[2] * 0.6, C.green[3] * 0.6, 1)
        end)
        msAddBtn:SetScript("OnLeave", function(self)
            self:SetBackdropColor(C.green[1] * 0.4, C.green[2] * 0.4, C.green[3] * 0.4, 0.8)
        end)

        local function AddMilestone()
            local pctVal = tonumber(msPctBox:GetText())
            if not pctVal or pctVal < 0.1 or pctVal > 99.99 then return end
            pctVal = math.floor(pctVal * 100 + 0.5) / 100  -- round to 2 decimals
            local labelVal = msLabelBox:GetText():trim()
            local milestones = GetMilestonesForSelected()
            if #milestones >= MS_MAX_ROWS then return end
            milestones[#milestones + 1] = { pct = pctVal, label = labelVal }
            table.sort(milestones, function(a, b) return a.pct < b.pct end)
            msPctBox:SetText("")
            msLabelBox:SetText("")
            RebuildMilestoneRows()
            MPC.ProgressBar:Update()
        end

        msAddBtn:SetScript("OnClick", AddMilestone)
        msPctBox:SetScript("OnEnterPressed", function(self) self:ClearFocus(); AddMilestone() end)
        msLabelBox:SetScript("OnEnterPressed", function(self) self:ClearFocus(); AddMilestone() end)

        RebuildMilestoneRows()
        y = y - 280

        bars:SetHeight(math.abs(y) + 20)
    end

    local ly = MakeTabFrame("frames")
    do
        local y = -10
        CreateSectionHeader(ly, "Frame Positioning", 12, y)
        y = y - 28

        local lockInfo = ly:CreateFontString(nil, "OVERLAY")
        lockInfo:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        lockInfo:SetPoint("TOPLEFT", 16, y)
        lockInfo:SetWidth(360)
        lockInfo:SetJustifyH("LEFT")
        lockInfo:SetTextColor(unpack(C.textNormal))
        lockInfo:SetText("Unlock frames to drag them to your preferred position.\nA blue glow and label will appear on movable frames.")
        y = y - 40

        local lockCb
        lockCb = CreateCheckbox(ly, "Lock frame positions", 16, y,
            function() return db.progressBar.locked end,
            function(v) MPC:SetLocked(v) end)
        y = y - 36

        CreateSectionHeader(ly, "Reset Positions", 12, y)
        y = y - 28

        CreateActionButton(ly, "Reset All Frame Positions", 16, y, 200, function()
            db.progressBar.point = nil
            db.pullFrame.point = nil
            MPC.ProgressBar:RestorePosition()
            MPC.PullTracker:RestorePosition()
            MPC:Print("Frame positions reset to default.")
        end, C.yellow)
        y = y - 40

        CreateSectionHeader(ly, "Individual Frame Reset", 12, y)
        y = y - 28

        CreateActionButton(ly, "Reset Progress Bar", 16, y, 150, function()
            db.progressBar.point = nil
            MPC.ProgressBar:RestorePosition()
            MPC:Print("Progress bar position reset.")
        end, C.accentDim)

        CreateActionButton(ly, "Reset Pull Frame", 176, y, 150, function()
            db.pullFrame.point = nil
            MPC.PullTracker:RestorePosition()
            MPC:Print("Pull frame position reset.")
        end, C.accentDim)
        y = y - 40

        ly:SetHeight(math.abs(y) + 20)
    end

    local ext = MakeTabFrame("extras")
    do
        local y = -10
        CreateSectionHeader(ext, "Extra Features", 12, y)
        y = y - 24

        local intro = ext:CreateFontString(nil, "OVERLAY")
        intro:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        intro:SetPoint("TOPLEFT", 16, y)
        intro:SetWidth(360)
        intro:SetJustifyH("LEFT")
        intro:SetTextColor(unpack(C.textNormal))
        intro:SetText("Optional features that can be enabled independently.")
        y = y - 28

        CreateSectionHeader(ext, "Minimap Button", 12, y)
        y = y - 24
        CreateCheckbox(ext, "Show minimap button", 16, y,
            function() return db.minimap and db.minimap.enabled end,
            function(v)
                if not db.minimap then db.minimap = { enabled = true, minimapPos = 220 } end
                db.minimap.enabled = v
                if MPC.MinimapButton then MPC.MinimapButton:UpdateVisibility() end
            end)
        y = y - 32

        if MPC.Extras and MPC.Extras.order then
            for _, key in ipairs(MPC.Extras.order) do
                local def = MPC.Extras.registry[key]
                if def then
                    CreateSectionHeader(ext, def.name or key, 12, y)
                    y = y - 24

                    if def.description then
                        local desc = ext:CreateFontString(nil, "OVERLAY")
                        desc:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
                        desc:SetPoint("TOPLEFT", 16, y)
                        desc:SetWidth(360)
                        desc:SetJustifyH("LEFT")
                        desc:SetTextColor(unpack(C.textDim))
                        desc:SetText(def.description)
                        y = y - 20
                    end

                    CreateCheckbox(ext, "Enable " .. (def.name or key), 16, y,
                        function() return MPC.Extras:IsEnabled(key) end,
                        function(v)
                            MPC.Extras:SetEnabled(key, v)
                            if Options.RefreshTabVisibility then Options.RefreshTabVisibility() end
                        end)
                    y = y - 28

                    y = y - 10
                end
            end
        end

        CreateSectionHeader(ext, "Developer", 12, y)
        y = y - 24
        CreateCheckbox(ext, "Developer mode (debug output, probe tools)", 16, y,
            function() return db.developerMode end,
            function(v)
                db.developerMode = v
                if Options.RefreshTabVisibility then Options.RefreshTabVisibility() end
            end)
        y = y - 36

        CreateSectionHeader(ext, "Settings Export / Import", 12, y)
        y = y - 24

        local exportNote = ext:CreateFontString(nil, "OVERLAY")
        exportNote:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
        exportNote:SetPoint("TOPLEFT", 16, y)
        exportNote:SetWidth(360)
        exportNote:SetJustifyH("LEFT")
        exportNote:SetTextColor(unpack(C.textDim))
        exportNote:SetText("Export your settings to share with friends, or import a settings string to apply someone else's setup.")
        y = y - 32

        CreateActionButton(ext, "Export Settings", 16, y, 140, function()
            Options:ExportSettings()
        end, C.accent)

        CreateActionButton(ext, "Import Settings", 166, y, 140, function()
            Options:ImportSettings()
        end, C.green)
        y = y - 36

        ext:SetHeight(math.abs(y) + 20)
    end

    local aq = MakeTabFrame("autoqueue")
    do
        local y = -10
        local aqSettings = MPC.Extras:GetSettings("autoqueue")

        local _, playerClass = UnitClass("player")
        local CLASS_ROLES = {
            WARRIOR     = { tank = true,  healer = false, dps = true },
            PALADIN     = { tank = true,  healer = true,  dps = true },
            HUNTER      = { tank = false, healer = false, dps = true },
            ROGUE       = { tank = false, healer = false, dps = true },
            PRIEST      = { tank = false, healer = true,  dps = true },
            DEATHKNIGHT = { tank = true,  healer = false, dps = true },
            SHAMAN      = { tank = false, healer = true,  dps = true },
            MAGE        = { tank = false, healer = false, dps = true },
            WARLOCK     = { tank = false, healer = false, dps = true },
            MONK        = { tank = true,  healer = true,  dps = true },
            DRUID       = { tank = true,  healer = true,  dps = true },
            DEMONHUNTER = { tank = true,  healer = false, dps = true },
            EVOKER      = { tank = false, healer = true,  dps = true },
        }
        local myRoles = CLASS_ROLES[playerClass] or { tank = false, healer = false, dps = true }

        CreateSectionHeader(aq, "Queue Pop", 12, y)
        y = y - 28

        CreateCheckbox(aq, "Auto-accept queue pops (LFG/LFR)", 16, y,
            function() return aqSettings.autoAccept ~= false end,
            function(v) aqSettings.autoAccept = v end)
        y = y - 28

        CreateCheckbox(aq, "Show notification", 16, y,
            function() return aqSettings.showNotification ~= false end,
            function(v) aqSettings.showNotification = v end)
        y = y - 36

        CreateSectionHeader(aq, "Auto Sign-Up (Premade Groups)", 12, y)
        y = y - 28

        CreateCheckbox(aq, "Auto-sign when clicking a premade group", 16, y,
            function() return aqSettings.autoSign end,
            function(v) aqSettings.autoSign = v end)
        y = y - 24

        local signNote = aq:CreateFontString(nil, "OVERLAY")
        signNote:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
        signNote:SetPoint("TOPLEFT", 40, y)
        signNote:SetWidth(330)
        signNote:SetJustifyH("LEFT")
        signNote:SetTextColor(unpack(C.textDim))
        signNote:SetText("Skips the role dialog and instantly signs up with your selected roles.\nHold |cFFFFFFFFShift|r when clicking a group to skip auto-sign.")
        y = y - 32

        CreateSectionHeader(aq, "Preferred Roles", 12, y)
        y = y - 24

        local function MakeRoleCheckbox(label, roleKey, yPos)
            local canPlay = myRoles[roleKey]
            local cb, cbText = CreateCheckbox(aq, label, 16, yPos,
                function() return aqSettings["role" .. label] and canPlay end,
                function(v)
                    if canPlay then
                        aqSettings["role" .. label] = v
                    end
                end)
            if not canPlay then
                if cbText then cbText:SetTextColor(0.4, 0.4, 0.4) end
                cb:Disable()
                cb:SetAlpha(0.4)
            end
            return cb
        end

        MakeRoleCheckbox("Tank", "tank", y)
        y = y - 26
        MakeRoleCheckbox("Healer", "healer", y)
        y = y - 26
        MakeRoleCheckbox("Damage", "dps", y)
        y = y - 32

        y = y - 4

        aq:SetHeight(math.abs(y) + 20)
    end

    -- Debug tab uses a raw frame (not MakeTabFrame) because it needs
    -- a full-size EditBox, not a scrolling content frame
    do
        local debugFrame = CreateFrame("Frame", nil, contentArea)
        debugFrame:SetPoint("TOPLEFT", 4, -4)
        debugFrame:SetPoint("BOTTOMRIGHT", -4, 4)
        debugFrame:Hide()
        tabFrames["debug"] = debugFrame

        local header = debugFrame:CreateFontString(nil, "OVERLAY")
        header:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
        header:SetPoint("TOPLEFT", 12, -8)
        header:SetTextColor(unpack(C.accent))
        header:SetText("Debug Output")

        local hint = debugFrame:CreateFontString(nil, "OVERLAY")
        hint:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
        hint:SetPoint("TOPRIGHT", -12, -10)
        hint:SetTextColor(unpack(C.textDim))
        hint:SetText("Ctrl+A to select all, Ctrl+C to copy")

        local scrollFrame = CreateFrame("ScrollFrame", "MythicPlusCountDebugScroll", debugFrame, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", 8, -50)
        scrollFrame:SetPoint("BOTTOMRIGHT", -26, 40)

        if scrollFrame.ScrollBar then
            local sb = scrollFrame.ScrollBar
            if sb.Background then sb.Background:Hide() end
            if sb.Track then
                if sb.Track.Begin then sb.Track.Begin:Hide() end
                if sb.Track.End then sb.Track.End:Hide() end
                if sb.Track.Middle then sb.Track.Middle:Hide() end
            end
        end

        local editBox = CreateFrame("EditBox", "MythicPlusCountDebugEditBox", scrollFrame)
        editBox:SetMultiLine(true)
        editBox:SetAutoFocus(false)
        editBox:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        editBox:SetTextColor(0.8, 0.8, 0.8, 1)
        editBox:SetWidth(scrollFrame:GetWidth() or 350)
        editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        scrollFrame:SetScrollChild(editBox)

        local editBg = CreateFrame("Frame", nil, debugFrame, "BackdropTemplate")
        editBg:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", -4, 4)
        editBg:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT", 4, -4)
        editBg:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        editBg:SetBackdropColor(0.06, 0.06, 0.08, 1)
        editBg:SetBackdropBorderColor(unpack(C.border))
        editBg:SetFrameLevel(debugFrame:GetFrameLevel())

        CreateActionButton(debugFrame, "Debug Dump", 8, -28, 100, function()
            Options:RunDebugDump()
        end, C.accent)

        CreateActionButton(debugFrame, "Probe Target", 118, -28, 100, function()
            Options:RunTargetProbe()
        end, C.green)

        CreateActionButton(debugFrame, "Clear", 228, -28, 50, function()
            editBox:SetText("")
        end, C.red)

        Options.debugEditBox = editBox
    end

    SelectTab("general")

    tinsert(UISpecialFrames, "MythicPlusCountOptions")
end

local issecretvalue = issecretvalue or function() return false end

function Options:DebugWrite(text)
    if not self.debugEditBox then return end
    local current = self.debugEditBox:GetText() or ""
    if current ~= "" then current = current .. "\n" end
    self.debugEditBox:SetText(current .. text)
end

function Options:DebugClear()
    if not self.debugEditBox then return end
    self.debugEditBox:SetText("")
end

function Options:RunDebugDump()
    self:DebugClear()
    local db = MPC.db
    local mapID = MPC.Util:GetActiveChallengeMapID()
    local instanceName = GetInstanceInfo()
    local inMP = MPC.Util:IsInMythicPlus()

    self:DebugWrite("=== MythicPlusCount Debug ===")
    self:DebugWrite("Version: " .. MPC.VERSION)
    self:DebugWrite("Challenge Map ID: " .. tostring(mapID or "none"))
    self:DebugWrite("Instance: " .. tostring(instanceName or "none"))
    self:DebugWrite("In Mythic+: " .. tostring(inMP))
    self:DebugWrite("Debug mode: " .. tostring(db.developerMode))
    self:DebugWrite("")

    local dungeonCount, mobCount = 0, 0
    for _, d in pairs(MPC.Data.dungeons) do
        dungeonCount = dungeonCount + 1
        for _ in pairs(d.mobs) do mobCount = mobCount + 1 end
    end
    self:DebugWrite("Loaded dungeons: " .. dungeonCount)
    self:DebugWrite("Loaded mob entries: " .. mobCount)

    if mapID then
        local dungeon = MPC.Data:GetDungeon(mapID)
        if dungeon then
            self:DebugWrite("Current dungeon: " .. dungeon.name .. " (totalForces=" .. dungeon.totalForces .. ")")
        else
            self:DebugWrite("WARNING: Map ID " .. mapID .. " not found in data table!")
        end
    end
    self:DebugWrite("")

    local completed = MPC.Util:GetCompletedPercent()
    local pullPct = MPC.PullTracker:GetCurrentPullPercent()
    self:DebugWrite("Completed: " .. string.format("%.2f%%", completed))
    self:DebugWrite("Pull: " .. string.format("%.2f%%", pullPct))
    self:DebugWrite("Predicted: " .. string.format("%.2f%%", completed + pullPct))
    self:DebugWrite("")

    self:DebugWrite("Settings:")
    self:DebugWrite("  Tooltip enabled: " .. tostring(db.tooltip.enabled))
    self:DebugWrite("  Nameplates enabled: " .. tostring(db.nameplates.enabled))
    self:DebugWrite("  Nameplates provider: " .. db.nameplates.provider)
    self:DebugWrite("  Active adapter: " .. MPC.Nameplates:GetActiveAdapterName())
    self:DebugWrite("  Pull frame enabled: " .. tostring(db.pull.enabled))
    self:DebugWrite("  Progress bar enabled: " .. tostring(db.progressBar.enabled))
    self:DebugWrite("  Frames locked: " .. tostring(db.progressBar.locked))
    self:DebugWrite("")

    self:DebugWrite("API Checks:")
    self:DebugWrite("  issecretvalue: " .. (issecretvalue ~= nil and "available" or "MISSING"))
    self:DebugWrite("  C_ChallengeMode: " .. (C_ChallengeMode and "available" or "MISSING"))
    self:DebugWrite("  C_ScenarioInfo: " .. (C_ScenarioInfo and "available" or "MISSING"))
    self:DebugWrite("  C_TooltipInfo: " .. (C_TooltipInfo and "available" or "MISSING"))
    self:DebugWrite("  C_NamePlate: " .. (C_NamePlate and "available" or "MISSING"))

    self:DebugWrite("")
    self:DebugWrite("=== Scenario Forces Probe ===")

    self:DebugWrite("--- Method A: C_ScenarioInfo ---")
    if C_ScenarioInfo and C_ScenarioInfo.GetScenarioStepInfo then
        local stepInfo = C_ScenarioInfo.GetScenarioStepInfo()
        if stepInfo then
            self:DebugWrite("  numCriteria: " .. tostring(stepInfo.numCriteria))
            self:DebugWrite("  stepID: " .. tostring(stepInfo.stepID))

            local numCrit = stepInfo.numCriteria or 0
            for i = 1, numCrit do
                local cInfo = C_ScenarioInfo.GetCriteriaInfoByStep(1, i)
                if cInfo then
                    local parts = {}
                    for k, v in pairs(cInfo) do
                        local s = (v ~= nil) and issecretvalue(v)
                        if type(v) ~= "table" and type(v) ~= "function" then
                            parts[#parts + 1] = k .. "=" .. (s and "(SECRET)" or tostring(v))
                        elseif type(v) == "table" then
                            parts[#parts + 1] = k .. "=(table)"
                        end
                    end
                    table.sort(parts)
                    self:DebugWrite("  crit[" .. i .. "]: " .. table.concat(parts, ", "))
                else
                    self:DebugWrite("  crit[" .. i .. "]: nil (GetCriteriaInfoByStep returned nil)")
                end
            end
        else
            self:DebugWrite("  stepInfo: nil")
        end
    else
        self:DebugWrite("  API not available")
    end

    self:DebugWrite("")
    self:DebugWrite("--- Method B: C_Scenario (exhaustive) ---")
    if C_Scenario then
        local funcs = {"GetStepInfo","GetInfo","GetCriteriaInfo","GetCriteriaInfoByStep",
                        "GetBonusCriteriaInfo","GetProvingGroundsInfo","GetSupersededObjectives"}
        for _, fname in ipairs(funcs) do
            self:DebugWrite("  C_Scenario." .. fname .. ": " .. (C_Scenario[fname] and "exists" or "NIL"))
        end
        self:DebugWrite("")

        if C_Scenario.GetCriteriaInfo then
            for i = 1, 6 do
                local ok, err = pcall(function()
                    local r1, r2, r3, r4, r5, r6, r7, r8 = C_Scenario.GetCriteriaInfo(i)
                    local parts = {}
                    local names = {"desc","type","completed","quantity","totalQty","flags","assetID","quantityStr"}
                    local vals = {r1, r2, r3, r4, r5, r6, r7, r8}
                    for j = 1, 8 do
                        local v = vals[j]
                        if v ~= nil then
                            local s = issecretvalue(v)
                            parts[#parts + 1] = names[j] .. "=" .. (s and "(SECRET)" or tostring(v))
                        end
                    end
                    if #parts > 0 then
                        MPC.Options:DebugWrite("    GetCriteriaInfo(" .. i .. "): " .. table.concat(parts, ", "))
                    else
                        MPC.Options:DebugWrite("    GetCriteriaInfo(" .. i .. "): all nil")
                    end
                end)
                if not ok then
                    self:DebugWrite("    GetCriteriaInfo(" .. i .. "): ERROR: " .. tostring(err))
                end
            end
        end

        if C_Scenario.GetCriteriaInfoByStep then
            self:DebugWrite("")
            for i = 1, 6 do
                local ok, err = pcall(function()
                    local r1, r2, r3, r4, r5, r6, r7, r8 = C_Scenario.GetCriteriaInfoByStep(1, i)
                    local vals = {r1, r2, r3, r4, r5, r6, r7, r8}
                    local parts = {}
                    for j, v in ipairs(vals) do
                        if v ~= nil then
                            local s = issecretvalue(v)
                            parts[#parts + 1] = (s and "(SECRET)" or tostring(v))
                        end
                    end
                    if #parts > 0 then
                        MPC.Options:DebugWrite("    GetCriteriaInfoByStep(1," .. i .. "): " .. table.concat(parts, ", "))
                    else
                        MPC.Options:DebugWrite("    GetCriteriaInfoByStep(1," .. i .. "): all nil")
                    end
                end)
                if not ok then
                    self:DebugWrite("    GetCriteriaInfoByStep(1," .. i .. "): ERROR: " .. tostring(err))
                end
            end
        end
    end

    self:DebugWrite("")
    self:DebugWrite("--- Method C: C_ScenarioInfo (all functions) ---")
    if C_ScenarioInfo then
        local funcs = {}
        for k, v in pairs(C_ScenarioInfo) do
            if type(v) == "function" then
                funcs[#funcs + 1] = k
            end
        end
        table.sort(funcs)
        self:DebugWrite("  Available functions: " .. table.concat(funcs, ", "))

        if C_ScenarioInfo.GetCriteriaInfo then
            self:DebugWrite("")
            for i = 1, 6 do
                local ok, result = pcall(C_ScenarioInfo.GetCriteriaInfo, i)
                if ok and result then
                    local parts = {}
                    for k, v in pairs(result) do
                        if type(v) ~= "table" and type(v) ~= "function" then
                            local s = issecretvalue(v)
                            parts[#parts + 1] = k .. "=" .. (s and "(SECRET)" or tostring(v))
                        end
                    end
                    table.sort(parts)
                    self:DebugWrite("    GetCriteriaInfo(" .. i .. "): " .. table.concat(parts, ", "))
                elseif ok then
                    self:DebugWrite("    GetCriteriaInfo(" .. i .. "): nil")
                else
                    self:DebugWrite("    GetCriteriaInfo(" .. i .. "): ERROR: " .. tostring(result))
                end
            end
        end
    end

    self:DebugWrite("")
    self:DebugWrite("--- Method D: Blizzard M+ UI Frames ---")
    local framesToCheck = {
        "ScenarioChallengeModeBlock", "ScenarioObjectiveBlock",
        "ScenarioStageBlock", "ScenarioProvingGroundsBlock",
        "ObjectiveTrackerBlocksFrame",
    }
    for _, fname in ipairs(framesToCheck) do
        local f = _G[fname]
        self:DebugWrite("  " .. fname .. ": " .. (f and "exists" or "nil"))
    end

    if ObjectiveTrackerFrame and ObjectiveTrackerFrame.modules then
        self:DebugWrite("  OTF modules: " .. #ObjectiveTrackerFrame.modules)
    end

    self:DebugWrite("")
    self:DebugWrite("--- Method E: C_ChallengeMode ---")
    if C_ChallengeMode then
        local cmFuncs = {}
        for k, v in pairs(C_ChallengeMode) do
            if type(v) == "function" then cmFuncs[#cmFuncs + 1] = k end
        end
        table.sort(cmFuncs)
        self:DebugWrite("  Functions: " .. table.concat(cmFuncs, ", "))

        if C_ChallengeMode.GetDeathCount then
            local ok, deaths = pcall(C_ChallengeMode.GetDeathCount)
            self:DebugWrite("  GetDeathCount: " .. (ok and tostring(deaths) or "ERROR"))
        end
        if C_ChallengeMode.GetActiveKeystoneInfo then
            local ok, r = pcall(function() return {C_ChallengeMode.GetActiveKeystoneInfo()} end)
            if ok and r then
                local parts = {}
                for i, v in ipairs(r) do
                    local s = issecretvalue(v)
                    parts[#parts + 1] = (s and "(SECRET)" or tostring(v))
                end
                self:DebugWrite("  GetActiveKeystoneInfo: " .. table.concat(parts, ", "))
            end
        end
    end

    self:DebugWrite("")
    self:DebugWrite("Target a mob and click 'Probe Target' for NPC ID detection.")
end

local function safeRead(fn, default)
    local ok, val = pcall(fn)
    if ok and val ~= nil and not issecretvalue(val) then return val end
    return default
end

function Options:RunTargetProbe()
    self:DebugClear()
    self:DebugWrite("=== Fingerprint Probe ===")

    if not UnitExists("target") then
        self:DebugWrite("ERROR: No target. Target a mob and try again.")
        return
    end

    local mapID = MPC.Util:GetCurrentMapID()
    self:DebugWrite("Map ID: " .. tostring(mapID or "none"))
    self:DebugWrite("")

    local fp = MPC.Util:GetFingerprint("target")
    self:DebugWrite("Fingerprint: " .. (fp or "FAILED"))
    self:DebugWrite("")

    self:DebugWrite("Components:")
    self:DebugWrite("  ModelFileID: " .. tostring(MPC.Util:GetModelFileID("target") or "nil"))
    self:DebugWrite("  UnitLevel: " .. tostring(safeRead(function() return UnitLevel("target") end, "?")))
    self:DebugWrite("  UnitClassification: " .. tostring(safeRead(function() return UnitClassification("target") end, "?")))
    self:DebugWrite("  UnitSex: " .. tostring(safeRead(function() return UnitSex("target") end, "?")))
    self:DebugWrite("  UnitClass(token): " .. tostring(safeRead(function() return select(2, UnitClass("target")) end, "?")))
    self:DebugWrite("  UnitPowerType: " .. tostring(safeRead(function() return UnitPowerType("target") end, "?")))
    self:DebugWrite("  UnitAttackSpeed: " .. tostring(safeRead(function() return string.format("%.3f", UnitAttackSpeed("target")) end, "?")))

    local buffCount = 0
    if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        for i = 1, 10 do
            local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, "target", i, "HELPFUL")
            if ok and aura then
                buffCount = buffCount + 1
                local name = aura.name and (issecretvalue(aura.name) and "(S)" or aura.name) or "nil"
                local spellId = aura.spellId and (issecretvalue(aura.spellId) and "(S)" or tostring(aura.spellId)) or "nil"
                self:DebugWrite("  Buff[" .. i .. "]: " .. name .. " (spellId=" .. spellId .. ")")
            else
                break
            end
        end
    end
    self:DebugWrite("  BuffCount: " .. buffCount)
    self:DebugWrite("")

    local npcID = MPC.Util:GetNpcIDFromUnit("target")
    if npcID then
        local info = MPC.Util:GetMobInfo(npcID)
        if info then
            self:DebugWrite("IDENTIFIED: " .. info.name)
            self:DebugWrite("  NPC ID: " .. npcID)
            self:DebugWrite("  Forces: " .. info.count .. " (" .. string.format("%.2f%%", info.percent) .. ")")
        else
            self:DebugWrite("NPC ID " .. npcID .. " found but not in data table")
        end
    else
        self:DebugWrite("NOT IDENTIFIED")
        self:DebugWrite("Use /mpc teach to teach this mob's fingerprint")
        if fp then
            -- Check if fingerprint is already mapped
            local fpMap = MPC.db.fingerprints
            if fpMap and fpMap[mapID] and fpMap[mapID][fp] then
                self:DebugWrite("(Fingerprint IS saved but NPC lookup failed)")
            end
        end
    end
end

function Options:RunQuickProbe()
    self:RunTargetProbe()
end

function Options:RegisterBlizzardSettings()
end

-- Settings Export: serialize key settings to a copyable string
-- Serialization helpers
local function serialize(tbl)
    local parts = {}
    for k, v in pairs(tbl) do
        local key = type(k) == "number" and ("[" .. k .. "]") or k
        if type(v) == "table" then
            parts[#parts + 1] = key .. "={" .. serialize(v) .. "}"
        elseif type(v) == "string" then
            parts[#parts + 1] = key .. '="' .. v .. '"'
        else
            parts[#parts + 1] = key .. "=" .. tostring(v)
        end
    end
    return table.concat(parts, ",")
end

local function deserialize(str)
    local fn, err = loadstring("return {" .. str .. "}")
    if fn then
        -- Run in empty environment to prevent code injection
        setfenv(fn, {})
        local ok, result = pcall(fn)
        if ok and type(result) == "table" then return result end
    end
    return nil
end

-- Copy/paste modal popup
local copyPasteFrame = nil
local function ShowCopyPasteModal(title, text, onAccept)
    if not copyPasteFrame then
        copyPasteFrame = CreateFrame("Frame", "MythicPlusCountCopyPaste", UIParent, "BackdropTemplate")
        copyPasteFrame:SetSize(450, 250)
        -- Full-screen dim overlay behind the modal
        local dimOverlay = CreateFrame("Frame", nil, UIParent)
        dimOverlay:SetFrameStrata("DIALOG")
        dimOverlay:SetAllPoints(UIParent)
        dimOverlay:EnableMouse(true) -- block clicks through
        local dimTex = dimOverlay:CreateTexture(nil, "BACKGROUND")
        dimTex:SetAllPoints()
        dimTex:SetColorTexture(0, 0, 0, 0.6)
        dimOverlay:Hide()
        copyPasteFrame._dimOverlay = dimOverlay

        copyPasteFrame:SetPoint("CENTER")
        copyPasteFrame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 2,
        })
        copyPasteFrame:SetBackdropColor(0.14, 0.14, 0.16, 1)
        copyPasteFrame:SetBackdropBorderColor(0.3, 0.7, 1.0, 1)
        copyPasteFrame:SetFrameStrata("FULLSCREEN_DIALOG")
        copyPasteFrame:SetMovable(true)
        copyPasteFrame:EnableMouse(true)
        copyPasteFrame:RegisterForDrag("LeftButton")
        copyPasteFrame:SetScript("OnDragStart", copyPasteFrame.StartMoving)
        copyPasteFrame:SetScript("OnDragStop", copyPasteFrame.StopMovingOrSizing)

        copyPasteFrame.title = copyPasteFrame:CreateFontString(nil, "OVERLAY")
        copyPasteFrame.title:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
        copyPasteFrame.title:SetPoint("TOP", 0, -10)
        copyPasteFrame.title:SetTextColor(0.3, 0.7, 1.0, 1)

        local hint = copyPasteFrame:CreateFontString(nil, "OVERLAY")
        hint:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
        hint:SetPoint("TOP", 0, -28)
        hint:SetTextColor(0.55, 0.55, 0.6, 1)
        hint:SetText("Ctrl+A to select all, Ctrl+C to copy, Ctrl+V to paste")
        copyPasteFrame.hint = hint

        local scrollFrame = CreateFrame("ScrollFrame", nil, copyPasteFrame, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", 12, -46)
        scrollFrame:SetPoint("BOTTOMRIGHT", -30, 44)

        local editBox = CreateFrame("EditBox", nil, scrollFrame)
        editBox:SetMultiLine(true)
        editBox:SetAutoFocus(false)
        editBox:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        editBox:SetTextColor(0.8, 0.8, 0.8, 1)
        editBox:SetWidth(400)
        editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        scrollFrame:SetScrollChild(editBox)
        copyPasteFrame.editBox = editBox

        local editBg = CreateFrame("Frame", nil, copyPasteFrame, "BackdropTemplate")
        editBg:SetPoint("TOPLEFT", scrollFrame, -4, 4)
        editBg:SetPoint("BOTTOMRIGHT", scrollFrame, 4, -4)
        editBg:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        editBg:SetBackdropColor(0.05, 0.05, 0.07, 1)
        editBg:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)
        editBg:SetFrameLevel(copyPasteFrame:GetFrameLevel())

        local closeBtn = CreateFrame("Button", nil, copyPasteFrame)
        closeBtn:SetSize(70, 24)
        closeBtn:SetPoint("BOTTOMRIGHT", -10, 10)
        local closeTxt = closeBtn:CreateFontString(nil, "OVERLAY")
        closeTxt:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        closeTxt:SetPoint("CENTER")
        closeTxt:SetTextColor(0.85, 0.85, 0.85)
        closeTxt:SetText("Close")
        closeBtn:SetScript("OnClick", function()
            copyPasteFrame:Hide()
            if copyPasteFrame._dimOverlay then copyPasteFrame._dimOverlay:Hide() end
        end)
        copyPasteFrame.closeBtn = closeBtn

        local acceptBtn = CreateFrame("Button", nil, copyPasteFrame, "BackdropTemplate")
        acceptBtn:SetSize(90, 24)
        acceptBtn:SetPoint("BOTTOMLEFT", 10, 10)
        acceptBtn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        acceptBtn:SetBackdropColor(0.1, 0.4, 0.15, 1)
        acceptBtn:SetBackdropBorderColor(0.2, 0.6, 0.3, 1)
        local acceptTxt = acceptBtn:CreateFontString(nil, "OVERLAY")
        acceptTxt:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        acceptTxt:SetPoint("CENTER")
        acceptTxt:SetTextColor(0.85, 0.85, 0.85)
        acceptTxt:SetText("Import")
        copyPasteFrame.acceptBtn = acceptBtn
        copyPasteFrame.acceptTxt = acceptTxt

        tinsert(UISpecialFrames, "MythicPlusCountCopyPaste")
    end

    copyPasteFrame.title:SetText(title)
    copyPasteFrame.editBox:SetText(text or "")
    if text and text ~= "" then
        copyPasteFrame.editBox:HighlightText()
    end

    if onAccept then
        copyPasteFrame.acceptBtn:Show()
        copyPasteFrame.acceptBtn:SetScript("OnClick", function()
            onAccept(copyPasteFrame.editBox:GetText())
            copyPasteFrame:Hide()
            if copyPasteFrame._dimOverlay then copyPasteFrame._dimOverlay:Hide() end
        end)
    else
        copyPasteFrame.acceptBtn:Hide()
    end

    if copyPasteFrame._dimOverlay then copyPasteFrame._dimOverlay:Show() end
    copyPasteFrame:Show()
    copyPasteFrame.editBox:SetFocus()
end

function Options:ExportSettings()
    if not MPC.db then return end

    -- Export EVERYTHING — full snapshot of all settings
    local export = {
        v = 2,
        tooltip = MPC.db.tooltip,
        nameplates = MPC.db.nameplates,
        pull = MPC.db.pull,
        progressBar = MPC.db.progressBar,
        pullFrame = MPC.db.pullFrame,
        nameplates_placement = MPC.db.nameplates_placement,
        showOutsideMPlus = MPC.db.showOutsideMPlus,
        developerMode = MPC.db.developerMode,
        optionsPanelScale = MPC.db.optionsPanelScale,
        minimap = MPC.db.minimap,
        extras = MPC.db.extras,
    }

    local exportStr = "MPC1:" .. serialize(export)
    ShowCopyPasteModal("Export Settings", exportStr, nil)
end

function Options:ImportSettings()
    ShowCopyPasteModal("Import Settings", "", function(text)
        if not text or text == "" then
            MPC:Print("No settings string provided.")
            return
        end

        -- Strip the MPC1: prefix
        local data = text:match("^MPC1:(.+)$")
        if not data then
            MPC:Print("|cFFFF4444Invalid settings string.|r Must start with MPC1:")
            return
        end

        local imported = deserialize(data)
        if not imported then
            MPC:Print("|cFFFF4444Failed to parse settings string.|r")
            return
        end

        -- Apply imported settings (merge, don't replace)
        local function deepMerge(target, source)
            for k, v in pairs(source) do
                if type(v) == "table" and type(target[k]) == "table" then
                    deepMerge(target[k], v)
                else
                    target[k] = v
                end
            end
        end

        if imported.tooltip then deepMerge(MPC.db.tooltip, imported.tooltip) end
        if imported.nameplates then deepMerge(MPC.db.nameplates, imported.nameplates) end
        if imported.pull then deepMerge(MPC.db.pull, imported.pull) end
        if imported.progressBar then deepMerge(MPC.db.progressBar, imported.progressBar) end
        if imported.pullFrame then deepMerge(MPC.db.pullFrame, imported.pullFrame) end
        if imported.nameplates_placement then MPC.db.nameplates_placement = imported.nameplates_placement end
        if imported.showOutsideMPlus ~= nil then MPC.db.showOutsideMPlus = imported.showOutsideMPlus end
        if imported.developerMode ~= nil then MPC.db.developerMode = imported.developerMode end
        if imported.optionsPanelScale then MPC.db.optionsPanelScale = imported.optionsPanelScale end
        if imported.minimap then deepMerge(MPC.db.minimap, imported.minimap) end
        if imported.extras then deepMerge(MPC.db.extras, imported.extras) end

        MPC.Nameplates:RefreshAll()
        MPC.ProgressBar:ApplySize()
        MPC.ProgressBar:ApplyStyle()
        MPC.ProgressBar:RestorePosition()
        MPC.PullTracker:ApplySize()
        MPC.PullTracker:RestorePosition()
        if MPC.MinimapButton then MPC.MinimapButton:UpdatePosition() end
        if MPC.MinimapButton then MPC.MinimapButton:UpdateVisibility() end

        -- Show reload confirmation dialog
        StaticPopupDialogs["MPC_RELOAD_CONFIRM"] = {
            text = "Settings imported successfully!\nReload UI to fully apply?",
            button1 = "Reload Now",
            button2 = "Later",
            OnAccept = function() ReloadUI() end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
        StaticPopup_Show("MPC_RELOAD_CONFIRM")
    end)
end
