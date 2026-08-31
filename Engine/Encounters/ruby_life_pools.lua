---@diagnostic disable: undefined-global
-- TomoBoss — Donjon : Ruby Life Pools / Bassin de l'essence rubis
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

-- Kokia Blazehoof  (encounterID 2606) — 3 pull(s) capturé(s)
R(2606, {
    name = "Kokia Blazehoof",
    provenance = "observed",
    dungeon = "Ruby Life Pools",
    matchOnly = true,
    events = {
        { role = "other", voice = "summon-adds", spellID = 372864, firstSeenSec = 8, cdSeriesSec = { 8, 40 }, severity = 1 },  -- Ritual of Blazebinding | AMBIGU : durée 40 partagée  [vu 8×3 40×17]
        { role = "other", voice = "watch-dodge", spellID = 372110, firstSeenSec = 19, cdSeriesSec = { 19, 20 }, severity = 1 },  -- Molten Boulder  [vu 19×3 20×15]
        { role = "tank", voice = "tank-buster", spellID = 372858, firstSeenSec = 28, cdSeriesSec = { 28 }, severity = 0 },  -- Searing Blows | AMBIGU : durée 40 partagée  [vu 28×3]
    },
})

-- Melidrussa Chillworn  (encounterID 2609) — 4 pull(s) capturé(s)
R(2609, {
    name = "Melidrussa Chillworn",
    provenance = "observed",
    dungeon = "Ruby Life Pools",
    matchOnly = true,
    events = {
        { role = "other", voice = "watch-explosion", spellID = 1307297, firstSeenSec = 5, cdSeriesSec = { 5, 24 }, severity = 0 },  -- Hailburst | AMBIGU : durée 27 partagée  [vu 5×8 24×27]
        { role = "other", voice = "watch-explosion", spellID = 373686, firstSeenSec = 12, cdSeriesSec = { 12 }, severity = 0 },  -- Frost Overload  [vu 12×7]
        { role = "other", voice = "prepare-aoe", spellID = 1307308, firstSeenSec = 15, cdSeriesSec = { 15 }, severity = 1 },  -- Chillstorm | AMBIGU : durée 27 partagée  [vu 15×8]
    },
})

-- Kyrakka and Erkhart Stormvein  (encounterID 2623) — 4 pull(s) capturé(s)
R(2623, {
    name = "Kyrakka and Erkhart Stormvein",
    provenance = "observed",
    dungeon = "Ruby Life Pools",
    matchOnly = true,
    events = {
        { role = "tank", voice = "tank-buster", spellID = 381512, firstSeenSec = 5, cdSeriesSec = { 5, 22.5 }, severity = 0 },  -- Stormslam  [vu 5×5 22.5×10]
        { role = "other", voice = "watch-dodge", spellID = 381862, firstSeenSec = 12, cdSeriesSec = { 12, 16, 20 }, severity = 1 },  -- Inferno Spit | AMBIGU : durée 16 partagée  [vu 12×3 16×22 20×15]
        { role = "other", voice = "watch-knockback", spellID = 381517, firstSeenSec = 10, cdSeriesSec = { 10, 21.5 }, severity = 0 },  -- Winds of Change | AMBIGU : durée 21.5 partagée  [vu 10×3 21.5×11]
        { role = "other", voice = "watch-frontal", spellID = 381525, firstSeenSec = 1, cdSeriesSec = { 1 }, severity = 1 },  -- Roaring Firebreath | AMBIGU : durée 16 partagée  [vu 1×3]
        { role = "other", voice = "watch-explosion", spellID = 381516, firstSeenSec = 21, cdSeriesSec = { 21, 25 }, severity = 2 },  -- Interrupting Cloudburst | AMBIGU : durée 21 partagée  [vu 21×3 25×8]
    },
})

