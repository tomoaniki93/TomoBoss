local addonName, NS = ...
if type(NS) ~= "table" then return end

local Bridge = NS.BossModBridge or {}
NS.BossModBridge = Bridge

Bridge.providers = Bridge.providers or {}
Bridge.active = Bridge.active or {}
Bridge.bySourceId = Bridge.bySourceId or {}
Bridge.listeners = Bridge.listeners or {}
Bridge._nextId = Bridge._nextId or 0
Bridge.stats = Bridge.stats or { secretDrops = 0, secretDropsBySource = {} }

local DEDUP_WINDOW = 0.75
local SENTINEL_MIN = 900
local SOURCE_PRIORITY = {
    blizzard = 100,
    bettertimeline = 90,
    bigwigs = 80,
    dbm = 80,
}

local function now()
    return GetTime and GetTime() or 0
end

local function isSecret(value)
    return type(issecretvalue) == "function" and issecretvalue(value) or false
end

local function safeString(value)
    if isSecret(value) then return nil end
    return type(value) == "string" and value or nil
end

local function safeId(value)
    if value == nil or isSecret(value) then return nil end
    local t = type(value)
    if t ~= "string" and t ~= "number" and t ~= "boolean" then return nil end
    return tostring(value)
end

local function normalizeName(value)
    value = safeString(value)
    if not value then return nil end
    value = value:lower():gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    value = value:gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", " ")
    if value == "" then return nil end
    return value
end

local function validNumber(value)
    if isSecret(value) or type(value) ~= "number" then return false end
    return value == value and value > -math.huge and value < math.huge
end

local function safePositiveNumber(value)
    if not validNumber(value) or value <= 0 then return nil end
    return value
end

local function safeBoolean(value)
    if isSecret(value) or type(value) ~= "boolean" then return nil end
    return value
end

local function safeOpaque(value)
    if isSecret(value) then return nil end
    return value
end

local function sourcePriority(source)
    return SOURCE_PRIORITY[source] or 0
end

local function sourceCount(sources)
    local n = 0
    for _ in pairs(sources or {}) do n = n + 1 end
    return n
end

function Bridge:IsSecretValue(value)
    return isSecret(value)
end

function Bridge:SafeString(value)
    return safeString(value)
end

function Bridge:SafeNumber(value)
    return validNumber(value) and value or nil
end

function Bridge:SafeId(value)
    return safeId(value)
end

function Bridge:NoteSecretDrop(source, kind)
    source = safeString(source) or "unknown"
    kind = safeString(kind) or "value"
    self.stats = self.stats or { secretDrops = 0, secretDropsBySource = {} }
    self.stats.secretDrops = (self.stats.secretDrops or 0) + 1
    self.stats.secretDropsBySource = self.stats.secretDropsBySource or {}
    local s = self.stats.secretDropsBySource[source] or { total = 0, kinds = {} }
    self.stats.secretDropsBySource[source] = s
    s.total = (s.total or 0) + 1
    s.kinds[kind] = (s.kinds[kind] or 0) + 1
end

function Bridge:GetSecretStats()
    local total = self.stats and self.stats.secretDrops or 0
    local bySource = {}
    for source, data in pairs((self.stats and self.stats.secretDropsBySource) or {}) do
        bySource[source] = { total = data.total or 0 }
    end
    return { total = total or 0, bySource = bySource }
end

function Bridge:RegisterProvider(name, provider)
    if isSecret(name) or type(name) ~= "string" or type(provider) ~= "table" then return false end
    self.providers[name] = provider
    provider.name = provider.name or name
    return true
end

function Bridge:SetProviderStatus(name, enabled, detail)
    if isSecret(name) or type(name) ~= "string" then return end
    local provider = self.providers[name] or { name = name }
    self.providers[name] = provider
    provider.enabled = enabled and true or false
    provider.detail = safeString(detail)
end

function Bridge:RegisterListener(callback)
    if type(callback) ~= "function" then return false end
    self.listeners[#self.listeners + 1] = callback
    return true
end

function Bridge:_Notify(kind, record)
    for i = 1, #self.listeners do
        pcall(self.listeners[i], kind, record)
    end
end

function Bridge:_FindDuplicate(spellID, name, expirationTime)
    spellID = safePositiveNumber(spellID)
    local normalized = normalizeName(name)
    if not validNumber(expirationTime) then return nil end
    for key, record in pairs(self.active) do
        if not record.paused and validNumber(record.expirationTime) then
            local sameIdentity = false
            if spellID and record.spellID == spellID then
                sameIdentity = true
            elseif normalized and record.normalizedName == normalized then
                sameIdentity = true
            end
            if sameIdentity and math.abs(record.expirationTime - expirationTime) <= DEDUP_WINDOW then
                return key, record
            end
        end
    end
end

function Bridge:PushTimer(source, providerId, data)
    source = safeString(source)
    local sid = safeId(providerId)
    if not source or not sid or type(data) ~= "table" then return nil end

    local duration = self:SafeNumber(data.duration)
    if not duration or duration <= 0 or duration >= SENTINEL_MIN then return nil end

    local expirationTime = self:SafeNumber(data.expirationTime)
    if not expirationTime then expirationTime = now() + duration end

    local cleanName = safeString(data.name)
    local spellID = safePositiveNumber(data.spellID)
    local icon = safeOpaque(data.icon)
    local paused = safeBoolean(data.paused) == true

    self.bySourceId[source] = self.bySourceId[source] or {}

    local existingKey = self.bySourceId[source][sid]
    if existingKey and self.active[existingKey] then
        local record = self.active[existingKey]
        record.duration = duration
        record.expirationTime = expirationTime
        if cleanName then record.name = cleanName end
        record.normalizedName = normalizeName(record.name)
        if spellID then record.spellID = spellID end
        if icon ~= nil then record.icon = icon end
        record.paused = paused
        record.updatedAt = now()
        self:_Notify("update", record)
        return record
    end

    local dupKey, dup = self:_FindDuplicate(spellID, cleanName, expirationTime)
    if dup then
        dup.sources[source] = sid
        self.bySourceId[source][sid] = dupKey
        if sourcePriority(source) > sourcePriority(dup.primarySource) then
            dup.primarySource = source
            if cleanName then dup.name = cleanName end
            dup.normalizedName = normalizeName(dup.name)
            if spellID then dup.spellID = spellID end
            if icon ~= nil then dup.icon = icon end
        end
        dup.updatedAt = now()
        self:_Notify("merge", dup)
        return dup
    end

    self._nextId = self._nextId + 1
    local key = tostring(self._nextId)
    local record = {
        bridgeId = key,
        primarySource = source,
        sources = { [source] = sid },
        providerId = sid,
        name = cleanName,
        normalizedName = normalizeName(cleanName),
        spellID = spellID,
        icon = icon,
        duration = duration,
        expirationTime = expirationTime,
        paused = paused,
        createdAt = now(),
        updatedAt = now(),
    }
    self.active[key] = record
    self.bySourceId[source][sid] = key
    self:_Notify("start", record)
    return record
end

function Bridge:StopTimer(source, providerId)
    source = safeString(source)
    local sid = safeId(providerId)
    if not source or not sid then return end
    local map = self.bySourceId[source]
    if not map then return end
    local key = map[sid]
    map[sid] = nil
    local record = key and self.active[key]
    if not record then return end
    record.sources[source] = nil
    if sourceCount(record.sources) == 0 then
        self.active[key] = nil
        self:_Notify("stop", record)
    else
        self:_Notify("source-stop", record)
    end
end

function Bridge:PauseTimer(source, providerId)
    source = safeString(source)
    local sid = safeId(providerId)
    if not source or not sid then return end
    local map = self.bySourceId[source]
    local record = map and self.active[map[sid]]
    if not record or record.paused then return end
    record.remaining = math.max(0, (record.expirationTime or now()) - now())
    record.paused = true
    record.updatedAt = now()
    self:_Notify("pause", record)
end

function Bridge:ResumeTimer(source, providerId)
    source = safeString(source)
    local sid = safeId(providerId)
    if not source or not sid then return end
    local map = self.bySourceId[source]
    local record = map and self.active[map[sid]]
    if not record or not record.paused then return end
    record.expirationTime = now() + (record.remaining or 0)
    record.remaining = nil
    record.paused = false
    record.updatedAt = now()
    self:_Notify("resume", record)
end

function Bridge:UpdateTimer(source, providerId, elapsed, total)
    source = safeString(source)
    local sid = safeId(providerId)
    total = self:SafeNumber(total)
    if not source or not sid or not total or total <= 0 then return end
    elapsed = self:SafeNumber(elapsed) or 0
    local map = self.bySourceId[source]
    local record = map and self.active[map[sid]]
    if not record then return end
    record.duration = total
    record.expirationTime = now() + math.max(0, total - elapsed)
    record.updatedAt = now()
    self:_Notify("update", record)
end

function Bridge:ResetSource(source)
    source = safeString(source)
    if not source then return end
    local map = self.bySourceId[source]
    if not map then return end
    local ids = {}
    for sid in pairs(map) do ids[#ids + 1] = sid end
    for i = 1, #ids do self:StopTimer(source, ids[i]) end
end

function Bridge:Prune()
    local t = now()
    local remove = {}
    for key, record in pairs(self.active) do
        if not record.paused and validNumber(record.expirationTime) and record.expirationTime < (t - 1) then
            remove[#remove + 1] = key
        end
    end
    for i = 1, #remove do
        local key = remove[i]
        local record = self.active[key]
        if record then
            for source, sid in pairs(record.sources or {}) do
                if self.bySourceId[source] then self.bySourceId[source][sid] = nil end
            end
            self.active[key] = nil
            self:_Notify("expire", record)
        end
    end
end

function Bridge:GetActiveTimers()
    self:Prune()
    local out = {}
    for _, record in pairs(self.active) do out[#out + 1] = record end
    table.sort(out, function(a, b) return (a.expirationTime or 0) < (b.expirationTime or 0) end)
    return out
end

function Bridge:GetStatus()
    local out = {}
    for name, provider in pairs(self.providers) do
        out[#out + 1] = {
            name = name,
            enabled = provider.enabled and true or false,
            detail = safeString(provider.detail),
        }
    end
    table.sort(out, function(a, b) return a.name < b.name end)
    return out
end
