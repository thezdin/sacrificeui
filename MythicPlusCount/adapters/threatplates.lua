-- MythicPlusCount - ThreatPlates Adapter
-- FontString overlay for TidyPlates ThreatPlates nameplates.
-- ThreatPlates stores health bar at nameplate.TPFrame.visual.healthbar (StatusBar).
local ADDON_NAME, NS = ...
local MPC = NS.MPC

local ThreatPlates = {}
MPC.Adapters = MPC.Adapters or {}
MPC.Adapters.ThreatPlates = ThreatPlates

local overlays = {}

function ThreatPlates:IsAvailable() return _G.TidyPlatesThreat ~= nil end
function ThreatPlates:Init() MPC:Debug("ThreatPlates adapter initialized") end

function ThreatPlates:OnNameplateAdded(unitToken)
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

function ThreatPlates:OnNameplateRemoved(unitToken)
    local nameplate = C_NamePlate.GetNamePlateForUnit(unitToken)
    if nameplate then self:HideOverlay(nameplate) end
end

function ThreatPlates:GetOrCreateOverlay(nameplate)
    if overlays[nameplate] then return overlays[nameplate] end
    local fs = nameplate:CreateFontString(nil, "OVERLAY")
    overlays[nameplate] = fs
    return fs
end

function ThreatPlates:ShowOverlay(nameplate, info)
    local fs = self:GetOrCreateOverlay(nameplate)
    local db = MPC.db.nameplates
    fs:SetFont(MPC.Nameplates:GetFont(), db.fontSize or 9, "OUTLINE")
    local c = db.fontColor or { r = 0.2, g = 1.0, b = 0.6, a = 1.0 }
    fs:SetTextColor(c.r, c.g, c.b, c.a)
    fs:ClearAllPoints()
    local pt, relPt, ox, oy = MPC.Nameplates:GetAnchorInfo()
    -- ThreatPlates: nameplate.TPFrame.visual.healthbar
    local anchor = nameplate
    if nameplate.TPFrame and nameplate.TPFrame.visual and nameplate.TPFrame.visual.healthbar then
        anchor = nameplate.TPFrame.visual.healthbar
    elseif nameplate.UnitFrame and nameplate.UnitFrame.healthBar then
        anchor = nameplate.UnitFrame.healthBar
    end
    fs:SetPoint(pt, anchor, relPt, ox, oy)
    fs:SetText(MPC.Nameplates:FormatOverlayText(info))
    fs:Show()
end

function ThreatPlates:HideOverlay(nameplate)
    local fs = overlays[nameplate]
    if fs then fs:Hide() end
end
