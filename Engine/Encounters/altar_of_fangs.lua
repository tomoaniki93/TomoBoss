---@diagnostic disable: undefined-global
-- TomoBoss — Donjon : Altar of Fangs / Autel des Crochets
--
-- Données de MATCHING générées depuis les captures TomoBoss (module Learn).
-- Chaque durée ci-dessous a été observée au moins 3 fois sur
-- ENCOUNTER_TIMELINE_EVENT_ADDED en jeu. Aucune source tierce.
--
-- `matchOnly = true` : le minutage vient de C_EncounterTimeline, ces valeurs
-- ne servent qu'à identifier la capacité. Rôles, voix et sévérités sont des
-- choix éditoriaux conservés depuis la version précédente.

local NS = select(2, ...)
local R = function(id, def) NS.Engine:RegisterEncounter(id, def) end

-- Rav'i  (encounterID 3456) — 7 pull(s) capturé(s)
R(3456, {
    name = "Rav'i",
    provenance = "observed",
    dungeon = "Altar of Fangs",
    matchOnly = true,
    events = {
        { role = "other", voice = "watch-dodge", spellID = 1307703, firstSeenSec = 8, cdSeriesSec = { 8, 24 }, severity = 1 },  -- Triple Shot | AMBIGU : durée 24 partagée  [vu 8×15 24×8]
        { role = "other", voice = "watch-dodge", spellID = 1296050, firstSeenSec = 13, cdSeriesSec = { 13 }, severity = 1 },  -- Regurgitate  [vu 13×8]
        { role = "other", voice = "watch-shockwave", spellID = 1307894, firstSeenSec = 23, cdSeriesSec = { 23 }, severity = 1 },  -- Ravenous Stomp | AMBIGU : durée 24 partagée  [vu 23×8]
        { role = "other", voice = "std-move", spellID = 1296216, firstSeenSec = 25, cdSeriesSec = { 25, 45 }, severity = 0 },  -- Ssscavenging  [vu 25×7 45×8]
    },
})

-- The Writhing Coil  (encounterID 3457) — 7 pull(s) capturé(s)
R(3457, {
    name = "The Writhing Coil",
    provenance = "observed",
    dungeon = "Altar of Fangs",
    matchOnly = true,
    events = {
        { role = "other", voice = "prepare-dispel", spellID = 1299154, firstSeenSec = 1, cdSeriesSec = { 1, 10 }, severity = 1 },  -- Synchronized Venom | AMBIGU : durée 10 partagée  [vu 1×7 10×11]
        { role = "other", voice = "std-move", spellID = 1298949, firstSeenSec = 7, cdSeriesSec = { 7, 16 }, severity = 0 },  -- Tail Scythe  [vu 7×7 16×4]
        { role = "other", voice = "special-mechanic", spellID = 1310547, firstSeenSec = 10, cdSeriesSec = { 10 }, severity = 2 },  -- Toxic Atrophy | AMBIGU : durée 10 partagée  [vu 10×11]
        { role = "other", voice = "watch-dodge", spellID = 1310357, firstSeenSec = 14, cdSeriesSec = { 14, 23 }, severity = 1 },  -- Preparing Toxin  [vu 14×7 23×4]
        { role = "other", voice = "std-move", spellID = 1300686, firstSeenSec = 25, cdSeriesSec = { 25 }, severity = 0 },  -- Assimilation  [vu 25×7]
        { role = "tank", voice = "tank-buster", spellID = 1299940, firstSeenSec = 30, cdSeriesSec = { 30, 39 }, severity = 1 },  -- Vindictive Onslaught  [vu 30×7 39×4]
        { role = "other", voice = "special-mechanic", spellID = 1299053, firstSeenSec = 44, cdSeriesSec = { 44, 53 }, severity = 2 },  -- Death Rattle  [vu 44×7 53×4]
    },
})

-- Zul'jan  (encounterID 3458) — 5 pull(s) capturé(s)
R(3458, {
    name = "Zul'jan",
    provenance = "observed",
    dungeon = "Altar of Fangs",
    matchOnly = true,
    events = {
        { role = "other", voice = "watch-dodge", spellID = 1301111, firstSeenSec = 14, cdSeriesSec = { 14 }, severity = 1 },  -- Axegrinder | AMBIGU : durée 14 partagée  [vu 14×19]
        { role = "other", voice = "special-mechanic", spellID = 1301413, firstSeenSec = 14, cdSeriesSec = { 14, 32 }, severity = 2 },  -- Boneslicer | AMBIGU : durée 14 partagée  [vu 14×19 32×11]
        { role = "other", voice = "std-move", spellID = 1301350, firstSeenSec = 26, cdSeriesSec = { 26, 30 }, severity = 0 },  -- Chop Down  [vu 26×11 30×8]
        { role = "other", voice = "std-move", spellID = 1300876, firstSeenSec = 64, cdSeriesSec = { 64 }, severity = 0 },  -- Ritual of the Fang  [vu 64×11]
    },
})

