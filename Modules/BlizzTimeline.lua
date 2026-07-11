---@diagnostic disable: undefined-global
-- TomoBoss — Timeline Blizzard. Consomme l'API officielle C_EncounterTimeline
-- (Midnight) pour afficher/annoncer les capacités de boss de N'IMPORTE QUEL contenu
-- (donjons, raids), avec un minutage fourni par le jeu.
--
-- Struct EncounterTimelineEventInfo (tous NeverSecret sauf icons/severity enum) :
--   id, source (0=Encounter,1=Script,2=EditMode), spellName, spellID, iconFileID,
--   duration, maxQueueDuration, icons (masque rôle/effet), severity (0/1/2), isApproximate
-- icons : TankRole=0x80, HealerRole=0x100, DpsRole=0x200 (+ effets Deadly/Magic/...).

local NS = select(2, ...)
local BT = {}
NS.BlizzTimeline = BT

BT.active = {} -- id -> { endTime, sev, role, name, announced }

local bit_band = bit and bit.band

local function cfg() return NS.db.profile.blizzTimeline end

-- L'API est-elle disponible et activée (côté jeu) ?
function BT:Available()
    if not C_EncounterTimeline then return false end
    local ok, avail = pcall(C_EncounterTimeline.IsFeatureAvailable)
    return ok and avail == true
end

local function readInfo(idOrInfo)
    -- l'événement peut fournir directement la structure, ou un id
    if type(idOrInfo) == "table" then return idOrInfo end
    if not (C_EncounterTimeline and C_EncounterTimeline.GetEventInfo) then return nil end
    local ok, info = pcall(C_EncounterTimeline.GetEventInfo, idOrInfo)
    if ok and type(info) == "table" then return info end
    return nil
end

local function timeRemaining(id)
    if C_EncounterTimeline and C_EncounterTimeline.GetEventTimeRemaining then
        local ok, tr = pcall(C_EncounterTimeline.GetEventTimeRemaining, id)
        if ok and type(tr) == "number" then return tr end
    end
    return nil
end

local function roleFromIcons(icons)
    if not icons or not bit_band or NS:IsSecret(icons) then return nil end
    if bit_band(icons, 0x80) ~= 0 then return "tank" end
    if bit_band(icons, 0x100) ~= 0 then return "heal" end
    return nil
end

-- Annonce vocale selon rôle / sévérité (voix du pack français).
local function voiceFor(role, sev)
    if role == "tank" then return "tank-buster" end
    if role == "heal" then return "prepare-aoe" end
    if sev == 2 then return "watch-dodge" end
    return nil
end

--------------------------------------------------------------------------
-- Rendu d'un événement de la timeline.
--------------------------------------------------------------------------
function BT:Render(id, info, tr)
    local now = GetTime()
    -- toutes les valeurs de l'API timeline peuvent être masquées (secret) sous taint :
    -- on les nettoie systématiquement avant toute comparaison / affichage.
    local sev = NS:SafeNumber(info.severity)
    if sev == nil then sev = 1 end
    local dur = NS:SafeNumber(tr) or NS:SafeNumber(info.duration) or 5
    local endTime = now + dur
    local name = (info.spellName ~= nil and not NS:IsSecret(info.spellName)) and tostring(info.spellName) or "Capacité"
    local icon = NS:SafeNumber(info.iconFileID) or 134400

    local args = { name = name, icon = icon, duration = dur, endTime = endTime, severity = sev }
    local role = roleFromIcons(info.icons)
    self.active[id] = { endTime = endTime, sev = sev, role = role, name = name, announced = false }

    if cfg().bar then NS.UI.TimerBars:AddOrUpdate("bt:" .. id, args) end

    local ringWanted = cfg().ring
        or (NS.db.profile.rings.autoRole and (role == "tank" or role == "heal" or sev == 2))
    if ringWanted and NS.UI.Rings then
        NS.UI.Rings:AddOrUpdate("bt:" .. id, args)
    end
end

function BT:OnAdded(idOrInfo)
    if not cfg().enabled then return end
    local info = readInfo(idOrInfo)
    if not info then return end
    -- on ne garde que les événements issus de la rencontre (pas Script/EditMode)
    if info.source ~= nil and not NS:IsSecret(info.source) and info.source ~= 0 then return end
    local id = info.id or (type(idOrInfo) == "number" and idOrInfo)
    id = NS:SafeNumber(id)
    if not id then return end
    self:Render(id, info, timeRemaining(id))
end

function BT:OnStateChanged(idOrInfo)
    if not cfg().enabled then return end
    local info = readInfo(idOrInfo)
    if not info then return end
    local id = info.id or (type(idOrInfo) == "number" and idOrInfo)
    id = NS:SafeNumber(id)
    if id and self.active[id] then
        self:Render(id, info, timeRemaining(id))
    end
end

function BT:OnRemoved(idOrInfo)
    local id = (type(idOrInfo) == "table" and idOrInfo.id) or idOrInfo
    id = NS:SafeNumber(id)
    if not id then return end
    self.active[id] = nil
    NS.UI.TimerBars:Remove("bt:" .. id)
    if NS.UI.Rings then NS.UI.Rings:Remove("bt:" .. id) end
end

function BT:ClearAll()
    for id in pairs(self.active) do
        NS.UI.TimerBars:Remove("bt:" .. id)
        if NS.UI.Rings then NS.UI.Rings:Remove("bt:" .. id) end
    end
    wipe(self.active)
end

--------------------------------------------------------------------------
-- Boucle d'annonce (pré-alerte vocale + flash).
--------------------------------------------------------------------------
function BT:Tick()
    if not cfg().enabled or not cfg().voice then return end
    local now = GetTime()
    local lead = (NS.db and NS.db.profile.voice.lead) or 0
    for _, e in pairs(self.active) do
        if not e.announced and now >= (e.endTime - math.max(lead, 0.5)) then
            e.announced = true
            local id = voiceFor(e.role, e.sev)
            if id then NS.Voice:Play(id) end
            if e.sev == 2 then NS.UI.FlashText:Show(e.name, "danger", 2.0) end
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
    f:RegisterEvent("ENCOUNTER_END")
    f:SetScript("OnEvent", function(_, event, a1)
        if event == "ENCOUNTER_TIMELINE_EVENT_ADDED" then
            self:OnAdded(a1)
        elseif event == "ENCOUNTER_TIMELINE_EVENT_STATE_CHANGED" then
            self:OnStateChanged(a1)
        elseif event == "ENCOUNTER_TIMELINE_EVENT_REMOVED" then
            self:OnRemoved(a1)
        else -- STATE_UPDATED (reset) / ENCOUNTER_END
            self:ClearAll()
        end
    end)

    -- ticker léger pour les annonces
    f._acc = 0
    f:SetScript("OnUpdate", function(self2, e)
        self2._acc = self2._acc + e
        if self2._acc < 0.1 then return end
        self2._acc = 0
        BT:Tick()
    end)
end
