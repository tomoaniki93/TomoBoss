---@diagnostic disable: undefined-global
-- TomoBoss — Donjon : Den of Nalorakk / Antre de Nalorak
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

-- The Hoardmonger  (encounterID 3207) — 5 pull(s) capturé(s)
R(3207, {
    name = "The Hoardmonger",
    provenance = "observed",
    dungeon = "Den of Nalorakk",
    matchOnly = true,
    events = {
        { role = "heal", voice = "prepare-aoe", spellID = 1235118, eventID = 801, firstSeenSec = 6, cdSeriesSec = { 6 }, severity = 2 },  -- Ravenous Bellow  [vu 6×11]
        { role = "tank", voice = "tank-buster", spellID = 1253268, eventID = 800, firstSeenSec = 16, cdSeriesSec = { 16 }, severity = 1 },  -- Earthshatter Slam  [vu 16×11]
        { role = "other", voice = "watch-dodge", spellID = 1234233, eventID = 802, firstSeenSec = 30, cdSeriesSec = { 30 }, severity = 0 },  -- Spoiled Supplies  [vu 30×11]
        { role = "other", voice = "watch-dodge", firstSeenSec = 92.39, cdSeriesSec = { 92.39 }, severity = 1 },  -- TODO identifier  [vu 92.39×3]
        { role = "other", voice = "watch-dodge", firstSeenSec = 99, cdSeriesSec = { 99 }, severity = 1 },  -- TODO identifier  [vu 99×27]
    },
})

-- Sentinel of Winter  (encounterID 3208) — 5 pull(s) capturé(s)
R(3208, {
    name = "Sentinel of Winter",
    provenance = "observed",
    dungeon = "Den of Nalorakk",
    matchOnly = true,
    events = {
        { role = "heal", voice = "prepare-aoe", spellID = 1235548, eventID = 811, firstSeenSec = 7, cdSeriesSec = { 7 }, severity = 1 },  -- Glacial Torment | AMBIGU : durée 7 partagée  [vu 7×17]
        { role = "other", voice = "watch-dodge", spellID = 1235783, eventID = 810, firstSeenSec = 25, cdSeriesSec = { 25 }, severity = 1 },  -- Shattering Frostspike | AMBIGU : durée 7 partagée  [vu 25×17]
        { role = "other", voice = "prepare-aoe", spellID = 1235623, eventID = 812, firstSeenSec = 13, cdSeriesSec = { 13 }, severity = 1 },  -- Raging Squall  [vu 13×17]
        { role = "mechanic", voice = "prepare-aoe", spellID = 1235656, eventID = 813, firstSeenSec = 50, cdSeriesSec = { 50 }, severity = 2 },  -- Frozen Tempest  [vu 50×17]
        { role = "other", voice = "watch-dodge", firstSeenSec = 61, cdSeriesSec = { 61 }, severity = 1 },  -- TODO identifier  [vu 61×8]
        { role = "other", voice = "watch-dodge", firstSeenSec = 63, cdSeriesSec = { 63 }, severity = 1 },  -- TODO identifier  [vu 63×14]
    },
})

-- Nalorakk Den  (encounterID 3209) — 5 pull(s) capturé(s)
R(3209, {
    name = "Nalorakk Den",
    provenance = "observed",
    dungeon = "Den of Nalorakk",
    matchOnly = true,
    events = {
        { role = "tank", voice = "tank-buster", spellID = 1242860, eventID = 820, firstSeenSec = 5, cdSeriesSec = { 5, 25 }, severity = 2 },  -- Echoing Maul | AMBIGU : durée 25 partagée  [vu 5×14 25×18]
        { role = "tank", voice = "tank-knockback", spellID = 1243569, eventID = 821, firstSeenSec = 13, cdSeriesSec = { 13, 25 }, severity = 2 },  -- Overwhelming Onslaught | AMBIGU : durée 25 partagée  [vu 13×11 25×18]
        { role = "mechanic", voice = "boss-enrage", spellID = 1243011, eventID = 823, firstSeenSec = 54, cdSeriesSec = { 54 }, severity = 2 },  -- Fury of the War God  [vu 54×11]
        { role = "other", voice = "watch-dodge", firstSeenSec = 10, cdSeriesSec = { 10 }, severity = 1 },  -- TODO identifier  [vu 10×3]
    },
})

