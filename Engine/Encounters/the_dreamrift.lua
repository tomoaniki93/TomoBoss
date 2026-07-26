---@diagnostic disable: undefined-global
-- TomoBoss — Raid : The Dreamrift (mapID 2939)
-- Données d'EVENTBRIDGE uniquement : eventID + rôle + voix + sévérité, AUCUN
-- minutage (la source BossReminder n'en fournit pas pour les raids).
-- `bridgeOnly = true` : ces rencontres n'entrent ni dans la prédiction ni dans
-- l'index de correspondance par durée. Elles deviennent utiles dès que
-- C_EncounterEvents.SetEventSound est câblé — c'est le jeu qui joue la voix,
-- et il n'a besoin que de l'eventID.

local NS = select(2, ...)
local R = function(id, def) NS.Engine:RegisterEncounter(id, def) end

-- Chimaeroth, God of the Undreamed  (encounterID 3306)
R(3306, {
    name = "Chimaeroth, God of the Undreamed",
    dungeon = "The Dreamrift",
    bridgeOnly = true,
    events = {
        { role = "other", voice = "watch-launch", spellID = 1245404, eventID = 48, severity = 1 },
        { role = "heal", voice = "prepare-aoe", spellID = 1251021, eventID = 49, severity = 2 },
        { role = "heal", voice = "prepare-aoe", spellID = 1246621, eventID = 50, severity = 0 },
        { role = "other", voice = "watch-dodge", spellID = 1272726, eventID = 51, severity = 0 },
        { role = "other", voice = "watch-shockwave", spellID = 1245452, eventID = 53, severity = 1 },
        { role = "other", voice = "interrupt-now", spellID = 1249017, eventID = 117, severity = 0 },
        { role = "heal", voice = "prepare-aoe", spellID = 1249207, eventID = 118, severity = 0 },
        { role = "mechanic", voice = "clear-water", spellID = 1257085, eventID = 119, severity = 1 },
        { role = "other", voice = "watch-dodge", spellID = 1245771, eventID = 126, severity = 1 },  -- voix par défaut (libellé source vide)
        { role = "mechanic", voice = "special-mechanic", spellID = 1262289, eventID = 149, severity = 2 },
        { role = "other", voice = "special-mechanic", spellID = 1260088, eventID = 170, severity = 2 },  -- voix par défaut (libellé source vide)
        { role = "other", voice = "std-move", spellID = 1262616, eventID = 208, severity = 0 },  -- voix par défaut (libellé source vide)
        { role = "mechanic", voice = "rescue-now", spellID = 1268905, eventID = 217, severity = 2 },
        { role = "heal", voice = "prepare-aoe", spellID = 1245396, eventID = 307, severity = 1 },
        { role = "mechanic", voice = "phase-change", spellID = 1280127, eventID = 353, severity = 1 },
        { role = "mechanic", voice = "special-mechanic", spellID = 1282001, eventID = 431, severity = 2 },
        { role = "other", voice = "watch-shockwave", spellID = 1282856, eventID = 458, severity = 1 },
        { role = "other", voice = "boss-enrage", spellID = 1245844, eventID = 555, severity = 0 },
    },
})
