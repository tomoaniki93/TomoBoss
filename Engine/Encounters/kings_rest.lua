---@diagnostic disable: undefined-global
-- TomoBoss — Donjon : Kings' Rest (saison 12.0 S2, mapID 1762)
-- Données de MATCHING uniquement, générées depuis les branches de durée de
-- LittleWigs (ENCOUNTER_TIMELINE_EVENT_ADDED, modes Mythique et Normal/Héroïque
-- fusionnés). Aucune série de prédiction — `matchOnly = true`.
-- Rôles, voix et sévérités sont des valeurs par défaut, à affiner en jeu.

local NS = select(2, ...)
local R = function(id, def) NS.Engine:RegisterEncounter(id, def) end

-- The Golden Serpent  (encounterID 2139)
R(2139, {
    name = "The Golden Serpent",
    dungeon = "Kings' Rest",
    matchOnly = true,
    events = {
        { role = "other", voice = "watch-dodge", spellID = 265773, firstSeenSec = 5, cdSeriesSec = { 5, 25 }, severity = 1 },  -- Spit Gold | AMBIGU : durée 25 partagée
        { role = "tank", voice = "tank-buster", spellID = 265910, firstSeenSec = 8, cdSeriesSec = { 8, 25 }, severity = 0 },  -- Tail Thrash | AMBIGU : durée 25 partagée
        { role = "other", voice = "watch-knockback", spellID = 265781, firstSeenSec = 14, cdSeriesSec = { 14, 28 }, severity = 2 },  -- Serpentine Gust
        { role = "other", voice = "summon-adds", spellID = 265923, firstSeenSec = 54, cdSeriesSec = { 54 }, severity = 2 },  -- Lucre's Call
    },
})

-- The Council of Tribes  (encounterID 2140)
R(2140, {
    name = "The Council of Tribes",
    dungeon = "Kings' Rest",
    matchOnly = true,
    events = {
        { role = "other", voice = "watch-dodge", spellID = 1305810, firstSeenSec = 2, cdSeriesSec = { 2, 7 }, severity = 1 },  -- Arc Lightning
        { role = "other", voice = "dodge-charge", spellID = 267494, firstSeenSec = 5, cdSeriesSec = { 5, 20 }, severity = 1 },  -- Barrel Through | AMBIGU : durée 20 partagée
        { role = "tank", voice = "tank-buster", spellID = 266206, firstSeenSec = 8, cdSeriesSec = { 8, 14.8 }, severity = 1 },  -- Whirling Axes | AMBIGU : durée 14.8 partagée
        { role = "other", voice = "watch-explosion", spellID = 267273, firstSeenSec = 10, cdSeriesSec = { 10, 24.4 }, severity = 2 },  -- Poison Nova
        { role = "other", voice = "std-move", spellID = 266237, firstSeenSec = 14, cdSeriesSec = { 14, 22 }, severity = 0 },  -- Debilitating Backhand
        { role = "tank", voice = "tank-buster", spellID = 266231, firstSeenSec = 15, cdSeriesSec = { 15, 16.5 }, severity = 1 },  -- Severing Axe | AMBIGU : durée 15 partagée
        { role = "other", voice = "summon-adds", spellID = 267060, firstSeenSec = 20, cdSeriesSec = { 20, 52.5 }, severity = 1 },  -- Call of the Elements | AMBIGU : durée 20 partagée
    },
})

-- Mchimba the Embalmer  (encounterID 2142)
R(2142, {
    name = "Mchimba the Embalmer",
    dungeon = "Kings' Rest",
    matchOnly = true,
    events = {
        { role = "other", voice = "watch-dodge", spellID = 267618, firstSeenSec = 5, cdSeriesSec = { 5, 32 }, severity = 2 },  -- Drain Fluids
        { role = "other", voice = "watch-dodge", spellID = 267639, firstSeenSec = 20, cdSeriesSec = { 20, 30 }, severity = 1 },  -- Burn Corruption | AMBIGU : durée 30 partagée
        { role = "tank", voice = "tank-buster", spellID = 1312146, firstSeenSec = 30, cdSeriesSec = { 30 }, severity = 0 },  -- Awakening Slam | AMBIGU : durée 30 partagée
        { role = "other", voice = "break-shield", spellID = 267702, firstSeenSec = 60, cdSeriesSec = { 60 }, severity = 1 },  -- Entomb
    },
})

-- Dazar, The First King  (encounterID 2143)
R(2143, {
    name = "Dazar, The First King",
    dungeon = "Kings' Rest",
    matchOnly = true,
    events = {
        { role = "other", voice = "dodge-charge", spellID = 269230, firstSeenSec = 8, cdSeriesSec = { 8, 10 }, severity = 1 },  -- Hunting Leap | AMBIGU : durée 10 partagée
        { role = "other", voice = "dodge-charge", spellID = 1303326, firstSeenSec = 9, cdSeriesSec = { 9 }, severity = 1 },  -- Quaking Leap
        { role = "other", voice = "special-mechanic", spellID = 269369, firstSeenSec = 10, cdSeriesSec = { 10, 14 }, severity = 2 },  -- Deathly Roar | AMBIGU : durée 10 partagée
        { role = "tank", voice = "tank-buster", spellID = 1303115, firstSeenSec = 15, cdSeriesSec = { 15 }, severity = 1 },  -- Aerial Smash
        { role = "tank", voice = "tank-buster", spellID = 268586, firstSeenSec = 23, cdSeriesSec = { 23, 38 }, severity = 0 },  -- Blade Combo
        { role = "other", voice = "special-mechanic", spellID = 1303267, firstSeenSec = 24, cdSeriesSec = { 24, 30 }, severity = 2 },  -- Gilded Destruction
        { role = "tank", voice = "tank-buster", spellID = 1303481, firstSeenSec = 36, cdSeriesSec = { 36 }, severity = 0 },  -- Savage Maul
    },
})
