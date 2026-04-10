-- MythicPlusCount - Pull Tracker
-- Tracks current pull forces by monitoring scenario quantity changes.
--
-- MIDNIGHT (12.0) REALITY:
-- All NPC identification APIs return Secret Values inside M+ instances.
-- We track forces by watching C_ScenarioInfo quantity changes:
--   - Record completed count at the START of combat
--   - During combat, the delta = current - start = forces gained so far
--   - When combat ends, reset for the next pull
-- This gives "pull result %" rather than "pull prediction %",
-- but it's the ONLY data available in Midnight M+.
local ADDON_NAME, NS = ...
local MPC = NS.MPC

local issecretvalue = issecretvalue or function() return false end

local PullTracker = {}
MPC.PullTracker = PullTracker

-- State for delta-based pull tracking
local combatStartQuantity = 0   -- raw quantity at start of combat
local combatStartTotal = 0      -- totalQuantity at start of combat
local lastKnownQuantity = 0     -- most recent readable quantity
local lastKnownTotal = 0        -- most recent readable totalQuantity
local inCombat = false

local pullFrame, pullText, unlockGlow

function PullTracker:Init()
    self:CreatePullFrame()
end

function PullTracker:ReadScenarioForces()
    local rawCount, total = MPC.Util:ReadEnemyForcesRaw()
    if total > 0 then
        return rawCount, total
    end
    return nil, nil
end

function PullTracker:OnEnterCombat()
    inCombat = true
    local qty, total = self:ReadScenarioForces()
    if qty and total then
        combatStartQuantity = qty
        combatStartTotal = total
        lastKnownQuantity = qty
        lastKnownTotal = total
        MPC:Debug("Pull started. Forces at start:", qty, "/", total)
    end
    self:UpdateDisplay()
end

function PullTracker:OnLeaveCombat()
    -- Delay to let final scenario updates come through
    C_Timer.After(0.5, function()
        local qty, total = self:ReadScenarioForces()
        if qty and total then
            lastKnownQuantity = qty
            lastKnownTotal = total
            local gained = qty - combatStartQuantity
            if gained > 0 and combatStartTotal > 0 then
                local gainedPct = (gained / combatStartTotal) * 100
                MPC:Debug(string.format("Pull ended. Gained: %d forces (%.2f%%)", gained, gainedPct))
            end
        end
        inCombat = false
        self:UpdateDisplay()
        C_Timer.After(3, function()
            if not inCombat then
                combatStartQuantity = lastKnownQuantity
                self:UpdateDisplay()
            end
        end)
    end)
end

-- Two sources combined:
--   1. Scenario delta: forces already gained from kills in this combat
--   2. Nameplate scan: sum forces of alive in-combat mobs with known fingerprints
-- No double-counting: scenario delta = DEAD mobs, nameplate scan = ALIVE mobs
function PullTracker:GetCurrentPullPercent()
    if not inCombat then return 0 end
    local total = lastKnownTotal or 0
    if total <= 0 then
        local _, t = self:ReadScenarioForces()
        total = t or 0
    end
    if total <= 0 then return 0 end

    local pullCount = self:GetCurrentPullCount()
    return (pullCount / total) * 100
end

function PullTracker:GetCurrentPullCount()
    if not inCombat then return 0 end

    local killedCount = 0
    local qty, total = self:ReadScenarioForces()
    if qty then
        lastKnownQuantity = qty
        killedCount = qty - combatStartQuantity
        if killedCount < 0 then killedCount = 0 end
    end
    if total then lastKnownTotal = total end

    local aliveCount = 0
    for i = 1, 40 do
        local unit = "nameplate" .. i
        if UnitExists(unit) and not UnitIsDead(unit)
           and UnitCanAttack("player", unit) and UnitAffectingCombat(unit) then
            local info = MPC.Util:GetMobInfoForUnit(unit)
            if info and info.count > 0 then
                aliveCount = aliveCount + info.count
            end
        end
    end

    return killedCount + aliveCount
end

function PullTracker:GetScenarioDelta()
    local qty = self:ReadScenarioForces()
    if qty then
        local delta = qty - combatStartQuantity
        return delta > 0 and delta or 0
    end
    return 0
end

-- Forces % confirmed BEFORE this combat started (fixed during combat)
function PullTracker:GetBasePct()
    if combatStartTotal > 0 then
        return (combatStartQuantity / combatStartTotal) * 100
    end
    return MPC.Util:GetCompletedPercent()
end

function PullTracker:GetAliveMobCount()
    if not inCombat then return 0 end
    local count = 0
    for i = 1, 40 do
        local unit = "nameplate" .. i
        if UnitExists(unit) and not UnitIsDead(unit)
           and UnitCanAttack("player", unit) and UnitAffectingCombat(unit) then
            count = count + 1
        end
    end
    return count
end

function PullTracker:Reset()
    local qty, total = self:ReadScenarioForces()
    if qty then
        combatStartQuantity = qty
        lastKnownQuantity = qty
    end
    if total then
        combatStartTotal = total
        lastKnownTotal = total
    end
    inCombat = false
    self:UpdateDisplay()
end

function PullTracker:CreatePullFrame()
    pullFrame = CreateFrame("Frame", "MythicPlusCountPullFrame", UIParent, "BackdropTemplate")
    local pullDb = MPC.db.pull
    pullFrame:SetSize(pullDb.width or 160, pullDb.height or 24)
    pullFrame:SetPoint("TOP", UIParent, "TOP", 0, -180)
    pullFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    pullFrame:SetBackdropColor(0, 0, 0, 0.7)
    pullFrame:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)

    pullFrame:SetMovable(true)
    pullFrame:EnableMouse(true)
    pullFrame:SetClampedToScreen(true)
    pullFrame:RegisterForDrag("LeftButton")
    pullFrame:SetScript("OnDragStart", function(f)
        if not MPC.db.progressBar.locked then f:StartMoving() end
    end)
    pullFrame:SetScript("OnDragStop", function(f)
        f:StopMovingOrSizing()
        local point, _, relPoint, x, y = f:GetPoint()
        MPC.db.pullFrame.point = { point, relPoint, x, y }
    end)

    unlockGlow = pullFrame:CreateTexture(nil, "OVERLAY", nil, 7)
    unlockGlow:SetPoint("TOPLEFT", -2, 2)
    unlockGlow:SetPoint("BOTTOMRIGHT", 2, -2)
    unlockGlow:SetColorTexture(0.2, 0.8, 1.0, 0.35)
    unlockGlow:Hide()

    pullFrame.unlockLabel = pullFrame:CreateFontString(nil, "OVERLAY")
    pullFrame.unlockLabel:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
    pullFrame.unlockLabel:SetPoint("BOTTOM", pullFrame, "TOP", 0, 2)
    pullFrame.unlockLabel:SetText("|cFF66CCFFPull Frame - drag to move|r")
    pullFrame.unlockLabel:Hide()

    pullText = pullFrame:CreateFontString(nil, "OVERLAY")
    if not pcall(pullText.SetFont, pullText, MPC.Nameplates:GetBarFont(), pullDb.fontSize or 11, "OUTLINE") then
        pullText:SetFont("Fonts\\FRIZQT__.TTF", pullDb.fontSize or 11, "OUTLINE")
    end
    pullText:SetPoint("CENTER")
    pullText:SetTextColor(1, 0.82, 0, 1)

    pullFrame:Hide()
    self:ApplyBackground()
    self:RestorePosition()
    self:UpdateLock()
end

function PullTracker:ApplySize()
    if not pullFrame then return end
    local pullDb = MPC.db.pull
    pullFrame:SetSize(pullDb.width or 160, pullDb.height or 24)
    if not pcall(pullText.SetFont, pullText, MPC.Nameplates:GetBarFont(), pullDb.fontSize or 11, "OUTLINE") then
        pullText:SetFont("Fonts\\FRIZQT__.TTF", pullDb.fontSize or 11, "OUTLINE")
    end
    self:ApplyBackground()
end

function PullTracker:ApplyBackground()
    if not pullFrame then return end
    if MPC.db.pull.showBackground then
        pullFrame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 8,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        pullFrame:SetBackdropColor(0, 0, 0, 0.7)
        pullFrame:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
    else
        pullFrame:SetBackdrop(nil)
    end
end

function PullTracker:RestorePosition()
    if not pullFrame then return end
    local pos = MPC.db and MPC.db.pullFrame and MPC.db.pullFrame.point
    if pos then
        pullFrame:ClearAllPoints()
        pullFrame:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
    else
        pullFrame:ClearAllPoints()
        pullFrame:SetPoint("TOP", UIParent, "TOP", 0, -180)
    end
end

function PullTracker:UpdateLock()
    if not pullFrame then return end
    local locked = MPC.db.progressBar.locked
    if unlockGlow then unlockGlow:SetShown(not locked) end
    if pullFrame.unlockLabel then pullFrame.unlockLabel:SetShown(not locked) end
    if not locked and MPC.db.pull.enabled then
        pullText:SetText("Pull: +0.00% (+0)")
        pullFrame:Show()
    else
        self:UpdateDisplay()
    end
end

function PullTracker:UpdateDisplay()
    if not pullFrame or not MPC.db then return end

    if not MPC.db.pull.enabled then
        pullFrame:Hide()
        if MPC.ProgressBar and MPC.ProgressBar.Update then MPC.ProgressBar:Update() end
        return
    end

    -- Unlocked: always show for positioning, regardless of M+ state
    if not MPC.db.progressBar.locked then
        pullText:SetText("Pull: +0.00% (+0)")
        pullFrame:Show()
        if MPC.ProgressBar and MPC.ProgressBar.Update then MPC.ProgressBar:Update() end
        return
    end

    -- Locked: check M+ visibility
    if not MPC.Util:IsInMythicPlus() then
        if MPC.db.developerMode then
            -- Developer mode: show everywhere
        elseif MPC.db.nameplates.onlyInMythicPlus then
            pullFrame:Hide()
            if MPC.ProgressBar and MPC.ProgressBar.Update then MPC.ProgressBar:Update() end
            return
        elseif not MPC.db.showOutsideMPlus and not MPC.Util:GetCurrentMapID() then
            pullFrame:Hide()
            if MPC.ProgressBar and MPC.ProgressBar.Update then MPC.ProgressBar:Update() end
            return
        end
    end

    local pullPct = self:GetCurrentPullPercent()
    local pullCount = self:GetCurrentPullCount()

    -- showFrame ON: always visible (shows 0 outside combat)
    -- showFrame OFF: only visible during active combat with data
    if not inCombat and pullPct <= 0 then
        if MPC.db.pull.showFrame then
            -- Show with idle text
            pullText:SetText("Pull: +0.00% (+0)")
            pullFrame:Show()
            if MPC.ProgressBar and MPC.ProgressBar.Update then MPC.ProgressBar:Update() end
            return
        else
            pullFrame:Hide()
            if MPC.ProgressBar and MPC.ProgressBar.Update then MPC.ProgressBar:Update() end
            return
        end
    end

    local decimals = MPC.db.pull.decimals or 2
    pullText:SetText(string.format("Pull: +%." .. decimals .. "f%% (+%d)", pullPct, pullCount))
    pullFrame:Show()
    if MPC.ProgressBar and MPC.ProgressBar.Update then MPC.ProgressBar:Update() end
end

local bootFrame = CreateFrame("Frame")
bootFrame:RegisterEvent("PLAYER_LOGIN")
bootFrame:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_LOGIN")

    local ef = CreateFrame("Frame")
    ef:RegisterEvent("PLAYER_REGEN_ENABLED")
    ef:RegisterEvent("PLAYER_REGEN_DISABLED")
    ef:RegisterEvent("SCENARIO_CRITERIA_UPDATE")
    ef:RegisterEvent("CHALLENGE_MODE_START")
    ef:RegisterEvent("CHALLENGE_MODE_COMPLETED")
    ef:RegisterEvent("CHALLENGE_MODE_RESET")

    ef:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_DISABLED" then
            PullTracker:OnEnterCombat()
        elseif event == "PLAYER_REGEN_ENABLED" then
            PullTracker:OnLeaveCombat()
        elseif event == "SCENARIO_CRITERIA_UPDATE" then
            PullTracker:UpdateDisplay()
        elseif event == "CHALLENGE_MODE_START" then
            PullTracker:Reset()
        elseif event == "CHALLENGE_MODE_COMPLETED" or event == "CHALLENGE_MODE_RESET" then
            PullTracker:Reset()
        end
    end)

    -- Periodic update while in combat (0.5s).
    -- SCENARIO_CRITERIA_UPDATE only fires on mob death; the 0.5s ticker
    -- is needed to refresh the alive-mob nameplate scan portion of the
    -- pull estimate. Only ticks when InCombatLockdown() is true.
    C_Timer.NewTicker(0.5, function()
        if InCombatLockdown() and (MPC.Util:IsInMythicPlus() or (MPC.db and MPC.db.showOutsideMPlus)) then
            PullTracker:UpdateDisplay()
        end
    end)
end)
