---@diagnostic disable: undefined-global
-- TomoBoss — Donjon : The Blinding Vale / Le Val Aveuglant
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

-- Lightblossom Trinity  (encounterID 3199) — 5 pull(s) capturé(s)
R(3199, {
    name = "Lightblossom Trinity",
    provenance = "observed",
    dungeon = "The Blinding Vale",
    matchOnly = true,
    events = {
        { role = "other", voice = "watch-dodge", spellID = 1235640, firstSeenSec = 8, cdSeriesSec = { 8, 10 }, severity = 1 },  -- Thornblade | round-robin LittleWigs sur 40-45 s — non transposable  [vu 8×3 10×12]
        { role = "tank", voice = "tank-buster", spellID = 1234753, firstSeenSec = 5, cdSeriesSec = { 5 }, severity = 0 },  -- Bedrock Slam | round-robin LittleWigs sur 40-45 s — non transposable  [vu 5×5]
        { role = "other", voice = "dodge-charge", spellID = 1234850, firstSeenSec = 20, cdSeriesSec = { 20 }, severity = 2 },  -- Lightsower Dash | round-robin LittleWigs sur 40-45 s — non transposable  [vu 20×5]
        { role = "other", voice = "prepare-beam", spellID = 1235564, firstSeenSec = 35, cdSeriesSec = { 35 }, severity = 0 },  -- Lightblossom Beam | round-robin LittleWigs sur 40-45 s — non transposable  [vu 35×5]
        { role = "other", voice = "watch-dodge", firstSeenSec = 45, cdSeriesSec = { 45 }, severity = 1 },  -- TODO identifier  [vu 45×27]
    },
})

-- Ikuzz the Light Hunter  (encounterID 3200) — 5 pull(s) capturé(s)
R(3200, {
    name = "Ikuzz the Light Hunter",
    provenance = "observed",
    dungeon = "The Blinding Vale",
    matchOnly = true,
    events = {
        { role = "other", voice = "watch-shockwave", spellID = 1236746, firstSeenSec = 6, cdSeriesSec = { 6, 29 }, severity = 1 },  -- Verdant Stomp  [vu 6×9 29×14]
        { role = "other", voice = "prepare-interrupt", spellID = 1236709, firstSeenSec = 20, cdSeriesSec = { 20, 22 }, severity = 2 },  -- Thorncaller Roar  [vu 20×3 22×6]
        { role = "other", voice = "prepare-beam", spellID = 1237090, firstSeenSec = 40, cdSeriesSec = { 40, 50 }, severity = 2 },  -- Bloodthirsty Gaze  [vu 40×3 50×6]
        { role = "other", voice = "watch-dodge", firstSeenSec = 60, cdSeriesSec = { 60 }, severity = 1 },  -- TODO identifier  [vu 60×3]
        { role = "other", voice = "watch-dodge", firstSeenSec = 62, cdSeriesSec = { 62 }, severity = 1 },  -- TODO identifier  [vu 62×3]
        { role = "other", voice = "watch-dodge", firstSeenSec = 63, cdSeriesSec = { 63 }, severity = 1 },  -- TODO identifier  [vu 63×3]
    },
})

-- Lightwarden Ruia  (encounterID 3201) — 5 pull(s) capturé(s)
R(3201, {
    name = "Lightwarden Ruia",
    provenance = "observed",
    dungeon = "The Blinding Vale",
    matchOnly = true,
    events = {
        { role = "other", voice = "phase-change", spellID = 1239882, firstSeenSec = 0.5, cdSeriesSec = { 0.5 }, severity = 0 },  -- Shapeshift: Moonkin  [vu 0.5×5]
        { role = "tank", voice = "tank-buster", spellID = 1241058, eventID = 882, firstSeenSec = 2.5, cdSeriesSec = { 2.5, 3, 15.3, 32 }, severity = 2 },  -- Grievous Thrash | AMBIGU : durée 32 partagée | round-robin LittleWigs sur 20-21 s — non transposable  [vu 2.5×3 3×5 15.3×3 32×12]
        { role = "other", voice = "watch-dodge", spellID = 1239824, firstSeenSec = 5, cdSeriesSec = { 5, 7.3, 32 }, severity = 1 },  -- Lightfire | AMBIGU : durée 32 partagée | round-robin LittleWigs sur 20-21 s — non transposable  [vu 5×5 7.3×3 32×12]
        { role = "tank", voice = "tank-buster", spellID = 1240210, firstSeenSec = 9, cdSeriesSec = { 9, 31.3, 32 }, severity = 1 },  -- Pulverizing Strikes | AMBIGU : durée 31.3/32 partagée | round-robin LittleWigs sur 20-21 s — non transposable  [vu 9×5 31.3×3 32×12]
        { role = "other", voice = "watch-dodge", spellID = 1240098, firstSeenSec = 18, cdSeriesSec = { 18, 23.3, 32 }, severity = 1 },  -- Lightfall | AMBIGU : durée 32 partagée | round-robin LittleWigs sur 20-21 s — non transposable  [vu 18×5 23.3×3 32×12]
        { role = "other", voice = "watch-dodge", firstSeenSec = 21, cdSeriesSec = { 21 }, severity = 1 },  -- TODO identifier  [vu 21×12]
    },
})

-- Ziekket  (encounterID 3202) — 5 pull(s) capturé(s)
R(3202, {
    name = "Ziekket",
    provenance = "observed",
    dungeon = "The Blinding Vale",
    matchOnly = true,
    events = {
        { role = "other", voice = "phase-change", spellID = 1246372, firstSeenSec = 4, cdSeriesSec = { 4, 45, 50 }, severity = 0 },  -- Awaken the Lightbloom | AMBIGU : durée 45/50 partagée  [vu 4×5 45×9 50×21]
        { role = "other", voice = "prepare-soak", spellID = 1246858, firstSeenSec = 14, cdSeriesSec = { 14, 50 }, severity = 1 },  -- Lightbloom's Essence | AMBIGU : durée 50 partagée  [vu 14×3 50×21]
        { role = "tank", voice = "tank-buster", spellID = 1247685, firstSeenSec = 26, cdSeriesSec = { 26, 45, 50 }, severity = 0 },  -- Thornspike | AMBIGU : durée 45/50 partagée  [vu 26×3 45×9 50×21]
        { role = "other", voice = "prepare-beam", spellID = 1246607, firstSeenSec = 40, cdSeriesSec = { 40, 45, 50 }, severity = 1 },  -- Concentrated Lightbeam | AMBIGU : durée 45/50 partagée  [vu 40×3 45×9 50×21]
    },
})

