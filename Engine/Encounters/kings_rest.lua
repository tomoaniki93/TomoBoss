---@diagnostic disable: undefined-global
-- TomoBoss — Donjon : Kings' Rest / Repos des rois
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

-- The Golden Serpent  (encounterID 2139) — 4 pull(s) capturé(s)
R(2139, {
    name = "The Golden Serpent",
    provenance = "observed",
    dungeon = "Kings' Rest",
    matchOnly = true,
    events = {
        { role = "other", voice = "watch-dodge", spellID = 265773, firstSeenSec = 5, cdSeriesSec = { 5, 25 }, severity = 1 },  -- Spit Gold | AMBIGU : durée 25 partagée  [vu 5×8 25×16]
        { role = "tank", voice = "tank-buster", spellID = 265910, firstSeenSec = 8, cdSeriesSec = { 8, 25 }, severity = 0 },  -- Tail Thrash | AMBIGU : durée 25 partagée  [vu 8×8 25×16]
        { role = "other", voice = "watch-knockback", spellID = 265781, firstSeenSec = 14, cdSeriesSec = { 14, 28 }, severity = 2 },  -- Serpentine Gust  [vu 14×8 28×8]
        { role = "other", voice = "summon-adds", spellID = 265923, firstSeenSec = 54, cdSeriesSec = { 54 }, severity = 2 },  -- Lucre's Call  [vu 54×8]
    },
})

-- The Council of Tribes  (encounterID 2140) — 4 pull(s) capturé(s)
R(2140, {
    name = "The Council of Tribes",
    provenance = "observed",
    dungeon = "Kings' Rest",
    matchOnly = true,
    events = {
        { role = "tank", voice = "tank-buster", spellID = 266206, firstSeenSec = 8, cdSeriesSec = { 8, 14.75 }, severity = 1 },  -- Whirling Axes | AMBIGU : durée 14.8 partagée  [vu 8×4 14.75×6]
        { role = "tank", voice = "tank-buster", spellID = 266231, firstSeenSec = 15, cdSeriesSec = { 15, 16.5 }, severity = 1 },  -- Severing Axe | AMBIGU : durée 15 partagée  [vu 15×4 16.5×4]
    },
})

-- Mchimba the Embalmer  (encounterID 2142) — 4 pull(s) capturé(s)
R(2142, {
    name = "Mchimba the Embalmer",
    provenance = "observed",
    dungeon = "Kings' Rest",
    matchOnly = true,
    events = {
        { role = "other", voice = "watch-dodge", spellID = 267618, firstSeenSec = 5, cdSeriesSec = { 5, 32 }, severity = 2 },  -- Drain Fluids  [vu 5×16 32×13]
        { role = "tank", voice = "tank-buster", spellID = 1312146, firstSeenSec = 30, cdSeriesSec = { 30, 102 }, severity = 0 },  -- Awakening Slam | AMBIGU : durée 30 partagée  [vu 30×29 102×7]
        { role = "other", voice = "break-shield", spellID = 267702, firstSeenSec = 60, cdSeriesSec = { 60 }, severity = 1 },  -- Entomb  [vu 60×16]
        { role = "other", voice = "watch-dodge", spellID = 1311956, firstSeenSec = 20, cdSeriesSec = { 20, 30 }, severity = 1 },  -- capacité  [vu 20×16 30×29]
        { role = "other", voice = "watch-dodge", firstSeenSec = 63, cdSeriesSec = { 63 }, severity = 1 },  -- TODO identifier  [vu 63×5]
    },
})

-- Dazar, The First King  (encounterID 2143) — 4 pull(s) capturé(s)
R(2143, {
    name = "Dazar, The First King",
    provenance = "observed",
    dungeon = "Kings' Rest",
    matchOnly = true,
    events = {
        { role = "other", voice = "dodge-charge", spellID = 269230, firstSeenSec = 8, cdSeriesSec = { 8, 10 }, severity = 1 },  -- Hunting Leap | AMBIGU : durée 10 partagée  [vu 8×7 10×8]
        { role = "other", voice = "special-mechanic", spellID = 269369, firstSeenSec = 10, cdSeriesSec = { 10, 14 }, severity = 2 },  -- Deathly Roar | AMBIGU : durée 10 partagée  [vu 10×8 14×7]
        { role = "tank", voice = "tank-buster", spellID = 1303115, firstSeenSec = 15, cdSeriesSec = { 15 }, severity = 1 },  -- Aerial Smash  [vu 15×4]
        { role = "tank", voice = "tank-buster", spellID = 268586, firstSeenSec = 23, cdSeriesSec = { 23, 38 }, severity = 0 },  -- Blade Combo  [vu 23×4 38×8]
        { role = "other", voice = "special-mechanic", spellID = 1303267, firstSeenSec = 24, cdSeriesSec = { 24, 30 }, severity = 2 },  -- Gilded Destruction  [vu 24×8 30×4]
        { role = "other", voice = "dodge-charge", spellID = 1303327, firstSeenSec = 9, cdSeriesSec = { 9 }, severity = 1 },  -- capacité  [vu 9×8]
        { role = "tank", voice = "tank-buster", spellID = 1303488, firstSeenSec = 36, cdSeriesSec = { 36 }, severity = 0 },  -- capacité  [vu 36×8]
    },
})

