---@diagnostic disable: undefined-global
-- TomoBoss — Donjon : The Blinding Vale (hors-saison Midnight, mapID 2859)
-- Données de MATCHING uniquement, générées depuis les branches de durée de
-- LittleWigs (ENCOUNTER_TIMELINE_EVENT_ADDED, modes Mythique et Normal/Héroïque
-- fusionnés). Aucune série de prédiction : la timeline Blizzard fournit déjà le
-- minutage — `matchOnly = true` empêche le moteur prédictif de démarrer dessus.
-- Rôles, voix et sévérités sont des valeurs par défaut, à affiner en jeu.

local NS = select(2, ...)
local R = function(id, def) NS.Engine:RegisterEncounter(id, def) end

-- Lightblossom Trinity  (encounterID 3199)
R(3199, {
    name = "Lightblossom Trinity",
    provenance = "littlewigs",
    dungeon = "The Blinding Vale",
    matchOnly = true,
    events = {
        { role = "other", voice = "watch-dodge", spellID = 1235640, firstSeenSec = 4, cdSeriesSec = { 4, 8, 10 }, severity = 1 },  -- Thornblade | round-robin LittleWigs sur 40-45 s — non transposable
        { role = "tank", voice = "tank-buster", spellID = 1234753, firstSeenSec = 5, cdSeriesSec = { 5 }, severity = 0 },  -- Bedrock Slam | round-robin LittleWigs sur 40-45 s — non transposable
        { role = "other", voice = "dodge-charge", spellID = 1234850, firstSeenSec = 20, cdSeriesSec = { 20 }, severity = 2 },  -- Lightsower Dash | round-robin LittleWigs sur 40-45 s — non transposable
        { role = "other", voice = "prepare-beam", spellID = 1235564, firstSeenSec = 35, cdSeriesSec = { 35 }, severity = 0 },  -- Lightblossom Beam | round-robin LittleWigs sur 40-45 s — non transposable
    },
})

-- Ikuzz the Light Hunter  (encounterID 3200)
R(3200, {
    name = "Ikuzz the Light Hunter",
    provenance = "littlewigs",
    dungeon = "The Blinding Vale",
    matchOnly = true,
    events = {
        { role = "other", voice = "watch-shockwave", spellID = 1236746, firstSeenSec = 6, cdSeriesSec = { 6, 29 }, severity = 1 },  -- Verdant Stomp
        { role = "other", voice = "prepare-interrupt", spellID = 1236709, firstSeenSec = 20, cdSeriesSec = { 20, 22 }, severity = 2 },  -- Thorncaller Roar
        { role = "other", voice = "prepare-beam", spellID = 1237090, firstSeenSec = 40, cdSeriesSec = { 40, 50 }, severity = 2 },  -- Bloodthirsty Gaze
    },
})

-- Lightwarden Ruia  (encounterID 3201)
R(3201, {
    name = "Lightwarden Ruia",
    provenance = "littlewigs",
    dungeon = "The Blinding Vale",
    matchOnly = true,
    events = {
        { role = "other", voice = "phase-change", spellID = 1239882, firstSeenSec = 0.5, cdSeriesSec = { 0.5 }, severity = 0 },  -- Shapeshift: Moonkin
        { role = "tank", voice = "tank-buster", spellID = 1241058, eventID = 882, firstSeenSec = 3, cdSeriesSec = { 3, 15.3, 32 }, severity = 2 },  -- Grievous Thrash | AMBIGU : durée 32 partagée | round-robin LittleWigs sur 20-21 s — non transposable
        { role = "other", voice = "watch-dodge", spellID = 1239824, firstSeenSec = 5, cdSeriesSec = { 5, 7.3, 32 }, severity = 1 },  -- Lightfire | AMBIGU : durée 32 partagée | round-robin LittleWigs sur 20-21 s — non transposable
        { role = "tank", voice = "tank-buster", spellID = 1240210, firstSeenSec = 9, cdSeriesSec = { 9, 31.3, 32 }, severity = 1 },  -- Pulverizing Strikes | AMBIGU : durée 31.3/32 partagée | round-robin LittleWigs sur 20-21 s — non transposable
        { role = "other", voice = "watch-dodge", spellID = 1240098, firstSeenSec = 18, cdSeriesSec = { 18, 23.3, 32 }, severity = 1 },  -- Lightfall | AMBIGU : durée 32 partagée | round-robin LittleWigs sur 20-21 s — non transposable
    },
})

-- Ziekket  (encounterID 3202)
R(3202, {
    name = "Ziekket",
    provenance = "littlewigs",
    dungeon = "The Blinding Vale",
    matchOnly = true,
    events = {
        { role = "other", voice = "phase-change", spellID = 1246372, firstSeenSec = 4, cdSeriesSec = { 4, 45, 50 }, severity = 0 },  -- Awaken the Lightbloom | AMBIGU : durée 45/50 partagée
        { role = "other", voice = "prepare-soak", spellID = 1246858, firstSeenSec = 14, cdSeriesSec = { 14, 50 }, severity = 1 },  -- Lightbloom's Essence | AMBIGU : durée 50 partagée
        { role = "tank", voice = "tank-buster", spellID = 1247685, firstSeenSec = 18, cdSeriesSec = { 18, 26, 45, 50 }, severity = 0 },  -- Thornspike | AMBIGU : durée 45/50 partagée
        { role = "other", voice = "prepare-beam", spellID = 1246607, firstSeenSec = 32, cdSeriesSec = { 32, 40, 45, 50 }, severity = 1 },  -- Concentrated Lightbeam | AMBIGU : durée 45/50 partagée
    },
})
