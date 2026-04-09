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

frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        SacrificeUIDB = SacrificeUIDB or {}
        if SacrificeUIDB.helperDismissed == nil then
            SacrificeUIDB.helperDismissed = false
        end
        SacrificeUI:CheckAddons()
    elseif event == "PLAYER_ENTERING_WORLD" then
        SacrificeUI:CheckAddons()
        if not SacrificeUIDB.helperDismissed then
            SacrificeUI:TryShowDungeonHelper()
        end
    end
end)

-- Slash commands
SLASH_SACRIFICE1 = "/sacrifice"
SlashCmdList["SACRIFICE"] = function(msg)
    local cmd = strlower(strtrim(msg))
    if cmd == "m+" or cmd == "mplus" then
        SacrificeUI:TryShowDungeonHelper(true)
    else
        SacrificeUI:ToggleMainWindow()
    end
end
