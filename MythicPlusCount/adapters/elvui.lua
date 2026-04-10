-- MythicPlusCount - ElvUI Adapter
-- FontString overlay for ElvUI nameplates.
local ADDON_NAME, NS = ...
local MPC = NS.MPC

local ElvUI = {}
MPC.Adapters = MPC.Adapters or {}
MPC.Adapters.ElvUI = ElvUI

local overlays = {}

function ElvUI:IsAvailable()
    return _G.ElvUI ~= nil
end

function ElvUI:Init()
    MPC:Debug("ElvUI adapter initialized")
end

function ElvUI:OnNameplateAdded(unitToken)
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

function ElvUI:OnNameplateRemoved(unitToken)
    local nameplate = C_NamePlate.GetNamePlateForUnit(unitToken)
    if nameplate then self:HideOverlay(nameplate) end
end

function ElvUI:GetOrCreateOverlay(nameplate)
    -- Determine ideal parent: ElvUI's Health bar or unitFrame for proper draw order
    local parent = nameplate
    if nameplate.unitFrame then
        parent = nameplate.unitFrame.Health or nameplate.unitFrame
    end

    local fs = overlays[nameplate]
    -- Recreate if parent changed (ElvUI frame reconstruction)
    if fs and fs:GetParent() ~= parent then
        fs:Hide()
        fs = nil
        overlays[nameplate] = nil
    end

    if not fs then
        fs = parent:CreateFontString(nil, "OVERLAY", nil, 7)
        overlays[nameplate] = fs
    end
    return fs
end

function ElvUI:ShowOverlay(nameplate, info)
    local fs = self:GetOrCreateOverlay(nameplate)
    local db = MPC.db.nameplates
    fs:SetFont(MPC.Nameplates:GetFont(), db.fontSize or 9, "OUTLINE")
    local c = db.fontColor or { r = 0.2, g = 1.0, b = 0.6, a = 1.0 }
    fs:SetTextColor(c.r, c.g, c.b, c.a)
    fs:ClearAllPoints()
    local pt, relPt, ox, oy = MPC.Nameplates:GetAnchorInfo()
    -- ElvUI nameplates: try unitFrame.Health (ElvUI's health bar)
    local anchor = nameplate
    if nameplate.unitFrame and nameplate.unitFrame.Health then
        anchor = nameplate.unitFrame.Health
    elseif nameplate.UnitFrame and nameplate.UnitFrame.healthBar then
        anchor = nameplate.UnitFrame.healthBar
    end
    fs:SetPoint(pt, anchor, relPt, ox, oy)
    fs:SetText(MPC.Nameplates:FormatOverlayText(info))
    fs:Show()
end

function ElvUI:HideOverlay(nameplate)
    local fs = overlays[nameplate]
    if fs then fs:Hide() end
end
