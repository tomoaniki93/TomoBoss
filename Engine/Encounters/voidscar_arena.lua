---@diagnostic disable: undefined-global
-- TomoBoss — Donjon : Voidscar Arena / Arène de la cicatrice du vide
--
-- Données de MATCHING générées depuis les captures TomoBoss (module Learn).
-- Chaque durée ci-dessous a été observée au moins 3 fois sur
-- ENCOUNTER_TIMELINE_EVENT_ADDED en jeu. Aucune source tierce.
--
-- `matchOnly = true` : le minutage vient de C_EncounterTimeline, ces valeurs
-- ne servent qu'à identifier la capacité. Rôles, voix et sévérités sont des
-- choix éditoriaux conservés depuis la version précédente.

local NS = select(2, ...)
local R = function(id, def) NS.Engine:RegisterEncounter(id, def) end

-- Taz'Rah  (encounterID 3285) — 3 pull(s) capturé(s)
R(3285, {
    name = "Taz'Rah",
    provenance = "observed",
    dungeon = "Voidscar Arena",
    matchOnly = true,
    events = {
        { role = "other", voice = "dodge-charge", spellID = 1222098, firstSeenSec = 6, cdSeriesSec = { 6 }, severity = 2 },  -- Nether Dash  [vu 6×9]
        { role = "other", voice = "watch-dodge", spellID = 1296963, firstSeenSec = 16, cdSeriesSec = { 16 }, severity = 1 },  -- Umbral Rupture  [vu 16×9]
        { role = "other", voice = "std-move", spellID = 1297017, firstSeenSec = 25, cdSeriesSec = { 25 }, severity = 0 },  -- Void Blast  [vu 25×9]
        { role = "other", voice = "watch-dodge", spellID = 1300259, firstSeenSec = 31, cdSeriesSec = { 31 }, severity = 1 },  -- Dark Bloom  [vu 31×9]
    },
})

-- Atroxus  (encounterID 3286) — 3 pull(s) capturé(s)
R(3286, {
    name = "Atroxus",
    provenance = "observed",
    dungeon = "Voidscar Arena",
    matchOnly = true,
    events = {
        { role = "other", voice = "prepare-dispel", spellID = 1226120, firstSeenSec = 5, cdSeriesSec = { 5, 20 }, severity = 1 },  -- Poison Splash | AMBIGU : durée 20 partagée  [vu 5×7 20×14]
        { role = "tank", voice = "tank-buster", spellID = 1222642, eventID = 911, firstSeenSec = 10, cdSeriesSec = { 10, 20 }, severity = 2 },  -- Hulking Claw | AMBIGU : durée 20 partagée  [vu 10×7 20×14]
        { role = "other", voice = "watch-frontal", spellID = 1222721, firstSeenSec = 15, cdSeriesSec = { 15, 30 }, severity = 2 },  -- Noxious Breath  [vu 15×7 30×7]
        { role = "other", voice = "prepare-interrupt", spellID = 1262497, firstSeenSec = 35, cdSeriesSec = { 35 }, severity = 0 },  -- Monstrous Roar  [vu 35×7]
    },
})

-- Charonus  (encounterID 3287) — 2 pull(s) capturé(s)
R(3287, {
    name = "Charonus",
    provenance = "observed",
    dungeon = "Voidscar Arena",
    matchOnly = true,
    events = {
        { role = "other", voice = "watch-dodge", spellID = 1282770, firstSeenSec = 5, cdSeriesSec = { 5 }, severity = 1 },  -- Unstable Singularity  [vu 5×7]
        { role = "other", voice = "special-mechanic", spellID = 1227264, firstSeenSec = 17, cdSeriesSec = { 17 }, severity = 2 },  -- Cosmic Crash  [vu 17×7]
        { role = "other", voice = "std-move", spellID = 1263982, firstSeenSec = 28, cdSeriesSec = { 28 }, severity = 0 },  -- Gravitic Orbs  [vu 28×7]
        { role = "other", voice = "watch-dodge", spellID = 1311923, firstSeenSec = 34, cdSeriesSec = { 34 }, severity = 0 },  -- Dark Waves  [vu 34×7]
        { role = "other", voice = "special-mechanic", spellID = 1222755, firstSeenSec = 43, cdSeriesSec = { 43 }, severity = 2 },  -- Void Cascade  [vu 43×7]
    },
})

