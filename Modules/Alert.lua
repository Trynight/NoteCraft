local NoteCraft = LibStub("AceAddon-3.0"):GetAddon("NoteCraft")
local A = NoteCraft:NewModule("Alert", "AceEvent-3.0")

-- Plays a chat warning + sound when a player tagged BAD (or any other tag the
-- user marked as "alert") joins the current group/raid. Fires once per player
-- per group session.

local alertedThisGroup = {}

local function isAlertTag(tag)
    if not tag then return false end
    if not NoteCraft.db then return false end
    if not NoteCraft.db.global.config.enableAlerts then return false end
    local cfg = NoteCraft.db.global.config
    cfg.alertTags = cfg.alertTags or { BAD = true, CAUTION = true }
    return cfg.alertTags[tag] == true
end

local function alert(p)
    local color = NoteCraft:GetTagColor(p.tag)
    local label = NoteCraft:GetTagLabel(p.tag)
    local display = NoteCraft.Util.DisplayName(p)
    local msg = string.format("|c%s[%s]|r %s — %s",
        color, label, display, p.title or p.note or NoteCraft.L["No note"])
    NoteCraft:Print("|cffff4444" .. NoteCraft.L["Warning:"] .. "|r " .. msg)
    if RaidNotice_AddMessage then
        RaidNotice_AddMessage(RaidWarningFrame,
            string.format(NoteCraft.L["NoteCraft alert: %s [%s]"], display, label),
            ChatTypeInfo and ChatTypeInfo.RAID_WARNING or { r = 1, g = 0.3, b = 0.3 })
    end
    if PlaySound and SOUNDKIT and SOUNDKIT.RAID_WARNING then
        PlaySound(SOUNDKIT.RAID_WARNING, "Master")
    end
end

local function check()
    if not NoteCraft.db then return end
    if not NoteCraft.db.global.config.enableAlerts then return end
    local n = GetNumGroupMembers() or 0
    if n == 0 then alertedThisGroup = {}; return end
    local prefix = IsInRaid() and "raid" or "party"
    local maxIdx = IsInRaid() and n or (n - 1)
    for i = 1, maxIdx do
        local unit = prefix .. i
        if UnitExists(unit) and not UnitIsUnit(unit, "player") then
            local name, realm = UnitFullName(unit)
            if name then
                local key = NoteCraft.Util.NormalizePlayerKey(name, realm)
                if key and not alertedThisGroup[key] then
                    local p = NoteCraft.db.global.players[key]
                    if p and isAlertTag(p.tag) then
                        alertedThisGroup[key] = true
                        alert(p)
                    end
                end
            end
        end
    end
end

function A:OnEnable()
    self:RegisterEvent("GROUP_ROSTER_UPDATE", function() C_Timer.After(0.6, check) end)
    self:RegisterEvent("GROUP_LEFT", function() alertedThisGroup = {} end)
end

function A:OnDisable()
    self:UnregisterAllEvents()
end
