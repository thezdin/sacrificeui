-- MythicPlusCount - Nameplates
-- Core nameplate management: detects provider, delegates to adapters.
-- Also contains shared anchor/formatting code used by all adapters.
local ADDON_NAME, NS = ...
local MPC = NS.MPC

local Nameplates = {}
MPC.Nameplates = Nameplates

local activeAdapter = nil

Nameplates.ANCHOR_MAP = {
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

local DEFAULT_FONT = "Fonts\\FRIZQT__.TTF"
local DEFAULT_FONT_NAME = "Friz Quadrata TT"

-- Get LibSharedMedia reference (cached)
local LSM
local function GetLSM()
    if LSM == nil then
        LSM = LibStub and LibStub("LibSharedMedia-3.0", true) or false
    end
    return LSM
end

-- Build font list for dropdowns: SharedMedia names (not paths)
-- Stored as { label = "Font Name" } — the name IS the key
Nameplates.FONTS = {}
do
    local lsm = GetLSM()
    if lsm then
        local mediaFonts = lsm:HashTable("font")
        if mediaFonts then
            for name in pairs(mediaFonts) do
                Nameplates.FONTS[#Nameplates.FONTS + 1] = { label = name }
            end
        end
    end
    -- Always ensure default is available
    if #Nameplates.FONTS == 0 then
        Nameplates.FONTS[1] = { label = DEFAULT_FONT_NAME }
    end
    table.sort(Nameplates.FONTS, function(a, b) return a.label:lower() < b.label:lower() end)
end

-- Resolve a font name to a file path at render time via LSM:Fetch
-- Stores/reads SharedMedia NAMES (like Plater does), not file paths
local function FetchFont(name)
    if not name or name == "" then return DEFAULT_FONT end
    local lsm = GetLSM()
    if lsm then
        local path = lsm:Fetch("font", name)
        if path then return path end
    end
    -- Legacy: if it's already a file path, use directly
    if name:find("\\") or name:find("/") then return name end
    return DEFAULT_FONT
end

function Nameplates:GetFont()
    return FetchFont(MPC.db.nameplates.font)
end

function Nameplates:GetBarFont()
    return FetchFont(MPC.db.progressBar.font)
end

function Nameplates:GetFontPath(name)
    return FetchFont(name)
end

function Nameplates:GetAnchorInfo()
    local db = MPC.db.nameplates
    local placement = MPC.db.nameplates_placement or "outside"

    if placement == "inside" then
        return "CENTER", "CENTER", db.offsetX or 0, db.offsetY or 0
    end

    local key = db.anchor or "BOTTOM"
    local a = self.ANCHOR_MAP[key] or self.ANCHOR_MAP["BOTTOM"]
    local ox = (db.offsetX or 0) + a.xMul * 2
    local oy = (db.offsetY or 2) + a.yMul * 2
    return a.point, a.relPoint, ox, oy
end

function Nameplates:FormatOverlayText(info)
    local db = MPC.db.nameplates
    if db.showCount and db.showPercent then
        return string.format("%d | %s", info.count,
            MPC.Util:FormatPercent(info.percent, MPC.db.tooltip.decimals))
    elseif db.showCount then
        return tostring(info.count)
    else
        return MPC.Util:FormatPercent(info.percent, MPC.db.tooltip.decimals)
    end
end

function Nameplates:Init()
    C_Timer.After(2, function() self:DetectAdapter() end)
end

function Nameplates:DetectAdapter()
    if not MPC.db then return end
    local provider = MPC.db.nameplates.provider

    if provider == "plater" or (provider == "auto" and MPC.Adapters.Plater and MPC.Adapters.Plater:IsAvailable()) then
        activeAdapter = MPC.Adapters.Plater
        MPC:Debug("Nameplate adapter: Plater")
    elseif provider == "elvui" or (provider == "auto" and MPC.Adapters.ElvUI and MPC.Adapters.ElvUI:IsAvailable()) then
        activeAdapter = MPC.Adapters.ElvUI
        MPC:Debug("Nameplate adapter: ElvUI")
    elseif provider == "platynator" or (provider == "auto" and MPC.Adapters.Platynator and MPC.Adapters.Platynator:IsAvailable()) then
        activeAdapter = MPC.Adapters.Platynator
        MPC:Debug("Nameplate adapter: Platynator")
    elseif provider == "ryoui" or (provider == "auto" and MPC.Adapters.RyoUI and MPC.Adapters.RyoUI:IsAvailable()) then
        activeAdapter = MPC.Adapters.RyoUI
        MPC:Debug("Nameplate adapter: RyoUI")
    elseif provider == "threatplates" or (provider == "auto" and MPC.Adapters.ThreatPlates and MPC.Adapters.ThreatPlates:IsAvailable()) then
        activeAdapter = MPC.Adapters.ThreatPlates
        MPC:Debug("Nameplate adapter: ThreatPlates")
    else
        activeAdapter = MPC.Adapters.Blizzard
        MPC:Debug("Nameplate adapter: Blizzard (default)")
    end

    if activeAdapter and activeAdapter.Init then
        activeAdapter:Init()
    end
    self:RefreshAll()
end

function Nameplates:OnNameplateAdded(unitToken)
    local shouldShow = true

    if not MPC.db or not MPC.db.nameplates.enabled then
        shouldShow = false
    elseif MPC.db.developerMode then
        -- Developer mode: always show (for teaching/testing)
        shouldShow = true
    elseif MPC.db.nameplates.onlyInMythicPlus and not MPC.Util:IsInMythicPlus() then
        shouldShow = false
    elseif not MPC.Util:IsInMythicPlus() and not MPC.db.showOutsideMPlus and not MPC.Util:GetCurrentMapID() then
        shouldShow = false
    end

    if not shouldShow then
        if activeAdapter and activeAdapter.OnNameplateRemoved then
            activeAdapter:OnNameplateRemoved(unitToken)
        end
        return
    end

    MPC.Util:GetMobInfoForUnit(unitToken)

    if activeAdapter and activeAdapter.OnNameplateAdded then
        activeAdapter:OnNameplateAdded(unitToken)
    end

    if MPC.PullTracker and MPC.PullTracker.OnNameplateAdded then
        MPC.PullTracker:OnNameplateAdded(unitToken)
    end

end

function Nameplates:OnNameplateRemoved(unitToken)
    if activeAdapter and activeAdapter.OnNameplateRemoved then
        activeAdapter:OnNameplateRemoved(unitToken)
    end
end

function Nameplates:RefreshAll()
    if not MPC.db then return end
    for i = 1, 40 do
        local unitToken = "nameplate" .. i
        if UnitExists(unitToken) then
            self:OnNameplateAdded(unitToken)
        end
    end
end

function Nameplates:GetActiveAdapterName()
    if activeAdapter == MPC.Adapters.Plater then return "Plater"
    elseif activeAdapter == MPC.Adapters.ElvUI then return "ElvUI"
    elseif activeAdapter == MPC.Adapters.Platynator then return "Platynator"
    elseif activeAdapter == MPC.Adapters.RyoUI then return "RyoUI"
    elseif activeAdapter == MPC.Adapters.ThreatPlates then return "ThreatPlates"
    else return "Blizzard"
    end
end

local bootFrame = CreateFrame("Frame")
bootFrame:RegisterEvent("PLAYER_LOGIN")
bootFrame:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_LOGIN")
    local ef = CreateFrame("Frame")
    ef:RegisterEvent("NAME_PLATE_UNIT_ADDED")
    ef:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
    ef:RegisterEvent("PLAYER_ENTERING_WORLD")
    ef:SetScript("OnEvent", function(_, event, ...)
        if event == "NAME_PLATE_UNIT_ADDED" then
            Nameplates:OnNameplateAdded(...)
        elseif event == "NAME_PLATE_UNIT_REMOVED" then
            Nameplates:OnNameplateRemoved(...)
        elseif event == "PLAYER_ENTERING_WORLD" then
            C_Timer.After(1, function() Nameplates:DetectAdapter() end)
        end
    end)

    -- Periodic refresh: picks up nameplates that failed initial identification.
    -- Only runs when in a dungeon or showing outside M+.
    C_Timer.NewTicker(3.0, function()
        if not MPC.db then return end
        if MPC.Util:GetCurrentMapID() or MPC.db.showOutsideMPlus then
            Nameplates:RefreshAll()
        end
    end)
end)
