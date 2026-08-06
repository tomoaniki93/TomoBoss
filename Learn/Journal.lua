---@diagnostic disable: undefined-global
-- TomoBoss — Apprentissage / Journal des rencontres.
--
-- Source de vérité pour la correspondance nom de sort -> spellID, fournie par
-- Blizzard elle-même (API EJ_*). C'est ce qui remplace définitivement toute
-- donnée tierce : le Journal liste, pour chaque rencontre, ses capacités avec
-- leur spellID, leur nom localisé et leur icône.
--
-- Bonus : il donne aussi le nom localisé du boss, ce qui permet de lever
-- l'ambiguïté quand ENCOUNTER_START masque l'encounterID.

local NS = select(2, ...)
local J = {}
NS.Learn = NS.Learn or {}
NS.Learn.Journal = J

J._cache = {}   -- journalEncounterID -> { byName = {..}, list = {..} } | false
J._nmap  = nil  -- nom de rencontre (minuscules) -> journalEncounterID

local MAX_SECTION_DEPTH = 40   -- garde-fou : le Journal est un arbre, on borne la descente

local function safeCall(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b, c, d = pcall(fn, ...)
    if not ok then return nil end
    return a, b, c, d
end

--------------------------------------------------------------------------
-- Correspondance entre les DEUX espaces d'identifiants.
--------------------------------------------------------------------------
-- ENCOUNTER_START livre un **DungeonEncounterID** ; les fonctions EJ_* parlent
-- **JournalEncounterID**. Deux espaces distincts (Maisara : 3212 d'un côté,
-- 2810 de l'autre).
--
-- J'ai d'abord tenté de bâtir le pont via le dungeonEncounterID que la
-- documentation annonce en 7e retour de EJ_GetEncounterInfoByIndex. Vérifié en
-- jeu : ce retour vaut **nil** sur ce client. Le pont n'existe pas par cette
-- voie.
--
-- On passe donc par le NOM de la rencontre, que les deux mondes partagent et
-- que ENCOUNTER_START fournit déjà localisé. Un nom n'est retenu que s'il est
-- UNIQUE dans le Journal : en cas d'ambiguïté on rend nil, plutôt que de
-- risquer d'attribuer les capacités d'un autre boss.
function J:EnsureLoaded()
    if self._loaded ~= nil then return self._loaded end
    local loaded = false
    local C = C_AddOns
    if C and C.IsAddOnLoaded then
        local ok, v = pcall(C.IsAddOnLoaded, "Blizzard_EncounterJournal")
        loaded = ok and v or false
    end
    if not loaded and C and C.LoadAddOn then
        pcall(C.LoadAddOn, "Blizzard_EncounterJournal")
        local ok, v = pcall(C.IsAddOnLoaded, "Blizzard_EncounterJournal")
        loaded = ok and v or false
    end
    self._loaded = loaded
    return loaded
end

-- nom de rencontre (minuscules) -> journalEncounterID, uniquement si unique.
function J:BuildNameMap()
    if self._nmap ~= nil then return self._nmap or nil end
    self:EnsureLoaded()
    if not (EJ_GetNumTiers and EJ_SelectTier and EJ_GetInstanceByIndex
            and EJ_GetEncounterInfoByIndex) then
        self._nmap = false
        return nil
    end

    local map, dup = {}, {}
    local saved = safeCall(EJ_GetCurrentTier)
    local nTiers = safeCall(EJ_GetNumTiers) or 0

    for tier = 1, nTiers do
        safeCall(EJ_SelectTier, tier)
        for _, isRaid in ipairs({ false, true }) do
            local i = 1
            while true do
                local instID = safeCall(EJ_GetInstanceByIndex, i, isRaid)
                if not instID then break end
                local j = 1
                while true do
                    local name, _, journalID = safeCall(EJ_GetEncounterInfoByIndex, j, instID)
                    if not name then break end
                    local jid = NS:SafeNumber(journalID)
                    local key = type(name) == "string" and name:lower() or nil
                    if key and jid then
                        if map[key] and map[key] ~= jid then dup[key] = true
                        else map[key] = jid end
                    end
                    j = j + 1
                end
                i = i + 1
            end
        end
    end
    if saved then safeCall(EJ_SelectTier, saved) end

    for key in pairs(dup) do map[key] = nil end   -- ambiguïté -> on ne tranche pas

    local n = 0
    for _ in pairs(map) do n = n + 1 end
    self._mapSize, self._dupCount = n, 0
    for _ in pairs(dup) do self._dupCount = self._dupCount + 1 end
    if n == 0 then self._nmap = false; return nil end
    self._nmap = map
    return map
end

-- Nom de rencontre -> journalEncounterID.
function J:ToJournalID(encounterName)
    if type(encounterName) ~= "string" or encounterName == "" then return nil end
    local map = self:BuildNameMap()
    return map and map[encounterName:lower()] or nil
end

--------------------------------------------------------------------------
-- Diagnostic.
--------------------------------------------------------------------------
function J:Diagnose(sample)
    NS:Print("|cff8bd5caDiagnostic du Journal des rencontres|r")
    local loaded = self:EnsureLoaded()
    NS:Print("  Blizzard_EncounterJournal chargé : "
        .. (loaded and "|cff8bd5caoui|r" or "|cffe06c75non|r"))
    NS:Print("  EJ_GetNumTiers -> " .. tostring(safeCall(EJ_GetNumTiers)))

    self._nmap = nil
    local map = self:BuildNameMap()
    NS:Print(string.format("  Rencontres indexées par nom : %d  (%d nom(s) ambigu(s) écarté(s))",
        self._mapSize or 0, self._dupCount or 0))

    if sample then
        local jid = self:ToJournalID(sample)
        NS:Print(string.format("  « %s » -> journalID %s", tostring(sample), tostring(jid)))
        if jid then
            local ab = self:GetAbilities(sample)
            NS:Print("  capacités trouvées : " .. tostring(ab and #ab.list or 0))
        end
    else
        NS:Print("  Astuce : |cff8bd5ca/tmb learn journal <nom du boss>|r pour tracer une résolution.")
    end
end

--------------------------------------------------------------------------
-- Parcours des sections d'une rencontre.
--------------------------------------------------------------------------
-- Descend l'arbre des sections et collecte tout ce qui porte un spellID.
local function walkSection(sectionID, out, seen, depth)
    if not sectionID or depth > MAX_SECTION_DEPTH then return end
    if seen[sectionID] then return end
    seen[sectionID] = true

    local info = safeCall(C_EncounterJournal and C_EncounterJournal.GetSectionInfo, sectionID)
    if type(info) ~= "table" then return end

    local spellID = NS:SafeNumber(info.spellID)
    if spellID and spellID > 0 then
        local name, icon
        local si = safeCall(C_Spell and C_Spell.GetSpellInfo, spellID)
        if type(si) == "table" then
            name = si.name
            icon = si.iconID or si.originalIconID
        end
        -- le titre de la section est un bon repli quand les données de sort
        -- ne sont pas encore en cache client
        if not name or name == "" then name = info.title end
        if name and name ~= "" then
            out[#out + 1] = {
                spellID = spellID,
                name    = name,
                icon    = icon,
                title   = info.title,
            }
        end
    end

    walkSection(info.firstChildSectionID, out, seen, depth + 1)
    walkSection(info.siblingSectionID, out, seen, depth + 1)
end

-- Renvoie { byName = { [nom minuscule] = entrée }, list = { entrées } } pour une rencontre.
-- `encounterName` : le nom livré par ENCOUNTER_START.
function J:GetAbilities(encounterName)
    local encounterID = self:ToJournalID(encounterName)
    if not encounterID then return nil end
    local hit = self._cache[encounterID]
    if hit ~= nil then return hit or nil end

    if not (C_EncounterJournal and EJ_SelectEncounter) then
        self._cache[encounterID] = false
        return nil
    end

    -- EJ_SelectEncounter modifie l'état global du Journal : on le fait hors combat
    -- uniquement (appelé depuis Infer/Export, jamais depuis le Recorder).
    safeCall(EJ_SelectEncounter, encounterID)
    local _, _, _, rootSection = safeCall(EJ_GetEncounterInfo, encounterID)

    local list, seen = {}, {}
    walkSection(NS:SafeNumber(rootSection), list, seen, 0)

    if #list == 0 then
        self._cache[encounterID] = false
        return nil
    end

    local byName = {}
    for _, e in ipairs(list) do
        local k = e.name:lower()
        -- en cas de doublon on garde le premier (le plus haut dans l'arbre,
        -- donc en général la capacité principale plutôt qu'un sous-effet)
        if not byName[k] then byName[k] = e end
    end

    local res = { byName = byName, list = list }
    self._cache[encounterID] = res
    return res
end

-- Nom localisé du boss.
-- Le nom vient de l'enregistrement lui-même (ENCOUNTER_START), pas du Journal.
-- Conservé pour compatibilité : rend le nom tel quel s'il est connu du Journal.
function J:EncounterName(encounterName)
    return self:ToJournalID(encounterName) and encounterName or nil
end

-- nom de sort -> { spellID, name, icon } pour une rencontre donnée.
function J:ResolveSpell(encounterName, spellName)
    if type(spellName) ~= "string" or spellName == "" then return nil end
    local ab = self:GetAbilities(encounterName)
    if not ab then return nil end
    return ab.byName[spellName:lower()]
end

--------------------------------------------------------------------------
-- Identification de la rencontre en cours.
--------------------------------------------------------------------------
-- ENCOUNTER_START peut masquer l'encounterID sous Midnight. On recoupe alors
-- les rencontres candidates de l'instance (Data/DungeonMaps.lua) avec le nom
-- de l'unité boss, que le client expose en clair et déjà localisé.
function J:ResolveCurrentEncounter()
    local candidates = NS.CurrentEncounterCandidates()
    if not candidates or #candidates == 0 then return nil end
    if #candidates == 1 then return candidates[1] end

    local names = {}
    for i = 1, 8 do
        -- même piège qu'à Recorder.lua : le nom d'une unité boss peut être masqué
        local n = NS:SafeString(UnitName("boss" .. i))
        if n then names[#names + 1] = n:lower() end
    end
    if #names == 0 then return nil end

    for _, encID in ipairs(candidates) do
        -- Le nom de référence vient des données du moteur, indexées sur le même
        -- espace d'identifiants qu'ENCOUNTER_START. Interroger le Journal ici
        -- était voué à l'échec : il ne connaît pas ces IDs.
        local def = NS.Engine:GetEncounter(encID)
        local ejName = def and def.name
        if ejName then
            local lower = ejName:lower()
            for _, n in ipairs(names) do
                -- correspondance souple : « Ick » doit matcher « Ick et Krick »
                if lower == n or lower:find(n, 1, true) or n:find(lower, 1, true) then
                    return encID
                end
            end
        end
    end
    return nil
end

function J:ClearCache()
    wipe(self._cache)
    self._nmap, self._loaded, self._mapSize, self._dupCount = nil, nil, nil, nil
end
