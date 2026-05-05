local L = LibStub("AceLocale-3.0"):NewLocale("NoteCraft", "enUS", true, true)
if not L then return end

-- Startup / generic
L["NoteCraft loaded. Type /nc for help."] = true
L["Commands: list, add, tag, show, export, import, config"] = true

-- Slash command usage
L["Usage: /nc add Name-Realm <text>"] = true
L["Usage: /nc tag Name-Realm <tagId|->"] = true
L["Usage: /nc show Name-Realm"] = true
L["Unknown tag '%s'. Use /nc tags to list available tags."] = true
L["Available tags:"] = true
L["Note saved for %s."] = true
L["Note cleared for %s."] = true
L["Tag set: %s -> %s"] = true
L["Tag cleared for %s."] = true
L["No data for %s."] = true
L["Player %s: encounters=%d, M+ %d/%d in time, tag=%s"] = true
L["Note: %s"] = true

-- Tags
L["GOOD"] = true
L["BAD"] = true
L["CAUTION"] = true
L["NEUTRAL"] = true

-- Tooltip
L["NoteCraft"] = true
L["M+: %d/%d in time"] = true
L["Played together: %d times"] = true

-- Main window
L["Search players..."] = true
L["Filter by tag"] = true
L["Filter by outcome"] = true
L["All"] = true
L["Has positive M+"] = true
L["Has negative M+"] = true
L["Edit"] = true
L["Delete"] = true
L["Close"] = true
L["No players tracked yet."] = true
L["%d players"] = true
L["Last seen: %s"] = true
L["Never"] = true

-- Note dialog
L["Add / Edit Note"] = true
L["Player"] = true
L["Note"] = true
L["Title (short)"] = true
L["Note (description)"] = true
L["Tag"] = true
L["Save"] = true
L["Cancel"] = true
L["Clear"] = true
L["No tag"] = true
L["No note"] = true
L["History"] = true
L["Filter by realm"] = true

-- Confirm
L["Delete record for %s?"] = true
L["Yes"] = true
L["No"] = true

-- Export / Import
L["NoteCraft Export"] = true
L["Copy this string:"] = true
L["NoteCraft Import"] = true
L["Paste import string:"] = true
L["Import (Merge)"] = true
L["Import (Replace)"] = true
L["Import error: %s"] = true
L["Imported %d players."] = true
L["Export contains personal data of other players. Share only with consent."] = true

-- Options
L["NoteCraft Options"] = true
L["General"] = true
L["UI integrations"] = true
L["Enable tooltip integration"] = true
L["Show 'Played together' counter in tooltip"] = true
L["Show M+ summary in tooltip"] = true
L["Enable LFG applicant screening"] = true
L["Enable chat right-click menu"] = true
L["Minimap button"] = true
L["Hide minimap button"] = true
L["Data"] = true
L["Max stored M+ runs per player"] = true
L["Reset all data"] = true
L["Reset confirmed."] = true

-- Tag management
L["Tags"] = true
L["Add new tag"] = true
L["Existing tags"] = true
L["Label"] = true
L["Color"] = true
L["Add Tag"] = true
L["Delete this tag? Players using it will be cleared."] = true

-- Minimap
L["%d players tracked"] = true
L["|cff00ff00Left-click|r open window"] = true
L["|cff00ff00Right-click|r open options"] = true

-- Main window tabs
L["Players"] = true
L["Stats"] = true
L["Help"] = true

-- History dialog
L["M+ history with %s"] = true
L["%d runs total — |cff00ff00%d in time|r / |cffff0000%d not in time|r"] = true
L["No M+ runs recorded yet."] = true
L["IN TIME"] = true
L["DEPLETED"] = true

-- Stats tab
L["Aggregate statistics"] = true
L["%d players tracked  •  %d total encounters  •  %d M+ runs (%.0f%% in time)"] = true
L["Role distribution: |cff5599ffTank %d|r  |cff44ff44Healer %d|r  |cffff7766DPS %d|r"] = true
L["Top players by encounters"] = true
L["Top players by M+ runs"] = true
L["Class distribution"] = true
L["Most-run dungeons"] = true

-- Alerts
L["Alert when a tagged player joins your group"] = true
L["Warning:"] = true
L["NoteCraft alert: %s [%s]"] = true

-- Help tab
L["NoteCraft tracks who you have played with, remembers M+ outcomes per player, and lets you attach personal notes and color-coded tags. 100% local — no network sync."] = true
L["Slash commands"] = true
L["Click modifiers (in main window)"] = true
L["Keybindings"] = true
L["You can bind hotkeys via Esc → Key Bindings → AddOns → NoteCraft."] = true
L["About"] = true
L["NoteCraft — © 2026 Roberto Cinque — MIT License\nGitHub: https://github.com/trynight/NoteCraft"] = true

-- Bindings (these strings are used by Blizzard binding UI via _G assignment below)
BINDING_HEADER_NOTECRAFT = "NoteCraft"
BINDING_NAME_NOTECRAFT_TOGGLE_WINDOW   = "Toggle main window"
BINDING_NAME_NOTECRAFT_TOGGLE_MINIMAP  = "Toggle minimap button"
BINDING_NAME_NOTECRAFT_OPEN_OPTIONS    = "Open options"
BINDING_NAME_NOTECRAFT_NOTE_TARGET     = "Add/Edit note for current target"

-- Chat menu / context
L["Add Note"] = true
L["Quick Tag: GOOD"] = true
L["Quick Tag: BAD"] = true
L["Quick Tag: CAUTION"] = true
L["Quick Tag: NEUTRAL"] = true
L["Clear Tag"] = true
L["View History"] = true

-- Post-run dialog
L["Abandoned"] = true
L["No members to show."] = true
L["Run-wide note (applied to all)"] = true
L["Don't show this dialog automatically"] = true
L["Save All"] = true
L["Skip"] = true
L["Auto-show post-M+ run dialog"] = true
L["Show a popup after each M+ run to quickly add notes and tags to party members."] = true

-- Stats display
L["%d times"] = true
L["Stats: × encounters | M+ in time/depleted | T/H/D role counts"] = true
