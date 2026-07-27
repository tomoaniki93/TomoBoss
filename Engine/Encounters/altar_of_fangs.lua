---@diagnostic disable: undefined-global
-- TomoBoss — Donjon : Altar of Fangs (hors-saison Midnight, mapID 2993)
-- Données de MATCHING uniquement, générées depuis les branches de durée de
-- LittleWigs (ENCOUNTER_TIMELINE_EVENT_ADDED, modes Mythique et Normal/Héroïque
-- fusionnés). Aucune série de prédiction : la timeline Blizzard fournit déjà le
-- minutage — `matchOnly = true` empêche le moteur prédictif de démarrer dessus.
-- Rôles, voix et sévérités sont des valeurs par défaut, à affiner en jeu.

local NS = select(2, ...)
local R = function(id, def) NS.Engine:RegisterEncounter(id, def) end

-- Rav'i  (encounterID 3456)
R(3456, {
    name = "Rav'i",
    provenance = "littlewigs",
    dungeon = "Altar of Fangs",
    matchOnly = true,
    events = {
        { role = "other", voice = "watch-dodge", spellID = 1307703, firstSeenSec = 8, cdSeriesSec = { 8, 24 }, severity = 1 },  -- Triple Shot | AMBIGU : durée 24 partagée
        { role = "other", voice = "watch-dodge", spellID = 1296050, firstSeenSec = 13, cdSeriesSec = { 13 }, severity = 1 },  -- Regurgitate
        { role = "other", voice = "watch-shockwave", spellID = 1307894, firstSeenSec = 24, cdSeriesSec = { 24 }, severity = 1 },  -- Ravenous Stomp | AMBIGU : durée 24 partagée
        { role = "other", voice = "std-move", spellID = 1296216, firstSeenSec = 25, cdSeriesSec = { 25, 45 }, severity = 0 },  -- Ssscavenging
    },
})

-- The Writhing Coil  (encounterID 3457)
R(3457, {
    name = "The Writhing Coil",
    provenance = "littlewigs",
    dungeon = "Altar of Fangs",
    matchOnly = true,
    events = {
        { role = "other", voice = "prepare-dispel", spellID = 1299154, firstSeenSec = 1, cdSeriesSec = { 1, 10 }, severity = 1 },  -- Synchronized Venom | AMBIGU : durée 10 partagée
        { role = "other", voice = "std-move", spellID = 1298949, firstSeenSec = 7, cdSeriesSec = { 7, 16 }, severity = 0 },  -- Tail Scythe
        { role = "other", voice = "special-mechanic", spellID = 1310547, firstSeenSec = 10, cdSeriesSec = { 10 }, severity = 2 },  -- Toxic Atrophy | AMBIGU : durée 10 partagée
        { role = "other", voice = "watch-dodge", spellID = 1310357, firstSeenSec = 14, cdSeriesSec = { 14, 23 }, severity = 1 },  -- Preparing Toxin
        { role = "other", voice = "std-move", spellID = 1300686, firstSeenSec = 25, cdSeriesSec = { 25 }, severity = 0 },  -- Assimilation
        { role = "tank", voice = "tank-buster", spellID = 1299940, firstSeenSec = 30, cdSeriesSec = { 30, 39 }, severity = 1 },  -- Vindictive Onslaught
        { role = "other", voice = "special-mechanic", spellID = 1299053, firstSeenSec = 44, cdSeriesSec = { 44, 53 }, severity = 2 },  -- Death Rattle
    },
})

-- Zul'jan  (encounterID 3458)
R(3458, {
    name = "Zul'jan",
    provenance = "littlewigs",
    dungeon = "Altar of Fangs",
    matchOnly = true,
    events = {
        { role = "other", voice = "watch-dodge", spellID = 1301111, firstSeenSec = 14, cdSeriesSec = { 14 }, severity = 1 },  -- Axegrinder | AMBIGU : durée 14 partagée
        { role = "other", voice = "special-mechanic", spellID = 1301413, firstSeenSec = 14, cdSeriesSec = { 14, 32 }, severity = 2 },  -- Boneslicer | AMBIGU : durée 14 partagée
        { role = "other", voice = "std-move", spellID = 1301350, firstSeenSec = 26, cdSeriesSec = { 26, 30 }, severity = 0 },  -- Chop Down
        { role = "other", voice = "std-move", spellID = 1300876, firstSeenSec = 64, cdSeriesSec = { 64 }, severity = 0 },  -- Ritual of the Fang
    },
})
