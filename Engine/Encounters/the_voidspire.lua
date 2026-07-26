---@diagnostic disable: undefined-global
-- TomoBoss — Raid : The Voidspire (mapID 2912)
-- Données d'EVENTBRIDGE uniquement : eventID + rôle + voix + sévérité, AUCUN
-- minutage (la source BossReminder n'en fournit pas pour les raids).
-- `bridgeOnly = true` : ces rencontres n'entrent ni dans la prédiction ni dans
-- l'index de correspondance par durée. Elles deviennent utiles dès que
-- C_EncounterEvents.SetEventSound est câblé — c'est le jeu qui joue la voix,
-- et il n'a besoin que de l'eventID.

local NS = select(2, ...)
local R = function(id, def) NS.Engine:RegisterEncounter(id, def) end

-- Chancellor Aforzane  (encounterID 3176)
R(3176, {
    name = "Chancellor Aforzane",
    dungeon = "The Voidspire",
    bridgeOnly = true,
    events = {
        { role = "mechanic", voice = "special-mechanic", spellID = 1262776, eventID = 194, severity = 2 },
        { role = "mechanic", voice = "special-mechanic", spellID = 1251361, eventID = 195, severity = 2 },
        { role = "heal", voice = "prepare-aoe", spellID = 1249251, eventID = 196, severity = 0 },
        { role = "mechanic", voice = "stack-share", spellID = 1249265, eventID = 197, severity = 1 },
        { role = "other", voice = "watch-dodge", spellID = 1260712, eventID = 198, severity = 1 },
        { role = "other", voice = "watch-dodge", spellID = 1258880, eventID = 199, severity = 1 },
        { role = "other", voice = "boss-enrage", spellID = 1251583, eventID = 200, severity = 2 },
        { role = "other", voice = "interrupt-now", spellID = 1255702, eventID = 201, severity = 0 },
        { role = "other", voice = "watch-dodge", spellID = 1266786, eventID = 209, severity = 1 },
        { role = "other", voice = "watch-dodge", spellID = 1270949, eventID = 361, severity = 1 },  -- voix par défaut (libellé source vide)
        { role = "mechanic", voice = "enter-bubble", spellID = 1280015, eventID = 419, severity = 1 },
        { role = "tank", voice = "intercept-add", spellID = 1283069, eventID = 492, severity = 1 },
    },
})

-- Flachius  (encounterID 3177)
R(3177, {
    name = "Flachius",
    dungeon = "The Voidspire",
    bridgeOnly = true,
    events = {
        { role = "tank", voice = "tank-buster", spellID = 1241836, eventID = 59, severity = 1 },
        { role = "tank", voice = "tank-buster", spellID = 1244293, eventID = 60, severity = 1 },
        { role = "other", voice = "watch-dodge", spellID = 1243853, eventID = 61, severity = 2 },
        { role = "heal", voice = "prepare-aoe", spellID = 1254199, eventID = 62, severity = 1 },
        { role = "other", voice = "watch-dodge", spellID = 1244346, eventID = 63, severity = 1 },  -- voix par défaut (libellé source vide)
        { role = "heal", voice = "prepare-aoe", spellID = 1260046, eventID = 133, severity = 1 },
        { role = "other", voice = "std-move", spellID = 1254112, eventID = 557, severity = 0 },  -- voix par défaut (libellé source vide)
        { role = "other", voice = "std-move", spellID = 1234346, eventID = 749, severity = 0 },  -- voix par défaut (libellé source vide)
    },
})

-- Fallen King Sahadal  (encounterID 3179)
R(3179, {
    name = "Fallen King Sahadal",
    dungeon = "The Voidspire",
    bridgeOnly = true,
    events = {
        { role = "mechanic", voice = "switch-add", spellID = 1243453, eventID = 139, severity = 2 },
        { role = "heal", voice = "prepare-target", spellID = 1260823, eventID = 140, severity = 0 },
        { role = "other", voice = "interrupt-now", spellID = 1254081, eventID = 141, severity = 0 },
        { role = "other", voice = "watch-shockwave", spellID = 1253911, eventID = 142, severity = 0 },
        { role = "heal", voice = "prepare-aoe", spellID = 1250686, eventID = 143, severity = 0 },
        { role = "mechanic", voice = "vuln-burst", spellID = 1246175, eventID = 148, severity = 1 },
        { role = "other", voice = "boss-enrage", spellID = 64238, eventID = 633, severity = 2 },
        { role = "other", voice = "std-move", spellID = 1272338, eventID = 802, severity = 0 },  -- voix par défaut (libellé source vide)
    },
})

-- Wielgor and Aizorak  (encounterID 3178)
R(3178, {
    name = "Wielgor and Aizorak",
    dungeon = "The Voidspire",
    bridgeOnly = true,
    events = {
        { role = "other", voice = "watch-frontal", spellID = 1262623, eventID = 101, severity = 1 },
        { role = "mechanic", voice = "switch-add", spellID = 1244917, eventID = 102, severity = 1 },
        { role = "mechanic", voice = "prepare-absorb-ball", spellID = 1245391, eventID = 103, severity = 1 },
        { role = "other", voice = "watch-frontal", spellID = 1244221, eventID = 104, severity = 1 },
        { role = "heal", voice = "prepare-aoe", spellID = 1249748, eventID = 105, severity = 2 },
        { role = "other", voice = "watch-dodge", spellID = 1280458, eventID = 219, severity = 1 },  -- voix par défaut (libellé source vide)
        { role = "tank", voice = "tank-buster", spellID = 1245645, eventID = 220, severity = 0 },
        { role = "tank", voice = "tank-buster", spellID = 1265131, eventID = 221, severity = 0 },
        { role = "mechanic", voice = "prepare-absorb-ball", spellID = 1277470, eventID = 377, severity = 1 },
        { role = "other", voice = "watch-frontal", spellID = 1277471, eventID = 378, severity = 1 },
        { role = "other", voice = "watch-frontal", spellID = 1277472, eventID = 379, severity = 1 },
        { role = "mechanic", voice = "switch-add", spellID = 1277473, eventID = 380, severity = 1 },
        { role = "mechanic", voice = "enter-bubble", spellID = 1248847, eventID = 381, severity = 2 },
    },
})

-- Light-Blind Vanguard  (encounterID 3180)
R(3180, {
    name = "Light-Blind Vanguard",
    dungeon = "The Voidspire",
    bridgeOnly = true,
    events = {
        { role = "mechanic", voice = "special-mechanic", spellID = 1248451, eventID = 71, severity = 2 },
        { role = "other", voice = "std-move", spellID = 1251886, eventID = 72, severity = 0 },  -- voix par défaut (libellé source vide)
        { role = "other", voice = "watch-frontal", spellID = 1249130, eventID = 73, severity = 1 },
        { role = "mechanic", voice = "break-shield", spellID = 1248674, eventID = 74, severity = 1 },
        { role = "heal", voice = "prepare-aoe", spellID = 1276831, eventID = 75, severity = 2 },
        { role = "mechanic", voice = "special-mechanic", spellID = 1246162, eventID = 76, severity = 2 },
        { role = "heal", voice = "prepare-aoe", spellID = 1255738, eventID = 77, severity = 0 },
        { role = "tank", voice = "tank-buster", spellID = 1251857, eventID = 78, severity = 0 },
        { role = "mechanic", voice = "spread-now", spellID = 1246485, eventID = 79, severity = 1 },
        { role = "mechanic", voice = "watch-dodge", spellID = 1248644, eventID = 80, severity = 2 },
        { role = "mechanic", voice = "special-mechanic", spellID = 1248449, eventID = 81, severity = 2 },
        { role = "tank", voice = "tank-buster", spellID = 1246736, eventID = 82, severity = 0 },
        { role = "mechanic", voice = "watch-dodge", spellID = 1246765, eventID = 83, severity = 0 },
        { role = "heal", voice = "prepare-aoe", spellID = 1246749, eventID = 84, severity = 0 },
        { role = "heal", voice = "stack-share", spellID = 1276368, eventID = 85, severity = 2 },
        { role = "mechanic", voice = "empower-hpal", spellID = 1272380, eventID = 358, severity = 0 },
        { role = "mechanic", voice = "empower-prot", spellID = 1272423, eventID = 359, severity = 0 },
        { role = "mechanic", voice = "empower-ret", spellID = 1272425, eventID = 360, severity = 0 },
        { role = "mechanic", voice = "spread-now", spellID = 1276635, eventID = 365, severity = 0 },
        { role = "heal", voice = "prepare-aoe", spellID = 1276639, eventID = 373, severity = 0 },
        { role = "other", voice = "watch-dodge", spellID = 1272310, eventID = 374, severity = 0 },
    },
})

-- Cosmic Crown  (encounterID 3181)
R(3181, {
    name = "Cosmic Crown",
    dungeon = "The Voidspire",
    bridgeOnly = true,
    events = {
        { role = "heal", voice = "prepare-aoe", spellID = 1233865, eventID = 4, severity = 0 },
        { role = "mechanic", voice = "std-drop", spellID = 1233819, eventID = 5, severity = 1 },
        { role = "mechanic", voice = "beam-on-you", spellID = 1233602, eventID = 6, severity = 1 },
        { role = "other", voice = "watch-dodge", spellID = 1234564, eventID = 7, severity = 1 },
        { role = "other", voice = "watch-dodge", spellID = 1235622, eventID = 8, severity = 1 },
        { role = "heal", voice = "prepare-aoe", spellID = 1237035, eventID = 9, severity = 0 },
        { role = "mechanic", voice = "switch-add", spellID = 1237837, eventID = 10, severity = 1 },
        { role = "heal", voice = "prepare-target", spellID = 1237614, eventID = 11, severity = 1 },
        { role = "heal", voice = "prepare-aoe", spellID = 1246918, eventID = 12, severity = 2 },
        { role = "mechanic", voice = "break-link", spellID = 1239080, eventID = 13, severity = 1 },
        { role = "heal", voice = "prepare-aoe", spellID = 1232467, eventID = 14, severity = 1 },
        { role = "mechanic", voice = "phase-change", spellID = 1238843, eventID = 15, severity = 2 },
        { role = "tank", voice = "tank-buster", spellID = 1233787, eventID = 64, severity = 0 },
        { role = "mechanic", voice = "away-add", spellID = 1243753, eventID = 65, severity = 0 },
        { role = "heal", voice = "prepare-aoe-break", spellID = 1243743, eventID = 66, severity = 1 },
        { role = "heal", voice = "prepare-target", spellID = 1260010, eventID = 131, severity = 1 },
        { role = "heal", voice = "prepare-aoe", spellID = 1260026, eventID = 132, severity = 1 },
        { role = "mechanic", voice = "switch-add", spellID = 1261016, eventID = 135, severity = 2 },
        { role = "mechanic", voice = "switch-add", spellID = 1261339, eventID = 136, severity = 1 },
        { role = "tank", voice = "tank-buster", spellID = 1246461, eventID = 137, severity = 0 },
        { role = "other", voice = "boss-enrage", spellID = 1239582, eventID = 169, severity = 2 },
    },
})
