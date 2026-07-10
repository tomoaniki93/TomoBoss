---@diagnostic disable: undefined-global
-- TomoBoss — Donjon : Terrasse des Magistères
-- Données de timeline converties depuis EXBoss (saison 12.0 S1).
-- Les noms de capacités sont résolus en direct depuis le client (spellID) ;
-- ils s'affichent donc dans la langue du jeu (français sur un client FR).

local NS = select(2, ...)
local R = function(id, def) NS.Engine:RegisterEncounter(id, def) end

-- Arcane Crowd Dispersing Construct  (encounterID 3071)
R(3071, {
    name = "Arcane Crowd Dispersing Construct",
    dungeon = "Terrasse des Magistères",
    events = {
        { role = "tank", voice = "tank-buster", spellID = 474496, castType = "begincast", castDuration = 2.5, firstSeenSec = 5, cdSeriesSec = { 23.1, 46.2 }, severity = 0 },
        { role = "other", voice = "prepare-aoe", spellID = 1214081, castType = "begincast", castDuration = 3, firstSeenSec = 16, cdSeriesSec = { 23.1, 44.9, 23.1, 46.1 }, severity = 1 },
        { role = "heal", voice = "prepare-dispel", spellID = 1214032, castType = "cast", firstSeenSec = 22, cdSeriesSec = { 69.2 }, severity = 0 },
        { role = "mechanic", voice = "phase-change", spellID = 474345, castType = "begincast", castDuration = 3, firstSeenSec = 45.1, cdSeriesSec = { 69.2 }, severity = 2, preAlertSec = 3 },
    },
})

-- Selanar Sunlash  (encounterID 3072)
R(3072, {
    name = "Selanar Sunlash",
    dungeon = "Terrasse des Magistères",
    events = {
        { role = "heal", voice = "prepare-clear-stack", spellID = 1225792, castType = "begincast", castDuration = 3, firstSeenSec = 7.3, cdSeriesSec = { 29.2, 26.7, 29.2, 28, 29.2, 28 }, severity = 1 },
        { role = "mechanic", voice = "watch-dodge", spellID = 1224903, castType = "begincast", castDuration = 3, firstSeenSec = 17, cdSeriesSec = { 57.1 }, severity = 1 },
        { role = "tank", voice = "tank-buster", spellID = 1248689, castType = "cast", firstSeenSec = 26.7, cdSeriesSec = { 55.9, 57.1 }, severity = 0 },
        { role = "mechanic", voice = "prepare-enter-circle", spellID = 1225193, castType = "begincast", castDuration = 5, firstSeenSec = 51, cdSeriesSec = { 57.1, 57.8 }, severity = 2, preAlertSec = 3 },
    },
})

-- Gemellus  (encounterID 3073)
R(3073, {
    name = "Gemellus",
    dungeon = "Terrasse des Magistères",
    events = {
        { role = "mechanic", spellID = 1223847, castType = "begincast", castDuration = 2.5, firstSeenSec = 5.1, cdSeriesSec = { 96 }, severity = 1 },
        { role = "heal", voice = "prepare-target", spellID = 1284954, castType = "begincast", castDuration = 4, firstSeenSec = 13.6, cdSeriesSec = { 40.9, 41.7, 43.8, 42.5 }, severity = 0 },
        { role = "mechanic", voice = "hit-clone", spellID = 1253709, castType = "begincast", castDuration = 2, firstSeenSec = 24.6, cdSeriesSec = { 41.3, 44.9, 41.3 }, severity = 1 },
        { role = "heal", voice = "prepare-pull", spellID = 1224299, castType = "begincast", castDuration = 4, firstSeenSec = 36.7, cdSeriesSec = { 41.3, 44.9 }, severity = 2, preAlertSec = 3 },
        { role = "other", spellID = 1224104, castType = "cast", firstSeenSec = 60.1, cdSeriesSec = { 56.8, 10.9, 6.6, 11.7, 12.3, 31.3 }, severity = 1 },
    },
})

-- Degentrius  (encounterID 3074)
R(3074, {
    name = "Degentrius",
    dungeon = "Terrasse des Magistères",
    events = {
        { role = "tank", voice = "tank-buster", spellID = 1280113, castType = "begincast", castDuration = 3, firstSeenSec = 3.8, cdSeriesSec = { 23.1 }, severity = 0 },
        { role = "heal", voice = "prepare-target", spellID = 1215893, castType = "cast", firstSeenSec = 8, cdSeriesSec = { 23.1 }, severity = 0 },
        { role = "other", voice = "prepare-soak", spellID = 1215087, castType = "begincast", castDuration = 2.5, firstSeenSec = 15.9, cdSeriesSec = { 23.1 }, severity = 2, preAlertSec = 3 },
    },
})

