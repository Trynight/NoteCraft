local NoteCraft = LibStub("AceAddon-3.0"):GetAddon("NoteCraft")
local AceGUI = LibStub("AceGUI-3.0")

local PostRunDialog = {}
NoteCraft.PostRunDialog = PostRunDialog

local activeFrame

local NONE_VALUE = "__none__"

local function getDungeonName(mapID)
    if not mapID or not C_ChallengeMode or not C_ChallengeMode.GetMapUIInfo then
        return "?"
    end
    local info = C_ChallengeMode.GetMapUIInfo(mapID)
    return (info and info.name) or "?"
end

local function buildTagDropdown(currentTag)
    local dd = AceGUI:Create("Dropdown")
    dd:SetLabel(NoteCraft.L["Tag"])
    local items, order = { [NONE_VALUE] = NoteCraft.L["No tag"] }, { NONE_VALUE }
    for _, t in ipairs(NoteCraft:GetTags()) do
        items[t.id] = string.format("|c%s%s|r", t.color, t.label)
        order[#order + 1] = t.id
    end
    dd:SetList(items, order)
    dd:SetValue(currentTag or NONE_VALUE)
    return dd
end

function PostRunDialog:Show(runInfo)
    if activeFrame then activeFrame:Release(); activeFrame = nil end

    local L = NoteCraft.L
    local dungeonName = getDungeonName(runInfo.mapID)
    local level = runInfo.level or "?"
    local outcomeLabel
    if runInfo.outcome == "COMPLETED" then
        outcomeLabel = "|cff00ff00" .. L["IN TIME"] .. "|r"
    elseif runInfo.outcome == "DEPLETED" then
        outcomeLabel = "|cffff0000" .. L["DEPLETED"] .. "|r"
    else
        outcomeLabel = "|cffff8000" .. (L["Abandoned"] or "ABANDONED") .. "|r"
    end

    local f = AceGUI:Create("Frame")
    f:SetTitle(string.format("M+ %s +%d — %s", dungeonName, level, outcomeLabel))
    f:SetLayout("Flow")
    f:SetWidth(520)
    f:SetHeight(480)
    f:SetCallback("OnClose", function(widget) AceGUI:Release(widget); activeFrame = nil end)
    activeFrame = f

    local scroll = AceGUI:Create("ScrollFrame")
    scroll:SetLayout("List")
    scroll:SetFullWidth(true)
    scroll:SetHeight(320)
    f:AddChild(scroll)

    local memberWidgets = {}

    for _, m in ipairs(runInfo.members or {}) do
        if m.key then
            local p = NoteCraft.db.global.players[m.key]
            local displayName = (p and NoteCraft.Util.DisplayName(p)) or (m.name or "?") .. "-" .. (m.realm or "")

            local row = AceGUI:Create("SimpleGroup")
            row:SetLayout("Flow")
            row:SetFullWidth(true)

            local classHex = (p and NoteCraft.Util.ClassColorHex(p.class)) or "ffffffff"
            local nameLbl = AceGUI:Create("Label")
            nameLbl:SetText("|c" .. classHex .. displayName .. "|r")
            nameLbl:SetWidth(160)
            row:AddChild(nameLbl)

            local currentTag = p and p.tag
            local tagDD = buildTagDropdown(currentTag)
            tagDD:SetWidth(100)
            row:AddChild(tagDD)

            local noteBox = AceGUI:Create("EditBox")
            noteBox:SetLabel(L["Note"])
            noteBox:SetWidth(220)
            noteBox:SetText((p and p.note) or "")
            row:AddChild(noteBox)

            scroll:AddChild(row)

            memberWidgets[#memberWidgets + 1] = {
                key     = m.key,
                tagDD   = tagDD,
                noteBox = noteBox,
            }
        end
    end

    if #memberWidgets == 0 then
        local emptyLbl = AceGUI:Create("Label")
        emptyLbl:SetText(L["No members to show."])
        emptyLbl:SetFullWidth(true)
        scroll:AddChild(emptyLbl)
    end

    local runNoteBox = AceGUI:Create("EditBox")
    runNoteBox:SetLabel(L["Run-wide note (applied to all)"])
    runNoteBox:SetText("")
    runNoteBox:SetFullWidth(true)
    f:AddChild(runNoteBox)

    local noShowCB = AceGUI:Create("CheckBox")
    noShowCB:SetLabel(L["Don't show this dialog automatically"])
    noShowCB:SetValue(false)
    noShowCB:SetFullWidth(true)
    f:AddChild(noShowCB)

    local btnGroup = AceGUI:Create("SimpleGroup")
    btnGroup:SetLayout("Flow")
    btnGroup:SetFullWidth(true)

    local saveBtn = AceGUI:Create("Button")
    saveBtn:SetText(L["Save All"])
    saveBtn:SetWidth(130)
    saveBtn:SetCallback("OnClick", function()
        local runNote = runNoteBox:GetText() or ""
        runNote = runNote:match("^%s*(.-)%s*$") or ""

        for _, mw in ipairs(memberWidgets) do
            local p = NoteCraft.db.global.players[mw.key]
            if p then
                local tag = mw.tagDD:GetValue()
                if tag and tag ~= NONE_VALUE then p.tag = tag else p.tag = nil end

                local text = mw.noteBox:GetText() or ""
                text = text:match("^%s*(.-)%s*$") or ""
                if runNote ~= "" then
                    text = (text ~= "" and text ~= "\n") and (runNote .. "\n" .. text) or runNote
                end
                p.note = (text ~= "" and text ~= "\n") and text or nil
            end
        end

        if noShowCB:GetValue() then
            NoteCraft.db.global.config.autoShowPostRunDialog = false
        end

        f:Release()
        activeFrame = nil
        if NoteCraft.MainWindow and NoteCraft.MainWindow.Refresh then
            NoteCraft.MainWindow:Refresh()
        end
    end)
    btnGroup:AddChild(saveBtn)

    local skipBtn = AceGUI:Create("Button")
    skipBtn:SetText(L["Skip"])
    skipBtn:SetWidth(130)
    skipBtn:SetCallback("OnClick", function()
        if noShowCB:GetValue() then
            NoteCraft.db.global.config.autoShowPostRunDialog = false
        end
        f:Release()
        activeFrame = nil
    end)
    btnGroup:AddChild(skipBtn)

    f:AddChild(btnGroup)
end
