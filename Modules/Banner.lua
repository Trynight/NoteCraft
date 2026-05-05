local NoteCraft = LibStub("AceAddon-3.0"):GetAddon("NoteCraft")
local Banner = NoteCraft:NewModule("Banner")

-- Adds a small NoteCraft summary line to the Mythic+ end-of-run banner
-- (`ChallengeModeCompleteBanner`). Triggered after a key completes.
--
-- Hook chain mirrors RaiderIO's pattern: TopBannerManager_Show fires once per
-- banner show, we then hook the banner's PlayBanner method to know the exact
-- moment the animation begins so our overlay text doesn't flash before the
-- main banner content is laid out.

local hookedTopManager = false
local hookedBanner = false

local overlayText  -- single FontString reused across runs

local function ensureOverlay(frame)
    if overlayText and overlayText:GetParent() == frame then return overlayText end
    overlayText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    overlayText:SetPoint("BOTTOM", frame, "BOTTOM", 0, 8)
    overlayText:SetJustifyH("CENTER")
    overlayText:SetWidth(700)
    return overlayText
end

local function buildSummary(bannerData)
    if not bannerData then return nil end
    local members = bannerData.upgradeMembers or bannerData.members or {}
    local positive = bannerData.onTime and true or false
    local affected = {}
    local g = NoteCraft.db.global

    for _, m in ipairs(members) do
        local fullName = m.name
        if fullName then
            local key = NoteCraft.Util.NormalizePlayerKey(fullName)
            local p = g.players[key]
            if p and not UnitIsUnit("player", fullName) then
                local total = (p.mPlusPositive or 0) + (p.mPlusNegative or 0)
                affected[#affected + 1] = {
                    display = NoteCraft.Util.DisplayName(p),
                    pos     = p.mPlusPositive or 0,
                    total   = total,
                    tag     = p.tag,
                }
            end
        end
    end

    if #affected == 0 then return nil end

    local pieces = {}
    for _, a in ipairs(affected) do
        local hex = a.tag and NoteCraft:GetTagColor(a.tag) or "ffffffff"
        pieces[#pieces + 1] = string.format("|c%s%s|r %d/%d", hex, a.display, a.pos, a.total)
    end

    local prefix = positive and "|cff00ff00NoteCraft +1 in time|r" or "|cffff8000NoteCraft +1 not in time|r"
    return prefix .. "  " .. table.concat(pieces, "  ")
end

local function onPlayBanner(frame, bannerData)
    local fs = ensureOverlay(frame)
    local text = buildSummary(bannerData)
    if text then
        fs:SetText(text)
        fs:Show()
    else
        fs:SetText("")
        fs:Hide()
    end
end

local function onTopBannerManagerShow(self)
    if hookedBanner then return end
    local frame = _G.ChallengeModeCompleteBanner
    if not frame or frame ~= self then return end
    hookedBanner = true
    hooksecurefunc(frame, "PlayBanner", onPlayBanner)
end

function Banner:OnEnable()
    if hookedTopManager then return end
    if not _G.TopBannerManager_Show then return end
    hooksecurefunc("TopBannerManager_Show", onTopBannerManagerShow)
    hookedTopManager = true
end
