---@diagnostic disable: undefined-global
-- TomoBoss — Donjon : Fosse de Saron
-- Données de timeline converties depuis EXBoss (saison 12.0 S1).
-- Les noms de capacités sont résolus en direct depuis le client (spellID) ;
-- ils s'affichent donc dans la langue du jeu (français sur un client FR).

local NS = select(2, ...)
local R = function(id, def) NS.Engine:RegisterEncounter(id, def) end

-- Forgemaster Garfrost  (encounterID 1999)
R(1999, {
    name = "Forgemaster Garfrost",
    dungeon = "Fosse de Saron",
    events = {
        { role = "other", voice = "watch-dodge", spellID = 1261299, castType = "begincast", castDuration = 2, firstSeenSec = 7, cdSeriesSec = { 41.5 }, severity = 1 },
        { role = "tank", voice = "tank-buster", spellID = 1261546, castType = "begincast", castDuration = 4.5, firstSeenSec = 20, cdSeriesSec = { 41.5 }, severity = 0 },
        { role = "other", voice = "fix-camera", spellID = 1262029, castType = "begincast", castDuration = 5, firstSeenSec = 33, cdSeriesSec = { 41.5 }, severity = 2, preAlertSec = 3 },
        { role = "heal", voice = "prepare-aoe", spellID = 1261847, castType = "begincast", castDuration = 2.5, firstSeenSec = 41.6, cdSeriesSec = { 41.5 }, severity = 1 },
    },
})

-- Ick and Krick  (encounterID 2001)
R(2001, {
    name = "Ick and Krick",
    dungeon = "Fosse de Saron",
    events = {
        { role = "mechanic", voice = "prepare-aoe", spellID = 1264027, castType = "begincast", castDuration = 4, firstSeenSec = 0, cdSeriesSec = { 82.8 }, severity = 1 },
        { role = "tank", voice = "tank-buster", spellID = 1264287, castType = "begincast", castDuration = 4, firstSeenSec = 11, cdSeriesSec = { 19, 63.8 }, severity = 0 },
        { role = "other", voice = "prepare-aoe", spellID = 1264336, castType = "begincast", castDuration = 2.5, firstSeenSec = 21, cdSeriesSec = { 19, 63.8 }, severity = 1 },
        { role = "mechanic", voice = "prepare-target", spellID = 1264363, castType = "begincast", castDuration = 4, firstSeenSec = 50, cdSeriesSec = { 82.8 }, severity = 2, preAlertSec = 3 },
        { role = "mechanic", voice = "prepare-fixate", spellID = 1264453, castType = "begincast", castDuration = 2, firstSeenSec = 54.8, cdSeriesSec = { 7, 7, 7, 61.8 }, severity = 1 },
    },
})

-- Scourgelord Tyrannus  (encounterID 2000)
R(2000, {
    name = "Scourgelord Tyrannus",
    dungeon = "Fosse de Saron",
    events = {
        { role = "heal", voice = "prepare-aoe", spellID = 1276648, castType = "begincast", castDuration = 3, firstSeenSec = 0, cdSeriesSec = { 85 }, severity = 1 },
        { role = "mechanic", voice = "find-beacon", spellID = 1262745, castType = "begincast", castDuration = 6, firstSeenSec = 7, cdSeriesSec = { 28, 57 }, severity = 1 },
        { role = "tank", voice = "tank-knockback", spellID = 1262582, castType = "begincast", castDuration = 2.5, firstSeenSec = 14, cdSeriesSec = { 28, 57.1 }, severity = 0 },
        { role = "other", voice = "watch-dodge", spellID = 1263756, castType = "cast", firstSeenSec = 24, cdSeriesSec = { 85 }, severity = 0 },
        { role = "mechanic", voice = "switch-add", spellID = 1263406, castType = "begincast", castDuration = 5, firstSeenSec = 52, cdSeriesSec = { 85 }, severity = 2, preAlertSec = 3 },
        { role = "other", voice = "watch-dodge", spellID = 1276948, castType = "cast", firstSeenSec = 69, cdSeriesSec = { 85 }, severity = 1 },
    },
})

