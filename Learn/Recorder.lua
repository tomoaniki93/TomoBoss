---@diagnostic disable: undefined-global
-- TomoBoss — Apprentissage / Enregistreur.
--
-- Capture brute, sans interprétation, de deux flux pendant un combat de boss :
--
--   1. C_EncounterTimeline  -> le calendrier autoritatif du serveur.
--      Donne le minutage exact, mais l'identité du sort est souvent masquée.
--
--   2. UNIT_SPELLCAST_* sur boss1..8 -> le nom du sort, lisible en clair.
--      Donne l'identité, mais seulement au moment où le sort part.
--
-- Croisés hors combat par Learn/Infer.lua, ces deux flux donnent ce qu'aucun
-- des deux ne fournit seul : « telle durée de timeline = telle capacité ».
--
-- Le Recorder ne touche JAMAIS au combat log (taint définitif sous Midnight)
-- et ne fait aucun appel EJ_* en combat (EJ_SelectEncounter modifie un état global).

local NS = select(2, ...)
local R = {}
NS.Learn = NS.Learn or {}
NS.Learn.Recorder = R

local Store = NS.Learn.Store

local function cfg() return NS.db.profile.learn end

--------------------------------------------------------------------------
-- Lecture d'une incantation de boss.
--------------------------------------------------------------------------
-- Renvoie nom, durée (s). Le spellID est secretvalue sous Midnight : on ne
-- s'en sert pas. Le NOM, lui, reste lisible et déjà localisé.
local function readCast(unit, channel)
    local fn = channel and UnitChannelInfo or UnitCastingInfo
    local ok, name, _, _, startMS, endMS = pcall(fn, unit)
    if not ok or type(name) ~= "string" or name == "" then return nil end
    local s, e = NS:SafeNumber(startMS), NS:SafeNumber(endMS)
    local dur
    if s and e and e > s then dur = (e - s) / 1000 end
    return name, dur
end

--------------------------------------------------------------------------
-- Démarrage / arrêt.
--------------------------------------------------------------------------
function R:Begin(reason)
    if not cfg().enabled then return end
    if Store:IsRecording() then return end

    local instID = select(8, GetInstanceInfo())
    local bossName = UnitName("boss1")

    -- L'encounterID est résolu ICI, une seule fois, tant que les unités boss
    -- existent encore. Si le Journal ne tranche pas, on ouvre une clé synthétique
    -- que l'utilisateur rebranchera depuis l'IHM.
    local encID = self._pendingEncID or NS.Learn.Journal:ResolveCurrentEncounter()
    local key = Store:MakeKey(encID, instID, bossName)

    Store:BeginPull(key, { boss = bossName, inst = instID })
    self._pendingEncID = nil
    self._seenTL = {}
    NS:Debug("Apprentissage : enregistrement démarré (", reason, ") clé =", key)
end

function R:Finish(outcome)
    if not Store:IsRecording() then return end
    local key, n = Store:Commit(outcome)
    self._seenTL = nil
    if key and cfg().announce then
        NS:Print(string.format("Pull enregistré (%s) — %d pull(s) en base. |cff8bd5caTapez /tmb learn|r pour analyser.",
            tostring(key), n or 0))
    end
end

--------------------------------------------------------------------------
-- Flux 1 : timeline Blizzard.
--------------------------------------------------------------------------
function R:OnTimelineAdded(x)
    if not Store:IsRecording() then return end

    local info = x
    if type(info) ~= "table" and C_EncounterTimeline and C_EncounterTimeline.GetEventInfo then
        local ok, got = pcall(C_EncounterTimeline.GetEventInfo, x)
        info = ok and got or nil
    end
    if type(info) ~= "table" then return end

    -- même filtre que BlizzTimeline : on ignore les événements dont la source
    -- est un joueur (auras personnelles, etc.)
    if info.source ~= nil and not NS:IsSecret(info.source) and info.source ~= 0 then return end

    local id = NS:SafeNumber(info.id) or (type(x) == "number" and NS:SafeNumber(x))
    local dur = NS:SafeNumber(info.duration)
    if not dur then return end

    -- anti-doublon : le serveur peut ré-ADD le même événement
    if id then
        local now = GetTime()
        self._seenTL = self._seenTL or {}
        local last = self._seenTL[id]
        if last and (now - last) < 1.0 then return end
        self._seenTL[id] = now
    end

    -- `duration` sert d'IDENTITÉ (c'est l'intervalle de la capacité, ce que
    -- BlizzTimeline compare à nos données) ; `GetEventTimeRemaining` donne le
    -- MINUTAGE réel. Les deux sont nécessaires : sans le second, impossible de
    -- savoir quand l'événement retombe, donc impossible de le corréler au cast.
    local fire
    if id and C_EncounterTimeline and C_EncounterTimeline.GetEventTimeRemaining then
        local ok, tr = pcall(C_EncounterTimeline.GetEventTimeRemaining, id)
        local n = ok and NS:SafeNumber(tr)
        if n then fire = NS.round((GetTime() - Store.current.t0) + n, 2) end
    end

    Store:Add(Store.KIND_TIMELINE, dur, nil, fire)
end

--------------------------------------------------------------------------
-- Flux 2 : incantations de boss.
--------------------------------------------------------------------------
function R:OnBossCast(unit, channel)
    if not Store:IsRecording() then return end
    local name, dur = readCast(unit, channel)
    if not name then return end
    Store:Add(channel and Store.KIND_CHANNEL or Store.KIND_CAST, dur, name)
end

--------------------------------------------------------------------------
-- Init.
--------------------------------------------------------------------------
function R:Init()
    -- Frame « général » : cycle de combat + timeline.
    local f = CreateFrame("Frame")
    self.frame = f
    f:RegisterEvent("ENCOUNTER_START")
    f:RegisterEvent("ENCOUNTER_END")
    f:RegisterEvent("PLAYER_REGEN_ENABLED")
    f:RegisterEvent("ENCOUNTER_TIMELINE_EVENT_ADDED")
    f:SetScript("OnEvent", function(_, event, a1, a2, a3, a4, a5)
        if event == "ENCOUNTER_START" then
            -- l'événement se déclenche même quand l'ID est masqué : c'est notre
            -- ancre temporelle t0, et c'est la seule qui soit fiable.
            self._pendingEncID = NS:SafeNumber(a1)
            self:Begin("ENCOUNTER_START")
        elseif event == "ENCOUNTER_END" then
            local success = NS:SafeNumber(a5)
            self:Finish(success == 1 and "kill" or "wipe")
        elseif event == "PLAYER_REGEN_ENABLED" then
            -- filet de sécurité : ENCOUNTER_END n'arrive pas toujours (fuite, déco)
            self:Finish("abandon")
        elseif event == "ENCOUNTER_TIMELINE_EVENT_ADDED" then
            self:OnTimelineAdded(a1)
        end
    end)

    -- Frames « unités boss ».
    -- RegisterUnitEvent n'accepte QUE DEUX unités par appel : un seul frame
    -- réutilisé dans une boucle écraserait silencieusement ses propres filtres
    -- et ne surveillerait plus que la dernière paire. D'où quatre frames.
    self.unitFrames = {}
    for i = 1, 7, 2 do
        local uf = CreateFrame("Frame")
        local u1, u2 = "boss" .. i, "boss" .. (i + 1)
        uf:RegisterUnitEvent("UNIT_SPELLCAST_START", u1, u2)
        uf:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", u1, u2)
        uf:SetScript("OnEvent", function(_, event, unit)
            R:OnBossCast(unit, event == "UNIT_SPELLCAST_CHANNEL_START")
        end)
        self.unitFrames[#self.unitFrames + 1] = uf
    end
end
