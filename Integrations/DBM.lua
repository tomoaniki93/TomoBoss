local addonName, NS = ...
if type(NS) ~= "table" or not NS.BossModBridge then return end

local Bridge = NS.BossModBridge
local Provider = { name = "dbm", enabled = false, _registered = false }
Bridge:RegisterProvider("dbm", Provider)

local function isSecret(v)
    return type(issecretvalue) == "function" and issecretvalue(v) or false
end

local function safeNumber(v)
    if isSecret(v) or type(v) ~= "number" then return nil end
    if v ~= v or v <= -math.huge or v >= math.huge then return nil end
    return v
end

local function safeString(v)
    if isSecret(v) then return nil end
    return type(v) == "string" and v or nil
end

local function safeId(v)
    if v == nil or isSecret(v) then return nil end
    local t = type(v)
    if t ~= "string" and t ~= "number" and t ~= "boolean" then return nil end
    return tostring(v)
end

local function note(kind)
    if Bridge.NoteSecretDrop then Bridge:NoteSecretDrop("dbm", kind) end
end

local function onBegin(_, timerId, msg, duration, icon, timerType, spellId, _, _, _, _, _, _, _, _, _, _, _, isBarEnabled)
    if isSecret(duration) then note("begin-duration"); return end
    duration = safeNumber(duration)
    if not duration or duration <= 0 then return end

    if not isSecret(isBarEnabled) and isBarEnabled == false then return end

    local sid = safeId(timerId)
    if not sid then
        if isSecret(timerId) then note("begin-id") end
        return
    end

    local numericSpell = safeNumber(spellId)
    local safeType = safeString(timerType)
    if safeType == "break" or safeType == "pull" then numericSpell = nil end

    local name = safeString(msg)
    if isSecret(msg) then note("begin-name") end
    if isSecret(icon) then note("begin-icon"); icon = nil end

    Bridge:PushTimer("dbm", sid, {
        spellID = numericSpell,
        name = name,
        duration = duration,
        icon = icon,
    })
end

local function onStop(_, timerId)
    local sid = safeId(timerId)
    if not sid then if isSecret(timerId) then note("stop-id") end; return end
    Bridge:StopTimer("dbm", sid)
end

local function onPause(_, timerId)
    local sid = safeId(timerId)
    if not sid then if isSecret(timerId) then note("pause-id") end; return end
    Bridge:PauseTimer("dbm", sid)
end

local function onResume(_, timerId)
    local sid = safeId(timerId)
    if not sid then if isSecret(timerId) then note("resume-id") end; return end
    Bridge:ResumeTimer("dbm", sid)
end

local function onUpdate(_, timerId, elapsed, total)
    local sid = safeId(timerId)
    if not sid then if isSecret(timerId) then note("update-id") end; return end
    if isSecret(elapsed) or isSecret(total) then note("update-time"); return end
    Bridge:UpdateTimer("dbm", sid, safeNumber(elapsed), safeNumber(total))
end

local function onReset()
    Bridge:ResetSource("dbm")
end

function Provider:TryEnable()
    if self._registered then return true end
    local dbm = _G.DBM
    if not dbm or type(dbm.RegisterCallback) ~= "function" then
        self.enabled = false
        self.detail = "not loaded"
        Bridge:SetProviderStatus("dbm", false, self.detail)
        return false
    end

    local ok = pcall(function()
        dbm:RegisterCallback("DBM_TimerBegin", onBegin)
        dbm:RegisterCallback("DBM_TimerStop", onStop)
        dbm:RegisterCallback("DBM_TimerPause", onPause)
        dbm:RegisterCallback("DBM_TimerResume", onResume)
        dbm:RegisterCallback("DBM_TimerUpdate", onUpdate)
        dbm:RegisterCallback("DBM_Wipe", onReset)
        dbm:RegisterCallback("DBM_Kill", onReset)
    end)

    self._registered = ok and true or false
    self.enabled = self._registered
    self.detail = ok and "callbacks registered (secret-safe)" or "callback registration failed"
    Bridge:SetProviderStatus("dbm", self.enabled, self.detail)
    return self.enabled
end
