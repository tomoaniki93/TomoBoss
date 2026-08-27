---@diagnostic disable: undefined-global
-- TomoBoss 2.8.0-beta5d — guarded state-aware timeline resolver + persistent runtime evidence.
--
-- Purpose:
--   Resolve only collisions whose identity can be proven from the current
--   encounter's native Timeline state. Unknown / incomplete state ALWAYS
--   falls back to P0-01 generic-safe behaviour.
--
-- PhaseDetector remains observation-only. This resolver does not use external
-- boss mods as an authority; BigWigs/DBM are used only to audit decisions.

local addonName, NS = ...
if type(NS) ~= "table" then return end

local SR = NS.StateResolver or {}
NS.StateResolver = SR

local TOL = 0.35
local AUDIT_TOL = 1.50

SR.mode = "guarded-active"
SR.current = SR.current or nil
SR.last = SR.last or nil
SR.lastByEncounter = SR.lastByEncounter or {}
SR.metrics = SR.metrics or {
    resolved = 0,
    fallback = 0,
    externalConfirmed = 0,
    externalMismatch = 0,
}
SR.gates = SR.gates or { [3201] = false }

local function safeNumber(v)
    if NS.SafeNumber then return NS:SafeNumber(v) end
    return type(v) == "number" and v or nil
end

local function near(v, target, tol)
    return type(v) == "number" and math.abs(v - target) <= (tol or TOL)
end

local function resolveSpell(encID, spellID)
    if not spellID or not NS.Engine or type(NS.Engine.GetEncounter) ~= "function" then return nil end
    local def = NS.Engine:GetEncounter(encID)
    if not def then return nil end
    spellID = tonumber(spellID) or spellID
    for _, ev in ipairs(def.events or {}) do
        if (tonumber(ev.spellID) or ev.spellID) == spellID then return ev end
    end
    return nil
end

local function readInfo(x)
    if type(x) == "table" then return x end
    local id = safeNumber(x)
    if not id or not C_EncounterTimeline or type(C_EncounterTimeline.GetEventInfo) ~= "function" then return nil end
    local ok, info = pcall(C_EncounterTimeline.GetEventInfo, id)
    return ok and type(info) == "table" and info or nil
end

local function countPulls(encID)
    local Store = NS.Learn and NS.Learn.Store
    if not Store or type(Store.CountPulls) ~= "function" then return 0 end
    local best = 0
    local ok, n = pcall(Store.CountPulls, Store, tostring(encID))
    if ok then best = tonumber(n) or 0 end
    ok, n = pcall(Store.CountPulls, Store, tonumber(encID) or encID)
    if ok then best = math.max(best, tonumber(n) or 0) end
    return best
end


local EVIDENCE_ENCOUNTERS = { [2124]=true, [2140]=true, [2142]=true, [3201]=true }

local function evidenceRoot(create)
    local db = rawget(_G, "TomoBossRecorderDB")
    if type(db) ~= "table" then
        if not create then return nil end
        db = {}
        _G.TomoBossRecorderDB = db
    end
    if type(db.stateResolverEvidence) ~= "table" then
        if not create then return nil end
        db.stateResolverEvidence = { version=1, byEncounter={} }
    end
    local root = db.stateResolverEvidence
    if type(root.byEncounter) ~= "table" then root.byEncounter = {} end
    return root
end

local function safeDate()
    if type(date) == "function" then
        local ok, s = pcall(date, "%Y-%m-%d %H:%M:%S")
        if ok and type(s) == "string" then return s end
    end
    return "?"
end

local function tableCount(t)
    local n=0
    for _ in pairs(t or {}) do n=n+1 end
    return n
end

local function persistEvidence(st)
    if type(st) ~= "table" or not EVIDENCE_ENCOUNTERS[st.encounterID] then return end
    local root = evidenceRoot(true)
    local key = tostring(st.encounterID)
    local list = root.byEncounter[key]
    if type(list) ~= "table" then list={}; root.byEncounter[key]=list end

    local rec = {
        date=safeDate(), encounterID=st.encounterID, outcome=st.outcome,
        resolved=st.resolved or 0, fallback=st.fallback or 0,
        duration=(st.endedAt and st.startedAt) and math.max(0, st.endedAt-st.startedAt) or 0,
        decisions={}, fallbacks={},
    }
    for _, d in ipairs(st.decisions or {}) do
        rec.decisions[#rec.decisions+1] = {
            t=d.t, duration=d.duration, spellID=d.spellID, label=d.label,
        }
    end
    for _, d in ipairs(st.fallbacks or {}) do
        rec.fallbacks[#rec.fallbacks+1] = {
            t=d.t, duration=d.duration, label=d.label,
        }
    end

    if st.encounterID == 2124 then
        rec.state = {
            adderisDead=st.aa and st.aa.adderisDead or false,
            aspixDead=st.aa and st.aa.aspixDead or false,
            count19=st.aa and st.aa.count19 or 0,
            count45=st.aa and st.aa.count45 or 0,
        }
    elseif st.encounterID == 2140 then
        rec.state = {
            barrelSeen=st.council and st.council.barrelSeen or false,
            akaaliAlive=st.council and st.council.akaaliAlive or false,
            barrelEvents=st.council and tableCount(st.council.barrelEventIds) or 0,
            stateChanges=st.council and st.council.stateChanges or 0,
        }
    elseif st.encounterID == 2142 then
        rec.state = {
            initialKnown=st.mchimba and st.mchimba.initialKnown or false,
            initial=st.mchimba and st.mchimba.initial or false,
            entombEvents=st.mchimba and tableCount(st.mchimba.entombEventIds) or 0,
            stateChanges=st.mchimba and st.mchimba.stateChanges or 0,
        }
    elseif st.encounterID == 3201 then
        rec.state = {
            stage=st.ruia and st.ruia.stage or 0,
            p3MarkerSeen=st.ruia and st.ruia.p3MarkerSeen or false,
            cycle32Seen=st.ruia and st.ruia.cycle32Seen or 0,
            cycle32Resolved=st.ruia and st.ruia.cycle32Resolved or 0,
        }
    end

    list[#list+1]=rec
    while #list > 12 do table.remove(list,1) end
    root.last=rec
end

-- Coverage metadata consumed by Doctor/Validator. "active" means the resolver
-- can identify the collision when its runtime guard is satisfied. "gated"
-- means the code exists but stays generic until Learn has enough evidence.
SR.COVERAGE = {
    [2124] = {
        [19] = { status="active", spells={1289059,1288049,1311805,1311804}, label="boss-death state + pair order" },
        [45] = { status="active", spells={1289059,1288049,1311805,1311804}, label="four-event native cycle" },
        -- 5 s intentionally remains generic-safe in beta5. A same-timestamp
        -- duplicate can straddle the death/resync marker and would otherwise
        -- risk upgrading one of two duplicate events incorrectly.
    },
    [2140] = {
        [20] = { status="active", spells={267494,267060}, label="Aka'ali timeline cancellation" },
    },
    [2142] = {
        [30] = { status="active", spells={1311956,1312146}, label="Entomb initial/follow-up state" },
    },
    [3201] = {
        [32] = { status="gated", minPulls=2, spells={1239824,1241058,1240098,1240210}, label="stage 3 four-event cycle" },
    },
}

function SR:GetCoverage(encID, duration)
    encID = tonumber(encID) or encID
    local byDur = self.COVERAGE[encID]
    if not byDur then return nil end
    for d, meta in pairs(byDur) do
        if near(duration, d, 0.05) then
            local out = {}
            for k, v in pairs(meta) do out[k] = v end
            if out.status == "gated" then
                out.armed = self.gates[encID] and true or false
            else
                out.armed = true
            end
            return out
        end
    end
    return nil
end

function SR:RefreshGates()
    -- Lightwarden Ruia stays generic until we have both repeated Learn data and
    -- at least one stable anchor. No inference is run in combat.
    local pulls = countPulls(3201)
    local stable = 0
    if pulls >= 2 and NS.PhaseDetector and type(NS.PhaseDetector.AnalyzeLearn) == "function"
        and not (InCombatLockdown and InCombatLockdown()) then
        local ok, a = pcall(NS.PhaseDetector.AnalyzeLearn, NS.PhaseDetector, 3201)
        if ok and type(a) == "table" then stable = tonumber(a.stableAnchors) or 0 end
    end
    self.gates[3201] = pulls >= 2 and stable >= 1
    local p3Pulls, cycle32Pulls = 0, 0
    if NS.Learn and NS.Learn.ProfileEvidence and type(NS.Learn.ProfileEvidence.GetRuiaEvidence) == "function"
        and not (InCombatLockdown and InCombatLockdown()) then
        local ok, ev = pcall(NS.Learn.ProfileEvidence.GetRuiaEvidence, NS.Learn.ProfileEvidence)
        if ok and type(ev) == "table" then
            p3Pulls = tonumber(ev.p3Pulls) or 0
            cycle32Pulls = tonumber(ev.cycle32Pulls) or 0
        end
    end
    self.gateInfo = self.gateInfo or {}
    self.gateInfo[3201] = {
        pulls=pulls, stableAnchors=stable, armed=self.gates[3201],
        p3Pulls=p3Pulls, cycle32Pulls=cycle32Pulls,
        p3Confirmed=p3Pulls > 0, cycle32Confirmed=cycle32Pulls > 0,
    }
end

local function newState(encID, name)
    return {
        encounterID = tonumber(encID) or encID,
        name = type(name) == "string" and name or nil,
        startedAt = GetTime(),
        resolved = 0,
        fallback = 0,
        externalConfirmed = 0,
        externalMismatch = 0,
        decisions = {},
        fallbacks = {},
        -- Adderis / Aspix
        aa = { adderisDead=false, aspixDead=false, count19=1, count45=1 },
        -- Council
        council = { akaaliAlive=true, barrelSeen=false, barrelEventIds={}, stateChanges=0 },
        -- Mchimba
        mchimba = { initial=true, initialKnown=false, entombEventIds={}, stateChanges=0 },
        -- Lightwarden Ruia (gated)
        ruia = { stage=1, sharedCount=1, p3MarkerSeen=false, cycle32Seen=0, cycle32Resolved=0 },
    }
end

function SR:Begin(encID, name)
    self.current = newState(encID, name)
end

function SR:End(outcome)
    if self.current then
        self.current.outcome = outcome
        self.current.endedAt = GetTime()
        self.last = self.current
        self.lastByEncounter[self.current.encounterID] = self.current
        persistEvidence(self.current)
    end
    self.current = nil
    C_Timer.After(0.5, function()
        if SR and SR.RefreshGates then SR:RefreshGates() end
    end)
end

function SR:_AuditExternal(encID, duration, spellID, candidates)
    if not NS.BossModBridge or type(NS.BossModBridge.GetActiveTimers) ~= "function" then return end
    local state = self.current
    local stateToken = state and state.startedAt or nil
    C_Timer.After(0.15, function()
        local timers = NS.BossModBridge:GetActiveTimers()
        local wanted = {}
        for _, sid in ipairs(candidates or {}) do wanted[tonumber(sid) or sid] = true end
        local picked, other = false, false
        local now = GetTime()
        for _, rec in ipairs(timers or {}) do
            local sid = tonumber(rec.spellID) or rec.spellID
            if sid and wanted[sid] then
                local rem = type(rec.expirationTime) == "number" and (rec.expirationTime - now) or nil
                local close = (type(rec.duration) == "number" and math.abs(rec.duration - duration) <= AUDIT_TOL)
                    or (type(rem) == "number" and math.abs(rem - duration) <= AUDIT_TOL)
                if close then
                    if sid == spellID then picked = true else other = true end
                end
            end
        end
        if picked then
            SR.metrics.externalConfirmed = (SR.metrics.externalConfirmed or 0) + 1
            if state and state.startedAt == stateToken then state.externalConfirmed = (state.externalConfirmed or 0) + 1 end
        elseif other then
            SR.metrics.externalMismatch = (SR.metrics.externalMismatch or 0) + 1
            if state and state.startedAt == stateToken then state.externalMismatch = (state.externalMismatch or 0) + 1 end
        end
    end)
end

function SR:_Return(encID, duration, spellID, label, candidates)
    local ev = resolveSpell(encID, spellID)
    if not ev then
        self.metrics.fallback = (self.metrics.fallback or 0) + 1
        if self.current then self.current.fallback = (self.current.fallback or 0) + 1 end
        return nil
    end
    self.metrics.resolved = (self.metrics.resolved or 0) + 1
    if self.current then
        self.current.resolved = (self.current.resolved or 0) + 1
        self.current.decisions[#self.current.decisions+1] = {
            t=GetTime()-(self.current.startedAt or GetTime()),
            duration=duration, spellID=tonumber(spellID) or spellID, label=label,
        }
    end
    if NS.ReferenceCatalog and type(NS.ReferenceCatalog.ObserveDecision) == "function" then
        pcall(NS.ReferenceCatalog.ObserveDecision, NS.ReferenceCatalog, encID, duration, tonumber(spellID) or spellID, label, candidates)
    end
    self:_AuditExternal(encID, duration, tonumber(spellID) or spellID, candidates)
    return ev, "état sûr: " .. tostring(label)
end

function SR:_Fallback(encID, duration, label)
    self.metrics.fallback = (self.metrics.fallback or 0) + 1
    if self.current then
        self.current.fallback = (self.current.fallback or 0) + 1
        self.current.fallbacks[#self.current.fallbacks+1] = {
            t=GetTime()-(self.current.startedAt or GetTime()),
            duration=duration, label=label,
        }
    end
    if NS.ReferenceCatalog and type(NS.ReferenceCatalog.ObserveFallback) == "function" then
        pcall(NS.ReferenceCatalog.ObserveFallback, NS.ReferenceCatalog, encID, duration, label)
    end
    return nil
end

function SR:Resolve(encID, duration)
    encID = tonumber(encID) or encID
    duration = safeNumber(duration)
    if not duration then return nil end
    local st = self.current
    -- Never reconstruct state after a reload/mid-fight attach. If we did not
    -- see ENCOUNTER_START for this exact encounter, generic-safe wins.
    if not st or st.encounterID ~= encID then return nil end

    if encID == 2124 then
        local a = st.aa
        -- State markers from the native 12.1 Timeline.
        if near(duration, 12) then a.adderisDead = true end
        if near(duration, 15) or near(duration, 22) then a.aspixDead = true end

        if near(duration, 45) then
            local spells = {1289059, 1288049, 1311805, 1311804}
            local idx = ((a.count45 - 1) % 4) + 1
            a.count45 = a.count45 + 1
            return self:_Return(encID, duration, spells[idx], "2124/45 cycle", spells)
        elseif near(duration, 19) then
            local spells
            if a.adderisDead and not a.aspixDead then
                spells = {1289059, 1311805} -- Gale Force / Tempest Winds
            elseif a.aspixDead and not a.adderisDead then
                spells = {1311804, 1288049} -- Overload / Thunder and Lightning
            else
                return self:_Fallback(encID, duration, "2124/19 unresolved boss state")
            end
            local idx = ((a.count19 - 1) % 2) + 1
            a.count19 = a.count19 + 1
            return self:_Return(encID, duration, spells[idx], "2124/19 boss-state", spells)
        end
        return nil
    end

    if encID == 2140 then
        local c = st.council
        if near(duration, 5) then c.barrelSeen = true end -- unique Barrel Through opener
        if near(duration, 20) then
            if c.akaaliAlive and c.barrelSeen then
                return self:_Return(encID, duration, 267494, "2140 Aka'ali alive", {267494,267060})
            elseif not c.akaaliAlive then
                return self:_Return(encID, duration, 267060, "2140 Aka'ali dead", {267494,267060})
            end
            return self:_Fallback(encID, duration, "2140/20 unresolved council state")
        end
        return nil
    end

    if encID == 2142 then
        local m = st.mchimba
        -- 20 s exists only in the initial group (pull / post-Entomb) and is a
        -- robust marker before the colliding 30 s entry in native captures.
        if near(duration, 20) then
            m.initial = true
            m.initialKnown = true
        end
        if near(duration, 30) then
            if not m.initialKnown then return self:_Fallback(encID, duration, "2142/30 initial state unknown") end
            if m.initial then
                return self:_Return(encID, duration, 1312146, "2142 initial Awakening Slam", {1311956,1312146})
            else
                return self:_Return(encID, duration, 1311956, "2142 follow-up Burn Corruption", {1311956,1312146})
            end
        end
        return nil
    end

    if encID == 3201 then
        local r = st.ruia
        if near(duration, 3) and r.stage == 1 then r.stage=2; r.sharedCount=1 end
        if near(duration, 2.5) then r.stage=3; r.sharedCount=1; r.p3MarkerSeen=true end
        if duration >= 19.9 and duration <= 21 then r.sharedCount = r.sharedCount + 1 end
        if near(duration, 32) then
            r.cycle32Seen = (r.cycle32Seen or 0) + 1
            local gate = self.gates[3201]
            if not gate or r.stage ~= 3 then return self:_Fallback(encID, duration, gate and "3201/32 not stage 3" or "3201/32 gate locked") end
            local spells = {1239824,1241058,1240098,1240210}
            local idx = ((r.sharedCount - 1) % 4) + 1
            r.sharedCount = r.sharedCount + 1
            r.cycle32Resolved = (r.cycle32Resolved or 0) + 1
            return self:_Return(encID, duration, spells[idx], "3201 stage 3 cycle", spells)
        end
        return nil
    end

    return nil
end

function SR:OnTimelineAdded(x)
    local st = self.current
    if not st then return end
    local info = readInfo(x)
    if not info then return end
    if info.source ~= nil and not NS:IsSecret(info.source) and safeNumber(info.source) ~= 0 then return end
    local id = safeNumber(info.id) or (type(x) == "number" and safeNumber(x))
    local d = safeNumber(info.duration)
    if not id or not d then return end

    if st.encounterID == 2140 then
        local c = st.council
        if near(d, 5) or (near(d,20) and c.akaaliAlive and c.barrelSeen) then
            c.barrelEventIds[id] = true
        end
    elseif st.encounterID == 2142 and near(d, 60) then
        local m = st.mchimba
        m.entombEventIds[id] = true
        -- Matches the native cycle: follow-up timers begin after the initial
        -- group has been posted. The next Entomb completion re-arms initial.
        C_Timer.After(1.0, function()
            if SR.current == st then
                m.initial = false
                m.initialKnown = true
            end
        end)
    end
end

function SR:OnTimelineStateChanged(x)
    local st = self.current
    if not st then return end
    local info = readInfo(x)
    local id = info and safeNumber(info.id) or safeNumber(x)
    if not id then return end
    local state
    if C_EncounterTimeline and type(C_EncounterTimeline.GetEventState) == "function" then
        local ok, v = pcall(C_EncounterTimeline.GetEventState, id)
        if ok then state = safeNumber(v) end
    end

    if st.encounterID == 2140 and st.council.barrelEventIds[id] and state == 3 then
        st.council.akaaliAlive = false
        st.council.stateChanges = (st.council.stateChanges or 0) + 1
    elseif st.encounterID == 2142 and st.mchimba.entombEventIds[id] and state == 2 then
        st.mchimba.initial = true
        st.mchimba.initialKnown = true
        st.mchimba.stateChanges = (st.mchimba.stateChanges or 0) + 1
    end
end

function SR:GetStatus()
    local st = self.current or self.last
    local gated = self.gateInfo and self.gateInfo[3201] or {pulls=countPulls(3201), stableAnchors=0, armed=false, p3Pulls=0, cycle32Pulls=0}
    local ruiaState
    if self.current and self.current.encounterID == 3201 then ruiaState = self.current
    else ruiaState = self.lastByEncounter and self.lastByEncounter[3201] or nil end
    local rr = ruiaState and ruiaState.ruia or nil
    return {
        mode = self.mode,
        active = self.current ~= nil,
        encounterID = st and st.encounterID or nil,
        resolved = st and st.resolved or 0,
        fallback = st and st.fallback or 0,
        externalConfirmed = st and st.externalConfirmed or 0,
        externalMismatch = st and st.externalMismatch or 0,
        totalResolved = self.metrics.resolved or 0,
        totalFallback = self.metrics.fallback or 0,
        gate3201 = gated,
        ruiaRuntime = {
            available = rr ~= nil,
            active = self.current == ruiaState and ruiaState ~= nil,
            stage = rr and rr.stage or nil,
            p3MarkerSeen = rr and rr.p3MarkerSeen or false,
            cycle32Seen = rr and rr.cycle32Seen or 0,
            cycle32Resolved = rr and rr.cycle32Resolved or 0,
            outcome = ruiaState and ruiaState.outcome or nil,
        },
    }
end


function SR:GetEvidenceStatus()
    local out = { byEncounter={} }
    local root = evidenceRoot(false)
    for _, encID in ipairs({2124,2140,2142,3201}) do
        local list = root and root.byEncounter and root.byEncounter[tostring(encID)] or {}
        local row = { runs=0, resolved=0, fallback=0, kills=0, last=nil }
        if type(list) == "table" then
            row.runs = #list
            for _, rec in ipairs(list) do
                row.resolved = row.resolved + (tonumber(rec.resolved) or 0)
                row.fallback = row.fallback + (tonumber(rec.fallback) or 0)
                if rec.outcome == "kill" then row.kills = row.kills + 1 end
                row.last = rec
            end
        end
        out.byEncounter[encID]=row
    end
    out.last = root and root.last or nil
    return out
end


function SR:BuildEvidenceExport()
    local root = evidenceRoot(false)
    local out = {
        "TomoBoss StateResolver Evidence — beta5d",
        "Persistent runtime evidence only; ReferenceCatalog/BigWigs/WeakAura never control these decisions.",
        "",
    }
    for _, encID in ipairs({2124,2140,2142,3201}) do
        local list = root and root.byEncounter and root.byEncounter[tostring(encID)] or {}
        out[#out+1] = string.format("=== encounter %d  stored runs=%d ===", encID, type(list) == "table" and #list or 0)
        if type(list) == "table" then
            local first = math.max(1, #list - 2)
            for i=first,#list do
                local rec=list[i]
                out[#out+1]=string.format("-- run %d/%d date=%s outcome=%s duration=%.1fs resolved=%d fallback=%d",
                    i,#list,tostring(rec.date or "?"),tostring(rec.outcome or "?"),
                    tonumber(rec.duration) or 0,tonumber(rec.resolved) or 0,tonumber(rec.fallback) or 0)
                local st=rec.state or {}
                if encID == 2124 then
                    out[#out+1]=string.format("state adderisDead=%s aspixDead=%s count45=%d count19=%d",
                        st.adderisDead and "yes" or "no", st.aspixDead and "yes" or "no",
                        tonumber(st.count45) or 0, tonumber(st.count19) or 0)
                elseif encID == 2140 then
                    out[#out+1]=string.format("state barrelSeen=%s akaaliAlive=%s barrelEvents=%d stateChanges=%d",
                        st.barrelSeen and "yes" or "no", st.akaaliAlive and "yes" or "no",
                        tonumber(st.barrelEvents) or 0, tonumber(st.stateChanges) or 0)
                elseif encID == 2142 then
                    out[#out+1]=string.format("state initialKnown=%s initial=%s entombEvents=%d stateChanges=%d",
                        st.initialKnown and "yes" or "no", st.initial and "yes" or "no",
                        tonumber(st.entombEvents) or 0, tonumber(st.stateChanges) or 0)
                elseif encID == 3201 then
                    out[#out+1]=string.format("state stage=%d marker2.5=%s 32s seen=%d resolved=%d",
                        tonumber(st.stage) or 0, st.p3MarkerSeen and "yes" or "no",
                        tonumber(st.cycle32Seen) or 0, tonumber(st.cycle32Resolved) or 0)
                end
                for _,d in ipairs(rec.decisions or {}) do
                    out[#out+1]=string.format("  DECISION t=%.2f dur=%.2f -> %s  %s",
                        tonumber(d.t) or 0, tonumber(d.duration) or 0,
                        tostring(d.spellID or "?"), tostring(d.label or ""))
                end
                for _,d in ipairs(rec.fallbacks or {}) do
                    out[#out+1]=string.format("  FALLBACK t=%.2f dur=%.2f  %s",
                        tonumber(d.t) or 0, tonumber(d.duration) or 0, tostring(d.label or ""))
                end
            end
        end
        out[#out+1]=""
    end
    return table.concat(out, "\n")
end

function SR:ShowEvidenceDump()
    local text=self:BuildEvidenceExport()
    if not self.evidenceDumpFrame then
        local f=CreateFrame("Frame","TomoBossStateEvidenceDumpFrame",UIParent,"BackdropTemplate")
        f:SetSize(760,560)
        f:SetPoint("CENTER")
        f:SetFrameStrata("DIALOG")
        f:SetMovable(true)
        f:EnableMouse(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart",f.StartMoving)
        f:SetScript("OnDragStop",f.StopMovingOrSizing)
        f:SetBackdrop({bgFile="Interface/Buttons/WHITE8X8",edgeFile="Interface/Buttons/WHITE8X8",edgeSize=1})
        f:SetBackdropColor(0.03,0.04,0.05,0.96)
        f:SetBackdropBorderColor(0.2,0.9,0.65,1)

        local title=f:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
        title:SetPoint("TOPLEFT",14,-12)
        title:SetText("TomoBoss — StateResolver Evidence")

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
        eb:SetScript("OnEscapePressed",function() f:Hide() end)
        sf:SetScrollChild(eb)

        f.editBox=eb
        self.evidenceDumpFrame=f
    end
    local eb=self.evidenceDumpFrame.editBox
    eb:SetText(text)
    local lines=1
    for _ in text:gmatch("\n") do lines=lines+1 end
    eb:SetHeight(math.max(480,lines*15))
    self.evidenceDumpFrame:Show()
    eb:SetFocus()
    eb:HighlightText()
end

function SR:Init()
    if self.frame then return end
    self:RefreshGates()
    local f = CreateFrame("Frame")
    self.frame = f
    f:RegisterEvent("PLAYER_LOGIN")
    f:RegisterEvent("ENCOUNTER_START")
    f:RegisterEvent("ENCOUNTER_END")
    f:RegisterEvent("ENCOUNTER_TIMELINE_EVENT_ADDED")
    f:RegisterEvent("ENCOUNTER_TIMELINE_EVENT_STATE_CHANGED")
    f:SetScript("OnEvent", function(_, event, a1, a2, a3, a4, a5)
        if event == "PLAYER_LOGIN" then
            SR:RefreshGates()
        elseif event == "ENCOUNTER_START" then
            SR:Begin(a1, a2)
        elseif event == "ENCOUNTER_END" then
            SR:End(safeNumber(a5) == 1 and "kill" or "wipe")
        elseif event == "ENCOUNTER_TIMELINE_EVENT_ADDED" then
            SR:OnTimelineAdded(a1)
        elseif event == "ENCOUNTER_TIMELINE_EVENT_STATE_CHANGED" then
            SR:OnTimelineStateChanged(a1)
        end
    end)
end

SR:Init()
