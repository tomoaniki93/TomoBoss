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

-- Kokia Blazehoof  (encounterID 2606) — 5 pull(s) capturé(s)
R(2606, {
    name = "Kokia Blazehoof",
    provenance = "observed",
    dungeon = "Ruby Life Pools",
    matchOnly = true,
    events = {
        { role = "other", voice = "summon-adds", spellID = 372863, firstSeenSec = 8, cdSeriesSec = { 8, 40 }, severity = 1 },  -- Ritual of Blazebinding | AMBIGU : durée 40 partagée  [vu 8×5 40×30]
        { role = "other", voice = "watch-dodge", spellID = 372107, firstSeenSec = 19, cdSeriesSec = { 19, 20 }, severity = 1 },  -- Molten Boulder  [vu 19×5 20×26]
        { role = "tank", voice = "tank-buster", spellID = 372858, firstSeenSec = 28, cdSeriesSec = { 28, 40 }, severity = 0 },  -- Searing Blows | AMBIGU : durée 40 partagée  [vu 28×5 40×30]
    },
})

-- Melidrussa Chillworn  (encounterID 2609) — 6 pull(s) capturé(s)
R(2609, {
    name = "Melidrussa Chillworn",
    provenance = "observed",
    dungeon = "Ruby Life Pools",
    matchOnly = true,
    events = {
        { role = "other", voice = "watch-explosion", spellID = 396044, firstSeenSec = 5, cdSeriesSec = { 5, 24 }, severity = 0 },  -- Hailburst | AMBIGU : durée 27 partagée  [vu 5×14 24×48]
        { role = "other", voice = "watch-explosion", spellID = 373680, firstSeenSec = 12, cdSeriesSec = { 12 }, severity = 0 },  -- Frost Overload  [vu 12×11]
        { role = "other", voice = "prepare-aoe", spellID = 372851, firstSeenSec = 15, cdSeriesSec = { 15, 24 }, severity = 1 },  -- Chillstorm | AMBIGU : durée 27 partagée  [vu 15×14 24×48]
    },
})

-- Kyrakka and Erkhart Stormvein  (encounterID 2623) — 6 pull(s) capturé(s)
R(2623, {
    name = "Kyrakka and Erkhart Stormvein",
    provenance = "observed",
    dungeon = "Ruby Life Pools",
    matchOnly = true,
    events = {
        { role = "tank", voice = "tank-buster", spellID = 381512, firstSeenSec = 5, cdSeriesSec = { 5, 22.5 }, severity = 0 },  -- Stormslam  [vu 5×9 22.5×16]
        { role = "other", voice = "watch-dodge", spellID = 381862, firstSeenSec = 12, cdSeriesSec = { 12, 16, 20 }, severity = 1 },  -- Inferno Spit | AMBIGU : durée 16 partagée  [vu 12×5 16×38 20×22]
        { role = "other", voice = "watch-knockback", spellID = 381517, firstSeenSec = 10, cdSeriesSec = { 10, 21.5 }, severity = 0 },  -- Winds of Change | AMBIGU : durée 21.5 partagée  [vu 10×6 21.5×17]
        { role = "other", voice = "watch-frontal", spellID = 381525, firstSeenSec = 1, cdSeriesSec = { 1, 16, 20 }, severity = 1 },  -- Roaring Firebreath | AMBIGU : durée 16 partagée  [vu 1×5 16×38 20×22]
        { role = "other", voice = "watch-explosion", spellID = 381516, firstSeenSec = 21, cdSeriesSec = { 21, 25 }, severity = 2 },  -- Interrupting Cloudburst | AMBIGU : durée 21 partagée  [vu 21×5 25×13]
    },
})

