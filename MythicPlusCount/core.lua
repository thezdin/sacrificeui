-- MythicPlusCount - Core
-- Addon initialization, saved variables, event dispatch, slash commands
local ADDON_NAME, NS = ...

-- Global addon table exposed through namespace
local MPC = {}
NS.MPC = MPC
MPC.NS = NS

MPC.VERSION = "1.2.0"

MPC.Data = {}
MPC.Util = {}
MPC.Tooltip = {}
MPC.Nameplates = {}
MPC.PullTracker = {}
MPC.ProgressBar = {}
MPC.Options = {}
MPC.Adapters = {}

local DEFAULTS = {
    tooltip = {
        enabled = true,
        showCount = false,
        showPercent = true,
        decimals = 2,
    },
    nameplates = {
        enabled = true,
        provider = "auto",
        showCount = false,
        showPercent = true,
        onlyInMythicPlus = true,
        fontSize = 9,
        font = "Friz Quadrata TT",
        fontColor = { r = 0.2, g = 1.0, b = 0.6, a = 1.0 },
        anchor = "BOTTOM",
        anchorTo = "TOP",
        offsetX = 0,
        offsetY = 2,
    },
    pull = {
        enabled = false,
        decimals = 2,
        showFrame = true,
        showBackground = false,
        width = 160,
        height = 24,
        fontSize = 11,
    },
    progressBar = {
        enabled = true,
        locked = true,
        width = 220,
        height = 18,
        fontSize = 10,
        font = "Friz Quadrata TT",
        showText = true,
        showOverflow = true,
        greenColor = { r = 0.1, g = 0.7, b = 0.1 },
        yellowColor = { r = 0.9, g = 0.8, b = 0.1 },
        overflowColor = { r = 0.9, g = 0.2, b = 0.2 },
        barTexture = "Blizzard",
        borderEnabled = true,
        borderColor = { r = 0.3, g = 0.3, b = 0.3, a = 0.8 },
        borderTexture = "Blizzard Tooltip",
        bgAlpha = 0.8,
        milestones = {
            enabled = false,
            showDefaults = true,
            color = { r = 1.0, g = 1.0, b = 1.0, a = 0.8 },
            completionColor = { r = 0.3, g = 0.85, b = 0.4, a = 0.8 },
            showLabels = false,
            showPercent = false,
            labelFontSize = 7,
            labelColor = { r = 1.0, g = 1.0, b = 1.0, a = 0.9 },
            labelFont = "Friz Quadrata TT",
            dungeons = {},  -- [mapID] = { { pct = 60, label = "Boss 2" }, ... }
        },
        point = nil,
    },
    pullFrame = {
        point = nil,
    },
    showOutsideMPlus = false,   -- show forces data outside M+ (for route planning)
    developerMode = false,      -- debug output, probe tools, Debug tab
    optionsPanelScale = 100,
    modelMap = {},       -- legacy: { [mapID] = { ["m:fileID"] = npcID } }
    fingerprints = {},   -- { [mapID] = { [fingerprintString] = npcID } }
    nameplates_placement = "outside",  -- "outside" or "inside" the health bar
    minimap = { enabled = true, minimapPos = 220 },
    extras = {},
}

local function DeepCopy(src)
    if type(src) ~= "table" then return src end
    local copy = {}
    for k, v in pairs(src) do
        copy[k] = DeepCopy(v)
    end
    return copy
end

local function MergeDefaults(target, defaults)
    for k, v in pairs(defaults) do
        if type(v) == "table" then
            if type(target[k]) ~= "table" then
                target[k] = {}
            end
            MergeDefaults(target[k], v)
        elseif target[k] == nil then
            target[k] = v
        end
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name == ADDON_NAME then
            if not MythicPlusCountDB then
                MythicPlusCountDB = DeepCopy(DEFAULTS)
            else
                MergeDefaults(MythicPlusCountDB, DEFAULTS)
            end
            MPC.db = MythicPlusCountDB

            if MPC.Tooltip.Init then MPC.Tooltip:Init() end
            if MPC.Nameplates.Init then MPC.Nameplates:Init() end
            if MPC.PullTracker.Init then MPC.PullTracker:Init() end
            if MPC.ProgressBar.Init then MPC.ProgressBar:Init() end
            if MPC.MinimapButton and MPC.MinimapButton.Init then MPC.MinimapButton:Init() end
            if MPC.Extras and MPC.Extras.Init then MPC.Extras:Init() end
            if MPC.Options.Init then MPC.Options:Init() end

            MPC:Debug("Addon loaded, v" .. MPC.VERSION)
            self:UnregisterEvent("ADDON_LOADED")
        end

    elseif event == "PLAYER_ENTERING_WORLD" then
        MPC.Util:UpdateDungeonState()
    end
end)

function MPC:Debug(...)
    if not self.db or not self.db.developerMode then return end
    local msg = "|cFF00CCFF[MPC Debug]|r"
    for i = 1, select("#", ...) do
        msg = msg .. " " .. tostring(select(i, ...))
    end
    print(msg)
end

function MPC:Print(...)
    local msg = "|cFF33FF99[MythicPlusCount]|r"
    for i = 1, select("#", ...) do
        msg = msg .. " " .. tostring(select(i, ...))
    end
    print(msg)
end

function MPC:SetLocked(locked)
    self.db.progressBar.locked = locked
    if self.ProgressBar.UpdateLock then self.ProgressBar:UpdateLock() end
    if self.PullTracker.UpdateLock then self.PullTracker:UpdateLock() end
    if locked then
        self:Debug("Frames locked.")
    else
        self:Debug("Frames unlocked - drag to reposition.")
    end
end

SLASH_MYTHICPLUSCOUNT1 = "/mforces"
SLASH_MYTHICPLUSCOUNT2 = "/mpc"

SlashCmdList["MYTHICPLUSCOUNT"] = function(input)
    local cmd = (input or ""):trim():lower()

    if cmd == "" or cmd == "config" or cmd == "options" then
        MPC.Options:Toggle()

    elseif cmd == "lock" then
        MPC:SetLocked(true)

    elseif cmd == "unlock" then
        MPC:SetLocked(false)

    elseif cmd == "reset" then
        MPC.db.progressBar.point = nil
        MPC.db.pullFrame.point = nil
        if MPC.ProgressBar.RestorePosition then MPC.ProgressBar:RestorePosition() end
        if MPC.PullTracker.RestorePosition then MPC.PullTracker:RestorePosition() end
        MPC:Debug("Frame positions reset.")

    elseif cmd == "debug" then
        MPC.db.developerMode = not MPC.db.developerMode
        MPC:Print("Developer mode:", MPC.db.developerMode and "|cFF44FF44ON|r" or "|cFFFF4444OFF|r")
        if MPC.db.developerMode then
            MPC:PrintDebugInfo()
        end

    elseif cmd:match("^teach") or cmd:match("^id ") or cmd:match("^identify") then
        local mobName = cmd:match("^teach%s+(.+)$") or cmd:match("^id%s+(.+)$") or cmd:match("^identify%s+(.+)$")

        if not UnitExists("target") then
            MPC:Print("Target a mob first, then /mpc teach")
            return
        end

        local mapID = MPC.Util:GetCurrentMapID()
        if not mapID then
            MPC:Print("Not in a recognized dungeon.")
            return
        end

        local fingerprint = MPC.Util:GetFingerprint("target")
        if not fingerprint then
            MPC:Print("Could not read fingerprint for your target.")
            return
        end

        if not mobName or mobName == "" then
            MPC:ShowTeachPicker(mapID, fingerprint)
            return
        end

        MPC:TeachMob(mapID, fingerprint, mobName)

    elseif cmd == "export" then
        local mapID = MPC.Util:GetCurrentMapID()
        if not mapID then
            MPC:Print("Not in a recognized dungeon. Export works per-dungeon.")
            return
        end
        local dungeon = MPC.Data:GetDungeon(mapID)
        local fpMap = MPC.db.fingerprints and MPC.db.fingerprints[mapID]
        if not fpMap then
            MPC:Print("No fingerprint data for this dungeon yet.")
            return
        end
        MPC.Options:Show()
        MPC.Options:DebugClear()
        MPC.Options:DebugWrite("-- Fingerprints for " .. (dungeon and dungeon.name or "map " .. mapID))
        MPC.Options:DebugWrite("-- Paste this into data.lua fingerprints section")
        MPC.Options:DebugWrite(string.format("[%d] = {", mapID))
        local sorted = {}
        for fp, npcID in pairs(fpMap) do
            local info = MPC.Util:GetMobInfo(npcID)
            sorted[#sorted+1] = { fp = fp, npcID = npcID, name = info and info.name or "?", count = info and info.count or 0 }
        end
        table.sort(sorted, function(a, b) return a.name < b.name end)
        for _, entry in ipairs(sorted) do
            MPC.Options:DebugWrite(string.format('    ["%s"] = %d, -- %s (%d)',
                entry.fp, entry.npcID, entry.name, entry.count))
        end
        MPC.Options:DebugWrite("},")
        MPC:Print(string.format("Exported %d fingerprints for %s. Check the Debug tab (Ctrl+A, Ctrl+C to copy).",
            #sorted, dungeon and dungeon.name or "map " .. mapID))

    elseif cmd == "cleardata" or cmd == "wipe" then
        local mapID = MPC.Util:GetCurrentMapID()
        if not mapID then
            MPC:Print("Not in a recognized dungeon.")
            return
        end
        local dungeon = MPC.Data:GetDungeon(mapID)
        local name = dungeon and dungeon.name or tostring(mapID)
        if MPC.db.fingerprints then MPC.db.fingerprints[mapID] = nil end
        if MPC.db.modelMap then MPC.db.modelMap[mapID] = nil end
        MPC:Debug(string.format("Cleared learned data for %s.", name))
        MPC.Nameplates:RefreshAll()

    elseif cmd == "mobs" or cmd == "list" then
        local mapID = MPC.Util:GetCurrentMapID()
        if not mapID then
            MPC:Print("Not in a recognized dungeon.")
            return
        end
        local dungeon = MPC.Data:GetDungeon(mapID)
        if not dungeon then
            MPC:Print("No data for map " .. mapID)
            return
        end

        local knownNpcs = MPC:CountKnownMobs(mapID)

        MPC:Print("|cFFFFCC00" .. dungeon.name .. " - Model Status:|r")
        local known, total = 0, 0
        local sorted = {}
        for npcID, mob in pairs(dungeon.mobs) do
            if mob.count > 0 then
                sorted[#sorted+1] = { npcID = npcID, name = mob.name, count = mob.count, known = knownNpcs[npcID] }
            end
        end
        table.sort(sorted, function(a, b) return a.name < b.name end)
        for _, entry in ipairs(sorted) do
            total = total + 1
            if entry.known then
                known = known + 1
                MPC:Print(string.format("  |cFF44FF44+|r %s (count %d)", entry.name, entry.count))
            else
                MPC:Print(string.format("  |cFFFF4444-|r %s (count %d, |cFFFF4444NOT LEARNED|r)", entry.name, entry.count))
            end
        end
        MPC:Print(string.format("  |cFFFFCC00%d/%d|r mob types known", known, total))

    elseif cmd == "scan" then
        local mapID = MPC.Util:GetCurrentMapID()
        if not mapID then
            MPC:Print("Not in a M+ dungeon. Enter a dungeon first.")
            return
        end
        local learned = 0
        for i = 1, 40 do
            local unit = "nameplate" .. i
            if UnitExists(unit) then
                local guid = UnitGUID(unit)
                local npcID = nil
                if guid and not (issecretvalue and issecretvalue(guid)) then
                    npcID = MPC.Util:GetNpcIDFromGUID(guid)
                end
                if npcID then
                    local fp = MPC.Util:GetFingerprint(unit)
                    if fp then MPC.Util:SaveFingerprint(fp, npcID, MPC.Util:GetExtendedFingerprint(unit)) end
                    local info = MPC.Util:GetMobInfo(npcID)
                    learned = learned + 1
                    MPC:Print(string.format("  Learned: %s (npcID %d, model %s)",
                        info and info.name or "?", npcID,
                        tostring(MPC.Util:GetModelFileID(unit) or "?")))
                else
                    local modelNpc = MPC.Util:GetNpcIDFromFingerprint(unit) or MPC.Util:GetNpcIDFromModelMap(unit)
                    if modelNpc then
                        MPC:Print(string.format("  Already known: npcID %d (model)", modelNpc))
                    else
                        local fileID = MPC.Util:GetModelFileID(unit)
                        MPC:Print(string.format("  Unknown mob (model %s) - need to learn outside instance",
                            tostring(fileID or "?")))
                    end
                end
            end
        end
        local totalKnown = 0
        if MPC.db.modelMap and MPC.db.modelMap[mapID] then
            for _ in pairs(MPC.db.modelMap[mapID]) do totalKnown = totalKnown + 1 end
        end
        MPC:Print(string.format("Scan complete. Learned %d new. Total known models for map %d: %d",
            learned, mapID, totalKnown))

    elseif cmd:match("^test") then
        local arg = cmd:match("^test%s+(.+)$")
        if arg == "off" or arg == "stop" or arg == "clear" then
            MPC.Util:ClearSimulation()
            MPC.db.showOutsideMPlus = false
            MPC:Print("Test mode |cFFFF4444OFF|r.")
            MPC.ProgressBar:Update()
            MPC.PullTracker:UpdateDisplay()
        else
            MPC.db.showOutsideMPlus = true
            local pct = tonumber(arg)
            if not pct then
                local current = MPC.Util:IsSimulating() and MPC.Util:GetCompletedPercent() or 0
                if current < 30 then pct = 45
                elseif current < 60 then pct = 72
                elseif current < 90 then pct = 89
                else pct = 0
                end
            end
            MPC.Util:SetSimulatedPercent(pct)
            MPC:Print(string.format("Test mode |cFF44FF44ON|r. Simulated completed: |cFFFFCC00%.1f%%|r", pct))
            MPC:Print("  Tooltip/nameplate data works on any dungeon mob (debug mode).")
            MPC:Print("  Use |cFFFFFFFF/mpc test off|r to stop.")
            MPC.ProgressBar:Update()
        end

    else
        MPC:Print("|cFFFFCC00Commands:|r")
        MPC:Print("  |cFFFFFFFF/mpc|r - open settings panel")
        MPC:Print("  |cFFFFFFFF/mpc teach|r - teach a mob (target first)")
        MPC:Print("  |cFFFFFFFF/mpc mobs|r - list known/unknown mobs")
        MPC:Print("  |cFFFFFFFF/mpc lock|r / |cFFFFFFFF/mpc unlock|r - lock/unlock frames")
        MPC:Print("  |cFFFFFFFF/mpc reset|r - reset frame positions")
    end
end

function MPC:TeachMob(mapID, fingerprint, mobName)
    local customName, customCount = mobName:match("^(.+)%s+(%d+)$")

    local npcID = MPC.Util:GetNpcIDFromName(mobName)

    if not npcID and customName then
        npcID = MPC.Util:GetNpcIDFromName(customName)
    end

    if not npcID and customName and customCount then
        local count = tonumber(customCount)
        local dungeon = MPC.Data:GetDungeon(mapID)
        if dungeon and count then
            -- Negative to avoid collisions with real npcIDs
            local customID = -(math.floor(math.random() * 100000) + 1)
            dungeon.mobs[customID] = {
                name = customName,
                count = count,
                percent = (dungeon.totalForces > 0) and (count / dungeon.totalForces * 100) or 0,
            }
            npcID = customID
            MPC:Print(string.format("|cFFFFCC00Custom mob added:|r %s with %d forces", customName, count))
        end
    end

    if not npcID then
        MPC:Print("|cFFFF4444'" .. mobName .. "'|r not found in dungeon data.")
        MPC:Print("To add a custom mob: |cFFFFFFFF/mpc teach Mob Name COUNT|r")
        MPC:Print("  Example: |cFFFFFFFF/mpc teach Outcast Warrior 3|r")
        MPC:Print("Or use |cFFFFFFFF/mpc teach|r (no name) to pick from the list.")
        return
    end

    local extFP = MPC.Util:GetExtendedFingerprint("target")
    MPC.Util:SaveFingerprint(fingerprint, npcID, extFP)

    -- Intentionally NOT saving to modelMap: fingerprints are primary now.
    -- Model-only maps cause shared-model mobs to all show the same value.

    local info = MPC.Util:GetMobInfo(npcID)
    MPC:Debug(string.format("Learned: %s (forces: %d = %.2f%%) fp: %s",
        info and info.name or mobName,
        info and info.count or 0, info and info.percent or 0, fingerprint))

    local knownNpcs = self:CountKnownMobs(mapID)
    local total = 0
    local dungeon = MPC.Data:GetDungeon(mapID)
    if dungeon then
        for _, mob in pairs(dungeon.mobs) do
            if mob.count > 0 then total = total + 1 end
        end
    end
    local known = 0
    for _ in pairs(knownNpcs) do known = known + 1 end
    MPC:Debug(string.format("Progress: %d/%d mob types learned", known, total))

    MPC.Nameplates:RefreshAll()
end

function MPC:CountKnownMobs(mapID)
    local knownNpcs = {}
    -- From fingerprint map
    if MPC.db.fingerprints and MPC.db.fingerprints[mapID] then
        for _, npcID in pairs(MPC.db.fingerprints[mapID]) do
            knownNpcs[npcID] = true
        end
    end
    -- From legacy model map
    if MPC.db.modelMap and MPC.db.modelMap[mapID] then
        for _, npcID in pairs(MPC.db.modelMap[mapID]) do
            if npcID > 0 then knownNpcs[npcID] = true end
        end
    end
    return knownNpcs
end

local teachPickerFrame = nil

function MPC:ShowTeachPicker(mapID, fingerprint)
    local dungeon = MPC.Data:GetDungeon(mapID)
    if not dungeon then return end

    local fpMap = MPC.db.fingerprints and MPC.db.fingerprints[mapID]
    local currentFpKnown = fpMap and fpMap[fingerprint]

    local knownNpcs = self:CountKnownMobs(mapID)

    local unlearned = {}
    local seen = {}
    for npcID, mob in pairs(dungeon.mobs) do
        if mob.count > 0 and not seen[mob.name] then
            -- Show if: npcID not known at all, OR current fingerprint not mapped yet
            if not knownNpcs[npcID] or not currentFpKnown then
                unlearned[#unlearned+1] = { npcID = npcID, name = mob.name, count = mob.count }
                seen[mob.name] = true
            end
        end
    end
    table.sort(unlearned, function(a, b) return a.name < b.name end)

    if #unlearned == 0 then
        MPC:Print("All fingerprints for this dungeon are already learned!")
        return
    end

    if teachPickerFrame then
        teachPickerFrame:Hide()
        for _, child in ipairs({teachPickerFrame.content:GetChildren()}) do
            child:Hide()
            child:SetParent(nil)
        end
    else
        teachPickerFrame = CreateFrame("Frame", "MythicPlusCountTeachPicker", UIParent, "BackdropTemplate")
        teachPickerFrame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        teachPickerFrame:SetBackdropColor(0.08, 0.08, 0.10, 0.95)
        teachPickerFrame:SetBackdropBorderColor(0.3, 0.7, 1.0, 0.8)
        teachPickerFrame:SetMovable(true)
        teachPickerFrame:EnableMouse(true)
        teachPickerFrame:RegisterForDrag("LeftButton")
        teachPickerFrame:SetScript("OnDragStart", teachPickerFrame.StartMoving)
        teachPickerFrame:SetScript("OnDragStop", teachPickerFrame.StopMovingOrSizing)
        teachPickerFrame:SetFrameStrata("DIALOG")
        teachPickerFrame:SetClampedToScreen(true)

        local title = teachPickerFrame:CreateFontString(nil, "OVERLAY")
        title:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
        title:SetPoint("TOP", 0, -8)
        title:SetTextColor(0.3, 0.7, 1.0, 1)
        title:SetText("What mob is this? (click one)")
        teachPickerFrame.title = title

        -- Close button
        local closeBtn = CreateFrame("Button", nil, teachPickerFrame)
        closeBtn:SetSize(20, 20)
        closeBtn:SetPoint("TOPRIGHT", -4, -4)
        local closeTxt = closeBtn:CreateFontString(nil, "OVERLAY")
        closeTxt:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
        closeTxt:SetPoint("CENTER")
        closeTxt:SetTextColor(0.6, 0.6, 0.6)
        closeTxt:SetText("x")
        closeBtn:SetScript("OnClick", function() teachPickerFrame:Hide() end)
        closeBtn:SetScript("OnEnter", function() closeTxt:SetTextColor(1, 0.3, 0.3) end)
        closeBtn:SetScript("OnLeave", function() closeTxt:SetTextColor(0.6, 0.6, 0.6) end)

        teachPickerFrame.content = CreateFrame("Frame", nil, teachPickerFrame)
        teachPickerFrame.content:SetPoint("TOPLEFT", 8, -28)
    end

    local btnHeight = 22
    local padding = 36
    local width = 260
    local height = padding + #unlearned * btnHeight + 8
    teachPickerFrame:SetSize(width, math.min(height, 400))
    teachPickerFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
    teachPickerFrame.content:SetSize(width - 16, #unlearned * btnHeight)

    for i, entry in ipairs(unlearned) do
        local btn = CreateFrame("Button", nil, teachPickerFrame.content, "BackdropTemplate")
        btn:SetSize(width - 20, btnHeight - 2)
        btn:SetPoint("TOPLEFT", 0, -(i - 1) * btnHeight)
        btn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
        })
        btn:SetBackdropColor(0.12, 0.12, 0.14, 1)

        local label = btn:CreateFontString(nil, "OVERLAY")
        label:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        label:SetPoint("LEFT", 8, 0)
        label:SetTextColor(0.85, 0.85, 0.85)
        label:SetText(string.format("%s  |cFF888888(%d = %.1f%%)|r",
            entry.name, entry.count, entry.count / dungeon.totalForces * 100))

        btn:SetScript("OnEnter", function(self)
            self:SetBackdropColor(0.2, 0.5, 0.8, 0.4)
        end)
        btn:SetScript("OnLeave", function(self)
            self:SetBackdropColor(0.12, 0.12, 0.14, 1)
        end)
        btn:SetScript("OnClick", function()
            teachPickerFrame:Hide()
            MPC:TeachMob(mapID, fingerprint, entry.name)
        end)
    end

    teachPickerFrame:Show()
    if not teachPickerFrame.addedToSpecialFrames then
        tinsert(UISpecialFrames, "MythicPlusCountTeachPicker")
        teachPickerFrame.addedToSpecialFrames = true
    end
end

function MPC:PrintDebugInfo()
    local mapID = MPC.Util:GetCurrentMapID()
    local instanceName = GetInstanceInfo()
    local inMP = MPC.Util:IsInMythicPlus()

    self:Print("--- Debug Info ---")
    self:Print("  Challenge Map ID:", mapID or "none")
    self:Print("  Instance:", instanceName or "none")
    self:Print("  In Mythic+:", tostring(inMP))

    if UnitExists("target") then
        self:Print("  --- Target Probe ---")

        local rawGuid = UnitGUID("target")
        local guidIsSecret = rawGuid and issecretvalue and issecretvalue(rawGuid)
        self:Print("    UnitGUID:", guidIsSecret and "(SECRET)" or (rawGuid or "nil"))

        local safeGuid = MPC.Util:SafeUnitGUID("target")
        self:Print("    SafeUnitGUID:", safeGuid or "nil")

        local np = C_NamePlate.GetNamePlateForUnit("target")
        if np then
            self:Print("    Has nameplate: yes")
            local npKeys = {}
            for k, v in pairs(np) do
                if type(v) ~= "function" and type(v) ~= "table" then
                    local isSecret = issecretvalue and issecretvalue(v)
                    npKeys[#npKeys + 1] = string.format("%s=%s", tostring(k), isSecret and "(SECRET)" or tostring(v))
                elseif type(v) == "table" then
                    npKeys[#npKeys + 1] = tostring(k) .. "=(table)"
                end
            end
            self:Print("    np keys:", table.concat(npKeys, ", "))

            if np.UnitFrame then
                self:Print("    Has np.UnitFrame: yes")
                local ufKeys = {}
                for k, v in pairs(np.UnitFrame) do
                    if type(v) ~= "function" and type(v) ~= "table" then
                        local isSecret = issecretvalue and issecretvalue(v)
                        ufKeys[#ufKeys + 1] = string.format("%s=%s", tostring(k), isSecret and "(SECRET)" or tostring(v))
                    elseif type(v) == "table" then
                        ufKeys[#ufKeys + 1] = tostring(k) .. "=(table)"
                    end
                end
                self:Print("    UF keys:", table.concat(ufKeys, ", "))
            end
        else
            self:Print("    Has nameplate: no (target a mob with visible nameplate)")
        end

        local unitName = UnitName("target")
        local nameIsSecret = unitName and issecretvalue and issecretvalue(unitName)
        self:Print("    UnitName:", nameIsSecret and "(SECRET)" or (unitName or "nil"))

        if C_TooltipInfo and C_TooltipInfo.GetUnit then
            local ok, tipData = pcall(C_TooltipInfo.GetUnit, "target")
            if ok and tipData then
                self:Print("    C_TooltipInfo.GetUnit: got data")
                if tipData.guid then
                    local tipGuidSecret = issecretvalue and issecretvalue(tipData.guid)
                    self:Print("      tipData.guid:", tipGuidSecret and "(SECRET)" or tostring(tipData.guid))
                    if not tipGuidSecret then
                        local tipNpcID = MPC.Util:GetNpcIDFromGUID(tipData.guid)
                        self:Print("      Parsed NPC ID:", tipNpcID or "nil")
                    end
                end
                local tipKeys = {}
                for k, v in pairs(tipData) do
                    if type(v) ~= "table" and type(v) ~= "function" then
                        local s = issecretvalue and issecretvalue(v)
                        tipKeys[#tipKeys + 1] = string.format("%s=%s", tostring(k), s and "(SECRET)" or tostring(v))
                    end
                end
                self:Print("      tipData keys:", table.concat(tipKeys, ", "))
            else
                self:Print("    C_TooltipInfo.GetUnit: failed or nil")
            end
        end

        local npcID = MPC.Util:GetNpcIDFromUnit("target")
        self:Print("    GetNpcIDFromUnit:", npcID or "nil")

        if npcID then
            local info = MPC.Util:GetMobInfo(npcID)
            if info then
                self:Print("    Forces:", info.count, string.format("(%.2f%%)", info.percent))
            else
                self:Print("    Forces: NPC ID", npcID, "NOT in data table for mapID", mapID or "?")
            end
        end
    else
        self:Print("  No target (target a mob and try again)")
    end

    local completed = MPC.Util:GetCompletedPercent()
    local pullPct = MPC.PullTracker:GetCurrentPullPercent()
    local predicted = completed + pullPct
    self:Print("  Completed:", string.format("%.2f%%", completed))
    self:Print("  Pull:", string.format("%.2f%%", pullPct))
    self:Print("  Predicted:", string.format("%.2f%%", predicted))
    self:Print("--- End Debug ---")
end
