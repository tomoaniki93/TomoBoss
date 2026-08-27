local addonName, NS = ...
if type(NS) ~= "table" then return end

local PD = NS.PhaseDetector or {}
NS.PhaseDetector = PD

local Store = NS.Learn and NS.Learn.Store

local BATCH_WINDOW = 0.18
local DUR_BUCKET = 0.25
local SENTINEL_MIN = 900

PD.mode = "observation-only"
PD.current = PD.current or nil
PD.last = PD.last or nil
PD.externalSignals = PD.externalSignals or 0
PD.sentinelTotal = PD.sentinelTotal or 0

local function safeNumber(v)
    if NS.SafeNumber then return NS:SafeNumber(v) end
    return type(v) == "number" and v or nil
end

local function readInfo(x)
    if type(x) == "table" then return x end
    local id = safeNumber(x)
    if not id or not C_EncounterTimeline or not C_EncounterTimeline.GetEventInfo then return nil end
    local ok, info = pcall(C_EncounterTimeline.GetEventInfo, id)
    return ok and type(info) == "table" and info or nil
end

local function bucket(v)
    return math.floor((v / DUR_BUCKET) + 0.5) * DUR_BUCKET
end

local function fmtDur(v)
    if math.abs(v - math.floor(v)) < 0.001 then return tostring(math.floor(v)) end
    return string.format("%.2f", v):gsub("0+$", ""):gsub("%.$", "")
end

local function signature(values)
    local set, out = {}, {}
    for _, v in ipairs(values or {}) do
        local b = bucket(v)
        local k = string.format("%.2f", b)
        if not set[k] then set[k] = b; out[#out+1] = b end
    end
    table.sort(out)
    local text = {}
    for i=1,#out do text[i] = fmtDur(out[i]) end
    return table.concat(text, ","), out
end

local function bossCount()
    local n = 0
    for i=1,8 do
        local u = "boss" .. i
        local ok, exists = pcall(UnitExists, u)
        if ok and exists then n = n + 1 end
    end
    return n
end

function PD:Begin(encounterID, name)
    self.current = {
        encounterID = safeNumber(encounterID) or encounterID,
        name = (type(name) == "string" and name) or nil,
        t0 = GetTime(),
        batches = {},
        anchorChanges = 0,
        stateUpdates = 0,
        bossCount = bossCount(),
        externalSignals = 0,
        sentinelEvents = 0,
        sentinelValues = {},
    }
    self._batch = nil
    self._batchSerial = 0
end

function PD:End(outcome)
    self:FlushBatch()
    if self.current then
        self.current.outcome = outcome
        self.current.endedAt = GetTime()
        self.last = self.current
    end
    self.current = nil
    self._batch = nil
end

function PD:FlushBatch()
    local b = self._batch
    if not b or not self.current then self._batch = nil; return end
    self._batch = nil
    local sig, vals = signature(b.durations)
    if sig == "" then return end

    local hasMarker = false
    for _, d in ipairs(vals) do if d >= SENTINEL_MIN then hasMarker = true; break end end
    -- Une ancre doit être un lot de plusieurs durées, ou un marker/sentinelle.
    if #vals < 2 and not hasMarker then return end

    local rec = {
        t = b.t - self.current.t0,
        signature = sig,
        durations = vals,
        marker = hasMarker or nil,
        bossCount = bossCount(),
    }
    local prev = self.current.batches[#self.current.batches]
    if not prev or prev.signature ~= rec.signature then
        self.current.anchorChanges = self.current.anchorChanges + 1
    else
        rec.repeatOfPrevious = true
    end
    self.current.batches[#self.current.batches+1] = rec
    self.current.bossCount = rec.bossCount

    if NS.Bus and type(NS.Bus.Emit) == "function" then
        NS.Bus:Emit("TMB_PHASE_ANCHOR_OBSERVED", rec)
    end
end

function PD:OnTimelineAdded(x)
    if not self.current then return end
    local info = readInfo(x)
    if not info then return end
    -- Pour P0-03, seules les données Blizzard natives servent à la détection.
    -- Better Timeline/BigWigs/DBM restent des confirmations externes séparées.
    if info.source ~= nil and not NS:IsSecret(info.source) and safeNumber(info.source) ~= 0 then return end
    local dur = safeNumber(info.duration)
    if not dur or dur <= 0 then return end

    if dur >= SENTINEL_MIN then
        self.sentinelTotal = (self.sentinelTotal or 0) + 1
        self.current.sentinelEvents = (self.current.sentinelEvents or 0) + 1
        local key = math.floor(dur + 0.5)
        self.current.sentinelValues[key] = (self.current.sentinelValues[key] or 0) + 1
    end

    local now = GetTime()
    local b = self._batch
    if not b or (now - b.last) > BATCH_WINDOW then
        self:FlushBatch()
        self._batchSerial = (self._batchSerial or 0) + 1
        b = { t=now, last=now, durations={}, serial=self._batchSerial }
        self._batch = b
    else
        b.last = now
    end
    b.durations[#b.durations+1] = dur

    local serial = b.serial
    C_Timer.After(BATCH_WINDOW + 0.04, function()
        if PD._batch and PD._batch.serial == serial and (GetTime() - PD._batch.last) >= BATCH_WINDOW then
            PD:FlushBatch()
        end
    end)
end

function PD:OnStateUpdated()
    if self.current then self.current.stateUpdates = self.current.stateUpdates + 1 end
end

function PD:OnExternal(kind, record)
    if not self.current or type(record) ~= "table" then return end
    if kind == "start" or kind == "merge" or kind == "update" then
        self.externalSignals = self.externalSignals + 1
        self.current.externalSignals = self.current.externalSignals + 1
    end
end

-- Analyse hors combat des lots Timeline déjà stockés par Learn. Cette fonction
-- ne décide PAS d'une phase : elle mesure des ancres reproductibles entre pulls.
local function batchesFromPull(p)
    local obs = p and p.obs or nil
    if type(obs) ~= "table" or not Store then return {} end
    local rows = {}
    for _, o in ipairs(obs) do
        if o[2] == Store.KIND_TIMELINE and type(o[1]) == "number" and type(o[3]) == "number" then
            rows[#rows+1] = { t=o[1], dur=o[3] }
        end
    end
    table.sort(rows, function(a,b) return a.t < b.t end)

    local groups, cur
    groups = {}
    for _, r in ipairs(rows) do
        if not cur or (r.t - cur.last) > BATCH_WINDOW then
            cur = { t=r.t, last=r.t, durations={} }
            groups[#groups+1] = cur
        else
            cur.last = r.t
        end
        cur.durations[#cur.durations+1] = r.dur
    end

    local out = {}
    for _, g in ipairs(groups) do
        local sig, vals = signature(g.durations)
        local marker = false
        for _, d in ipairs(vals) do if d >= SENTINEL_MIN then marker = true; break end end
        if #vals >= 2 or marker then
            out[#out+1] = { t=g.t, signature=sig, durations=vals, marker=marker or nil }
        end
    end
    return out
end

local function median(t)
    if #t == 0 then return 0 end
    local c = {}; for i=1,#t do c[i]=t[i] end; table.sort(c)
    local n=#c
    if n%2==1 then return c[(n+1)/2] end
    return (c[n/2]+c[n/2+1])/2
end

function PD:AnalyzeLearn(encounterID)
    local result = {
        encounterID = tonumber(encounterID) or encounterID,
        pulls = 0,
        stableAnchors = 0,
        tentativeAnchors = 0,
        transitionCandidates = 0,
        confidence = "LOW",
        signatures = {},
    }
    if not Store or type(Store.GetPulls) ~= "function" then return result end
    if InCombatLockdown and InCombatLockdown() then result.deferred=true; return result end

    local key = tostring(encounterID)
    local ok, pulls = pcall(Store.GetPulls, Store, key)
    if not ok or type(pulls) ~= "table" or #pulls == 0 then
        local n = tonumber(encounterID)
        if n then ok, pulls = pcall(Store.GetPulls, Store, n) end
    end
    if not ok or type(pulls) ~= "table" then return result end
    result.pulls = #pulls
    if result.pulls == 0 then return result end

    local stats = {}
    local transitionCounts = {}
    for pullIdx, p in ipairs(pulls) do
        local batches = batchesFromPull(p)
        local seenPull = {}
        local prev
        for _, b in ipairs(batches) do
            local s = stats[b.signature]
            if not s then s={ total=0, pulls=0, firsts={}, marker=b.marker }; stats[b.signature]=s end
            s.total = s.total + 1
            if not seenPull[b.signature] then s.pulls=s.pulls+1; seenPull[b.signature]=true end
            s.firsts[#s.firsts+1] = b.t
            if prev and prev ~= b.signature then
                local tk = prev .. " -> " .. b.signature
                transitionCounts[tk] = (transitionCounts[tk] or 0) + 1
            end
            prev = b.signature
        end
    end

    for sig, s in pairs(stats) do
        local stable = result.pulls >= 2 and s.pulls >= math.min(2, result.pulls)
        local tentative = not stable and (s.total >= 2 or s.pulls >= 1)
        if stable then result.stableAnchors = result.stableAnchors + 1
        elseif tentative then result.tentativeAnchors = result.tentativeAnchors + 1 end
        result.signatures[#result.signatures+1] = {
            signature=sig, pulls=s.pulls, total=s.total,
            firstSeen=median(s.firsts), stable=stable, tentative=tentative,
            marker=s.marker,
        }
    end
    for _, n in pairs(transitionCounts) do
        if result.pulls >= 2 and n >= 2 then result.transitionCandidates = result.transitionCandidates + 1 end
    end
    table.sort(result.signatures, function(a,b)
        if a.stable ~= b.stable then return a.stable end
        return a.firstSeen < b.firstSeen
    end)

    if result.pulls >= 3 and result.stableAnchors >= 1 then result.confidence = "HIGH"
    elseif result.pulls >= 2 and result.stableAnchors >= 1 then result.confidence = "MEDIUM"
    else result.confidence = "LOW" end
    return result
end

function PD:GetRuntimeStatus()
    local c = self.current or self.last
    if not c then return { mode=self.mode, active=false, anchors=0, changes=0, externalSignals=self.externalSignals, sentinelEvents=0, sentinelTotal=self.sentinelTotal or 0, sentinelValues={} } end
    return {
        mode=self.mode,
        active=self.current ~= nil,
        encounterID=c.encounterID,
        anchors=#(c.batches or {}),
        changes=c.anchorChanges or 0,
        stateUpdates=c.stateUpdates or 0,
        bossCount=c.bossCount or 0,
        externalSignals=c.externalSignals or 0,
        sentinelEvents=c.sentinelEvents or 0,
        sentinelTotal=self.sentinelTotal or 0,
        sentinelValues=c.sentinelValues or {},
    }
end

function PD:Init()
    if self.frame then return end
    local f = CreateFrame("Frame")
    self.frame = f
    f:RegisterEvent("ENCOUNTER_START")
    f:RegisterEvent("ENCOUNTER_END")
    f:RegisterEvent("ENCOUNTER_TIMELINE_EVENT_ADDED")
    f:RegisterEvent("ENCOUNTER_TIMELINE_STATE_UPDATED")
    f:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
    f:SetScript("OnEvent", function(_, event, a1, a2, a3, a4, a5)
        if event == "ENCOUNTER_START" then
            PD:Begin(a1, a2)
        elseif event == "ENCOUNTER_END" then
            PD:End(safeNumber(a5) == 1 and "kill" or "wipe")
        elseif event == "ENCOUNTER_TIMELINE_EVENT_ADDED" then
            PD:OnTimelineAdded(a1)
        elseif event == "ENCOUNTER_TIMELINE_STATE_UPDATED" then
            PD:OnStateUpdated()
        elseif event == "INSTANCE_ENCOUNTER_ENGAGE_UNIT" then
            if PD.current then PD.current.bossCount = bossCount() end
        end
    end)

    if NS.BossModBridge and type(NS.BossModBridge.RegisterListener) == "function" then
        NS.BossModBridge:RegisterListener(function(kind, record) PD:OnExternal(kind, record) end)
    end
end

PD:Init()
