local NoteCraft = LibStub("AceAddon-3.0"):GetAddon("NoteCraft")
local CM = NoteCraft:NewModule("ChatMenu")

-- Modern Blizzard menu API (used by most unit-frame popups in current WoW).
local PLAYER_MENU_TAGS = {
    "MENU_UNIT_SELF",
    "MENU_UNIT_PLAYER",
    "MENU_UNIT_PARTY",
    "MENU_UNIT_RAID",
    "MENU_UNIT_RAID_PLAYER",
    "MENU_UNIT_FRIEND",
    "MENU_UNIT_FRIEND_OFFLINE",
    "MENU_UNIT_ENEMY_PLAYER",
    "MENU_UNIT_ARENAENEMY",
    "MENU_UNIT_OTHER_PLAYER",
    "MENU_UNIT_GUILD",
    "MENU_UNIT_GUILD_OFFLINE",
    "MENU_UNIT_BN_FRIEND",
    "MENU_UNIT_BN_FRIEND_PLAYER",
    "MENU_UNIT_COMMUNITIES_GUILD_MEMBER",
    "MENU_UNIT_COMMUNITIES_MEMBER",
    "MENU_UNIT_CHAT_ROSTER",
    "MENU_UNIT_TARGET",
    "MENU_UNIT_FOCUS",
    "MENU_UNIT_PLAYER_FRAME",
    "MENU_UNIT_WORLD_STATE_SCORE",
}

-- LFG-specific menu tags (right-click on a search entry / applicant member).
-- These don't carry contextData like MENU_UNIT_*; we resolve via owner frame.
local LFG_MENU_TAGS = {
    "MENU_LFG_FRAME_SEARCH_ENTRY",
    "MENU_LFG_FRAME_MEMBER_APPLY",
}

-- Legacy UIDropDownMenu types (used by chat hyperlink popups, friends list, etc.).
-- These must be matched against `bdropdown.which` from LibDropDownExtension.
local VALID_LEGACY_TYPES = {
    SELF = true, PLAYER = true, PARTY = true, RAID = true, RAID_PLAYER = true,
    FRIEND = true, FRIEND_OFFLINE = true, ENEMY_PLAYER = true, ARENAENEMY = true,
    OTHER_PLAYER = true, GUILD = true, GUILD_OFFLINE = true,
    BN_FRIEND = true, COMMUNITIES_WOW_MEMBER = true, COMMUNITIES_GUILD_MEMBER = true,
    CHAT_ROSTER = true, TARGET = true, FOCUS = true, WORLD_STATE_SCORE = true,
}

local registeredModern = false
local registeredLegacy = false

-- ----------------------------------------------------------------------------
-- Common helpers
-- ----------------------------------------------------------------------------

local function isEnabled()
    return NoteCraft.db and NoteCraft.db.global.config.enableChatMenu
end

local function setTag(displayName, tag)
    local pl = select(1, NoteCraft:GetOrCreatePlayer(displayName))
    if pl then pl.tag = tag end
end

local function clearTag(displayName)
    local p = NoteCraft.db.global.players[NoteCraft.Util.NormalizePlayerKey(displayName)]
    if p then p.tag = nil end
end

local function hasTag(displayName)
    local p = NoteCraft.db.global.players[NoteCraft.Util.NormalizePlayerKey(displayName)]
    return p and p.tag ~= nil
end

local function openNote(displayName)
    if NoteCraft.NoteDialog then NoteCraft.NoteDialog:Show(displayName) end
end

local function viewHistory(displayName)
    if NoteCraft.HistoryDialog then
        NoteCraft.HistoryDialog:Show(displayName)
    elseif NoteCraft.MainWindow then
        NoteCraft.MainWindow:ShowPlayer(displayName)
    end
end

-- ----------------------------------------------------------------------------
-- Modern menu (Menu.ModifyMenu) — submenu structure
-- ----------------------------------------------------------------------------

local function resolveDisplayNameModern(contextData)
    if not contextData then return nil end
    local unit = contextData.unit or contextData.UnitToken
    if unit and UnitExists(unit) and UnitIsPlayer(unit) then
        local name, realm = UnitFullName(unit)
        if name and name ~= "" then
            if not realm or realm == "" then realm = GetNormalizedRealmName() or "" end
            return realm ~= "" and (name .. "-" .. realm) or name
        end
    end
    local name = contextData.name or contextData.unitName or contextData.accountName
    local realm = contextData.server or contextData.realm
    if name and name:find("-", 1, true) then return name end
    if name and name ~= "" then
        return realm and realm ~= "" and (name .. "-" .. realm) or name
    end
end

-- For LFG-specific menus (search entry / applicant), context comes from the
-- owner frame (resultID or memberIdx+parent.applicantID), not contextData.
local function resolveLFGOwner(owner)
    if not owner or not C_LFGList then return nil end
    local resultID = owner.resultID
    if resultID and C_LFGList.GetSearchResultInfo then
        local info = C_LFGList.GetSearchResultInfo(resultID)
        if info and info.leaderName and info.leaderName ~= "" then
            return info.leaderName
        end
    end
    local memberIdx = owner.memberIdx
    if memberIdx and C_LFGList.GetApplicantMemberInfo then
        local parent = owner.GetParent and owner:GetParent() or nil
        local applicantID = parent and parent.applicantID
        if applicantID then
            local fullName = C_LFGList.GetApplicantMemberInfo(applicantID, memberIdx)
            if fullName and fullName ~= "" then return fullName end
        end
    end
end

local function buildModernSubmenu(rootDescription, display)
    local L = NoteCraft.L
    rootDescription:CreateDivider()
    local sub = rootDescription:CreateButton(L["NoteCraft"])
    sub:CreateButton(L["Add Note"], function() openNote(display) end)
    sub:CreateDivider()
    for _, t in ipairs(NoteCraft:GetTags()) do
        local label = string.format("|c%s%s|r", t.color, t.label)
        local id = t.id
        sub:CreateButton(label, function() setTag(display, id) end)
    end
    if hasTag(display) then
        sub:CreateButton(L["Clear Tag"], function() clearTag(display) end)
    end
    sub:CreateDivider()
    sub:CreateButton(L["View History"], function() viewHistory(display) end)
end

local function lfgMenuHandler(owner, rootDescription)
    if not isEnabled() then return end
    local display = resolveLFGOwner(owner)
    if not display then return end
    buildModernSubmenu(rootDescription, display)
end

local function modernMenuHandler(_, rootDescription, contextData)
    if not isEnabled() then return end
    local display = resolveDisplayNameModern(contextData)
    if not display then return end
    buildModernSubmenu(rootDescription, display)
end

-- ----------------------------------------------------------------------------
-- Legacy UIDropDownMenu (LibDropDownExtension) — flat list with title divider
-- ----------------------------------------------------------------------------

local function resolveDisplayNameLegacy(bdropdown)
    if not bdropdown then return nil end
    local unit = bdropdown.unit
    if unit and UnitExists(unit) and UnitIsPlayer(unit) then
        local name, realm = UnitFullName(unit)
        if name and name ~= "" then
            if not realm or realm == "" then realm = GetNormalizedRealmName() or "" end
            return realm ~= "" and (name .. "-" .. realm) or name
        end
    end
    local name = bdropdown.name
    local realm = bdropdown.server
    if name and name:find("-", 1, true) then return name end
    if name and name ~= "" then
        return realm and realm ~= "" and (name .. "-" .. realm) or name
    end
end

local function legacyHandler(bdropdown, event, options, _level, _data)
    if event ~= "OnShow" then
        if options[1] then for i = #options, 1, -1 do options[i] = nil end; return true end
        return
    end
    if not isEnabled() then return end
    if not bdropdown or not bdropdown.which or not VALID_LEGACY_TYPES[bdropdown.which] then return end
    local display = resolveDisplayNameLegacy(bdropdown)
    if not display then return end

    local L = NoteCraft.L
    local idx = 0
    local function add(o) idx = idx + 1; options[idx] = o end

    add({ text = L["NoteCraft"], isTitle = true, notCheckable = true })
    add({ text = L["Add Note"], notCheckable = true,
          func = function() openNote(display) end })
    for _, t in ipairs(NoteCraft:GetTags()) do
        local id = t.id
        local label = string.format("|c%s%s|r", t.color, t.label)
        add({ text = label, notCheckable = true,
              func = function() setTag(display, id) end })
    end
    if hasTag(display) then
        add({ text = L["Clear Tag"], notCheckable = true,
              func = function() clearTag(display) end })
    end
    add({ text = L["View History"], notCheckable = true,
          func = function() viewHistory(display) end })
    return true
end

-- ----------------------------------------------------------------------------
-- Module lifecycle
-- ----------------------------------------------------------------------------

function CM:OnEnable()
    if not registeredModern and Menu and Menu.ModifyMenu then
        for _, tag in ipairs(PLAYER_MENU_TAGS) do
            Menu.ModifyMenu(tag, modernMenuHandler)
        end
        for _, tag in ipairs(LFG_MENU_TAGS) do
            Menu.ModifyMenu(tag, lfgMenuHandler)
        end
        registeredModern = true
    end

    if not registeredLegacy then
        local lib = LibStub and LibStub:GetLibrary("LibDropDownExtension-1.0", true)
        if lib then
            lib:RegisterEvent("OnShow OnHide", legacyHandler, 1)
            registeredLegacy = true
        end
    end
end

function CM:OnDisable()
    -- Both APIs honor the cfg flag at runtime via isEnabled(); no clean removal needed.
end
