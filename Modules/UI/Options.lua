local NoteCraft = LibStub("AceAddon-3.0"):GetAddon("NoteCraft")
local AceConfig         = LibStub("AceConfig-3.0")
local AceConfigDialog   = LibStub("AceConfigDialog-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")

local Options = {}
NoteCraft.Options = Options

local function get(info)
    return NoteCraft.db.global.config[info[#info]]
end

local function set(info, value)
    NoteCraft.db.global.config[info[#info]] = value
end

-- ---------------------------------------------------------------------------
-- Minimap toggle
-- ---------------------------------------------------------------------------

local function getMinimapHidden()
    return NoteCraft.db.global.minimap and NoteCraft.db.global.minimap.hide
end

local function setMinimapHidden(_, hidden)
    if not NoteCraft.Minimap then return end
    if hidden then NoteCraft.Minimap:Hide() else NoteCraft.Minimap:Show() end
end

-- ---------------------------------------------------------------------------
-- Tag management — add / edit / delete
-- ---------------------------------------------------------------------------

local function tagColorRGB(hex)
    local h = hex or "ffaaaaaa"
    if #h == 8 then
        return tonumber(h:sub(3, 4), 16) / 255,
               tonumber(h:sub(5, 6), 16) / 255,
               tonumber(h:sub(7, 8), 16) / 255,
               tonumber(h:sub(1, 2), 16) / 255
    end
    return 1, 1, 1, 1
end

local function rgbToHex(r, g, b)
    return string.format("ff%02x%02x%02x", math.floor(r * 255 + 0.5),
                                            math.floor(g * 255 + 0.5),
                                            math.floor(b * 255 + 0.5))
end

local function notifyChange()
    AceConfigRegistry:NotifyChange("NoteCraft")
    if NoteCraft.MainWindow and NoteCraft.MainWindow.Refresh then
        NoteCraft.MainWindow:Refresh()
    end
end

-- New-tag widget state (held in module closure, not persistent).
local newTagLabel = ""
local newTagColor = "ff00ffff"

local function buildTagsGroup()
    local L = NoteCraft.L
    local args = {
        addHeader = { type = "header", name = L["Add new tag"], order = 1 },
        addLabel = {
            type = "input", order = 2,
            name = L["Label"], width = 1.5,
            get = function() return newTagLabel end,
            set = function(_, v) newTagLabel = v or "" end,
        },
        addColor = {
            type = "color", order = 3,
            name = L["Color"], hasAlpha = false, width = 0.5,
            get = function() return tagColorRGB(newTagColor) end,
            set = function(_, r, g, b) newTagColor = rgbToHex(r, g, b) end,
        },
        addBtn = {
            type = "execute", order = 4,
            name = L["Add Tag"], width = 1.0,
            func = function()
                if newTagLabel == "" then return end
                local _, err = NoteCraft:AddTag(newTagLabel, newTagColor)
                if not err then newTagLabel = "" end
                notifyChange()
            end,
        },
        listHeader = { type = "header", name = L["Existing tags"], order = 10 },
    }

    -- Build per-tag inline group (label edit, color picker, delete).
    for i, t in ipairs(NoteCraft:GetTags()) do
        local tagId = t.id
        args["tag_" .. tagId] = {
            type = "group", order = 10 + i, inline = true,
            name = string.format("|c%s%s|r (%s)%s",
                t.color, t.label, tagId, t.builtin and " [builtin]" or ""),
            args = {
                label = {
                    type = "input", order = 1,
                    name = NoteCraft.L["Label"], width = 1.5,
                    get = function()
                        local cur = NoteCraft:GetTag(tagId)
                        return cur and cur.label or ""
                    end,
                    set = function(_, v)
                        NoteCraft:UpdateTag(tagId, v, nil)
                        notifyChange()
                    end,
                },
                color = {
                    type = "color", order = 2,
                    name = NoteCraft.L["Color"], hasAlpha = false, width = 0.5,
                    get = function()
                        local cur = NoteCraft:GetTag(tagId)
                        return tagColorRGB(cur and cur.color)
                    end,
                    set = function(_, r, g, b)
                        NoteCraft:UpdateTag(tagId, nil, rgbToHex(r, g, b))
                        notifyChange()
                    end,
                },
                delete = {
                    type = "execute", order = 3,
                    name = NoteCraft.L["Delete"], width = 1.0,
                    confirm = true,
                    confirmText = NoteCraft.L["Delete this tag? Players using it will be cleared."],
                    disabled = function() return t.builtin end,
                    func = function()
                        NoteCraft:RemoveTag(tagId)
                        notifyChange()
                    end,
                },
            },
        }
    end

    return { type = "group", name = NoteCraft.L["Tags"], args = args }
end

-- ---------------------------------------------------------------------------
-- Root options
-- ---------------------------------------------------------------------------

local function buildOptions()
    local L = NoteCraft.L
    return {
        type = "group",
        name = L["NoteCraft Options"],
        childGroups = "tab",
        args = {
            general = {
                type = "group", order = 1, name = L["General"],
                args = {
                    headerUI = { type = "header", name = L["UI integrations"], order = 1 },
                    enableTooltip = {
                        type = "toggle", order = 2,
                        name = L["Enable tooltip integration"],
                        width = "full",
                        get = get, set = set,
                    },
                    tooltipShowEncounters = {
                        type = "toggle", order = 3,
                        name = L["Show 'Played together' counter in tooltip"],
                        width = "full",
                        get = get, set = set,
                    },
                    tooltipShowMPlus = {
                        type = "toggle", order = 4,
                        name = L["Show M+ summary in tooltip"],
                        width = "full",
                        get = get, set = set,
                    },
                    enableLFG = {
                        type = "toggle", order = 5,
                        name = L["Enable LFG applicant screening"],
                        width = "full",
                        get = get, set = set,
                    },
                    enableChatMenu = {
                        type = "toggle", order = 6,
                        name = L["Enable chat right-click menu"],
                        width = "full",
                        get = get, set = set,
                    },
                    enableAlerts = {
                        type = "toggle", order = 7,
                        name = L["Alert when a tagged player joins your group"],
                        width = "full",
                        get = get, set = set,
                    },
                    autoShowPostRunDialog = {
                        type = "toggle", order = 8,
                        name = L["Auto-show post-M+ run dialog"],
                        desc = L["Show a popup after each M+ run to quickly add notes and tags to party members."],
                        width = "full",
                        get = get, set = set,
                    },
                    headerMinimap = { type = "header", name = L["Minimap button"], order = 10 },
                    minimapHidden = {
                        type = "toggle", order = 11,
                        name = L["Hide minimap button"],
                        width = "full",
                        get = getMinimapHidden,
                        set = setMinimapHidden,
                    },
                    headerData = { type = "header", name = L["Data"], order = 20 },
                    maxMPlusRunsPerPlayer = {
                        type = "range", order = 21,
                        name = L["Max stored M+ runs per player"],
                        min = 10, max = 200, step = 5,
                        width = "full",
                        get = get, set = set,
                    },
                    resetSpacer = { type = "description", order = 99, name = " ", width = "full" },
                    resetAll = {
                        type = "execute", order = 100,
                        name = L["Reset all data"],
                        confirm = true,
                        func = function()
                            NoteCraft.db.global.players = {}
                            NoteCraft.db.global.guidIndex = {}
                            NoteCraft.db.global.pendingRun = nil
                            NoteCraft:Print(L["Reset confirmed."])
                            notifyChange()
                        end,
                    },
                },
            },
            tags = buildTagsGroup(),
            help = {
                type = "group", order = 99, name = L["Help"],
                args = {
                    intro = {
                        type = "description", order = 1, fontSize = "medium",
                        name = L["NoteCraft tracks who you have played with, remembers M+ outcomes per player, and lets you attach personal notes and color-coded tags. 100% local — no network sync."],
                    },
                    cmdHeader = { type = "header", order = 10, name = L["Slash commands"] },
                    cmdList = {
                        type = "description", order = 11,
                        name = "|cffffff80/nc|r — toggle the main window\n"
                            .. "|cffffff80/nc list|r — same as /nc\n"
                            .. "|cffffff80/nc add <Name-Realm> <text>|r — set a note\n"
                            .. "|cffffff80/nc tag <Name-Realm> <tagId|->|r — set or clear a tag\n"
                            .. "|cffffff80/nc tags|r — list all tags\n"
                            .. "|cffffff80/nc show <Name-Realm>|r — print player record in chat\n"
                            .. "|cffffff80/nc export|r — open the export dialog\n"
                            .. "|cffffff80/nc import <data>|r — open the import dialog\n"
                            .. "|cffffff80/nc config|r — open this options panel",
                    },
                    bindHeader = { type = "header", order = 20, name = L["Click modifiers (in main window)"] },
                    bindList = {
                        type = "description", order = 21,
                        name = "|cffffff80Click|r — open Add/Edit Note\n"
                            .. "|cffffff80Ctrl+Click|r — whisper the player\n"
                            .. "|cffffff80Shift+Click|r — insert player link in chat\n"
                            .. "|cffffff80Alt+Click|r — open M+ history",
                    },
                    keyHeader = { type = "header", order = 30, name = L["Keybindings"] },
                    keyList = {
                        type = "description", order = 31,
                        name = L["You can bind hotkeys via Esc → Key Bindings → AddOns → NoteCraft."],
                    },
                    aboutHeader = { type = "header", order = 90, name = L["About"] },
                    aboutText = {
                        type = "description", order = 91,
                        name = L["NoteCraft — © 2026 Roberto Cinque — MIT License\nGitHub: https://github.com/trynight/NoteCraft"],
                    },
                },
            },
        },
    }
end

function Options:Register()
    AceConfig:RegisterOptionsTable("NoteCraft", buildOptions)
    -- Set a sensible default size for the standalone dialog. Users can resize.
    AceConfigDialog:SetDefaultSize("NoteCraft", 720, 560)
    -- Also keep a Blizzard Settings entry as a navigation alias (compact view).
    self.dialogFrame = AceConfigDialog:AddToBlizOptions("NoteCraft", "NoteCraft")
end

function Options:Open()
    -- Prefer the standalone resizable dialog — the Blizzard Settings panel has
    -- a fixed narrow content area which clips wide rows (tag editor, buttons).
    if AceConfigDialog.OpenFrames and AceConfigDialog.OpenFrames["NoteCraft"] then
        AceConfigDialog:Close("NoteCraft")
        return
    end
    AceConfigDialog:Open("NoteCraft")
end
