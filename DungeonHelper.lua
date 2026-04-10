-- SacrificeUI M+ Dungeon Helper
-- Shows contextual reminders when entering a Mythic+ dungeon.
-- Styled to match the SacrificeUI main window.
-- Table format: abilities grouped by mob, with INT / DISP / BUFF / WARN badge columns.

local helperFrame = nil

-- Layout constants
local WIN_W    = 480
local WIN_H    = 600
local HDR_H    = 44   -- title bar height
local FOO_H    = 40   -- footer bar height
local COLHDR_H = 20   -- column header strip height
local ROW_H    = 26   -- ability row height
local MOB_H    = 22   -- mob section header height
local CAT_H    = 20   -- category section header height
local NOTE_H   = 18   -- note row base height

local BADGE_W  = 38   -- width of each badge column
local N_BADGES = 4    -- INT, DISP, BUFF, WARN
local PAD_L    = 6    -- left padding inside rows
local INNER_W  = WIN_W - 22  -- scroll child width for the floating helper window

-- Colors
local C_WHITE    = { 0.90, 0.90, 0.90, 1.0 }
local C_INACTIVE = { 0.45, 0.45, 0.48, 1.0 }
local C_INT      = { 0.90, 0.20, 0.20, 1.0 }
local C_DISP     = { 0.25, 0.65, 1.00, 1.0 }
local C_BUFF     = { 0.20, 0.80, 0.30, 1.0 }
local C_WARN     = { 0.90, 0.55, 0.05, 1.0 }

local function GetAccent()
    if SacrificeUIDB and SacrificeUIDB.classColorEnabled then
        local _, cls = UnitClass("player")
        if cls and RAID_CLASS_COLORS then
            local c = RAID_CLASS_COLORS[cls]
            if c then return c.r, c.g, c.b, 1.0 end
        end
    end
    return 0.86, 0.08, 0.24, 1.0
end

local function GetPlayerClass()
    local _, className = UnitClass("player")
    return className
end

local function GetCurrentDungeonMapID()
    local _, _, _, _, _, _, _, instanceMapID = GetInstanceInfo()
    return instanceMapID
end

-- ============================================================
-- Window construction
-- ============================================================

local function CreateHelperWindow()
    if helperFrame then return helperFrame end

    helperFrame = CreateFrame("Frame", "SacrificeUIDungeonHelper", UIParent, "BackdropTemplate")
    helperFrame:SetSize(WIN_W, WIN_H)
    helperFrame:SetPoint("RIGHT", UIParent, "RIGHT", -20, 0)
    helperFrame:SetMovable(true); helperFrame:EnableMouse(true)
    helperFrame:RegisterForDrag("LeftButton")
    helperFrame:SetScript("OnDragStart", helperFrame.StartMoving)
    helperFrame:SetScript("OnDragStop",  helperFrame.StopMovingOrSizing)
    helperFrame:SetFrameStrata("HIGH")

    -- Dark background
    helperFrame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", tile = false })
    helperFrame:SetBackdropColor(0.07, 0.07, 0.08, 0.97)

    -- 1px accent border lines (OVERLAY layer)
    local function BLine()
        local t = helperFrame:CreateTexture(nil, "OVERLAY")
        local r, g, b = GetAccent()
        t:SetColorTexture(r, g, b, 1.0)
        return t
    end
    local bTop = BLine(); bTop:SetHeight(1)
    bTop:SetPoint("TOPLEFT",  helperFrame, "TOPLEFT",  0, 0)
    bTop:SetPoint("TOPRIGHT", helperFrame, "TOPRIGHT", 0, 0)
    local bBot = BLine(); bBot:SetHeight(1)
    bBot:SetPoint("BOTTOMLEFT",  helperFrame, "BOTTOMLEFT",  0, 0)
    bBot:SetPoint("BOTTOMRIGHT", helperFrame, "BOTTOMRIGHT", 0, 0)
    local bLeft = BLine(); bLeft:SetWidth(1)
    bLeft:SetPoint("TOPLEFT",    helperFrame, "TOPLEFT",    0, 0)
    bLeft:SetPoint("BOTTOMLEFT", helperFrame, "BOTTOMLEFT", 0, 0)
    local bRight = BLine(); bRight:SetWidth(1)
    bRight:SetPoint("TOPRIGHT",    helperFrame, "TOPRIGHT",    0, 0)
    bRight:SetPoint("BOTTOMRIGHT", helperFrame, "BOTTOMRIGHT", 0, 0)
    helperFrame.borderLines = { bTop, bBot, bLeft, bRight }

    -- Title background strip
    local titleBg = helperFrame:CreateTexture(nil, "BACKGROUND", nil, -4)
    titleBg:SetHeight(HDR_H)
    titleBg:SetPoint("TOPLEFT",  helperFrame, "TOPLEFT",  1, -1)
    titleBg:SetPoint("TOPRIGHT", helperFrame, "TOPRIGHT", -1, -1)
    titleBg:SetColorTexture(0.04, 0.04, 0.05, 0.98)

    -- Title separator
    local titleSep = helperFrame:CreateTexture(nil, "ARTWORK")
    titleSep:SetHeight(1)
    titleSep:SetPoint("TOPLEFT",  helperFrame, "TOPLEFT",  1, -HDR_H)
    titleSep:SetPoint("TOPRIGHT", helperFrame, "TOPRIGHT", -1, -HDR_H)
    local r, g, b = GetAccent()
    titleSep:SetColorTexture(r, g, b, 1.0)
    helperFrame.titleSep = titleSep

    -- Title text
    local titleText = helperFrame:CreateFontString(nil, "OVERLAY")
    titleText:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
    titleText:SetPoint("TOPLEFT", helperFrame, "TOPLEFT", 14, -15)
    titleText:SetSize(WIN_W - 50, HDR_H - 10)
    titleText:SetJustifyH("LEFT")
    titleText:SetText("M+ Helper")
    titleText:SetTextColor(r, g, b)
    helperFrame.titleText = titleText

    -- Close button (X)
    local closeBtn = CreateFrame("Button", nil, helperFrame)
    closeBtn:SetSize(24, 24)
    closeBtn:SetPoint("TOPRIGHT", helperFrame, "TOPRIGHT", -8, -10)
    local xfs = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    xfs:SetAllPoints()
    xfs:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
    xfs:SetText("x")
    xfs:SetTextColor(unpack(C_INACTIVE))
    closeBtn:SetScript("OnEnter", function() local ar, ag, ab = GetAccent(); xfs:SetTextColor(ar, ag, ab) end)
    closeBtn:SetScript("OnLeave", function() xfs:SetTextColor(unpack(C_INACTIVE)) end)
    closeBtn:SetScript("OnClick", function() helperFrame:Hide() end)

    -- Column header strip (non-scrolling, sits between title and scroll area)
    local colHdrY = -HDR_H - 1
    local colHdrBg = helperFrame:CreateTexture(nil, "BACKGROUND", nil, -3)
    colHdrBg:SetHeight(COLHDR_H)
    colHdrBg:SetPoint("TOPLEFT",  helperFrame, "TOPLEFT",  1, colHdrY)
    colHdrBg:SetPoint("TOPRIGHT", helperFrame, "TOPRIGHT", -1, colHdrY)
    colHdrBg:SetColorTexture(0.055, 0.055, 0.065, 0.98)

    -- Column header labels (right-aligned, matching badge column positions)
    -- Badges are drawn from right edge of scroll child.
    -- INNER_W = WIN_W - 22.  Scrollbar is ~18px inside scrollFrame.
    -- Actual right edge of content relative to helperFrame right = -(WIN_W - INNER_W) = -22px...
    -- We approximate: badges align from window right -20px offset (scrollbar + border).
    local BADGE_RIGHT_OFFSET = -20  -- approximate right edge of scroll content
    local function ColHeader(label, slot, color)
        -- slot 0 = rightmost (WARN), 1 = BUFF, 2 = DISP, 3 = INT
        local xRight = BADGE_RIGHT_OFFSET - (BADGE_W * slot)
        local lbl = helperFrame:CreateFontString(nil, "OVERLAY")
        lbl:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        lbl:SetSize(BADGE_W, COLHDR_H)
        lbl:SetPoint("TOPRIGHT", helperFrame, "TOPRIGHT", xRight, colHdrY)
        lbl:SetText(label)
        lbl:SetTextColor(unpack(color))
        lbl:SetJustifyH("CENTER"); lbl:SetJustifyV("MIDDLE")
    end
    ColHeader("WARN", 0, C_WARN)
    ColHeader("BUFF", 1, C_BUFF)
    ColHeader("DISP", 2, C_DISP)
    ColHeader("INT",  3, C_INT)

    -- Column header bottom separator
    local colHdrSep = helperFrame:CreateTexture(nil, "ARTWORK")
    colHdrSep:SetHeight(1)
    colHdrSep:SetPoint("TOPLEFT",  helperFrame, "TOPLEFT",  1, colHdrY - COLHDR_H)
    colHdrSep:SetPoint("TOPRIGHT", helperFrame, "TOPRIGHT", -1, colHdrY - COLHDR_H)
    colHdrSep:SetColorTexture(0.15, 0.15, 0.17, 1.0)

    -- Footer background strip
    local footerBg = helperFrame:CreateTexture(nil, "BACKGROUND", nil, -4)
    footerBg:SetHeight(FOO_H)
    footerBg:SetPoint("BOTTOMLEFT",  helperFrame, "BOTTOMLEFT",  1, 1)
    footerBg:SetPoint("BOTTOMRIGHT", helperFrame, "BOTTOMRIGHT", -1, 1)
    footerBg:SetColorTexture(0.04, 0.04, 0.05, 0.98)

    local footerSep = helperFrame:CreateTexture(nil, "ARTWORK")
    footerSep:SetHeight(1)
    footerSep:SetPoint("BOTTOMLEFT",  helperFrame, "BOTTOMLEFT",  1, FOO_H)
    footerSep:SetPoint("BOTTOMRIGHT", helperFrame, "BOTTOMRIGHT", -1, FOO_H)
    footerSep:SetColorTexture(r, g, b, 1.0)
    helperFrame.footerSep = footerSep

    -- "Don't show again" button
    local dismissBtn = CreateFrame("Button", nil, helperFrame, "BackdropTemplate")
    dismissBtn:SetSize(140, 24)
    dismissBtn:SetPoint("RIGHT", helperFrame, "BOTTOMRIGHT", -10, FOO_H / 2)
    dismissBtn:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    dismissBtn:SetBackdropColor(0.10, 0.10, 0.13, 0.95)
    dismissBtn:SetBackdropBorderColor(r * 0.5, g * 0.5, b * 0.5, 1.0)
    local dTxt = dismissBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    dTxt:SetAllPoints(); dTxt:SetText("Don't show again")
    dTxt:SetTextColor(unpack(C_INACTIVE))
    dismissBtn:SetScript("OnClick", function()
        SacrificeUIDB.helperDismissed = true
        helperFrame:Hide()
    end)

    -- Scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", nil, helperFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT",     helperFrame, "TOPLEFT",  1, -(HDR_H + COLHDR_H + 2))
    scrollFrame:SetPoint("BOTTOMRIGHT", helperFrame, "BOTTOMRIGHT", -1, FOO_H + 1)
    helperFrame.scrollFrame = scrollFrame

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(INNER_W)
    scrollChild:SetHeight(10)
    scrollFrame:SetScrollChild(scrollChild)
    helperFrame.scrollChild = scrollChild

    tinsert(UISpecialFrames, "SacrificeUIDungeonHelper")
    helperFrame:Hide()
    return helperFrame
end

-- ============================================================
-- Data normalization
-- ============================================================

-- Parse "MobName - Ability (note)" → mob, ability, note
local function ParseEntry(str)
    local mob, rest = str:match("^(.-)%s*%-%s*(.+)$")
    if mob and rest then
        local ability, note = rest:match("^(.-)%s*%((.-)%)%s*$")
        if ability then
            return mob, ability, note
        end
        return mob, rest, nil
    end
    return nil, str, nil
end

local function IsPriority(ability, note)
    local check = ((note or "") .. " " .. (ability or "")):lower()
    return check:find("priority") ~= nil or check:find("top priority") ~= nil
end

-- Returns a flat list of row descriptors for rendering.
-- Row types:
--   { isMobHeader = true, text }
--   { isCatHeader = true, text, color }
--   { isAbility   = true, text, note, int, danger, dispel, buff, priority }
--   { isNote      = true, text }
local function BuildRows(data, playerClass)
    local rows = {}

    -- Phase 1: interrupts + dangerous, grouped by mob name
    local mobOrder = {}
    local mobMap   = {}

    local function GetOrCreateMob(name)
        local key = name or "(General)"
        if not mobMap[key] then
            tinsert(mobOrder, key)
            mobMap[key] = {}
        end
        return mobMap[key]
    end

    local function AddAbility(str, flags)
        local mob, ability, note = ParseEntry(str)
        local list = GetOrCreateMob(mob)
        -- Merge with existing entry if same ability name
        for _, ab in ipairs(list) do
            if ab.text == ability then
                for k, v in pairs(flags) do if v then ab[k] = v end end
                return
            end
        end
        local entry = { isAbility = true, text = ability, note = note }
        for k, v in pairs(flags) do entry[k] = v end
        entry.priority = IsPriority(ability, note)
        tinsert(list, entry)
    end

    if data.interrupts then
        for _, s in ipairs(data.interrupts) do AddAbility(s, { int = true }) end
    end
    if data.dangerous then
        for _, s in ipairs(data.dangerous) do AddAbility(s, { danger = true }) end
    end
    if data.dispels then
        for _, s in ipairs(data.dispels) do AddAbility(s, { dispel = true }) end
    end
    if data.buffs then
        for _, s in ipairs(data.buffs) do AddAbility(s, { buff = true }) end
    end

    for _, mobName in ipairs(mobOrder) do
        local display = mobName:gsub("%s*%(Boss%)%s*", ""):gsub("%s*%(boss%)%s*", "")
        display = display:match("^%s*(.-)%s*$"):upper()
        tinsert(rows, { isMobHeader = true, text = display })
        for _, ab in ipairs(mobMap[mobName]) do
            tinsert(rows, ab)
        end
    end

    -- Phase 4: class tips
    local tips = data.classTips and playerClass and data.classTips[playerClass]
    if tips and #tips > 0 then
        tinsert(rows, { isCatHeader = true, text = "TIPS FOR YOUR CLASS", color = { 1.0, 0.85, 0.25, 1.0 } })
        for _, s in ipairs(tips) do
            tinsert(rows, { isNote = true, text = s })
        end
    end

    -- Phase 5: notes
    if data.notes and #data.notes > 0 then
        tinsert(rows, { isCatHeader = true, text = "NOTES", color = C_INACTIVE })
        for _, s in ipairs(data.notes) do
            tinsert(rows, { isNote = true, text = s })
        end
    end

    return rows
end

-- ============================================================
-- Row rendering
-- ============================================================

local function RenderRows(scrollChild, rows, innerW)
    innerW = innerW or INNER_W
    local NAME_W = innerW - PAD_L - (BADGE_W * N_BADGES)

    -- Hide previous content batch
    if scrollChild._active then scrollChild._active:Hide() end

    local content = CreateFrame("Frame", nil, scrollChild)
    content:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, 0)
    content:SetWidth(innerW)
    scrollChild._active = content

    local r, g, b = GetAccent()
    local y = 0
    local odd = false

    for _, row in ipairs(rows) do

        if row.isMobHeader then
            -- ---- Mob section header ----
            y = y - 2
            local bg = content:CreateTexture(nil, "BACKGROUND")
            bg:SetSize(innerW, MOB_H)
            bg:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
            bg:SetColorTexture(r * 0.18, g * 0.10, b * 0.10, 0.95)

            local bar = content:CreateTexture(nil, "ARTWORK")
            bar:SetSize(2, MOB_H)
            bar:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
            bar:SetColorTexture(r, g, b, 1.0)

            local sep = content:CreateTexture(nil, "ARTWORK")
            sep:SetHeight(1)
            sep:SetPoint("TOPLEFT",  content, "TOPLEFT",  0, y)
            sep:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, y)
            sep:SetColorTexture(r * 0.5, g * 0.3, b * 0.3, 0.7)

            local txt = content:CreateFontString(nil, "OVERLAY")
            txt:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
            txt:SetSize(innerW - PAD_L, MOB_H)
            txt:SetPoint("TOPLEFT", content, "TOPLEFT", PAD_L + 4, y)
            txt:SetJustifyH("LEFT"); txt:SetJustifyV("MIDDLE")
            txt:SetText(row.text)
            txt:SetTextColor(r, g, b)

            y = y - MOB_H
            odd = false

        elseif row.isCatHeader then
            -- ---- Category section header ----
            y = y - 6
            local color = row.color or C_INACTIVE

            local sep = content:CreateTexture(nil, "ARTWORK")
            sep:SetHeight(1)
            sep:SetPoint("TOPLEFT",  content, "TOPLEFT",  0, y)
            sep:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, y)
            sep:SetColorTexture(0.18, 0.18, 0.20, 1.0)

            local bg = content:CreateTexture(nil, "BACKGROUND")
            bg:SetSize(innerW, CAT_H)
            bg:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
            bg:SetColorTexture(0.045, 0.045, 0.055, 0.98)

            local txt = content:CreateFontString(nil, "OVERLAY")
            txt:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
            txt:SetSize(innerW, CAT_H)
            txt:SetPoint("TOPLEFT", content, "TOPLEFT", PAD_L, y)
            txt:SetJustifyH("LEFT"); txt:SetJustifyV("MIDDLE")
            txt:SetText(row.text)
            txt:SetTextColor(unpack(color))

            y = y - CAT_H
            odd = false

        elseif row.isNote then
            -- ---- Note / tip row ----
            local shade = odd and 0.10 or 0.07
            local bg = content:CreateTexture(nil, "BACKGROUND")
            bg:SetSize(innerW, NOTE_H)
            bg:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
            bg:SetColorTexture(shade, shade, shade + 0.01, 0.75)

            local txt = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            txt:SetPoint("TOPLEFT", content, "TOPLEFT", PAD_L + 4, y - 3)
            txt:SetWidth(innerW - PAD_L * 2)
            txt:SetJustifyH("LEFT"); txt:SetJustifyV("TOP")
            txt:SetText("|cFF888899*|r " .. row.text)
            txt:SetTextColor(0.65, 0.65, 0.68)

            -- Expand row height if text wraps
            local lh = max(NOTE_H, (txt:GetStringHeight() or NOTE_H) + 6)
            bg:SetSize(innerW, lh)
            y = y - lh
            odd = not odd

        elseif row.isAbility then
            -- ---- Ability row (main table row) ----
            local shade = odd and 0.105 or 0.075
            local bg = content:CreateTexture(nil, "BACKGROUND")
            bg:SetSize(innerW, ROW_H)
            bg:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
            if row.priority then
                bg:SetColorTexture(0.20, 0.10, 0.02, 0.85)
            else
                bg:SetColorTexture(shade, shade, shade + 0.01, 0.75)
            end

            -- Priority outline (top + bottom 1px orange lines)
            if row.priority then
                local bt = content:CreateTexture(nil, "ARTWORK")
                bt:SetHeight(1)
                bt:SetPoint("TOPLEFT",  content, "TOPLEFT",  0, y)
                bt:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, y)
                bt:SetColorTexture(unpack(C_WARN))
                local bb = content:CreateTexture(nil, "ARTWORK")
                bb:SetHeight(1)
                bb:SetPoint("TOPLEFT",  content, "TOPLEFT",  0, y - ROW_H + 1)
                bb:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, y - ROW_H + 1)
                bb:SetColorTexture(unpack(C_WARN))
            end

            -- Left category color bar
            local bar = content:CreateTexture(nil, "ARTWORK")
            bar:SetSize(2, ROW_H - 2)
            bar:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y - 1)
            if     row.int    then bar:SetColorTexture(unpack(C_INT))
            elseif row.danger then bar:SetColorTexture(unpack(C_WARN))
            elseif row.dispel then bar:SetColorTexture(unpack(C_DISP))
            elseif row.buff   then bar:SetColorTexture(unpack(C_BUFF))
            else                   bar:SetColorTexture(0.25, 0.25, 0.28, 1.0) end

            -- Ability name
            local nc = row.priority and { 1.0, 0.82, 0.45, 1.0 } or C_WHITE
            local nameTxt = content:CreateFontString(nil, "OVERLAY")
            nameTxt:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
            nameTxt:SetSize(NAME_W, ROW_H)
            nameTxt:SetPoint("TOPLEFT", content, "TOPLEFT", PAD_L + 4, y)
            nameTxt:SetJustifyH("LEFT"); nameTxt:SetJustifyV("MIDDLE")
            nameTxt:SetText(row.text)
            nameTxt:SetTextColor(unpack(nc))

            -- Badge columns: slot 3=INT  2=DISP  1=BUFF  0=WARN (right to left)
            local function DrawBadge(label, slot, color, active)
                if not active then return end
                -- xRight is offset from content right edge
                local xRight = -(BADGE_W * slot) - 2
                local badgeBg = content:CreateTexture(nil, "ARTWORK", nil, 1)
                badgeBg:SetSize(BADGE_W - 4, ROW_H - 8)
                badgeBg:SetPoint("TOPRIGHT", content, "TOPRIGHT", xRight, y - 4)
                badgeBg:SetColorTexture(color[1], color[2], color[3], 0.70)
                local badgeTxt = content:CreateFontString(nil, "OVERLAY")
                badgeTxt:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
                badgeTxt:SetSize(BADGE_W - 4, ROW_H - 8)
                badgeTxt:SetPoint("TOPRIGHT", content, "TOPRIGHT", xRight, y - 4)
                badgeTxt:SetJustifyH("CENTER"); badgeTxt:SetJustifyV("MIDDLE")
                badgeTxt:SetText(label)
                badgeTxt:SetTextColor(1, 1, 1, 1)
            end

            DrawBadge("INT",  3, C_INT,  row.int)
            DrawBadge("DISP", 2, C_DISP, row.dispel)
            DrawBadge("BUFF", 1, C_BUFF, row.buff)
            DrawBadge("WARN", 0, C_WARN, row.priority)

            y = y - ROW_H
            odd = not odd
        end
    end

    local totalH = math.abs(y) + 10
    content:SetSize(innerW, totalH)
    scrollChild:SetHeight(totalH)
end

-- ============================================================
-- Public API
-- ============================================================

local function RefreshAccent(f)
    local r, g, b = GetAccent()
    for _, line in ipairs(f.borderLines) do line:SetColorTexture(r, g, b, 1.0) end
    f.titleSep:SetColorTexture(r, g, b, 1.0)
    f.footerSep:SetColorTexture(r, g, b, 1.0)
    f.titleText:SetTextColor(r, g, b)
end

function SacrificeUI:TryShowDungeonHelper(force)
    if not force and SacrificeUIDB.helperDismissed then return end

    local inInstance, instanceType = IsInInstance()
    if not force and (not inInstance or instanceType ~= "party") then return end

    local mapID       = GetCurrentDungeonMapID()
    local playerClass = GetPlayerClass()

    local dungeonData = SacrificeUI.DungeonData and SacrificeUI.DungeonData[mapID]
    if not dungeonData then
        local instanceName = GetInstanceInfo()
        if instanceName and SacrificeUI.DungeonDataByName then
            dungeonData = SacrificeUI.DungeonDataByName[instanceName]
        end
    end

    local f = CreateHelperWindow()
    RefreshAccent(f)

    if not dungeonData then
        if force then
            f.titleText:SetText("M+ Helper")
            RenderRows(f.scrollChild, {
                { isCatHeader = true, text = "No data for this instance.", color = C_INACTIVE },
                { isNote = true, text = "Zone into a Mythic+ dungeon to see contextual tips." },
            })
            f:Show()
        end
        return
    end

    f.titleText:SetText(dungeonData.name or "M+ Helper")
    RenderRows(f.scrollChild, BuildRows(dungeonData, playerClass))
    f:Show()
end

-- ============================================================
-- Shared API for main window Dungeons pane
-- ============================================================

SacrificeUI.BuildDungeonRows   = BuildRows
SacrificeUI.RenderDungeonTable = function(scrollChild, rows, innerW)
    RenderRows(scrollChild, rows, innerW)
end
