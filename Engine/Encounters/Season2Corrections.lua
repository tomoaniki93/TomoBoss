---@diagnostic disable: undefined-global
-- TomoBoss 2.8.0-beta4 — verified Midnight 12.1/S2 matching corrections.
-- Loaded AFTER the base encounter files and applied through Engine:MergeEncounter.
-- No predictive scheduling is enabled: all affected encounters remain matchOnly.

local NS = select(2, ...)
if type(NS) ~= "table" or not NS.Engine or not NS.Engine.MergeEncounter then return end
local M = function(id, patch) NS.Engine:MergeEncounter(id, patch) end

-- ---------------------------------------------------------------------------
-- Den of Nalorakk
-- ---------------------------------------------------------------------------
M(3207, { events = {
    { spellID = 1235118, firstSeenSec = 6,  cdSeriesSec = { 6 } },
    { spellID = 1253268, firstSeenSec = 16, cdSeriesSec = { 16 } },
    { spellID = 1234233, firstSeenSec = 30, cdSeriesSec = { 30 } },
} })

M(3208, { events = {
    { spellID = 1235548, firstSeenSec = 7,  cdSeriesSec = { 7 } },
    { spellID = 1235623, firstSeenSec = 13, cdSeriesSec = { 13 } },
    { spellID = 1235783, firstSeenSec = 25, cdSeriesSec = { 25 } },
    { spellID = 1235656, firstSeenSec = 50, cdSeriesSec = { 50 } },
} })

M(3209, {
    remove = { 1255385 }, -- old 12.0-only entry
    events = {
        { spellID = 1242860, firstSeenSec = 5,  cdSeriesSec = { 5, 25 } },
        { spellID = 1243569, firstSeenSec = 13, cdSeriesSec = { 13, 25 } },
        { spellID = 1243011, firstSeenSec = 54, cdSeriesSec = { 54 } },
    },
})

-- ---------------------------------------------------------------------------
-- Voidscar Arena
-- ---------------------------------------------------------------------------
M(3285, {
    -- Entries explicitly marked "remove in 12.1" in the old generated data.
    remove = { 1222085, 1222274, 1262901 },
})

M(3286, {
    -- Provoke Creeper is scheduled relative to another mechanic; it is not a
    -- stable C_EncounterTimeline identity and therefore must not be matched here.
    remove = { 1222371 },
    events = {
        { spellID = 1226120, firstSeenSec = 5,  cdSeriesSec = { 5, 20 } },
        { spellID = 1222642, firstSeenSec = 10, cdSeriesSec = { 10, 20 } },
        { spellID = 1222721, firstSeenSec = 15, cdSeriesSec = { 15, 30 } },
        { spellID = 1262497, firstSeenSec = 35, cdSeriesSec = { 35 } },
    },
})

-- ---------------------------------------------------------------------------
-- Altar of Fangs
-- ---------------------------------------------------------------------------
M(3456, { events = {
    -- 12.1: Ravenous Stomp is 23 s, not 24 s. This removes a false collision
    -- with Triple Shot and matches the user's 5-pull Learn capture.
    { spellID = 1307894, firstSeenSec = 23, cdSeriesSec = { 23 } },
} })

-- ---------------------------------------------------------------------------
-- Ruby Life Pools
-- ---------------------------------------------------------------------------
M(2609, { events = {
    { spellID = 1307297, firstSeenSec = 5,  cdSeriesSec = { 5, 24 } },
    { spellID = 373686,  firstSeenSec = 12, cdSeriesSec = { 12 } },
    { spellID = 1307308, firstSeenSec = 15, cdSeriesSec = { 15, 24 } },
} })

M(2623, { events = {
    { spellID = 381512, firstSeenSec = 5,  cdSeriesSec = { 5, 22.5 } },
    { spellID = 381517, firstSeenSec = 10, cdSeriesSec = { 10, 21.5 } },
    { spellID = 381525, firstSeenSec = 1,  cdSeriesSec = { 1, 16, 20 } },
    { spellID = 381862, firstSeenSec = 12, cdSeriesSec = { 9, 12, 16, 20 } },
    { spellID = 381516, firstSeenSec = 21, cdSeriesSec = { 21, 25 } },
} })

-- ---------------------------------------------------------------------------
-- Temple of Sethraliss
-- ---------------------------------------------------------------------------
M(2124, {
    remove = { 1288864, 1288428 }, -- replaced spell IDs in 12.1
    events = {
        { spellID = 1289059, firstSeenSec = 5,  cdSeriesSec = { 1, 5, 19, 45 } },
        { spellID = 1288049, firstSeenSec = 9,  cdSeriesSec = { 5, 9, 19, 22, 45 } },
        { role = "other", voice = "prepare-aoe",      spellID = 1311805, firstSeenSec = 29, cdSeriesSec = { 12, 19, 25, 29, 45 }, severity = 1 },
        { role = "other", voice = "watch-explosion", spellID = 1311804, firstSeenSec = 39, cdSeriesSec = { 15, 19, 35, 39, 45 }, severity = 0 },
    },
})

M(2126, { events = {
    { spellID = 1291618, firstSeenSec = 5,  cdSeriesSec = { 5, 22 } },
    { spellID = 1309525, firstSeenSec = 20, cdSeriesSec = { 20, 22 } },
} })

M(2127, { events = {
    { spellID = 1301202, firstSeenSec = 15, cdSeriesSec = { 15 } },
    { spellID = 1273408, firstSeenSec = 32.5, cdSeriesSec = { 32.5 } },
} })

-- ---------------------------------------------------------------------------
-- King's Rest
-- ---------------------------------------------------------------------------
M(2140, { events = {
    -- Poison Nova has several valid branches in the current encounter script.
    { spellID = 267273, firstSeenSec = 10, cdSeriesSec = { 10, 24, 24.4, 25.2 } },
} })

M(2142, {
    remove = { 267639 }, -- Burn Corruption changed spell ID
    events = {
        { spellID = 267618, firstSeenSec = 5,  cdSeriesSec = { 5, 32 } },
        { role = "other", voice = "watch-dodge", spellID = 1311956, firstSeenSec = 20, cdSeriesSec = { 20, 30 }, severity = 1 },
        { spellID = 1312146, firstSeenSec = 30, cdSeriesSec = { 30, 102 } },
        { spellID = 267702, firstSeenSec = 60, cdSeriesSec = { 60 } },
    },
})

M(2143, {
    remove = { 1303326, 1303481 }, -- corrected 12.1 spell IDs
    events = {
        { spellID = 269230,  firstSeenSec = 8,  cdSeriesSec = { 8, 10, 28 } },
        { spellID = 269369,  firstSeenSec = 14, cdSeriesSec = { 10, 14, 27 } },
        { spellID = 1303115, firstSeenSec = 15, cdSeriesSec = { 15 } },
        { spellID = 268586,  firstSeenSec = 23, cdSeriesSec = { 23, 38 } },
        { spellID = 1303267, firstSeenSec = 30, cdSeriesSec = { 24, 30 } },
        { role = "other", voice = "dodge-charge", spellID = 1303327, firstSeenSec = 9, cdSeriesSec = { 9 }, severity = 1 },
        { role = "tank", voice = "tank-buster", spellID = 1303488, firstSeenSec = 36, cdSeriesSec = { 36 }, severity = 0 },
    },
})
