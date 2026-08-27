---@diagnostic disable: undefined-global
-- TomoBoss 2.8.0-beta5 — Midnight S2 duration disambiguation.
--
-- P0-02 principle:
--   * Blizzard eventID values are NOT used as durable identities anymore.
--   * Rules target TomoBoss spellID values, which are stable encounter data.
--   * Only deterministic collisions receive a rule.
--   * State/phase-dependent collisions intentionally remain generic until a
--     dedicated state-aware resolver can prove the identity.

local NS = select(2, ...)
if type(NS) ~= "table" then return end

NS.DURATION_RULES = NS.DURATION_RULES or {}
local R = NS.DURATION_RULES

-- Every S2 encounter previously carried rules generated against an older set
-- of Blizzard eventID values. Doctor beta2 proved 0/51 still resolved.
local S2 = {
    3101, 3102, 3103, 3105,             -- Murder Row
    3207, 3208, 3209,                   -- Den of Nalorakk
    3199, 3200, 3201, 3202,             -- The Blinding Vale
    3285, 3286, 3287,                   -- Voidscar Arena
    3456, 3457, 3458,                   -- Altar of Fangs
    2606, 2609, 2623,                   -- Ruby Life Pools
    2124, 2125, 2126, 2127,             -- Temple of Sethraliss
    2139, 2140, 2142, 2143,             -- King's Rest
}
for _, encounterID in ipairs(S2) do
    R[encounterID] = {}
end

local function counter(encounterID, duration, group, ...)
    local out = R[encounterID]
    local spells = { ... }
    for order, spellID in ipairs(spells) do
        out[#out + 1] = {
            time = duration,
            spellID = spellID,
            sequenceGroup = group,
            sequenceOrder = order,
            strategy = "counter",
        }
    end
end


-- The Blinding Vale — Ziekket. Current native Timeline uses a deterministic
-- shared sequence: 45 s in Normal/Heroic (3 events), 50 s in Mythic (4 events).
counter(3202, 45, "ziekket_45", 1246372, 1247685, 1246607)
counter(3202, 50, "ziekket_50", 1246372, 1246858, 1247685, 1246607)

-- Nalorakk Den: Mythic alternates Echoing Maul / Overwhelming Onslaught at 25 s.
counter(3209, 25, "nalorakk_25", 1242860, 1243569)

-- Atroxus: Poison Splash / Hulking Claw alternate on the 20 s branch.
counter(3286, 20, "atroxus_20", 1226120, 1222642)

-- The Writhing Coil: equal 10 s branch, deterministic sequence.
counter(3457, 10, "coil_10", 1310547, 1299154)

-- Zul'jan: equal 14 s branch, deterministic sequence.
counter(3458, 14, "zuljan_14", 1301111, 1301413)

-- Ruby Life Pools.
counter(2606, 40, "kokia_40", 372864, 372858)
counter(2609, 24, "melidrussa_24", 1307297, 1307308)
counter(2623, 20, "kyrakka_20", 381525, 381862)
counter(2623, 16, "kyrakka_16", 381525, 381862)

-- Temple of Sethraliss.
counter(2126, 22, "galvazzt_22", 1291618, 1309525)

-- King's Rest.
counter(2139, 25, "golden_serpent_25", 265773, 265910)
counter(2143, 10, "dazar_10", 269230, 269369)

-- State-dependent collisions are intentionally NOT represented as counters here.
-- Engine/Phases/StateResolver.lua owns the guarded 2124/2140/2142 cases.
-- If its runtime state is incomplete, P0-01 generic-safe remains authoritative.
