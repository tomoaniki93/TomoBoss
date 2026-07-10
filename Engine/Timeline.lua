---@diagnostic disable: undefined-global
-- TomoBoss — Moteur de timeline (prédiction + resynchronisation des capacités de boss).

local NS = select(2, ...)
NS.Engine = NS.Engine or {}
local E = NS.Engine
E.Encounters = E.Encounters or {}

--------------------------------------------------------------------------
-- Enregistrement des rencontres.
--------------------------------------------------------------------------
function E:RegisterEncounter(encounterID, def)
    encounterID = tonumber(encounterID)
    if not encounterID or type(def) ~= "table" then return end
    def.encounterID = encounterID
    def.events = def.events or {}
    for i, ev in ipairs(def.events) do
        ev.__key = "tl" .. i
        ev.cdSeriesSec = ev.cdSeriesSec or { 30 }
        ev.firstSeenSec = ev.firstSeenSec or ev.cdSeriesSec[1] or 10
        ev.severity = ev.severity or 1
    end
    self.Encounters[encounterID] = def
end

function E:GetEncounter(id) return self.Encounters[tonumber(id)] end

--------------------------------------------------------------------------
-- Fusion dans la base (merge).
-- Permet à un fichier complémentaire d'ajouter, remplacer ou retirer des
-- événements d'un boss déjà enregistré, sans réécrire toute la définition.
--   patch.name / patch.dungeon : remplacent les métadonnées si fournis.
--   patch.events               : fusionnés par spellID (remplacent l'existant),
--                                sinon ajoutés.
--   patch.remove               : liste de spellID à retirer.
-- Si le boss n'existe pas encore, le patch est enregistré tel quel.
--------------------------------------------------------------------------
function E:MergeEncounter(id, patch)
    id = tonumber(id)
    if not id or type(patch) ~= "table" then return end
    local def = self.Encounters[id]
    if not def then
        self:RegisterEncounter(id, patch)
        return
    end

    if patch.name then def.name = patch.name end
    if patch.dungeon then def.dungeon = patch.dungeon end

    if patch.remove then
        local rm = {}
        for _, sid in ipairs(patch.remove) do rm[sid] = true end
        for i = #def.events, 1, -1 do
            local s = def.events[i].spellID
            if s and rm[s] then table.remove(def.events, i) end
        end
    end

    if patch.events then
        for _, ev in ipairs(patch.events) do
            local existing
            if ev.spellID then
                for _, e in ipairs(def.events) do
                    if e.spellID == ev.spellID then existing = e break end
                end
            end
            if existing then
                for k, v in pairs(ev) do existing[k] = v end
                existing.__icon = nil
                existing.__name = nil
            else
                def.events[#def.events + 1] = ev
            end
        end
    end

    self:RegisterEncounter(id, def) -- renormalise et ré-enregistre
end

-- Nombre de rencontres enregistrées (pratique pour le debug / l'à-propos).
function E:CountEncounters()
    local n = 0
    for _ in pairs(self.Encounters) do n = n + 1 end
    return n
end

--------------------------------------------------------------------------
-- Runtime.
--------------------------------------------------------------------------
local T = {}
E.Timeline = T
T.running = false
T.occ = {}          -- liste d'occurrences actives

local function IconFor(ev)
    if ev.__icon then return ev.__icon end
    local tex = 134400
    if ev.spellID and C_Spell and C_Spell.GetSpellTexture then
        local ok, t = pcall(C_Spell.GetSpellTexture, ev.spellID)
        if ok and t then tex = t end
    end
    ev.__icon = tex
    return tex
end

-- Nom affiché sur la barre.
-- Priorité : nom explicite -> nom du sort résolu en direct (localisé par le client)
-- -> libellé vocal français -> "Sort <id>". On ne met en cache que le nom réel du
-- sort (les données de sort se chargent parfois de façon asynchrone).
local function NameFor(ev)
    if ev.name and ev.name ~= "" then return ev.name end
    if ev.__name then return ev.__name end
    local nm
    if ev.spellID and C_Spell and C_Spell.GetSpellInfo then
        local ok, info = pcall(C_Spell.GetSpellInfo, ev.spellID)
        if ok and type(info) == "table" and info.name and info.name ~= "" then
            nm = info.name
            ev.__name = nm  -- cache uniquement le vrai nom du sort
        end
    end
    if not nm and ev.voice then
        local e = NS.Voice and NS.Voice.Catalog and NS.Voice.Catalog[ev.voice]
        if e then nm = e.fr end
    end
    return nm or ("Sort " .. tostring(ev.spellID or "?"))
end

-- Nom du sort résolu directement (sans repli), utilisé pour le matching.
-- Le spellID vient des DONNÉES (nombre lisible), pas de l'incantation masquée.
local function SpellName(ev)
    if ev.spellID and C_Spell and C_Spell.GetSpellInfo then
        local ok, info = pcall(C_Spell.GetSpellInfo, ev.spellID)
        if ok and type(info) == "table" and info.name and info.name ~= "" then
            return info.name
        end
    end
    return nil
end

-- Lit l'incantation en cours d'une unité : nom + durée (gère les valeurs masquées).
-- Le NOM et les temps restent lisibles même quand le spellID de l'événement est masqué.
local function ReadBossCast(unit, isChannel)
    local name, _, _, startMS, endMS
    if isChannel then
        name, _, _, startMS, endMS = UnitChannelInfo(unit)
    else
        name, _, _, startMS, endMS = UnitCastingInfo(unit)
    end
    local safeName = (name ~= nil and not NS:IsSecret(name)) and tostring(name) or nil
    local s, e = NS:SafeNumber(startMS), NS:SafeNumber(endMS)
    local dur
    if s and e and e > s then dur = (e - s) / 1000 end
    return safeName, dur
end

local function leadFor(ev)
    local base = NS.db and NS.db.profile and NS.db.profile.voice.lead or 0
    return math.max(base or 0, ev.preAlertSec or 0)
end

-- Un événement de transition de phase / intermède : sert de DÉCLENCHEUR.
-- Détecté via un drapeau explicite ou via son annonce vocale « phase-change ».
local function isPhaseEvent(ev)
    return ev.phase == true or ev.voice == "phase-change"
end

-- Affichage par défaut (événements intégrés) : barre + son, pas d'anneau.
local DEFAULT_DISPLAY = { bar = true, sound = true }
local function dispOf(ev) return ev.display or DEFAULT_DISPLAY end

-- Rend une occurrence sur les widgets choisis (barre et/ou anneau).
local function RenderOcc(occ)
    local ev = occ.ev
    local d = dispOf(ev)
    local args = { name = NameFor(ev), icon = IconFor(ev), duration = occ.duration, endTime = occ.fireAt, severity = ev.severity }
    if d.bar then NS.UI.TimerBars:AddOrUpdate(occ.key, args)
    else NS.UI.TimerBars:Remove(occ.key) end
    if NS.UI.Rings then
        if d.ring then NS.UI.Rings:AddOrUpdate(occ.key, args)
        else NS.UI.Rings:Remove(occ.key) end
    end
end

-- Retire une occurrence de tous les widgets.
local function RemoveOcc(occ)
    NS.UI.TimerBars:Remove(occ.key)
    if NS.UI.Rings then NS.UI.Rings:Remove(occ.key) end
end

-- Annonce vocale (si activée pour cette occurrence) + flash central en sévérité 2.
local function AnnounceOcc(occ)
    local ev = occ.ev
    if dispOf(ev).sound then NS.Voice:Play(ev.voice) end
    if ev.severity == 2 then NS.UI.FlashText:Show(NameFor(ev), "danger", 2.2) end
end

-- Cadre pour la synchronisation sur les incantations réelles des boss.
function T:EnsureCastFrame()
    if self.castFrame then return self.castFrame end
    local f = CreateFrame("Frame")
    f:SetScript("OnEvent", function(_, event, unit, _, spellID)
        if not self.running then return end
        local isChannel = (event == "UNIT_SPELLCAST_CHANNEL_START")
        self:OnBossCast(unit, spellID, isChannel)
    end)
    self.castFrame = f
    return f
end

function T:RegisterCastEvents()
    local f = self:EnsureCastFrame()
    for i = 1, 8 do
        f:RegisterUnitEvent("UNIT_SPELLCAST_START", "boss" .. i)
        f:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "boss" .. i)
    end
end

function T:UnregisterCastEvents()
    if self.castFrame then self.castFrame:UnregisterAllEvents() end
end

--------------------------------------------------------------------------
-- Démarrage / arrêt.
--------------------------------------------------------------------------
function T:Start(encounterID, isDemo)
    local def = E:GetEncounter(encounterID)
    if not def then return false end
    self:Stop()

    self.running = true
    self.demo = isDemo and true or false
    self.encounterID = tonumber(encounterID)
    self.startTime = GetTime()

    local now = self.startTime
    for _, ev in ipairs(def.events) do
        local occ = {
            ev = ev,
            key = ev.__key,
            cycleIndex = 1,
            fireAt = now + ev.firstSeenSec,
            duration = ev.firstSeenSec,
            voiced = false,
            dormant = false,
        }
        self.occ[#self.occ + 1] = occ
        -- les événements de phase sont des déclencheurs : pas de barre prédictive
        if not isPhaseEvent(ev) then
            RenderOcc(occ)
        end
    end

    self:RegisterCastEvents()
    self:EnsureTicker()
    self.ticker:Show()
    NS:Debug("Timeline démarrée :", def.name, "(", encounterID, ")", self.demo and "[aperçu]" or "")
    return true
end

function T:Stop()
    self.running = false
    self.demo = false
    self.encounterID = nil
    for _, occ in ipairs(self.occ) do
        NS.UI.TimerBars:Remove(occ.key)
    end
    wipe(self.occ)
    self:UnregisterCastEvents()
    if self.ticker then self.ticker:Hide() end
end

function T:IsRunning() return self.running end

--------------------------------------------------------------------------
-- Ticker principal.
--------------------------------------------------------------------------
function T:EnsureTicker()
    if self.ticker then return self.ticker end
    self.ticker = CreateFrame("Frame")
    self.ticker._acc = 0
    self.ticker:Hide()
    self.ticker:SetScript("OnUpdate", function(_, elapsed)
        self.ticker._acc = self.ticker._acc + elapsed
        if self.ticker._acc < 0.05 then return end
        self.ticker._acc = 0
        self:Tick()
    end)
    return self.ticker
end

function T:Tick()
    if not self.running then return end
    local now = GetTime()
    for _, occ in ipairs(self.occ) do
        local ev = occ.ev
        -- ignore les capacités en dormance (mises en pause par une transition de phase)
        -- et les événements de phase eux-mêmes (inertes : ils n'agissent que sur cast réel)
        if not occ.dormant and not isPhaseEvent(ev) then
            local lead = leadFor(ev)

            -- annonce vocale (+ flash) juste avant l'impact
            if not occ.voiced and now >= (occ.fireAt - lead) then
                occ.voiced = true
                AnnounceOcc(occ)
            end

            -- l'occurrence est passée : planifier la suivante
            if now >= occ.fireAt then
                local series = ev.cdSeriesSec
                local interval = series[occ.cycleIndex] or series[#series] or 30
                occ.cycleIndex = occ.cycleIndex + 1
                if occ.cycleIndex > #series then occ.cycleIndex = 1 end
                occ.fireAt = occ.fireAt + interval
                occ.duration = interval
                occ.voiced = false
            end

            -- maintient les widgets à jour
            RenderOcc(occ)
        end
    end
end

--------------------------------------------------------------------------
-- Transition de phase : déclenchée par le cast réel d'un événement de phase.
-- Met en dormance toutes les autres capacités (barre masquée, boucle stoppée) ;
-- chacune se réveille et se recale quand elle est réellement observée dans la
-- nouvelle phase. On réinitialise aussi leur index de série pour repartir propre.
--------------------------------------------------------------------------
function T:OnPhaseTransition(phaseOcc)
    for _, occ in ipairs(self.occ) do
        if occ ~= phaseOcc and not isPhaseEvent(occ.ev) then
            occ.dormant = true
            occ.cycleIndex = 1
            occ.voiced = false
            RemoveOcc(occ)
        end
    end
    NS:Debug("Transition de phase — capacités mises en dormance jusqu'à réobservation.")
end

--------------------------------------------------------------------------
-- Synchronisation sur incantation réelle du boss.
--
-- En WoW Midnight, le spellID de UNIT_SPELLCAST_* est masqué (secretvalue),
-- MAIS le nom et la durée de l'incantation restent lisibles via UnitCastingInfo.
-- On recale donc la timeline à 3 niveaux, du plus fiable au moins fiable :
--   1. spellID exact (si lisible)
--   2. nom exact : nom live == nom résolu depuis le spellID des DONNÉES
--      (le spellID stocké est un nombre lisible, contrairement à celui du cast)
--   3. durée d'incantation proche (dernier recours pour lever une ambiguïté)
--------------------------------------------------------------------------
function T:MatchOccurrence(sid, liveName, liveDur)
    -- 1. par spellID lisible
    if sid then
        for _, occ in ipairs(self.occ) do
            if occ.ev.spellID == sid then return occ end
        end
    end
    -- 2. par nom exact
    if liveName then
        for _, occ in ipairs(self.occ) do
            if SpellName(occ.ev) == liveName then return occ end
        end
    end
    -- 3. par durée d'incantation — uniquement si le nom est indisponible.
    --    (si on a un nom mais qu'il ne correspond à rien, c'est une autre capacité :
    --     on garde la prédiction plutôt que de risquer un faux recalage par durée)
    if liveDur and not liveName then
        local best, bestGap
        local now = GetTime()
        for _, occ in ipairs(self.occ) do
            local cd = occ.ev.castDuration
            if cd and math.abs(cd - liveDur) <= 0.35 then
                local gap = math.abs((occ.fireAt or now) - now)
                if not bestGap or gap < bestGap then best, bestGap = occ, gap end
            end
        end
        if best then return best end
    end
    return nil
end

function T:OnBossCast(unit, spellID, isChannel)
    if not self.running then return end

    local liveName, liveDur = ReadBossCast(unit, isChannel)
    local sid = NS:SafeNumber(spellID)

    local occ = self:MatchOccurrence(sid, liveName, liveDur)
    if not occ then return end

    local ev = occ.ev
    local now = GetTime()

    -- le nom live fait autorité pour l'affichage (corrige aussi les noms non encore
    -- résolus au pull, ex. données de sort pas encore en cache)
    if liveName then ev.__name = liveName end

    -- événement de phase réellement casté : bascule de phase (dormance des autres),
    -- puis annonce systématique (le callout d'intermède est important). Pas de barre.
    if isPhaseEvent(ev) then
        self:OnPhaseTransition(occ)
        NS.Voice:Play(ev.voice)
        if ev.severity == 2 then
            NS.UI.FlashText:Show(NameFor(ev), "danger", 2.2)
        end
        return
    end

    -- capacité réobservée : sort de dormance si besoin.
    occ.dormant = false

    -- recale l'occurrence sur l'impact réel : maintenant + durée d'incantation
    local wasVoiced = occ.voiced
    local dur = liveDur or ev.castDuration or occ.duration
    occ.fireAt = now + (dur or 0)
    occ.duration = math.max(0.1, dur or occ.duration)
    occ.voiced = true

    -- n'annonce que si la pré-alerte du Tick ne l'a pas déjà fait pour cette occurrence
    -- (sinon le cast réel se contente de recaler la barre, sans doublon vocal)
    if not wasVoiced then
        AnnounceOcc(occ)
    end

    RenderOcc(occ)
end

--------------------------------------------------------------------------
-- Aperçu / test (sans être réellement en combat).
--------------------------------------------------------------------------
function T:RunDemo(encounterID)
    encounterID = encounterID or 1999
    self:Start(encounterID, true)
end

function T:StopDemo()
    if self.demo then self:Stop() end
end
