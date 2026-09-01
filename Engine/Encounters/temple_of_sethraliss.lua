---@diagnostic disable: undefined-global
-- TomoBoss — Donjon : Temple of Sethraliss / Temple de Sephraliss
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

-- Adderis and Aspix  (encounterID 2124) — 3 pull(s) capturé(s)
R(2124, {
    name = "Adderis and Aspix",
    provenance = "observed",
    dungeon = "Temple of Sethraliss",
    matchOnly = true,
    events = {
        { role = "other", voice = "watch-dodge", spellID = 1289059, firstSeenSec = 1, cdSeriesSec = { 1, 5, 19, 45 }, severity = 1 },  -- Gale Force  [vu 1×4 5×11 19×5 45×16]
        { role = "other", voice = "watch-dodge", spellID = 1288049, firstSeenSec = 5, cdSeriesSec = { 5, 9, 19, 45 }, severity = 2 },  -- Thunder and Lightning  [vu 5×11 9×5 19×5 45×16]
        { role = "other", voice = "prepare-aoe", spellID = 1311805, firstSeenSec = 12, cdSeriesSec = { 12, 19, 25, 29, 45 }, severity = 1 },  -- capacité  [vu 12×3 19×5 25×4 29×6 45×16]
        { role = "other", voice = "watch-explosion", spellID = 1311804, firstSeenSec = 19, cdSeriesSec = { 19, 39, 45 }, severity = 0 },  -- capacité  [vu 19×5 39×5 45×16]
    },
})

-- Merektha  (encounterID 2125) — 3 pull(s) capturé(s)
R(2125, {
    name = "Merektha",
    provenance = "observed",
    dungeon = "Temple of Sethraliss",
    matchOnly = true,
    events = {
        { role = "other", voice = "watch-dodge", spellID = 1290797, firstSeenSec = 5, cdSeriesSec = { 5 }, severity = 0 },  -- Lightning Bite  [vu 5×8]
        { role = "other", voice = "summon-adds", spellID = 1290029, firstSeenSec = 13, cdSeriesSec = { 13 }, severity = 2 },  -- A Knot of Snakes  [vu 13×8]
        { role = "other", voice = "watch-dodge", spellID = 1289109, firstSeenSec = 25, cdSeriesSec = { 25 }, severity = 1 },  -- Thunder Spit  [vu 25×8]
        { role = "other", voice = "prepare-aoe", spellID = 1293048, firstSeenSec = 36, cdSeriesSec = { 36 }, severity = 1 },  -- Serpentstorm  [vu 36×8]
        { role = "other", voice = "summon-adds", spellID = 1289205, firstSeenSec = 44, cdSeriesSec = { 44 }, severity = 1 },  -- Hatch  [vu 44×8]
        { role = "other", voice = "dodge-charge", spellID = 264172, firstSeenSec = 49, cdSeriesSec = { 49 }, severity = 0 },  -- Burrow  [vu 49×8]
    },
})

-- Galvazzt  (encounterID 2126) — 3 pull(s) capturé(s)
R(2126, {
    name = "Galvazzt",
    provenance = "observed",
    dungeon = "Temple of Sethraliss",
    matchOnly = true,
    events = {
        { role = "other", voice = "prepare-beam", spellID = 1291618, firstSeenSec = 5, cdSeriesSec = { 5, 22 }, severity = 1 },  -- Lightning Spire | AMBIGU : durée 26 partagée  [vu 5×3 22×26]
        { role = "other", voice = "prepare-interrupt", spellID = 1309525, firstSeenSec = 20, cdSeriesSec = { 20, 22 }, severity = 1 },  -- Induction | AMBIGU : durée 26 partagée  [vu 20×3 22×26]
    },
})

-- Avatar of Sethraliss  (encounterID 2127) — 3 pull(s) capturé(s)
R(2127, {
    name = "Avatar of Sethraliss",
    provenance = "observed",
    dungeon = "Temple of Sethraliss",
    matchOnly = true,
    events = {
        { role = "other", voice = "prepare-dispel", spellID = 1301202, firstSeenSec = 15, cdSeriesSec = { 15 }, severity = 1 },  -- Defiling Taint  [vu 15×9]
        { role = "other", voice = "phase-change", spellID = 1273408, firstSeenSec = 32.5, cdSeriesSec = { 32.5 }, severity = 0 },  -- Stage One  [vu 32.5×6]
    },
})

