local _, ns = ...

-- Small helpers around modern ScrollBox + legacy ScrollFrame hookups.
-- Mirrors the API of RaiderIO's internal ScrollBoxUtil / HookUtil so that
-- tooltip-overlay modules (WhoTooltip, GuildRoster, Communities) have a single
-- place to keep the boilerplate.
local SH = {}
ns.ScrollHook = SH

-- Run `callback(buttons, scrollBox)` whenever the visible frame range changes.
-- Returns:
--   1     -> legacy ScrollBox (uses .buttons table directly)
--   true  -> modern ScrollBox (RegisterCallback API)
--   false -> unsupported / scrollBox missing
function SH.OnViewFramesChanged(scrollBox, callback)
    if not scrollBox then return false end
    -- Legacy 9.x ScrollBox: exposes .buttons directly.
    if scrollBox.buttons then
        callback(scrollBox.buttons, scrollBox)
        return 1
    end
    -- Modern ScrollBox: RegisterCallback + GetFrames.
    if scrollBox.RegisterCallback and scrollBox.GetFrames then
        local frames = scrollBox:GetFrames()
        if frames and frames[1] then callback(frames, scrollBox) end
        local Event = _G.ScrollBoxListMixin and _G.ScrollBoxListMixin.Event
        local eventName = (Event and Event.OnUpdate) or "OnUpdate"
        scrollBox:RegisterCallback(eventName, function()
            callback(scrollBox:GetFrames(), scrollBox)
        end)
        return true
    end
    return false
end

-- Run `callback(scrollBox)` whenever the scroll position changes.
function SH.OnViewScrollChanged(scrollBox, callback)
    if not scrollBox then return false end
    local function wrapped() callback(scrollBox) end
    if scrollBox.update then
        hooksecurefunc(scrollBox, "update", wrapped)
        return 1
    end
    if scrollBox.RegisterCallback then
        local Event = _G.ScrollBoxListMixin and _G.ScrollBoxListMixin.Event
        local eventName = (Event and Event.OnScroll) or "OnScroll"
        scrollBox:RegisterCallback(eventName, wrapped)
        return true
    end
    return false
end

local hooked = setmetatable({}, { __mode = "k" })

-- HookScript on a frame; idempotent — calling twice with the same callback no-ops.
function SH.HookScript(frame, scriptKey, callback)
    if type(frame) ~= "table" then return end
    local h = hooked[frame] or {}
    hooked[frame] = h
    local kh = h[scriptKey] or {}
    h[scriptKey] = kh
    if kh[callback] then return end
    kh[callback] = true
    frame:HookScript(scriptKey, callback)
end

-- Apply { OnEnter = fn, OnLeave = fn, ... } to a frame or array of frames.
function SH.MapOn(framesOrFrame, scriptMap)
    if type(framesOrFrame) ~= "table" then return end
    if type(framesOrFrame.GetObjectType) == "function" then
        for key, fn in pairs(scriptMap) do SH.HookScript(framesOrFrame, key, fn) end
        return
    end
    for _, f in ipairs(framesOrFrame) do
        for key, fn in pairs(scriptMap) do SH.HookScript(f, key, fn) end
    end
end
