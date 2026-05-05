local _, ns = ...

local CURRENT_DB_VERSION = 3

-- Built-in tag set installed for new accounts (v2 schema). Each entry has a
-- stable `id` (used as the player.tag value), a display `label`, a hex color,
-- and a `builtin` flag (built-ins can be edited but not deleted).
local DEFAULT_TAGS = {
    { id = "GOOD",    label = "GOOD",    color = "ff00ff00", builtin = true },
    { id = "BAD",     label = "BAD",     color = "ffff0000", builtin = true },
    { id = "CAUTION", label = "CAUTION", color = "ffffff00", builtin = true },
    { id = "NEUTRAL", label = "NEUTRAL", color = "ffaaaaaa", builtin = true },
}

local DB_DEFAULTS = {
    global = {
        dbVersion = CURRENT_DB_VERSION,
        config = {
            enableTooltip          = true,
            enableLFG              = true,
            enableChatMenu         = true,
            enableAlerts           = true,
            alertTags              = { BAD = true, CAUTION = true },
            tooltipShowEncounters  = true,
            tooltipShowMPlus       = true,
            maxMPlusRunsPerPlayer  = 50,
            autoShowPostRunDialog  = true,
        },
        tags       = DEFAULT_TAGS,        -- AceDB clones the array on first init
        minimap    = { hide = false },    -- LibDBIcon-1.0 position
        players    = {},
        guidIndex  = {},
        pendingRun = nil,
    },
}

-- Migration handlers keyed by *target* dbVersion. Each receives `db.global`.
local migrations = {}

-- v2 -> v3: add p.title and p.roleCounts to existing player records.
migrations[3] = function(g)
    for _, p in pairs(g.players or {}) do
        if p.title == nil then p.title = nil end
        if p.roleCounts == nil then p.roleCounts = { TANK = 0, HEALER = 0, DAMAGER = 0 } end
        -- Backfill roleCounts from existing mPlusRuns.
        for _, run in ipairs(p.mPlusRuns or {}) do
            local r = run.role
            if r == "TANK" or r == "HEALER" or r == "DAMAGER" then
                p.roleCounts[r] = (p.roleCounts[r] or 0) + 1
            end
        end
    end
end

-- v1 -> v2: move config.tagColors into a `tags` array of records, drop tagColors.
migrations[2] = function(g)
    if g.tags and #g.tags > 0 then return end
    local oldColors = g.config and g.config.tagColors
    local tags = {}
    if oldColors then
        for _, def in ipairs(DEFAULT_TAGS) do
            tags[#tags + 1] = {
                id      = def.id,
                label   = def.label,
                color   = oldColors[def.id] or def.color,
                builtin = true,
            }
        end
        g.config.tagColors = nil
    else
        for _, def in ipairs(DEFAULT_TAGS) do
            tags[#tags + 1] = { id = def.id, label = def.label, color = def.color, builtin = true }
        end
    end
    g.tags = tags
end

local function runMigrations(g)
    if not g.dbVersion then g.dbVersion = 1 end
    for v = g.dbVersion + 1, CURRENT_DB_VERSION do
        local m = migrations[v]
        if m then m(g) end
        g.dbVersion = v
    end
end

-- Drop a stale pendingRun (older than 5 minutes) and flush as negative outcomes.
local function flushStalePendingRun(g)
    local pending = g.pendingRun
    if not pending or not pending.startTime then return end
    if (time() - pending.startTime) < 300 then return end
    for _, m in ipairs(pending.members or {}) do
        local p = g.players[m.key]
        if p then
            p.mPlusNegative = (p.mPlusNegative or 0) + 1
            table.insert(p.mPlusRuns, {
                date   = pending.startTime,
                mapID  = pending.mapID,
                level  = pending.level,
                onTime = false,
                role   = m.role,
            })
            local maxN = (g.config and g.config.maxMPlusRunsPerPlayer) or 50
            while #p.mPlusRuns > maxN do table.remove(p.mPlusRuns, 1) end
        end
    end
    g.pendingRun = nil
end

-- Re-seed tags array if it ended up empty (e.g. user deleted everything via UI).
local function ensureTagsPresent(g)
    if not g.tags or #g.tags == 0 then
        g.tags = {}
        for _, def in ipairs(DEFAULT_TAGS) do
            g.tags[#g.tags + 1] = { id = def.id, label = def.label, color = def.color, builtin = true }
        end
    end
end

local Database = {
    DEFAULTS           = DB_DEFAULTS,
    DEFAULT_TAGS       = DEFAULT_TAGS,
    CURRENT_DB_VERSION = CURRENT_DB_VERSION,
}

function Database:RunMigrations(global)
    runMigrations(global)
    ensureTagsPresent(global)
    flushStalePendingRun(global)
end

ns.Database = Database
