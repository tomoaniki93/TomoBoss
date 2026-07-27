---@diagnostic disable: undefined-global
-- TomoBoss — Donjon : Point de Nexus : Xenas
-- Les noms de capacités sont résolus en direct depuis le client (spellID) ;
-- ils s'affichent donc dans la langue du jeu (français sur un client FR).

local NS = select(2, ...)
local R = function(id, def) NS.Engine:RegisterEncounter(id, def) end

-- Chief Corewright Kasreth  (encounterID 3328)
R(3328, {
    name = "Chief Corewright Kasreth",
    provenance = "exboss",
    dungeon = "Point de Nexus : Xenas",
    events = {
        { role = "other", voice = "target-clear-line", spellID = 1251772, eventID = 107, castType = "begincast", castDuration = 2.1, firstSeenSec = 5.7, cdSeriesSec = { 12.1, 12.1, 25.8 }, severity = 2, preAlertSec = 3 },
        { role = "other", voice = "watch-dodge", spellID = 1264048, eventID = 172, castType = "cast", firstSeenSec = 10.5, cdSeriesSec = { 13.3, 29.5, 13.3, 15.8, 26.7, 14.6, 13.3, 26.7, 14.6, 15.7, 26.7 }, severity = 0 },
        { role = "heal", voice = "prepare-aoe", spellID = 1257509, eventID = 106, castType = "begincast", castDuration = 5, firstSeenSec = 46.6, cdSeriesSec = { 52.1, 53.3 }, severity = 2, preAlertSec = 3 },
    },
})

-- Corewarden Nysarra  (encounterID 3332)
R(3332, {
    name = "Corewarden Nysarra",
    provenance = "exboss",
    dungeon = "Point de Nexus : Xenas",
    events = {
        { role = "tank", voice = "tank-buster", spellID = 1247937, eventID = 35, castType = "begincast", castDuration = 0.8, firstSeenSec = 3.8, cdSeriesSec = { 17.8, 38.8, 18.6, 17.8, 25.9, 17 }, severity = 0 },
        { role = "heal", voice = "prepare-target", spellID = 1249027, eventID = 33, castType = "begincast", castDuration = 2.5, firstSeenSec = 10.7, cdSeriesSec = { 19, 37.6, 18.6, 43.7, 18.2 }, severity = 2, preAlertSec = 3 },
        { role = "mechanic", voice = "phase-change", spellID = 1264439, eventID = 34, castType = "cast", castDuration = 4.2, firstSeenSec = 36.8, cdSeriesSec = { 62.1 }, severity = 2, preAlertSec = 3 },
    },
})

-- Lothraxion  (encounterID 3333)
R(3333, {
    name = "Lothraxion",
    provenance = "exboss",
    dungeon = "Point de Nexus : Xenas",
    events = {
        { role = "tank", voice = "tank-buster", spellID = 1253950, eventID = 111, castType = "begincast", castDuration = 3, firstSeenSec = 2.2, cdSeriesSec = { 26.9, 38.9, 3.9, 22.8, 3.9, 33.5, 16.3, 10.5, 16.3, 21.6, 17.3, 9.4, 17.3 }, severity = 0 },
        { role = "heal", voice = "prepare-target", spellID = 1253855, eventID = 109, castType = "begincast", castDuration = 4, firstSeenSec = 11.1, cdSeriesSec = { 25.1, 39.1, 2.2, 23.3, 2.2, 37.6, 16.3, 9.2, 16.3, 22.8, 17.3, 8.2, 17.3 }, severity = 2, preAlertSec = 3 },
        { role = "other", voice = "watch-dodge", spellID = 1255531, eventID = 112, castType = "cast", firstSeenSec = 29.3, cdSeriesSec = { 10.7, 10.4, 43.3, 3.9, 7, 3.9, 6.9, 4, 38.4, 10.9, 6.6, 4.3, 6.6, 11, 25.1, 2.3, 8.7, 2.3, 4.1, 10.9 }, severity = 0 },
        { role = "mechanic", voice = "phase-change", spellID = 1257601, eventID = 110, castType = "begincast", castDuration = 0.5, firstSeenSec = 60.5, cdSeriesSec = { 64.3, 3.9, 60.3, 17.5 }, severity = 2, preAlertSec = 3 },
    },
})

