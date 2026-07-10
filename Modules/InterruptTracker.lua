---@diagnostic disable: undefined-global
-- TomoBoss — Suivi des interruptions (donjons 5).
-- Affiche qui a utilisé son interruption (barre à la couleur de classe, icône du
-- sort d'interruption), une barre de recharge de la vôtre, et un décompte M+.
--
-- Détection SANS le journal de combat (restreint et bloquant sous Midnight) :
-- on écoute UNIT_SPELLCAST_SUCCEEDED du joueur et des membres du groupe, et on ne
-- retient que les sorts d'interruption connus. Les spellID des joueurs alliés
-- restent lisibles (seuls ceux des ennemis sont masqués).

local NS = select(2, ...)
local IT = {}
NS.InterruptTracker = IT

local RECORD_DURATION = 14
local DEFAULT_ICON = 132316 -- icône d'interruption générique

local function cfg() return NS.db.profile.interrupts end

--------------------------------------------------------------------------
-- Ensemble des spellID d'interruption connus (toutes spécialisations).
--------------------------------------------------------------------------
function IT:BuildSet()
    local set = {}
    for _, d in pairs(NS.Data.Interrupts) do
        if d.id and d.id ~= 0 then set[d.id] = true end
    end
    self.interruptSet = set
end

--------------------------------------------------------------------------
-- Environnement : uniquement en groupe dans un donjon 5 joueurs.
--------------------------------------------------------------------------
function IT:IsValidEnv()
    if not cfg().enabled then return false end
    local _, instanceType = GetInstanceInfo()
    return IsInGroup() and instanceType == "party"
end

local function ClassColor(classToken)
    if classToken and C_ClassColor and C_ClassColor.GetClassColor then
        local ok, c = pcall(C_ClassColor.GetClassColor, classToken)
        if ok and c then return { c.r, c.g, c.b } end
    end
    return { 0.8, 0.8, 0.8 }
end

--------------------------------------------------------------------------
-- Spécialisation du joueur -> sort d'interruption (pour la barre de recharge).
--------------------------------------------------------------------------
function IT:GetPlayerInterrupt()
    local idx = GetSpecialization and GetSpecialization()
    if not idx or idx <= 0 then return nil end
    local specID = select(1, GetSpecializationInfo(idx))
    if not specID then return nil end
    local data = NS.Data.Interrupts[specID]
    if not data or data.id == 0 then return nil end
    return data
end

--------------------------------------------------------------------------
-- Création du groupe de barres.
--------------------------------------------------------------------------
function IT:Init()
    if self.group then return end
    self:BuildSet()
    self.group = NS.UI.CreateBarGroup("Interrupts", cfg())
    self.group.demoFn = function(g, on)
        if on then
            local now = GetTime()
            g:AddOrUpdate("__d1", { name = "Vous",  duration = 15, endTime = now + 11, color = ClassColor(select(2, UnitClass("player"))), icon = DEFAULT_ICON })
            g:AddOrUpdate("__d2", { name = "Tomo",  duration = 14, endTime = now + 9,  color = { 0.78, 0.61, 0.43 }, icon = 132316 })
            g:AddOrUpdate("__d3", { name = "Aniki", duration = 14, endTime = now + 5,  color = { 0.41, 0.80, 0.94 }, icon = 132316 })
        else
            g:Remove("__d1"); g:Remove("__d2"); g:Remove("__d3")
        end
    end
    self:RegisterEvents()
end

--------------------------------------------------------------------------
-- Décompte M+ (nombre d'interruptions par joueur).
--------------------------------------------------------------------------
IT.tally = {}
IT.inMythicPlus = false

function IT:RecordTally(name)
    if not self.inMythicPlus or not name then return end
    self.tally[name] = (self.tally[name] or 0) + 1
end

function IT:PrintTally()
    local list = {}
    for name, n in pairs(self.tally) do list[#list + 1] = { name = name, n = n } end
    if #list == 0 then
        NS:Print("Aucune interruption enregistrée pour cette clé.")
        return
    end
    table.sort(list, function(a, b) return a.n > b.n end)
    NS:Print("|cff33e6a6Interruptions (clé en cours) :|r")
    for _, e in ipairs(list) do
        print(string.format("  |cffe6edea%s|r : |cff33e6a6%d|r", e.name, e.n))
    end
end

--------------------------------------------------------------------------
-- Interruption utilisée par un joueur (soi ou un membre du groupe).
--------------------------------------------------------------------------
local function isPartyUnit(unit)
    return unit == "player" or (type(unit) == "string" and unit:match("^party[1-4]$") ~= nil)
end

function IT:OnCastSucceeded(unit, spellID)
    if not self._envOK or not isPartyUnit(unit) then return end
    local sid = NS:SafeNumber(spellID)
    if not sid or not self.interruptSet[sid] then return end

    local name = UnitName(unit)
    if not name or NS:IsSecret(name) then return end
    name = name:match("^[^-]+") or name

    local _, classToken = UnitClass(unit)
    local icon = DEFAULT_ICON
    if C_Spell and C_Spell.GetSpellTexture then
        local ok, t = pcall(C_Spell.GetSpellTexture, sid)
        if ok and t then icon = t end
    end

    self._rec = (self._rec or 0) + 1
    local now = GetTime()
    self.group:AddOrUpdate("rec" .. self._rec, {
        name = name, icon = icon, color = ClassColor(classToken),
        duration = RECORD_DURATION, endTime = now + RECORD_DURATION,
    })
    self:RecordTally(name)

    -- barre de recharge de votre propre interruption
    if unit == "player" and cfg().showSelfCD then
        local d = self:GetPlayerInterrupt()
        if d and d.id == sid then
            self.group:AddOrUpdate("self", {
                name = "Vous", icon = icon,
                color = ClassColor(classToken),
                duration = d.cd, endTime = now + d.cd, fillAlpha = 0.35,
            })
        end
    end
end

--------------------------------------------------------------------------
-- Environnement + événements.
--------------------------------------------------------------------------
function IT:UpdateEnv()
    self._envOK = self:IsValidEnv()
    if self._envOK then
        self.group:EnsureAnchor()
    else
        if self.group then self.group:Clear() end
    end
end

function IT:RegisterEvents()
    local f = CreateFrame("Frame")
    self.frame = f
    f:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    f:RegisterEvent("CHALLENGE_MODE_START")
    f:SetScript("OnEvent", function(_, event, a1, a2, a3)
        if event == "UNIT_SPELLCAST_SUCCEEDED" then
            self:OnCastSucceeded(a1, a3)
        elseif event == "CHALLENGE_MODE_START" then
            wipe(self.tally); self.inMythicPlus = true; self:UpdateEnv()
        else -- PLAYER_ENTERING_WORLD / ZONE_CHANGED_NEW_AREA
            local _, instanceType = GetInstanceInfo()
            self.inMythicPlus = (instanceType == "party" and C_ChallengeMode
                and C_ChallengeMode.GetActiveKeystoneInfo and C_ChallengeMode.GetActiveKeystoneInfo() ~= nil) or false
            self:UpdateEnv()
        end
    end)
end

-- Rafraîchit le style après changement d'options.
function IT:Restyle()
    if self.group then self.group:Restyle() end
end
