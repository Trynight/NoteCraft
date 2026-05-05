local NoteCraft = LibStub("AceAddon-3.0"):GetAddon("NoteCraft")
local AceGUI = LibStub("AceGUI-3.0")

-- StatsTab is a panel-builder used by MainWindow. It does not own a frame.
local Stats = {}
NoteCraft.StatsTab = Stats

local CLASS_HEX = {} -- cache from RAID_CLASS_COLORS
local function classHex(c)
    if not c then return "ffffff" end
    if CLASS_HEX[c] then return CLASS_HEX[c] end
    local cc = RAID_CLASS_COLORS and RAID_CLASS_COLORS[c]
    if cc then
        CLASS_HEX[c] = string.format("%02x%02x%02x", cc.r * 255, cc.g * 255, cc.b * 255)
    else
        CLASS_HEX[c] = "ffffff"
    end
    return CLASS_HEX[c]
end

local function compute()
    local totals = {
        playerCount = 0,
        totalEncounters = 0,
        totalRuns = 0,
        totalPositive = 0,
        totalNegative = 0,
        roleCounts = { TANK = 0, HEALER = 0, DAMAGER = 0 },
        classCounts = {},          -- [classToken] = count
        dungeonCounts = {},        -- [mapID] = count
        topByEncounter = {},       -- list of { p = ..., encounters = N }
        topByRuns = {},            -- list of { p = ..., runs = N }
    }
    for _, p in pairs(NoteCraft.db.global.players or {}) do
        totals.playerCount = totals.playerCount + 1
        totals.totalEncounters = totals.totalEncounters + (p.encounters or 0)
        totals.totalPositive = totals.totalPositive + (p.mPlusPositive or 0)
        totals.totalNegative = totals.totalNegative + (p.mPlusNegative or 0)
        local pTotal = (p.mPlusPositive or 0) + (p.mPlusNegative or 0)
        totals.totalRuns = totals.totalRuns + pTotal
        if p.class then
            totals.classCounts[p.class] = (totals.classCounts[p.class] or 0) + 1
        end
        if p.roleCounts then
            for r, n in pairs(p.roleCounts) do
                totals.roleCounts[r] = (totals.roleCounts[r] or 0) + (n or 0)
            end
        end
        for _, run in ipairs(p.mPlusRuns or {}) do
            if run.mapID then
                totals.dungeonCounts[run.mapID] = (totals.dungeonCounts[run.mapID] or 0) + 1
            end
        end
        totals.topByEncounter[#totals.topByEncounter + 1] = { p = p, encounters = p.encounters or 0 }
        if pTotal > 0 then
            totals.topByRuns[#totals.topByRuns + 1] = { p = p, runs = pTotal }
        end
    end
    table.sort(totals.topByEncounter, function(a, b) return a.encounters > b.encounters end)
    table.sort(totals.topByRuns, function(a, b) return a.runs > b.runs end)
    return totals
end

local function dungeonName(mapID)
    if C_ChallengeMode and C_ChallengeMode.GetMapUIInfo then
        local n = C_ChallengeMode.GetMapUIInfo(mapID)
        if n and n ~= "" then return n end
    end
    return tostring(mapID)
end

function Stats:Build(container)
    container:ReleaseChildren()
    local L = NoteCraft.L
    local s = compute()

    local hdr = AceGUI:Create("Label")
    hdr:SetText(string.format("|cffffffff%s|r", L["Aggregate statistics"]))
    hdr:SetFontObject(GameFontHighlightLarge)
    hdr:SetFullWidth(true)
    container:AddChild(hdr)

    local summary = AceGUI:Create("Label")
    local winRate = s.totalRuns > 0 and (s.totalPositive / s.totalRuns * 100) or 0
    summary:SetText(string.format(
        L["%d players tracked  •  %d total encounters  •  %d M+ runs (%.0f%% in time)"],
        s.playerCount, s.totalEncounters, s.totalRuns, winRate))
    summary:SetFullWidth(true)
    container:AddChild(summary)

    local rolesLine = AceGUI:Create("Label")
    rolesLine:SetText(string.format(L["Role distribution: |cff5599ffTank %d|r  |cff44ff44Healer %d|r  |cffff7766DPS %d|r"],
        s.roleCounts.TANK or 0, s.roleCounts.HEALER or 0, s.roleCounts.DAMAGER or 0))
    rolesLine:SetFullWidth(true)
    container:AddChild(rolesLine)

    local sep1 = AceGUI:Create("Heading"); sep1:SetText(L["Top players by encounters"]); sep1:SetFullWidth(true)
    container:AddChild(sep1)
    for i = 1, math.min(10, #s.topByEncounter) do
        local e = s.topByEncounter[i]
        local row = AceGUI:Create("Label")
        row:SetText(string.format("%2d. |cff%s%s|r  x%d",
            i, classHex(e.p.class), NoteCraft.Util.DisplayName(e.p), e.encounters))
        row:SetFullWidth(true)
        container:AddChild(row)
    end

    if #s.topByRuns > 0 then
        local sep2 = AceGUI:Create("Heading"); sep2:SetText(L["Top players by M+ runs"]); sep2:SetFullWidth(true)
        container:AddChild(sep2)
        for i = 1, math.min(10, #s.topByRuns) do
            local e = s.topByRuns[i]
            local pos = e.p.mPlusPositive or 0
            local row = AceGUI:Create("Label")
            row:SetText(string.format("%2d. |cff%s%s|r  %d/%d in time",
                i, classHex(e.p.class), NoteCraft.Util.DisplayName(e.p), pos, e.runs))
            row:SetFullWidth(true)
            container:AddChild(row)
        end
    end

    -- Class distribution.
    local sep3 = AceGUI:Create("Heading"); sep3:SetText(L["Class distribution"]); sep3:SetFullWidth(true)
    container:AddChild(sep3)
    local classList = {}
    for c, n in pairs(s.classCounts) do classList[#classList + 1] = { c = c, n = n } end
    table.sort(classList, function(a, b) return a.n > b.n end)
    for _, e in ipairs(classList) do
        local row = AceGUI:Create("Label")
        row:SetText(string.format("|cff%s%s|r  x%d", classHex(e.c), e.c, e.n))
        row:SetFullWidth(true)
        container:AddChild(row)
    end

    -- Dungeon distribution.
    local dungeonList = {}
    for m, n in pairs(s.dungeonCounts) do dungeonList[#dungeonList + 1] = { m = m, n = n } end
    if #dungeonList > 0 then
        local sep4 = AceGUI:Create("Heading"); sep4:SetText(L["Most-run dungeons"]); sep4:SetFullWidth(true)
        container:AddChild(sep4)
        table.sort(dungeonList, function(a, b) return a.n > b.n end)
        for i = 1, math.min(10, #dungeonList) do
            local e = dungeonList[i]
            local row = AceGUI:Create("Label")
            row:SetText(string.format("%2d. %s  x%d", i, dungeonName(e.m), e.n))
            row:SetFullWidth(true)
            container:AddChild(row)
        end
    end
end
