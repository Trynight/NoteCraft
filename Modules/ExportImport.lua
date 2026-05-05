local NoteCraft = LibStub("AceAddon-3.0"):GetAddon("NoteCraft")
local AceGUI       = LibStub("AceGUI-3.0")
local LibSerialize = LibStub("LibSerialize")
local LibDeflate   = LibStub("LibDeflate")

local EI = {}
NoteCraft.ExportImport = EI

local function encode(t)
    local s = LibSerialize:Serialize(t)
    local c = LibDeflate:CompressDeflate(s, { level = 9 })
    return LibDeflate:EncodeForPrint(c)
end

local function decode(str)
    if not str or str == "" then return nil, "empty" end
    str = str:gsub("^%s+", ""):gsub("%s+$", "")
    local c = LibDeflate:DecodeForPrint(str)
    if not c then return nil, "decode failed" end
    local s = LibDeflate:DecompressDeflate(c)
    if not s then return nil, "decompress failed" end
    local ok, t = LibSerialize:Deserialize(s)
    if not ok then return nil, "deserialize failed" end
    return t
end

local function countTable(t)
    local n = 0
    for _ in pairs(t or {}) do n = n + 1 end
    return n
end

function EI:ShowExportDialog()
    local payload = { v = 1, players = NoteCraft.db.global.players }
    local str = encode(payload)

    local f = AceGUI:Create("Frame")
    f:SetTitle(NoteCraft.L["NoteCraft Export"])
    f:SetLayout("Flow")
    f:SetWidth(520)
    f:SetHeight(360)
    f:SetCallback("OnClose", function(w) AceGUI:Release(w) end)

    local warn = AceGUI:Create("Label")
    warn:SetText(NoteCraft.L["Export contains personal data of other players. Share only with consent."])
    warn:SetFullWidth(true)
    f:AddChild(warn)

    local box = AceGUI:Create("MultiLineEditBox")
    box:SetLabel(NoteCraft.L["Copy this string:"])
    box:SetText(str)
    box:DisableButton(true)
    box:SetFullWidth(true)
    box:SetNumLines(12)
    f:AddChild(box)

    C_Timer.After(0, function()
        if box.editBox then
            box.editBox:HighlightText()
            box:SetFocus()
        end
    end)
end

function EI:ShowSharePlayerDialog(key)
    local player = NoteCraft.db.global.players[key]
    if not player then return end

    local payload = { v = 1, players = { [key] = player } }
    local encoded = encode(payload)

    local f = AceGUI:Create("Frame")
    f:SetTitle(NoteCraft.L["Share Note"])
    f:SetLayout("Flow")
    f:SetWidth(520)
    f:SetHeight(440)
    f:SetCallback("OnClose", function(w) AceGUI:Release(w) end)

    local warn = AceGUI:Create("Label")
    warn:SetText(NoteCraft.L["Export contains personal data of other players. Share only with consent."])
    warn:SetFullWidth(true)
    f:AddChild(warn)

    local plainParts = {}
    plainParts[#plainParts + 1] = NoteCraft.L["Player"] .. ": " .. NoteCraft.Util.DisplayName(player)
    plainParts[#plainParts + 1] = "Key: " .. key
    plainParts[#plainParts + 1] = NoteCraft.L["Date"] .. ": " .. (NoteCraft.Util.FormatDate(player.lastSeen) ~= "" and NoteCraft.Util.FormatDate(player.lastSeen) or NoteCraft.L["Never"])
    if player.title and player.title ~= "" then
        plainParts[#plainParts + 1] = NoteCraft.L["Title (short)"] .. ": " .. player.title
    end
    if player.note and player.note ~= "" then
        plainParts[#plainParts + 1] = NoteCraft.L["Note"] .. ":\n" .. player.note
    end

    local plainBox = AceGUI:Create("MultiLineEditBox")
    plainBox:SetLabel(NoteCraft.L["Plain text (chat-friendly):"])
    plainBox:SetText(table.concat(plainParts, "\n"))
    plainBox:DisableButton(true)
    plainBox:SetFullWidth(true)
    plainBox:SetNumLines(6)
    f:AddChild(plainBox)

    local box = AceGUI:Create("MultiLineEditBox")
    box:SetLabel(NoteCraft.L["NoteCraft share string (importable):"])
    box:SetText(encoded)
    box:DisableButton(true)
    box:SetFullWidth(true)
    box:SetNumLines(8)
    f:AddChild(box)

    C_Timer.After(0, function()
        if box.editBox then
            box.editBox:HighlightText()
            box:SetFocus()
        end
    end)
end

function EI:ShowImportDialog(prefill)
    local f = AceGUI:Create("Frame")
    f:SetTitle(NoteCraft.L["NoteCraft Import"])
    f:SetLayout("Flow")
    f:SetWidth(520)
    f:SetHeight(380)
    f:SetCallback("OnClose", function(w) AceGUI:Release(w) end)

    local box = AceGUI:Create("MultiLineEditBox")
    box:SetLabel(NoteCraft.L["Paste import string:"])
    box:SetText(prefill or "")
    box:DisableButton(true)
    box:SetFullWidth(true)
    box:SetNumLines(12)
    f:AddChild(box)

    local btnMerge = AceGUI:Create("Button")
    btnMerge:SetText(NoteCraft.L["Import (Merge)"])
    btnMerge:SetWidth(160)
    btnMerge:SetCallback("OnClick", function()
        EI:DoImport(box:GetText(), false)
        f:Release()
    end)
    f:AddChild(btnMerge)

    local btnReplace = AceGUI:Create("Button")
    btnReplace:SetText(NoteCraft.L["Import (Replace)"])
    btnReplace:SetWidth(160)
    btnReplace:SetCallback("OnClick", function()
        EI:DoImport(box:GetText(), true)
        f:Release()
    end)
    f:AddChild(btnReplace)
end

function EI:DoImport(str, replace)
    local data, err = decode(str)
    if not data or type(data) ~= "table" or not data.players then
        NoteCraft:Print(string.format(NoteCraft.L["Import error: %s"], err or "invalid"))
        return
    end
    if replace then
        NoteCraft.db.global.players = data.players
        NoteCraft.db.global.guidIndex = {}
        for k, p in pairs(data.players) do
            if p.lastGUID then NoteCraft.db.global.guidIndex[p.lastGUID] = k end
        end
    else
        for k, v in pairs(data.players) do
            NoteCraft.db.global.players[k] = v
            if v.lastGUID then NoteCraft.db.global.guidIndex[v.lastGUID] = k end
        end
    end
    NoteCraft:Print(string.format(NoteCraft.L["Imported %d players."], countTable(data.players)))
    if NoteCraft.MainWindow and NoteCraft.MainWindow.Refresh then
        NoteCraft.MainWindow:Refresh()
    end
end
