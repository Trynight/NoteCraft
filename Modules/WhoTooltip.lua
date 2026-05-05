local _, ns = ...
local NoteCraft = LibStub("AceAddon-3.0"):GetAddon("NoteCraft")
local WT = NoteCraft:NewModule("WhoTooltip")

-- Adds an OnEnter / OnLeave tooltip on each row of the /who results window,
-- showing the NoteCraft summary for any player we already know.

local hooked = false

local function getWhoIndex(button)
    return button and (button.index or button.whoIndex)
end

local function onEnter(self)
    if not NoteCraft.db or not NoteCraft.db.global.config.enableTooltip then return end
    local idx = getWhoIndex(self)
    if not idx or not C_FriendList or not C_FriendList.GetWhoInfo then return end
    local info = C_FriendList.GetWhoInfo(idx)
    if not info or not info.fullName or info.fullName == "" then return end
    local p = NoteCraft.db.global.players[NoteCraft.Util.NormalizePlayerKey(info.fullName)]
    if not p then return end

    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:ClearLines()
    GameTooltip:AddLine(NoteCraft.Util.DisplayName(p), 1, 1, 1)
    if NoteCraft.TooltipAppendInfo then NoteCraft.TooltipAppendInfo(GameTooltip, p) end
    GameTooltip:Show()
end

local function onLeave() GameTooltip:Hide() end
local function onScroll() if GameTooltip:IsShown() then GameTooltip:Hide() end end

local hookMap = { OnEnter = onEnter, OnLeave = onLeave }

function WT:OnEnable()
    if hooked then return end
    local SH = ns.ScrollHook
    local box = _G.WhoFrame and _G.WhoFrame.ScrollBox
    if box then
        SH.OnViewFramesChanged(box, function(buttons) SH.MapOn(buttons, hookMap) end)
        SH.OnViewScrollChanged(box, onScroll)
        hooked = true
    end
end
