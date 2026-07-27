---@diagnostic disable: undefined-global
-- TomoBoss — Donjon : Den of Nalorakk (hors-saison Midnight, mapID 2825)
-- Données de MATCHING uniquement, générées depuis les branches de durée de
-- LittleWigs (ENCOUNTER_TIMELINE_EVENT_ADDED, modes Mythique et Normal/Héroïque
-- fusionnés). Aucune série de prédiction : la timeline Blizzard fournit déjà le
-- minutage — `matchOnly = true` empêche le moteur prédictif de démarrer dessus.
-- Rôles, voix et sévérités sont des valeurs par défaut, à affiner en jeu.

local NS = select(2, ...)
local R = function(id, def) NS.Engine:RegisterEncounter(id, def) end

-- The Hoardmonger  (encounterID 3207)
R(3207, {
    name = "The Hoardmonger",
    provenance = "littlewigs",
    dungeon = "Den of Nalorakk",
    matchOnly = true,
    events = {
        { role = "heal", voice = "prepare-aoe", spellID = 1235118, eventID = 801, firstSeenSec = 6, cdSeriesSec = { 6, 18 }, severity = 2 },  -- Ravenous Bellow
        { role = "tank", voice = "tank-buster", spellID = 1253268, eventID = 800, firstSeenSec = 7, cdSeriesSec = { 7, 16, 21 }, severity = 1 },  -- Earthshatter Slam
        { role = "other", voice = "watch-dodge", spellID = 1234233, eventID = 802, firstSeenSec = 30, cdSeriesSec = { 30, 39 }, severity = 0 },  -- Spoiled Supplies
    },
})

-- Sentinel of Winter  (encounterID 3208)
R(3208, {
    name = "Sentinel of Winter",
    provenance = "littlewigs",
    dungeon = "Den of Nalorakk",
    matchOnly = true,
    events = {
        { role = "heal", voice = "prepare-aoe", spellID = 1235548, eventID = 811, firstSeenSec = 7, cdSeriesSec = { 7, 17 }, severity = 1 },  -- Glacial Torment | AMBIGU : durée 7 partagée
        { role = "other", voice = "watch-dodge", spellID = 1235783, eventID = 810, firstSeenSec = 7, cdSeriesSec = { 7, 25 }, severity = 1 },  -- Shattering Frostspike | AMBIGU : durée 7 partagée
        { role = "other", voice = "prepare-aoe", spellID = 1235623, eventID = 812, firstSeenSec = 13, cdSeriesSec = { 13, 30 }, severity = 1 },  -- Raging Squall
        { role = "mechanic", voice = "prepare-aoe", spellID = 1235656, eventID = 813, firstSeenSec = 38, cdSeriesSec = { 38, 50 }, severity = 2 },  -- Frozen Tempest
    },
})

-- Nalorakk Den  (encounterID 3209)
R(3209, {
    name = "Nalorakk Den",
    provenance = "littlewigs",
    dungeon = "Den of Nalorakk",
    matchOnly = true,
    events = {
        { role = "tank", voice = "tank-buster", spellID = 1242860, eventID = 820, firstSeenSec = 5, cdSeriesSec = { 5, 25, 33 }, severity = 2 },  -- Echoing Maul | AMBIGU : durée 25 partagée
        { role = "tank", voice = "tank-knockback", spellID = 1243569, eventID = 821, firstSeenSec = 13, cdSeriesSec = { 13, 15, 25 }, severity = 2 },  -- Overwhelming Onslaught | AMBIGU : durée 25 partagée
        { role = "heal", voice = "prepare-aoe", spellID = 1255385, eventID = 822, firstSeenSec = 27, cdSeriesSec = { 27 }, severity = 1 },  -- XXX remove in 12.1
        { role = "mechanic", voice = "boss-enrage", spellID = 1243011, eventID = 823, firstSeenSec = 48, cdSeriesSec = { 48, 54 }, severity = 2 },  -- Fury of the War God
    },
})
