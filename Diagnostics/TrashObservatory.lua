---@diagnostic disable: undefined-global
-- TomoBoss 2.8.0-beta5d2 — Midnight-safe TrashCD observatory + deferred cast-target audit.
--
-- Goals:
--   * absolutely no combat-log event registration;
--   * never inspect/compare/stringify secret enemy cast identity;
--   * record NeverSecret castBarID and non-secret spellID only;
--   * correlate a spell with TrashCD reference data only after Blizzard exposed
--     that spellID as non-secret;
--   * optional PREVIEW TTS is diagnostic and OFF by default.
--
-- This module does not replace the existing TrashCD cast-bar/nameplate module.

local addonName, NS = ...
if type(NS) ~= "table" then return end

local O = NS.TrashObservatory or {}
NS.TrashObservatory = O

O.mode = "observation-only"
O.schema = 3
O.previewEnabled = O.previewEnabled or false
O.prewarn = 3.0
O.maxEventsPerPull = 120
O.maxStoredPulls = 30
O.metrics = O.metrics or {
    castEvents=0, primaryCasts=0, nonSecretSpellIDs=0, secretSpellIDs=0,
    castBarEvents=0, castBarInfoMatches=0, castBarInfoMissing=0, castBarInfoMismatch=0,
    referenceMatches=0, previewEligible=0, previewFired=0,
    nameplatesAdded=0, nameplatesRemoved=0, secretUnitTokens=0,
    targetSamples=0, targetProbeAttempts=0, targetProbeStale=0,
    targetImmediateUsable=0, targetImmediateSecret=0, targetImmediateNone=0,
    targetDeferredRecovered=0, targetDeferredSecret=0,
    targetSecret=0, targetNone=0, targetSelf=0, targetTank=0,
    targetHealer=0, targetDps=0, targetGroup=0, targetOther=0, targetApiErrors=0,
}
O.uniqueSpells = O.uniqueSpells or {}
O.uniqueCastBars = O.uniqueCastBars or {}
O.activePredictions = O.activePredictions or {}
O.activeTargetProbes = O.activeTargetProbes or {}
O.targetProbeSerial = O.targetProbeSerial or 0
O.targetProbeDelays = { 0.00, 0.05, 0.15, 0.30 }
O.encounterActive = false
O.current = nil
O.last = nil
O.lastVoiceAt = 0

local function isSecret(v)
    return type(issecretvalue) == "function" and issecretvalue(v) or false
end

local function safeNumber(v)
    if isSecret(v) then return nil end
    return type(v) == "number" and v or nil
end

local function safeString(v)
    if isSecret(v) then return nil end
    return type(v) == "string" and v or nil
end

local function countSet(t)
    local n = 0
    for _ in pairs(t or {}) do n = n + 1 end
    return n
end

local function chat(text)
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage(text)
    else
        print(text)
    end
end

local function nowDate()
    if type(date) == "function" then
        local ok, s = pcall(date, "%Y-%m-%d %H:%M:%S")
        if ok and type(s) == "string" then return s end
    end
    return "?"
end

local function currentContext()
    local ctx = { instanceID=nil, difficultyID=nil, instanceType=nil, mapID=nil }
    if type(GetInstanceInfo) == "function" then
        local ok, _, instanceType, difficultyID, _, _, _, _, instanceID = pcall(GetInstanceInfo)
        if ok then
            ctx.instanceType = safeString(instanceType)
            ctx.difficultyID = safeNumber(difficultyID)
            ctx.instanceID = safeNumber(instanceID)
        end
    end
    if C_ChallengeMode and type(C_ChallengeMode.GetActiveChallengeMapID) == "function" then
        local ok, mapID = pcall(C_ChallengeMode.GetActiveChallengeMapID)
        if ok then ctx.mapID = safeNumber(mapID) end
    end
    return ctx
end

local function inSupportedDungeon()
    local c = currentContext()
    if c.mapID then return true, c end
    return c.instanceType == "party", c
end

local function acceptedUnit(v)
    local token = safeString(v)
    if not token then
        if isSecret(v) then O.metrics.secretUnitTokens = (O.metrics.secretUnitTokens or 0) + 1 end
        return nil
    end
    if token:match("^nameplate%d+$") then return token end
    if token == "target" or token == "focus" or token == "mouseover"
        or token == "softenemy" or token == "softinteract" then
        return token
    end
    return nil
end


-- UnitSpellTargetName() exists specifically to expose the current spell target,
-- but its return may be secret in Midnight. beta5d2 samples it at cast start and
-- again shortly afterwards, because the default UI can receive the target after
-- UNIT_SPELLCAST_START. Deferred probes are accepted only while the same
-- NeverSecret castBarID is still active, so a target can never be attributed to
-- a later cast by accident.
local function safeUnitName(unit)
    if type(UnitName) ~= "function" then return nil end
    local ok, name, realm = pcall(UnitName, unit)
    if not ok or isSecret(name) or isSecret(realm) then return nil end
    if type(name) ~= "string" or name == "" then return nil end
    local full
    if type(realm) == "string" and realm ~= "" then full = name .. "-" .. realm end
    return name, full
end

local function classifyTargetName(targetName)
    if targetName == nil then return "NONE" end
    if isSecret(targetName) then return "SECRET" end
    if type(targetName) ~= "string" or targetName == "" then return "NONE" end

    local playerName, playerFull = safeUnitName("player")
    if targetName == playerName or (playerFull and targetName == playerFull) then
        return "SELF"
    end

    for i=1,4 do
        local unit = "party" .. i
        local name, full = safeUnitName(unit)
        if name and (targetName == name or (full and targetName == full)) then
            local role
            if type(UnitGroupRolesAssigned) == "function" then
                local ok, value = pcall(UnitGroupRolesAssigned, unit)
                if ok and not isSecret(value) and type(value) == "string" then role = value end
            end
            if role == "TANK" then return "TANK" end
            if role == "HEALER" then return "HEALER" end
            if role == "DAMAGER" then return "DPS" end
            return "GROUP"
        end
    end
    return "OTHER"
end

local function readTargetClass(unit)
    if type(UnitSpellTargetName) ~= "function" then return "UNAVAILABLE" end
    local ok, targetName = pcall(UnitSpellTargetName, unit)
    if not ok then return "ERROR" end
    return classifyTargetName(targetName)
end

-- Read only the NeverSecret castBarID return. All other UnitCastingInfo /
-- UnitChannelInfo values may be secret and are intentionally ignored.
local function currentCastBarID(unit)
    if type(UnitCastingInfo) == "function" then
        local ok, v1,v2,v3,v4,v5,v6,v7,v8,v9,barID = pcall(UnitCastingInfo, unit)
        if ok then
            local id = safeNumber(barID)
            if id then return id, "CAST" end
        end
    end
    if type(UnitChannelInfo) == "function" then
        local ok, v1,v2,v3,v4,v5,v6,v7,v8,v9,v10,barID = pcall(UnitChannelInfo, unit)
        if ok then
            local id = safeNumber(barID)
            if id then return id, "CHANNEL" end
        end
    end
    return nil, nil
end

local function targetClassIsUsable(class)
    return class == "SELF" or class == "TANK" or class == "HEALER"
        or class == "DPS" or class == "GROUP" or class == "OTHER"
end

local function bumpFinalTargetClass(metrics, class)
    if class == "SECRET" then metrics.targetSecret = (metrics.targetSecret or 0) + 1
    elseif class == "NONE" or class == "UNAVAILABLE" then metrics.targetNone = (metrics.targetNone or 0) + 1
    elseif class == "SELF" then metrics.targetSelf = (metrics.targetSelf or 0) + 1
    elseif class == "TANK" then metrics.targetTank = (metrics.targetTank or 0) + 1
    elseif class == "HEALER" then metrics.targetHealer = (metrics.targetHealer or 0) + 1
    elseif class == "DPS" then metrics.targetDps = (metrics.targetDps or 0) + 1
    elseif class == "GROUP" then metrics.targetGroup = (metrics.targetGroup or 0) + 1
    elseif class == "OTHER" then metrics.targetOther = (metrics.targetOther or 0) + 1
    end
end

function O:FinalizeTargetProbe(key, probe, class, reason, delay)
    if type(probe) ~= "table" or probe.done then return end
    probe.done = true
    if probe.timer and type(probe.timer.Cancel) == "function" then
        pcall(probe.timer.Cancel, probe.timer)
    end
    self.activeTargetProbes[key] = nil

    class = class or probe.bestClass or "NONE"
    delay = tonumber(delay) or probe.lastDelay or 0
    self.metrics.targetSamples = (self.metrics.targetSamples or 0) + 1
    bumpFinalTargetClass(self.metrics, class)

    if (probe.immediateClass == "NONE" or probe.immediateClass == nil) and delay > 0 then
        if targetClassIsUsable(class) then
            self.metrics.targetDeferredRecovered = (self.metrics.targetDeferredRecovered or 0) + 1
        elseif class == "SECRET" then
            self.metrics.targetDeferredSecret = (self.metrics.targetDeferredSecret or 0) + 1
        end
    end
    if reason == "STALE" then
        self.metrics.targetProbeStale = (self.metrics.targetProbeStale or 0) + 1
    end

    if probe.eventRow then
        probe.eventRow.targetClass = class
        probe.eventRow.targetImmediate = probe.immediateClass or "NONE"
        probe.eventRow.targetDelayMs = math.floor(delay * 1000 + 0.5)
        probe.eventRow.targetProbes = probe.attempts or 0
        probe.eventRow.targetReason = reason or "FINAL"
    end
end

function O:_RunTargetProbe(key, index)
    local probe = self.activeTargetProbes[key]
    if not probe or probe.done then return end

    local delay = self.targetProbeDelays[index] or 0
    probe.lastDelay = delay
    probe.attempts = (probe.attempts or 0) + 1
    self.metrics.targetProbeAttempts = (self.metrics.targetProbeAttempts or 0) + 1

    -- After the immediate sample, only continue if the same opaque cast is
    -- still active. castBarID is NeverSecret and safe to compare.
    if index > 1 and probe.castBarID then
        local activeBarID = currentCastBarID(probe.unit)
        if activeBarID ~= probe.castBarID then
            self:FinalizeTargetProbe(key, probe, probe.bestClass or "NONE", "STALE", delay)
            return
        end
    end

    local class = readTargetClass(probe.unit)
    if index == 1 then
        probe.immediateClass = class
        if targetClassIsUsable(class) then
            self.metrics.targetImmediateUsable = (self.metrics.targetImmediateUsable or 0) + 1
        elseif class == "SECRET" then
            self.metrics.targetImmediateSecret = (self.metrics.targetImmediateSecret or 0) + 1
        elseif class == "NONE" or class == "UNAVAILABLE" then
            self.metrics.targetImmediateNone = (self.metrics.targetImmediateNone or 0) + 1
        end
    end

    if class == "ERROR" then
        self.metrics.targetApiErrors = (self.metrics.targetApiErrors or 0) + 1
        self:FinalizeTargetProbe(key, probe, probe.bestClass or "NONE", "ERROR", delay)
        return
    elseif class ~= "NONE" and class ~= "UNAVAILABLE" then
        probe.bestClass = class
        self:FinalizeTargetProbe(key, probe, class, index == 1 and "IMMEDIATE" or "DEFERRED", delay)
        return
    end

    probe.bestClass = probe.bestClass or class

    -- Without castBarID we cannot safely prove a later sample still belongs to
    -- this cast, so never defer in that case.
    if not probe.castBarID or index >= #self.targetProbeDelays then
        self:FinalizeTargetProbe(key, probe, probe.bestClass or "NONE", "EXHAUSTED", delay)
        return
    end

    local nextIndex = index + 1
    local nextDelay = self.targetProbeDelays[nextIndex] or delay
    local wait = math.max(0.01, nextDelay - delay)
    probe.timer = C_Timer.NewTimer(wait, function()
        if O then O:_RunTargetProbe(key, nextIndex) end
    end)
end

function O:StartTargetProbe(unit, castBarID, eventRow)
    self.targetProbeSerial = (self.targetProbeSerial or 0) + 1
    local key
    if castBarID then
        key = unit .. "|" .. tostring(castBarID)
    else
        key = unit .. "|noid|" .. tostring(self.targetProbeSerial)
    end

    local previous = self.activeTargetProbes[key]
    if previous then
        self:FinalizeTargetProbe(key, previous, previous.bestClass or "NONE", "REPLACED", previous.lastDelay or 0)
    end

    local probe = {
        unit=unit, castBarID=castBarID, eventRow=eventRow,
        attempts=0, bestClass=nil, immediateClass=nil, lastDelay=0,
    }
    self.activeTargetProbes[key] = probe
    self:_RunTargetProbe(key, 1)
end

function O:CancelAllTargetProbes(reason, discard)
    local keys = {}
    for key in pairs(self.activeTargetProbes or {}) do keys[#keys+1] = key end
    for _, key in ipairs(keys) do
        local probe = self.activeTargetProbes[key]
        if probe then
            if probe.timer and type(probe.timer.Cancel) == "function" then
                pcall(probe.timer.Cancel, probe.timer)
            end
            if discard then
                self.activeTargetProbes[key] = nil
            else
                self:FinalizeTargetProbe(key, probe, probe.bestClass or "NONE", reason or "CANCELLED", probe.lastDelay or 0)
            end
        end
    end
end

local function recorderRoot(create)
    local db = rawget(_G, "TomoBossRecorderDB")
    if type(db) ~= "table" then
        if not create then return nil end
        db = {}
        _G.TomoBossRecorderDB = db
    end
    if type(db.trashObservatory) ~= "table" then
        if not create then return nil end
        db.trashObservatory = { version=O.schema, pulls={} }
    end
    local r = db.trashObservatory
    r.version = O.schema
    if type(r.pulls) ~= "table" then r.pulls = {} end
    return r
end

local function cancelPrediction(key)
    local p = O.activePredictions[key]
    if p and p.timer and type(p.timer.Cancel) == "function" then
        pcall(p.timer.Cancel, p.timer)
    end
    O.activePredictions[key] = nil
end

function O:CancelPredictionsForUnit(unit)
    if type(unit) ~= "string" then return end
    local prefix = unit .. "|"
    for key in pairs(self.activePredictions) do
        if key:sub(1, #prefix) == prefix then cancelPrediction(key) end
    end
end

function O:CancelAllPredictions()
    local keys = {}
    for key in pairs(self.activePredictions) do keys[#keys+1] = key end
    for _, key in ipairs(keys) do cancelPrediction(key) end
end

local VOICE_TEXT = {
    enUS = {
        aoe="AOE", tank="Tank hit", move="Move", frontal="Frontal", targeted="Targeted",
        interrupt="Interrupt", adds="Adds", dodge="Dodge", cc="Crowd control", spread="Spread",
        soothe="Soothe", charge="Charge", breakshield="Break shield", totem="Totem", behind="Behind",
        bleed="Bleed", purge="Purge", save="Save ally", ccinterrupt="Control interrupt", shield="Shield",
        stack="Stack", poison="Poison", orb="Orb", switch="Switch target", root="Root", drop="Drop circle",
        curse="Curse", keepmoving="Keep moving", magic="Magic", trap="Trap",
    },
    frFR = {
        aoe="AOE", tank="Coup tank", move="Bougez", frontal="Frontal", targeted="Ciblé",
        interrupt="Interruption", adds="Adds", dodge="Esquivez", cc="Contrôle", spread="Écartez-vous",
        soothe="Enrage", charge="Charge", breakshield="Brisez le bouclier", totem="Totem", behind="Derrière",
        bleed="Saignement", purge="Purge", save="Sauvez l'allié", ccinterrupt="Contrôle", shield="Bouclier",
        stack="Regroupez-vous", poison="Poison", orb="Orbe", switch="Changez de cible", root="Enracinement",
        drop="Posez la zone", curse="Malédiction", keepmoving="Restez en mouvement", magic="Magie", trap="Piège",
    },
}

local function voiceText(key)
    if type(key) ~= "string" then return nil end
    local locale = type(GetLocale) == "function" and GetLocale() or "enUS"
    local tbl = VOICE_TEXT[locale] or VOICE_TEXT.enUS
    return tbl[key] or VOICE_TEXT.enUS[key]
end

function O:SpeakPreview(key)
    local text = voiceText(key)
    if not text then return false end
    local now = GetTime()
    if now - (self.lastVoiceAt or 0) < 0.8 then return false end
    self.lastVoiceAt = now

    if C_VoiceChat and type(C_VoiceChat.GetTtsVoices) == "function"
        and type(C_VoiceChat.SpeakText) == "function" then
        local voiceID
        if C_TTSSettings and type(C_TTSSettings.GetVoiceOptionID) == "function"
            and Enum and Enum.TtsVoiceType and Enum.TtsVoiceType.Standard ~= nil then
            local okPreferred, preferred = pcall(C_TTSSettings.GetVoiceOptionID, Enum.TtsVoiceType.Standard)
            if okPreferred then voiceID = safeNumber(preferred) end
        end
        if not voiceID then
            local ok, voices = pcall(C_VoiceChat.GetTtsVoices)
            if ok and type(voices) == "table" and type(voices[1]) == "table" then
                voiceID = safeNumber(voices[1].voiceID)
            end
        end
        if voiceID then
            local spoken = pcall(C_VoiceChat.SpeakText, voiceID, text, 0, 85, false)
            if spoken then return true end
        end
    end
    if type(PlaySound) == "function" and SOUNDKIT and SOUNDKIT.RAID_WARNING then
        pcall(PlaySound, SOUNDKIT.RAID_WARNING, "Master")
        return true
    end
    return false
end

function O:BeginPull(reason)
    if self.current or self.encounterActive then return end
    local ok, ctx = inSupportedDungeon()
    if not ok then return end
    self.current = {
        t0=GetTime(), date=nowDate(), reason=reason or "combat",
        instanceID=ctx.instanceID, difficultyID=ctx.difficultyID, mapID=ctx.mapID,
        events={}, primary=0, secret=0, nonSecret=0, refs=0, eligible=0,
        castBarEvents=0, seenCastBars={}, uniqueCastBars={},
    }
end

local function compactEvent(ev)
    return {
        t=ev.t, kind=ev.kind, unit=ev.unit, castBarID=ev.castBarID,
        spellID=ev.spellID, secretSpell=ev.secretSpell or nil,
        ref=ev.ref or nil, eligible=ev.eligible or nil,
        targetClass=ev.targetClass or nil, targetImmediate=ev.targetImmediate or nil,
        targetDelayMs=ev.targetDelayMs or nil, targetProbes=ev.targetProbes or nil,
        targetReason=ev.targetReason or nil,
    }
end

function O:PersistPull(p)
    if type(p) ~= "table" then return end
    local root = recorderRoot(true)
    local row = {
        date=p.date, duration=math.max(0, (p.endedAt or GetTime()) - (p.t0 or GetTime())),
        instanceID=p.instanceID, difficultyID=p.difficultyID, mapID=p.mapID,
        primary=p.primary or 0, secret=p.secret or 0, nonSecret=p.nonSecret or 0,
        refs=p.refs or 0, eligible=p.eligible or 0,
        castBarEvents=p.castBarEvents or 0, uniqueCastBars=countSet(p.uniqueCastBars), events={},
    }
    for i=1, math.min(#(p.events or {}), self.maxEventsPerPull) do
        row.events[#row.events+1] = compactEvent(p.events[i])
    end
    root.pulls[#root.pulls+1] = row
    while #root.pulls > self.maxStoredPulls do table.remove(root.pulls, 1) end
    root.last = row
    self.last = row
end

function O:EndPull(reason)
    local p = self.current
    if not p then return end
    p.endedAt = GetTime()
    p.endReason = reason or "combat-end"
    self:CancelAllTargetProbes("PULL-END", false)
    self.current = nil
    self:CancelAllPredictions()
    if (p.primary or 0) > 0 then self:PersistPull(p) end
end

function O:Record(kind, unit, spellID, castBarID)
    if self.encounterActive then return end
    local token = acceptedUnit(unit)
    if not token then return end
    if not self.current then self:BeginPull("unit-cast") end
    local p = self.current
    if not p then return end

    local sid = safeNumber(spellID)
    local barID = safeNumber(castBarID)
    local secretSpell = sid == nil and isSecret(spellID)

    self.metrics.castEvents = (self.metrics.castEvents or 0) + 1
    if barID then
        self.metrics.castBarEvents = (self.metrics.castBarEvents or 0) + 1
        self.uniqueCastBars[barID] = true
        p.castBarEvents = (p.castBarEvents or 0) + 1
        p.uniqueCastBars[barID] = true
    end

    -- A cast can emit START/CHANNEL and then SUCCEEDED. castBarID is the
    -- NeverSecret identity Blizzard explicitly provides for castbar-visible
    -- casts, so use it only to dedupe observations; never infer a spell from it.
    local primary = false
    if kind == "START" or kind == "CHANNEL" then
        if barID then
            if not p.seenCastBars[barID] then
                p.seenCastBars[barID] = true
                primary = true
            end
        else
            primary = true
        end
    elseif kind == "SUCCEEDED" then
        -- Instant/non-castbar spells can arrive only as SUCCEEDED. If a
        -- castBarID exists and START was already seen, do not count/schedule
        -- the same cast twice.
        if barID then
            if not p.seenCastBars[barID] then
                p.seenCastBars[barID] = true
                primary = true
            end
        elseif sid then
            primary = true
        end
    end

    if primary then
        self.metrics.primaryCasts = (self.metrics.primaryCasts or 0) + 1
        p.primary = (p.primary or 0) + 1

        if sid then
            self.metrics.nonSecretSpellIDs = (self.metrics.nonSecretSpellIDs or 0) + 1
            p.nonSecret = (p.nonSecret or 0) + 1
            self.uniqueSpells[sid] = true
        elseif secretSpell then
            self.metrics.secretSpellIDs = (self.metrics.secretSpellIDs or 0) + 1
            p.secret = (p.secret or 0) + 1
        end
    end

    local ref
    if primary and sid and NS.TrashCDReference and type(NS.TrashCDReference.Get) == "function" then
        ref = NS.TrashCDReference:Get(p.mapID, sid)
        if ref then
            self.metrics.referenceMatches = (self.metrics.referenceMatches or 0) + 1
            p.refs = (p.refs or 0) + 1
            if ref.previewEligible then
                self.metrics.previewEligible = (self.metrics.previewEligible or 0) + 1
                p.eligible = (p.eligible or 0) + 1
            end
        end
    end

    local eventRow
    if primary and #p.events < self.maxEventsPerPull then
        eventRow = {
            t=GetTime() - p.t0, kind=kind, unit=token, castBarID=barID,
            spellID=sid, secretSpell=secretSpell, ref=ref and true or false,
            eligible=ref and ref.previewEligible or false,
        }
        p.events[#p.events+1] = eventRow
    end

    if primary and (kind == "START" or kind == "CHANNEL") then
        if barID then
            local infoBarID = currentCastBarID(token)
            if infoBarID == barID then
                self.metrics.castBarInfoMatches = (self.metrics.castBarInfoMatches or 0) + 1
            elseif infoBarID == nil then
                self.metrics.castBarInfoMissing = (self.metrics.castBarInfoMissing or 0) + 1
            else
                self.metrics.castBarInfoMismatch = (self.metrics.castBarInfoMismatch or 0) + 1
            end
        end
        self:StartTargetProbe(token, barID, eventRow)
    end

    if (kind == "INTERRUPTED" or kind == "FAILED") and self.previewEnabled then
        if sid then
            cancelPrediction(token .. "|" .. tostring(sid))
        else
            -- Identity is restricted: cancel all predictions for that unit
            -- rather than risk keeping a stale warning.
            self:CancelPredictionsForUnit(token)
        end
    end

    if primary and sid and ref and ref.previewEligible and self.previewEnabled then
        self:SchedulePreview(token, sid, ref)
    end
end

function O:SchedulePreview(unit, spellID, ref)
    local cd = safeNumber(ref.cdMedian)
    if not cd or cd <= self.prewarn then return end
    local key = unit .. "|" .. tostring(spellID)
    cancelPrediction(key)
    local delay = math.max(0.1, cd - self.prewarn)
    local voiceKey = ref.voiceKey
    local timer = C_Timer.NewTimer(delay, function()
        local rec = O.activePredictions[key]
        if not rec then return end
        O.activePredictions[key] = nil
        O.metrics.previewFired = (O.metrics.previewFired or 0) + 1
        O:SpeakPreview(voiceKey)
        chat(string.format("|cff33e6a6TomoBoss Trash PREVIEW|r  spell=%d  %.1fs reference  %s",
            spellID, cd, tostring(voiceText(voiceKey) or "warning")))
    end)
    self.activePredictions[key] = { timer=timer, unit=unit, spellID=spellID, cd=cd, voiceKey=voiceKey }
end

function O:SetPreview(enabled)
    self.previewEnabled = enabled and true or false
    if not self.previewEnabled then self:CancelAllPredictions() end
    chat("|cff33e6a6TomoBoss Trash preview|r : " .. (self.previewEnabled and "|cff33e6a6ON|r" or "|cffffb86cOFF|r"))
    if self.previewEnabled then
        chat("|cffaaaaaaDiagnostic only: prediction starts only after a non-secret known cast; no CLEU and no secret identity decoding.|r")
    end
end

function O:Reset()
    self:CancelAllPredictions()
    self.current = nil
    self.last = nil
    self:CancelAllTargetProbes("RESET", true)
    self.metrics = {
        castEvents=0, primaryCasts=0, nonSecretSpellIDs=0, secretSpellIDs=0,
        castBarEvents=0, castBarInfoMatches=0, castBarInfoMissing=0, castBarInfoMismatch=0,
        referenceMatches=0, previewEligible=0, previewFired=0,
        nameplatesAdded=0, nameplatesRemoved=0, secretUnitTokens=0,
        targetSamples=0, targetProbeAttempts=0, targetProbeStale=0,
        targetImmediateUsable=0, targetImmediateSecret=0, targetImmediateNone=0,
        targetDeferredRecovered=0, targetDeferredSecret=0,
        targetSecret=0, targetNone=0, targetSelf=0, targetTank=0,
        targetHealer=0, targetDps=0, targetGroup=0, targetOther=0, targetApiErrors=0,
    }
    self.uniqueSpells = {}
    self.uniqueCastBars = {}
    local root = recorderRoot(false)
    if root then root.pulls = {}; root.last = nil end
    chat("|cff33e6a6TomoBoss Trash Observatory|r : capture reset.")
end


function O:GetStatus()
    local root = recorderRoot(false)
    local ctx = currentContext()
    local refMeta = NS.TrashCDReference and NS.TrashCDReference.GetStatus and NS.TrashCDReference:GetStatus() or {}
    return {
        mode=self.mode, preview=self.previewEnabled,
        active=self.current ~= nil, encounterActive=self.encounterActive,
        instanceID=ctx.instanceID, difficultyID=ctx.difficultyID, mapID=ctx.mapID,
        storedPulls=root and #(root.pulls or {}) or 0,
        castEvents=self.metrics.castEvents or 0,
        primaryCasts=self.metrics.primaryCasts or 0,
        nonSecretSpellIDs=self.metrics.nonSecretSpellIDs or 0,
        secretSpellIDs=self.metrics.secretSpellIDs or 0,
        uniqueNonSecretSpells=countSet(self.uniqueSpells),
        castBarEvents=self.metrics.castBarEvents or 0,
        uniqueCastBarIDs=countSet(self.uniqueCastBars),
        castBarInfoMatches=self.metrics.castBarInfoMatches or 0,
        castBarInfoMissing=self.metrics.castBarInfoMissing or 0,
        castBarInfoMismatch=self.metrics.castBarInfoMismatch or 0,
        referenceMatches=self.metrics.referenceMatches or 0,
        previewEligible=self.metrics.previewEligible or 0,
        previewFired=self.metrics.previewFired or 0,
        nameplatesAdded=self.metrics.nameplatesAdded or 0,
        nameplatesRemoved=self.metrics.nameplatesRemoved or 0,
        targetSamples=self.metrics.targetSamples or 0,
        targetProbeAttempts=self.metrics.targetProbeAttempts or 0,
        targetProbeStale=self.metrics.targetProbeStale or 0,
        targetImmediateUsable=self.metrics.targetImmediateUsable or 0,
        targetImmediateSecret=self.metrics.targetImmediateSecret or 0,
        targetImmediateNone=self.metrics.targetImmediateNone or 0,
        targetDeferredRecovered=self.metrics.targetDeferredRecovered or 0,
        targetDeferredSecret=self.metrics.targetDeferredSecret or 0,
        targetSecret=self.metrics.targetSecret or 0,
        targetNone=self.metrics.targetNone or 0, targetSelf=self.metrics.targetSelf or 0,
        targetTank=self.metrics.targetTank or 0, targetHealer=self.metrics.targetHealer or 0,
        targetDps=self.metrics.targetDps or 0, targetGroup=self.metrics.targetGroup or 0,
        targetOther=self.metrics.targetOther or 0, targetApiErrors=self.metrics.targetApiErrors or 0,
        referenceMaps=refMeta.maps or 0, referenceSpells=refMeta.spells or 0,
        referencePreviewEligible=refMeta.previewEligible or 0,
    }
end

function O:RunDoctor()
    local s = self:GetStatus()
    chat("|cff33e6a6TomoBoss TrashCD Observatory|r")
    chat("  Mode ....................... Midnight-safe observation; NO CLEU")
    chat("  Active map ................ " .. tostring(s.mapID or "none") .. "  instance=" .. tostring(s.instanceID or "none"))
    chat("  Stored trash pulls ........ " .. tostring(s.storedPulls))
    chat("  Primary cast observations . " .. tostring(s.primaryCasts))
    chat("  Non-secret spellID samples  " .. tostring(s.nonSecretSpellIDs) .. "  unique=" .. tostring(s.uniqueNonSecretSpells))
    chat("  Secret spellID samples .... " .. tostring(s.secretSpellIDs) .. "  dropped")
    chat(string.format("  castBarID-bearing events ... %d  unique=%d",
        s.castBarEvents or 0, s.uniqueCastBarIDs or 0))
    chat(string.format("  CastBar API correlation .... match %d / missing %d / mismatch %d",
        s.castBarInfoMatches or 0, s.castBarInfoMissing or 0, s.castBarInfoMismatch or 0))
    chat(string.format("  Target casts probed ........ %d casts / %d probe attempts / stale %d",
        s.targetSamples or 0, s.targetProbeAttempts or 0, s.targetProbeStale or 0))
    chat(string.format("  Target immediate ........... usable %d / secret %d / none %d",
        s.targetImmediateUsable or 0, s.targetImmediateSecret or 0, s.targetImmediateNone or 0))
    chat(string.format("  Target deferred recovery ... usable %d / secret %d",
        s.targetDeferredRecovered or 0, s.targetDeferredSecret or 0))
    chat(string.format("  Target final visibility .... %d secret / %d none / %d errors",
        s.targetSecret or 0, s.targetNone or 0, s.targetApiErrors or 0))
    chat(string.format("  Cast target classes ........ SELF %d  TANK %d  HEAL %d  DPS %d  GROUP %d  OTHER %d",
        s.targetSelf or 0, s.targetTank or 0, s.targetHealer or 0, s.targetDps or 0,
        s.targetGroup or 0, s.targetOther or 0))
    chat("  Reference matches ......... " .. tostring(s.referenceMatches))
    chat("  Preview-eligible samples .. " .. tostring(s.previewEligible))
    chat("  Preview voice fires ....... " .. tostring(s.previewFired))
    chat("  Preview mode .............. " .. (s.preview and "ON  diagnostic TTS" or "OFF"))
    chat(string.format("  Reference catalog ......... %d maps / %d spells / %d stable preview rows",
        s.referenceMaps, s.referenceSpells, s.referencePreviewEligible))
end

function O:BuildExport()
    local root = recorderRoot(false)
    local pulls = root and root.pulls or {}
    local out = {
        "TomoBoss TrashCD Observatory — beta5d2",
        "Mode=Midnight-safe; combat-log events=NEVER REGISTERED",
        "Secret enemy spellIDs and secret cast targets are counted then discarded; castGUID/name/GUID are never stored.",
        "Cast targets are sampled at 0/50/150/300ms only while the same NeverSecret castBarID is active.",
        "Non-secret targets are stored only as SELF/TANK/HEALER/DPS/GROUP/OTHER; no player names are persisted.",
        "",
    }
    local start = math.max(1, #pulls - 9)
    for i=start,#pulls do
        local p = pulls[i]
        out[#out+1] = string.format("--- pull %d/%d  date=%s  map=%s instance=%s diff=%s duration=%.1fs",
            i, #pulls, tostring(p.date or "?"), tostring(p.mapID or "?"), tostring(p.instanceID or "?"),
            tostring(p.difficultyID or "?"), tonumber(p.duration) or 0)
        out[#out+1] = string.format("primary=%d nonSecret=%d secret=%d refs=%d eligible=%d castBarEvents=%d uniqueCastBars=%d",
            p.primary or 0, p.nonSecret or 0, p.secret or 0, p.refs or 0, p.eligible or 0,
            p.castBarEvents or 0, p.uniqueCastBars or 0)
        for _, e in ipairs(p.events or {}) do
            local spell = e.spellID and tostring(e.spellID) or (e.secretSpell and "<secret>" or "-")
            out[#out+1] = string.format("[%7.2f] %-9s unit=%-12s castBar=%-8s spell=%-10s target=%-7s initial=%-7s delay=%-4sms probes=%s reason=%-9s ref=%s eligible=%s",
                tonumber(e.t) or 0, tostring(e.kind or "?"), tostring(e.unit or "?"),
                tostring(e.castBarID or "-"), spell, tostring(e.targetClass or "-"),
                tostring(e.targetImmediate or "-"), tostring(e.targetDelayMs or "-"),
                tostring(e.targetProbes or "-"), tostring(e.targetReason or "-"),
                e.ref and "yes" or "no", e.eligible and "yes" or "no")
        end
        out[#out+1] = ""
    end
    if #pulls == 0 then out[#out+1] = "(no stored trash pulls yet)" end
    return table.concat(out, "\n")
end

function O:ShowDump()
    local text = self:BuildExport()
    if not self.dumpFrame then
        local f = CreateFrame("Frame", "TomoBossTrashDumpFrame", UIParent, "BackdropTemplate")
        f:SetSize(760, 560)
        f:SetPoint("CENTER")
        f:SetFrameStrata("DIALOG")
        f:SetMovable(true)
        f:EnableMouse(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", f.StartMoving)
        f:SetScript("OnDragStop", f.StopMovingOrSizing)
        f:SetBackdrop({ bgFile="Interface/Buttons/WHITE8X8", edgeFile="Interface/Buttons/WHITE8X8", edgeSize=1 })
        f:SetBackdropColor(0.03,0.04,0.05,0.96)
        f:SetBackdropBorderColor(0.2,0.9,0.65,1)

        local title=f:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
        title:SetPoint("TOPLEFT",14,-12)
        title:SetText("TomoBoss — TrashCD Observatory Dump")

        local close=CreateFrame("Button",nil,f,"UIPanelCloseButton")
        close:SetPoint("TOPRIGHT",-4,-4)

        local sf=CreateFrame("ScrollFrame",nil,f,"UIPanelScrollFrameTemplate")
        sf:SetPoint("TOPLEFT",14,-42)
        sf:SetPoint("BOTTOMRIGHT",-34,14)

        local eb=CreateFrame("EditBox",nil,sf)
        eb:SetMultiLine(true)
        eb:SetAutoFocus(false)
        eb:SetFontObject(ChatFontNormal)
        eb:SetWidth(690)
        eb:SetTextInsets(4,4,4,4)
        eb:SetScript("OnEscapePressed", function() f:Hide() end)
        sf:SetScrollChild(eb)

        f.editBox=eb
        self.dumpFrame=f
    end
    local eb=self.dumpFrame.editBox
    eb:SetText(text)
    local lines=1
    for _ in text:gmatch("\n") do lines=lines+1 end
    eb:SetHeight(math.max(480, lines*15))
    self.dumpFrame:Show()
    eb:SetFocus()
    eb:HighlightText()
end

function O:OnEvent(event, a1, a2, a3, a4, a5)
    if event == "PLAYER_ENTERING_WORLD" then
        self:CancelAllPredictions()
        self:CancelAllTargetProbes("WORLD", true)
        return
    elseif event == "ENCOUNTER_START" then
        -- Persist the trash pull that led into the boss instead of dropping it.
        if self.current then self:EndPull("boss-start") end
        self.encounterActive = true
        self:CancelAllPredictions()
        return
    elseif event == "ENCOUNTER_END" then
        self.encounterActive = false
        return
    elseif event == "PLAYER_REGEN_DISABLED" then
        if not self.encounterActive then self:BeginPull("combat") end
        return
    elseif event == "PLAYER_REGEN_ENABLED" then
        local endingPull = self.current
        C_Timer.After(0.25, function()
            -- Do not end a new pull that started during the debounce window.
            if O and not O.encounterActive and O.current == endingPull then
                O:EndPull("combat-end")
            end
        end)
        return
    elseif event == "NAME_PLATE_UNIT_ADDED" then
        self.metrics.nameplatesAdded = (self.metrics.nameplatesAdded or 0) + 1
        return
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        self.metrics.nameplatesRemoved = (self.metrics.nameplatesRemoved or 0) + 1
        local token = acceptedUnit(a1)
        if token then self:CancelPredictionsForUnit(token) end
        return
    end

    local kind
    if event == "UNIT_SPELLCAST_START" then kind="START"
    elseif event == "UNIT_SPELLCAST_CHANNEL_START" then kind="CHANNEL"
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then kind="SUCCEEDED"
    elseif event == "UNIT_SPELLCAST_INTERRUPTED" then kind="INTERRUPTED"
    elseif event == "UNIT_SPELLCAST_STOP" then kind="STOP"
    elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" then kind="CHANNEL_STOP"
    elseif event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_FAILED_QUIET" then kind="FAILED"
    end
    if kind then
        local castBarID
        if event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_CHANNEL_STOP" then
            castBarID = a5
        else
            castBarID = a4
        end
        self:Record(kind, a1, a3, castBarID)
    end
end

function O:Init()
    if self.frame then return end
    local f=CreateFrame("Frame")
    self.frame=f

    -- Explicit policy: no combat-log event is registered by this module.
    local events = {
        "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED",
        "ENCOUNTER_START", "ENCOUNTER_END",
        "NAME_PLATE_UNIT_ADDED", "NAME_PLATE_UNIT_REMOVED",
        "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_CHANNEL_START",
        "UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_CHANNEL_STOP",
        "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_FAILED",
        "UNIT_SPELLCAST_FAILED_QUIET", "UNIT_SPELLCAST_SUCCEEDED",
    }
    for _, ev in ipairs(events) do pcall(f.RegisterEvent, f, ev) end
    f:SetScript("OnEvent", function(_, event, ...)
        O:OnEvent(event, ...)
    end)
end

O:Init()
