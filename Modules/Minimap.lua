local NoteCraft = LibStub("AceAddon-3.0"):GetAddon("NoteCraft")
local M = NoteCraft:NewModule("Minimap")

-- Adds a draggable LibDBIcon button on the minimap edge:
--   left-click  -> toggle the main NoteCraft window
--   right-click -> open Options panel
--   tooltip     -> brief stats summary

local LDB    = LibStub("LibDataBroker-1.1", true)
local LDBIcon = LibStub("LibDBIcon-1.0", true)

local registered = false

local function buildTooltip(tooltip)
    if not tooltip or not tooltip.AddLine then return end
    tooltip:ClearLines()
    tooltip:AddLine("|cffffffff" .. NoteCraft.L["NoteCraft"] .. "|r")
    if NoteCraft.db then
        local n = 0
        for _ in pairs(NoteCraft.db.global.players or {}) do n = n + 1 end
        tooltip:AddLine(string.format(NoteCraft.L["%d players tracked"], n), 0.8, 0.8, 1)
    end
    tooltip:AddLine(" ")
    tooltip:AddLine(NoteCraft.L["|cff00ff00Left-click|r open window"], 1, 1, 1)
    tooltip:AddLine(NoteCraft.L["|cff00ff00Right-click|r open options"], 1, 1, 1)
end

local function onClick(_, button)
    if button == "RightButton" then
        if NoteCraft.Options and NoteCraft.Options.Open then NoteCraft.Options:Open() end
    else
        if NoteCraft.MainWindow and NoteCraft.MainWindow.Toggle then NoteCraft.MainWindow:Toggle() end
    end
end

function M:OnEnable()
    if registered or not LDB or not LDBIcon then return end

    local dataObject = LDB:NewDataObject("NoteCraft", {
        type    = "launcher",
        text    = "NoteCraft",
        icon    = "Interface\\AddOns\\NoteCraft\\Media\\logo.png",
        OnClick = onClick,
        OnTooltipShow = buildTooltip,
    })

    LDBIcon:Register("NoteCraft", dataObject, NoteCraft.db.global.minimap)
    registered = true
end

function M:Show()
    if LDBIcon then LDBIcon:Show("NoteCraft") end
    if NoteCraft.db then NoteCraft.db.global.minimap.hide = false end
end

function M:Hide()
    if LDBIcon then LDBIcon:Hide("NoteCraft") end
    if NoteCraft.db then NoteCraft.db.global.minimap.hide = true end
end

function M:Toggle()
    if NoteCraft.db.global.minimap.hide then self:Show() else self:Hide() end
end
