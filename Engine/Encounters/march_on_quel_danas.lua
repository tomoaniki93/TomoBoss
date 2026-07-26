---@diagnostic disable: undefined-global
-- TomoBoss — Raid : March on Quel'Danas (mapID 2913)
-- Données d'EVENTBRIDGE uniquement : eventID + rôle + voix + sévérité, AUCUN
-- minutage (la source BossReminder n'en fournit pas pour les raids).
-- `bridgeOnly = true` : ces rencontres n'entrent ni dans la prédiction ni dans
-- l'index de correspondance par durée. Elles deviennent utiles dès que
-- C_EncounterEvents.SetEventSound est câblé — c'est le jeu qui joue la voix,
-- et il n'a besoin que de l'eventID.

local NS = select(2, ...)
local R = function(id, def) NS.Engine:RegisterEncounter(id, def) end

-- Beloran, Heir of Arcane  (encounterID 3182)
R(3182, {
    name = "Beloran, Heir of Arcane",
    dungeon = "March on Quel'Danas",
    bridgeOnly = true,
    events = {
        { role = "mechanic", voice = "switch-add", spellID = 1241282, eventID = 128, severity = 0 },
        { role = "mechanic", voice = "clear-ball", spellID = 1242981, eventID = 130, severity = 0 },
        { role = "tank", voice = "tank-buster", spellID = 1260763, eventID = 134, severity = 0 },
        { role = "heal", voice = "use-defensive", spellID = 1244344, eventID = 138, severity = 0 },
        { role = "mechanic", voice = "prepare-block-line", spellID = 1242260, eventID = 161, severity = 1 },
        { role = "heal", voice = "prepare-aoe", spellID = 1242515, eventID = 218, severity = 2 },
        { role = "mechanic", voice = "away-boss", spellID = 1246709, eventID = 272, severity = 2 },
        { role = "other", voice = "watch-dodge", spellID = 1242792, eventID = 273, severity = 2 },
        { role = "mechanic", voice = "prepare-block-line", spellID = 1241992, eventID = 384, severity = 2 },
        { role = "mechanic", voice = "prepare-block-line", spellID = 1242091, eventID = 385, severity = 2 },
        { role = "other", voice = "special-mechanic", spellID = 1262972, eventID = 417, severity = 2 },  -- voix par défaut (libellé source vide)
        { role = "other", voice = "special-mechanic", spellID = 1262983, eventID = 418, severity = 2 },  -- voix par défaut (libellé source vide)
        { role = "mechanic", voice = "you-white", spellID = 1241162, eventID = 482, severity = 2 },
        { role = "mechanic", voice = "you-black", spellID = 1241163, eventID = 483, severity = 2 },
        { role = "heal", voice = "stack-share", spellID = 1241292, eventID = 494, severity = 2 },
        { role = "heal", voice = "stack-share", spellID = 1241339, eventID = 495, severity = 2 },
        { role = "mechanic", voice = "boss-vuln", spellID = 1241313, eventID = 497, severity = 1 },
        { role = "mechanic", voice = "boss-enrage", spellID = 1241267, eventID = 500, severity = 2 },
        { role = "other", voice = "std-move", spellID = 1241320, eventID = 748, severity = 0 },  -- voix par défaut (libellé source vide)
    },
})

-- Midnight Descends  (encounterID 3183)
R(3183, {
    name = "Midnight Descends",
    dungeon = "March on Quel'Danas",
    bridgeOnly = true,
    events = {
        { role = "mechanic", voice = "special-mechanic", spellID = 1244412, eventID = 255, severity = 2 },
        { role = "other", voice = "watch-dodge", spellID = 1253915, eventID = 256, severity = 1 },
        { role = "other", voice = "interrupt-now", spellID = 1251386, eventID = 257, severity = 2 },
        { role = "heal", voice = "prepare-aoe", spellID = 1249796, eventID = 258, severity = 0 },
        { role = "heal", voice = "prepare-aoe", spellID = 1261871, eventID = 259, severity = 2 },
        { role = "mechanic", voice = "prepare-stack", spellID = 1266622, eventID = 260, severity = 1 },
        { role = "mechanic", voice = "clear-ball", spellID = 1266897, eventID = 261, severity = 1 },
        { role = "other", voice = "watch-dodge", spellID = 1266388, eventID = 262, severity = 0 },
        { role = "other", voice = "away-boss", spellID = 1250898, eventID = 263, severity = 2 },
        { role = "mechanic", voice = "special-mechanic", spellID = 1273158, eventID = 362, severity = 2 },
        { role = "heal", voice = "prepare-aoe", spellID = 1276202, eventID = 363, severity = 1 },
        { role = "tank", voice = "tank-buster", spellID = 1267049, eventID = 364, severity = 0 },
        { role = "mechanic", voice = "phase-change", spellID = 1282047, eventID = 433, severity = 2 },
        { role = "heal", voice = "prepare-aoe", spellID = 1282249, eventID = 434, severity = 1 },
        { role = "heal", voice = "prepare-aoe", spellID = 1282412, eventID = 435, severity = 1 },
        { role = "other", voice = "watch-launch", spellID = 1281194, eventID = 436, severity = 2 },
        { role = "heal", voice = "use-defensive", spellID = 1282441, eventID = 437, severity = 1 },
        { role = "heal", voice = "prepare-aoe", spellID = 1284525, eventID = 632, severity = 2 },
        { role = "other", voice = "prepare-interrupt", spellID = 1284931, eventID = 636, severity = 2 },
        { role = "mechanic", voice = "special-mechanic", spellID = 1284980, eventID = 644, severity = 2 },
        { role = "other", voice = "watch-dodge", spellID = 1279420, eventID = 649, severity = 1 },
        { role = "heal", voice = "prepare-target", spellID = 1249609, eventID = 650, severity = 2 },
        { role = "other", voice = "std-move", spellID = 1295191, eventID = 750, severity = 0 },  -- voix par défaut (libellé source vide)
    },
})
