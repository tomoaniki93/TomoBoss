---@diagnostic disable: undefined-global
-- TomoBoss — Donjon : Cime-du-Ciel
-- Données de timeline converties depuis EXBoss (saison 12.0 S1).
-- Les noms de capacités sont résolus en direct depuis le client (spellID) ;
-- ils s'affichent donc dans la langue du jeu (français sur un client FR).

local NS = select(2, ...)
local R = function(id, def) NS.Engine:RegisterEncounter(id, def) end

-- Ranjit  (encounterID 1698)
R(1698, {
    name = "Ranjit",
    dungeon = "Cime-du-Ciel",
    events = {
        { role = "other", voice = "watch-knockback", spellID = 1252690, castType = "begincast", castDuration = 3, firstSeenSec = 5, cdSeriesSec = { 40 }, severity = 1 },
        { role = "heal", voice = "prepare-aoe", spellID = 153757, castType = "begincast", castDuration = 2, firstSeenSec = 12, cdSeriesSec = { 20 }, severity = 1 },
        { role = "other", voice = "watch-frontal", spellID = 1258152, castType = "begincast", castDuration = 3, firstSeenSec = 18, cdSeriesSec = { 10, 30 }, severity = 1 },
        { role = "mechanic", voice = "watch-dodge", spellID = 156793, castType = "begincast", castDuration = 3, firstSeenSec = 35, cdSeriesSec = { 40 }, severity = 2, preAlertSec = 3 },
    },
})

-- Araknath  (encounterID 1699)
R(1699, {
    name = "Araknath",
    dungeon = "Cime-du-Ciel",
    events = {
        { role = "tank", voice = "watch-frontal", spellID = 154113, castType = "begincast", castDuration = 3, firstSeenSec = 5, cdSeriesSec = { 15, 20, 34, 15, 5, 19, 30, 5, 19, 10, 5, 15, 5 }, severity = 1 },
        { role = "heal", voice = "prepare-aoe", spellID = 154135, castType = "begincast", castDuration = 4, firstSeenSec = 50, cdSeriesSec = { 54 }, severity = 2, preAlertSec = 3 },
    },
})

-- Rukhran  (encounterID 1700)
R(1700, {
    name = "Rukhran",
    dungeon = "Cime-du-Ciel",
    events = {
        { role = "tank", voice = "tank-buster", spellID = 1253519, castType = "begincast", castDuration = 3, firstSeenSec = 5, cdSeriesSec = { 12, 35 }, severity = 1 },
        { role = "heal", voice = "switch-add", spellID = 1253510, castType = "begincast", castDuration = 3, firstSeenSec = 12, cdSeriesSec = { 21, 26 }, severity = 1 },
        { role = "other", spellID = 1253416, castType = "begincast", castDuration = 3, firstSeenSec = 25.9, cdSeriesSec = { 22.7, 25.5, 23.5, 22.3, 23, 27.8 }, severity = 1 },
        { role = "mechanic", voice = "fix-camera", spellID = 159382, castType = "begincast", castDuration = 5, firstSeenSec = 39.3, cdSeriesSec = { 46.7, 47.7 }, severity = 2, preAlertSec = 3 },
    },
})

-- High Sage Viryx  (encounterID 1701)
R(1701, {
    name = "High Sage Viryx",
    dungeon = "Cime-du-Ciel",
    events = {
        { role = "heal", voice = "prepare-target", spellID = 1253538, castType = "cast", firstSeenSec = 5, cdSeriesSec = { 10, 10, 19 }, severity = 1 },
        { role = "other", voice = "interrupt-now", spellID = 154396, castType = "begincast", castDuration = 3, firstSeenSec = 8, cdSeriesSec = { 12, 27 }, severity = 1 },
        { role = "mechanic", voice = "switch-add", spellID = 153954, castType = "cast", firstSeenSec = 12, cdSeriesSec = { 39 }, severity = 1 },
        { role = "mechanic", voice = "prepare-beam", spellID = 1253840, castType = "begincast", castDuration = 3, firstSeenSec = 30, cdSeriesSec = { 39 }, severity = 2, preAlertSec = 3 },
    },
})

