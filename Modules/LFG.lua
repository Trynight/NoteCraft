local NoteCraft = LibStub("AceAddon-3.0"):GetAddon("NoteCraft")
local LFG = NoteCraft:NewModule("LFG", "AceEvent-3.0")

local hookedApplicantUpdate = false
local hookedSearchEntryTooltip = false
local searchEntryHookAttempts = 0

-- For each applicant member frame, attach a small overlay (note text + colored border)
-- if we know that player. Frame layout in modern WoW exposes member sub-frames as
-- LFGListApplicantViewer applicant.Members[i].
local function decorateApplicant(applicantFrame, applicantID)
    if not applicantFrame or not C_LFGList or not C_LFGList.GetApplicantInfo then return end
    if not applicantFrame.Members then return end

    for i, memberFrame in ipairs(applicantFrame.Members) do
        local name, _, _, _, _, _, _, _, _, _, _, _ =
            C_LFGList.GetApplicantMemberInfo(applicantID, i)
        if name then
            local key = NoteCraft.Util.NormalizePlayerKey(name)
            local p = NoteCraft.db.global.players[key]
            if p then
                local hex = NoteCraft:GetTagColor(p.tag)
                local r = tonumber(hex:sub(3, 4), 16) / 255
                local g = tonumber(hex:sub(5, 6), 16) / 255
                local b = tonumber(hex:sub(7, 8), 16) / 255

                if not memberFrame.NoteCraftBorder then
                    local tex = memberFrame:CreateTexture(nil, "OVERLAY")
                    tex:SetAllPoints(memberFrame)
                    tex:SetColorTexture(0, 0, 0, 0)
                    local bd = memberFrame:CreateTexture(nil, "OVERLAY")
                    bd:SetPoint("TOPLEFT", memberFrame, "TOPLEFT", -1, 1)
                    bd:SetPoint("BOTTOMRIGHT", memberFrame, "BOTTOMRIGHT", 1, -1)
                    bd:SetColorTexture(0, 0, 0, 0)
                    memberFrame.NoteCraftBorder = bd
                end
                memberFrame.NoteCraftBorder:SetColorTexture(r, g, b, 0.55)

                if not memberFrame.NoteCraftLabel then
                    local fs = memberFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                    fs:SetPoint("LEFT", memberFrame, "RIGHT", 4, 0)
                    fs:SetWidth(220)
                    fs:SetJustifyH("LEFT")
                    memberFrame.NoteCraftLabel = fs
                end
                local note = (p.note and p.note ~= "") and p.note or ""
                local total = (p.mPlusPositive or 0) + (p.mPlusNegative or 0)
                local stats = ""
                if total > 0 then
                    stats = string.format(" [|cff00ff00%d|r/|cffff0000%d|r]",
                        p.mPlusPositive or 0, p.mPlusNegative or 0)
                end
                memberFrame.NoteCraftLabel:SetText("|c" .. hex .. note .. "|r" .. stats)
            else
                if memberFrame.NoteCraftBorder then
                    memberFrame.NoteCraftBorder:SetColorTexture(0, 0, 0, 0)
                end
                if memberFrame.NoteCraftLabel then
                    memberFrame.NoteCraftLabel:SetText("")
                end
            end
        end
    end
end

local function refreshAll()
    if not LFGListApplicantViewer or not LFGListApplicantViewer.ScrollFrame then return end
    local buttons = LFGListApplicantViewer.ScrollFrame.buttons
    if not buttons then return end
    for _, btn in ipairs(buttons) do
        if btn and btn.applicantID then
            decorateApplicant(btn, btn.applicantID)
        end
    end
end

local function tryHookSearchEntryTooltip()
    if hookedSearchEntryTooltip then return end
    if searchEntryHookAttempts > 10 then return end
    searchEntryHookAttempts = searchEntryHookAttempts + 1

    if _G.LFGListUtil_SetSearchEntryTooltip then
        hooksecurefunc("LFGListUtil_SetSearchEntryTooltip", function(tooltip, resultID)
            appendSearchEntry(tooltip, resultID)
        end)
        hookedSearchEntryTooltip = true
    elseif _G.LFGListSearchEntry and _G.LFGListSearchEntry.SetTooltip then
        hooksecurefunc(_G.LFGListSearchEntry, "SetTooltip", function(_, tooltip, resultID)
            appendSearchEntry(tooltip, resultID)
        end)
        hookedSearchEntryTooltip = true
    end
end

local function appendSearchEntry(tooltip, resultID)
    if not tooltip or not resultID then return end
    if not C_LFGList or not C_LFGList.GetSearchResultInfo then return end
    local info = C_LFGList.GetSearchResultInfo(resultID)
    if not info or not info.leaderName or info.leaderName == "" then return end

    local key = NoteCraft.Util.NormalizePlayerKey(info.leaderName)
    local p = NoteCraft.db.global.players[key]
    if p then
        if NoteCraft.TooltipAppendInfo then
            NoteCraft.TooltipAppendInfo(tooltip, p)
        end
    else
        tooltip:AddLine(" ")
        tooltip:AddLine("|cff888888NoteCraft: no data|r")
    end
    tooltip:Show()
end

local function tryHookAllSearchListings()
    if not LFGListSearchPanel or not LFGListSearchPanel.ScrollFrame then
        return
    end
    local buttons = LFGListSearchPanel.ScrollFrame.buttons
    if not buttons then return end
    for _, btn in ipairs(buttons) do
        if btn and not btn.NoteCraftHookedSearch and btn.OnEnter then
            local origOnEnter = btn:GetScript("OnEnter")
            btn:SetScript("OnEnter", function(self)
                if origOnEnter then origOnEnter(self) end
                if self.resultID then
                    local tip = GameTooltip
                    if tip and tip:IsOwned(self) then
                        appendSearchEntry(tip, self.resultID)
                    end
                end
            end)
            btn.NoteCraftHookedSearch = true
        end
    end
end

function LFG:OnEnable()
    self:RegisterEvent("LFG_LIST_APPLICANT_LIST_UPDATED", "OnApplicantListUpdated")
    self:RegisterEvent("LFG_LIST_APPLICANT_UPDATED",      "OnApplicantListUpdated")
    self:RegisterEvent("LFG_LIST_SEARCH_RESULTS_UPDATED",  "OnSearchResultsUpdated")

    if not hookedApplicantUpdate and _G.LFGListApplicantViewer_UpdateApplicant then
        hooksecurefunc("LFGListApplicantViewer_UpdateApplicant", function(frame, applicantID)
            decorateApplicant(frame, applicantID)
        end)
        hookedApplicantUpdate = true
    end

    tryHookSearchEntryTooltip()
end

function LFG:OnDisable()
    self:UnregisterAllEvents()
end

local refreshPending = false

function LFG:OnApplicantListUpdated()
    if refreshPending then return end
    refreshPending = true
    C_Timer.After(0.25, function()
        refreshPending = false
        refreshAll()
    end)
end

function LFG:OnSearchResultsUpdated()
    tryHookSearchEntryTooltip()
    C_Timer.After(0.25, function()
        tryHookAllSearchListings()
    end)
end
