local NoteCraft = LibStub("AceAddon-3.0"):GetAddon("NoteCraft")
local AceGUI = LibStub("AceGUI-3.0")

local MainWindow = {}
NoteCraft.MainWindow = MainWindow

local frame, scroll, tabGroup
local currentTab = "players"
local state = {
    search        = "",
    tagFilter     = "ALL",     -- ALL | __none__ | <tag id>
    outcomeFilter = "ALL",     -- ALL | POS | NEG
    realmFilter   = "ALL",     -- ALL | <realm>
}

local function matches(p)
    if state.tagFilter == "__none__" then
        if p.tag then return false end
    elseif state.tagFilter ~= "ALL" then
        if p.tag ~= state.tagFilter then return false end
    end
    if state.outcomeFilter == "POS" and (p.mPlusPositive or 0) == 0 then return false end
    if state.outcomeFilter == "NEG" and (p.mPlusNegative or 0) == 0 then return false end
    if state.realmFilter and state.realmFilter ~= "ALL" then
        if (p.realm or "") ~= state.realmFilter then return false end
    end
    if state.search ~= "" then
        local q = state.search:lower()
        local hay = (p.name or "") .. " " .. (p.realm or "") .. " "
                .. (p.title or "") .. " " .. (p.note or "")
        if not hay:lower():find(q, 1, true) then return false end
    end
    return true
end

local function buildRoleSummary(p)
    local rc = p.roleCounts
    if not rc then return "" end
    local parts = {}
    if (rc.TANK    or 0) > 0 then parts[#parts + 1] = "|cff5599ffT" .. rc.TANK .. "|r" end
    if (rc.HEALER  or 0) > 0 then parts[#parts + 1] = "|cff44ff44H" .. rc.HEALER .. "|r" end
    if (rc.DAMAGER or 0) > 0 then parts[#parts + 1] = "|cffff7766D" .. rc.DAMAGER .. "|r" end
    return table.concat(parts, " ")
end

local NOTE_PREVIEW_MAX = 80

local function buildRow(scrollContainer, p, key)
    local row = AceGUI:Create("SimpleGroup")
    row:SetLayout("List")
    row:SetFullWidth(true)

    local topRow = AceGUI:Create("SimpleGroup")
    topRow:SetLayout("Flow")
    topRow:SetFullWidth(true)
    topRow:SetHeight(24)

    local classHex = NoteCraft.Util.ClassColorHex(p.class)
    local tagColor = NoteCraft:GetTagColor(p.tag)

    local nameLbl = AceGUI:Create("InteractiveLabel")
    local nameText = string.format("|c%s%s|r", classHex, NoteCraft.Util.DisplayName(p))
    if p.tag then
        nameText = nameText .. string.format(" |c%s[%s]|r", tagColor, NoteCraft:GetTagLabel(p.tag))
    end
    nameLbl:SetText(nameText)
    nameLbl:SetWidth(200)
    -- Click semantics:
    --   default       -> open NoteDialog (edit)
    --   Ctrl+click    -> /whisper player
    --   Shift+click   -> insert link in chat
    --   Alt+click     -> open M+ history
    nameLbl:SetCallback("OnClick", function()
        local display = NoteCraft.Util.DisplayName(p)
        if IsControlKeyDown() and ChatFrame_OpenChat then
            ChatFrame_OpenChat("/w " .. display .. " ")
        elseif IsShiftKeyDown() and ChatEdit_InsertLink then
            ChatEdit_InsertLink(display)
        elseif IsAltKeyDown() and NoteCraft.HistoryDialog then
            NoteCraft.HistoryDialog:Show(display)
        else
            NoteCraft.NoteDialog:Show(display)
        end
    end)
    topRow:AddChild(nameLbl)

    local statsLbl = AceGUI:Create("Label")
    local total = (p.mPlusPositive or 0) + (p.mPlusNegative or 0)
    local stats = string.format(NoteCraft.L["%d times"], p.encounters or 0)
    if total > 0 then
        stats = stats .. string.format("  M+ |cff00ff00%d|r/|cffff0000%d|r",
            p.mPlusPositive or 0, p.mPlusNegative or 0)
    end
    local roleSummary = buildRoleSummary(p)
    if roleSummary ~= "" then stats = stats .. "  " .. roleSummary end
    statsLbl:SetText(stats)
    statsLbl:SetWidth(160)
    topRow:AddChild(statsLbl)

    local lastLbl = AceGUI:Create("Label")
    lastLbl:SetText(NoteCraft.Util.FormatDate(p.lastSeen))
    lastLbl:SetWidth(80)
    topRow:AddChild(lastLbl)

    local histBtn = AceGUI:Create("Button")
    histBtn:SetText(NoteCraft.L["History"])
    histBtn:SetWidth(90)
    histBtn:SetCallback("OnClick", function()
        if NoteCraft.HistoryDialog then NoteCraft.HistoryDialog:Show(NoteCraft.Util.DisplayName(p)) end
    end)
    topRow:AddChild(histBtn)

    local editBtn = AceGUI:Create("Button")
    editBtn:SetText(NoteCraft.L["Edit"])
    editBtn:SetWidth(70)
    editBtn:SetCallback("OnClick", function()
        NoteCraft.NoteDialog:Show(NoteCraft.Util.DisplayName(p))
    end)
    topRow:AddChild(editBtn)

    local delBtn = AceGUI:Create("Button")
    delBtn:SetText(NoteCraft.L["Delete"])
    delBtn:SetWidth(85)
    delBtn:SetCallback("OnClick", function()
        NoteCraft.db.global.players[key] = nil
        MainWindow:Refresh()
    end)
    topRow:AddChild(delBtn)

    row:AddChild(topRow)

    if p.title and p.title ~= "" then
        local titleLbl = AceGUI:Create("Label")
        titleLbl:SetText(string.format("|cffffd54f%s|r", p.title))
        titleLbl:SetFullWidth(true)
        row:AddChild(titleLbl)
    end

    if p.note and p.note ~= "" then
        local txt = p.note
        if #txt > NOTE_PREVIEW_MAX then txt = txt:sub(1, NOTE_PREVIEW_MAX - 3) .. "..." end
        local noteLbl = AceGUI:Create("Label")
        noteLbl:SetText(string.format('|cffaaaaaa"%s"|r', txt))
        noteLbl:SetFullWidth(true)
        row:AddChild(noteLbl)
    end

    scrollContainer:AddChild(row)
end

function MainWindow:Refresh()
    if not frame then return end
    if currentTab == "stats" then
        if tabGroup and NoteCraft.StatsTab then
            buildStatsTab(tabGroup)
        end
        return
    end
    if not scroll then return end
    scroll:ReleaseChildren()

    local players = NoteCraft.db.global.players or {}
    local list = {}
    for k, p in pairs(players) do
        if matches(p) then list[#list + 1] = { key = k, p = p } end
    end
    table.sort(list, function(a, b) return (a.p.lastSeen or 0) > (b.p.lastSeen or 0) end)

    local count = AceGUI:Create("Label")
    count:SetText(string.format(NoteCraft.L["%d players"], #list))
    count:SetFullWidth(true)
    scroll:AddChild(count)

    if #list == 0 then
        local empty = AceGUI:Create("Label")
        empty:SetText(NoteCraft.L["No players tracked yet."])
        empty:SetFullWidth(true)
        scroll:AddChild(empty)
        return
    end
    for _, e in ipairs(list) do buildRow(scroll, e.p, e.key) end
end

local function buildPlayersTab(container)
    container:ReleaseChildren()
    container:SetLayout("Flow")

    local search = AceGUI:Create("EditBox")
    search:SetLabel(NoteCraft.L["Search players..."])
    search:SetWidth(300)
    local searchPending
    search:SetCallback("OnTextChanged", function(_, _, text)
        state.search = text or ""
        if searchPending then return end
        searchPending = true
        C_Timer.After(0.2, function()
            searchPending = false
            MainWindow:Refresh()
        end)
    end)
    container:AddChild(search)

    local tagDD = AceGUI:Create("Dropdown")
    tagDD:SetLabel(NoteCraft.L["Filter by tag"])
    tagDD:SetWidth(180)
    local tagItems = { ALL = NoteCraft.L["All"], __none__ = NoteCraft.L["No tag"] }
    local tagOrder = { "ALL", "__none__" }
    for _, t in ipairs(NoteCraft:GetTags()) do
        tagItems[t.id] = string.format("|c%s%s|r", t.color, t.label)
        tagOrder[#tagOrder + 1] = t.id
    end
    tagDD:SetList(tagItems, tagOrder)
    tagDD:SetValue("ALL")
    tagDD:SetCallback("OnValueChanged", function(_, _, val)
        state.tagFilter = val; MainWindow:Refresh()
    end)
    container:AddChild(tagDD)

    local outDD = AceGUI:Create("Dropdown")
    outDD:SetLabel(NoteCraft.L["Filter by outcome"])
    outDD:SetWidth(140)
    outDD:SetList({
        ALL = NoteCraft.L["All"],
        POS = NoteCraft.L["Has positive M+"],
        NEG = NoteCraft.L["Has negative M+"],
    }, { "ALL", "POS", "NEG" })
    outDD:SetValue("ALL")
    outDD:SetCallback("OnValueChanged", function(_, _, val)
        state.outcomeFilter = val; MainWindow:Refresh()
    end)
    container:AddChild(outDD)

    local realmDD = AceGUI:Create("Dropdown")
    realmDD:SetLabel(NoteCraft.L["Filter by realm"])
    realmDD:SetWidth(160)
    local realms = { ALL = NoteCraft.L["All"] }
    local realmOrder = { "ALL" }
    local seenRealms = {}
    for _, p in pairs(NoteCraft.db.global.players or {}) do
        local r = p.realm
        if r and r ~= "" and not seenRealms[r] then
            seenRealms[r] = true
            realms[r] = r
            realmOrder[#realmOrder + 1] = r
        end
    end
    table.sort(realmOrder, function(a, b)
        if a == "ALL" then return true elseif b == "ALL" then return false end
        return a < b
    end)
    realmDD:SetList(realms, realmOrder)
    realmDD:SetValue("ALL")
    realmDD:SetCallback("OnValueChanged", function(_, _, val)
        state.realmFilter = val; MainWindow:Refresh()
    end)
    container:AddChild(realmDD)

    local legend = AceGUI:Create("Label")
    legend:SetText("|cff888888" .. NoteCraft.L["Stats: × encounters | M+ in time/depleted | T/H/D role counts"] .. "|r")
    legend:SetFullWidth(true)
    container:AddChild(legend)

    scroll = AceGUI:Create("ScrollFrame")
    scroll:SetLayout("List")
    scroll:SetFullWidth(true)
    scroll:SetFullHeight(true)
    container:AddChild(scroll)

    MainWindow:Refresh()
end

local function buildStatsTab(container)
    container:ReleaseChildren()
    container:SetLayout("Fill")
    local statsScroll = AceGUI:Create("ScrollFrame")
    statsScroll:SetLayout("List")
    container:AddChild(statsScroll)
    if NoteCraft.StatsTab then NoteCraft.StatsTab:Build(statsScroll) end
end

local function selectTab(_, _, group)
    currentTab = group or "players"
    if not tabGroup then return end
    scroll = nil
    if currentTab == "stats" then
        buildStatsTab(tabGroup)
    else
        buildPlayersTab(tabGroup)
    end
end

function MainWindow:Show()
    if frame then frame:Show(); self:Refresh(); return end

    frame = AceGUI:Create("Frame")
    frame:SetTitle("NoteCraft")
    frame:SetLayout("Fill")
    frame:SetWidth(760)
    frame:SetHeight(560)
    frame:SetCallback("OnClose", function(widget)
        AceGUI:Release(widget); frame = nil; scroll = nil; tabGroup = nil
    end)

    tabGroup = AceGUI:Create("TabGroup")
    tabGroup:SetLayout("Flow")
    tabGroup:SetTabs({
        { value = "players", text = NoteCraft.L["Players"] },
        { value = "stats",   text = NoteCraft.L["Stats"] },
    })
    tabGroup:SetCallback("OnGroupSelected", selectTab)
    frame:AddChild(tabGroup)
    tabGroup:SelectTab(currentTab)
end

function MainWindow:Toggle()
    if frame and frame.frame and frame.frame:IsShown() then
        frame:Release()
        frame = nil; scroll = nil
    else
        self:Show()
    end
end

function MainWindow:ShowPlayer(displayName)
    self:Show()
    state.search = displayName or ""
    self:Refresh()
end
