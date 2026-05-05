local NoteCraft = LibStub("AceAddon-3.0"):GetAddon("NoteCraft")

-- Commands.lua loads after NoteCraft.lua per the .toc, so we attach to OnInitialize
-- via a deferred registration: the addon's slash command needs AceConsole, which is
-- already mixed into NoteCraft (see NoteCraft.lua).

local handlers = {}

local function usage(line)
    NoteCraft:Print(line)
end

function handlers.list()
    if NoteCraft.MainWindow then NoteCraft.MainWindow:Toggle() end
end

function handlers.config()
    if NoteCraft.Options then NoteCraft.Options:Open() end
end

function handlers.add(rest)
    local target, text = rest:match("^(%S+)%s+(.+)$")
    if not target or not text then
        usage(NoteCraft.L["Usage: /nc add Name-Realm <text>"])
        return
    end
    local p = select(1, NoteCraft:GetOrCreatePlayer(target))
    if not p then return end
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    if text == "" then
        p.note = nil
        NoteCraft:Print(string.format(NoteCraft.L["Note cleared for %s."], target))
    else
        p.note = text
        NoteCraft:Print(string.format(NoteCraft.L["Note saved for %s."], target))
    end
    if NoteCraft.MainWindow and NoteCraft.MainWindow.Refresh then
        NoteCraft.MainWindow:Refresh()
    end
end

function handlers.tag(rest)
    local target, t = rest:match("^(%S+)%s+(%S+)$")
    if not target or not t then
        usage(NoteCraft.L["Usage: /nc tag Name-Realm <tagId|->"])
        return
    end
    local p = select(1, NoteCraft:GetOrCreatePlayer(target))
    if not p then return end
    if t == "-" or t:lower() == "none" or t:lower() == "clear" then
        p.tag = nil
        NoteCraft:Print(string.format(NoteCraft.L["Tag cleared for %s."], target))
    else
        local id = t:upper()
        if not NoteCraft:IsValidTag(id) then
            usage(NoteCraft.L["Unknown tag '%s'. Use /nc tags to list available tags."]:format(t))
            return
        end
        p.tag = id
        NoteCraft:Print(string.format(NoteCraft.L["Tag set: %s -> %s"], target, id))
    end
    if NoteCraft.MainWindow and NoteCraft.MainWindow.Refresh then
        NoteCraft.MainWindow:Refresh()
    end
end

function handlers.tags()
    local lines = { NoteCraft.L["Available tags:"] }
    for _, t in ipairs(NoteCraft:GetTags()) do
        lines[#lines + 1] = string.format("  |c%s%s|r (%s)%s",
            t.color, t.label, t.id, t.builtin and " [builtin]" or "")
    end
    for _, line in ipairs(lines) do NoteCraft:Print(line) end
end

function handlers.show(rest)
    local target = rest and rest:match("^(%S+)") or nil
    if not target then
        usage(NoteCraft.L["Usage: /nc show Name-Realm"])
        return
    end
    local key = NoteCraft.Util.NormalizePlayerKey(target)
    local p = NoteCraft.db.global.players[key]
    if not p then
        NoteCraft:Print(string.format(NoteCraft.L["No data for %s."], target))
        return
    end
    local total = (p.mPlusPositive or 0) + (p.mPlusNegative or 0)
    NoteCraft:Print(string.format(
        NoteCraft.L["Player %s: encounters=%d, M+ %d/%d in time, tag=%s"],
        NoteCraft.Util.DisplayName(p), p.encounters or 0,
        p.mPlusPositive or 0, total, p.tag or "-"))
    if p.note and p.note ~= "" then
        NoteCraft:Print(string.format(NoteCraft.L["Note: %s"], p.note))
    end
end

function handlers.export()
    if NoteCraft.ExportImport then NoteCraft.ExportImport:ShowExportDialog() end
end

function handlers.import(rest)
    if NoteCraft.ExportImport then NoteCraft.ExportImport:ShowImportDialog(rest) end
end

function NoteCraft:Dispatch(input)
    input = input and input:gsub("^%s+", "") or ""
    if input == "" then handlers.list(); return end
    local cmd, rest = input:match("^(%S+)%s*(.*)$")
    cmd = cmd:lower()
    rest = rest or ""
    if handlers[cmd] then
        handlers[cmd](rest)
    else
        usage(NoteCraft.L["Commands: list, add, tag, show, export, import, config"])
    end
end

-- Register slash commands. AceConsole is mixed into NoteCraft.
NoteCraft:RegisterChatCommand("nc",        "Dispatch")
NoteCraft:RegisterChatCommand("notecraft", "Dispatch")
