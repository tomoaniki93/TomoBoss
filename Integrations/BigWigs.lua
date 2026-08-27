local addonName, NS = ...
if type(NS) ~= "table" or not NS.BossModBridge then return end

local Bridge = NS.BossModBridge
local Provider = { name = "bigwigs", enabled = false, _registered = false }
Bridge:RegisterProvider("bigwigs", Provider)

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

local function safeToken(v)
    if v == nil or isSecret(v) then return nil end
    local t = type(v)
    if t ~= "string" and t ~= "number" and t ~= "boolean" then return nil end
    return tostring(v)
end

local function note(kind)
    if Bridge.NoteSecretDrop then Bridge:NoteSecretDrop("bigwigs", kind) end
end

local function makeId(key, text, eventId)
    -- BigWigs' Retail Timeline plugin sends native timeline eventId in the
    -- trailing args while spellName/icon are intentionally secret in combat.
    local eventToken = safeToken(eventId)
    if eventToken then return "event|" .. eventToken end

    local keyToken = safeToken(key)
    if keyToken then return "key|" .. keyToken end

    local textToken = safeString(text)
    if textToken then return "text|" .. textToken end

    return nil
end

local function onStart(_, module, key, text, duration, icon, maxQueueDuration, originalDuration, eventId, timelineEventId)
    if isSecret(duration) then note("start-duration"); return end
    duration = safeNumber(duration)
    if not duration or duration <= 0 then return end

    -- Depending on BigWigs version/source, the native event id can be in either
    -- of the last two positions. Both are non-secret in the current Retail API.
    local nativeEventId = safeToken(timelineEventId) and timelineEventId or eventId
    local id = makeId(key, text, nativeEventId)
    if not id then
        if isSecret(text) or isSecret(key) or isSecret(eventId) or isSecret(timelineEventId) then
            note("start-identity")
        end
        return
    end

    local numericSpell = safeNumber(key)
    local name = safeString(text)
    if isSecret(text) then note("start-name") end
    if isSecret(icon) then note("start-icon"); icon = nil end

    Bridge:PushTimer("bigwigs", id, {
        spellID = numericSpell,
        name = name,
        duration = duration,
        icon = icon,
    })
end

local function collectIds(key, text)
    local ids, seen = {}, {}
    local function add(prefix, token)
        if not token then return end
        local id = prefix .. token
        if not seen[id] then
            seen[id] = true
            ids[#ids + 1] = id
        end
    end

    if isSecret(key) or isSecret(text) then return ids, true end
    local keyToken = safeToken(key)
    local textToken = safeToken(text)

    -- Native Timeline stop/pause/resume uses its eventId as the third argument,
    -- which lands in `text`. Normal BigWigs bars normally use `key`.
    add("key|", keyToken)
    add("event|", keyToken)
    add("text|", keyToken)
    add("event|", textToken)
    add("key|", textToken)
    add("text|", textToken)
    return ids, false
end

local function onStop(_, module, key, text)
    local ids, secret = collectIds(key, text)
    if secret then note("stop-identity") end
    for i = 1, #ids do Bridge:StopTimer("bigwigs", ids[i]) end
end

local function onPause(_, module, key, text)
    local ids, secret = collectIds(key, text)
    if secret then note("pause-identity") end
    for i = 1, #ids do Bridge:PauseTimer("bigwigs", ids[i]) end
end

local function onResume(_, module, key, text)
    local ids, secret = collectIds(key, text)
    if secret then note("resume-identity") end
    for i = 1, #ids do Bridge:ResumeTimer("bigwigs", ids[i]) end
end

local function onReset()
    Bridge:ResetSource("bigwigs")
end

function Provider:TryEnable()
    if self._registered then return true end
    local loader = _G.BigWigsLoader
    if not loader or type(loader.RegisterMessage) ~= "function" then
        self.enabled = false
        self.detail = "not loaded"
        Bridge:SetProviderStatus("bigwigs", false, self.detail)
        return false
    end

    local ok = pcall(function()
        loader.RegisterMessage(Provider, "BigWigs_StartBar", onStart)
        loader.RegisterMessage(Provider, "BigWigs_StopBar", onStop)
        loader.RegisterMessage(Provider, "BigWigs_PauseBar", onPause)
        loader.RegisterMessage(Provider, "BigWigs_ResumeBar", onResume)
        loader.RegisterMessage(Provider, "BigWigs_StopBars", onReset)
        loader.RegisterMessage(Provider, "BigWigs_OnBossDisable", onReset)
    end)

    self._registered = ok and true or false
    self.enabled = self._registered
    self.detail = ok and "callbacks registered (secret-safe)" or "callback registration failed"
    Bridge:SetProviderStatus("bigwigs", self.enabled, self.detail)
    return self.enabled
end
