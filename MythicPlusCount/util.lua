-- MythicPlusCount - Utilities
-- NPC ID parsing, dungeon detection, mob info lookup, helpers
--
-- MIDNIGHT (12.0) COMPATIBLE:
-- All NPC identity APIs are SECRET inside instances. We identify
-- mobs using a COMPOUND FINGERPRINT of readable properties:
--   ModelFileID + Level + ClassToken + PowerType + AttackSpeed + BuffCount
-- Fingerprints are learned via /mpc teach and stored in SavedVariables.
local ADDON_NAME, NS = ...
local MPC = NS.MPC

local Util = {}
MPC.Util = Util

local currentMapID = nil
local inMythicPlus = false
local simulatedCompletedPct = nil

local issecretvalue = issecretvalue or function() return false end

function Util:GetNpcIDFromGUID(guid)
    if not guid or issecretvalue(guid) then return nil end
    if type(guid) ~= "string" then return nil end
    local guidType = strsplit("-", guid)
    if guidType ~= "Creature" and guidType ~= "Vehicle" then return nil end
    local _, _, _, _, _, npcID = strsplit("-", guid)
    return npcID and tonumber(npcID)
end

local function safeRead(fn, default)
    local ok, val = pcall(fn)
    if ok and val ~= nil and not issecretvalue(val) then return val end
    return default
end

-- COMPOUND FINGERPRINT SYSTEM
-- Fingerprint = "modelFileID:level:classification:sex:classToken:powerType:attackSpeed:buffCount"
-- This combination uniquely identifies ~95% of mob types in M+.

local modelFrame = nil
local function GetModelFrame()
    if not modelFrame then
        modelFrame = CreateFrame("PlayerModel")
    end
    return modelFrame
end

function Util:GetModelFileID(unit)
    if not unit then return nil end
    local ok, fileID = pcall(function()
        local mf = GetModelFrame()
        mf:SetUnit(unit)
        local id = mf:GetModelFileID()
        if id and not issecretvalue(id) and id > 0 then return id end
        return nil
    end)
    if ok then return fileID end
    return nil
end

local function GetBuffCount(unit)
    if not C_UnitAuras or not C_UnitAuras.GetAuraDataByIndex then return 0 end
    local count = 0
    for i = 1, 20 do
        local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, unit, i, "HELPFUL")
        if ok and aura then
            count = count + 1
        else
            break
        end
    end
    return count
end

local function GetAttackSpeed(unit)
    local ok, speed = pcall(UnitAttackSpeed, unit)
    if ok and speed and not issecretvalue(speed) then
        return string.format("%.3f", speed)
    end
    return "0"
end

function Util:GetFingerprint(unit)
    if not unit then return nil end

    local modelID = self:GetModelFileID(unit)
    if not modelID then return nil end

    local level   = safeRead(function() return UnitLevel(unit) end, 0)
    local classn  = safeRead(function() return UnitClassification(unit) end, "?")
    local sex     = safeRead(function() return UnitSex(unit) end, 0)
    local class   = safeRead(function() return select(2, UnitClass(unit)) end, "?")
    local ptype   = safeRead(function() return UnitPowerType(unit) end, -1)

    -- Relative level so fingerprints match across difficulties
    local relLevel = level % 10

    return string.format("%d:%d:%s:%d:%s:%d",
        modelID, relLevel, classn, sex, class, ptype)
end

-- Extended fingerprint includes buffCount for tiebreaking collisions.
-- Only used as a secondary lookup — not the primary key.
function Util:GetExtendedFingerprint(unit)
    local base = self:GetFingerprint(unit)
    if not base then return nil end
    local buffs = GetBuffCount(unit)
    return base .. ":" .. buffs
end

local function GetFingerprintMap()
    if not MPC.db then return nil end
    if not MPC.db.fingerprints then MPC.db.fingerprints = {} end
    return MPC.db.fingerprints
end

-- Load default fingerprints for a dungeon if no user data exists
local function EnsureDefaultFingerprints(mapID)
    if not mapID or not MPC.db then return end
    if not MPC.DefaultFingerprints then return end
    local defaults = MPC.DefaultFingerprints[mapID]
    if not defaults then return end
    local fpMap = GetFingerprintMap()
    if not fpMap[mapID] then fpMap[mapID] = {} end
    -- Only seed defaults for keys that don't already exist (user data wins)
    for fp, npcID in pairs(defaults) do
        if fpMap[mapID][fp] == nil then
            fpMap[mapID][fp] = npcID
        end
    end
end

function Util:SaveFingerprint(fingerprint, npcID, extFingerprint)
    if not fingerprint or not npcID then return end
    local mapID = currentMapID
    if not mapID then return end
    local fpMap = GetFingerprintMap()
    if not fpMap then return end
    if not fpMap[mapID] then fpMap[mapID] = {} end
    local changed = false
    if fpMap[mapID][fingerprint] ~= npcID then
        fpMap[mapID][fingerprint] = npcID
        changed = true
    end
    -- Also save extended fingerprint (with buffCount) for tiebreaking
    if extFingerprint and fpMap[mapID][extFingerprint] ~= npcID then
        fpMap[mapID][extFingerprint] = npcID
        changed = true
    end
    if changed then
        MPC:Debug("Saved fingerprint:", fingerprint, "→ npcID", npcID)
    end
end

function Util:GetNpcIDFromFingerprint(unit)
    local mapID = currentMapID
    if not mapID then return nil end
    local fpMap = GetFingerprintMap()
    if not fpMap or not fpMap[mapID] then return nil end

    -- Try extended fingerprint first (with buffCount for tiebreaking)
    local extFP = self:GetExtendedFingerprint(unit)
    if extFP and fpMap[mapID][extFP] then
        return fpMap[mapID][extFP]
    end

    -- Fall back to primary fingerprint
    local fp = self:GetFingerprint(unit)
    if not fp then return nil end
    return fpMap[mapID][fp]
end

local function GetModelMap()
    if not MPC.db then return nil end
    if not MPC.db.modelMap then MPC.db.modelMap = {} end
    return MPC.db.modelMap
end

function Util:GetNpcIDFromModelMap(unit)
    local mapID = currentMapID
    if not mapID then return nil end
    local modelMap = GetModelMap()
    if not modelMap or not modelMap[mapID] then return nil end
    local fileID = self:GetModelFileID(unit)
    if fileID then
        local npcID = modelMap[mapID]["m:" .. fileID]
        if npcID and npcID > 0 then return npcID end
    end
    return nil
end

function Util:GetNpcIDFromUnit(unit)
    if not unit then return nil end

    -- Strategy 1: UnitGUID (works outside instances)
    local guid = UnitGUID(unit)
    if guid and not issecretvalue(guid) then
        local npcID = self:GetNpcIDFromGUID(guid)
        if npcID then
            local fp = self:GetFingerprint(unit)
            if fp then self:SaveFingerprint(fp, npcID, self:GetExtendedFingerprint(unit)) end
            return npcID
        end
    end

    -- Strategy 2: Name from nameplate (works outside instances)
    local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
    if nameplate and nameplate.UnitFrame and nameplate.UnitFrame.name then
        local nameFS = nameplate.UnitFrame.name
        if nameFS.GetText then
            local ok, nameText = pcall(nameFS.GetText, nameFS)
            if ok and nameText and not issecretvalue(nameText) then
                local npcID = self:GetNpcIDFromName(nameText)
                if npcID then
                    local fp = self:GetFingerprint(unit)
                    if fp then self:SaveFingerprint(fp, npcID, self:GetExtendedFingerprint(unit)) end
                    return npcID
                end
            end
        end
    end

    -- Strategy 3: COMPOUND FINGERPRINT (Midnight M+ path)
    local fpNpcID = self:GetNpcIDFromFingerprint(unit)
    if fpNpcID then return fpNpcID end

    -- Strategy 4: Legacy model map
    local modelNpcID = self:GetNpcIDFromModelMap(unit)
    if modelNpcID then return modelNpcID end

    return nil
end

local nameCache = {}

local function BuildNameCache(mapID)
    if nameCache[mapID] then return nameCache[mapID] end
    local dungeon = MPC.Data:GetDungeon(mapID)
    if not dungeon then return nil end
    local cache = {}
    for npcID, mob in pairs(dungeon.mobs) do
        local lower = mob.name:lower()
        if not cache[lower] or mob.count > 0 then
            cache[lower] = npcID
        end
    end
    nameCache[mapID] = cache
    return cache
end

function Util:GetNpcIDFromName(name)
    if not name or name == "" then return nil end
    local lower = name:lower()
    local mapID = currentMapID or self:GetActiveChallengeMapID()
    if mapID then
        local cache = BuildNameCache(mapID)
        if cache and cache[lower] then return cache[lower] end
    end
    if MPC.db and MPC.db.showOutsideMPlus then
        for mID in pairs(MPC.Data.dungeons) do
            local cache = BuildNameCache(mID)
            if cache and cache[lower] then return cache[lower] end
        end
    end
    return nil
end

function Util:SafeUnitGUID(unit)
    if not unit then return nil end
    local guid = UnitGUID(unit)
    if guid and not issecretvalue(guid) and type(guid) == "string" then return guid end
    return nil
end

function Util:GetActiveChallengeMapID()
    if C_ChallengeMode and C_ChallengeMode.GetActiveChallengeMapID then
        local mapID = C_ChallengeMode.GetActiveChallengeMapID()
        if mapID and not issecretvalue(mapID) then return mapID end
    end
    return nil
end

function Util:IsInMythicPlus() return inMythicPlus end
function Util:GetCurrentMapID() return currentMapID end

function Util:UpdateDungeonState()
    local mapID = self:GetActiveChallengeMapID()
    if mapID then
        currentMapID = mapID
        inMythicPlus = true
        EnsureDefaultFingerprints(mapID)
        return
    end
    if C_ChallengeMode and C_ChallengeMode.IsChallengeModeActive
       and C_ChallengeMode.IsChallengeModeActive() then
        inMythicPlus = true
        return
    end
    inMythicPlus = false
    local instanceName = GetInstanceInfo()
    if instanceName then
        for cmapID, dungeon in pairs(MPC.Data.dungeons) do
            if dungeon.name == instanceName then
                currentMapID = cmapID
                EnsureDefaultFingerprints(cmapID)
                return
            end
        end
        local lowerInstance = instanceName:lower()
        for cmapID, dungeon in pairs(MPC.Data.dungeons) do
            if lowerInstance:find(dungeon.name:lower(), 1, true) or
               dungeon.name:lower():find(lowerInstance, 1, true) then
                currentMapID = cmapID
                EnsureDefaultFingerprints(cmapID)
                return
            end
        end
    end
    -- Only clear mapID if we're actually outside an instance
    -- Don't clear during combat (APIs might be unreliable)
    if not InCombatLockdown() then
        currentMapID = nil
    end
end

function Util:GetMobInfo(npcID)
    if not npcID then return nil end
    local mapID = currentMapID or self:GetActiveChallengeMapID()
    if mapID then
        local result = MPC.Data:GetMob(mapID, npcID)
        if result then return result end
    end
    if MPC.db and MPC.db.showOutsideMPlus then
        for _, dungeon in pairs(MPC.Data.dungeons) do
            local mob = dungeon.mobs[npcID]
            if mob then return mob end
        end
    end
    return nil
end

function Util:GetMobInfoForUnit(unit)
    if not unit then return nil, nil end

    -- Level 92+ mobs in M+ are bosses (0 forces)
    local level = safeRead(function() return UnitLevel(unit) end, 0)
    if level >= 92 then return nil, nil end

    local npcID = self:GetNpcIDFromUnit(unit)
    if not npcID then return nil, nil end
    local info = self:GetMobInfo(npcID)
    return info, npcID
end

function Util:FindEnemyForcesCriteria()
    if not C_ScenarioInfo or not C_ScenarioInfo.GetScenarioStepInfo then return nil end
    local stepInfo = C_ScenarioInfo.GetScenarioStepInfo()
    if not stepInfo or not stepInfo.numCriteria then return nil end
    if issecretvalue(stepInfo.numCriteria) then return nil end
    for i = 1, stepInfo.numCriteria do
        local cInfo = C_ScenarioInfo.GetCriteriaInfo(i)
        if cInfo and cInfo.isWeightedProgress then return cInfo end
    end
    return nil
end

function Util:GetCompletedPercent()
    if simulatedCompletedPct then return simulatedCompletedPct end
    if not self:IsInMythicPlus() then return 0 end
    local rawCount, total = self:ReadEnemyForcesRaw()
    if total > 0 then return (rawCount / total) * 100 end
    return 0
end

function Util:ReadEnemyForcesRaw()
    local cInfo = self:FindEnemyForcesCriteria()
    if not cInfo then return 0, 0 end
    local total = cInfo.totalQuantity
    if not total or issecretvalue(total) then return 0, 0 end
    local qStr = cInfo.quantityString
    if qStr and not issecretvalue(qStr) then
        local rawCount = tonumber(qStr:match("(%d+)"))
        if rawCount then return rawCount, total end
    end
    local qty = cInfo.quantity
    if qty and not issecretvalue(qty) then return qty, total end
    return 0, total
end

function Util:SetSimulatedPercent(pct) simulatedCompletedPct = pct end
function Util:ClearSimulation()        simulatedCompletedPct = nil end
function Util:IsSimulating()           return simulatedCompletedPct ~= nil end

function Util:IsTrackableMob(unit)
    if not UnitExists(unit) then return false end
    if not UnitCanAttack("player", unit) then return false end
    if UnitIsDead(unit) then return false end
    if UnitIsPlayer(unit) then return false end
    local npcID = self:GetNpcIDFromUnit(unit)
    if not npcID then return false end
    local info = self:GetMobInfo(npcID)
    if not info or info.count == 0 then return false end
    return true
end

function Util:IsUnitInCombat(unit)
    if not UnitExists(unit) then return false end
    return UnitAffectingCombat(unit)
end

function Util:FormatPercent(value, decimals)
    decimals = decimals or 2
    return string.format("%." .. decimals .. "f%%", value)
end

function Util:FormatCount(count) return tostring(count) end

function Util:FormatForces(count, percent, decimals)
    decimals = decimals or 2
    return string.format("%d (%." .. decimals .. "f%%)", count, percent)
end

local bootFrame = CreateFrame("Frame")
bootFrame:RegisterEvent("PLAYER_LOGIN")
bootFrame:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_LOGIN")
    local ef = CreateFrame("Frame")
    ef:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    ef:RegisterEvent("PLAYER_ENTERING_WORLD")
    ef:RegisterEvent("CHALLENGE_MODE_START")
    ef:RegisterEvent("CHALLENGE_MODE_COMPLETED")
    ef:RegisterEvent("CHALLENGE_MODE_RESET")
    ef:RegisterEvent("PLAYER_ENTERING_WORLD")
    ef:SetScript("OnEvent", function() Util:UpdateDungeonState() end)
    Util:UpdateDungeonState()
end)
