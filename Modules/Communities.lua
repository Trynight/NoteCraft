local _, ns = ...
local NoteCraft = LibStub("AceAddon-3.0"):GetAddon("NoteCraft")
local C = NoteCraft:NewModule("Communities")

-- Adds NoteCraft hover tooltips on the Communities member list and the
-- Club Finder community/guild cards.

local hooked = false

local function clubMemberDisplayName(button)
    local clubInfo = button and (button.memberInfo or button.GetMemberInfo and button:GetMemberInfo())
    if not clubInfo then return nil end
    local name = clubInfo.name
    local realm = clubInfo.realm or clubInfo.server
    if not name or name == "" then return nil end
    if name:find("-", 1, true) then return name end
    if realm and realm ~= "" then return name .. "-" .. realm end
    return name
end

local function onEnter(self)
    if not NoteCraft.db or not NoteCraft.db.global.config.enableTooltip then return end
    local display = clubMemberDisplayName(self)
    if not display then return end
    local p = NoteCraft.db.global.players[NoteCraft.Util.NormalizePlayerKey(display)]
    if not p then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    GameTooltip:AddLine(NoteCraft.Util.DisplayName(p), 1, 1, 1)
    if NoteCraft.TooltipAppendInfo then NoteCraft.TooltipAppendInfo(GameTooltip, p) end
    GameTooltip:Show()
end

local function onLeave() GameTooltip:Hide() end
local function onScroll() if GameTooltip:IsShown() then GameTooltip:Hide() end end

local hookMap = { OnEnter = onEnter, OnLeave = onLeave }

local function hookScrollBox(box)
    if not box then return end
    local SH = ns.ScrollHook
    SH.OnViewFramesChanged(box, function(buttons) SH.MapOn(buttons, hookMap) end)
    SH.OnViewScrollChanged(box, onScroll)
end

local function hookCardSet(cardSet)
    if not cardSet or not cardSet.Cards then return end
    local SH = ns.ScrollHook
    SH.MapOn(cardSet.Cards, hookMap)
    if cardSet.RefreshLayout then
        hooksecurefunc(cardSet, "RefreshLayout", function()
            SH.MapOn(cardSet.Cards, hookMap)
        end)
    end
end

function C:OnEnable()
    if hooked then return end

    -- Communities member list (open Communities frame, click guild/community).
    if _G.CommunitiesFrame and _G.CommunitiesFrame.MemberList then
        hookScrollBox(_G.CommunitiesFrame.MemberList.ScrollBox)
    end

    -- Club Finder — guild and community cards (browse + pending).
    local guildFinder = _G.ClubFinderGuildFinderFrame
    if guildFinder then
        if guildFinder.CommunityCards then hookScrollBox(guildFinder.CommunityCards.ScrollBox) end
        if guildFinder.PendingCommunityCards then hookScrollBox(guildFinder.PendingCommunityCards.ScrollBox) end
        hookCardSet(guildFinder.GuildCards)
        hookCardSet(guildFinder.PendingGuildCards)
    end
    local commGuildFinder = _G.ClubFinderCommunityAndGuildFinderFrame
    if commGuildFinder then
        if commGuildFinder.CommunityCards then hookScrollBox(commGuildFinder.CommunityCards.ScrollBox) end
        if commGuildFinder.PendingCommunityCards then hookScrollBox(commGuildFinder.PendingCommunityCards.ScrollBox) end
        hookCardSet(commGuildFinder.GuildCards)
        hookCardSet(commGuildFinder.PendingGuildCards)
    end

    hooked = true
end
