-- MythicPlusCount - Plater Adapter
-- Simple FontString overlay on the nameplate.
-- Uses shared anchor/formatting from MPC.Nameplates.
local ADDON_NAME, NS = ...
local MPC = NS.MPC

local Plater = {}
MPC.Adapters = MPC.Adapters or {}
MPC.Adapters.Plater = Plater

local overlays = {}

function Plater:IsAvailable() return _G.Plater ~= nil end
function Plater:Init() MPC:Debug("Plater adapter initialized") end

function Plater:OnNameplateAdded(unitToken)
    if not self:IsAvailable() then return end
    local nameplate = C_NamePlate.GetNamePlateForUnit(unitToken)
    if not nameplate then return end
    local info = MPC.Util:GetMobInfoForUnit(unitToken)
    if not info or info.count == 0 then
        if not overlays[nameplate] or not overlays[nameplate]:IsShown() then return end
        return
    end
    self:ShowOverlay(nameplate, info)
end

function Plater:OnNameplateRemoved(unitToken)
    local nameplate = C_NamePlate.GetNamePlateForUnit(unitToken)
    if nameplate then self:HideOverlay(nameplate) end
end

function Plater:GetOrCreateOverlay(nameplate)
    if overlays[nameplate] then return overlays[nameplate] end
    local fs = nameplate:CreateFontString(nil, "OVERLAY")
    overlays[nameplate] = fs
    return fs
end

function Plater:ShowOverlay(nameplate, info)
    local fs = self:GetOrCreateOverlay(nameplate)
    local db = MPC.db.nameplates
    fs:SetFont(MPC.Nameplates:GetFont(), db.fontSize or 9, "OUTLINE")
    local c = db.fontColor or { r = 0.2, g = 1.0, b = 0.6, a = 1.0 }
    fs:SetTextColor(c.r, c.g, c.b, c.a)

    fs:ClearAllPoints()
    local pt, relPt, ox, oy = MPC.Nameplates:GetAnchorInfo()
    -- Plater uses unitFrame (lowercase) instead of UnitFrame
    local anchor = nameplate
    local platerUnit = nameplate.unitFrame or nameplate.UnitFrame
    if platerUnit and platerUnit.healthBar then
        anchor = platerUnit.healthBar
    end
    fs:SetPoint(pt, anchor, relPt, ox, oy)

    fs:SetText(MPC.Nameplates:FormatOverlayText(info))
    fs:Show()
end

function Plater:HideOverlay(nameplate)
    local fs = overlays[nameplate]
    if fs then fs:Hide() end
end
