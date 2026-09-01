---@diagnostic disable: undefined-global
-- TomoBoss — Donjon : Murder Row / L'Allée du Meurtre
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

-- Kystia Manaheart  (encounterID 3101) — 9 pull(s) capturé(s)
R(3101, {
    name = "Kystia Manaheart",
    provenance = "observed",
    dungeon = "Murder Row",
    matchOnly = true,
    events = {
        { role = "other", voice = "prepare-beam", spellID = 1253811, firstSeenSec = 8, cdSeriesSec = { 8, 27.5 }, severity = 2 },  -- Fel Spray  [vu 8×23 27.5×21]
        { role = "other", voice = "prepare-aoe", spellID = 474240, firstSeenSec = 12, cdSeriesSec = { 12, 25 }, severity = 1 },  -- Fel Nova  [vu 12×42 25×4]
        { role = "other", voice = "summon-adds", spellID = 1264095, firstSeenSec = 15, cdSeriesSec = { 15, 30 }, severity = 0 },  -- Mirror Images  [vu 15×23 30×15]
    },
})

-- Zaen Bladesorrow  (encounterID 3102) — 7 pull(s) capturé(s)
R(3102, {
    name = "Zaen Bladesorrow",
    provenance = "observed",
    dungeon = "Murder Row",
    matchOnly = true,
    events = {
        { role = "other", voice = "watch-dodge", spellID = 474478, eventID = 835, firstSeenSec = 8, cdSeriesSec = { 8 }, severity = 1 },  -- Killing Spree  [vu 8×21]
        { role = "mechanic", voice = "watch-dodge", spellID = 474765, eventID = 836, firstSeenSec = 12, cdSeriesSec = { 12, 16 }, severity = 1 },  -- Same-Day Delivery  [vu 12×21 16×20]
        { role = "other", voice = "watch-dodge", spellID = 1214357, eventID = 837, firstSeenSec = 18, cdSeriesSec = { 18 }, severity = 2 },  -- Fire Bomb  [vu 18×21]
        { role = "mechanic", voice = "prepare-interrupt", spellID = 1222795, eventID = 838, firstSeenSec = 26, cdSeriesSec = { 26 }, severity = 1 },  -- Envenom  [vu 26×21]
        { role = "mechanic", voice = "watch-frontal", spellID = 1218347, eventID = 839, firstSeenSec = 36, cdSeriesSec = { 36 }, severity = 2 },  -- Murder in a Row  [vu 36×21]
    },
})

-- Xathuux the Annihilator  (encounterID 3103) — 6 pull(s) capturé(s)
R(3103, {
    name = "Xathuux the Annihilator",
    provenance = "observed",
    dungeon = "Murder Row",
    matchOnly = true,
    events = {
        { role = "tank", voice = "tank-buster", spellID = 473898, eventID = 845, firstSeenSec = 6, cdSeriesSec = { 6, 27 }, severity = 2 },  -- Legion Strike  [vu 6×15 27×24]
        { role = "other", voice = "watch-knockback", spellID = 1214637, firstSeenSec = 15, cdSeriesSec = { 15 }, severity = 2 },  -- Axe Toss  [vu 15×15]
        { role = "tank", voice = "tank-buster", spellID = 1295453, firstSeenSec = 30, cdSeriesSec = { 30 }, severity = 1 },  -- Infernal Crush  [vu 30×15]
        { role = "other", voice = "watch-dodge", spellID = 474197, firstSeenSec = 35, cdSeriesSec = { 35 }, severity = 1 },  -- Demonic Rage  [vu 35×15]
    },
})

-- Lithiel Cinderfury  (encounterID 3105) — 7 pull(s) capturé(s)
R(3105, {
    name = "Lithiel Cinderfury",
    provenance = "observed",
    dungeon = "Murder Row",
    matchOnly = true,
    events = {
        { role = "other", voice = "summon-adds", spellID = 474408, firstSeenSec = 10, cdSeriesSec = { 10, 57 }, severity = 0 },  -- Summon Vilefiend  [vu 10×7 57×15]
        { role = "other", voice = "watch-dodge", spellID = 1218203, firstSeenSec = 15, cdSeriesSec = { 15, 55 }, severity = 1 },  -- Fingers of Gul'dan  [vu 15×7 55×14]
        { role = "other", voice = "watch-dodge", spellID = 1224478, firstSeenSec = 24, cdSeriesSec = { 24, 59 }, severity = 2 },  -- Malefic Wave  [vu 24×7 59×11]
    },
})

