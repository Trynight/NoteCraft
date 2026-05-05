local NoteCraft = LibStub("AceAddon-3.0"):GetAddon("NoteCraft")
local FT = NoteCraft:NewModule("FriendsTooltip")

-- The friends panel uses a custom frame `FriendsTooltip` (NOT the unit tooltip
-- system), so `TooltipDataProcessor` doesn't fire on hover there. We open a
-- secondary GameTooltip anchored to FriendsTooltip and populate it with our note.

local hooked = false

local function getFriendDisplayName(button)
    if not button then return nil end
    local btype = button.buttonType
    if btype == FRIENDS_BUTTON_TYPE_BNET and C_BattleNet and C_BattleNet.GetFriendAccountInfo then
        local info = C_BattleNet.GetFriendAccountInfo(button.id)
        if info and info.gameAccountInfo then
            local g = info.gameAccountInfo
            local name, realm = g.characterName, g.realmName
            if name and name ~= "" then
                if realm and realm ~= "" then return name .. "-" .. realm end
                return name
            end
        end
    elseif btype == FRIENDS_BUTTON_TYPE_WOW and C_FriendList and C_FriendList.GetFriendInfoByIndex then
        local info = C_FriendList.GetFriendInfoByIndex(button.id)
        if info and info.name and info.name ~= "" then
            return info.name  -- already in "Name-Realm" form when cross-realm, or bare for same-realm
        end
    end
end

local function onFriendsTooltipShow(self)
    if not NoteCraft.db or not NoteCraft.db.global.config.enableTooltip then return end
    local display = getFriendDisplayName(self.button)
    if not display then return end
    local key = NoteCraft.Util.NormalizePlayerKey(display)
    local p = NoteCraft.db.global.players[key]
    if not p then return end

    GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT", -self:GetWidth(), -4)
    GameTooltip:ClearLines()
    if NoteCraft.TooltipAppendInfo then
        NoteCraft.TooltipAppendInfo(GameTooltip, p)
    end
    GameTooltip:Show()
end

local function onFriendsTooltipHide()
    GameTooltip:Hide()
end

function FT:OnEnable()
    if hooked then return end
    if FriendsTooltip then
        hooksecurefunc(FriendsTooltip, "Show", onFriendsTooltipShow)
        hooksecurefunc(FriendsTooltip, "Hide", onFriendsTooltipHide)
        hooked = true
    end
end
