---@diagnostic disable: undefined-global
-- TomoBoss — Donjon : Voidscar Arena (hors-saison Midnight, mapID 2923)
-- Données de MATCHING uniquement, générées depuis les branches de durée de
-- LittleWigs (ENCOUNTER_TIMELINE_EVENT_ADDED, modes Mythique et Normal/Héroïque
-- fusionnés). Aucune série de prédiction : la timeline Blizzard fournit déjà le
-- minutage — `matchOnly = true` empêche le moteur prédictif de démarrer dessus.
-- Rôles, voix et sévérités sont des valeurs par défaut, à affiner en jeu.

local NS = select(2, ...)
local R = function(id, def) NS.Engine:RegisterEncounter(id, def) end

-- Taz'Rah  (encounterID 3285)
R(3285, {
    name = "Taz'Rah",
    provenance = "littlewigs",
    dungeon = "Voidscar Arena",
    matchOnly = true,
    events = {
        { role = "other", voice = "std-move", spellID = 1222085, firstSeenSec = 5, cdSeriesSec = { 5, 22.5 }, severity = 0 },  -- XXX remove in 12.1
        { role = "other", voice = "dodge-charge", spellID = 1222098, firstSeenSec = 6, cdSeriesSec = { 6 }, severity = 2 },  -- Nether Dash
        { role = "other", voice = "watch-dodge", spellID = 1222274, firstSeenSec = 12, cdSeriesSec = { 12, 50 }, severity = 1 },  -- XXX remove in 12.1 | AMBIGU : durée 50 partagée
        { role = "other", voice = "watch-dodge", spellID = 1296963, firstSeenSec = 16, cdSeriesSec = { 16 }, severity = 1 },  -- Umbral Rupture
        { role = "other", voice = "std-move", spellID = 1297017, firstSeenSec = 25, cdSeriesSec = { 25 }, severity = 0 },  -- Void Blast
        { role = "other", voice = "watch-dodge", spellID = 1300259, firstSeenSec = 31, cdSeriesSec = { 31 }, severity = 1 },  -- Dark Bloom
        { role = "other", voice = "std-move", spellID = 1262901, firstSeenSec = 35, cdSeriesSec = { 35, 50 }, severity = 0 },  -- XXX remove in 12.1 | AMBIGU : durée 50 partagée
    },
})

-- Atroxus  (encounterID 3286)
R(3286, {
    name = "Atroxus",
    provenance = "littlewigs",
    dungeon = "Voidscar Arena",
    matchOnly = true,
    events = {
        { role = "other", voice = "prepare-dispel", spellID = 1226120, firstSeenSec = 5, cdSeriesSec = { 5, 20, 23 }, severity = 1 },  -- Poison Splash | AMBIGU : durée 20 partagée
        { role = "tank", voice = "tank-buster", spellID = 1222642, eventID = 911, firstSeenSec = 10, cdSeriesSec = { 10, 20, 25 }, severity = 2 },  -- Hulking Claw | AMBIGU : durée 20 partagée
        { role = "other", voice = "watch-frontal", spellID = 1222721, firstSeenSec = 15, cdSeriesSec = { 15, 21, 30 }, severity = 2 },  -- Noxious Breath
        { role = "other", voice = "std-move", spellID = 1222371, firstSeenSec = 17, cdSeriesSec = { 17 }, severity = 0 },  -- Provoke Creeper
        { role = "other", voice = "prepare-interrupt", spellID = 1262497, firstSeenSec = 35, cdSeriesSec = { 35, 42 }, severity = 0 },  -- Monstrous Roar
    },
})

-- Charonus  (encounterID 3287)
R(3287, {
    name = "Charonus",
    provenance = "littlewigs",
    dungeon = "Voidscar Arena",
    matchOnly = true,
    events = {
        { role = "other", voice = "watch-dodge", spellID = 1282770, firstSeenSec = 5, cdSeriesSec = { 5, 40 }, severity = 1 },  -- Unstable Singularity
        { role = "other", voice = "special-mechanic", spellID = 1227264, firstSeenSec = 17, cdSeriesSec = { 17, 19, 44.8 }, severity = 2 },  -- Cosmic Crash
        { role = "other", voice = "std-move", spellID = 1263982, firstSeenSec = 28, cdSeriesSec = { 28, 36, 44 }, severity = 0 },  -- Gravitic Orbs
        { role = "other", voice = "watch-dodge", spellID = 1311923, firstSeenSec = 34, cdSeriesSec = { 34 }, severity = 0 },  -- Dark Waves
        { role = "other", voice = "special-mechanic", spellID = 1222755, firstSeenSec = 43, cdSeriesSec = { 43 }, severity = 2 },  -- Void Cascade
    },
})
