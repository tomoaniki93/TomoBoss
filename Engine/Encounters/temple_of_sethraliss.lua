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

-- Adderis and Aspix  (encounterID 2124) — 7 pull(s) capturé(s)
R(2124, {
    name = "Adderis and Aspix",
    provenance = "observed",
    dungeon = "Temple of Sethraliss",
    matchOnly = true,
    events = {
        { role = "other", voice = "watch-dodge", spellID = 1289059, firstSeenSec = 1, cdSeriesSec = { 1, 5, 45 }, severity = 1 },  -- Gale Force  [vu 1×18 5×34 45×53]
        { role = "other", voice = "watch-dodge", spellID = 1288049, firstSeenSec = 5, cdSeriesSec = { 5, 9, 45 }, severity = 2 },  -- Thunder and Lightning  [vu 5×34 9×13 45×53]
        { role = "other", voice = "prepare-aoe", spellID = 1311805, firstSeenSec = 12, cdSeriesSec = { 12, 25, 29, 45 }, severity = 1 },  -- capacité  [vu 12×8 25×32 29×14 45×53]
        { role = "tank", voice = "tank-buster", spellID = 1288428, firstSeenSec = 35, cdSeriesSec = { 35, 35.27, 39, 45 }, severity = 0 },  -- capacité  [vu 35×14 35.27×7 39×14 45×53]
    },
})

-- Merektha  (encounterID 2125) — 7 pull(s) capturé(s)
R(2125, {
    name = "Merektha",
    provenance = "observed",
    dungeon = "Temple of Sethraliss",
    matchOnly = true,
    events = {
        { role = "tank", voice = "tank-buster", spellID = 1290797, firstSeenSec = 5, cdSeriesSec = { 5 }, severity = 0 },  -- Lightning Bite  [vu 5×20]
        { role = "other", voice = "summon-adds", spellID = 263958, firstSeenSec = 13, cdSeriesSec = { 13 }, severity = 2 },  -- A Knot of Snakes  [vu 13×20]
        { role = "other", voice = "watch-dodge", spellID = 1289109, firstSeenSec = 25, cdSeriesSec = { 25 }, severity = 1 },  -- Thunder Spit  [vu 25×20]
        { role = "heal", voice = "prepare-aoe", spellID = 1293048, firstSeenSec = 36, cdSeriesSec = { 36 }, severity = 1 },  -- Serpentstorm  [vu 36×20]
        { role = "other", voice = "summon-adds", spellID = 1289205, firstSeenSec = 44, cdSeriesSec = { 44 }, severity = 1 },  -- Hatch  [vu 44×20]
        { role = "other", voice = "dodge-charge", spellID = 264206, firstSeenSec = 49, cdSeriesSec = { 49 }, severity = 0 },  -- Burrow  [vu 49×20]
    },
})

-- Galvazzt  (encounterID 2126) — 7 pull(s) capturé(s)
R(2126, {
    name = "Galvazzt",
    provenance = "observed",
    dungeon = "Temple of Sethraliss",
    matchOnly = true,
    events = {
        { role = "other", voice = "prepare-beam", spellID = 1291618, eventID = 2601, firstSeenSec = 5, cdSeriesSec = { 5, 22 }, severity = 1 },  -- Lightning Spire | AMBIGU : durée 26 partagée  [vu 5×7 22×65]
        { role = "heal", voice = "prepare-interrupt", spellID = 1290531, eventID = 2602, firstSeenSec = 20, cdSeriesSec = { 20, 22 }, severity = 1 },  -- Induction | AMBIGU : durée 26 partagée  [vu 20×7 22×65]
    },
})

-- Avatar of Sethraliss  (encounterID 2127) — 7 pull(s) capturé(s)
R(2127, {
    name = "Avatar of Sethraliss",
    provenance = "observed",
    dungeon = "Temple of Sethraliss",
    matchOnly = true,
    events = {
        { role = "heal", voice = "special-mechanic", spellID = 1301199, firstSeenSec = 15, cdSeriesSec = { 15 }, severity = 1 },  -- Defiling Taint  [vu 15×19]
        { role = "other", voice = "phase-change", spellID = 1273408, firstSeenSec = 32.5, cdSeriesSec = { 32.5 }, severity = 0 },  -- Stage One  [vu 32.5×15]
    },
})

