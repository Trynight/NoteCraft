local NoteCraft = LibStub("AceAddon-3.0"):GetAddon("NoteCraft")
local AceGUI = LibStub("AceGUI-3.0")

local HistoryDialog = {}
NoteCraft.HistoryDialog = HistoryDialog

local active

-- Try to read the localized dungeon name from the journal; fall back to mapID.
local function dungeonName(mapID)
    if not mapID then return "?" end
    if C_ChallengeMode and C_ChallengeMode.GetMapUIInfo then
        local name = C_ChallengeMode.GetMapUIInfo(mapID)
        if name and name ~= "" then return name end
    end
    return tostring(mapID)
end

local ROLE_HEX = { TANK = "5599ff", HEALER = "44ff44", DAMAGER = "ff7766" }

local function colorRole(role)
    if not role or role == "" then return "?" end
    local hex = ROLE_HEX[role] or "ffffff"
    return string.format("|cff%s%s|r", hex, role:sub(1, 1))
end

function HistoryDialog:Show(displayName)
    if active then active:Release(); active = nil end
    local key = NoteCraft.Util.NormalizePlayerKey(displayName)
    local p = NoteCraft.db.global.players[key]
    if not p then return end

    local f = AceGUI:Create("Frame")
    f:SetTitle(string.format(NoteCraft.L["M+ history with %s"], NoteCraft.Util.DisplayName(p)))
    f:SetLayout("Fill")
    f:SetWidth(560)
    f:SetHeight(420)
    f:SetCallback("OnClose", function(w) AceGUI:Release(w); active = nil end)
    active = f

    local scroll = AceGUI:Create("ScrollFrame")
    scroll:SetLayout("List")
    f:AddChild(scroll)

    local header = AceGUI:Create("Label")
    local total = (p.mPlusPositive or 0) + (p.mPlusNegative or 0)
    header:SetText(string.format(NoteCraft.L["%d runs total — |cff00ff00%d in time|r / |cffff0000%d not in time|r"],
        total, p.mPlusPositive or 0, p.mPlusNegative or 0))
    header:SetFullWidth(true)
    scroll:AddChild(header)

    local runs = p.mPlusRuns or {}
    if #runs == 0 then
        local empty = AceGUI:Create("Label")
        empty:SetText(NoteCraft.L["No M+ runs recorded yet."])
        empty:SetFullWidth(true)
        scroll:AddChild(empty)
        return
    end

    -- Newest first.
    for i = #runs, 1, -1 do
        local r = runs[i]
        local outcome = r.onTime
            and "|cff00ff00" .. NoteCraft.L["IN TIME"] .. "|r"
            or  "|cffff0000" .. NoteCraft.L["DEPLETED"] .. "|r"
        local lvl = r.level and ("+" .. r.level) or "?"
        local line = string.format("%s  %s  |cffffffff%s|r  %s  %s",
            NoteCraft.Util.FormatDate(r.date), lvl, dungeonName(r.mapID), colorRole(r.role), outcome)
        local lbl = AceGUI:Create("Label")
        lbl:SetText(line)
        lbl:SetFullWidth(true)
        scroll:AddChild(lbl)
    end
end
