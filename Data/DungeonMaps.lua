---@diagnostic disable: undefined-global
-- TomoBoss — Correspondance instanceMapID -> rencontres (pour identifier le boss
-- actif à partir de la timeline Blizzard, sans dépendre d'ENCOUNTER_START).

local NS = select(2, ...)

NS.DUNGEON_ENCOUNTERS = {
    [658]  = { 1999, 2000, 2001 },       -- Fosse de Saron
    [1209] = { 1698, 1699, 1700, 1701 }, -- Cime-du-ciel
    [1753] = { 2065, 2066, 2067, 2068 }, -- Siège du Triumvirat
    [2526] = { 2562, 2563, 2564, 2565 }, -- Académie d'Algeth'ar
    [2805] = { 3056, 3057, 3058, 3059 }, -- Flèche des Coursevent
    [2811] = { 3071, 3072, 3073, 3074 }, -- Terrasse des Magistères
    [2874] = { 3212, 3213, 3214 },       -- Cavernes de Maisara
    [2915] = { 3328, 3332, 3333 },       -- Point-Nexus Xenas
}

-- Rencontres candidates pour l'instance courante (les deux identifiants possibles).
function NS.CurrentEncounterCandidates()
    local a = select(8, GetInstanceInfo()) -- instanceMapID
    local b = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    return NS.DUNGEON_ENCOUNTERS[a] or NS.DUNGEON_ENCOUNTERS[b], (a or b)
end
