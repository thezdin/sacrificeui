-- SacrificeUI M+ Enemy Forces Counter
-- Shows each mob's enemy forces % on tooltips and nameplates in Mythic+ dungeons.
-- Mob data lives in MythicCountData.lua.
--
-- To find an NPC ID in-game, target or mouseover the mob and run:
--   /run print(select(6, strsplit("-", UnitGUID("mouseover"))))

-- ============================================================
-- Helpers
-- ============================================================

local function IsEnabled()
    return SacrificeUIDB and SacrificeUIDB.mythicCountEnabled
end

local function GetNPCID(unit)
    local guid = unit and UnitGUID(unit)
    if not guid then return nil end
    local unitType, _, _, _, _, npcID = strsplit("-", guid)
    if unitType ~= "Creature" and unitType ~= "Vehicle" then return nil end
    return tonumber(npcID)
end

local function GetMobData(unit)
    local npcID = GetNPCID(unit)
    if not npcID then return nil end
    return SacrificeUI.MobCount and SacrificeUI.MobCount[npcID]
end

-- ============================================================
-- Tooltip injection
-- ============================================================

GameTooltip:HookScript("OnTooltipSetUnit", function(self)
    if not IsEnabled() then return end
    local _, unit = self:GetUnit()
    if not unit then return end
    local data = GetMobData(unit)
    if not data then return end
    self:AddLine(" ")
    self:AddDoubleLine(
        "|cFFAAAAAA[M+] Enemy Forces|r",
        string.format("|cFFFF8800%.2f%%|r", data.pct),
        0.85, 0.85, 0.85, 1, 0.53, 0
    )
    self:Show()
end)

-- ============================================================
-- Nameplate injection
-- ============================================================

local activePlates = {}  -- unit -> fontstring

local function RefreshPlate(unit)
    local plate = C_NamePlate and C_NamePlate.GetNamePlateForUnit(unit)
    if not plate then return end

    local data = IsEnabled() and GetMobData(unit)

    if not data then
        local fs = activePlates[unit]
        if fs then fs:Hide() end
        return
    end

    local fs = activePlates[unit]
    if not fs then
        local anchor = (plate.UnitFrame and plate.UnitFrame.healthBar) or plate
        fs = plate:CreateFontString(nil, "OVERLAY")
        fs:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        fs:SetPoint("BOTTOM", anchor, "TOP", 0, 4)
        activePlates[unit] = fs
    end

    fs:SetText(string.format("|cFFFF8800%.2f%%|r", data.pct))
    fs:Show()
end

local plateFrame = CreateFrame("Frame")
plateFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
plateFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
plateFrame:SetScript("OnEvent", function(_, event, unit)
    if event == "NAME_PLATE_UNIT_REMOVED" then
        activePlates[unit] = nil
        return
    end
    RefreshPlate(unit)
end)

-- ============================================================
-- Public API (called from toggle checkbox)
-- ============================================================

function SacrificeUI:RefreshMythicCount()
    -- Re-evaluate every active nameplate when the setting changes
    if C_NamePlate and C_NamePlate.GetNamePlates then
        for _, plate in pairs(C_NamePlate.GetNamePlates()) do
            local unit = plate.namePlateUnitToken
            if unit then
                if IsEnabled() then
                    RefreshPlate(unit)
                else
                    local fs = activePlates[unit]
                    if fs then fs:Hide() end
                end
            end
        end
    end
end
