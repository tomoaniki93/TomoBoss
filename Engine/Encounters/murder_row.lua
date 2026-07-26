---@diagnostic disable: undefined-global
-- TomoBoss — Donjon : Murder Row (hors-saison Midnight, mapID 2813)
-- Données de MATCHING uniquement, générées depuis les branches de durée de
-- LittleWigs (ENCOUNTER_TIMELINE_EVENT_ADDED, modes Mythique et Normal/Héroïque
-- fusionnés). Aucune série de prédiction : la timeline Blizzard fournit déjà le
-- minutage — `matchOnly = true` empêche le moteur prédictif de démarrer dessus.
-- Rôles, voix et sévérités sont des valeurs par défaut, à affiner en jeu.

local NS = select(2, ...)
local R = function(id, def) NS.Engine:RegisterEncounter(id, def) end

-- Kystia Manaheart  (encounterID 3101)
R(3101, {
    name = "Kystia Manaheart",
    dungeon = "Murder Row",
    matchOnly = true,
    events = {
        { role = "other", voice = "prepare-beam", spellID = 1253811, firstSeenSec = 8, cdSeriesSec = { 8, 27.5 }, severity = 2 },  -- Fel Spray
        { role = "other", voice = "prepare-aoe", spellID = 474240, firstSeenSec = 12, cdSeriesSec = { 12, 25 }, severity = 1 },  -- Fel Nova
        { role = "other", voice = "summon-adds", spellID = 1264095, firstSeenSec = 15, cdSeriesSec = { 15, 30 }, severity = 0 },  -- Mirror Images
    },
})

-- Zaen Bladesorrow  (encounterID 3102)
R(3102, {
    name = "Zaen Bladesorrow",
    dungeon = "Murder Row",
    matchOnly = true,
    events = {
        { role = "other", voice = "watch-dodge", spellID = 474478, eventID = 835, firstSeenSec = 8, cdSeriesSec = { 8 }, severity = 1 },  -- Killing Spree
        { role = "mechanic", voice = "watch-dodge", spellID = 474765, eventID = 836, firstSeenSec = 12, cdSeriesSec = { 12, 16 }, severity = 1 },  -- Same-Day Delivery
        { role = "other", voice = "watch-dodge", spellID = 1214357, eventID = 837, firstSeenSec = 18, cdSeriesSec = { 18 }, severity = 2 },  -- Fire Bomb
        { role = "mechanic", voice = "prepare-interrupt", spellID = 1222795, eventID = 838, firstSeenSec = 26, cdSeriesSec = { 26 }, severity = 1 },  -- Envenom
        { role = "mechanic", voice = "watch-frontal", spellID = 1218347, eventID = 839, firstSeenSec = 36, cdSeriesSec = { 36 }, severity = 2 },  -- Murder in a Row
    },
})

-- Xathuux the Annihilator  (encounterID 3103)
R(3103, {
    name = "Xathuux the Annihilator",
    dungeon = "Murder Row",
    matchOnly = true,
    events = {
        { role = "tank", voice = "tank-buster", spellID = 473898, eventID = 845, firstSeenSec = 6, cdSeriesSec = { 6, 27 }, severity = 2 },  -- Legion Strike
        { role = "other", voice = "watch-knockback", spellID = 1214637, firstSeenSec = 15, cdSeriesSec = { 15 }, severity = 2 },  -- Axe Toss
        { role = "tank", voice = "tank-buster", spellID = 1295453, firstSeenSec = 30, cdSeriesSec = { 30 }, severity = 1 },  -- Infernal Crush
        { role = "other", voice = "watch-dodge", spellID = 474197, firstSeenSec = 35, cdSeriesSec = { 35 }, severity = 1 },  -- Demonic Rage
    },
})

-- Lithiel Cinderfury  (encounterID 3105)
R(3105, {
    name = "Lithiel Cinderfury",
    dungeon = "Murder Row",
    matchOnly = true,
    events = {
        { role = "other", voice = "summon-adds", spellID = 474408, firstSeenSec = 10, cdSeriesSec = { 10, 57 }, severity = 0 },  -- Summon Vilefiend
        { role = "other", voice = "watch-dodge", spellID = 1218203, firstSeenSec = 15, cdSeriesSec = { 15, 55 }, severity = 1 },  -- Fingers of Gul'dan
        { role = "other", voice = "watch-dodge", spellID = 1224478, firstSeenSec = 24, cdSeriesSec = { 24, 59 }, severity = 2 },  -- Malefic Wave
    },
})
