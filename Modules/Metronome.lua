---@diagnostic disable: undefined-global
-- TomoBoss — Métronome de groupe.
--
-- Joue un son à intervalle régulier tant qu'un joueur désigné est dans le
-- groupe ET que l'on est en combat, SAUF pendant une rencontre de boss.
--
-- Le son est purement local : rien n'est envoyé au joueur désigné, sa présence
-- sert seulement de déclencheur côté client.
--
-- Trois conditions doivent être réunies simultanément. Chacune est suivie par
-- son propre événement plutôt que sondée, et toute transition réévalue l'état :
--   présence   GROUP_ROSTER_UPDATE
--   combat     PLAYER_REGEN_DISABLED / PLAYER_REGEN_ENABLED
--   hors boss  ENCOUNTER_START / ENCOUNTER_END
--
-- L'exclusion des boss est doublée par IsEncounterInProgress() : un /reload en
-- plein combat de boss fait manquer ENCOUNTER_START, et le métronome se
-- déclencherait pendant la rencontre — exactement ce qu'on veut éviter.

local addonName, NS = ...
if type(NS) ~= "table" then return end

local M = {}
NS.Metronome = M

local SOUND_PATH = "Interface\\AddOns\\TomoBoss\\Media\\Sounds\\"

local function cfg() return NS.db and NS.db.profile and NS.db.profile.metronome end

--------------------------------------------------------------------------
-- Présence du joueur déclencheur
--------------------------------------------------------------------------
-- Compare le nom court ET le nom complet. GetUnitName(unit, true) renvoie
-- « Nom-Royaume » seulement pour un joueur d'un autre royaume : sur le même
-- royaume il renvoie « Nom » tout court. Accepter les deux formes évite au
-- réglage de dépendre du royaume de celui qui l'écrit.
local function unitMatches(unit, wanted)
    local full = GetUnitName and GetUnitName(unit, true) or UnitName(unit)
    full = NS:SafeString(full)
    if not full or NS:IsSecret(full) then return false end
    full = full:lower()
    if wanted[full] then return true end
    local short = full:match("^[^-]+")
    return short ~= nil and wanted[short] == true
end

function M:TriggerPresent()
    local c = cfg()
    if not c or not c.names then return false end

    local wanted, any = {}, false
    for name, on in pairs(c.names) do
        if on and type(name) == "string" and name ~= "" then
            wanted[name:lower()] = true
            -- Un réglage écrit « Taluani-Varimathras » doit aussi reconnaître
            -- le joueur quand il est sur notre royaume et ne porte que « Taluani ».
            local short = name:lower():match("^[^-]+")
            if short then wanted[short] = true end
            any = true
        end
    end
    if not any then return false end

    if IsInRaid and IsInRaid() then
        for i = 1, (GetNumGroupMembers and GetNumGroupMembers() or 0) do
            if unitMatches("raid" .. i, wanted) then return true end
        end
    elseif IsInGroup and IsInGroup() then
        for i = 1, 4 do
            if UnitExists("party" .. i) and unitMatches("party" .. i, wanted) then return true end
        end
    end
    -- Le joueur lui-même compte : utile pour tester le réglage seul.
    return unitMatches("player", wanted)
end

--------------------------------------------------------------------------
-- Conditions et bascule
--------------------------------------------------------------------------
local function inBossFight()
    if NS.Metronome._encounter then return true end
    return IsEncounterInProgress and IsEncounterInProgress() == true
end

function M:ShouldRun()
    local c = cfg()
    if not c or not c.enabled then return false end
    if inBossFight() then return false end
    if not (InCombatLockdown and InCombatLockdown()) then return false end
    return self:TriggerPresent()
end

function M:Play()
    local c = cfg()
    if not c then return end
    self._ticks = (self._ticks or 0) + 1
    self._lastPlay = GetTime()
    local file = SOUND_PATH .. ((c.sound or "Top") .. ".ogg")
    local channel = c.channel
        or (NS.db.profile.ui and NS.db.profile.ui.general and NS.db.profile.ui.general.soundChannel)
        or "Master"
    if not PlaySoundFile then return end
    local willPlay = PlaySoundFile(file, channel)
    self._lastFile, self._lastOK = file, willPlay
    -- Averti une seule fois : un fichier manquant ne doit pas inonder le chat
    -- à chaque battement.
    if willPlay == false and not self._warned then
        self._warned = true
        if NS.Print then NS:Print("métronome : fichier introuvable — " .. file) end
    end
end

function M:Update()
    local run = self:ShouldRun()
    if run and not self._ticker then
        local c = cfg()
        local period = tonumber(c and c.interval) or 10
        if period < 1 then period = 1 end
        -- Premier battement immédiat : attendre une période entière donnerait
        -- l'impression que le réglage ne marche pas.
        self:Play()
        self._ticker = C_Timer.NewTicker(period, function() M:Play() end)
    elseif not run and self._ticker then
        self._ticker:Cancel()
        self._ticker = nil
    end
end

function M:Restart()
    if self._ticker then self._ticker:Cancel(); self._ticker = nil end
    self:Update()
end

--------------------------------------------------------------------------
-- Événements
--------------------------------------------------------------------------
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("GROUP_ROSTER_UPDATE")
f:RegisterEvent("PLAYER_REGEN_DISABLED")
f:RegisterEvent("PLAYER_REGEN_ENABLED")
f:RegisterEvent("ENCOUNTER_START")
f:RegisterEvent("ENCOUNTER_END")
f:SetScript("OnEvent", function(_, event)
    if event == "ENCOUNTER_START" then
        M._encounter = true
    elseif event == "ENCOUNTER_END" then
        M._encounter = false
    end
    M:Update()
end)

M._frame = f

--------------------------------------------------------------------------
-- Diagnostic — /tmb metro
--------------------------------------------------------------------------
-- Trois conditions doivent tenir ensemble ; quand le métronome se tait, la
-- seule question utile est LAQUELLE manque. Le rapport les donne toutes plutôt
-- que de laisser deviner.
function M:Report()
    local c = cfg()
    local function yn(v) return v and "|cff8bd5caoui|r" or "|cffed8796non|r" end

    NS:Print("— métronome —")
    if not c then NS:Print("  configuration absente (profil non migré ?)"); return end

    NS:Print(string.format("  activé          : %s", yn(c.enabled)))
    NS:Print(string.format("  intervalle      : %s s", tostring(c.interval or 10)))

    local names = {}
    for n, on in pairs(c.names or {}) do if on then names[#names + 1] = n end end
    table.sort(names)
    NS:Print(string.format("  noms configurés : %s",
        #names > 0 and table.concat(names, ", ") or "|cffed8796aucun|r"))

    -- Ce que le client voit réellement du groupe : c'est ici que se cache la
    -- plupart des cas « ça ne se déclenche pas ».
    local seen = {}
    local function note(unit)
        if not UnitExists(unit) then return end
        local full = GetUnitName and GetUnitName(unit, true) or UnitName(unit)
        full = NS:SafeString(full)
        if not full then seen[#seen + 1] = unit .. "=<illisible>"
        elseif NS:IsSecret(full) then seen[#seen + 1] = unit .. "=<secret>"
        else seen[#seen + 1] = unit .. "=" .. full end
    end
    note("player")
    if IsInRaid and IsInRaid() then
        for i = 1, (GetNumGroupMembers and GetNumGroupMembers() or 0) do note("raid" .. i) end
    else
        for i = 1, 4 do note("party" .. i) end
    end
    NS:Print("  groupe vu       : " .. (#seen > 0 and table.concat(seen, "  ") or "seul"))

    NS:Print(string.format("  joueur présent  : %s", yn(self:TriggerPresent())))
    NS:Print(string.format("  en combat       : %s", yn(InCombatLockdown and InCombatLockdown())))
    NS:Print(string.format("  rencontre boss  : %s  (drapeau %s, API %s)",
        yn(inBossFight()), tostring(self._encounter),
        tostring(IsEncounterInProgress and IsEncounterInProgress())))
    NS:Print(string.format("  minuteur actif  : %s", yn(self._ticker ~= nil)))
    NS:Print(string.format("  battements      : %d", self._ticks or 0))
    if self._lastPlay then
        NS:Print(string.format("  dernier         : il y a %.0f s  (%s, lecture %s)",
            GetTime() - self._lastPlay, tostring(self._lastFile), tostring(self._lastOK)))
    end
end

-- Joue le son une fois, hors de toute condition — pour vérifier le fichier.
function M:Test()
    self._warned = nil
    self:Play()
end
