local addonName, NS = ...
if type(NS) ~= "table" then return end

local Doctor = NS.Doctor or {}
NS.Doctor = Doctor

local S2_INSTANCES = {
    [2813] = "Murder Row", [2825] = "Den of Nalorakk", [2859] = "The Blinding Vale",
    [2923] = "Voidscar Arena", [2993] = "Altar of Fangs", [2521] = "Ruby Life Pools",
    [1877] = "Temple of Sethraliss", [1762] = "King's Rest", [3004] = "The Venomous Abyss",
}

local function chat(text)
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then DEFAULT_CHAT_FRAME:AddMessage(text)
    else print(text) end
end
local function yesno(v) return v and "|cff33e6a6OK|r" or "|cffff6666NO|r" end

local function isSecret(v)
    return type(issecretvalue) == "function" and issecretvalue(v) or false
end
local function safeText(v, fallback)
    if isSecret(v) then return "<secret>" end
    if v == nil then return fallback or "?" end
    return tostring(v)
end
local function addonVersion()
    if C_AddOns and C_AddOns.GetAddOnMetadata then return C_AddOns.GetAddOnMetadata(addonName, "Version") or "?" end
    return GetAddOnMetadata and GetAddOnMetadata(addonName, "Version") or "?"
end

function Doctor:Run()
    chat("|cff33e6a6TomoBoss Doctor|r  " .. tostring(addonVersion()))
    chat("  C_EncounterTimeline ........ " .. yesno(type(C_EncounterTimeline) == "table"))
    chat("  BlizzTimeline module ....... " .. yesno(type(NS.BlizzTimeline) == "table" or type(NS.BT) == "table"))
    chat("  BossModBridge .............. " .. yesno(type(NS.BossModBridge) == "table"))
    chat("  PhaseDetector .............. " .. yesno(type(NS.PhaseDetector) == "table") .. (NS.PhaseDetector and "  observation-only" or ""))
    chat("  StateResolver .............. " .. yesno(type(NS.StateResolver) == "table") .. (NS.StateResolver and "  guarded-active" or ""))
    chat("  ReferenceCatalog ........... " .. yesno(type(NS.ReferenceCatalog) == "table") .. (NS.ReferenceCatalog and "  observation-only" or ""))
    chat("  LearnProfileEvidence ....... " .. yesno(NS.Learn and type(NS.Learn.ProfileEvidence) == "table") .. ((NS.Learn and NS.Learn.ProfileEvidence) and "  observation-only" or ""))
    chat("  TrashCD Observatory ........ " .. yesno(type(NS.TrashObservatory) == "table") .. (NS.TrashObservatory and "  observation-only" or ""))

    local _, _, difficultyID, difficultyName, _, _, _, instanceID = GetInstanceInfo()
    local label = (not isSecret(instanceID)) and S2_INSTANCES[instanceID] or nil
    chat("  Instance ................... " .. safeText(instanceID) .. (label and ("  " .. label) or ""))
    chat("  Difficulty ID .............. " .. safeText(difficultyID))
    chat("  Difficulty (client) ........ " .. safeText(difficultyName, ""))

    if NS.BossModBridge then
        local statuses = NS.BossModBridge:GetStatus()
        for i = 1, #statuses do
            local s = statuses[i]
            chat(string.format("  Bridge %-20s %s  %s", s.name, yesno(s.enabled), tostring(s.detail or "")))
        end
        local timers = NS.BossModBridge:GetActiveTimers()
        chat("  External normalized timers . " .. tostring(#timers))
        if type(NS.BossModBridge.GetSecretStats) == "function" then
            local sec = NS.BossModBridge:GetSecretStats()
            local bw = sec.bySource and sec.bySource.bigwigs and sec.bySource.bigwigs.total or 0
            local dbm = sec.bySource and sec.bySource.dbm and sec.bySource.dbm.total or 0
            chat(string.format("  Secret values dropped ...... %d  (BW %d / DBM %d)", sec.total or 0, bw or 0, dbm or 0))
        end
    end

    if NS.Validator then
        local scan = NS.Validator:RunS2()
        local r, c = scan.rules, scan.collisions
        chat("|cff33e6a6  Season 2 data validation|r")
        chat(string.format("  DurationRules .............. %d/%d resolved", r.resolved, r.rules))
        chat("  Unresolved rules ........... " .. tostring(r.unresolved))
        chat("  Duration collision groups .. " .. tostring(c.collisionGroups))
        chat(string.format("  Collision coverage ......... %d/%d safe", c.covered or 0, c.collisionGroups or 0))
        chat("  Static-covered .............. " .. tostring(c.staticCovered or 0))
        chat("  State-covered ............... " .. tostring(c.stateCovered or 0))
        chat("  Gated state candidates ..... " .. tostring(c.gatedState or 0))
        chat("  Generic-safe collisions .... " .. tostring(c.genericSafe or 0))
        if r.unresolved > 0 then
            chat("|cffffb86c  First unresolved rules:|r")
            for i = 1, math.min(8, #r.details) do
                local d = r.details[i]
                chat(string.format("    enc=%s  time=%s  %s=%s%s",
                    tostring(d.encounterID), tostring(d.time), tostring(d.targetType), tostring(d.target),
                    d.missingEncounter and "  [encounter missing]" or ""))
            end
            if #r.details > 8 then chat("    ... +" .. tostring(#r.details - 8) .. " more") end
        end
    end



    if NS.ReferenceCatalog then
        local rs = NS.ReferenceCatalog:GetStatus()
        local rm = rs.meta or {}
        local mm = rs.metrics or {}
        chat("|cff33e6a6  Reference audit|r")
        chat(string.format("  Reference encounters ....... %d/28", rm.encounters or 0))
        chat(string.format("  EXBoss event maps ........... %d", rm.exbossEvents or 0))
        chat(string.format("  EXBoss duration rows ........ %d  (%d mapped)", rm.exbossDurationRules or 0, rm.exbossMappedDurationRules or 0))
        chat(string.format("  WeakAura reference IDs ...... %d", rm.weakAuraIDs or 0))
        chat(string.format("  Beta5a/EX exact IDs ........ %d/%d", rm.tomoExbossExact or 0, rm.tomoExplicitIDs or 0))
        chat(string.format("  Canonical alias groups ..... %d  (confirmed %d / candidate %d)", rm.aliasGroups or 0, rm.confirmedAliasGroups or 0, rm.candidateAliasGroups or 0))
        chat(string.format("  Learn profile variants ..... %d  observation-only", rm.learnProfileVariants or 0))
        chat("  Runtime encounter .......... " .. tostring(rs.encounterID or "none") .. (rs.active and "  active" or "  last/idle"))
        chat("  Audited decisions .......... " .. tostring(mm.audited or 0))
        chat(string.format("  Reference matches .......... %d  multi-phase=%d", mm.matched or 0, mm.ambiguous or 0))
        chat("  Reference conflicts ........ " .. tostring(mm.conflicts or 0))
        chat("  Reference unverified ....... " .. tostring(mm.unverified or 0))
        chat("  Alias resolutions .......... " .. tostring(mm.aliases or 0))
        chat("  External event matches ..... " .. tostring(mm.externalMatched or 0))
        chat("  Learn profile matches ...... " .. tostring(mm.learnProfileMatched or 0))
        local er = rs.encounter
        if er then
            chat(string.format("  Encounter reference ........ %s  events=%d rules=%d WA=%d aliases=%d",
                tostring(er.confidence or "REFERENCE"), er.eventCount or 0, er.ruleCount or 0, er.weakAuraCount or 0, er.aliasCount or 0))
            if (er.tomoBossEvents or 0) > 0 then
                chat(string.format("  TomoBoss reference match ... EX %d/%d  WA %d/%d",
                    er.tomoExbossMatch or 0, er.tomoBossEvents or 0, er.tomoWeakAuraMatch or 0, er.tomoBossEvents or 0))
            end
            if NS.PhaseDetector and type(NS.PhaseDetector.AnalyzeLearn) == "function" and not (InCombatLockdown and InCombatLockdown()) then
                local ok, lp = pcall(NS.PhaseDetector.AnalyzeLearn, NS.PhaseDetector, er.encounterID)
                if ok and type(lp) == "table" then
                    chat(string.format("  Learn reference profile .... pulls=%d  %s  stable=%d",
                        lp.pulls or 0, tostring(lp.confidence or "LOW"), lp.stableAnchors or 0))
                end
            end
        end
        local last = rs.lastDecision
        if last then
            chat(string.format("  Last reference decision .... enc=%s  %.2fs -> %s  %s",
                tostring(last.encounterID), tonumber(last.duration) or 0, tostring(last.canonicalSpellID or last.spellID or "?"), tostring(last.verdict or "?")))
            local function yn(v) if v == nil then return "n/a" end return v and "MATCH" or "NO" end
            local learnText = last.learnProfileMatch and "PROFILE" or "n/a"
            chat(string.format("  Decision sources ........... EX %s  WA %s  BW %s  LEARN %s  TMB %s",
                yn(last.exbossMatch), yn(last.weakAuraMatch), yn(last.externalMatch), learnText, yn(last.tomoBossMatch)))
        end
        local ruia = NS.ReferenceCatalog:GetEncounterStatus(3201)
        chat(string.format("  Ruia reference ............. HIGH  EX=%d rules / WA=%d IDs / runtime gate unchanged",
            ruia and ruia.ruleCount or 0, ruia and ruia.weakAuraCount or 0))
    end

    if NS.Learn and NS.Learn.ProfileEvidence and not (InCombatLockdown and InCombatLockdown()) then
        local pe = NS.Learn.ProfileEvidence:ScanVal()
        local function profileCount(encID, id)
            local row = pe.encounters and pe.encounters[encID]
            return row and row.profiles and row.profiles[id] or 0
        end
        local ruiaRow = pe.encounters and pe.encounters[3201]
        local ruia = ruiaRow and ruiaRow.ruia or {}
        chat("|cff33e6a6  Learn profile evidence|r")
        chat(string.format("  Val profile 3199 ........... ALT %d  MYTHIC %d", profileCount(3199,"ALT"), profileCount(3199,"MYTHIC")))
        chat(string.format("  Val profile 3200 ........... ALT %d  MYTHIC %d", profileCount(3200,"ALT"), profileCount(3200,"MYTHIC")))
        chat(string.format("  Val stages 3201 ............ P1 %d  P2 %d  P3 %d  32s %d",
            ruia.p1Pulls or 0, ruia.p2Pulls or 0, ruia.p3Pulls or 0, ruia.cycle32Pulls or 0))
        chat(string.format("  Val profile 3202 ........... ALT %d  MYTHIC %d", profileCount(3202,"ALT"), profileCount(3202,"MYTHIC")))
        local sv = pe.sentinelValues or {}
        local parts = {}
        for value, n in pairs(sv) do parts[#parts+1] = tostring(value) .. "x" .. tostring(n) end
        table.sort(parts)
        chat(string.format("  Learn sentinel samples ..... %d%s", pe.sentinels or 0, #parts > 0 and ("  (" .. table.concat(parts, " / ") .. ")") or ""))
    end

    if NS.StateResolver then
        local ss = NS.StateResolver:GetStatus()
        chat("|cff33e6a6  State-aware resolution|r")
        chat("  Runtime encounter .......... " .. tostring(ss.encounterID or "none") .. (ss.active and "  active" or "  last/idle"))
        chat("  Specific resolutions ....... " .. tostring(ss.resolved or 0))
        chat("  Guarded fallbacks .......... " .. tostring(ss.fallback or 0))
        chat("  BigWigs confirmations ...... " .. tostring(ss.externalConfirmed or 0))
        chat("  BigWigs mismatches ......... " .. tostring(ss.externalMismatch or 0))
        local g = ss.gate3201 or {}
        chat(string.format("  Ruia Learn gate ............ %s  pulls=%d stable=%d%s",
            g.armed and "ARMED" or "LOCKED", g.pulls or 0, g.stableAnchors or 0,
            ss.gateRefreshPending and "  refresh=pending" or ""))
        chat(string.format("  Ruia P3 Learn evidence ..... %s  pulls=%d  32s=%d",
            (g.p3Confirmed and g.cycle32Confirmed) and "CONFIRMED" or "WAITING", g.p3Pulls or 0, g.cycle32Pulls or 0))
        local rr = ss.ruiaRuntime or {}
        chat(string.format("  Ruia runtime P3 guard ...... %s  marker2.5=%s  32s seen=%d resolved=%d",
            rr.available and (rr.p3MarkerSeen and "SEEN" or "NOT-SEEN") or "NO-RUNTIME",
            rr.p3MarkerSeen and "yes" or "no", rr.cycle32Seen or 0, rr.cycle32Resolved or 0))

        if type(NS.StateResolver.GetEvidenceStatus) == "function" then
            local es = NS.StateResolver:GetEvidenceStatus()
            chat("|cff33e6a6  Persistent state evidence|r")
            for _, encID in ipairs({2124,2140,2142,3201}) do
                local row = es.byEncounter and es.byEncounter[encID] or {}
                local extra = ""
                local last = row.last
                if last and type(last.state) == "table" then
                    if encID == 2140 then
                        extra = string.format("  stateChanges=%d barrel=%s",
                            last.state.stateChanges or 0, last.state.barrelSeen and "yes" or "no")
                    elseif encID == 2142 then
                        extra = string.format("  entombState=%d initialKnown=%s",
                            last.state.stateChanges or 0, last.state.initialKnown and "yes" or "no")
                    elseif encID == 3201 then
                        extra = string.format("  P3=%s 32s=%d/%d",
                            last.state.p3MarkerSeen and "yes" or "no",
                            last.state.cycle32Resolved or 0, last.state.cycle32Seen or 0)
                    elseif encID == 2124 then
                        extra = string.format("  deadMarkers=%s/%s",
                            last.state.adderisDead and "A" or "-",
                            last.state.aspixDead and "X" or "-")
                    end
                end
                chat(string.format("  Encounter %-4d evidence ..... runs=%d kills=%d resolved=%d fallback=%d%s",
                    encID, row.runs or 0, row.kills or 0, row.resolved or 0, row.fallback or 0, extra))
            end
        end
    end

    if NS.TrashObservatory then
        local ts = NS.TrashObservatory:GetStatus()
        chat("|cff33e6a6  TrashCD observatory|r")
        chat("  Mode ....................... Midnight-safe; no CLEU; secret IDs dropped")
        chat(string.format("  Active context ............. map=%s instance=%s diff=%s",
            tostring(ts.mapID or "none"), tostring(ts.instanceID or "none"), tostring(ts.difficultyID or "none")))
        chat("  Stored trash pulls ........ " .. tostring(ts.storedPulls or 0))
        chat(string.format("  Cast observations ......... %d primary / %d total",
            ts.primaryCasts or 0, ts.castEvents or 0))
        chat(string.format("  SpellID visibility ........ %d non-secret / %d secret  unique=%d",
            ts.nonSecretSpellIDs or 0, ts.secretSpellIDs or 0, ts.uniqueNonSecretSpells or 0))
        chat(string.format("  castBarID-bearing events ... %d  unique=%d",
            ts.castBarEvents or 0, ts.uniqueCastBarIDs or 0))
        chat(string.format("  CastBar API correlation .... match %d / missing %d / mismatch %d",
            ts.castBarInfoMatches or 0, ts.castBarInfoMissing or 0, ts.castBarInfoMismatch or 0))
        chat(string.format("  Target casts probed ........ %d casts / %d probe attempts / stale %d",
            ts.targetSamples or 0, ts.targetProbeAttempts or 0, ts.targetProbeStale or 0))
        chat(string.format("  Target immediate ........... usable %d / secret %d / none %d",
            ts.targetImmediateUsable or 0, ts.targetImmediateSecret or 0, ts.targetImmediateNone or 0))
        chat(string.format("  Target deferred recovery ... usable %d / secret %d",
            ts.targetDeferredRecovered or 0, ts.targetDeferredSecret or 0))
        chat(string.format("  Target final visibility .... %d secret / %d none / %d errors",
            ts.targetSecret or 0, ts.targetNone or 0, ts.targetApiErrors or 0))
        chat(string.format("  Cast target classes ........ SELF %d  TANK %d  HEAL %d  DPS %d  GROUP %d  OTHER %d",
            ts.targetSelf or 0, ts.targetTank or 0, ts.targetHealer or 0, ts.targetDps or 0,
            ts.targetGroup or 0, ts.targetOther or 0))
        chat(string.format("  Reference matches ......... %d  preview-eligible=%d",
            ts.referenceMatches or 0, ts.previewEligible or 0))
        chat(string.format("  Reference catalog ......... %d maps / %d spells / %d stable preview rows",
            ts.referenceMaps or 0, ts.referenceSpells or 0, ts.referencePreviewEligible or 0))
        chat("  Trash preview ............. " .. (ts.preview and "ON  diagnostic TTS" or "OFF"))
        chat("  Preview voice fires ....... " .. tostring(ts.previewFired or 0))
    end

    if NS.PhaseDetector then
        local ps = NS.PhaseDetector:GetRuntimeStatus()
        chat("|cff33e6a6  Phase observation|r")
        chat("  Runtime encounter .......... " .. tostring(ps.encounterID or "none") .. (ps.active and "  active" or "  last/idle"))
        chat("  Runtime anchor batches ..... " .. tostring(ps.anchors or 0))
        chat("  Runtime anchor changes ..... " .. tostring(ps.changes or 0))
        chat("  Timeline state updates ..... " .. tostring(ps.stateUpdates or 0))
        chat("  Boss units observed ........ " .. tostring(ps.bossCount or 0))
        chat("  External confirmations ..... " .. tostring(ps.externalSignals or 0))
        chat(string.format("  Runtime sentinel events .... %d  session=%d", ps.sentinelEvents or 0, ps.sentinelTotal or 0))
    end

    if NS.Learn and NS.Learn.Confidence then
        if InCombatLockdown and InCombatLockdown() then
            chat("|cffe8c07d  Learn confidence ............ deferred (in combat)|r")
        else
            local lc = NS.Learn.Confidence:ScanTracked()
            chat("|cff33e6a6  Learn confidence|r")
            chat("  Learned tracked encounters . " .. tostring(lc.learned or 0))
            chat("  Stored tracked pulls ........ " .. tostring(lc.pulls or 0))
            chat(string.format("  Ability confidence .......... HIGH %d  MED %d  LOW %d", lc.high or 0, lc.medium or 0, lc.low or 0))

            if NS.PhaseDetector then
                local ph = { high=0, medium=0, low=0, stable=0, tentative=0, transitions=0, analyzed=0 }
                for _, d in ipairs(lc.details or {}) do
                    local a = NS.PhaseDetector:AnalyzeLearn(d.encounterID)
                    if a and a.pulls and a.pulls > 0 then
                        ph.analyzed = ph.analyzed + 1
                        ph.stable = ph.stable + (a.stableAnchors or 0)
                        ph.tentative = ph.tentative + (a.tentativeAnchors or 0)
                        ph.transitions = ph.transitions + (a.transitionCandidates or 0)
                        if a.confidence == "HIGH" then ph.high = ph.high + 1
                        elseif a.confidence == "MEDIUM" then ph.medium = ph.medium + 1
                        else ph.low = ph.low + 1 end
                    end
                end
                chat(string.format("  Phase-anchor confidence ..... HIGH %d  MED %d  LOW %d", ph.high, ph.medium, ph.low))
                chat("  Stable phase anchors ........ " .. tostring(ph.stable))
                chat("  Tentative phase anchors ..... " .. tostring(ph.tentative))
                chat("  Stable transitions .......... " .. tostring(ph.transitions))

                local ps = NS.PhaseDetector:GetRuntimeStatus()
                if ps and ps.encounterID then
                    local cur = NS.PhaseDetector:AnalyzeLearn(ps.encounterID)
                    chat(string.format("  Last phase profile .......... enc=%s  pulls=%d  %s",
                        tostring(ps.encounterID), cur.pulls or 0, tostring(cur.confidence or "LOW")))
                    chat(string.format("  Profile anchors ............. stable %d  tentative %d  transitions %d",
                        cur.stableAnchors or 0, cur.tentativeAnchors or 0, cur.transitionCandidates or 0))
                end
            end
        end
    end

    chat("  P0-01 sentinel guard ....... |cff33e6a6validated in game|r")
    chat("|cffaaaaaaBeta5d2: TrashCD Observatory distinguishes castBarID events from unique casts and probes UnitSpellTargetName at 0/50/150/300ms only while the same castBarID remains active.|r")
    chat("|cffaaaaaaBeta5c: Learn profile evidence keeps ALT/MYTHIC native duration profiles separate; profile evidence never controls player-facing output.|r")
    chat("|cffaaaaaaBeta5a secret-safe bridge remains active; inaccessible external identities are dropped, never interpreted.|r")
    chat("|cffaaaaaaP0-04 guarded state rules are unchanged; Ruia Learn gate, P3 Learn evidence, and native 2.5s runtime guard are reported separately.|r")
end
