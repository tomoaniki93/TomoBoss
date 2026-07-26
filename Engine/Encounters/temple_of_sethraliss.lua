---@diagnostic disable: undefined-global
-- TomoBoss — Donjon : Temple of Sethraliss (saison 12.0 S2, mapID 1877)
-- Données de MATCHING uniquement, générées depuis les branches de durée de
-- LittleWigs (ENCOUNTER_TIMELINE_EVENT_ADDED, modes Mythique et Normal/Héroïque
-- fusionnés). Aucune série de prédiction — `matchOnly = true`.
-- Rôles, voix et sévérités sont des valeurs par défaut, à affiner en jeu.

local NS = select(2, ...)
local R = function(id, def) NS.Engine:RegisterEncounter(id, def) end

-- Adderis and Aspix  (encounterID 2124)
R(2124, {
    name = "Adderis and Aspix",
    dungeon = "Temple of Sethraliss",
    matchOnly = true,
    events = {
        { role = "other", voice = "watch-dodge", spellID = 1289059, firstSeenSec = 1, cdSeriesSec = { 1, 5 }, severity = 1 },  -- Gale Force
        { role = "other", voice = "watch-dodge", spellID = 1288049, firstSeenSec = 4, cdSeriesSec = { 4, 9 }, severity = 2 },  -- Thunder and Lightning
        { role = "other", voice = "prepare-aoe", spellID = 1288864, firstSeenSec = 12, cdSeriesSec = { 12, 21, 26 }, severity = 1 },  -- Tempest Winds
        { role = "other", voice = "watch-explosion", spellID = 1288428, firstSeenSec = 31, cdSeriesSec = { 31, 36 }, severity = 0 },  -- Overload
    },
})

-- Merektha  (encounterID 2125)
R(2125, {
    name = "Merektha",
    dungeon = "Temple of Sethraliss",
    matchOnly = true,
    events = {
        { role = "other", voice = "watch-dodge", spellID = 1290797, firstSeenSec = 5, cdSeriesSec = { 5 }, severity = 0 },  -- Lightning Bite
        { role = "other", voice = "summon-adds", spellID = 1290029, firstSeenSec = 13, cdSeriesSec = { 13 }, severity = 2 },  -- A Knot of Snakes
        { role = "other", voice = "watch-dodge", spellID = 1289109, firstSeenSec = 25, cdSeriesSec = { 25 }, severity = 1 },  -- Thunder Spit
        { role = "other", voice = "prepare-aoe", spellID = 1293048, firstSeenSec = 36, cdSeriesSec = { 36 }, severity = 1 },  -- Serpentstorm
        { role = "other", voice = "summon-adds", spellID = 1289205, firstSeenSec = 44, cdSeriesSec = { 44 }, severity = 1 },  -- Hatch
        { role = "other", voice = "dodge-charge", spellID = 264172, firstSeenSec = 49, cdSeriesSec = { 49 }, severity = 0 },  -- Burrow
    },
})

-- Galvazzt  (encounterID 2126)
R(2126, {
    name = "Galvazzt",
    dungeon = "Temple of Sethraliss",
    matchOnly = true,
    events = {
        { role = "other", voice = "prepare-beam", spellID = 1291618, firstSeenSec = 6, cdSeriesSec = { 6, 26 }, severity = 1 },  -- Lightning Spire | AMBIGU : durée 26 partagée
        { role = "other", voice = "prepare-interrupt", spellID = 1309525, firstSeenSec = 24, cdSeriesSec = { 24, 26 }, severity = 1 },  -- Induction | AMBIGU : durée 26 partagée
    },
})

-- Avatar of Sethraliss  (encounterID 2127)
R(2127, {
    name = "Avatar of Sethraliss",
    dungeon = "Temple of Sethraliss",
    matchOnly = true,
    events = {
        { role = "other", voice = "prepare-dispel", spellID = 1301202, firstSeenSec = 11, cdSeriesSec = { 11 }, severity = 1 },  -- Defiling Taint
        { role = "other", voice = "phase-change", spellID = 1273408, firstSeenSec = 32.5, cdSeriesSec = { 32.5 }, severity = 0 },  -- Stage One
    },
})
