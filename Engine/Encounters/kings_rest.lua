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

-- The Golden Serpent  (encounterID 2139) — 5 pull(s) capturé(s)
R(2139, {
    name = "The Golden Serpent",
    provenance = "observed",
    dungeon = "Kings' Rest",
    matchOnly = true,
    events = {
        { role = "other", voice = "watch-dodge", spellID = 265773, firstSeenSec = 5, cdSeriesSec = { 5, 25 }, severity = 1 },  -- Spit Gold | AMBIGU : durée 25 partagée  [vu 5×10 25×20]
        { role = "tank", voice = "tank-buster", spellID = 265910, firstSeenSec = 8, cdSeriesSec = { 8, 25 }, severity = 0 },  -- Tail Thrash | AMBIGU : durée 25 partagée  [vu 8×10 25×20]
        { role = "heal", voice = "prepare-aoe", spellID = 1311987, firstSeenSec = 14, cdSeriesSec = { 14, 28 }, severity = 2 },  -- Serpentine Gust  [vu 14×10 28×10]
        { role = "other", voice = "summon-adds", spellID = 265923, firstSeenSec = 54, cdSeriesSec = { 54 }, severity = 2 },  -- Lucre's Call  [vu 54×10]
    },
})

-- The Council of Tribes  (encounterID 2140) — 5 pull(s) capturé(s)
R(2140, {
    name = "The Council of Tribes",
    provenance = "observed",
    dungeon = "Kings' Rest",
    matchOnly = true,
    events = {
        { role = "other", voice = "watch-knockback", spellID = 266206, firstSeenSec = 8, cdSeriesSec = { 8, 14.75 }, severity = 1 },  -- Whirling Axes | AMBIGU : durée 14.8 partagée  [vu 8×5 14.75×8]
        { role = "other", voice = "prepare-target", spellID = 266231, firstSeenSec = 15, cdSeriesSec = { 15, 16.5 }, severity = 1 },  -- Severing Axe | AMBIGU : durée 15 partagée  [vu 15×5 16.5×5]
    },
})

-- Mchimba the Embalmer  (encounterID 2142) — 5 pull(s) capturé(s)
R(2142, {
    name = "Mchimba the Embalmer",
    provenance = "observed",
    dungeon = "Kings' Rest",
    matchOnly = true,
    events = {
        { role = "heal", voice = "std-drop", spellID = 267639, firstSeenSec = 63, cdSeriesSec = { 63 }, severity = 1 },  -- Burn Corruption  [vu 63×6]
        { role = "heal", voice = "prepare-dispel", spellID = 267618, firstSeenSec = 5, cdSeriesSec = { 5, 32 }, severity = 2 },  -- Drain Fluids  [vu 5×20 32×16]
        { role = "mechanic", voice = "switch-add", spellID = 1312146, firstSeenSec = 30, cdSeriesSec = { 30 }, severity = 0 },  -- Awakening Slam | AMBIGU : durée 30 partagée  [vu 30×36]
        { role = "other", voice = "break-shield", spellID = 267702, firstSeenSec = 60, cdSeriesSec = { 60 }, severity = 1 },  -- Entomb  [vu 60×20]
        { role = "other", voice = "watch-dodge", spellID = 1311956, firstSeenSec = 20, cdSeriesSec = { 20, 30 }, severity = 1 },  -- capacité  [vu 20×20 30×36]
    },
})

-- Dazar, The First King  (encounterID 2143) — 5 pull(s) capturé(s)
R(2143, {
    name = "Dazar, The First King",
    provenance = "observed",
    dungeon = "Kings' Rest",
    matchOnly = true,
    events = {
        { role = "mechanic", voice = "prepare-interrupt", firstSeenSec = 36, cdSeriesSec = { 36 }, severity = 2 },  -- Fear du raptor (à nommer)  [vu 36×10]
        { role = "other", voice = "dodge-charge", spellID = 269230, firstSeenSec = 8, cdSeriesSec = { 8, 10 }, severity = 1 },  -- Hunting Leap | AMBIGU : durée 10 partagée  [vu 8×8 10×10]
        { role = "mechanic", voice = "prepare-interrupt", spellID = 269369, firstSeenSec = 10, cdSeriesSec = { 10, 14 }, severity = 2 },  -- Deathly Roar | AMBIGU : durée 10 partagée  [vu 10×10 14×8]
        { role = "tank", voice = "tank-buster", spellID = 1303115, firstSeenSec = 15, cdSeriesSec = { 15 }, severity = 1 },  -- Aerial Smash  [vu 15×6]
        { role = "tank", voice = "tank-buster", spellID = 268586, firstSeenSec = 23, cdSeriesSec = { 23, 38 }, severity = 0 },  -- Blade Combo  [vu 23×6 38×10]
        { role = "other", voice = "special-mechanic", spellID = 1303267, firstSeenSec = 24, cdSeriesSec = { 24, 30 }, severity = 2 },  -- Gilded Destruction  [vu 24×10 30×6]
        { role = "other", voice = "dodge-charge", spellID = 1303327, firstSeenSec = 9, cdSeriesSec = { 9 }, severity = 1 },  -- capacité  [vu 9×10]
    },
})

