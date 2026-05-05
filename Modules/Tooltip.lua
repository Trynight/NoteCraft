local NoteCraft = LibStub("AceAddon-3.0"):GetAddon("NoteCraft")
local TT = NoteCraft:NewModule("Tooltip")

local hooked = false

local function lookupPlayer(unit)
    if not unit or not UnitIsPlayer(unit) then return nil end
    local name, realm = UnitFullName(unit)
    if not name then return nil end
    if not realm or realm == "" then realm = GetNormalizedRealmName() end
    local key = NoteCraft.Util.NormalizePlayerKey(name, realm)
    return NoteCraft.db.global.players[key]
end

local function appendInfo(tooltip, p)
    local L   = NoteCraft.L
    local cfg = NoteCraft.db.global.config
    local color = NoteCraft:GetTagColor(p.tag)

    tooltip:AddLine(" ")
    local header
    if p.tag then
        local label = NoteCraft:GetTagLabel(p.tag)
        header = string.format("|c%s%s [%s]|r", color, L["NoteCraft"], label)
    else
        header = string.format("|cffaaaaaa%s|r", L["NoteCraft"])
    end
    tooltip:AddLine(header)

    if p.title and p.title ~= "" then
        tooltip:AddLine(p.title, 1, 0.85, 0.2)
    end
    if p.note and p.note ~= "" then
        tooltip:AddLine('"' .. p.note .. '"', 1, 1, 0.6, true)
    end

    if cfg.tooltipShowMPlus then
        local pos = p.mPlusPositive or 0
        local total = pos + (p.mPlusNegative or 0)
        if total > 0 then
            tooltip:AddLine(string.format(L["M+: %d/%d in time"], pos, total), 1, 1, 1)
        end
    end

    if cfg.tooltipShowEncounters and (p.encounters or 0) > 1 then
        tooltip:AddLine(string.format(L["Played together: %d times"], p.encounters), 0.7, 0.7, 1)
    end
end

local function onUnitTooltip(tooltip, data)
    if tooltip ~= GameTooltip then return end
    -- Honor user toggle without re-installing the hook.
    if not NoteCraft.db or not NoteCraft.db.global.config.enableTooltip then return end
    local _, unit = tooltip:GetUnit()
    local p = lookupPlayer(unit)
    if not p and data and data.guid then
        local key = NoteCraft.db.global.guidIndex[data.guid]
        if key then p = NoteCraft.db.global.players[key] end
    end
    if not p then return end
    appendInfo(tooltip, p)
end

function TT:OnEnable()
    if hooked then return end
    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, onUnitTooltip)
        hooked = true
    end
    -- TooltipDataProcessor handlers cannot be unregistered in current API,
    -- so OnDisable can only no-op; we gate calls via NoteCraft.db.global.config.enableTooltip.
end

function TT:OnDisable()
    -- Soft-disable: leave the hook installed but it now early-returns because
    -- we re-check the player record (which is still tracked); for full disable
    -- the user can toggle the option which is checked at OnEnable for new runs.
end

-- Public for other modules (LFG) to call directly.
NoteCraft.TooltipAppendInfo = appendInfo
NoteCraft.TooltipLookupPlayer = lookupPlayer
