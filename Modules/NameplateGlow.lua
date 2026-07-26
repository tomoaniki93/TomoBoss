---@diagnostic disable: undefined-global
-- TomoBoss — Halo de castbar sur les nameplates.
--
-- Fait briller la barre d'incantation d'un mob (sur sa plaque) quand son cast
-- est DANGEREUX. Deux critères, cumulables :
--   important       -> C_Spell.IsSpellImportant(spellID) : le jeu classe ce sort
--                      comme important (« létal s'il n'est pas interrompu »).
--   non interruptible -> le cast ne peut pas être coupé (à esquiver/gérer).
--
-- POURQUOI PAS « le cast me cible » : sous Midnight c'est verrouillé.
-- UnitSpellTargetName renvoie un secret, UnitIsUnit refuse les tokens nameplate
-- et targettarget. On s'appuie donc sur le flag d'importance du jeu, qui recoupe
-- l'essentiel de l'intention sans jamais toucher au ciblage.
--
-- LE PIÈGE DU SECRET : C_Spell.IsSpellImportant renvoie un BOOLÉEN SECRET.
-- `if important then glow:Show() end` LÈVE une erreur. On ne teste jamais la
-- valeur : le halo est monté en permanence, et sa TRANSPARENCE est pilotée par
-- Region:SetAlphaFromBoolean(secret) — le moteur consomme le secret sans jamais
-- l'exposer au Lua. Important -> alpha 1 (visible) ; sinon -> alpha 0 (invisible).

local NS = select(2, ...)
local NG = {}
NS.NameplateGlow = NG

local DEFAULT_COLOR = { 1.00, 0.30, 0.25 }   -- rouge « danger »
local PULSE_MIN, PULSE_MAX = 0.35, 1.0       -- amplitude du battement
local PULSE_SPEED = 3.2                       -- rad/s

NG._plates = {}      -- unitToken -> { plate, overlay, active }

local function cfg() return NS.db and NS.db.profile and NS.db.profile.nameplateGlow end

--------------------------------------------------------------------------
-- Disponibilité.
--------------------------------------------------------------------------
function NG:Available()
    -- le flag d'importance ET le pilotage anti-taint doivent exister
    if not (C_Spell and C_Spell.IsSpellImportant) then return false end
    local probe = _G.WorldFrame or UIParent
    return probe and type(probe.SetAlphaFromBoolean) == "function"
end

local function sameEnvAsTrash()
    if not cfg() or not cfg().enabled then return false end
    local _, itype = GetInstanceInfo()
    return itype == "party" or itype == "raid"
end

--------------------------------------------------------------------------
-- Construction / rendu du halo.
--------------------------------------------------------------------------
-- Repère la barre d'incantation dans la plaque Blizzard par défaut.
local function castBarOf(plate)
    local uf = plate and plate.UnitFrame
    if not uf then return nil end
    return uf.castBar or uf.CastBar or (uf.healthBar and uf.healthBar.castBar) or nil
end

-- Crée l'overlay + ses 4 bords (textures additives) une seule fois par barre.
local function ensureOverlay(entry, bar)
    if entry.overlay and entry.overlay._bar == bar then return entry.overlay end
    if entry.overlay then entry.overlay:Hide(); entry.overlay:SetParent(nil) end

    local ov = CreateFrame("Frame", nil, bar)
    ov._bar = bar
    ov:SetAllPoints(bar)
    ov:SetFrameLevel(bar:GetFrameLevel() + 5)
    ov:EnableMouse(false)

    local thick = 2
    local edges = {}
    for _, side in ipairs({ "TOP", "BOTTOM", "LEFT", "RIGHT" }) do
        local t = ov:CreateTexture(nil, "OVERLAY")
        t:SetColorTexture(1, 1, 1, 1)
        t:SetBlendMode("ADD")
        edges[#edges + 1] = t
    end
    edges[1]:SetPoint("TOPLEFT", ov, "TOPLEFT", 0, 0)
    edges[1]:SetPoint("TOPRIGHT", ov, "TOPRIGHT", 0, 0)
    edges[1]:SetHeight(thick)
    edges[2]:SetPoint("BOTTOMLEFT", ov, "BOTTOMLEFT", 0, 0)
    edges[2]:SetPoint("BOTTOMRIGHT", ov, "BOTTOMRIGHT", 0, 0)
    edges[2]:SetHeight(thick)
    edges[3]:SetPoint("TOPLEFT", ov, "TOPLEFT", 0, 0)
    edges[3]:SetPoint("BOTTOMLEFT", ov, "BOTTOMLEFT", 0, 0)
    edges[3]:SetWidth(thick)
    edges[4]:SetPoint("TOPRIGHT", ov, "TOPRIGHT", 0, 0)
    edges[4]:SetPoint("BOTTOMRIGHT", ov, "BOTTOMRIGHT", 0, 0)
    edges[4]:SetWidth(thick)
    ov._edges = edges

    -- battement : anime l'alpha DES BORDS, pas de l'overlay (dont l'alpha est
    -- réservé au pilotage secret via SetAlphaFromBoolean).
    ov._t = 0
    ov:SetScript("OnUpdate", function(self, dt)
        self._t = self._t + dt * PULSE_SPEED
        local a = PULSE_MIN + (PULSE_MAX - PULSE_MIN) * (0.5 + 0.5 * math.sin(self._t))
        for i = 1, #self._edges do self._edges[i]:SetAlpha(a) end
    end)

    entry.overlay = ov
    return ov
end

local function applyColor(ov)
    local c = (cfg() and cfg().color) or DEFAULT_COLOR
    for i = 1, #ov._edges do ov._edges[i]:SetVertexColor(c[1], c[2], c[3]) end
end

--------------------------------------------------------------------------
-- Décision : ce cast doit-il briller ? (sans jamais lire le secret)
--------------------------------------------------------------------------
-- Renvoie une VALEUR (éventuellement secrète) passée telle quelle à
-- SetAlphaFromBoolean. On combine importance et interruptibilité sans test Lua.
local function glowBoolean(spellID, notInterruptible)
    local c = cfg()
    local wantImportant = c.onImportant ~= false
    local wantLocked    = c.onUninterruptible == true

    -- Important : booléen secret. On ne le teste pas, on le renvoie.
    if wantImportant and spellID then
        local ok, imp = pcall(C_Spell.IsSpellImportant, spellID)
        if ok then
            if wantLocked then
                -- « important OU non interruptible » sans brancher sur un secret :
                -- si non-interruptible est déjà vrai (non secret ici), on force ;
                -- sinon on laisse le secret d'importance décider.
                if notInterruptible == true then return true end
            end
            return imp
        end
    end

    -- Repli : uniquement le critère non-interruptible (valeur non secrète).
    if wantLocked then
        return notInterruptible == true
    end
    return false
end

--------------------------------------------------------------------------
-- Application sur une plaque.
--------------------------------------------------------------------------
function NG:UpdatePlate(unit)
    if not self:Available() or not sameEnvAsTrash() then return end
    local plate = C_NamePlate and C_NamePlate.GetNamePlateForUnit and C_NamePlate.GetNamePlateForUnit(unit)
    if not plate then return end

    local name, _, _, _, _, _, _, notInterruptible, spellID = UnitCastingInfo(unit)
    if name == nil then
        name, _, _, _, _, _, notInterruptible, spellID = UnitChannelInfo(unit)
    end
    local entry = self._plates[unit] or {}
    self._plates[unit] = entry
    entry.plate = plate

    if name == nil then
        self:ClearPlate(unit)
        return
    end

    local bar = castBarOf(plate)
    if not bar then return end
    local ov = ensureOverlay(entry, bar)
    applyColor(ov)
    ov:Show()

    -- pilotage anti-taint : l'alpha de l'overlay (donc de ses bords) suit le
    -- booléen — potentiellement secret — sans qu'on le lise jamais.
    ov:SetAlphaFromBoolean(glowBoolean(spellID, notInterruptible))
    entry.active = true
end

function NG:ClearPlate(unit)
    local entry = self._plates[unit]
    if entry and entry.overlay then
        entry.overlay:SetAlpha(0)
        entry.overlay:Hide()
        entry.active = false
    end
end

function NG:ClearAll()
    for unit in pairs(self._plates) do self:ClearPlate(unit) end
end

--------------------------------------------------------------------------
-- Événements.
--------------------------------------------------------------------------
function NG:Init()
    if not self:Available() then
        NS:Debug("NameplateGlow : IsSpellImportant ou SetAlphaFromBoolean absent — module inactif.")
        return
    end
    local f = CreateFrame("Frame")
    self.frame = f
    f:RegisterEvent("UNIT_SPELLCAST_START")
    f:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
    f:RegisterEvent("UNIT_SPELLCAST_STOP")
    f:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
    f:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    f:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    f:RegisterEvent("NAME_PLATE_UNIT_ADDED")
    f:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:SetScript("OnEvent", function(_, event, unit)
        if event == "PLAYER_ENTERING_WORLD" then
            self:ClearAll()
            return
        end
        if type(unit) ~= "string" or unit:match("^nameplate%d+$") == nil then return end
        if event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START"
            or event == "NAME_PLATE_UNIT_ADDED" then
            self:UpdatePlate(unit)
        else
            -- STOP / CHANNEL_STOP / INTERRUPTED / SUCCEEDED / NAME_PLATE_UNIT_REMOVED
            self:ClearPlate(unit)
        end
    end)
end

--------------------------------------------------------------------------
-- Diagnostic : /tmb glow
--------------------------------------------------------------------------
function NG:Report()
    if not self:Available() then
        NS:Print("Halo castbar : |cffff6b6bindisponible|r (IsSpellImportant ou SetAlphaFromBoolean absent).")
        return
    end
    local c = cfg()
    NS:Print("Halo castbar — ", c.enabled and "|cff33e6a6actif|r" or "|cffff6b6bcoupé|r",
        " | important : ", c.onImportant ~= false and "oui" or "non",
        " | non interruptible : ", c.onUninterruptible and "oui" or "non")
    local n = 0
    for _, e in pairs(self._plates) do if e.active then n = n + 1 end end
    NS:Print("  plaques suivies : ", n)
end
