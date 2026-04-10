-- MythicPlusCount - Blizzard Nameplates Adapter
-- Simple FontString overlay on the nameplate.
-- Uses shared anchor/formatting from MPC.Nameplates.
local ADDON_NAME, NS = ...
local MPC = NS.MPC

local Blizzard = {}
MPC.Adapters = MPC.Adapters or {}
MPC.Adapters.Blizzard = Blizzard

local overlays = {}  -- [nameplate] = FontString

function Blizzard:IsAvailable() return true end
function Blizzard:Init() end

function Blizzard:OnNameplateAdded(unitToken)
    local nameplate = C_NamePlate.GetNamePlateForUnit(unitToken)
    if not nameplate then return end
    local info = MPC.Util:GetMobInfoForUnit(unitToken)
    if not info or info.count == 0 then
        -- Don't hide if overlay is already showing (fingerprint may have failed temporarily)
        if not overlays[nameplate] or not overlays[nameplate]:IsShown() then return end
        return
    end
    self:ShowOverlay(nameplate, info)
end

function Blizzard:OnNameplateRemoved(unitToken)
    local nameplate = C_NamePlate.GetNamePlateForUnit(unitToken)
    if nameplate then self:HideOverlay(nameplate) end
end

function Blizzard:GetOrCreateOverlay(nameplate)
    if overlays[nameplate] then return overlays[nameplate] end
    local fs = nameplate:CreateFontString(nil, "OVERLAY")
    overlays[nameplate] = fs
    return fs
end

function Blizzard:ApplyStyle(fs, nameplate)
    local db = MPC.db.nameplates
    fs:SetFont(MPC.Nameplates:GetFont(), db.fontSize or 9, "OUTLINE")
    local c = db.fontColor or { r = 0.2, g = 1.0, b = 0.6, a = 1.0 }
    fs:SetTextColor(c.r, c.g, c.b, c.a)

    fs:ClearAllPoints()
    local pt, relPt, ox, oy = MPC.Nameplates:GetAnchorInfo()
    if nameplate.UnitFrame and nameplate.UnitFrame.healthBar then
        fs:SetPoint(pt, nameplate.UnitFrame.healthBar, relPt, ox, oy)
    else
        fs:SetPoint(pt, nameplate, relPt, ox, oy)
    end
end

function Blizzard:ShowOverlay(nameplate, info)
    local fs = self:GetOrCreateOverlay(nameplate)
    self:ApplyStyle(fs, nameplate)
    fs:SetText(MPC.Nameplates:FormatOverlayText(info))
    fs:Show()
end

function Blizzard:HideOverlay(nameplate)
    local fs = overlays[nameplate]
    if fs then fs:Hide() end
end
