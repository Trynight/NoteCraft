local ADDON_NAME, ns = ...

local NoteCraft = LibStub("AceAddon-3.0"):NewAddon(
    ADDON_NAME, "AceEvent-3.0", "AceConsole-3.0"
)
_G[ADDON_NAME] = NoteCraft

NoteCraft.L        = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)
NoteCraft.Util     = ns.Util
NoteCraft.Database = ns.Database

function NoteCraft:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("NoteCraftDB", self.Database.DEFAULTS, true)
    self.Database:RunMigrations(self.db.global)
    if self.Options and self.Options.Register then
        self.Options:Register()
    end
end

function NoteCraft:OnEnable()
    -- Modules created via NewModule() in their files; enable order is implicit
    -- but we toggle conditional ones based on saved config.
    local cfg = self.db.global.config

    local function enableModule(name, condition)
        local m = self:GetModule(name, true)
        if not m then return end
        if condition == false then
            self:DisableModule(name)
        else
            self:EnableModule(name)
        end
    end

    enableModule("Tooltip",        cfg.enableTooltip)
    enableModule("FriendsTooltip", cfg.enableTooltip)
    enableModule("WhoTooltip",     cfg.enableTooltip)
    enableModule("WhoChatFilter",  cfg.enableTooltip)
    enableModule("GuildRoster",    cfg.enableTooltip)
    enableModule("Communities",    cfg.enableTooltip)
    enableModule("Banner",         cfg.enableTooltip)
    enableModule("LFG",            cfg.enableLFG)
    enableModule("ChatMenu",       cfg.enableChatMenu)
    enableModule("Minimap",        true)
    enableModule("Alert",          cfg.enableAlerts)

    self:Print(self.L["NoteCraft loaded. Type /nc for help."])
end

-- Find or create a player record by display name (e.g. typed "Roby-Pozzo").
-- Returns (record, key). Always returns non-nil values when input is non-empty.
function NoteCraft:GetOrCreatePlayer(displayName)
    if not displayName or displayName == "" then return nil, nil end
    local key = self.Util.NormalizePlayerKey(displayName)
    if not key then return nil, nil end
    local p = self.db.global.players[key]
    if not p then
        p = self.Util.CreateStubPlayer(key, displayName)
        self.db.global.players[key] = p
    end
    return p, key
end

-- ----------------------------------------------------------------------------
-- Tag management
-- ----------------------------------------------------------------------------

local DEFAULT_COLOR = "ffaaaaaa"

function NoteCraft:GetTags()
    return self.db.global.tags
end

function NoteCraft:GetTag(id)
    if not id then return nil end
    for _, t in ipairs(self.db.global.tags) do
        if t.id == id then return t end
    end
end

function NoteCraft:GetTagColor(id)
    local t = self:GetTag(id)
    return (t and t.color) or DEFAULT_COLOR
end

function NoteCraft:GetTagLabel(id)
    local t = self:GetTag(id)
    return (t and t.label) or id or ""
end

function NoteCraft:IsValidTag(id)
    return self:GetTag(id) ~= nil
end

local function sanitizeTagId(s)
    if type(s) ~= "string" then return nil end
    s = s:upper():gsub("[^%w_]", "_"):gsub("__+", "_"):gsub("^_+", ""):gsub("_+$", "")
    if s == "" then return nil end
    return s
end

local function sanitizeColor(s)
    if type(s) ~= "string" then return DEFAULT_COLOR end
    s = s:gsub("|c", ""):gsub("|r", "")
    if not s:match("^%x%x%x%x%x%x%x%x$") then
        if s:match("^%x%x%x%x%x%x$") then s = "ff" .. s
        else return DEFAULT_COLOR end
    end
    return s:lower()
end

function NoteCraft:AddTag(label, color)
    local id = sanitizeTagId(label)
    if not id then return nil, "invalid label" end
    if self:GetTag(id) then return nil, "duplicate id" end
    local tag = { id = id, label = label, color = sanitizeColor(color) }
    table.insert(self.db.global.tags, tag)
    return tag
end

function NoteCraft:UpdateTag(id, label, color)
    local t = self:GetTag(id)
    if not t then return false end
    if label and label ~= "" then t.label = label end
    if color then t.color = sanitizeColor(color) end
    return true
end

function NoteCraft:RemoveTag(id)
    local t = self:GetTag(id)
    if not t or t.builtin then return false end
    for i, x in ipairs(self.db.global.tags) do
        if x.id == id then table.remove(self.db.global.tags, i); break end
    end
    -- Detach from any player still pointing at this tag.
    for _, p in pairs(self.db.global.players) do
        if p.tag == id then p.tag = nil end
    end
    return true
end
