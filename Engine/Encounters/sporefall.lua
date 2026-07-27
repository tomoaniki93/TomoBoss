---@diagnostic disable: undefined-global
-- TomoBoss — Raid : Sporefall (mapID 1592)
-- Données d'EVENTBRIDGE uniquement : eventID + rôle + voix + sévérité, AUCUN
-- minutage (la source BossReminder n'en fournit pas pour les raids).
-- `bridgeOnly = true` : ces rencontres n'entrent ni dans la prédiction ni dans
-- l'index de correspondance par durée. Elles deviennent utiles dès que
-- C_EncounterEvents.SetEventSound est câblé — c'est le jeu qui joue la voix,
-- et il n'a besoin que de l'eventID.

local NS = select(2, ...)
local R = function(id, def) NS.Engine:RegisterEncounter(id, def) end

-- Rotmire  (encounterID 3159)
R(3159, {
    name = "Rotmire",
    provenance = "bossreminder",
    dungeon = "Sporefall",
    bridgeOnly = true,
    events = {
        { role = "mechanic", voice = "summon-adds", spellID = 1221637, eventID = 424, severity = 0 },
        { role = "mechanic", voice = "summon-adds", spellID = 1221622, eventID = 425, severity = 0 },
        { role = "heal", voice = "prepare-aoe", spellID = 1221787, eventID = 426, severity = 0 },
        { role = "tank", voice = "tank-buster", spellID = 1221781, eventID = 427, severity = 0 },
        { role = "heal", voice = "std-drop", spellID = 1222088, eventID = 428, severity = 0 },
        { role = "mechanic", voice = "prepare-link", spellID = 1299508, eventID = 808, severity = 0 },
        { role = "mechanic", voice = "prepare-link", spellID = 1221639, eventID = 809, severity = 0 },
    },
})
