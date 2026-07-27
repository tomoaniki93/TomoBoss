---@diagnostic disable: undefined-global
-- TomoBoss — Donjon : Siège du Triumvirat
-- Les noms de capacités sont résolus en direct depuis le client (spellID) ;
-- ils s'affichent donc dans la langue du jeu (français sur un client FR).

local NS = select(2, ...)
local R = function(id, def) NS.Engine:RegisterEncounter(id, def) end

-- Zuraal the Ascended  (encounterID 2065)
R(2065, {
    name = "Zuraal the Ascended",
    provenance = "exboss",
    dungeon = "Siège du Triumvirat",
    events = {
        { role = "tank", voice = "tank-buster", spellID = 1263440, eventID = 226, castType = "cast", firstSeenSec = 4.1, cdSeriesSec = { 40, 17 }, severity = 1 },
        { role = "mechanic", voice = "prepare-target", spellID = 1263282, eventID = 224, castType = "begincast", castDuration = 5, firstSeenSec = 7.8, cdSeriesSec = { 29.1, 26.7, 28.8, 28.2, 28.3, 29.9 }, severity = 1 },
        { role = "other", voice = "dodge-frontal", spellID = 1268916, eventID = 223, castType = "begincast", castDuration = 3.5, firstSeenSec = 16.3, cdSeriesSec = { 57.1 }, severity = 1 },
        { role = "heal", voice = "summon-adds", spellID = 1263399, eventID = 225, castType = "begincast", castDuration = 3, firstSeenSec = 22.4, cdSeriesSec = { 57.1 }, severity = 1 },
        { role = "mechanic", voice = "prepare-aoe", spellID = 1263297, eventID = 238, castType = "begincast", castDuration = 5, firstSeenSec = 50.3, cdSeriesSec = { 57.1 }, severity = 2, preAlertSec = 3 },
    },
})

-- Saprish  (encounterID 2066)
R(2066, {
    name = "Saprish",
    provenance = "exboss",
    dungeon = "Siège du Triumvirat",
    events = {
        { role = "other", voice = "interrupt-now", spellID = 248831, eventID = 236, castType = "begincast", castDuration = 5, firstSeenSec = 5.2, cdSeriesSec = { 16.6, 14.3, 16, 15.8, 15.7, 16.3, 15.2, 15.4, 15.8 }, severity = 1 },
        { role = "heal", voice = "prepare-target", spellID = 245738, eventID = 237, castType = "cast", firstSeenSec = 8.6, cdSeriesSec = { 12.1, 12.2, 12.6, 12.2, 12, 12.2, 12.2 }, severity = 1 },
        { role = "mechanic", voice = "clear-ball", spellID = 1263509, eventID = 235, castType = "begincast", firstSeenSec = 20, cdSeriesSec = { 38 }, severity = 1 },
        { role = "heal", voice = "prepare-aoe", spellID = 1263523, eventID = 243, castType = "begincast", castDuration = 4, firstSeenSec = 32, cdSeriesSec = { 38 }, severity = 2, preAlertSec = 3 },
    },
})

-- Viceroy Nezhar  (encounterID 2067)
R(2067, {
    name = "Viceroy Nezhar",
    provenance = "exboss",
    dungeon = "Siège du Triumvirat",
    events = {
        { role = "other", voice = "prepare-interrupt", spellID = 244750, eventID = 244, castType = "begincast", castDuration = 2, firstSeenSec = 4, cdSeriesSec = { 4, 12, 16, 6, 27 }, severity = 1 },
        { role = "heal", voice = "prepare-aoe", spellID = 1263542, eventID = 245, castType = "begincast", castDuration = 2, firstSeenSec = 12, cdSeriesSec = { 65 }, severity = 1 },
        { role = "heal", voice = "switch-add", spellID = 1263538, eventID = 246, castType = "begincast", castDuration = 3, firstSeenSec = 26, cdSeriesSec = { 65 }, severity = 1 },
        { role = "mechanic", voice = "watch-launch-hit", spellID = 1263528, eventID = 247, castType = "begincast", castDuration = 2, firstSeenSec = 45, cdSeriesSec = { 65 }, severity = 2, preAlertSec = 3 },
    },
})

-- L'ura  (encounterID 2068)
R(2068, {
    name = "L'ura",
    provenance = "exboss",
    dungeon = "Siège du Triumvirat",
    events = {
        { role = "heal", voice = "prepare-aoe", spellID = 1265419, eventID = 248, castType = "cast", firstSeenSec = 0, cdSeriesSec = { 97.1, 33.4, 63.8 }, severity = 1 },
        { role = "heal", voice = "prepare-aoe", spellID = 1265421, eventID = 249, castType = "begincast", castDuration = 4, firstSeenSec = 1.5, cdSeriesSec = { 97.1, 33.4, 63.7 }, severity = 1 },
        { role = "other", voice = "prepare-dance", spellID = 1264196, eventID = 251, castType = "begincast", castDuration = 3, firstSeenSec = 12, cdSeriesSec = { 33, 33, 31, 33, 33.4, 33 }, severity = 1 },
        { role = "mechanic", voice = "aim-note", spellID = 1265463, eventID = 250, castType = "begincast", castDuration = 7, firstSeenSec = 24, cdSeriesSec = { 33, 33, 31.1, 33, 33.4, 33 }, severity = 1 },
        { role = "other", voice = "watch-dodge", spellID = 1265689, eventID = 252, castType = "begincast", castDuration = 5.5, firstSeenSec = 35, cdSeriesSec = { 33, 64, 33.4, 33 }, severity = 1 },
        { role = "mechanic", voice = "phase-change", spellID = 1266003, eventID = 253, castType = "begincast", castDuration = 10, firstSeenSec = 65.5, cdSeriesSec = { 33, 64.1, 66.4 }, severity = 2, preAlertSec = 3 },
        { role = "mechanic", voice = "watch-knockback", spellID = 1266001, eventID = 254, castType = "cast", firstSeenSec = 96, cdSeriesSec = { 33.4, 63.8 }, severity = 2, preAlertSec = 3 },
    },
})

