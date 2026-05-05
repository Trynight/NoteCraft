local _, ns = ...

local U = {}
ns.Util = U

local function stripRealm(realm)
    if not realm or realm == "" then return "" end
    return (realm:gsub("[%s'%-%.]", ""))
end

-- Build a stable lower-case key from a name and realm.
-- Accepted shapes:
--   NormalizePlayerKey("Roby", "PozzoDelleTerne") -> "roby-pozzodelleterne"
--   NormalizePlayerKey("Roby-PozzoDelleTerne")    -> "roby-pozzodelleterne"
--   NormalizePlayerKey("Roby")                    -> "roby-<currentRealmStripped>"
function U.NormalizePlayerKey(nameOrFull, realm)
    if not nameOrFull or nameOrFull == "" then return nil end
    local name
    if realm == nil then
        name, realm = nameOrFull:match("^([^%-]+)%-(.+)$")
        if not name then name = nameOrFull end
    else
        name = nameOrFull
    end
    if not realm or realm == "" then
        realm = GetNormalizedRealmName() or ""
    end
    realm = stripRealm(realm)
    return (name:lower() .. "-" .. realm:lower())
end

-- Pretty "Name-Realm" form for display.
function U.DisplayName(player)
    if not player then return "" end
    if player.name and player.realm and player.realm ~= "" then
        return player.name .. "-" .. player.realm
    end
    return player.name or player.normalized or "?"
end

-- Create a placeholder record for a player we know by name only (e.g. typed via slash command).
function U.CreateStubPlayer(key, displayName)
    local now = time()
    local name, realm = displayName:match("^([^%-]+)%-(.+)$")
    if not name then
        name = displayName
        realm = GetNormalizedRealmName() or ""
    end
    return {
        name          = name,
        realm         = realm,
        normalized    = key,
        encounters    = 0,
        mPlusPositive = 0,
        mPlusNegative = 0,
        mPlusRuns     = {},
        roleCounts    = { TANK = 0, HEALER = 0, DAMAGER = 0 },
        title         = nil,
        firstSeen     = now,
        lastSeen      = now,
    }
end

-- Get class color hex (rrggbb) for a class token like "PRIEST"; safe fallback to white.
function U.ClassColorHex(classToken)
    if classToken and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classToken] then
        local c = RAID_CLASS_COLORS[classToken]
        return string.format("ff%02x%02x%02x", c.r * 255, c.g * 255, c.b * 255)
    end
    return "ffffffff"
end

-- Format a unix timestamp as YYYY-MM-DD; empty for nil/0.
function U.FormatDate(t)
    if not t or t == 0 then return "" end
    return date("%Y-%m-%d", t)
end

-- (Tag list moved to db.global.tags; see NoteCraft:GetTags()/IsValidTag().)

-- Snapshot the current group (excluding self) as a list of {key,role,name,realm,guid,class}.
function U.SnapshotGroup()
    local list = {}
    local n = GetNumGroupMembers() or 0
    if n == 0 then return list end
    local prefix = IsInRaid() and "raid" or "party"
    local maxIdx = IsInRaid() and n or (n - 1)
    for i = 1, maxIdx do
        local unit = prefix .. i
        if UnitExists(unit) and not UnitIsUnit(unit, "player") then
            local name, realm = UnitFullName(unit)
            if name then
                if not realm or realm == "" then realm = GetNormalizedRealmName() end
                local _, classToken = UnitClass(unit)
                list[#list + 1] = {
                    key   = U.NormalizePlayerKey(name, realm),
                    role  = UnitGroupRolesAssigned(unit),
                    name  = name,
                    realm = realm,
                    guid  = UnitGUID(unit),
                    class = classToken,
                }
            end
        end
    end
    return list
end

-- Trim a list in-place to at most `maxN` elements, keeping the tail (most recent).
function U.TrimList(list, maxN)
    while #list > maxN do
        table.remove(list, 1)
    end
end
