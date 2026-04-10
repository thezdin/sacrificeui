-- MythicPlusCount - Minimap Button
-- Standard minimap button positioned on the edge of the minimap.
local ADDON_NAME, NS = ...
local MPC = NS.MPC

local MinimapButton = {}
MPC.MinimapButton = MinimapButton

local button = nil

function MinimapButton:Init()
    if not MPC.db.minimap then
        MPC.db.minimap = { enabled = true, minimapPos = 220 }
    end
    self:Create()
    self:UpdateVisibility()
end

function MinimapButton:Create()
    button = CreateFrame("Button", "MythicPlusCountMinimapButton", Minimap)
    button:SetSize(24, 24)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)

    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetSize(17, 17)
    bg:SetPoint("CENTER", 0, 0)
    bg:SetColorTexture(0, 0, 0, 1)
    button.bg = bg

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(15, 15)
    icon:SetPoint("CENTER", 0, 0)
    icon:SetTexture("Interface\\AddOns\\MythicPlusCount\\AddonIcon")
    button.icon = icon

    local mask = button:CreateMaskTexture()
    mask:SetSize(17, 17)
    mask:SetPoint("CENTER", 0, 0)
    mask:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    bg:AddMaskTexture(mask)
    icon:AddMaskTexture(mask)

    -- Minimap tracking border has built-in offset in the art, shift to center it
    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetSize(42, 42)
    border:SetPoint("CENTER", 8, -8)
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    button.border = border

    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetSize(17, 17)
    highlight:SetPoint("CENTER", 0, 0)
    highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    highlight:SetBlendMode("ADD")
    button.highlight = highlight

    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:SetScript("OnClick", function(_, btn)
        if btn == "LeftButton" then
            MPC.Options:Toggle()
        elseif btn == "RightButton" then
            local pct = MPC.Util:GetCompletedPercent()
            local pull = MPC.PullTracker:GetCurrentPullPercent()
            if MPC.Util:IsInMythicPlus() then
                MPC:Print(string.format("Forces: %.1f%% + pull %.1f%% = %.1f%%",
                    pct, pull, pct + pull))
            else
                MPC:Print("Not in M+. Left-click to open settings.")
            end
        end
    end)

    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("|cFF4CB3FFMythicPlusCount|r")
        GameTooltip:AddLine("Left-click: Settings", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Right-click: Quick status", 0.8, 0.8, 0.8)
        if MPC.Util:IsInMythicPlus() then
            local pct = MPC.Util:GetCompletedPercent()
            GameTooltip:AddLine(string.format("Forces: %.1f%%", pct), 0.2, 1, 0.6)
        end
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    button:RegisterForDrag("LeftButton")
    button:SetScript("OnDragStart", function()
        button:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local cx, cy = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            cx, cy = cx / scale, cy / scale
            local angle = math.atan2(cy - my, cx - mx)
            MPC.db.minimap.minimapPos = math.deg(angle)
            MinimapButton:UpdatePosition()
        end)
    end)
    button:SetScript("OnDragStop", function()
        button:SetScript("OnUpdate", nil)
    end)

    self:UpdatePosition()
end

-- Minimap shape handling (matches LibDBIcon algorithm)
local minimapShapes = {
    ["ROUND"]                 = {true,  true,  true,  true },
    ["SQUARE"]                = {false, false, false, false},
    ["CORNER-TOPLEFT"]        = {false, false, false, true },
    ["CORNER-TOPRIGHT"]       = {false, false, true,  false},
    ["CORNER-BOTTOMLEFT"]     = {false, true,  false, false},
    ["CORNER-BOTTOMRIGHT"]    = {true,  false, false, false},
    ["SIDE-LEFT"]             = {false, true,  false, true },
    ["SIDE-RIGHT"]            = {true,  false, true,  false},
    ["SIDE-TOP"]              = {false, false, true,  true },
    ["SIDE-BOTTOM"]           = {true,  true,  false, false},
    ["TRICORNER-TOPLEFT"]     = {false, true,  true,  true },
    ["TRICORNER-TOPRIGHT"]    = {true,  false, true,  true },
    ["TRICORNER-BOTTOMLEFT"]  = {true,  true,  false, true },
    ["TRICORNER-BOTTOMRIGHT"] = {true,  true,  true,  false},
}

function MinimapButton:UpdatePosition()
    if not button then return end
    local angle = math.rad(MPC.db.minimap.minimapPos or 220)
    local x, y = math.cos(angle), math.sin(angle)

    -- Determine quadrant: 1=BR, 2=BL, 3=TR, 4=TL
    local q = 1
    if x < 0 then q = q + 1 end
    if y > 0 then q = q + 2 end

    local minimapRadius = (Minimap:GetWidth() / 2) + 5
    local shape = GetMinimapShape and GetMinimapShape() or "ROUND"
    local quadTable = minimapShapes[shape] or minimapShapes["ROUND"]

    if quadTable[q] then
        -- Round quadrant: place on circle
        x, y = x * minimapRadius, y * minimapRadius
    else
        -- Square quadrant: use diagonal radius, clamp to square edge
        local diag = math.sqrt(2 * minimapRadius * minimapRadius) - 10
        x = math.max(-minimapRadius, math.min(x * diag, minimapRadius))
        y = math.max(-minimapRadius, math.min(y * diag, minimapRadius))
    end

    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

function MinimapButton:UpdateVisibility()
    if not button then return end
    if MPC.db.minimap and MPC.db.minimap.enabled then
        button:Show()
    else
        button:Hide()
    end
end
