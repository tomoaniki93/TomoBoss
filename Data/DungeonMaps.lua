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

    -- Donjons hors-saison Midnight (données de matching uniquement, matchOnly)
    [2813]  = { 3101, 3102, 3103, 3105 }, -- Murder Row
    [2825]  = { 3207, 3208, 3209 },       -- Den of Nalorakk
    [2859]  = { 3199, 3200, 3201, 3202 }, -- The Blinding Vale
    [2923]  = { 3285, 3286, 3287 },       -- Voidscar Arena
    [2993]  = { 3456, 3457, 3458 },       -- Altar of Fangs
    [16865] = { 3456, 3457, 3458 },       -- Altar of Fangs (id alternatif relevé dans BossReminder)

    -- Donjons de la saison 2 (contenu recyclé — données de matching)
    [1877 ] = { 2124, 2125, 2126, 2127 }, -- Temple of Sethraliss
    [1030 ] = { 2124, 2125, 2126, 2127 }, -- Temple of Sethraliss (id alternatif BossReminder)
    [1762 ] = { 2139, 2140, 2142, 2143 }, -- Kings' Rest
    [1041 ] = { 2139, 2140, 2142, 2143 }, -- Kings' Rest (id alternatif BossReminder)
    [2521 ] = { 2606, 2609, 2623 }, -- Ruby Life Pools

    -- Raids (bridgeOnly : aucun minutage, exploités via l'EventBridge)
    [1592 ] = { 3159 }, -- Sporefall
    [2912 ] = { 3176, 3177, 3178, 3179, 3180, 3181 }, -- The Voidspire
    [2913 ] = { 3182, 3183 }, -- March on Quel'Danas
    [2939 ] = { 3306 }, -- The Dreamrift
}

-- Rencontres candidates pour l'instance courante (les deux identifiants possibles).
function NS.CurrentEncounterCandidates()
    local a = select(8, GetInstanceInfo()) -- instanceMapID
    local b = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    return NS.DUNGEON_ENCOUNTERS[a] or NS.DUNGEON_ENCOUNTERS[b], (a or b)
end
