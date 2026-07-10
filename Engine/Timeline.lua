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

local function leadFor(ev)
    local base = NS.db and NS.db.profile and NS.db.profile.voice.lead or 0
    return math.max(base or 0, ev.preAlertSec or 0)
end

-- Cadre pour la synchronisation sur les incantations réelles des boss.
function T:EnsureCastFrame()
    if self.castFrame then return self.castFrame end
    local f = CreateFrame("Frame")
    f:SetScript("OnEvent", function(_, event, unit, _, spellID)
        if self.running then self:OnBossCast(unit, spellID) end
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
        }
        self.occ[#self.occ + 1] = occ
        NS.UI.TimerBars:AddOrUpdate(occ.key, {
            name = NameFor(ev), icon = IconFor(ev),
            duration = occ.duration, endTime = occ.fireAt, severity = ev.severity,
        })
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
        local lead = leadFor(ev)

        -- annonce vocale (+ flash) juste avant l'impact
        if not occ.voiced and now >= (occ.fireAt - lead) then
            occ.voiced = true
            NS.Voice:Play(ev.voice)
            if ev.severity == 2 then
                NS.UI.FlashText:Show(ev.name, "danger", 2.2)
            end
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

        -- maintient la barre à jour
        NS.UI.TimerBars:AddOrUpdate(occ.key, {
            name = NameFor(ev), icon = IconFor(ev),
            duration = occ.duration, endTime = occ.fireAt, severity = ev.severity,
        })
    end
end

--------------------------------------------------------------------------
-- Synchronisation sur incantation réelle du boss.
-- En WoW Midnight les spellID de UNIT_SPELLCAST_* sont masqués (secretvalue) :
-- on ne resynchronise que si l'id est lisible, sinon on garde la prédiction.
--------------------------------------------------------------------------
function T:OnBossCast(unit, spellID)
    local sid = NS:SafeNumber(spellID)
    if not sid then return end -- id masqué -> on s'appuie sur la timeline prédite

    for _, occ in ipairs(self.occ) do
        local ev = occ.ev
        if ev.spellID == sid then
            local now = GetTime()
            occ.fireAt = now + (ev.castDuration or 0)
            occ.duration = math.max(0.1, ev.castDuration or occ.duration)
            occ.voiced = true
            NS.Voice:Play(ev.voice)
            if ev.severity == 2 then
                NS.UI.FlashText:Show(ev.name, "danger", 2.2)
            end
            NS.UI.TimerBars:AddOrUpdate(occ.key, {
                name = NameFor(ev), icon = IconFor(ev),
                duration = occ.duration, endTime = occ.fireAt, severity = ev.severity,
            })
            break
        end
    end
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
