-- MythicPlusCount - Progress Bar
-- Shows completed %, current pull %, and predicted total %.
-- Yellow segment = current pull. Gold glow when pull crosses 100%.
-- Supports LibSharedMedia bar textures and LibEditMode integration.
local ADDON_NAME, NS = ...
local MPC = NS.MPC

local ProgressBar = {}
MPC.ProgressBar = ProgressBar

local barFrame, bgBar, greenBar, yellowBar, overflowBar, barText
local unlockGlow, completionGlow
local hasShownCompletionGlow = false  -- only show the glow once per key
local inEditMode = false

local MILESTONE_POOL_SIZE = 10
local milestoneLines = {}
local milestoneLabels = {}
local milestoneOverlay

local DEFAULT_BAR_TEXTURE = "Interface\\TargetingFrame\\UI-StatusBar"
local DEFAULT_BAR_NAME = "Blizzard"

-- SharedMedia bar texture list (built lazily on first access)
ProgressBar.BAR_TEXTURES = nil

-- Get LibSharedMedia reference (cached)
local LSM
local function GetLSM()
    if LSM == nil then
        LSM = LibStub and LibStub("LibSharedMedia-3.0", true) or false
    end
    return LSM
end

-- Build bar texture list from SharedMedia (called lazily)
function ProgressBar:GetBarTextures()
    if self.BAR_TEXTURES then return self.BAR_TEXTURES end
    self.BAR_TEXTURES = {}
    local lsm = GetLSM()
    if lsm then
        local mediaBars = lsm:HashTable("statusbar")
        if mediaBars then
            for name in pairs(mediaBars) do
                self.BAR_TEXTURES[#self.BAR_TEXTURES + 1] = { label = name }
            end
        end
    end
    if #self.BAR_TEXTURES == 0 then
        self.BAR_TEXTURES[1] = { label = DEFAULT_BAR_NAME }
    end
    table.sort(self.BAR_TEXTURES, function(a, b) return a.label:lower() < b.label:lower() end)
    return self.BAR_TEXTURES
end

-- Resolve a bar texture name to a file path via LSM
local function FetchBarTexture(name)
    if not name or name == "" then return DEFAULT_BAR_TEXTURE end
    local lsm = GetLSM()
    if lsm then
        local path = lsm:Fetch("statusbar", name)
        if path then return path end
    end
    return DEFAULT_BAR_TEXTURE
end

function ProgressBar:GetBarTexturePath()
    return FetchBarTexture(MPC.db.progressBar.barTexture)
end

-- Border texture list from SharedMedia (lazy)
local DEFAULT_BORDER_TEXTURE = "Interface\\Tooltips\\UI-Tooltip-Border"
local DEFAULT_BORDER_NAME = "Blizzard Tooltip"
ProgressBar.BORDER_TEXTURES = nil

function ProgressBar:GetBorderTextures()
    if self.BORDER_TEXTURES then return self.BORDER_TEXTURES end
    self.BORDER_TEXTURES = {}
    local lsm = GetLSM()
    if lsm then
        local mediaBorders = lsm:HashTable("border")
        if mediaBorders then
            for name in pairs(mediaBorders) do
                self.BORDER_TEXTURES[#self.BORDER_TEXTURES + 1] = { label = name }
            end
        end
    end
    if #self.BORDER_TEXTURES == 0 then
        self.BORDER_TEXTURES[1] = { label = DEFAULT_BORDER_NAME }
    end
    table.sort(self.BORDER_TEXTURES, function(a, b) return a.label:lower() < b.label:lower() end)
    return self.BORDER_TEXTURES
end

local function FetchBorderTexture(name)
    if not name or name == "" then return DEFAULT_BORDER_TEXTURE end
    local lsm = GetLSM()
    if lsm then
        local path = lsm:Fetch("border", name)
        if path then return path end
    end
    return DEFAULT_BORDER_TEXTURE
end

function ProgressBar:Init()
    self:CreateBar()
end

function ProgressBar:CreateBar()
    local db = MPC.db.progressBar
    local width = db.width or 220
    local height = db.height or 18

    barFrame = CreateFrame("Frame", "MythicPlusCountProgressBar", UIParent, "BackdropTemplate")
    barFrame:SetSize(width, height)
    barFrame:SetPoint("TOP", UIParent, "TOP", 0, -150)
    barFrame:SetFrameStrata("MEDIUM")

    barFrame:SetMovable(true)
    barFrame:EnableMouse(true)
    barFrame:SetClampedToScreen(true)
    barFrame:RegisterForDrag("LeftButton")
    barFrame:SetScript("OnDragStart", function(f)
        if not MPC.db.progressBar.locked then f:StartMoving() end
    end)
    barFrame:SetScript("OnDragStop", function(f)
        f:StopMovingOrSizing()
        local point, _, relPoint, x, y = f:GetPoint()
        MPC.db.progressBar.point = { point, relPoint, x, y }
    end)

    unlockGlow = barFrame:CreateTexture(nil, "OVERLAY", nil, 7)
    unlockGlow:SetPoint("TOPLEFT", -2, 2)
    unlockGlow:SetPoint("BOTTOMRIGHT", 2, -2)
    unlockGlow:SetColorTexture(0.2, 0.8, 1.0, 0.35)
    unlockGlow:Hide()

    barFrame.unlockLabel = barFrame:CreateFontString(nil, "OVERLAY")
    barFrame.unlockLabel:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
    barFrame.unlockLabel:SetPoint("BOTTOM", barFrame, "TOP", 0, 2)
    barFrame.unlockLabel:SetText("|cFF66CCFFProgress Bar - drag to move|r")
    barFrame.unlockLabel:Hide()

    completionGlow = barFrame:CreateTexture(nil, "OVERLAY", nil, 6)
    completionGlow:SetPoint("TOPLEFT", -3, 3)
    completionGlow:SetPoint("BOTTOMRIGHT", 3, -3)
    completionGlow:SetColorTexture(1.0, 0.85, 0.0, 0.5)
    completionGlow:Hide()

    local fadeAnim = completionGlow:CreateAnimationGroup()
    local fadeIn = fadeAnim:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(0)
    fadeIn:SetToAlpha(0.6)
    fadeIn:SetDuration(0.3)
    fadeIn:SetOrder(1)
    local hold = fadeAnim:CreateAnimation("Alpha")
    hold:SetFromAlpha(0.6)
    hold:SetToAlpha(0.6)
    hold:SetDuration(1.5)
    hold:SetOrder(2)
    local fadeOut = fadeAnim:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(0.6)
    fadeOut:SetToAlpha(0)
    fadeOut:SetDuration(1.0)
    fadeOut:SetOrder(3)
    fadeAnim:SetScript("OnFinished", function() completionGlow:Hide() end)
    barFrame.completionFadeAnim = fadeAnim

    local innerWidth = width - 6
    local innerHeight = height - 6

    local gc = db.greenColor or { r = 0.1, g = 0.7, b = 0.1 }
    local yc = db.yellowColor or { r = 0.9, g = 0.8, b = 0.1 }
    local oc = db.overflowColor or { r = 0.9, g = 0.2, b = 0.2 }

    -- Use StatusBar frames so LSM bar textures render properly (fill left-to-right)
    -- Layer order: bg (always full) → yellow → green → overflow → text
    local baseLevel = barFrame:GetFrameLevel()

    -- Background bar: always at 100%, dark tint of selected texture
    bgBar = CreateFrame("StatusBar", nil, barFrame)
    bgBar:SetPoint("TOPLEFT", barFrame, "TOPLEFT", 3, -3)
    bgBar:SetSize(innerWidth, innerHeight)
    bgBar:SetMinMaxValues(0, 100)
    bgBar:SetValue(100)
    bgBar:SetFrameLevel(baseLevel + 1)

    yellowBar = CreateFrame("StatusBar", nil, barFrame)
    yellowBar:SetPoint("TOPLEFT", barFrame, "TOPLEFT", 3, -3)
    yellowBar:SetSize(innerWidth, innerHeight)
    yellowBar:SetMinMaxValues(0, 100)
    yellowBar:SetValue(0)
    yellowBar:SetFrameLevel(baseLevel + 2)

    greenBar = CreateFrame("StatusBar", nil, barFrame)
    greenBar:SetPoint("TOPLEFT", barFrame, "TOPLEFT", 3, -3)
    greenBar:SetSize(innerWidth, innerHeight)
    greenBar:SetMinMaxValues(0, 100)
    greenBar:SetValue(0)
    greenBar:SetFrameLevel(baseLevel + 3)

    overflowBar = CreateFrame("StatusBar", nil, barFrame)
    overflowBar:SetPoint("TOPLEFT", barFrame, "TOPLEFT", 3, -3)
    overflowBar:SetSize(innerWidth, innerHeight)
    overflowBar:SetMinMaxValues(0, 100)
    overflowBar:SetValue(0)
    overflowBar:SetReverseFill(true)
    overflowBar:SetFrameLevel(baseLevel + 4)
    overflowBar:Hide()

    self:ApplyTexture(bgBar, 0.15, 0.15, 0.15)
    self:ApplyTexture(greenBar, gc.r, gc.g, gc.b)
    self:ApplyTexture(yellowBar, yc.r, yc.g, yc.b)
    self:ApplyTexture(overflowBar, oc.r, oc.g, oc.b)

    -- Milestone marker overlay (between bar layers and text)
    milestoneOverlay = CreateFrame("Frame", nil, barFrame)
    milestoneOverlay:SetAllPoints(barFrame)
    milestoneOverlay:SetFrameLevel(baseLevel + 5)

    for i = 1, MILESTONE_POOL_SIZE do
        local line = milestoneOverlay:CreateTexture(nil, "OVERLAY")
        line:Hide()
        milestoneLines[i] = line
        local lbl = milestoneOverlay:CreateFontString(nil, "OVERLAY")
        lbl:SetFont("Fonts\\FRIZQT__.TTF", 7, "OUTLINE")
        lbl:Hide()
        milestoneLabels[i] = lbl
    end

    -- Text overlay needs to be above all StatusBar layers and milestones
    local textOverlay = CreateFrame("Frame", nil, barFrame)
    textOverlay:SetAllPoints(barFrame)
    textOverlay:SetFrameLevel(baseLevel + 6)

    local fontSize = db.fontSize or 10
    local fontPath = MPC.Nameplates:GetBarFont()
    barText = textOverlay:CreateFontString(nil, "OVERLAY")
    if not pcall(barText.SetFont, barText, fontPath, fontSize, "OUTLINE") then
        barText:SetFont("Fonts\\FRIZQT__.TTF", fontSize, "OUTLINE")
    end
    barText:SetPoint("CENTER", barFrame, "CENTER")
    barText:SetTextColor(1, 1, 1, 1)

    self:ApplyBorder()
    barFrame:Hide()
    self:RestorePosition()
    self:UpdateLock()
end

function ProgressBar:RestorePosition()
    if not barFrame then return end
    local pos = MPC.db and MPC.db.progressBar and MPC.db.progressBar.point
    if pos then
        barFrame:ClearAllPoints()
        barFrame:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
    else
        barFrame:ClearAllPoints()
        barFrame:SetPoint("TOP", UIParent, "TOP", 0, -150)
    end
end

function ProgressBar:UpdateLock()
    if not barFrame then return end
    local locked = MPC.db.progressBar.locked
    if unlockGlow then unlockGlow:SetShown(not locked) end
    if barFrame.unlockLabel then barFrame.unlockLabel:SetShown(not locked) end
    if not locked and MPC.db.progressBar.enabled then
        barFrame:Show()
    else
        self:Update()
    end
end

function ProgressBar:ApplyTexture(bar, r, g, b)
    local texPath = self:GetBarTexturePath()
    bar:SetStatusBarTexture(texPath)
    bar:SetStatusBarColor(r, g, b, 0.9)
end

function ProgressBar:ApplyBorder()
    if not barFrame then return end
    local db = MPC.db.progressBar
    if db.borderEnabled then
        local edgePath = FetchBorderTexture(db.borderTexture)
        barFrame:SetBackdrop({
            edgeFile = edgePath,
            edgeSize = 8,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        local bc = db.borderColor or { r = 0.3, g = 0.3, b = 0.3, a = 0.8 }
        barFrame:SetBackdropBorderColor(bc.r, bc.g, bc.b, bc.a or 0.8)
    else
        barFrame:SetBackdrop(nil)
    end
end

function ProgressBar:ApplyStyle()
    if not barFrame then return end
    local db = MPC.db.progressBar
    local gc = db.greenColor or { r = 0.1, g = 0.7, b = 0.1 }
    local yc = db.yellowColor or { r = 0.9, g = 0.8, b = 0.1 }
    local oc = db.overflowColor or { r = 0.9, g = 0.2, b = 0.2 }
    self:ApplyTexture(bgBar, 0.15, 0.15, 0.15)
    self:ApplyTexture(greenBar, gc.r, gc.g, gc.b)
    self:ApplyTexture(yellowBar, yc.r, yc.g, yc.b)
    self:ApplyTexture(overflowBar, oc.r, oc.g, oc.b)
    self:ApplyBorder()
    local fontPath = MPC.Nameplates:GetBarFont()
    local ok = pcall(barText.SetFont, barText, fontPath, db.fontSize or 10, "OUTLINE")
    if not ok then
        barText:SetFont("Fonts\\FRIZQT__.TTF", db.fontSize or 10, "OUTLINE")
    end
    self:Update()
end

function ProgressBar:ApplySize()
    if not barFrame then return end
    local db = MPC.db.progressBar
    barFrame:SetSize(db.width or 220, db.height or 18)
    local innerW = (db.width or 220) - 6
    local innerH = (db.height or 18) - 6
    bgBar:SetSize(innerW, innerH)
    greenBar:SetSize(innerW, innerH)
    yellowBar:SetSize(innerW, innerH)
    overflowBar:SetSize(innerW, innerH)
    self:ApplyStyle()
end

function ProgressBar:ResetCompletionGlow()
    hasShownCompletionGlow = false
    if completionGlow then completionGlow:Hide() end
end

function ProgressBar:Update()
    if not barFrame or not MPC.db then return end

    if not MPC.db.progressBar.enabled then
        barFrame:Hide()
        return
    end

    -- Edit Mode: always show for repositioning
    if inEditMode then
        self:RenderBar()
        barFrame:Show()
        return
    end

    -- Unlocked: always show for positioning, regardless of M+ state
    if not MPC.db.progressBar.locked then
        self:RenderBar()
        barFrame:Show()
        return
    end

    -- Locked: check M+ visibility
    if not MPC.Util:IsInMythicPlus() then
        if MPC.db.developerMode then
            -- Developer mode: show everywhere
        elseif MPC.db.nameplates.onlyInMythicPlus then
            barFrame:Hide()
            return
        elseif not MPC.db.showOutsideMPlus and not MPC.Util:GetCurrentMapID() then
            barFrame:Hide()
            return
        end
    end

    self:RenderBar()
    barFrame:Show()
end

function ProgressBar:RenderBar()
    local db = MPC.db.progressBar
    local innerWidth = (db.width or 220) - 6

    -- completedPct = confirmed forces from scenario API (grows as mobs die)
    -- pullPct = total estimated forces in this combat (alive mobs + killed delta)
    -- basePct = forces BEFORE combat started (fixed)
    --
    -- Green = completedPct (grows in real-time as mobs die)
    -- Yellow = remaining pull estimate (alive mobs not yet dead)
    -- Total = max(completedPct, basePct + pullPct)
    local completedPct = MPC.Util:GetCompletedPercent()
    local pullPct = MPC.PullTracker:GetCurrentPullPercent()
    local basePct = MPC.PullTracker:GetBasePct()

    -- During combat: green = confirmed killed, yellow = estimated alive remainder
    -- The yellow portion is what pullPct predicts BEYOND what's already confirmed
    local yellowPct = 0
    local totalPct = completedPct
    if pullPct > 0 then
        local predictedTotal = basePct + pullPct
        yellowPct = math.max(predictedTotal - completedPct, 0)
        totalPct = math.max(completedPct, predictedTotal)
    end

    -- Green fills from 0 to completedPct (capped at 100)
    local greenVal = math.min(completedPct, 100)

    -- Yellow fills from 0 to (completedPct + yellowPct), layered behind green
    -- so only the portion beyond green is visible
    local yellowVal = 0
    if completedPct < 100 and yellowPct > 0 then
        yellowVal = math.min(completedPct + yellowPct, 100)
    end

    -- Overflow: fills right-to-left from the right edge
    local overflowVal = 0
    if totalPct > 100 and db.showOverflow then
        overflowVal = math.min(totalPct - 100, 10) / 10 * 100
    end

    greenBar:SetValue(greenVal)
    greenBar:SetShown(greenVal > 0)

    -- Yellow is drawn behind green (same anchor) showing the predicted portion
    yellowBar:SetValue(yellowVal)
    yellowBar:SetShown(yellowVal > greenVal)

    if overflowVal > 0 and db.showOverflow then
        overflowBar:SetValue(overflowVal)
        overflowBar:Show()
    else
        overflowBar:SetValue(0)
        overflowBar:Hide()
    end

    if totalPct >= 100 and not hasShownCompletionGlow and pullPct > 0 then
        hasShownCompletionGlow = true
        completionGlow:Show()
        if barFrame.completionFadeAnim then
            barFrame.completionFadeAnim:Play()
        end
    end

    if db.showText then
        local decimals = MPC.db.pull and MPC.db.pull.decimals or 2
        local fmt = "%." .. decimals .. "f%%"
        if yellowPct > 0 then
            -- Show: confirmed% (+remaining estimate%) = total%
            barText:SetText(string.format(
                fmt .. " |cFFE6CC1A(+" .. fmt .. ")|r = " .. fmt,
                completedPct, yellowPct, totalPct
            ))
        else
            barText:SetText(string.format(fmt, completedPct))
        end
        if totalPct >= 100 then
            barText:SetTextColor(1, 0.85, 0, 1)
        else
            barText:SetTextColor(1, 1, 1, 1)
        end
    else
        barText:SetText("")
    end

    self:RenderMilestones()
end

function ProgressBar:RenderMilestones()
    -- Hide all first
    for i = 1, MILESTONE_POOL_SIZE do
        milestoneLines[i]:Hide()
        milestoneLabels[i]:Hide()
    end

    local db = MPC.db.progressBar
    local ms = db.milestones
    if not ms or not ms.enabled then return end

    local mapID = MPC.Util:GetCurrentMapID()
    if not mapID then return end

    -- Merge default milestones (if enabled) with user-configured ones
    local entries = {}
    local seenPct = {}
    if ms.showDefaults then
        local defaults = MPC.Data.DEFAULT_MILESTONES and MPC.Data.DEFAULT_MILESTONES[mapID]
        if defaults then
            for _, d in ipairs(defaults) do
                entries[#entries + 1] = d
                seenPct[d.pct] = true
            end
        end
    end
    local userEntries = ms.dungeons and ms.dungeons[mapID]
    if userEntries then
        for _, u in ipairs(userEntries) do
            if not seenPct[u.pct] then
                entries[#entries + 1] = u
                seenPct[u.pct] = true
            end
        end
    end
    if #entries == 0 then return end
    table.sort(entries, function(a, b) return a.pct < b.pct end)

    local baseColor = ms.color or { r = 1, g = 1, b = 1, a = 0.8 }
    local doneColor = ms.completionColor or { r = 0.3, g = 0.85, b = 0.4, a = 0.8 }
    local completedPct = MPC.Util:GetCompletedPercent()
    local innerWidth = (db.width or 220) - 6
    local innerHeight = (db.height or 18) - 6

    for i = 1, math.min(#entries, MILESTONE_POOL_SIZE) do
        local entry = entries[i]
        local pct = entry.pct
        if pct and pct > 0 and pct < 100 then
            local reached = completedPct >= pct
            local color = reached and doneColor or baseColor

            local xPos = 3 + (pct / 100) * innerWidth
            local line = milestoneLines[i]
            line:ClearAllPoints()
            line:SetPoint("TOPLEFT", barFrame, "TOPLEFT", xPos - 0.5, -2)
            line:SetSize(1.5, innerHeight + 1)
            line:SetColorTexture(color.r, color.g, color.b, color.a or 0.8)
            line:Show()

            if ms.showLabels then
                local lbl = milestoneLabels[i]
                local lblSize = ms.labelFontSize or 7
                local lblFont = ms.labelFont or "Friz Quadrata TT"
                local fontPath = MPC.Nameplates:GetFontPath(lblFont)
                if not pcall(lbl.SetFont, lbl, fontPath, lblSize, "OUTLINE") then
                    lbl:SetFont("Fonts\\FRIZQT__.TTF", lblSize, "OUTLINE")
                end
                lbl:ClearAllPoints()
                lbl:SetPoint("BOTTOM", line, "TOP", 0, 1)

                local text = ""
                local hasLabel = entry.label and entry.label ~= ""
                if hasLabel and ms.showPercent then
                    text = string.format("%g%% %s", pct, entry.label)
                elseif hasLabel then
                    text = entry.label
                else
                    text = string.format("%g%%", pct)
                end
                lbl:SetText(text)

                local lc = ms.labelColor or baseColor
                lbl:SetTextColor(lc.r, lc.g, lc.b, lc.a or 0.9)
                lbl:Show()
            end
        end
    end
end

local bootFrame = CreateFrame("Frame")
bootFrame:RegisterEvent("PLAYER_LOGIN")
bootFrame:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_LOGIN")

    local ef = CreateFrame("Frame")
    ef:RegisterEvent("SCENARIO_CRITERIA_UPDATE")
    ef:RegisterEvent("SCENARIO_UPDATE")
    ef:RegisterEvent("CHALLENGE_MODE_START")
    ef:RegisterEvent("CHALLENGE_MODE_COMPLETED")
    ef:RegisterEvent("CHALLENGE_MODE_RESET")

    ef:SetScript("OnEvent", function(_, event)
        if event == "CHALLENGE_MODE_START" then
            ProgressBar:ResetCompletionGlow()
        end
        if event == "CHALLENGE_MODE_COMPLETED" or event == "CHALLENGE_MODE_RESET" then
            ProgressBar:ResetCompletionGlow()
            ProgressBar:Update()
        else
            C_Timer.After(0.1, function() ProgressBar:Update() end)
        end
    end)

    C_Timer.NewTicker(1.0, function()
        if MPC.Util and MPC.Util.IsInMythicPlus then
            if MPC.Util:IsInMythicPlus() or (MPC.db and MPC.db.showOutsideMPlus) then
                ProgressBar:Update()
            end
        end
    end)

    -- LibEditMode integration (optional)
    ProgressBar:RegisterWithEditMode()
end)

function ProgressBar:RegisterWithEditMode()
    local LEM = LibStub and LibStub("LibEditMode", true)
    if not LEM or not LEM.AddFrame then return end

    -- Register progress bar frame
    if barFrame then
        local barDefault = { point = "TOP", x = 0, y = -150 }
        LEM:AddFrame(barFrame, function(frame)
            local point, _, relPoint, x, y = frame:GetPoint()
            if MPC.db then
                MPC.db.progressBar.point = { point, relPoint, x, y }
            end
        end, barDefault, "MPC Progress Bar")
        MPC:Debug("LibEditMode: registered Progress Bar")
    end

    -- Register pull tracker frame
    local pullFrame = _G["MythicPlusCountPullFrame"]
    if pullFrame then
        local pullDefault = { point = "TOP", x = 0, y = -180 }
        LEM:AddFrame(pullFrame, function(frame)
            local point, _, relPoint, x, y = frame:GetPoint()
            if MPC.db then
                MPC.db.pullFrame.point = { point, relPoint, x, y }
            end
        end, pullDefault, "MPC Pull Tracker")
        MPC:Debug("LibEditMode: registered Pull Tracker")
    end

    -- When entering Edit Mode, show frames for positioning
    LEM:RegisterCallback("enter", function()
        inEditMode = true
        if barFrame and MPC.db.progressBar.enabled then barFrame:Show() end
        if pullFrame and MPC.db.pull.enabled then pullFrame:Show() end
    end)

    -- When exiting Edit Mode, restore normal visibility
    LEM:RegisterCallback("exit", function()
        inEditMode = false
        ProgressBar:Update()
        if MPC.PullTracker and MPC.PullTracker.UpdateDisplay then
            MPC.PullTracker:UpdateDisplay()
        end
    end)
end
