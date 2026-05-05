local NoteCraft = LibStub("AceAddon-3.0"):GetAddon("NoteCraft")
local WCF = NoteCraft:NewModule("WhoChatFilter")

-- Appends a NoteCraft summary to /who results printed in chat (CHAT_MSG_SYSTEM).
-- The Blizzard /who output uses the system-wide `WHO_LIST_FORMAT` /
-- `WHO_LIST_GUILD_FORMAT` patterns, so we extract the player name and look it
-- up in our DB. If we know the player, we append [tag note] or M+ counts.

local registered = false

-- Strip color codes / hyperlinks to extract the bare name token.
local function extractPlayerName(message)
    if not message then return nil end
    -- WHO_LIST_FORMAT examples (en):
    --   "[%s] %s (%s)%s, %d, %s, %s, %s"  -> [Lvl] Name (Race) Class, Zone, ...
    --   "[%s] %s (%s) (%s)%s, %d, %s, %s" -> [Lvl] Name (Race) (GuildName) Class, ...
    -- We try to grab the token immediately after the [Lvl] bracket.
    local name = message:match("^%[[^%]]+%]%s+([^%s%(]+)")
    return name
end

local function summaryForPlayer(p)
    local tag = p.tag
    local hex = NoteCraft:GetTagColor(tag)
    local pieces = {}
    if tag then
        pieces[#pieces + 1] = string.format("|c%s[%s]|r", hex, NoteCraft:GetTagLabel(tag))
    end
    local total = (p.mPlusPositive or 0) + (p.mPlusNegative or 0)
    if total > 0 then
        pieces[#pieces + 1] = string.format("|cffaaaaffM+ %d/%d|r", p.mPlusPositive or 0, total)
    end
    if (p.encounters or 0) > 1 then
        pieces[#pieces + 1] = string.format("|cffaaccffx%d|r", p.encounters)
    end
    if p.note and p.note ~= "" then
        pieces[#pieces + 1] = '|cffffff80"' .. p.note .. '"|r'
    end
    if not pieces[1] then return nil end
    return " " .. table.concat(pieces, " ")
end

local function filter(_chatFrame, _event, message, ...)
    if not NoteCraft.db or not NoteCraft.db.global.config.enableTooltip then
        return false, message, ...
    end
    local name = extractPlayerName(message)
    if not name then return false, message, ... end
    local p = NoteCraft.db.global.players[NoteCraft.Util.NormalizePlayerKey(name)]
    if not p then return false, message, ... end
    local extra = summaryForPlayer(p)
    if not extra then return false, message, ... end
    return false, message .. extra, ...
end

function WCF:OnEnable()
    if registered or not _G.ChatFrame_AddMessageEventFilter then return end
    ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", filter)
    registered = true
end
