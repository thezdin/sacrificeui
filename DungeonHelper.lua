-- SacrificeUI M+ Dungeon Helper
-- Shows contextual reminders when entering a Mythic+ dungeon.
-- Data sourced from guild spreadsheet; /sacrifice m+ to reload.

local helperFrame = nil

local function GetPlayerClass()
    local _, className = UnitClass("player")
    return className -- e.g. "WARRIOR", "MAGE", etc.
end

local function GetCurrentDungeonMapID()
    local _, _, _, _, _, _, _, instanceMapID = GetInstanceInfo()
    return instanceMapID
end

local function CreateHelperWindow()
    if helperFrame then
        return helperFrame
    end

    helperFrame = CreateFrame("Frame", "SacrificeUIDungeonHelper", UIParent, "BackdropTemplate")
    helperFrame:SetSize(380, 500)
    helperFrame:SetPoint("RIGHT", UIParent, "RIGHT", -20, 0)
    helperFrame:SetMovable(true)
    helperFrame:EnableMouse(true)
    helperFrame:RegisterForDrag("LeftButton")
    helperFrame:SetScript("OnDragStart", helperFrame.StartMoving)
    helperFrame:SetScript("OnDragStop", helperFrame.StopMovingOrSizing)
    helperFrame:SetFrameStrata("HIGH")

    helperFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 },
    })

    -- Title
    local title = helperFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", helperFrame, "TOP", 0, -16)
    title:SetText("|cFFFF8800Sacrifice M+ Helper|r")
    helperFrame.title = title

    -- Close button
    local closeBtn = CreateFrame("Button", nil, helperFrame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", helperFrame, "TOPRIGHT", -4, -4)

    -- Dismiss permanently button
    local dismissBtn = CreateFrame("Button", nil, helperFrame, "UIPanelButtonTemplate")
    dismissBtn:SetSize(140, 24)
    dismissBtn:SetPoint("BOTTOM", helperFrame, "BOTTOM", 0, 16)
    dismissBtn:SetText("Don't show again")
    dismissBtn:SetScript("OnClick", function()
        SacrificeUIDB.helperDismissed = true
        helperFrame:Hide()
    end)

    -- Scroll frame for content
    local scrollFrame = CreateFrame("ScrollFrame", nil, helperFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", helperFrame, "TOPLEFT", 12, -44)
    scrollFrame:SetPoint("BOTTOMRIGHT", helperFrame, "BOTTOMRIGHT", -30, 48)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(330, 1)
    scrollFrame:SetScrollChild(scrollChild)
    helperFrame.scrollChild = scrollChild

    tinsert(UISpecialFrames, "SacrificeUIDungeonHelper")
    return helperFrame
end

local function AddSection(parent, yOffset, header, items, color)
    if not items or #items == 0 then
        return yOffset
    end

    local headerText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    headerText:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, yOffset)
    headerText:SetText(color .. header .. "|r")
    yOffset = yOffset - 18

    for _, item in ipairs(items) do
        local line = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        line:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, yOffset)
        line:SetWidth(310)
        line:SetJustifyH("LEFT")
        line:SetText("• " .. item)
        local lineHeight = line:GetStringHeight() or 14
        yOffset = yOffset - (lineHeight + 4)
    end

    yOffset = yOffset - 6
    return yOffset
end

local function PopulateDungeonData(dungeonData, playerClass)
    local f = CreateHelperWindow()
    local parent = f.scrollChild

    -- Clear old content
    local regions = { parent:GetRegions() }
    for _, region in ipairs(regions) do
        if region:GetObjectType() == "FontString" then
            region:Hide()
            region:SetText("")
        end
    end

    f.title:SetText("|cFFFF8800" .. (dungeonData.name or "M+ Helper") .. "|r")

    local yOffset = -4

    -- Key interrupts
    yOffset = AddSection(parent, yOffset, "Key Interrupts", dungeonData.interrupts, "|cFFFF4444")

    -- Party damage / dangerous abilities
    yOffset = AddSection(parent, yOffset, "Dangerous Abilities", dungeonData.dangerous, "|cFFFF8800")

    -- Dispels
    yOffset = AddSection(parent, yOffset, "Dispels", dungeonData.dispels, "|cFF44BBFF")

    -- Buffs / defensives
    yOffset = AddSection(parent, yOffset, "Buffs & Defensives", dungeonData.buffs, "|cFF00FF00")

    -- Class-specific tips
    local classTips = dungeonData.classTips and dungeonData.classTips[playerClass]
    yOffset = AddSection(parent, yOffset, "Tips for Your Class", classTips, "|cFFFFFF00")

    -- General notes
    yOffset = AddSection(parent, yOffset, "Notes", dungeonData.notes, "|cFFAAAAAA")

    parent:SetHeight(math.abs(yOffset) + 20)
    f:Show()
end

function SacrificeUI:TryShowDungeonHelper(force)
    if not force and SacrificeUIDB.helperDismissed then
        return
    end

    local inInstance, instanceType = IsInInstance()
    -- Show for M+ dungeons (party instances) or when forced
    if not force and (not inInstance or instanceType ~= "party") then
        return
    end

    local mapID = GetCurrentDungeonMapID()
    local playerClass = GetPlayerClass()

    local dungeonData = SacrificeUI.DungeonData and SacrificeUI.DungeonData[mapID]

    -- Fallback: try matching by instance name
    if not dungeonData then
        local instanceName = GetInstanceInfo()
        if instanceName and SacrificeUI.DungeonDataByName then
            dungeonData = SacrificeUI.DungeonDataByName[instanceName]
        end
    end
    if not dungeonData then
        if force then
            -- Show a generic message
            local f = CreateHelperWindow()
            f.title:SetText("|cFFFF8800M+ Helper|r")
            local parent = f.scrollChild
            local regions = { parent:GetRegions() }
            for _, region in ipairs(regions) do
                if region:GetObjectType() == "FontString" then
                    region:Hide()
                end
            end
            local msg = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            msg:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -10)
            msg:SetWidth(310)
            msg:SetText("No dungeon data available for this instance.\nZone into a M+ dungeon to see contextual tips.")
            f:Show()
        end
        return
    end

    PopulateDungeonData(dungeonData, playerClass)
end
