---@diagnostic disable: undefined-global
-- TomoBoss — TrashCD : barres d'incantation des capacités importantes des packs.
-- SÉLECTION DES INCANTATIONS — refondue pour Midnight.
--
-- L'ancienne version filtrait par npcID, extrait de UnitGUID. Or UnitGUID est
-- MASQUÉ sous Midnight : NpcID rendait nil, et le handler sortait dès sa
-- deuxième ligne. Le module ne montrait donc jamais rien en donjon, quelle que
-- soit la qualité de la base de données.
--
-- Trois critères le remplacent, tous lisibles même sous masquage, et combinés
-- par un OU — une incantation retenue par n'importe lequel s'affiche :
--
--   1. IMPORTANTE — C_Spell.IsSpellImportant : le jeu lui-même classe le sort
--      comme notable. C'est le critère le plus fiable et il ne demande aucune
--      donnée de notre part.
--   2. ME VISE — l'incantation prend le joueur pour cible. En clé, un sort qui
--      vous vise personnellement compte davantage que tout le reste.
--   3. BASE — l'ancien filtre par npcID, conservé pour les rares cas où le GUID
--      reste lisible. Ne coûte rien et ne peut que compléter.
--
-- Le npcID n'est donc plus une CONDITION mais un bonus.

local NS = select(2, ...)
local TC = {}
NS.TrashCD = TC

TC.Dungeons = TC.Dungeons or {}

local COLOR_KICK = { 1.00, 0.55, 0.20 } -- interruptible (orange « à couper »)
local COLOR_LOCK = { 0.40, 0.72, 1.00 } -- non interruptible (bleu)
local COLOR_ONME = { 1.00, 0.30, 0.35 } -- dirigé sur le joueur (rouge)

-- Période de ré-évaluation du ciblage (voir TC:WatchTargets).
-- DÉCLARÉE ICI, avec les autres constantes : un `local` n'existe qu'à partir de
-- sa ligne, et TC:Init l'utilise bien plus haut dans le fichier. Déclarée près
-- de la fonction qui la commente, elle valait nil à l'initialisation — le
-- ticker levait une erreur et toute l'initialisation s'arrêtait là.
local WATCH_PERIOD = 0.25
local DEFAULT_ICON = 134400

local function cfg() return NS.db.profile.trash end

--------------------------------------------------------------------------
-- Enregistrement / fusion des données par donjon.
--------------------------------------------------------------------------
function TC:RegisterDungeon(mapID, def)
    mapID = tonumber(mapID)
    if not mapID or type(def) ~= "table" then return end
    local d = self.Dungeons[mapID]
    if not d then
        self.Dungeons[mapID] = def
        return
    end
    -- fusion : ajoute/complète les mobs et sorts
    d.mobs = d.mobs or {}
    for npc, mob in pairs(def.mobs or {}) do
        if not d.mobs[npc] then
            d.mobs[npc] = mob
        else
            d.mobs[npc].spells = d.mobs[npc].spells or {}
            for sid, sp in pairs(mob.spells or {}) do
                d.mobs[npc].spells[sid] = sp
            end
        end
    end
end

--------------------------------------------------------------------------
-- Environnement : donjon 5 joueurs disposant de données.
--------------------------------------------------------------------------
function TC:CurrentMapID()
    local id = select(8, GetInstanceInfo())
    return tonumber(id)
end

function TC:IsValidEnv()
    if not cfg().enabled then return false end
    local _, instanceType = GetInstanceInfo()
    if not (IsInGroup() and instanceType == "party") then return false end
    self.currentMap = self.Dungeons[self:CurrentMapID()]
    return self.currentMap ~= nil
end

--------------------------------------------------------------------------
-- Création du groupe de barres.
--------------------------------------------------------------------------
function TC:Init()
    if self.group then return end
    self.group = NS.UI.CreateBarGroup("Trash", cfg())
    self.group.demoFn = function(g, on)
        if on then
            local now = GetTime()
            g:AddOrUpdate("__d1", { name = "Cryoburst",     duration = 5, endTime = now + 4, color = COLOR_KICK, icon = 135848 })
            g:AddOrUpdate("__d2", { name = "Focused Guard", duration = 6, endTime = now + 5, color = COLOR_LOCK, icon = 135834 })
        else
            g:Remove("__d1"); g:Remove("__d2")
        end
    end
    self:RegisterEvents()

    -- ticker de suivi du ciblage
    if not self._watch then
        self._watch = C_Timer.NewTicker(WATCH_PERIOD, function() TC:WatchTargets() end)
    end
end

--------------------------------------------------------------------------
-- Utilitaires.
--------------------------------------------------------------------------
local function NpcID(guid)
    if not guid or NS:IsSecret(guid) then return nil end
    local id = select(6, strsplit("-", guid))
    return tonumber(id)
end

-- Le jeu classe-t-il ce sort comme important ?
--
-- C'est Blizzard qui décide, donc aucune
-- base à maintenir et une couverture automatique sur tout le contenu, y compris
-- les donjons que nous n'avons pas encore renseignés.
local function IsImportant(spellID)
    local fn = C_Spell and C_Spell.IsSpellImportant
    if not fn or not spellID then return false end
    local ok, v = pcall(fn, spellID)
    if not ok or NS:IsSecret(v) then return false end
    return v == true
end

-- L'incantation vise-t-elle le joueur ?
--
-- Le jeton de cible d'une unité s'obtient en suffixant « target ». Il reste
-- lisible sous Midnight, contrairement au GUID : c'est une comparaison d'unités
-- faite par le client, pas une valeur qu'on inspecte.
local function TargetsPlayer(unit)
    local ok, same = pcall(UnitIsUnit, unit .. "target", "player")
    if not ok or NS:IsSecret(same) then return false end
    return same == true
end

local function IsTrackedUnit(unit)
    if type(unit) ~= "string" then return false end
    return unit:match("^nameplate%d+$") ~= nil or unit:match("^boss%d+$") ~= nil
end

-- Lit les infos d'incantation (gère les valeurs masquées).
local function ReadCast(unit, isChannel)
    local name, _, texture, startMS, endMS, _, a7, a8
    if isChannel then
        name, _, texture, startMS, endMS, _, a7, a8 = UnitChannelInfo(unit)
    else
        name, _, texture, startMS, endMS, _, _, a7, a8 = UnitCastingInfo(unit)
    end
    local notInterruptible = a7
    if NS:IsSecret(notInterruptible) then notInterruptible = nil end
    local spellID = a8
    -- durée / fin (avec repli si masqué)
    local s = NS:SafeNumber(startMS)
    local e = NS:SafeNumber(endMS)
    local endTime, duration
    if s and e and e > s then
        endTime = e / 1000
        duration = (e - s) / 1000
    end
    local safeName = (name ~= nil and not NS:IsSecret(name)) and tostring(name) or nil
    return safeName, texture, endTime, duration, notInterruptible, spellID
end

--------------------------------------------------------------------------
-- Gestion d'une incantation de pack.
--------------------------------------------------------------------------
function TC:OnCastStart(unit, isChannel)
    if not self._envOK or not self.currentMap then return end
    if not IsTrackedUnit(unit) then return end

    local liveName, texture, endTime, duration, notInterruptible, spellID = ReadCast(unit, isChannel)
    local sid = NS:SafeNumber(spellID)

    -- npcID quand il est lisible : bonus, plus une condition
    local npc = NpcID(UnitGUID(unit))
    local mob = npc and self.currentMap.mobs[npc] or nil
    local spInfo = (mob and sid) and mob.spells[sid] or nil

    -- 1. le jeu classe-t-il ce sort comme important ?
    local important = sid and IsImportant(sid) or false

    -- 2. l'incantation vise-t-elle le joueur ?
    local onMe = TargetsPlayer(unit)

    -- 3. la base le connaît-elle ?
    local known = spInfo ~= nil
    -- mob connu dont le sort n'est pas répertorié : on écarte, la base fait foi
    if mob and sid and not spInfo then return end

    if not (important or onMe or known) then return end
    -- filtre volontaire : ne garder que ce que le jeu juge important, plus ce
    -- qui vous vise. Utile sur les packs bavards où tout s'affiche.
    if cfg().onlyImportant and not (important or onMe) then return end

    -- nom : live -> nameEN -> résolu -> repli
    local displayName = liveName
    if not displayName and spInfo then displayName = spInfo.nameEN end
    if not displayName then displayName = NS.L.CF_CAST_CAST end

    -- durée : live -> base -> défaut
    if not duration then
        local base = spInfo and (spInfo.channelTime or spInfo.castTime)
        duration = base or 3
        endTime = GetTime() + duration
    end

    local interruptible = (notInterruptible ~= true)
    local color = interruptible and COLOR_KICK or COLOR_LOCK
    -- une incantation dirigée sur le joueur prime visuellement sur le reste
    if onMe then color = COLOR_ONME end

    -- mémorisé pour la ré-évaluation du ciblage (voir WatchTargets)
    self._active = self._active or {}
    self._active[unit] = {
        name = displayName, icon = texture or DEFAULT_ICON,
        duration = duration, endTime = endTime,
        interruptible = interruptible, onMe = onMe,
    }

    self.group:AddOrUpdate("u:" .. unit, {
        name = displayName,
        icon = texture or DEFAULT_ICON,
        color = color,
        duration = duration,
        endTime = endTime,
    })

    if interruptible and cfg().voiceOnKick then
        NS.Voice:Play("interrupt-now")
    end

    -- extras d'entrées personnalisées liées à ce mob (voix dédiée / anneau)
    if NS.Custom and NS.Custom.TrashExtras then
        local c = NS.Custom:TrashExtras(self:CurrentMapID(), npc, liveName, sid)
        if c and c.display then
            if c.display.sound and c.voice then NS.Voice:Play(c.voice) end
            if c.display.ring and NS.UI.Rings then
                NS.UI.Rings:AddOrUpdate("u:" .. unit, {
                    name = displayName, icon = texture or DEFAULT_ICON,
                    color = color, duration = duration, endTime = endTime,
                })
            end
        end
    end
end

function TC:OnCastEnd(unit)
    if self._active then self._active[unit] = nil end
    if self.group then self.group:Remove("u:" .. tostring(unit)) end
    if NS.UI.Rings then NS.UI.Rings:Remove("u:" .. tostring(unit)) end
end

--------------------------------------------------------------------------
-- Suivi du ciblage pendant l'incantation.
--------------------------------------------------------------------------
-- Un mob change de cible en cours d'incantation : un sort qui ne vous visait
-- pas au départ peut vous viser une seconde plus tard. Évaluer le ciblage une
-- seule fois, au début, raterait précisément les cas qui comptent.
--
-- On ré-évalue donc à intervalle court. Le coût est négligeable — quelques
-- appels UnitIsUnit sur les incantations en cours, jamais sur toutes les
-- plaques — et seule la couleur change, sans reconstruire la barre.
function TC:WatchTargets()
    if not self._active then return end
    if not self.group then return end
    for unit, a in pairs(self._active) do
        local now = TargetsPlayer(unit)
        if now ~= a.onMe then
            a.onMe = now
            local color = now and COLOR_ONME
                or (a.interruptible and COLOR_KICK or COLOR_LOCK)
            self.group:AddOrUpdate("u:" .. unit, {
                name = a.name, icon = a.icon, color = color,
                duration = a.duration, endTime = a.endTime,
            })
            -- Une incantation qui se retourne vers vous mérite d'être annoncée.
            -- « target-on-you » existe déjà dans les deux packs vocaux : aucun
            -- fichier à produire, et la formulation convient exactement.
            if now and cfg().voiceOnMe then NS.Voice:Play("target-on-you") end
        end
    end
end

--------------------------------------------------------------------------
-- Environnement + événements.
--------------------------------------------------------------------------
function TC:UpdateEnv()
    self._envOK = self:IsValidEnv()
    if self._envOK then
        self.group:EnsureAnchor()
    else
        if self.group then self.group:Clear() end
    end
end

function TC:RegisterEvents()
    local f = CreateFrame("Frame")
    self.frame = f
    f:RegisterEvent("UNIT_SPELLCAST_START")
    f:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
    f:RegisterEvent("UNIT_SPELLCAST_STOP")
    f:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
    f:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    f:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    f:RegisterEvent("GROUP_ROSTER_UPDATE")
    f:RegisterEvent("NAME_PLATE_UNIT_REMOVED") -- mob mort/hors de portée : retire sa barre
    f:SetScript("OnEvent", function(_, event, unit)
        if event == "UNIT_SPELLCAST_START" then
            self:OnCastStart(unit, false)
        elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
            self:OnCastStart(unit, true)
        elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_CHANNEL_STOP"
            or event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_SUCCEEDED" then
            if IsTrackedUnit(unit) then self:OnCastEnd(unit) end
        elseif event == "NAME_PLATE_UNIT_REMOVED" then
            -- la plaque disparaît (mort ou hors de portée) sans toujours émettre
            -- UNIT_SPELLCAST_STOP : on retire la barre pour éviter un fantôme.
            self:OnCastEnd(unit)
        else -- changement de zone / groupe
            self:UpdateEnv()
        end
    end)
end

function TC:Restyle()
    if self.group then self.group:Restyle() end
end

-- Nombre de donjons chargés (pour l'à-propos / debug).
function TC:CountDungeons()
    local n = 0
    for _ in pairs(self.Dungeons) do n = n + 1 end
    return n
end
