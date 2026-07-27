---@diagnostic disable: undefined-global
-- TomoBoss — Apprentissage / Enregistreur (v2).
--
-- RÈGLE ABSOLUE : on ne lit JAMAIS UnitCastingInfo / UnitChannelInfo sur une
-- unité hostile. Sous Midnight ces fonctions ne renvoient rien d'exploitable
-- (spellID masqué, nom masqué) — c'est le constat déjà consigné dans
-- BossReminder/TrashCD/Observation.lua, et la v1 de ce module l'avait ignoré.
-- Elle ne captait donc que les sorts du JOUEUR, seuls non masqués.
--
-- Ce qui reste lisible, et sur quoi tout repose désormais :
--   * l'ORDRE et l'INSTANT des événements UNIT_SPELLCAST_* (les événements
--     eux-mêmes arrivent, seuls leurs arguments sont masqués) ;
--   * UnitGUID(unit) -> npcID quand il est lisible. La capture réelle montre
--     qu'il est MASQUÉ sur les unités boss (colonne npc vide) : on le tente,
--     on ne s'appuie pas dessus. L'identité repose sur la DURÉE ;
--   * C_EncounterTimeline : durée-identité + instant de déclenchement.
--
-- La durée d'incantation est donc MESURÉE au chronomètre entre START et
-- SUCCEEDED, jamais demandée à l'API. Même méthode que TrashCD.
--
-- Aucun accès au combat log (taint définitif). Aucun appel EJ_* en combat.

local NS = select(2, ...)
local R = {}
NS.Learn = NS.Learn or {}
NS.Learn.Recorder = R

local Store = NS.Learn.Store

local PENDING_TIMEOUT = 30   -- une incantation en cours abandonnée au-delà

local function cfg() return NS.db.profile.learn end

--------------------------------------------------------------------------
-- Identité du lanceur.
--------------------------------------------------------------------------
-- UnitGUID reste lisible sous Midnight. Format attendu :
--   Creature-0-<serveur>-<instance>-<zone>-<npcID>-<spawn>
-- Un GUID masqué ne doit surtout pas être passé à string.match : toute
-- opération sur un secretvalue lève le taint. D'où le test IsSecret d'abord.
local function npcIDOf(unit)
    local ok, guid = pcall(UnitGUID, unit)
    if not ok or guid == nil then return nil end
    if NS:IsSecret(guid) then return nil end
    if type(guid) ~= "string" then return nil end
    local id = guid:match("^%a+%-%d+%-%d+%-%d+%-%d+%-(%d+)%-")
    return tonumber(id)
end

--------------------------------------------------------------------------
-- Démarrage / arrêt.
--------------------------------------------------------------------------
function R:Begin(reason)
    if not cfg().enabled then return end
    if Store:IsRecording() then return end

    local instID = select(8, GetInstanceInfo())
    local encID  = self._pendingEncID or NS.Learn.Journal:ResolveCurrentEncounter()

    -- npcID du boss principal : identifiant bien plus fiable que la comparaison
    -- de noms localisés que faisait la v1 (et qui échouait silencieusement).
    -- ENCOUNTER_START précède la disponibilité des unités boss : au moment du
    -- Begin, UnitGUID et UnitName renvoient nil (constaté : « boss=nil npc=nil »
    -- en tête de capture). On résout donc au premier cast observé.
    local npc = npcIDOf("boss1")
    local key = Store:MakeKey(encID, instID, npc)

    Store:BeginPull(key, { npc = npc, inst = instID, boss = UnitName("boss1") })
    self._pendingEncID = nil
    self._pending = {}
    self._seenTL = {}
    NS:Debug("Apprentissage v2 : enregistrement démarré (", reason, ") clé =", key, "npc =", tostring(npc))
end

function R:Finish(outcome)
    if not Store:IsRecording() then return end
    local key, n = Store:Commit(outcome)
    self._pending, self._seenTL = nil, nil
    if key and cfg().announce then
        NS:Print(string.format("Pull enregistré (%s) — %d pull(s) en base. |cff8bd5ca/tmb learn dump|r pour voir la capture brute.",
            tostring(key), n or 0))
    end
end

--------------------------------------------------------------------------
-- Flux 1 : timeline Blizzard (minutage autoritatif).
--------------------------------------------------------------------------
function R:OnTimelineAdded(x)
    if not Store:IsRecording() then return end

    local info = x
    if type(info) ~= "table" and C_EncounterTimeline and C_EncounterTimeline.GetEventInfo then
        local ok, got = pcall(C_EncounterTimeline.GetEventInfo, x)
        info = ok and got or nil
    end
    if type(info) ~= "table" then return end
    if info.source ~= nil and not NS:IsSecret(info.source) and info.source ~= 0 then return end

    local id  = NS:SafeNumber(info.id) or (type(x) == "number" and NS:SafeNumber(x))
    local dur = NS:SafeNumber(info.duration)
    if not dur then return end

    if id then
        local now = GetTime()
        self._seenTL = self._seenTL or {}
        local last = self._seenTL[id]
        if last and (now - last) < 1.0 then return end
        self._seenTL[id] = now
    end

    -- `duration` = identité (l'intervalle, ce que compare BT:MatchDuration).
    -- `GetEventTimeRemaining` = minutage réel. Sans le second, impossible de
    -- corréler l'événement à l'incantation qu'il annonce.
    local fire
    if id and C_EncounterTimeline and C_EncounterTimeline.GetEventTimeRemaining then
        local ok, tr = pcall(C_EncounterTimeline.GetEventTimeRemaining, id)
        local n = ok and NS:SafeNumber(tr)
        if n then fire = NS.round((GetTime() - Store.current.t0) + n, 2) end
    end

    -- on garde aussi le nom serveur QUAND il est lisible : c'est un bonus
    -- opportuniste, jamais une dépendance.
    local sname
    if info.spellName ~= nil and not NS:IsSecret(info.spellName) then
        sname = tostring(info.spellName)
    end

    Store:Add(Store.KIND_TIMELINE, dur, nil, nil, fire, sname)
end

--------------------------------------------------------------------------
-- Flux 2 : cycle de vie des incantations de boss, mesuré au chronomètre.
--------------------------------------------------------------------------
function R:OnCastStart(unit, channel)
    if not Store:IsRecording() then return end
    self._pending = self._pending or {}
    local npc = npcIDOf(unit)
    -- résolution tardive de l'identité du boss (voir Begin)
    local meta = Store.current and Store.current.meta
    if meta then
        if not meta.npc and npc then meta.npc = npc end
        if not meta.boss then
            -- SafeString garde l'ordre : masqué d'abord, comparaison ensuite.
            meta.boss = NS:SafeString(UnitName(unit))
        end
    end
    self._pending[unit] = { t = GetTime(), channel = channel, npc = npc }
end

function R:OnCastEnd(unit, kind)
    if not Store:IsRecording() then return end
    local p = self._pending and self._pending[unit]
    if not p then
        -- SUCCEEDED sans START : incantation instantanée. C'est une classe
        -- d'identité à part entière (TrashCD la traite pareil), on la garde.
        if kind == Store.KIND_CAST then
            Store:Add(Store.KIND_INSTANT, 0, npcIDOf(unit), unit)
        end
        return
    end
    self._pending[unit] = nil
    local dur = GetTime() - p.t
    if dur < 0 or dur > PENDING_TIMEOUT then return end
    Store:Add(kind, dur, p.npc, unit)
end

function R:OnCastAborted(unit)
    if not Store:IsRecording() then return end
    local p = self._pending and self._pending[unit]
    if not p then return end
    self._pending[unit] = nil
    -- une incantation interrompue ne doit pas polluer les durées, mais savoir
    -- qu'elle a eu lieu aide à comprendre un cycle qui « saute ».
    Store:Add(Store.KIND_INTERRUPTED, GetTime() - p.t, p.npc, unit)
end

--------------------------------------------------------------------------
-- Init.
--------------------------------------------------------------------------
function R:Init()
    local f = CreateFrame("Frame")
    self.frame = f
    f:RegisterEvent("ENCOUNTER_START")
    f:RegisterEvent("ENCOUNTER_END")
    f:RegisterEvent("PLAYER_REGEN_ENABLED")
    f:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
    f:RegisterEvent("ENCOUNTER_TIMELINE_EVENT_ADDED")
    f:SetScript("OnEvent", function(_, event, a1, a2, a3, a4, a5)
        if event == "ENCOUNTER_START" then
            self._pendingEncID = NS:SafeNumber(a1)
            self:Begin("ENCOUNTER_START")
        elseif event == "ENCOUNTER_END" then
            self:Finish(NS:SafeNumber(a5) == 1 and "kill" or "wipe")
        elseif event == "INSTANCE_ENCOUNTER_ENGAGE_UNIT" then
            if Store:IsRecording() and not UnitExists("boss1") then self:Finish("abandon") end
        elseif event == "PLAYER_REGEN_ENABLED" then
            self:Finish("abandon")
        elseif event == "ENCOUNTER_TIMELINE_EVENT_ADDED" then
            self:OnTimelineAdded(a1)
        end
    end)

    -- RegisterUnitEvent ne tient pas sur boss1..8 : ces jetons n'existent pas
    -- hors rencontre, le filtre ne s'établit pas et le frame reçoit TOUTES les
    -- unités. Inscription non filtrée + filtrage du jeton, comme Engine/Timeline.
    local uf = CreateFrame("Frame")
    self.unitFrame = uf
    for _, ev in ipairs({
        "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_SUCCEEDED",
        "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_STOP",
        "UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_CHANNEL_STOP",
    }) do uf:RegisterEvent(ev) end

    uf:SetScript("OnEvent", function(_, event, unit)
        if type(unit) ~= "string" or not unit:match("^boss%d") then return end
        if event == "UNIT_SPELLCAST_START" then
            R:OnCastStart(unit, false)
        elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
            R:OnCastStart(unit, true)
        elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
            R:OnCastEnd(unit, Store.KIND_CAST)
        elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" then
            R:OnCastEnd(unit, Store.KIND_CHANNEL)
        elseif event == "UNIT_SPELLCAST_INTERRUPTED" then
            R:OnCastAborted(unit)
        elseif event == "UNIT_SPELLCAST_STOP" then
            -- STOP arrive aussi après SUCCEEDED : s'il reste un pending, c'est
            -- que l'incantation a été annulée sans succès ni interruption.
            R:OnCastAborted(unit)
        end
    end)
end
