local NoteCraft = LibStub("AceAddon-3.0"):GetAddon("NoteCraft")
local MP = NoteCraft:NewModule("MythicPlus", "AceEvent-3.0")

local lastProcessedTime = 0
local DOUBLE_FIRE_WINDOW = 5  -- seconds

function MP:OnEnable()
    self:RegisterEvent("CHALLENGE_MODE_START",        "OnStart")
    self:RegisterEvent("CHALLENGE_MODE_COMPLETED",    "OnCompleted")
    self:RegisterEvent("CHALLENGE_MODE_RESET",        "OnReset")
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA",       "OnZoneChanged")
end

function MP:OnDisable()
    self:UnregisterAllEvents()
end

local function safeCall(fn, ...)
    if type(fn) ~= "function" then return end
    local ok, a, b, c, d, e, f, g, h, i, j, k, l, m, n = pcall(fn, ...)
    if not ok then return end
    return a, b, c, d, e, f, g, h, i, j, k, l, m, n
end

local function isValidMPlusGroup()
    if IsInRaid() then return false end
    local n = GetNumGroupMembers() or 0
    if n > 5 then return false end
    return true
end

function MP:OnStart()
    if not isValidMPlusGroup() then
        NoteCraft.db.global.pendingRun = nil
        return
    end
    local mapID, level
    if C_ChallengeMode then
        level = safeCall(C_ChallengeMode.GetActiveKeystoneInfo)
        mapID = safeCall(C_ChallengeMode.GetActiveChallengeMapID)
    end
    NoteCraft.db.global.pendingRun = {
        startTime = time(),
        mapID     = mapID,
        level     = level,
        members   = NoteCraft.Util.SnapshotGroup(),
    }
end

function MP:OnCompleted()
    if not isValidMPlusGroup() then
        NoteCraft.db.global.pendingRun = nil
        return
    end
    local now = time()
    if (now - lastProcessedTime) < DOUBLE_FIRE_WINDOW then return end
    lastProcessedTime = now

    local mapID, level, _t, onTime
    if C_ChallengeMode and C_ChallengeMode.GetCompletionInfo then
        mapID, level, _t, onTime = safeCall(C_ChallengeMode.GetCompletionInfo)
    end
    local pending = NoteCraft.db.global.pendingRun
    local members = (pending and pending.members) or NoteCraft.Util.SnapshotGroup()
    mapID = mapID or (pending and pending.mapID)
    level = level or (pending and pending.level)
    local outcomeFlag = onTime and true or false
    for _, m in ipairs(members) do
        MP:Record(m.key, mapID, level, outcomeFlag, m.role)
    end
    NoteCraft.db.global.pendingRun = nil

    if NoteCraft.PostRunDialog and NoteCraft.PostRunDialog.Show and
       NoteCraft.db.global.config.autoShowPostRunDialog then
        NoteCraft.PostRunDialog:Show({
            mapID   = mapID,
            level   = level,
            onTime  = outcomeFlag,
            members = members,
            outcome = outcomeFlag and "COMPLETED" or "DEPLETED",
        })
    end
end

function MP:OnReset()
    if not isValidMPlusGroup() then
        NoteCraft.db.global.pendingRun = nil
        return
    end
    local now = time()
    if (now - lastProcessedTime) < DOUBLE_FIRE_WINDOW then return end
    lastProcessedTime = now

    local pending = NoteCraft.db.global.pendingRun
    if not pending then return end
    for _, m in ipairs(pending.members or {}) do
        MP:Record(m.key, pending.mapID, pending.level, false, m.role)
    end
    local runInfo = {
        mapID   = pending.mapID,
        level   = pending.level,
        onTime  = false,
        members = pending.members,
        outcome = "ABANDONED",
    }
    NoteCraft.db.global.pendingRun = nil

    if NoteCraft.PostRunDialog and NoteCraft.PostRunDialog.Show and
       NoteCraft.db.global.config.autoShowPostRunDialog then
        NoteCraft.PostRunDialog:Show(runInfo)
    end
end

function MP:OnZoneChanged()
    local pending = NoteCraft.db.global.pendingRun
    if not pending then return end
    if not isValidMPlusGroup() then
        NoteCraft.db.global.pendingRun = nil
        return
    end
    local stillInCM = safeCall(C_ChallengeMode.GetActiveChallengeMapID)
    if stillInCM then return end

    local now = time()
    if (now - lastProcessedTime) < DOUBLE_FIRE_WINDOW then return end
    lastProcessedTime = now

    for _, m in ipairs(pending.members or {}) do
        MP:Record(m.key, pending.mapID, pending.level, false, m.role)
    end
    local runInfo = {
        mapID   = pending.mapID,
        level   = pending.level,
        onTime  = false,
        members = pending.members,
        outcome = "ABANDONED",
    }
    NoteCraft.db.global.pendingRun = nil

    if NoteCraft.PostRunDialog and NoteCraft.PostRunDialog.Show and
       NoteCraft.db.global.config.autoShowPostRunDialog then
        NoteCraft.PostRunDialog:Show(runInfo)
    end
end

function MP:Record(key, mapID, level, onTime, role)
    if not key then return end
    local g = NoteCraft.db.global
    local p = g.players[key]
    if not p then
        p = NoteCraft.Util.CreateStubPlayer(key, key)
        g.players[key] = p
    end
    if p.mPlusRuns and #p.mPlusRuns > 0 then
        local last = p.mPlusRuns[#p.mPlusRuns]
        if last.mapID == mapID and last.level == level and (time() - last.date) < 10 then
            return
        end
    end
    if onTime then
        p.mPlusPositive = (p.mPlusPositive or 0) + 1
    else
        p.mPlusNegative = (p.mPlusNegative or 0) + 1
    end
    p.encounters = (p.encounters or 0) + 1
    p.mPlusRuns = p.mPlusRuns or {}
    table.insert(p.mPlusRuns, {
        date   = time(),
        mapID  = mapID,
        level  = level,
        onTime = onTime and true or false,
        role   = role,
    })
    NoteCraft.Util.TrimList(p.mPlusRuns, g.config.maxMPlusRunsPerPlayer or 50)
    p.lastSeen = time()
end
