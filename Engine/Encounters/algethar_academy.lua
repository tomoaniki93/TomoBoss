---@diagnostic disable: undefined-global
-- TomoBoss — Donjon : Académie d'Algeth'ar
-- Les noms de capacités sont résolus en direct depuis le client (spellID) ;
-- ils s'affichent donc dans la langue du jeu (français sur un client FR).

local NS = select(2, ...)
local R = function(id, def) NS.Engine:RegisterEncounter(id, def) end

-- Vexamus  (encounterID 2562)
R(2562, {
    name = "Vexamus",
    dungeon = "Académie d'Algeth'ar",
    events = {
        { role = "other", voice = "block-ball", spellID = 387691, eventID = 274, castType = "cast", firstSeenSec = 2, cdSeriesSec = { 18, 26 }, severity = 1 },
        { role = "tank", voice = "tank-buster", spellID = 385958, eventID = 276, castType = "begincast", castDuration = 4, firstSeenSec = 5, cdSeriesSec = { 18, 26 }, severity = 1 },
        { role = "heal", voice = "prepare-target", spellID = 386173, eventID = 275, castType = "begincast", castDuration = 2.5, firstSeenSec = 15, cdSeriesSec = { 18, 26 }, severity = 1 },
        { role = "mechanic", voice = "prepare-aoe", spellID = 388537, eventID = 277, castType = "begincast", castDuration = 3, firstSeenSec = 40, cdSeriesSec = { 44 }, severity = 2, preAlertSec = 3 },
    },
})

-- Overgrown Ancient  (encounterID 2563)
R(2563, {
    name = "Overgrown Ancient",
    dungeon = "Académie d'Algeth'ar",
    events = {
        { role = "tank", voice = "tank-buster", spellID = 388544, eventID = 282, castType = "begincast", castDuration = 1, firstSeenSec = 9, cdSeriesSec = { 28 }, severity = 1 },
        { role = "other", voice = "stack-drop", spellID = 388796, eventID = 284, castType = "cast", firstSeenSec = 18, cdSeriesSec = { 33, 23 }, severity = 1 },
        { role = "mechanic", voice = "summon-adds", spellID = 388623, eventID = 283, castType = "begincast", castDuration = 2.5, firstSeenSec = 30, cdSeriesSec = { 56 }, severity = 1 },
        { role = "mechanic", voice = "prepare-aoe", spellID = 388923, eventID = 285, castType = "begincast", castDuration = 3, firstSeenSec = 55.1, cdSeriesSec = { 56 }, severity = 2, preAlertSec = 3 },
    },
})

-- Crawth  (encounterID 2564)
R(2564, {
    name = "Crawth",
    dungeon = "Académie d'Algeth'ar",
    events = {
        { role = "tank", voice = "tank-buster", spellID = 376997, eventID = 278, castType = "begincast", castDuration = 3, firstSeenSec = 5, cdSeriesSec = { 24, 24, 28.4, 3.7, 2.4, 17.9, 3.7, 2.4, 17.9, 3.7, 2.4, 21.6, 2.4, 20.9, 6, 12.1, 6.1, 4.6, 13.3, 6, 4.7 }, severity = 1 },
        { role = "heal", voice = "prepare-aoe", spellID = 377004, eventID = 279, castType = "begincast", castDuration = 2.5, firstSeenSec = 14, cdSeriesSec = { 24, 24, 28.4, 3.7, 2.4, 17.9, 3.7, 2.4, 17.9, 3.7, 2.4, 21.6, 2.4, 20.9, 6, 12.1, 6.1, 4.7, 13.3, 10.7 }, severity = 1 },
        { role = "other", voice = "watch-frontal", spellID = 377034, eventID = 280, castType = "begincast", castDuration = 4, firstSeenSec = 20, cdSeriesSec = { 24, 52.4, 3.7, 2.4, 17.9, 3.7, 2.4, 17.9, 3.7, 2.4, 24, 20.9, 6, 12.1, 6, 4.7 }, severity = 1 },
    },
})

-- Echo of Doragosa  (encounterID 2565)
R(2565, {
    name = "Echo of Doragosa",
    dungeon = "Académie d'Algeth'ar",
    events = {
        { role = "tank", voice = "tank-buster", spellID = 1282251, eventID = 294, castType = "begincast", castDuration = 3, firstSeenSec = 9, cdSeriesSec = { 12, 21 }, severity = 1 },
        { role = "heal", voice = "prepare-dispel", spellID = 374350, eventID = 295, castType = "begincast", castDuration = 1.5, firstSeenSec = 14, cdSeriesSec = { 33 }, severity = 1 },
        { role = "mechanic", voice = "prepare-pull", spellID = 388822, eventID = 296, castType = "begincast", castDuration = 4, firstSeenSec = 30, cdSeriesSec = { 33 }, severity = 2, preAlertSec = 3 },
    },
})

