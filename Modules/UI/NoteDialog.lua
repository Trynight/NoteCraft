local NoteCraft = LibStub("AceAddon-3.0"):GetAddon("NoteCraft")
local AceGUI = LibStub("AceGUI-3.0")

local NoteDialog = {}
NoteCraft.NoteDialog = NoteDialog

local activeFrame

local NONE_VALUE = "__none__"

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

function NoteDialog:Show(displayName)
    if activeFrame then activeFrame:Release(); activeFrame = nil end

    local p, key = NoteCraft:GetOrCreatePlayer(displayName)
    if not p then return end

    local f = AceGUI:Create("Frame")
    f:SetTitle(NoteCraft.L["Add / Edit Note"])
    f:SetLayout("Flow")
    f:SetWidth(440)
    f:SetHeight(360)
    f:SetCallback("OnClose", function(widget) AceGUI:Release(widget); activeFrame = nil end)
    activeFrame = f

    local nameLabel = AceGUI:Create("Label")
    nameLabel:SetText("|c" .. NoteCraft.Util.ClassColorHex(p.class) ..
        NoteCraft.Util.DisplayName(p) .. "|r")
    nameLabel:SetFontObject(GameFontHighlightLarge)
    nameLabel:SetFullWidth(true)
    f:AddChild(nameLabel)

    local tagDD = buildTagDropdown(p.tag)
    tagDD:SetFullWidth(true)
    f:AddChild(tagDD)

    local titleBox = AceGUI:Create("EditBox")
    titleBox:SetLabel(NoteCraft.L["Title (short)"])
    titleBox:SetText(p.title or "")
    titleBox:SetFullWidth(true)
    f:AddChild(titleBox)

    local box = AceGUI:Create("MultiLineEditBox")
    box:SetLabel(NoteCraft.L["Note (description)"])
    box:SetText(p.note or "")
    box:SetNumLines(5)
    box:SetFullWidth(true)
    box:DisableButton(true)
    f:AddChild(box)

    local saveBtn = AceGUI:Create("Button")
    saveBtn:SetText(NoteCraft.L["Save"])
    saveBtn:SetWidth(120)
    saveBtn:SetCallback("OnClick", function()
        local title = (titleBox:GetText() or ""):match("^%s*(.-)%s*$")
        p.title = (title ~= "" and title) or nil
        local text = (box:GetText() or ""):match("^%s*(.-)%s*$")
        p.note = (text ~= "" and text) or nil
        local tag = tagDD:GetValue()
        if tag and tag ~= NONE_VALUE then p.tag = tag else p.tag = nil end
        f:Release()
        activeFrame = nil
        if NoteCraft.MainWindow and NoteCraft.MainWindow.Refresh then
            NoteCraft.MainWindow:Refresh()
        end
    end)
    f:AddChild(saveBtn)

    local clearBtn = AceGUI:Create("Button")
    clearBtn:SetText(NoteCraft.L["Clear"])
    clearBtn:SetWidth(120)
    clearBtn:SetCallback("OnClick", function()
        box:SetText("")
        titleBox:SetText("")
        tagDD:SetValue(NONE_VALUE)
    end)
    f:AddChild(clearBtn)

    local cancelBtn = AceGUI:Create("Button")
    cancelBtn:SetText(NoteCraft.L["Cancel"])
    cancelBtn:SetWidth(120)
    cancelBtn:SetCallback("OnClick", function() f:Release(); activeFrame = nil end)
    f:AddChild(cancelBtn)
end
