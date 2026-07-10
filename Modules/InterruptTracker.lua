---@diagnostic disable: undefined-global
-- TomoBoss — Suivi des interruptions (donjons 5).
-- Affiche qui a interrompu (barre à la couleur de classe, icône du sort coupé),
-- une barre de recharge de votre propre interruption, et un décompte M+.

local NS = select(2, ...)
local IT = {}
NS.InterruptTracker = IT

local RECORD_DURATION = 14
local DEFAULT_ICON = 132316 -- icône d'interruption générique
local bit_band = bit and bit.band

local function cfg() return NS.db.profile.interrupts end

--------------------------------------------------------------------------
-- Environnement : uniquement en groupe dans un donjon 5 joueurs.
--------------------------------------------------------------------------
function IT:IsValidEnv()
    if not cfg().enabled then return false end
    local _, instanceType = GetInstanceInfo()
    return IsInGroup() and instanceType == "party"
end

--------------------------------------------------------------------------
-- Correspondance GUID -> classe (membres du groupe), pour la couleur.
--------------------------------------------------------------------------
IT.classByGUID = {}
function IT:RefreshRoster()
    wipe(self.classByGUID)
    local units = { "player", "party1", "party2", "party3", "party4" }
    for _, u in ipairs(units) do
        if UnitExists(u) then
            local guid = UnitGUID(u)
            local _, classToken = UnitClass(u)
            if guid and classToken and not NS:IsSecret(guid) then
                self.classByGUID[guid] = classToken
            end
        end
    end
end

local function ClassColor(classToken)
    if classToken and C_ClassColor and C_ClassColor.GetClassColor then
        local ok, c = pcall(C_ClassColor.GetClassColor, classToken)
        if ok and c then return { c.r, c.g, c.b } end
    end
    return { 0.8, 0.8, 0.8 }
end

--------------------------------------------------------------------------
-- Spécialisation du joueur -> sort d'interruption.
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
    self.group = NS.UI.CreateBarGroup("Interrupts", cfg())
    self.group.demoFn = function(g, on)
        if on then
            local now = GetTime()
            g:AddOrUpdate("__d1", { name = "Vous",   duration = 15, endTime = now + 11, color = ClassColor(select(2, UnitClass("player"))), icon = DEFAULT_ICON })
            g:AddOrUpdate("__d2", { name = "Tomo",    duration = 14, endTime = now + 9,  color = { 0.78, 0.61, 0.43 }, icon = 132316 })
            g:AddOrUpdate("__d3", { name = "Aniki",   duration = 14, endTime = now + 5,  color = { 0.41, 0.80, 0.94 }, icon = 132316 })
        else
            g:Remove("__d1"); g:Remove("__d2"); g:Remove("__d3")
        end
    end
    self:RefreshRoster()
    self:RegisterEvents()
end

--------------------------------------------------------------------------
-- Décompte M+ (nombre d'interruptions par joueur).
--------------------------------------------------------------------------
IT.tally = {}
IT.inMythicPlus = false

local function safeName(v)
    if v == nil or NS:IsSecret(v) then return nil end
    local s = tostring(v)
    if s == "" then return nil end
    return (s:match("^[^-]+")) or s
end

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
-- Ajout d'un enregistrement d'interruption.
--------------------------------------------------------------------------
function IT:AddRecord(interrupterGUID, interrupterName, interruptedSpellID)
    if not self.group then return end
    local classToken = interrupterGUID and self.classByGUID[interrupterGUID]
    local icon = DEFAULT_ICON
    local sid = NS:SafeNumber(interruptedSpellID)
    if sid and C_Spell and C_Spell.GetSpellTexture then
        local ok, t = pcall(C_Spell.GetSpellTexture, sid)
        if ok and t then icon = t end
    end
    self._rec = (self._rec or 0) + 1
    local now = GetTime()
    self.group:AddOrUpdate("rec" .. self._rec, {
        name = interrupterName,
        icon = icon,
        color = ClassColor(classToken),
        duration = RECORD_DURATION,
        endTime = now + RECORD_DURATION,
    })
end

--------------------------------------------------------------------------
-- Barre de recharge de votre propre interruption.
--------------------------------------------------------------------------
function IT:StartSelfCD()
    if not cfg().showSelfCD or not self.group then return end
    local data = self:GetPlayerInterrupt()
    if not data then return end
    local now = GetTime()
    self.group:AddOrUpdate("self", {
        name = "Vous",
        icon = (C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(data.id)) or DEFAULT_ICON,
        color = ClassColor(select(2, UnitClass("player"))),
        duration = data.cd,
        endTime = now + data.cd,
        fillAlpha = 0.35,
    })
end

--------------------------------------------------------------------------
-- Événements.
--------------------------------------------------------------------------
function IT:HandleCLEU()
    if not self._envOK then return end
    local info = { CombatLogGetCurrentEventInfo() }
    local sub = info[2]
    if sub ~= "SPELL_INTERRUPT" then return end
    local sourceGUID, sourceName, sourceFlags = info[4], info[5], info[6]
    local extraSpellID = info[15]

    if NS:IsSecret(sourceFlags) then return end
    if bit_band and sourceFlags then
        local isPlayer = bit_band(sourceFlags, COMBATLOG_OBJECT_TYPE_PLAYER or 0) ~= 0
        local mine = bit_band(sourceFlags, (COMBATLOG_OBJECT_AFFILIATION_MINE or 0)
            + (COMBATLOG_OBJECT_AFFILIATION_PARTY or 0) + (COMBATLOG_OBJECT_AFFILIATION_RAID or 0)) ~= 0
        if not (isPlayer and mine) then return end
    end

    local name = safeName(sourceName)
    if not name then return end
    self:RecordTally(name)
    self:AddRecord(sourceGUID, name, extraSpellID)
end

function IT:HandleSelfSucceeded(unit, spellID)
    if unit ~= "player" or not self._envOK then return end
    local data = self:GetPlayerInterrupt()
    if not data then return end
    local sid = NS:SafeNumber(spellID)
    if sid and sid == data.id then
        self:StartSelfCD()
    end
end

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
    f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    f:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    f:RegisterEvent("GROUP_ROSTER_UPDATE")
    f:RegisterEvent("CHALLENGE_MODE_START")
    f:SetScript("OnEvent", function(_, event, a1, a2, a3)
        if event == "COMBAT_LOG_EVENT_UNFILTERED" then
            self:HandleCLEU()
        elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
            self:HandleSelfSucceeded(a1, a3)
        elseif event == "GROUP_ROSTER_UPDATE" then
            self:RefreshRoster(); self:UpdateEnv()
        elseif event == "CHALLENGE_MODE_START" then
            wipe(self.tally); self.inMythicPlus = true; self:UpdateEnv()
        else -- PLAYER_ENTERING_WORLD / ZONE_CHANGED_NEW_AREA
            local _, instanceType = GetInstanceInfo()
            self.inMythicPlus = (instanceType == "party" and C_ChallengeMode
                and C_ChallengeMode.GetActiveKeystoneInfo and C_ChallengeMode.GetActiveKeystoneInfo() ~= nil) or false
            self:RefreshRoster(); self:UpdateEnv()
        end
    end)
end

-- Rafraîchit le style après changement d'options.
function IT:Restyle()
    if self.group then self.group:Restyle() end
end
