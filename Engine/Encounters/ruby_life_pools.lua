---@diagnostic disable: undefined-global
-- TomoBoss — Donjon : Ruby Life Pools (saison 12.0 S2, mapID 2521)
-- Données de MATCHING uniquement, générées depuis les branches de durée de
-- LittleWigs (ENCOUNTER_TIMELINE_EVENT_ADDED, modes Mythique et Normal/Héroïque
-- fusionnés). Aucune série de prédiction — `matchOnly = true`.
-- Rôles, voix et sévérités sont des valeurs par défaut, à affiner en jeu.

local NS = select(2, ...)
local R = function(id, def) NS.Engine:RegisterEncounter(id, def) end

-- Kokia Blazehoof  (encounterID 2606)
R(2606, {
    name = "Kokia Blazehoof",
    provenance = "littlewigs",
    dungeon = "Ruby Life Pools",
    matchOnly = true,
    events = {
        { role = "other", voice = "summon-adds", spellID = 372864, firstSeenSec = 8, cdSeriesSec = { 8, 40 }, severity = 1 },  -- Ritual of Blazebinding | AMBIGU : durée 40 partagée
        { role = "other", voice = "watch-dodge", spellID = 372110, firstSeenSec = 19, cdSeriesSec = { 19, 20 }, severity = 1 },  -- Molten Boulder
        { role = "tank", voice = "tank-buster", spellID = 372858, firstSeenSec = 28, cdSeriesSec = { 28, 40 }, severity = 0 },  -- Searing Blows | AMBIGU : durée 40 partagée
    },
})

-- Melidrussa Chillworn  (encounterID 2609)
R(2609, {
    name = "Melidrussa Chillworn",
    provenance = "littlewigs",
    dungeon = "Ruby Life Pools",
    matchOnly = true,
    events = {
        { role = "other", voice = "watch-explosion", spellID = 1307297, firstSeenSec = 6, cdSeriesSec = { 6, 27 }, severity = 0 },  -- Hailburst | AMBIGU : durée 27 partagée
        { role = "other", voice = "watch-explosion", spellID = 373686, firstSeenSec = 12, cdSeriesSec = { 12 }, severity = 0 },  -- Frost Overload
        { role = "other", voice = "prepare-aoe", spellID = 1307308, firstSeenSec = 16, cdSeriesSec = { 16, 27 }, severity = 1 },  -- Chillstorm | AMBIGU : durée 27 partagée
    },
})

-- Kyrakka and Erkhart Stormvein  (encounterID 2623)
R(2623, {
    name = "Kyrakka and Erkhart Stormvein",
    provenance = "littlewigs",
    dungeon = "Ruby Life Pools",
    matchOnly = true,
    events = {
        { role = "tank", voice = "tank-buster", spellID = 381512, firstSeenSec = 5, cdSeriesSec = { 5, 22.5 }, severity = 0 },  -- Stormslam
        { role = "other", voice = "watch-dodge", spellID = 381862, firstSeenSec = 9, cdSeriesSec = { 9, 12, 16, 20 }, severity = 1 },  -- Inferno Spit | AMBIGU : durée 16 partagée
        { role = "other", voice = "watch-knockback", spellID = 381517, firstSeenSec = 10, cdSeriesSec = { 10, 21.5 }, severity = 0 },  -- Winds of Change | AMBIGU : durée 21.5 partagée
        { role = "other", voice = "watch-frontal", spellID = 381525, firstSeenSec = 16, cdSeriesSec = { 16 }, severity = 1 },  -- Roaring Firebreath | AMBIGU : durée 16 partagée
        { role = "other", voice = "watch-explosion", spellID = 381516, firstSeenSec = 21, cdSeriesSec = { 21, 25 }, severity = 2 },  -- Interrupting Cloudburst | AMBIGU : durée 21 partagée
    },
})
