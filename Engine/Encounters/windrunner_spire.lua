---@diagnostic disable: undefined-global
-- TomoBoss — Donjon : Flèche des Coursevent
-- Données de timeline converties depuis EXBoss (saison 12.0 S1).
-- Les noms de capacités sont résolus en direct depuis le client (spellID) ;
-- ils s'affichent donc dans la langue du jeu (français sur un client FR).

local NS = select(2, ...)
local R = function(id, def) NS.Engine:RegisterEncounter(id, def) end

-- Emberdawn  (encounterID 3056)
R(3056, {
    name = "Emberdawn",
    dungeon = "Flèche des Coursevent",
    events = {
        { role = "heal", voice = "prepare-target", spellID = 466556, castType = "begincast", castDuration = 1.5, firstSeenSec = 6.1, cdSeriesSec = { 40.1, 15.8, 38.9, 15.8 }, severity = 1 },
        { role = "tank", voice = "tank-buster", spellID = 466064, castType = "begincast", castDuration = 3, firstSeenSec = 10.9, cdSeriesSec = { 40.1, 13.4, 41.3, 13.4 }, severity = 0 },
        { role = "heal", voice = "prepare-aoe", spellID = 467040, castType = "begincast", firstSeenSec = 16.2, cdSeriesSec = { 54.3 }, severity = 2, preAlertSec = 3 },
    },
})

-- Derelict Duo  (encounterID 3057)
R(3057, {
    name = "Derelict Duo",
    dungeon = "Flèche des Coursevent",
    events = {
        { role = "other", voice = "target-drop-water", spellID = 472745, castType = "begincast", castDuration = 4, firstSeenSec = 8, cdSeriesSec = { 27.3, 30.7 }, severity = 1 },
        { role = "tank", voice = "tank-buster", spellID = 472888, castType = "begincast", castDuration = 2, firstSeenSec = 17.4, cdSeriesSec = { 58 }, severity = 0 },
        { role = "heal", voice = "prepare-dispel", spellID = 474105, castType = "begincast", castDuration = 4, firstSeenSec = 22.7, cdSeriesSec = { 58 }, severity = 1 },
        { role = "mechanic", voice = "prepare-hook", spellID = 472795, castType = "begincast", castDuration = 7, firstSeenSec = 48, cdSeriesSec = { 58.1 }, severity = 2, preAlertSec = 3 },
    },
})

-- Commander Kroluk  (encounterID 3058)
R(3058, {
    name = "Commander Kroluk",
    dungeon = "Flèche des Coursevent",
    events = {
        { role = "tank", voice = "tank-buster", spellID = 467620, castType = "begincast", castDuration = 2, firstSeenSec = 3.2, cdSeriesSec = { 52.2, 30.5, 8.4, 11, 41.3, 9.7, 14.7, 15.7, 26.7, 51.1 }, severity = 0 },
        { role = "tank", voice = "tank-buster", spellID = 467620, castType = "begincast", castDuration = 2, firstSeenSec = 3.2, cdSeriesSec = { 52.2, 30.5, 8.4, 11, 41.3, 9.7, 14.7, 15.7, 26.7, 51.1 }, severity = 0 },
        { role = "heal", voice = "prepare-target", spellID = 472053, castType = "begincast", castDuration = 3, firstSeenSec = 10.5, cdSeriesSec = { 3.4, 23.4, 3.4, 22, 3.4, 27, 3.5, 4.9, 3.4, 7.5, 3.4, 4, 3.4, 4.9, 3.4, 7.5, 3.4, 20.9, 3.4, 11.2, 3.4, 12.3, 3.4, 7.6, 3.4, 12.3, 3.4, 23.4, 3.4, 20.9, 3.4 }, severity = 1 },
        { role = "heal", voice = "prepare-target", spellID = 472053, castType = "begincast", castDuration = 3, firstSeenSec = 10.5, cdSeriesSec = { 3.4, 23.4, 3.4, 22, 3.4, 27, 3.5, 4.9, 3.4, 7.5, 3.4, 4, 3.4, 4.9, 3.4, 7.5, 3.4, 20.9, 3.4, 11.2, 3.4, 12.3, 3.4, 7.6, 3.4, 12.3, 3.4, 23.4, 3.4, 20.9, 3.4 }, severity = 1 },
        { role = "mechanic", voice = "prepare-stack", spellID = 1253026, castType = "begincast", castDuration = 5, firstSeenSec = 18.2, cdSeriesSec = { 82.3, 8.4, 10.7, 51.2, 14.7, 15.7, 26.7, 51.1 }, severity = 2, preAlertSec = 3 },
        { role = "mechanic", voice = "prepare-stack", spellID = 1253026, castType = "begincast", castDuration = 5, firstSeenSec = 18.2, cdSeriesSec = { 82.3, 8.4, 10.7, 51.2, 14.7, 15.7, 26.7, 51.1 }, severity = 2, preAlertSec = 3 },
        { role = "mechanic", voice = "phase-change", spellID = 472043, castType = "begincast", castDuration = 4, firstSeenSec = 51.9, cdSeriesSec = { 10.8, 7.3, 63.3, 20.5, 26.7 }, severity = 2, preAlertSec = 3 },
        { role = "other", voice = "away-boss", spellID = 1271676, castType = "begincast", castDuration = 3, firstSeenSec = 56.7, cdSeriesSec = { 9, 9, 9.1, 9, 45.2, 9, 9, 2.5, 6.6, 3.2, 9, 8, 9, 9 }, severity = 1 },
    },
})

-- Restless Heart  (encounterID 3059)
R(3059, {
    name = "Restless Heart",
    dungeon = "Flèche des Coursevent",
    events = {
        { role = "mechanic", voice = "prepare-arrow", spellID = 468429, castType = "begincast", castDuration = 7, firstSeenSec = 25.5, cdSeriesSec = { 65 }, severity = 2, preAlertSec = 3 },
        { role = "tank", voice = "tank-buster", spellID = 472662, castType = "begincast", castDuration = 2.5, firstSeenSec = 57, cdSeriesSec = { 65 }, severity = 0 },
        { role = "heal", voice = "clear-water", spellID = 1253986, castType = "cast", firstSeenSec = 60, cdSeriesSec = { 65 }, severity = 1 },
        { role = "heal", voice = "prepare-target", spellID = 474528, castType = "begincast", castDuration = 4, firstSeenSec = 75.1, cdSeriesSec = { 65 }, severity = 1 },
    },
})

