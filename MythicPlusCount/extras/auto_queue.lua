-- MythicPlusCount - Auto Queue Extra
-- 1. Auto-accepts queue pops via SecureActionButtonTemplate
-- 2. Auto-signs for LFG groups via OnShow secure context
-- 3. Auto-completes role checks via CompleteLFGRoleCheck API
local ADDON_NAME, NS = ...
local MPC = NS.MPC

local AutoQueue = {}

local CLASS_ROLES = {
    WARRIOR     = { tank = true,  healer = false, dps = true },
    PALADIN     = { tank = true,  healer = true,  dps = true },
    HUNTER      = { tank = false, healer = false, dps = true },
    ROGUE       = { tank = false, healer = false, dps = true },
    PRIEST      = { tank = false, healer = true,  dps = true },
    DEATHKNIGHT = { tank = true,  healer = false, dps = true },
    SHAMAN      = { tank = false, healer = true,  dps = true },
    MAGE        = { tank = false, healer = false, dps = true },
    WARLOCK     = { tank = false, healer = false, dps = true },
    MONK        = { tank = true,  healer = true,  dps = true },
    DRUID       = { tank = true,  healer = true,  dps = true },
    DEMONHUNTER = { tank = true,  healer = false, dps = true },
    EVOKER      = { tank = false, healer = true,  dps = true },
}

function AutoQueue:CanPlayRole(role)
    local _, classToken = UnitClass("player")
    local roles = CLASS_ROLES[classToken] or { tank = false, healer = false, dps = true }
    return roles[role] or false
end

function AutoQueue:GetEffectiveRoles()
    local settings = MPC.Extras:GetSettings("autoqueue")
    local isTank   = settings.roleTank == true and self:CanPlayRole("tank")
    local isHealer = settings.roleHealer == true and self:CanPlayRole("healer")
    local isDPS    = settings.roleDamage == true and self:CanPlayRole("dps")
    -- If nothing is selected, default to DPS
    if not isTank and not isHealer and not isDPS then
        isDPS = self:CanPlayRole("dps")
    end
    return isTank, isHealer, isDPS
end

MPC.Extras:Register("autoqueue", {
    name = "Auto Accept Queue",
    description = "Auto-accept queue pops and auto-sign for LFG groups.",

    Init = function(self)
        AutoQueue:Setup()
    end,
})

local setupDone = false

function AutoQueue:Setup()
    if setupDone then return end
    setupDone = true

    local bootFrame = CreateFrame("Frame")
    bootFrame:RegisterEvent("PLAYER_LOGIN")
    bootFrame:SetScript("OnEvent", function(self)
        self:UnregisterEvent("PLAYER_LOGIN")

        local ef = CreateFrame("Frame")
        ef:RegisterEvent("LFG_ROLE_CHECK_SHOW")
        ef:SetScript("OnEvent", function(_, event)
            if event == "LFG_ROLE_CHECK_SHOW" then
                AutoQueue:OnRoleCheck()
            end
        end)

        AutoQueue:SetupSecureAcceptButton()
        AutoQueue:SetupApplicationDialog()
    end)
end

-- Blizzard's approved way to click protected buttons:
-- SecureActionButtonTemplate + SetAttribute("clickbutton")
function AutoQueue:SetupSecureAcceptButton()
    local secureBtn = CreateFrame("Button", "MythicPlusCountAutoAcceptBtn", UIParent, "SecureActionButtonTemplate")
    secureBtn:Hide()
    secureBtn:SetAttribute("type", "click")

    if LFGDungeonReadyPopup_Update then
        hooksecurefunc("LFGDungeonReadyPopup_Update", function()
            if not MPC.Extras:IsEnabled("autoqueue") then return end
            local settings = MPC.Extras:GetSettings("autoqueue")
            if settings.autoAccept == false then return end

            if LFGDungeonReadyDialogEnterDungeonButton then
                secureBtn:SetAttribute("clickbutton", LFGDungeonReadyDialogEnterDungeonButton)
            end

            if LFGDungeonReadyDialog and LFGDungeonReadyDialog:IsShown() then
                C_Timer.After(0.2, function()
                    if not InCombatLockdown() and LFGDungeonReadyDialog:IsShown() then
                        secureBtn:Click()
                        if settings.showNotification ~= false then
                            MPC:Debug("Queue auto-accepted.")
                        end
                    end
                end)
            end
        end)
    elseif LFGDungeonReadyPopup then
        LFGDungeonReadyPopup:HookScript("OnShow", function()
            if not MPC.Extras:IsEnabled("autoqueue") then return end
            local settings = MPC.Extras:GetSettings("autoqueue")
            if settings.autoAccept == false then return end

            if LFGDungeonReadyDialogEnterDungeonButton then
                secureBtn:SetAttribute("clickbutton", LFGDungeonReadyDialogEnterDungeonButton)
            end

            C_Timer.After(0.2, function()
                if not InCombatLockdown() then
                    secureBtn:Click()
                    if settings.showNotification ~= false then
                        MPC:Debug("Queue auto-accepted.")
                    end
                end
            end)
        end)
    end
end

-- SetScript("OnShow") runs in secure context, allowing direct :Click()
-- on the Sign Up button without taint.
function AutoQueue:SetupApplicationDialog()
    if not LFGListApplicationDialog then return end

    -- SetScript (not hooksecurefunc!) to stay in secure context
    LFGListApplicationDialog:SetScript("OnShow", function(dialog)
        if not MPC.Extras:IsEnabled("autoqueue") then return end
        local settings = MPC.Extras:GetSettings("autoqueue")
        if not settings.autoSign then return end

        -- Hold Shift to skip auto-sign
        if IsShiftKeyDown() then return end

        local isTank, isHealer, isDPS = AutoQueue:GetEffectiveRoles()
        local isLeader = GetLFGRoles()
        SetLFGRoles(isLeader, isTank, isHealer, isDPS)

        -- Set the dialog's checkbuttons and note to match our settings
        pcall(function()
            if dialog.TankButton and dialog.TankButton.CheckButton then
                dialog.TankButton.CheckButton:SetChecked(isTank)
            end
            if dialog.HealerButton and dialog.HealerButton.CheckButton then
                dialog.HealerButton.CheckButton:SetChecked(isHealer)
            end
            if dialog.DamagerButton and dialog.DamagerButton.CheckButton then
                dialog.DamagerButton.CheckButton:SetChecked(isDPS)
            end
            -- Note: dialog note field is protected in Midnight, cannot be auto-filled
        end)

        if dialog.SignUpButton then
            dialog.SignUpButton:Click()
            if settings.showNotification ~= false then
                MPC:Debug("Auto-signed for group.")
            end
        end
    end)
end

function AutoQueue:OnRoleCheck()
    if not MPC.Extras:IsEnabled("autoqueue") then return end
    local settings = MPC.Extras:GetSettings("autoqueue")
    if settings.autoAccept == false then return end

    local isTank, isHealer, isDPS = self:GetEffectiveRoles()
    local isLeader = GetLFGRoles()
    SetLFGRoles(isLeader, isTank, isHealer, isDPS)
    CompleteLFGRoleCheck(true)

    if settings.showNotification ~= false then
        MPC:Debug("Role check auto-completed.")
    end
end
