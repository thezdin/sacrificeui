-- SacrificeUI Core
-- Sacrifice Guild <US-Hyjal>
-- All bundled addon references retain full credit to their original authors.

local ADDON_NAME = "SacrificeUI"
SacrificeUI = SacrificeUI or {}
SacrificeUI.version = "1.0.0"

-- Saved variables
SacrificeUIDB = SacrificeUIDB or {}

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("CHALLENGE_MODE_START")
frame:RegisterEvent("UNIT_DURABILITY_UPDATE")

frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        SacrificeUIDB = SacrificeUIDB or {}
        local defaults = {
            helperDismissed      = false,
            classColorEnabled    = false,
            showPerformance      = false,
            showStats            = false,
            mythicCountEnabled   = false,
            apiKey               = "",
            talentReminders      = {},
            durabilityEnabled    = false,
            durabilityThreshold  = 40,
            -- Combat logging (LoggerHead)
            logEnabled       = false,
            logEnableAll     = false,
            logDungeons      = false,
            logRaids         = true,
            logBattlegrounds = false,
            logArenas        = false,
        }
        for k, v in pairs(defaults) do
            if SacrificeUIDB[k] == nil then SacrificeUIDB[k] = v end
        end
        SacrificeUI:ApplySettings()
        SacrificeUI:CheckAddons()
    elseif event == "UNIT_DURABILITY_UPDATE" then
        SacrificeUI:CheckDurability()
    elseif event == "PLAYER_ENTERING_WORLD" then
        SacrificeUI:CheckAddons()
        SacrificeUI:CheckTalentReminders()
        SacrificeUI:UpdateCombatLogging()
        SacrificeUI:CheckDurability()
        if not SacrificeUIDB.helperDismissed then
            SacrificeUI:TryShowDungeonHelper()
        end
    elseif event == "CHALLENGE_MODE_START" then
        SacrificeUI:ShowFunnyMessage()
    end
end)

-- Game Menu button
local function InjectGameMenuButton()
    if SacrificeUIGameMenuButton then return end
    if not GameMenuFrame then return end

    -- Find the AddOns button (try all known names across WoW versions)
    local addonsBtn = GameMenuButtonAddOns
        or GameMenuButtonAddons
        or _G["GameMenuButtonAddOns"]
        or _G["GameMenuButtonAddons"]
    if not addonsBtn then return end

    -- Match exact dimensions of existing menu buttons
    local w = addonsBtn:GetWidth()
    local h = addonsBtn:GetHeight()
    if w < 1 then w = 144 end
    if h < 1 then h = 25  end

    local MARGIN = 8  -- px gap above and below our button

    -- Custom-styled button: dark grey bg, crimson text, same size as peers
    local btn = CreateFrame("Button", "SacrificeUIGameMenuButton", GameMenuFrame, "BackdropTemplate")
    btn:SetSize(w, h)
    btn:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    btn:SetBackdropColor(0.06, 0.06, 0.07, 0.97)
    btn:SetBackdropBorderColor(0.20, 0.06, 0.09, 1.0)

    local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lbl:SetAllPoints()
    lbl:SetText("SacrificeUI")
    lbl:SetTextColor(0.86, 0.08, 0.24)  -- C_CRIMSON

    btn:SetScript("OnEnter", function()
        btn:SetBackdropColor(0.14, 0.04, 0.07, 0.97)
        btn:SetBackdropBorderColor(0.86, 0.08, 0.24, 0.80)
        lbl:SetTextColor(1.0, 0.25, 0.38)
    end)
    btn:SetScript("OnLeave", function()
        btn:SetBackdropColor(0.06, 0.06, 0.07, 0.97)
        btn:SetBackdropBorderColor(0.20, 0.06, 0.09, 1.0)
        lbl:SetTextColor(0.86, 0.08, 0.24)
    end)
    btn:SetScript("OnClick", function()
        HideUIPanel(GameMenuFrame)
        SacrificeUI:ToggleMainWindow()
    end)

    -- Inherit AddOns' current anchor (shifted by MARGIN for gap above),
    -- then re-anchor AddOns below our button with matching MARGIN gap below.
    local point, relativeTo, relativePoint, ox, oy = addonsBtn:GetPoint(1)
    if point then
        btn:ClearAllPoints()
        btn:SetPoint(point, relativeTo, relativePoint, ox, (oy or 0) - MARGIN)
        addonsBtn:ClearAllPoints()
        addonsBtn:SetPoint("TOP", btn, "BOTTOM", 0, -MARGIN)
    else
        btn:SetPoint("BOTTOM", addonsBtn, "TOP", 0, MARGIN)
    end

    GameMenuFrame:SetHeight(GameMenuFrame:GetHeight() + h + MARGIN * 2)
end

if GameMenuFrame then
    GameMenuFrame:HookScript("OnShow", InjectGameMenuButton)
end

-- Slash commands
SLASH_SACRIFICE1 = "/sacrifice"
SlashCmdList["SACRIFICE"] = function(msg)
    local cmd = strlower(strtrim(msg))
    if cmd == "m+" or cmd == "mplus" then
        SacrificeUI:TryShowDungeonHelper(true)
    elseif cmd == "funny" then
        SacrificeUI:ShowFunnyMessage()
    elseif cmd == "debug" then
        SacrificeUI:DebugFrames()
    else
        SacrificeUI:ToggleMainWindow()
    end
end
