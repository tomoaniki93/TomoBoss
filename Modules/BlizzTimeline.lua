---@diagnostic disable: undefined-global
-- TomoBoss — Moteur Timeline (Midnight). Piloté par C_EncounterTimeline : le
-- minutage vient du serveur (exact), et chaque événement est IDENTIFIÉ par sa
-- DURÉE comparée à mes données (firstSeenSec / cdSeriesSec, tolérance 0,75 s) —
-- même approche que BossReminder, car l'API ne fournit pas le spellID et masque
-- souvent spellName. Une fois identifié, on utilise MON spellID (nom/icône
-- lisibles) et MA voix française. Non identifié -> repli sur spellName / « Capacité »,
-- et MODE GÉNÉRIQUE : voix par sévérité (0=tank, 2=danger) pour couvrir le contenu
-- sans données (donjons Saison 2, raids...). Sévérité lisible ? Jamais garanti
-- (secretvalue) -> tout passe par NS:SafeNumber, repli sévérité 1 (pas de fausse alerte).

local NS = select(2, ...)
local BT = {}
NS.BlizzTimeline = BT

BT.active = {}     -- timelineID -> { endTime, name, severity, voice, evRef, role, announced }
BT._index = {}     -- encID -> liste {ev, durs} (ou false)
BT._activeEnc = nil
BT._candidates = nil
BT._byEventID = {}   -- encID -> { [eventID] = ev }
BT._syncUsed  = {}   -- encID -> { [index de règle] = true }
BT._seqCounters = {} -- sequenceGroup -> compteur round-robin (repli seulement)
BT._phases    = {}   -- "encID|groupe" -> { [eventID] = offset dans le cycle }
BT._drift     = {}   -- groupe -> correction de phase accumulée (s)
BT._pullTime = nil   -- 1er ADDED depuis le dernier reset = pull

local TOL   = 0.75 -- tolérance de correspondance de durée (s)
local SYNC_WINDOW = 10 -- fenêtre après le pull où les règles « sync » sont éligibles (s)
local DEDUP = 1.0  -- fenêtre anti-doublon (ré-ADD du même sort)

-- Ré-ADD : le serveur re-poste un événement DÉJÀ programmé, et dans ce cas
-- `duration` ne contient plus l'intervalle mais le TEMPS RESTANT. Relevé sur
-- capture réelle (Emberdawn) : fire=128,77 posté à 113,27 avec duration 15,50,
-- puis re-posté à 118,13 avec duration 10,64. Identifier sur 10,64 désigne une
-- AUTRE capacité, ou fait basculer en mode générique.
-- Signature retenue : même instant de déclenchement ET durée réduite.
local READD_TOL = 0.25  -- coïncidence de fin (s)

local function cfg() return NS.db.profile.blizzTimeline end

function BT:Available()
    if not C_EncounterTimeline then return false end
    local ok, a = pcall(C_EncounterTimeline.IsFeatureAvailable)
    return ok and a == true
end

local function readInfo(x)
    if type(x) == "table" then return x end
    if C_EncounterTimeline and C_EncounterTimeline.GetEventInfo then
        local ok, info = pcall(C_EncounterTimeline.GetEventInfo, x)
        if ok and type(info) == "table" then return info end
    end
    return nil
end

local function timeRemaining(id)
    if C_EncounterTimeline and C_EncounterTimeline.GetEventTimeRemaining then
        local ok, tr = pcall(C_EncounterTimeline.GetEventTimeRemaining, id)
        local n = NS:SafeNumber(tr)
        if ok and n then return n end
    end
    return nil
end

-- Voix générique selon la sévérité (contenu non couvert par mes données).
-- Renvoie nil si le mode est coupé ou si aucune voix n'est définie pour cette sévérité.
local function genericVoice(sev)
    local c = cfg()
    if not c.generic then return nil end
    local id
    if sev == 0 then id = c.genericTank
    elseif sev == 2 then id = c.genericDanger
    else id = c.genericOther end
    if type(id) == "string" and id ~= "" then return id end
    return nil
end

-- Nom + icône depuis MON spellID (lisibles ; contrairement à l'eventInfo masqué).
local function spellNameIcon(spellID)
    if spellID and C_Spell and C_Spell.GetSpellInfo then
        local ok, info = pcall(C_Spell.GetSpellInfo, spellID)
        if ok and type(info) == "table" then
            local nm = info.name; if nm == "" then nm = nil end
            return nm, info.iconID or info.originalIconID
        end
    end
    return nil, nil
end

--------------------------------------------------------------------------
-- Index de correspondance durée -> événement (par rencontre).
--------------------------------------------------------------------------
function BT:BuildMatchIndex(encID)
    if self._index[encID] ~= nil then return self._index[encID] or nil end
    local def = NS.Engine:GetEncounter(encID)
    if not def then self._index[encID] = false; return nil end
    local list = {}
    for _, ev in ipairs(def.events or {}) do
        local durs = {}
        if ev.firstSeenSec then durs[#durs + 1] = ev.firstSeenSec end
        if ev.cdSeriesSec then for _, d in ipairs(ev.cdSeriesSec) do durs[#durs + 1] = d end end
        if #durs > 0 then list[#list + 1] = { ev = ev, durs = durs } end
    end
    self._index[encID] = list
    return list
end

-- Index eventID -> événement, pour résoudre les règles de durée.
function BT:BuildEventIDIndex(encID)
    self._byEventID = self._byEventID or {}
    if self._byEventID[encID] ~= nil then return self._byEventID[encID] or nil end
    local def = NS.Engine:GetEncounter(encID)
    if not def then self._byEventID[encID] = false; return nil end
    local map = {}
    for _, ev in ipairs(def.events or {}) do
        local eid = NS:SafeNumber(ev.eventID)
        if eid and not map[eid] then map[eid] = ev end
    end
    self._byEventID[encID] = map
    return map
end

--------------------------------------------------------------------------
-- Désambiguïsation par PHASE.
--------------------------------------------------------------------------
-- Quand plusieurs capacités partagent la même durée (22 rencontres sur 41), il
-- faut choisir. Le compteur round-robin le faisait par comptage : une seule
-- perte d'ADDED le décalait, et TOUTES les annonces suivantes du groupe
-- devenaient fausses jusqu'à la fin du pull. C'est le même mode de défaillance
-- que l'indexation dans Learn/Infer, écarté là-bas pour la même raison.
--
-- Les règles `sync` contiennent déjà ce qu'il faut : l'offset de chaque capacité
-- dans le cycle (rencontre 3212 : 5, 12, 20, 28, 35, 41 s sur 45 s). On calcule
-- donc la phase de l'événement reçu et on retient le membre le plus proche.
-- Une observation manquée ne décale rien : la phase suivante reste juste.
--
-- Correction de dérive : le cycle nominal n'est pas exactement le cycle réel
-- (relevé sur capture : 24,28 s annoncés 24). Sans correction, l'écart
-- s'accumule et finit par franchir la moitié de l'espacement. On suit donc le
-- résidu par moyenne glissante, avec un gain faible et un résidu borné pour
-- qu'une résolution douteuse ne puisse pas emporter l'ancrage.
local DRIFT_GAIN = 0.25

-- Offsets du groupe, déduits des règles `sync`. Repli : répartition uniforme
-- selon sequenceOrder, pour les groupes dont un membre n'a pas de règle sync.
function BT:GroupPhases(encID, grp, cycle, members)
    local key = tostring(encID) .. "|" .. grp
    local hit = self._phases[key]
    if hit ~= nil then return hit or nil end

    local set = NS.DURATION_RULES and NS.DURATION_RULES[encID]
    if not set or not cycle or cycle <= 0 then self._phases[key] = false; return nil end

    local syncTime = {}
    for _, r in ipairs(set) do
        if r.sync == true and r.eventID and r.time then
            syncTime[r.eventID] = syncTime[r.eventID] or (r.time % cycle)
        end
    end

    local out, missing = {}, 0
    for i, m in ipairs(members) do
        local off = syncTime[m.eventID]
        if off then
            out[i] = off
        else
            missing = missing + 1
            out[i] = ((m.sequenceOrder or i) - 1) * (cycle / #members)
        end
    end
    if missing > 0 then
        NS:Debug("Timeline : groupe ", grp, " — ", missing,
            " membre(s) sans règle sync, offsets répartis uniformément.")
    end
    self._phases[key] = out
    return out
end

-- Écart circulaire signé entre deux phases.
local function phaseDelta(a, b, cycle)
    local d = (a - b) % cycle
    if d > cycle / 2 then d = d - cycle end
    return d
end

-- Applique les règles curées (durée -> eventID) pour une rencontre donnée.
-- Rend l'événement, ou nil pour laisser la main à l'index historique.
--   passe 1 : règles « sync » (séquence d'ouverture), consommées une seule fois
--             et seulement dans la fenêtre de pull ;
--   passe 2 : règles récurrentes, plus proche dans la tolérance, round-robin
--             sur sequenceGroup/sequenceOrder en cas d'égalité.
function BT:MatchRules(encID, duration)
    local set = NS.DURATION_RULES and NS.DURATION_RULES[encID]
    if not (set and duration) then return nil end
    local byID = self:BuildEventIDIndex(encID)
    if not byID then return nil end

    local now = GetTime()
    local inOpener = self._pullTime and (now - self._pullTime) <= SYNC_WINDOW

    if inOpener then
        local bestIdx, bestDelta
        for i, r in ipairs(set) do
            if r.sync == true and not (self._syncUsed[encID] and self._syncUsed[encID][i]) then
                local delta = math.abs(duration - r.time)
                if delta <= TOL and (not bestDelta or delta < bestDelta) then
                    bestIdx, bestDelta = i, delta
                end
            end
        end
        if bestIdx then
            local ev = byID[set[bestIdx].eventID]
            if ev then
                self._syncUsed[encID] = self._syncUsed[encID] or {}
                self._syncUsed[encID][bestIdx] = true
                return ev, "sync"
            end
        end
    end

    local cands, bestDelta = {}, nil
    for _, r in ipairs(set) do
        if r.sync ~= true then
            local delta = math.abs(duration - r.time)
            if delta <= TOL then
                if not bestDelta or delta < bestDelta then
                    bestDelta, cands = delta, { r }
                elseif delta == bestDelta then
                    cands[#cands + 1] = r
                end
            end
        end
    end
    if #cands == 0 then return nil end

    local pick, how = cands[1], "règle"
    if #cands > 1 then
        local grp = cands[1].sequenceGroup
        if type(grp) == "string" and grp ~= "" then
            local grouped = {}
            for _, r in ipairs(cands) do
                if r.sequenceGroup == grp then grouped[#grouped + 1] = r end
            end
            if #grouped > 0 then
                table.sort(grouped, function(a, b)
                    return (a.sequenceOrder or 0) < (b.sequenceOrder or 0)
                end)

                local cycle  = grouped[1].time
                local phases = self._pullTime
                    and self:GroupPhases(encID, grp, cycle, grouped) or nil

                if phases then
                    local drift = self._drift[grp] or 0
                    local ph = (now - self._pullTime - drift) % cycle
                    local bestI, bestD
                    for i = 1, #grouped do
                        local d = math.abs(phaseDelta(ph, phases[i], cycle))
                        if not bestD or d < bestD then bestI, bestD = i, d end
                    end
                    pick = grouped[bestI]
                    how  = "phase"

                    -- suivi de dérive, borné au quart de l'espacement moyen
                    local resid = phaseDelta(ph, phases[bestI], cycle)
                    local lim   = (cycle / #grouped) * 0.25
                    if resid > lim then resid = lim elseif resid < -lim then resid = -lim end
                    self._drift[grp] = drift + resid * DRIFT_GAIN
                else
                    -- repli quand la phase n'est pas calculable (arrivée en cours
                    -- de combat, offsets absents) : comportement historique.
                    local n = self._seqCounters[grp] or 0
                    pick = grouped[(n % #grouped) + 1]
                    self._seqCounters[grp] = n + 1
                    how = "round-robin (repli)"
                end
            end
        end
    end
    local ev = byID[pick.eventID]
    if ev then return ev, how end
    return nil
end

-- Identifie un événement timeline par sa durée, parmi les rencontres candidates.
function BT:MatchDuration(duration)
    if type(duration) ~= "number" then return nil end
    if not self._candidates then
        self._candidates = NS.CurrentEncounterCandidates() or {}
    end
    local order = {}
    if self._activeEnc then order[#order + 1] = self._activeEnc end
    for _, e in ipairs(self._candidates) do
        if e ~= self._activeEnc then order[#order + 1] = e end
    end
    -- 1) règles curées : elles seules savent trancher deux capacités de même durée
    for _, encID in ipairs(order) do
        local ev, how = self:MatchRules(encID, duration)
        if ev then
            if not self._activeEnc then
                self._activeEnc = encID
                NS:Debug("Timeline : boss identifié -> encounter", encID)
            end
            self._lastMatchHow = how
            return ev
        end
    end

    -- 2) repli : index historique par durée (plus proche, toutes durées confondues)
    local best, bestDelta, bestEnc
    for _, encID in ipairs(order) do
        local idx = self:BuildMatchIndex(encID)
        if idx then
            for _, entry in ipairs(idx) do
                for _, d in ipairs(entry.durs) do
                    local delta = math.abs(duration - d)
                    if delta <= TOL and (not bestDelta or delta < bestDelta) then
                        best, bestDelta, bestEnc = entry.ev, delta, encID
                    end
                end
            end
        end
        if best and encID == self._activeEnc then break end
    end
    if best then
        self._lastMatchHow = "durée"
        if not self._activeEnc then
            self._activeEnc = bestEnc
            NS:Debug("Timeline : boss identifié -> encounter", bestEnc)
        end
        return best
    end
    return nil
end

--------------------------------------------------------------------------
-- Rendu.
--------------------------------------------------------------------------
function BT:Render(id, name, icon, dur, endTime, sev, role)
    local args = { name = name, icon = icon, duration = dur, endTime = endTime, severity = sev }
    if cfg().bar then NS.UI.TimerBars:AddOrUpdate("bt:" .. id, args) end
    local ringWanted = cfg().ring
        or (NS.db.profile.rings.autoRole and (role == "tank" or role == "heal" or sev == 2))
    if ringWanted and NS.UI.Rings then NS.UI.Rings:AddOrUpdate("bt:" .. id, args) end
end

function BT:OnAdded(x)
    if not cfg().enabled then return end
    local info = readInfo(x)
    if not info then return end
    if info.source ~= nil and not NS:IsSecret(info.source) and info.source ~= 0 then return end
    local id = NS:SafeNumber(info.id) or (type(x) == "number" and NS:SafeNumber(x))
    if not id then return end
    local matchDur = NS:SafeNumber(info.duration)   -- identité (≈ intervalle, matche mes données)
    local fireDur  = timeRemaining(id) or matchDur   -- minutage (temps réel restant côté serveur)
    if not (matchDur or fireDur) then return end

    -- premier événement depuis le dernier reset : c'est le pull, il ouvre la
    -- fenêtre où les règles « sync » sont éligibles.
    if not self._pullTime then
        self._pullTime = GetTime()
        NS.Bus:Emit("TMB_TIMELINE_PULL", "1er événement de timeline")
    end

    local now = GetTime()
    local endTime = now + (fireDur or 5)

    -- Ré-ADD d'un événement déjà actif : on met à jour le MINUTAGE et on
    -- conserve l'IDENTITÉ d'origine. Ce test doit précéder MatchDuration :
    -- ré-identifier sur une durée qui est en fait un temps restant est
    -- exactement le piège que ce bloc existe pour éviter.
    do
        local hitID, hitE
        for aid, e in pairs(self.active) do
            if math.abs(e.endTime - endTime) <= READD_TOL
                and matchDur and e.matchDur and matchDur < e.matchDur - 0.01 then
                hitID, hitE = aid, e
                break
            end
        end
        if hitE then
            hitE.endTime = endTime
            if id and id ~= hitID then
                -- le serveur a changé d'identifiant : on suit le nouveau sans
                -- refaire l'identification (mutation hors de la boucle pairs)
                self.active[hitID] = nil
                self.active[id] = hitE
                NS.UI.TimerBars:Remove("bt:" .. hitID)
                if NS.UI.Rings then NS.UI.Rings:Remove("bt:" .. hitID) end
            end
            local key = (id and id ~= hitID) and id or hitID
            self:Render(key, hitE.name, hitE.icon or 134400,
                math.max(0.1, endTime - now), endTime, hitE.severity, hitE.role)
            NS:Debug("Timeline : ré-ADD ignoré pour l'identité (durée ", tostring(matchDur),
                " = temps restant), minutage mis à jour.")
            return
        end
    end

    local ev = self:MatchDuration(matchDur or fireDur)

    -- anti-doublon : même capacité déjà programmée quasi au même instant
    if ev then
        for _, e in pairs(self.active) do
            if e.evRef == ev and math.abs(e.endTime - endTime) <= DEDUP then return end
        end
    end

    local name, icon, sev, voice, role, preAlert, generic
    if ev then
        local n, ic = spellNameIcon(ev.spellID)
        name  = n or "Capacité"
        icon  = ic or 134400
        sev   = NS:SafeNumber(ev.severity) or 1
        voice = ev.voice
        role  = ev.role
        preAlert = ev.preAlertSec
        NS:Debug("Timeline ADDED dur=", string.format("%.1f", fireDur or 0), "-> ", name,
            "(voix ", tostring(voice), ")")
    else
        name = (info.spellName ~= nil and not NS:IsSecret(info.spellName)) and tostring(info.spellName) or "Capacité"
        icon = NS:SafeNumber(info.iconFileID) or 134400
        sev  = NS:SafeNumber(info.severity) or 1
        generic = true
        -- même règle que mes données : les dangers (sévérité 2) méritent 3 s d'avance
        if sev == 2 then preAlert = 3 end
        NS:Debug("Timeline ADDED dur=", string.format("%.1f", fireDur or 0),
            "-> non identifié (générique, sév ", tostring(sev), ")")
    end

    if NS.Recorder and NS.Recorder:IsRecording() then
        NS.Recorder:OnAdded(id, matchDur, fireDur, ev, self._lastMatchHow, info)
    end

    self.active[id] = {
        endTime = endTime, total = fireDur or 5, matchDur = matchDur,
        name = name, icon = icon, severity = sev,
        voice = voice, evRef = ev, role = role, preAlert = preAlert, announced = false,
        generic = generic,
    }
    self:Render(id, name, icon, fireDur or 5, endTime, sev, role)
end

function BT:OnStateChanged(x)
    if not cfg().enabled then return end
    local info = readInfo(x); if not info then return end
    local id = NS:SafeNumber(info.id) or (type(x) == "number" and NS:SafeNumber(x))
    local e = id and self.active[id]
    if not e then return end
    local dur = timeRemaining(id) or NS:SafeNumber(info.duration)
    if dur then
        e.endTime = GetTime() + dur
        local ic
        if e.evRef then _, ic = spellNameIcon(e.evRef.spellID) end
        self:Render(id, e.name, ic or 134400, dur, e.endTime, e.severity, e.role)
    end
end

function BT:OnRemoved(x)
    local id = (type(x) == "table" and NS:SafeNumber(x.id)) or NS:SafeNumber(x)
    if not id then return end
    if NS.Recorder and NS.Recorder:IsRecording() then NS.Recorder:OnRemoved(id) end
    self.active[id] = nil
    NS.UI.TimerBars:Remove("bt:" .. id)
    if NS.UI.Rings then NS.UI.Rings:Remove("bt:" .. id) end
end

function BT:ClearAll()
    if self._pullTime then NS.Bus:Emit("TMB_TIMELINE_RESET", "fin de combat") end
    for id in pairs(self.active) do
        NS.UI.TimerBars:Remove("bt:" .. id)
        if NS.UI.Rings then NS.UI.Rings:Remove("bt:" .. id) end
    end
    wipe(self.active)
    self._activeEnc = nil
    self._candidates = nil
    wipe(self._syncUsed)
    wipe(self._seqCounters)
    wipe(self._drift)
    self._pullTime = nil
end

--------------------------------------------------------------------------
-- Annonces vocales (pré-alerte au lead).
--------------------------------------------------------------------------
function BT:Tick()
    if not cfg().enabled then return end
    local now = GetTime()
    local baseLead = (NS.db and NS.db.profile.voice.lead) or 0

    -- recalage périodique sur le compte à rebours serveur (anti-dérive)
    self._resyncAcc = (self._resyncAcc or 0) + 0.1
    local doResync = self._resyncAcc >= 0.3
    if doResync then self._resyncAcc = 0 end

    for id, e in pairs(self.active) do
        if doResync then
            local tr = timeRemaining(id)
            if tr then
                e.endTime = now + tr
                if cfg().bar then
                    NS.UI.TimerBars:AddOrUpdate("bt:" .. id, {
                        name = e.name, icon = e.icon or 134400,
                        duration = tr, endTime = e.endTime, severity = e.severity,
                    })
                end
            end
        end
        -- avance : slider « Avance des annonces » ou pré-alerte de la capacité (min 0,5 s)
        local lead = math.max(baseLead, e.preAlert or 0, 0.5)
        if not e.announced and now >= (e.endTime - lead) then
            e.announced = true
            -- Si l'EventBridge a confié cette annonce au jeu, il l'a DÉJÀ jouée
            -- (trigger highlight, ~5 s avant). Rejouer ici ferait doublon.
            local bridged = e.evRef and NS.EventBridge and NS.EventBridge:WillPlaySound(e.evRef)
            if cfg().voice and not bridged then
                if e.voice then
                    NS.Voice:Play(e.voice)
                else
                    -- non identifié : voix générique par sévérité, sinon bip
                    local gid = e.generic and genericVoice(e.severity) or nil
                    local played = gid and NS.Voice:Play(gid)
                    if not played and cfg().cue and PlaySound then
                        pcall(PlaySound, 8959, (NS.db.profile.voice.channel) or "Master")
                    end
                end
            end
            if e.severity == 2 then NS.UI.FlashText:Show(e.name, "danger", 2.0) end
        end
    end

    -- anneau central : suit la PROCHAINE capacité imminente (la plus proche, <= 30 s)
    if NS.UI.RingProgress then
        local bestId, bestRem, bestE
        for id, e in pairs(self.active) do
            local rem = e.endTime - now
            if rem > 0 and rem <= 30 and (not bestRem or rem < bestRem) then
                bestId, bestRem, bestE = id, rem, e
            end
        end
        if bestE then
            NS.UI.RingProgress:Track("bt:" .. bestId, bestRem, bestE.total, bestE.name, bestE.severity)
        else
            NS.UI.RingProgress:Stop()
        end
    end
end

--------------------------------------------------------------------------
-- Init.
--------------------------------------------------------------------------
function BT:Init()
    local f = CreateFrame("Frame")
    self.frame = f
    f:RegisterEvent("ENCOUNTER_TIMELINE_EVENT_ADDED")
    f:RegisterEvent("ENCOUNTER_TIMELINE_EVENT_REMOVED")
    f:RegisterEvent("ENCOUNTER_TIMELINE_EVENT_STATE_CHANGED")
    f:RegisterEvent("ENCOUNTER_TIMELINE_STATE_UPDATED")
    f:RegisterEvent("PLAYER_REGEN_ENABLED")
    f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    f:SetScript("OnEvent", function(_, event, a1)
        if event == "ENCOUNTER_TIMELINE_EVENT_ADDED" then
            self:OnAdded(a1)
        elseif event == "ENCOUNTER_TIMELINE_EVENT_STATE_CHANGED" then
            self:OnStateChanged(a1)
        elseif event == "ENCOUNTER_TIMELINE_EVENT_REMOVED" then
            self:OnRemoved(a1)
        elseif event == "ZONE_CHANGED_NEW_AREA" then
            self._candidates = nil
        else -- STATE_UPDATED / PLAYER_REGEN_ENABLED
            self:ClearAll()
        end
    end)
    f._acc = 0
    f:SetScript("OnUpdate", function(self2, e)
        self2._acc = self2._acc + e
        if self2._acc < 0.1 then return end
        self2._acc = 0
        BT:Tick()
    end)
end
