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

-- Kystia Manaheart  (encounterID 3101) — 8 pull(s) capturé(s)
R(3101, {
    name = "Kystia Manaheart",
    provenance = "observed",
    dungeon = "Murder Row",
    matchOnly = true,
    events = {
        { role = "other", voice = "prepare-beam", spellID = 1253811, firstSeenSec = 8, cdSeriesSec = { 8, 27.5 }, severity = 2 },  -- Fel Spray  [vu 8×18 27.5×17]
        { role = "other", voice = "prepare-aoe", spellID = 474240, firstSeenSec = 12, cdSeriesSec = { 12, 25 }, severity = 1 },  -- Fel Nova  [vu 12×32 25×4]
        { role = "other", voice = "summon-adds", spellID = 1264095, firstSeenSec = 15, cdSeriesSec = { 15, 30 }, severity = 0 },  -- Mirror Images  [vu 15×18 30×12]
    },
})

-- Zaen Bladesorrow  (encounterID 3102) — 6 pull(s) capturé(s)
R(3102, {
    name = "Zaen Bladesorrow",
    provenance = "observed",
    dungeon = "Murder Row",
    matchOnly = true,
    events = {
        { role = "other", voice = "watch-dodge", spellID = 474478, eventID = 835, firstSeenSec = 8, cdSeriesSec = { 8 }, severity = 1 },  -- Killing Spree  [vu 8×17]
        { role = "mechanic", voice = "watch-dodge", spellID = 474765, eventID = 836, firstSeenSec = 12, cdSeriesSec = { 12, 16 }, severity = 1 },  -- Same-Day Delivery  [vu 12×17 16×16]
        { role = "other", voice = "watch-dodge", spellID = 1214357, eventID = 837, firstSeenSec = 18, cdSeriesSec = { 18 }, severity = 2 },  -- Fire Bomb  [vu 18×17]
        { role = "mechanic", voice = "prepare-interrupt", spellID = 1222795, eventID = 838, firstSeenSec = 26, cdSeriesSec = { 26 }, severity = 1 },  -- Envenom  [vu 26×17]
        { role = "mechanic", voice = "watch-frontal", spellID = 1218347, eventID = 839, firstSeenSec = 36, cdSeriesSec = { 36 }, severity = 2 },  -- Murder in a Row  [vu 36×17]
    },
})

-- Xathuux the Annihilator  (encounterID 3103) — 5 pull(s) capturé(s)
R(3103, {
    name = "Xathuux the Annihilator",
    provenance = "observed",
    dungeon = "Murder Row",
    matchOnly = true,
    events = {
        { role = "tank", voice = "tank-buster", spellID = 473898, eventID = 845, firstSeenSec = 6, cdSeriesSec = { 6, 27 }, severity = 2 },  -- Legion Strike  [vu 6×12 27×19]
        { role = "other", voice = "watch-knockback", spellID = 1214637, firstSeenSec = 15, cdSeriesSec = { 15 }, severity = 2 },  -- Axe Toss  [vu 15×12]
        { role = "tank", voice = "tank-buster", spellID = 1295453, firstSeenSec = 30, cdSeriesSec = { 30 }, severity = 1 },  -- Infernal Crush  [vu 30×12]
        { role = "other", voice = "watch-dodge", spellID = 474197, firstSeenSec = 35, cdSeriesSec = { 35 }, severity = 1 },  -- Demonic Rage  [vu 35×12]
    },
})

-- Lithiel Cinderfury  (encounterID 3105) — 5 pull(s) capturé(s)
R(3105, {
    name = "Lithiel Cinderfury",
    provenance = "observed",
    dungeon = "Murder Row",
    matchOnly = true,
    events = {
        { role = "other", voice = "summon-adds", spellID = 474408, firstSeenSec = 10, cdSeriesSec = { 10, 57 }, severity = 0 },  -- Summon Vilefiend  [vu 10×5 57×10]
        { role = "other", voice = "watch-dodge", spellID = 1218203, firstSeenSec = 15, cdSeriesSec = { 15, 55 }, severity = 1 },  -- Fingers of Gul'dan  [vu 15×5 55×9]
        { role = "other", voice = "watch-dodge", spellID = 1224478, firstSeenSec = 24, cdSeriesSec = { 24, 59 }, severity = 2 },  -- Malefic Wave  [vu 24×5 59×7]
    },
})

