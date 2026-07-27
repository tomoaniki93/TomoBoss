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

J._cache = {}   -- encounterID -> { byName = {..}, list = {..} } | false

local MAX_SECTION_DEPTH = 40   -- garde-fou : le Journal est un arbre, on borne la descente

local function safeCall(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b, c, d = pcall(fn, ...)
    if not ok then return nil end
    return a, b, c, d
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
function J:GetAbilities(encounterID)
    encounterID = NS:SafeNumber(encounterID)
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
function J:EncounterName(encounterID)
    encounterID = NS:SafeNumber(encounterID)
    if not encounterID then return nil end
    local n = safeCall(EJ_GetEncounterInfo, encounterID)
    if type(n) == "string" and n ~= "" then return n end
    return nil
end

-- nom de sort -> { spellID, name, icon } pour une rencontre donnée.
function J:ResolveSpell(encounterID, spellName)
    if type(spellName) ~= "string" or spellName == "" then return nil end
    local ab = self:GetAbilities(encounterID)
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
        local ejName = self:EncounterName(encID)
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
end
