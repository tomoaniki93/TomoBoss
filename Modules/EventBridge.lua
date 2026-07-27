---@diagnostic disable: undefined-global
-- TomoBoss — EventBridge (Midnight 12.0+).
--
-- Au lieu d'annoncer depuis Lua (boucle BT:Tick, avance calculée, dérive possible),
-- on confie le fichier son au JEU via C_EncounterEvents.SetEventSound. Le client
-- le déclenche lui-même au bon instant : zéro latence, zéro taint, et ça continue
-- de fonctionner quand les restrictions d'encounter masquent tout le reste.
--
-- SÉMANTIQUE DES TRIGGERS (doc Blizzard, EncounterEventsSharedDocumentation) :
--   0 OnTextWarningShown       -> l'avertissement texte s'affiche
--   1 OnTimelineEventFinished  -> la capacité part (trop tard pour réagir)
--   2 OnTimelineEventHighlight -> ~5 s avant l'incantation      <= CELUI QU'ON VEUT
-- Attention : les commentaires de BossReminder inversent 1 et 2.
--
-- LIMITE ASSUMÉE : le trigger 2 est câblé à ~5 s côté client, il n'est pas réglable.
-- Pour les events repris par le pont, le curseur « Avance des annonces » et le
-- preAlertSec de la capacité n'ont donc plus d'effet. C'est le prix de l'exactitude ;
-- couper le pont rend la main au chemin Lua.
--
-- SetEventSound / SetEventColor sont marquées SecretArguments = "NotAllowed" :
-- on ne leur passe que des nombres validés par NS:SafeNumber.

local NS = select(2, ...)
local EB = {}
NS.EventBridge = EB

-- Triggers son
local SND_TEXT_WARNING = 0
local SND_FINISHED     = 1
local SND_HIGHLIGHT    = 2
-- Triggers couleur
local CLR_TEXT_WARNING = 0
local CLR_TIMELINE     = 1
local CLR_HIGHLIGHT    = 2

local BATCH_INTERVAL = 0.05

EB.batchSize   = 200  -- events posés par passe (abaissable pour les tests)
EB._registered = {}   -- [eventID] = true : ce qu'on a posé, pour pouvoir nettoyer
EB._willPlay   = {}   -- [eventID] = true : le jeu jouera un son -> Lua doit se taire
EB._gen        = 0    -- génération, annule les lots encore en vol
EB._count      = 0

local function cfg() return NS.db and NS.db.profile and NS.db.profile.eventBridge end

--------------------------------------------------------------------------
-- Disponibilité.
--------------------------------------------------------------------------
function EB:Available()
    return C_EncounterEvents ~= nil and C_EncounterEvents.SetEventSound ~= nil
end

local function colorAvailable()
    return C_EncounterEvents ~= nil and C_EncounterEvents.SetEventColor ~= nil
end

-- Le client connaît-il cet eventID ? Indispensable : les eventID ne sont PAS
-- uniques d'une instance à l'autre (802 existe dans Den of Nalorakk ET
-- The Voidspire). Ce filtre, combiné au cadrage par instance, évite d'écraser
-- le son d'une capacité d'un autre donjon.
local function knownEvent(eventID)
    if not (C_EncounterEvents and C_EncounterEvents.HasEventInfo) then return true end
    local ok, exists = pcall(C_EncounterEvents.HasEventInfo, eventID)
    return ok and exists == true
end

--------------------------------------------------------------------------
-- Résolution du son (mêmes règles que NS.Voice:Play, y compris le repli de pack).
--------------------------------------------------------------------------
local function soundPath(voiceID)
    if type(voiceID) ~= "string" or voiceID == "" then return nil end
    local LSM = NS.LSM
    if not (LSM and NS.Voice and NS.Voice.Catalog and NS.Voice.Catalog[voiceID]) then return nil end
    local def  = NS.VOICE_DEFAULT_PACK or "frFR"
    local lang = NS.CurrentVoicePack and NS.CurrentVoicePack() or def
    local p = LSM:Fetch("sound", NS.VoiceKey(lang, voiceID), true)
    if not p and lang ~= def then
        p = LSM:Fetch("sound", NS.VoiceKey(def, voiceID), true)
    end
    return p
end

-- Voix générique par sévérité, alignée sur le mode générique de BlizzTimeline.
local function genericVoiceID(sev)
    local bt = NS.db and NS.db.profile and NS.db.profile.blizzTimeline
    if not (bt and bt.generic) then return nil end
    local id
    if sev == 0 then id = bt.genericTank
    elseif sev == 2 then id = bt.genericDanger
    else id = bt.genericOther end
    if type(id) == "string" and id ~= "" then return id end
    return nil
end

-- Renvoie le chemin du son à confier au jeu pour cet événement, ou nil.
function EB:ResolvePath(ev)
    if not ev then return nil end
    local c = cfg()
    if not (c and c.enabled and c.sounds) then return nil end
    local v = NS.db.profile.voice
    if not (v and v.enabled) then return nil end
    local p = soundPath(ev.voice)
    if p then return p end
    if c.genericFallback then
        return soundPath(genericVoiceID(NS:SafeNumber(ev.severity) or 1))
    end
    return nil
end

local SEV_COLOR = {
    [0] = { 0.40, 0.85, 1.00 },   -- info / tank
    [1] = { 1.00, 0.82, 0.00 },   -- normal
    [2] = { 1.00, 0.30, 0.25 },   -- danger
}

--------------------------------------------------------------------------
-- Collecte : uniquement les rencontres de l'instance courante.
--------------------------------------------------------------------------
function EB:Collect()
    local out, seen = {}, {}
    local list = NS.CurrentEncounterCandidates and NS.CurrentEncounterCandidates()
    if not list then return out end
    for _, encID in ipairs(list) do
        local def = NS.Engine and NS.Engine:GetEncounter(encID)
        if def and def.events then
            for _, ev in ipairs(def.events) do
                local eid = NS:SafeNumber(ev.eventID)
                if eid and not seen[eid] then
                    seen[eid] = true
                    out[#out + 1] = { eventID = eid, ev = ev, encID = encID }
                end
            end
        end
    end
    return out
end

--------------------------------------------------------------------------
-- Pose / retrait.
--------------------------------------------------------------------------
local function applyOne(entry)
    local c = cfg()
    local eid, ev = entry.eventID, entry.ev
    if not knownEvent(eid) then return false end

    local done = false

    if c.sounds then
        local path = EB:ResolvePath(ev)
        if path then
            local vol = NS.clamp((NS.db.profile.voice.boost or 100) / 100, 0.1, 3.0)
            local info = {
                file    = path,
                channel = NS.db.profile.voice.channel or "Master",
                volume  = vol,   -- vrai gain, contrairement à l'empilement de PlaySoundFile
            }
            local trig = (c.trigger == 0 or c.trigger == 1) and c.trigger or SND_HIGHLIGHT
            if pcall(C_EncounterEvents.SetEventSound, eid, trig, info) then
                EB._willPlay[eid] = true
                done = true
            end
        end
    end

    if c.colors and colorAvailable() and CreateColor then
        local rgb = SEV_COLOR[NS:SafeNumber(ev.severity) or 1]
        if rgb then
            local col = CreateColor(rgb[1], rgb[2], rgb[3], 1)
            pcall(C_EncounterEvents.SetEventColor, eid, CLR_TIMELINE, col)
            pcall(C_EncounterEvents.SetEventColor, eid, CLR_HIGHLIGHT, col)
            done = true
        end
    end

    if done then EB._registered[eid] = true end
    return done
end

function EB:Clear(reason)
    if self:Available() then
        for eid in pairs(self._registered) do
            pcall(C_EncounterEvents.SetEventSound, eid, SND_TEXT_WARNING, nil)
            pcall(C_EncounterEvents.SetEventSound, eid, SND_FINISHED, nil)
            pcall(C_EncounterEvents.SetEventSound, eid, SND_HIGHLIGHT, nil)
            if colorAvailable() then
                pcall(C_EncounterEvents.SetEventColor, eid, CLR_TEXT_WARNING, nil)
                pcall(C_EncounterEvents.SetEventColor, eid, CLR_TIMELINE, nil)
                pcall(C_EncounterEvents.SetEventColor, eid, CLR_HIGHLIGHT, nil)
            end
        end
    end
    wipe(self._registered)
    wipe(self._willPlay)
    self._count = 0
    self._gen = self._gen + 1        -- invalide tout lot encore en vol
    if reason then NS:Debug("EventBridge : nettoyé (", reason, ")") end
end

function EB:Apply(reason)
    local c = cfg()
    if not (c and c.enabled) then return false, "désactivé" end
    if not self:Available() then return false, "C_EncounterEvents indisponible" end

    local _, itype = GetInstanceInfo()
    if itype ~= "party" and itype ~= "raid" then
        self:Clear("hors instance")
        return false, "hors instance"
    end

    -- l'avertissement texte doit être actif côté client, sinon rien ne se déclenche
    if c.forceCVar and C_CVar and C_CVar.GetCVar then
        local ok, val = pcall(C_CVar.GetCVar, "encounterWarningsEnabled")
        if ok and val == "0" then pcall(C_CVar.SetCVar, "encounterWarningsEnabled", "1") end
    end

    -- une pose effective rend caduque toute demande mise de côté
    self._deferred = nil

    self:Clear()                     -- incrémente _gen
    local gen = self._gen
    local entries = self:Collect()
    if #entries == 0 then return false, "aucun event pour cette instance" end

    -- pose par lots : 334 appels d'un coup provoquent un à-coup à l'entrée
    local i = 1
    local function nextBatch()
        if gen ~= EB._gen then return end          -- une autre passe a pris la main
        local last = math.min(i + EB.batchSize - 1, #entries)
        for k = i, last do
            if applyOne(entries[k]) then EB._count = EB._count + 1 end
        end
        i = last + 1
        if i <= #entries then C_Timer.After(BATCH_INTERVAL, nextBatch) end
    end
    nextBatch()

    NS:Debug("EventBridge : ", #entries, " events candidats (", tostring(reason), ")")
    return true
end

--------------------------------------------------------------------------
-- API consommée par BlizzTimeline.
--------------------------------------------------------------------------

-- Le jeu jouera-t-il lui-même la voix pour cet événement ? Si oui, le chemin Lua
-- DOIT rester muet, sinon l'annonce part deux fois.
function EB:WillPlaySound(ev)
    if not ev then return false end
    local eid = NS:SafeNumber(ev.eventID)
    return eid ~= nil and self._willPlay[eid] == true
end

function EB:Count() return self._count end

--------------------------------------------------------------------------
-- Rafraîchissement sur changement de configuration.
--------------------------------------------------------------------------
-- Ce qui est posé côté jeu dépend de la config AU MOMENT de la pose : chemin
-- du fichier (pack de langue, voix activée, repli générique), volume, canal,
-- déclencheur, couleurs. Sans re-pose, changer le pack vocal ou le volume en
-- plein donjon laissait le jeu jouer les ANCIENS fichiers à l'ANCIEN volume
-- jusqu'au prochain changement de zone.
--
-- Deux précautions :
--   * anti-rebond, parce qu'un glissement de curseur émet des dizaines
--     d'appels et qu'une pose représente plusieurs centaines d'entrées ;
--   * report hors combat. Apply() commence par Clear(), ce qui vide _willPlay :
--     re-poser pendant une rencontre ferait momentanément croire à
--     BlizzTimeline que le jeu ne joue plus rien, et l'annonce partirait en
--     double. On attend donc la fin du combat.
local REFRESH_DELAY = 0.4

function EB:Refresh(reason)
    if not self.frame then return end          -- module inactif
    self._pending = reason or "config"
    if self._scheduled then return end
    self._scheduled = true
    C_Timer.After(REFRESH_DELAY, function()
        EB._scheduled = false
        local r = EB._pending
        EB._pending = nil
        if not r then return end
        if InCombatLockdown() then
            EB._deferred = r
            NS:Debug("EventBridge : re-pose reportée à la fin du combat (", r, ")")
            return
        end
        EB:Apply(r)
    end)
end

--------------------------------------------------------------------------
-- Diagnostic : /tmb bridge
--------------------------------------------------------------------------
function EB:Report()
    if not self:Available() then
        NS:Print("EventBridge : |cffff6b6bC_EncounterEvents indisponible sur ce client.|r")
        return
    end
    local c = cfg()
    local name, itype = GetInstanceInfo()
    local entries = self:Collect()
    local resolved, unknown = 0, 0
    for _, e in ipairs(entries) do
        if not knownEvent(e.eventID) then unknown = unknown + 1
        elseif self:ResolvePath(e.ev) then resolved = resolved + 1 end
    end
    local trig = (c.trigger == 0 or c.trigger == 1) and c.trigger or SND_HIGHLIGHT
    local trigName = ({ [0] = "avertissement texte", [1] = "capacité lancée",
                        [2] = "~5 s avant (highlight)" })[trig]
    NS:Print("EventBridge — ", c.enabled and "|cff33e6a6actif|r" or "|cffff6b6bcoupé|r",
        " | instance : ", tostring(name), " (", tostring(itype), ")")
    NS:Print("  events de l'instance : ", #entries,
        " | voix résolue : ", resolved,
        " | inconnus du client : ", unknown,
        " | posés : ", self._count)
    NS:Print("  déclencheur : ", trig, " — ", trigName)
end

--------------------------------------------------------------------------
-- Init.
--------------------------------------------------------------------------
--------------------------------------------------------------------------
-- Commandes.
--------------------------------------------------------------------------
-- Les réglages du pont existaient en base sans aucun moyen de les changer en
-- jeu. Chaque bascule déclenche une re-pose : sans elle, le réglage n'aurait
-- d'effet qu'au prochain changement de zone.
local function onOff(word, current)
    if word == "on" or word == "oui" then return true end
    if word == "off" or word == "non" then return false end
    return not current
end

function EB:HandleSlash(rest)
    local sub, arg = tostring(rest or ""):match("^(%S*)%s*(%S*)$")
    local c = cfg()

    if sub == "" then
        self:Report()
        NS:Print("  |cff8bd5ca/tmb bridge on|off|r  |cff8bd5cason|r  |cff8bd5cacouleurs|r  "
            .. "|cff8bd5cadeclencheur 0|1|2|r  |cff8bd5careposer|r")
    elseif sub == "on" or sub == "off" then
        c.enabled = (sub == "on")
        if c.enabled then self:Refresh("activation") else self:Clear("désactivé") end
        NS:Print("Pont : " .. (c.enabled and "|cff8bd5caactif|r" or "|cffe06c75coupé|r"))
    elseif sub == "son" or sub == "sons" then
        c.sounds = onOff(arg, c.sounds)
        self:Refresh("sons")
        NS:Print("Sons confiés au jeu : " .. (c.sounds and "oui" or "non"))
    elseif sub == "couleurs" or sub == "colors" then
        c.colors = onOff(arg, c.colors)
        self:Refresh("couleurs")
        NS:Print("Teinte des barres Blizzard : " .. (c.colors and "oui" or "non"))
    elseif sub == "generique" or sub == "generic" then
        c.genericFallback = onOff(arg, c.genericFallback)
        self:Refresh("repli générique")
        NS:Print("Voix générique de repli : " .. (c.genericFallback and "oui" or "non"))
    elseif sub == "declencheur" or sub == "trigger" then
        local n = tonumber(arg)
        if n ~= 0 and n ~= 1 and n ~= 2 then
            NS:Print("Usage : |cff8bd5ca/tmb bridge declencheur 0|1|2|r "
                .. "(0 avertissement texte, 1 capacité lancée, 2 ~5 s avant)")
            return
        end
        c.trigger = n
        self:Refresh("déclencheur")
        NS:Print("Déclencheur : " .. n)
    elseif sub == "reposer" or sub == "refresh" then
        self:Refresh("manuel")
        NS:Print("Re-pose demandée.")
    else
        self:Report()
    end
end

function EB:Init()
    if not self:Available() then
        NS:Debug("EventBridge : C_EncounterEvents absent — module inactif.")
        return
    end
    local f = CreateFrame("Frame")
    self.frame = f
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    f:RegisterEvent("PLAYER_REGEN_ENABLED")
    f:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_ENABLED" then
            -- une re-pose demandée pendant le combat a été mise de côté
            local r = EB._deferred
            if r then
                EB._deferred = nil
                C_Timer.After(0.2, function() EB:Apply(r) end)
            end
            return
        end
        C_Timer.After(0.3, function() EB:Apply("changement de zone") end)
    end)
    C_Timer.After(0.5, function() EB:Apply("init") end)
end
