-- MythicPlusCount - Tooltip
-- Shows per-mob forces and estimated pack total on mouseover.
local ADDON_NAME, NS = ...
local MPC = NS.MPC

local issecretvalue = issecretvalue or function() return false end

local Tooltip = {}
MPC.Tooltip = Tooltip

function Tooltip:Init()
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip, data)
        self:OnTooltipSetUnit(tooltip, data)
    end)
end

local function GetNpcIDFromTooltip(data)
    if data and data.guid and not issecretvalue(data.guid) then
        local npcID = MPC.Util:GetNpcIDFromGUID(data.guid)
        if npcID then return npcID end
    end
    if UnitExists("mouseover") then
        return MPC.Util:GetNpcIDFromUnit("mouseover")
    end
    return nil
end

function Tooltip:OnTooltipSetUnit(tooltip, data)
    if not MPC.db or not MPC.db.tooltip.enabled then return end
    if not MPC.db.developerMode then
        if MPC.db.nameplates.onlyInMythicPlus and not MPC.Util:IsInMythicPlus() then return end
        if not MPC.Util:IsInMythicPlus() and not MPC.db.showOutsideMPlus and not MPC.Util:GetCurrentMapID() then return end
    end

    local npcID = GetNpcIDFromTooltip(data)
    if not npcID then return end

    local info = MPC.Util:GetMobInfo(npcID)
    if not info or info.count == 0 then return end

    local decimals = MPC.db.tooltip.decimals or 2
    local forcesText = "|cFF33FF99Mythic+ Forces:|r "
    local parts = {}
    if MPC.db.tooltip.showCount then
        parts[#parts + 1] = tostring(info.count)
    end
    if MPC.db.tooltip.showPercent then
        local pct = MPC.Util:FormatPercent(info.percent, decimals)
        if MPC.db.tooltip.showCount then
            parts[#parts + 1] = "(" .. pct .. ")"
        else
            parts[#parts + 1] = pct
        end
    end
    forcesText = forcesText .. table.concat(parts, " ")
    tooltip:AddLine(forcesText)


    tooltip:Show()
end
