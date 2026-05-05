local NoteCraft = LibStub("AceAddon-3.0"):GetAddon("NoteCraft")
local PT = NoteCraft:NewModule("PlayerTracker", "AceEvent-3.0")

local THROTTLE_SECONDS = 0.5

local pendingScan = false
local seenThisGroup = {}

function PT:OnEnable()
    self:RegisterEvent("GROUP_ROSTER_UPDATE", "OnRosterUpdate")
    self:RegisterEvent("GROUP_LEFT",          "OnGroupLeft")
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnRosterUpdate")
end

function PT:OnDisable()
    self:UnregisterAllEvents()
    pendingScan, seenThisGroup = false, {}
end

function PT:OnGroupLeft()
    seenThisGroup = {}
end

function PT:OnRosterUpdate()
    if pendingScan then return end
    pendingScan = true
    C_Timer.After(THROTTLE_SECONDS, function()
        pendingScan = false
        PT:ScanRoster()
    end)
end

function PT:ScanRoster()
    local n = GetNumGroupMembers() or 0
    if n == 0 then
        seenThisGroup = {}
        return
    end
    local members = NoteCraft.Util.SnapshotGroup()
    for _, m in ipairs(members) do
        if m.key and not seenThisGroup[m.key] then
            seenThisGroup[m.key] = true
            PT:RegisterPlayer(m.key, m.name, m.realm, m.guid, m.class, m.role)
        end
    end
end

local function bumpRole(p, role)
    if not role or role == "NONE" or role == "" then return end
    p.roleCounts = p.roleCounts or { TANK = 0, HEALER = 0, DAMAGER = 0 }
    p.roleCounts[role] = (p.roleCounts[role] or 0) + 1
end

function PT:RegisterPlayer(key, name, realm, guid, class, role)
    local g = NoteCraft.db.global
    local p = g.players[key]
    local now = time()
    if not p then
        p = {
            name          = name,
            realm         = realm or GetNormalizedRealmName() or "",
            normalized    = key,
            lastGUID      = guid,
            class         = class,
            encounters    = 0,
            mPlusPositive = 0,
            mPlusNegative = 0,
            mPlusRuns     = {},
            roleCounts    = { TANK = 0, HEALER = 0, DAMAGER = 0 },
            title         = nil,
            firstSeen     = now,
            lastSeen      = now,
        }
        g.players[key] = p
    else
        p.lastSeen   = now
        if guid  then p.lastGUID = guid end
        if class then p.class    = class end
        if name  then p.name     = name end
        if realm and realm ~= "" then p.realm = realm end
    end
    bumpRole(p, role)
    if guid then g.guidIndex[guid] = key end
end
