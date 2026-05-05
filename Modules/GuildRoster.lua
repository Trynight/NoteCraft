local _, ns = ...
local NoteCraft = LibStub("AceAddon-3.0"):GetAddon("NoteCraft")
local GR = NoteCraft:NewModule("GuildRoster")

-- Adds a NoteCraft tooltip on hover over each row of the Guild Roster
-- (`GuildRosterContainer.ScrollBox` in retail, `GuildListScrollFrame` legacy).

local hookedScrollBox = false

local function getNameForRow(button)
    local idx = button and (button.index or button.guildIndex)
    if not idx or not _G.GetGuildRosterInfo then return nil end
    local fullName = _G.GetGuildRosterInfo(idx)
    if not fullName or fullName == "" then return nil end
    return fullName
end

local function onEnter(self)
    if not NoteCraft.db or not NoteCraft.db.global.config.enableTooltip then return end
    local fullName = getNameForRow(self)
    if not fullName then return end
    local p = NoteCraft.db.global.players[NoteCraft.Util.NormalizePlayerKey(fullName)]
    if not p then return end
    GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
    GameTooltip:ClearLines()
    GameTooltip:AddLine(NoteCraft.Util.DisplayName(p), 1, 1, 1)
    if NoteCraft.TooltipAppendInfo then NoteCraft.TooltipAppendInfo(GameTooltip, p) end
    GameTooltip:Show()
end

local function onLeave() GameTooltip:Hide() end
local function onScroll() if GameTooltip:IsShown() then GameTooltip:Hide() end end

local hookMap = { OnEnter = onEnter, OnLeave = onLeave }

function GR:OnEnable()
    if hookedScrollBox then return end
    local SH = ns.ScrollHook
    -- Retail Guild Roster.
    local container = _G.GuildRosterContainer
    local box = container and (container.ScrollBox or container)
    if box then
        SH.OnViewFramesChanged(box, function(buttons) SH.MapOn(buttons, hookMap) end)
        SH.OnViewScrollChanged(box, onScroll)
        hookedScrollBox = true
    end
end
