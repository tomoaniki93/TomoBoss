---@diagnostic disable: undefined-global
-- TomoBoss — Donjon : Cavernes de Maisara
-- Données de timeline converties depuis EXBoss (saison 12.0 S1).
-- Les noms de capacités sont résolus en direct depuis le client (spellID) ;
-- ils s'affichent donc dans la langue du jeu (français sur un client FR).

local NS = select(2, ...)
local R = function(id, def) NS.Engine:RegisterEncounter(id, def) end

-- Muro'jin and Nekraxx  (encounterID 3212)
R(3212, {
    name = "Muro'jin and Nekraxx",
    dungeon = "Cavernes de Maisara",
    events = {
        { role = "tank", voice = "tank-buster", spellID = 1266480, castType = "begincast", castDuration = 2.5, firstSeenSec = 5.9, cdSeriesSec = { 44.4, 45.1 }, severity = 0 },
        { role = "heal", voice = "prepare-dispel", spellID = 1246666, castType = "begincast", castDuration = 1.5, firstSeenSec = 12, cdSeriesSec = { 45 }, severity = 0 },
        { role = "mechanic", voice = "watch-dodge", spellID = 1260731, castType = "begincast", castDuration = 2, firstSeenSec = 20, cdSeriesSec = { 45 }, severity = 1 },
        { role = "other", voice = "watch-dodge", spellID = 1243900, castType = "begincast", castDuration = 3, firstSeenSec = 28, cdSeriesSec = { 45 }, severity = 0 },
        { role = "heal", voice = "target-frontal", spellID = 1260648, castType = "cast", firstSeenSec = 35, cdSeriesSec = { 3, 42 }, severity = 1 },
        { role = "mechanic", voice = "step-trap", spellID = 1249479, castType = "begincast", castDuration = 4.5, firstSeenSec = 41, cdSeriesSec = { 45 }, severity = 2, preAlertSec = 3 },
    },
})

-- Vordaza  (encounterID 3213)
R(3213, {
    name = "Vordaza",
    dungeon = "Cavernes de Maisara",
    events = {
        { role = "tank", voice = "tank-buster", spellID = 1251554, castType = "begincast", castDuration = 1, firstSeenSec = 3, cdSeriesSec = { 33.5, 63, 33.5, 60 }, severity = 0 },
        { role = "mechanic", voice = "kite-add", spellID = 1251204, castType = "cast", firstSeenSec = 14.2, cdSeriesSec = { 33.5, 63, 33.5, 60 }, severity = 2, preAlertSec = 3 },
        { role = "mechanic", voice = "kite-add", spellID = 1251775, castType = "cast", firstSeenSec = 19.2, cdSeriesSec = { 33.7, 61.8, 3.2, 30.6, 3.5, 56, 3.1 }, severity = 1 },
        { role = "other", spellID = 1251775, castType = "cast", firstSeenSec = 19.2, cdSeriesSec = { 33.7, 61.8, 3.2, 30.6, 3.5, 56, 3.1 }, severity = 1 },
        { role = "other", voice = "watch-frontal", spellID = 1252054, castType = "begincast", castDuration = 2.5, firstSeenSec = 25.4, cdSeriesSec = { 33.5, 63, 33.5, 60 }, severity = 0 },
    },
})

-- Raktul, Vessel of Souls  (encounterID 3214)
R(3214, {
    name = "Raktul, Vessel of Souls",
    dungeon = "Cavernes de Maisara",
    events = {
        { role = "tank", voice = "tank-buster", spellID = 1251023, castType = "channel", firstSeenSec = 4, cdSeriesSec = { 26.4, 26.4, 67.2 }, severity = 0 },
        { role = "heal", voice = "spread-close", spellID = 1252676, castType = "begincast", castDuration = 4.5, firstSeenSec = 17.2, cdSeriesSec = { 26.4, 93.7 }, severity = 1 },
        { role = "mechanic", voice = "phase-change", spellID = 1253788, castType = "begincast", castDuration = 3, firstSeenSec = 70.1, cdSeriesSec = { 120.1 }, severity = 2, preAlertSec = 3 },
    },
})

