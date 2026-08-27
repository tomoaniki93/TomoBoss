---@diagnostic disable: undefined-global
-- TomoBoss 2.8.0-beta5c — external reference catalog (observation-only).
--
-- Derived from user-supplied EXBossData + WeakAura S2 reference material.
-- This file NEVER creates, renames, reschedules, cancels, or voices a player-facing alert.
-- Runtime authority remains Blizzard Timeline + TomoBoss encounter/state logic.

local addonName, NS = ...
if type(NS) ~= "table" then return end

local RC = NS.ReferenceCatalog or {}
NS.ReferenceCatalog = RC
RC.mode = "observation-only"
RC.metrics = RC.metrics or { audited=0, matched=0, ambiguous=0, conflicts=0, unverified=0, fallbacks=0, aliases=0, externalMatched=0 }
RC.recentExternal = RC.recentExternal or {}
RC.currentEncounter = RC.currentEncounter or nil
RC.lastEncounter = RC.lastEncounter or nil
RC.lastDecision = RC.lastDecision or nil

RC.META = {
    season = "12.1 S2",
    encounters = 28,
    exbossEvents = 143,
    exbossDurationRules = 205,
    exbossMappedDurationRules = 204,
    weakAuraIDs = 113,
    weakAuraExbossExact = 104,
    tomoExplicitIDs = 61,
    tomoExbossExact = 59,
    aliasGroups = 2,
    confirmedAliasGroups = 1,
    candidateAliasGroups = 1,
    weakAuraId = "DfWtfh5H_",
    weakAuraVersion = 10,
    weakAuraToc = 120100,
    exbossGeneratedAt = "2026-08-12 12:19:59",
    learnProfileVariants = 6,
    learnProfileSource = "user Learn dumps",
}

RC.DATA = {
    [3285] = {
        name = "Voidscar Arena — Taz'Rah",
        confidence = "REFERENCE",
        events = {
            [39] = { physicalSpellID=1297017 },
            [40] = { physicalSpellID=1262901 },
            [41] = { physicalSpellID=1300259 },
            [42] = { physicalSpellID=1225011 },
            [558] = { physicalSpellID=1222098 },
            [782] = { physicalSpellID=1296963 },
        },
        rules = {
            { time=31, eventID=41, physicalSpellID=1300259, sync=true },
            { time=16, eventID=782, physicalSpellID=1296963, sync=true },
            { time=25, eventID=39, physicalSpellID=1297017, sync=true },
            { time=6, eventID=558, physicalSpellID=1222098, sync=true },
        },
        weakAuraIDs = { 1222098, 1296963, 1297017, 1300259 },
    },
    [3286] = {
        name = "Voidscar Arena — Atroxus",
        confidence = "REFERENCE",
        events = {
            [46] = { physicalSpellID=1222371 },
            [47] = { physicalSpellID=1222642 },
            [54] = { physicalSpellID=1222721 },
            [55] = { physicalSpellID=1226120 },
            [297] = { physicalSpellID=1262497 },
        },
        rules = {
            { time=10, eventID=47, physicalSpellID=1222642, sync=true },
            { time=5, eventID=55, physicalSpellID=1226120, sync=true },
            { time=35, eventID=297, physicalSpellID=1262497, sync=true },
            { time=15, eventID=54, physicalSpellID=1222721, sync=true },
            { time=20, eventID=55, physicalSpellID=1226120, sequenceGroup="3286_loop_20", sequenceOrder=1 },
            { time=20, eventID=47, physicalSpellID=1222642, sequenceGroup="3286_loop_20", sequenceOrder=2 },
            { time=30, eventID=54, physicalSpellID=1222721 },
        },
        weakAuraIDs = { 1222642, 1222721, 1226120, 1262497 },
    },
    [3287] = {
        name = "Voidscar Arena — Charonus",
        confidence = "REFERENCE",
        events = {
            [56] = { physicalSpellID=1282770 },
            [57] = { physicalSpellID=1227264 },
            [58] = { physicalSpellID=1263982 },
            [171] = { physicalSpellID=1222758 },
            [961] = { physicalSpellID=1311923 },
        },
        rules = {
            { time=5, eventID=56, physicalSpellID=1282770, sync=true },
            { time=43, eventID=171, physicalSpellID=1222758, sync=true },
            { time=17, eventID=57, physicalSpellID=1227264, sync=true },
            { time=34, eventID=961, physicalSpellID=1311923, sync=true },
            { time=28, eventID=58, physicalSpellID=1263982, sync=true },
        },
        weakAuraIDs = { 1222755, 1227264, 1282770, 1311923 },
    },
    [3199] = {
        name = "The Blinding Vale — Lightblossom Trinity",
        confidence = "MEDIUM",
        events = {
            [173] = { physicalSpellID=1234753 },
            [174] = { physicalSpellID=1234850 },
            [175] = { physicalSpellID=1235640 },
            [176] = { physicalSpellID=1261276 },
            [177] = { physicalSpellID=1235564 },
        },
        rules = {
            { time=8, eventID=176, physicalSpellID=1261276, phase="MAIN", sync=true },
            { time=5, eventID=173, physicalSpellID=1234753, phase="MAIN", sync=true },
            { time=35, eventID=177, physicalSpellID=1235564, phase="MAIN", sync=true },
            { time=20, eventID=174, physicalSpellID=1234850, phase="MAIN", sync=true },
            { time=45, eventID=173, physicalSpellID=1234753, phase="MAIN", sequenceGroup="3199_loop_45", sequenceOrder=1 },
            { time=45, eventID=176, physicalSpellID=1261276, phase="MAIN", sequenceGroup="3199_loop_45", sequenceOrder=2 },
            { time=45, eventID=174, physicalSpellID=1234850, phase="MAIN", sequenceGroup="3199_loop_45", sequenceOrder=3 },
            { time=45, eventID=177, physicalSpellID=1235564, phase="MAIN", sequenceGroup="3199_loop_45", sequenceOrder=4 },
        },
        weakAuraIDs = { 1234753, 1234850, 1235564, 1235640 },
        aliases = {
            [1235640] = { physical={ 1261276 }, status="candidate", label="Thornblade canonical mechanic" },
        },
    },
    [3200] = {
        name = "The Blinding Vale — Ikuzz",
        confidence = "MEDIUM",
        events = {
            [178] = { physicalSpellID=1236746 },
            [179] = { physicalSpellID=1236709 },
            [180] = { physicalSpellID=1237090 },
        },
        rules = {
            { time=6, eventID=178, physicalSpellID=1236746, sync=true },
            { time=22, eventID=179, physicalSpellID=1236709, sync=true },
            { time=50, eventID=180, physicalSpellID=1237090, sync=true },
            { time=29, eventID=178, physicalSpellID=1236746 },
        },
        weakAuraIDs = { 1236709, 1236746, 1237090 },
    },
    [3201] = {
        name = "The Blinding Vale — Lightwarden Ruia",
        confidence = "HIGH",
        events = {
            [181] = { physicalSpellID=1239824 },
            [182] = { physicalSpellID=1240098 },
            [183] = { physicalSpellID=1240210 },
            [184] = { physicalSpellID=1241058 },
            [185] = { physicalSpellID=1239885 },
            [186] = { physicalSpellID=1239882 },
            [187] = { physicalSpellID=1239883 },
            [188] = { physicalSpellID=1241067 },
            [780] = { physicalSpellID=1296871 },
        },
        rules = {
            { time=0.5, eventID=186, physicalSpellID=1239882, phase="P1", sync=true },
            { time=5, eventID=181, physicalSpellID=1239824, phase="P1", sync=true },
            { time=18, eventID=182, physicalSpellID=1240098, phase="P1", sync=true },
            { time=20, eventID=181, physicalSpellID=1239824, phase="P1", sequenceGroup="3201_P1_loop_20", sequenceOrder=1 },
            { time=20, eventID=182, physicalSpellID=1240098, phase="P1", sequenceGroup="3201_P1_loop_20", sequenceOrder=2 },
            { time=3, eventID=184, physicalSpellID=1241058, phase="P2", sync=true },
            { time=9, eventID=183, physicalSpellID=1240210, phase="P2", sync=true },
            { time=20, eventID=184, physicalSpellID=1241058, phase="P2", sequenceGroup="3201_P2_loop_20", sequenceOrder=1 },
            { time=20, eventID=183, physicalSpellID=1240210, phase="P2", sequenceGroup="3201_P2_loop_20", sequenceOrder=2 },
            { time=2.5, eventID=188, physicalSpellID=1241067, phase="P3" },
            { time=7.3, eventID=181, physicalSpellID=1239824, phase="P3", sync=true },
            { time=15.3, eventID=184, physicalSpellID=1241058, phase="P3", sync=true },
            { time=23.3, eventID=182, physicalSpellID=1240098, phase="P3", sync=true },
            { time=31.1, eventID=183, physicalSpellID=1240210, phase="P3", sync=true },
            { time=32, eventID=181, physicalSpellID=1239824, phase="P3", sequenceGroup="3201_loop_32", sequenceOrder=1 },
            { time=32, eventID=184, physicalSpellID=1241058, phase="P3", sequenceGroup="3201_loop_32", sequenceOrder=2 },
            { time=32, eventID=182, physicalSpellID=1240098, phase="P3", sequenceGroup="3201_loop_32", sequenceOrder=3 },
            { time=32, eventID=183, physicalSpellID=1240210, phase="P3", sequenceGroup="3201_loop_32", sequenceOrder=4 },
        },
        weakAuraIDs = { 1239824, 1239883, 1239885, 1240098, 1240210, 1241058 },
    },
    [3202] = {
        name = "The Blinding Vale — Ziekket",
        confidence = "HIGH",
        events = {
            [189] = { physicalSpellID=1246372 },
            [190] = { physicalSpellID=1247685 },
            [191] = { physicalSpellID=1246607 },
            [192] = { physicalSpellID=1246858 },
        },
        rules = {
            { time=26, eventID=190, physicalSpellID=1247685, sync=true },
            { time=4, eventID=189, physicalSpellID=1246372, sync=true },
            { time=40, eventID=191, physicalSpellID=1246607, sync=true },
            { time=14, eventID=192, physicalSpellID=1246858, sync=true },
            { time=50, eventID=189, physicalSpellID=1246372, sequenceGroup="3202_loop_50", sequenceOrder=1 },
            { time=50, eventID=192, physicalSpellID=1246858, sequenceGroup="3202_loop_50", sequenceOrder=2 },
            { time=50, eventID=190, physicalSpellID=1247685, sequenceGroup="3202_loop_50", sequenceOrder=3 },
            { time=50, eventID=191, physicalSpellID=1246607, sequenceGroup="3202_loop_50", sequenceOrder=4 },
        },
        weakAuraIDs = { 1246372, 1246607, 1246858, 1247685 },
    },
    [3101] = {
        name = "Murder Row — Kystia Manaheart",
        confidence = "REFERENCE",
        events = {
            [120] = { physicalSpellID=1264095 },
            [122] = { physicalSpellID=1253811 },
            [202] = { physicalSpellID=474240 },
            [610] = { physicalSpellID=1230304 },
            [613] = { physicalSpellID=1248184 },
        },
        rules = {
            { time=8, eventID=122, physicalSpellID=1253811, sync=true },
            { time=12, eventID=202, physicalSpellID=474240, sync=true },
            { time=15, eventID=120, physicalSpellID=1264095, sync=true },
            { time=27.5, eventID=122, physicalSpellID=1253811 },
            { time=30, eventID=120, physicalSpellID=1264095 },
            { time=12, eventID=202, physicalSpellID=474240 },
        },
        weakAuraIDs = { 474240, 1230304, 1253811, 1264095 },
    },
    [3102] = {
        name = "Murder Row — Zaen Bladesorrow",
        confidence = "REFERENCE",
        events = {
            [123] = { physicalSpellID=1214357 },
            [124] = { physicalSpellID=474765 },
            [125] = { physicalSpellID=1218347 },
            [127] = { physicalSpellID=474478 },
            [193] = { physicalSpellID=1222795 },
            [615] = { physicalSpellID=1218465 },
            [616] = { physicalSpellID=1218466 },
        },
        rules = {
            { time=12, eventID=124, physicalSpellID=474765, sync=true },
            { time=26, eventID=193, physicalSpellID=1222795, sync=true },
            { time=36, eventID=125, physicalSpellID=1218347, sync=true },
            { time=18, eventID=123, physicalSpellID=1214357, sync=true },
            { time=8, eventID=127, physicalSpellID=474478, sync=true },
            { time=16, eventID=124, physicalSpellID=474765 },
        },
        weakAuraIDs = { 474478, 474765, 1214357, 1218347, 1222795 },
    },
    [3103] = {
        name = "Murder Row — Xavroth",
        confidence = "REFERENCE",
        events = {
            [30] = { physicalSpellID=473898 },
            [32] = { physicalSpellID=474197 },
            [559] = { physicalSpellID=1214641 },
            [752] = { physicalSpellID=1295452 },
        },
        rules = {
            { time=6, eventID=30, physicalSpellID=473898, sync=true },
            { time=15, eventID=559, physicalSpellID=1214641, sync=true },
            { time=35, eventID=32, physicalSpellID=474197, sync=true },
            { time=30, eventID=752, physicalSpellID=1295452, sync=true },
            { time=27, eventID=30, physicalSpellID=473898 },
        },
        weakAuraIDs = { 473898, 474197, 1214637, 1295453 },
    },
    [3105] = {
        name = "Murder Row — Lithiel Cinderfury",
        confidence = "REFERENCE",
        events = {
            [37] = { physicalSpellID=1218203 },
            [38] = { physicalSpellID=474408 },
            [207] = { physicalSpellID=1224478 },
        },
        rules = {
            { time=15, eventID=37, physicalSpellID=1218203, sync=true },
            { time=10, eventID=38, physicalSpellID=474408, sync=true },
            { time=24, eventID=207, physicalSpellID=1224478, sync=true },
            { time=57, eventID=38, physicalSpellID=474408 },
            { time=55, eventID=37, physicalSpellID=1218203 },
            { time=59, eventID=207, physicalSpellID=1224478 },
        },
        weakAuraIDs = { 1218203, 1224478 },
    },
    [3207] = {
        name = "Den of Nalorakk — The Hoardmonger",
        confidence = "REFERENCE",
        events = {
            [86] = { physicalSpellID=1234233 },
            [87] = { physicalSpellID=1253268 },
            [88] = { physicalSpellID=1235118 },
        },
        rules = {
            { time=30, eventID=86, physicalSpellID=1234233, sync=true },
            { time=6, eventID=88, physicalSpellID=1235118, sync=true },
            { time=16, eventID=87, physicalSpellID=1253268, sync=true },
        },
        weakAuraIDs = { 1234233, 1235118, 1253268 },
    },
    [3208] = {
        name = "Den of Nalorakk — Sentinel of Winter",
        confidence = "REFERENCE",
        events = {
            [67] = { physicalSpellID=1235548 },
            [68] = { physicalSpellID=1235623 },
            [69] = { physicalSpellID=1235783 },
            [70] = { physicalSpellID=1235656 },
        },
        rules = {
            { time=7, eventID=67, physicalSpellID=1235548, sync=true },
            { time=13, eventID=68, physicalSpellID=1235623, sync=true },
            { time=25, eventID=69, physicalSpellID=1235783, sync=true },
            { time=50, eventID=70, physicalSpellID=1235656, sync=true },
        },
        weakAuraIDs = { 1235548, 1235623, 1235656, 1235783 },
    },
    [3209] = {
        name = "Den of Nalorakk — Nalorakk",
        confidence = "REFERENCE",
        events = {
            [89] = { physicalSpellID=1255385 },
            [90] = { physicalSpellID=1242860 },
            [91] = { physicalSpellID=1243011 },
            [92] = { physicalSpellID=1243569 },
            [163] = { physicalSpellID=1262846 },
            [909] = { physicalSpellID=1242860 },
            [910] = { physicalSpellID=1243011 },
            [911] = { physicalSpellID=1242860 },
        },
        rules = {
            { time=13, eventID=92, physicalSpellID=1243569, sync=true },
            { time=5, eventID=911, physicalSpellID=1242860, sync=true },
            { time=54, eventID=910, physicalSpellID=1243011, sync=true },
            { time=25, eventID=911, physicalSpellID=1242860, sequenceGroup="3209_loop_25", sequenceOrder=1 },
            { time=25, eventID=92, physicalSpellID=1243569, sequenceGroup="3209_loop_25", sequenceOrder=2 },
        },
        weakAuraIDs = { 1242860, 1243011, 1243569 },
    },
    [2124] = {
        name = "Temple of Sethraliss — Adderis & Aspix",
        confidence = "HIGH",
        events = {
            [689] = { physicalSpellID=1288049 },
            [690] = { physicalSpellID=1311804 },
            [691] = { physicalSpellID=1311805 },
            [692] = { physicalSpellID=1289059 },
            [713] = { physicalSpellID=1289754 },
            [718] = { physicalSpellID=1289059 },
            [720] = { physicalSpellID=1292518 },
        },
        rules = {
            { time=9, eventID=689, physicalSpellID=1288049, phase="P1", sync=true },
            { time=39, eventID=690, physicalSpellID=1311804, phase="P1", sync=true },
            { time=29, eventID=691, physicalSpellID=1311805, phase="P1", sync=true },
            { time=5, eventID=692, physicalSpellID=1289059, phase="P1", sync=true },
            { time=4, eventID=689, physicalSpellID=1288049, phase="P1", sync=true },
            { time=29, eventID=691, physicalSpellID=1311805, phase="P1", sync=true },
            { time=35, eventID=690, physicalSpellID=1311804, phase="P1", sync=true },
            { time=25, eventID=691, physicalSpellID=1311805, phase="P1", sync=true },
            { time=1, eventID=692, physicalSpellID=1289059, phase="P1", sync=true },
            { time=45, eventID=692, physicalSpellID=1289059, phase="P1", sequenceGroup="2124_loop_45", sequenceOrder=1 },
            { time=45, eventID=689, physicalSpellID=1288049, phase="P1", sequenceGroup="2124_loop_45", sequenceOrder=2 },
            { time=45, eventID=691, physicalSpellID=1311805, phase="P1", sequenceGroup="2124_loop_45", sequenceOrder=3 },
            { time=45, eventID=690, physicalSpellID=1311804, phase="P1", sequenceGroup="2124_loop_45", sequenceOrder=4 },
            { time=12, eventID=691, physicalSpellID=1311805, phase="P2", sync=true },
            { time=5, eventID=692, physicalSpellID=1289059, phase="P2", sync=true },
            { time=19, eventID=692, physicalSpellID=1289059, phase="P2", sequenceGroup="2124_loop_19", sequenceOrder=1 },
            { time=19, eventID=691, physicalSpellID=1311805, phase="P2", sequenceGroup="2124_loop_19", sequenceOrder=2 },
        },
        weakAuraIDs = { 1288049, 1289059, 1311804, 1311805 },
    },
    [2125] = {
        name = "Temple of Sethraliss — Merektha",
        confidence = "REFERENCE",
        events = {
            [701] = { physicalSpellID=264172 },
            [702] = { physicalSpellID=1290029 },
            [703] = { physicalSpellID=1289109 },
            [704] = { physicalSpellID=1289205 },
            [705] = { physicalSpellID=1290797 },
            [706] = { physicalSpellID=1293048 },
            [730] = { physicalSpellID=1293154 },
        },
        rules = {
            { time=13, eventID=702, physicalSpellID=1290029, sync=true },
            { time=36, eventID=706, physicalSpellID=1293048, sync=true },
            { time=5, eventID=705, physicalSpellID=1290797, sync=true },
            { time=25, eventID=703, physicalSpellID=1289109, sync=true },
            { time=44, eventID=704, physicalSpellID=1289205, sync=true },
            { time=49, eventID=701, physicalSpellID=264172, sync=true },
        },
        weakAuraIDs = { 264172, 1289109, 1290029, 1290797, 1293048 },
    },
    [2126] = {
        name = "Temple of Sethraliss — Galvazzt",
        confidence = "REFERENCE",
        events = {
            [697] = { physicalSpellID=1309525 },
            [698] = { physicalSpellID=1291618 },
        },
        rules = {
            { time=20, eventID=697, physicalSpellID=1309525, sync=true },
            { time=5, eventID=698, physicalSpellID=1291618, sync=true },
            { time=22, eventID=698, physicalSpellID=1291618, sequenceGroup="2126_loop_22", sequenceOrder=1 },
            { time=22, eventID=697, physicalSpellID=1309525, sequenceGroup="2126_loop_22", sequenceOrder=2 },
        },
        weakAuraIDs = { 1291618, 1309525 },
    },
    [2127] = {
        name = "Temple of Sethraliss — Avatar of Sethraliss",
        confidence = "REFERENCE",
        events = {
            [827] = { physicalSpellID=1301963 },
            [828] = { physicalSpellID=1301202 },
        },
        rules = {
            { time=13, eventID=92, sync=true },
            { time=15, eventID=828, physicalSpellID=1301202, sync=true },
        },
        weakAuraIDs = { 1301202 },
    },
    [2609] = {
        name = "Ruby Life Pools — Melidrussa Chillworn",
        confidence = "REFERENCE",
        events = {
            [866] = { physicalSpellID=1307297 },
            [867] = { physicalSpellID=1307308 },
            [868] = { physicalSpellID=373686 },
            [869] = { physicalSpellID=373046 },
        },
        rules = {
            { time=5, eventID=866, physicalSpellID=1307297, sync=true },
            { time=15, eventID=867, physicalSpellID=1307308, sync=true },
            { time=12, eventID=868, physicalSpellID=373686 },
            { time=24, eventID=866, physicalSpellID=1307297, sequenceGroup="2609_loop_27", sequenceOrder=1 },
            { time=24, eventID=867, physicalSpellID=1307308, sequenceGroup="2609_loop_27", sequenceOrder=2 },
        },
        weakAuraIDs = { 373046, 373686, 1307297, 1307308 },
    },
    [2606] = {
        name = "Ruby Life Pools — Kokia Blazehoof",
        confidence = "REFERENCE",
        events = {
            [882] = { physicalSpellID=372864 },
            [883] = { physicalSpellID=372110 },
            [884] = { physicalSpellID=372858 },
        },
        rules = {
            { time=28, eventID=884, physicalSpellID=372858, sync=true },
            { time=19, eventID=883, physicalSpellID=372110, sync=true },
            { time=8, eventID=882, physicalSpellID=372864, sync=true },
            { time=20, eventID=883, physicalSpellID=372110 },
            { time=40, eventID=882, physicalSpellID=372864, sequenceGroup="2606_loop_40", sequenceOrder=1 },
            { time=40, eventID=884, physicalSpellID=372858, sequenceGroup="2606_loop_40", sequenceOrder=2 },
        },
        weakAuraIDs = { 372110, 372858, 372864 },
    },
    [2623] = {
        name = "Ruby Life Pools — Kyrakka & Erkhart Stormvein",
        confidence = "REFERENCE",
        events = {
            [885] = { physicalSpellID=381516 },
            [887] = { physicalSpellID=381517 },
            [888] = { physicalSpellID=381512 },
            [889] = { physicalSpellID=381602 },
            [890] = { physicalSpellID=381525 },
            [894] = { physicalSpellID=381605 },
        },
        rules = {
            { time=10, eventID=887, physicalSpellID=381517, sync=true },
            { time=21, eventID=885, physicalSpellID=381516, sync=true },
            { time=5, eventID=888, physicalSpellID=381512, sync=true },
            { time=1, eventID=890, physicalSpellID=381525, sync=true },
            { time=12, eventID=889, physicalSpellID=381602, sync=true },
            { time=22.5, eventID=888, physicalSpellID=381512 },
            { time=21.5, eventID=887, physicalSpellID=381517 },
            { time=25, eventID=885, physicalSpellID=381516 },
            { time=9, eventID=894, physicalSpellID=381605 },
            { time=20, eventID=890, physicalSpellID=381525, sequenceGroup="2623_loop_20", sequenceOrder=1 },
            { time=20, eventID=889, physicalSpellID=381602, sequenceGroup="2623_loop_20", sequenceOrder=2 },
            { time=16, eventID=890, physicalSpellID=381525, sequenceGroup="2623_loop_16", sequenceOrder=1 },
            { time=16, eventID=894, physicalSpellID=381605, sequenceGroup="2623_loop_16", sequenceOrder=2 },
        },
        weakAuraIDs = { 381512, 381516, 381525, 381862 },
        aliases = {
            [381862] = { physical={ 381602, 381605 }, status="confirmed", label="Inferno Spit canonical mechanic" },
        },
    },
    [2139] = {
        name = "King's Rest — Golden Serpent",
        confidence = "REFERENCE",
        events = {
            [767] = { physicalSpellID=265773 },
            [891] = { physicalSpellID=265910 },
            [892] = { physicalSpellID=1311987 },
            [893] = { physicalSpellID=265923 },
        },
        rules = {
            { time=8, eventID=891, physicalSpellID=265910, sync=true },
            { time=5, eventID=767, physicalSpellID=265773, sync=true },
            { time=54, eventID=893, physicalSpellID=265923, sync=true },
            { time=14, eventID=892, physicalSpellID=1311987, sync=true },
            { time=28, eventID=892, physicalSpellID=1311987 },
            { time=25, eventID=767, physicalSpellID=265773, sequenceGroup="2139_loop_25", sequenceOrder=1 },
            { time=25, eventID=891, physicalSpellID=265910, sequenceGroup="2139_loop_25", sequenceOrder=2 },
        },
        weakAuraIDs = { 265773, 265781, 265910, 265923 },
    },
    [2142] = {
        name = "King's Rest — Mchimba the Embalmer",
        confidence = "HIGH",
        events = {
            [878] = { physicalSpellID=1311956 },
            [879] = { physicalSpellID=267702 },
            [880] = { physicalSpellID=267618 },
            [973] = { physicalSpellID=1312146 },
        },
        rules = {
            { time=20, eventID=878, physicalSpellID=1311956, sync=true },
            { time=60, eventID=879, physicalSpellID=267702, sync=true },
            { time=5, eventID=880, physicalSpellID=267618, sync=true },
            { time=30, eventID=973, physicalSpellID=1312146, sync=true },
            { time=32, eventID=880, physicalSpellID=267618 },
            { time=30, eventID=878, physicalSpellID=1311956 },
        },
        weakAuraIDs = { 267618, 267702, 1311956, 1312146 },
    },
    [2140] = {
        name = "King's Rest — Council of Tribes",
        confidence = "HIGH",
        events = {
            [870] = { physicalSpellID=266206 },
            [871] = { physicalSpellID=266231 },
            [872] = { physicalSpellID=267494 },
            [873] = { physicalSpellID=266237 },
            [874] = { physicalSpellID=1305810 },
            [875] = { physicalSpellID=267273 },
            [876] = { physicalSpellID=267060 },
        },
        rules = {
            { time=8, eventID=870, physicalSpellID=266206, phase="P1", sync=true },
            { time=15, eventID=871, physicalSpellID=266231, phase="P1", sync=true },
            { time=14.75, eventID=870, physicalSpellID=266206, phase="P1" },
            { time=16.5, eventID=871, physicalSpellID=266231, phase="P1" },
            { time=5, eventID=872, physicalSpellID=267494, phase="P2", sync=true },
            { time=14, eventID=873, physicalSpellID=266237, phase="P2", sync=true },
            { time=20, eventID=872, physicalSpellID=267494, phase="P2" },
            { time=22, eventID=873, physicalSpellID=266237, phase="P2" },
            { time=2, eventID=874, physicalSpellID=1305810, phase="P3", sync=true },
            { time=10, eventID=875, physicalSpellID=267273, phase="P3", sync=true },
            { time=20, eventID=876, physicalSpellID=267060, phase="P3", sync=true },
            { time=7, eventID=874, physicalSpellID=1305810, phase="P3" },
            { time=24.4, eventID=875, physicalSpellID=267273, phase="P3" },
            { time=52.5, eventID=876, physicalSpellID=267060, phase="P3" },
        },
        weakAuraIDs = { 266206, 266231, 266237, 267060, 267494, 1305810 },
    },
    [2143] = {
        name = "King's Rest — King Dazar",
        confidence = "REFERENCE",
        events = {
            [831] = { physicalSpellID=1303115 },
            [832] = { physicalSpellID=268586 },
            [833] = { physicalSpellID=1303267 },
            [834] = { physicalSpellID=269230 },
            [835] = { physicalSpellID=269369 },
            [836] = { physicalSpellID=1303327 },
            [837] = { physicalSpellID=1303488 },
        },
        rules = {
            { time=23, eventID=832, physicalSpellID=268586, sync=true },
            { time=30, eventID=833, physicalSpellID=1303267, sync=true },
            { time=15, eventID=831, physicalSpellID=1303115, sync=true },
            { time=8, eventID=834, physicalSpellID=269230, sync=true },
            { time=14, eventID=835, physicalSpellID=269369, sync=true },
            { time=10, eventID=834, physicalSpellID=269230, sequenceGroup="2143_loop_10", sequenceOrder=1 },
            { time=10, eventID=835, physicalSpellID=269369, sequenceGroup="2143_loop_10", sequenceOrder=2 },
            { time=36, eventID=837, physicalSpellID=1303488, sync=true },
            { time=9, eventID=836, physicalSpellID=1303327, sync=true },
            { time=38, eventID=832, physicalSpellID=268586, sync=true },
            { time=24, eventID=833, physicalSpellID=1303267, sync=true },
        },
        weakAuraIDs = { 268586, 269230, 1303115, 1303267, 1303327 },
    },
    [3456] = {
        name = "Altar of Fangs — Rav'i",
        confidence = "REFERENCE",
        events = {
            [795] = { physicalSpellID=1309522 },
            [796] = { physicalSpellID=1296219 },
            [797] = { physicalSpellID=1296220 },
            [798] = { physicalSpellID=1296050 },
            [899] = { physicalSpellID=1307894 },
            [901] = { physicalSpellID=1307921 },
            [902] = { physicalSpellID=1307765 },
        },
        rules = {
            { time=8, eventID=797, physicalSpellID=1296220, sync=true },
            { time=25, eventID=795, physicalSpellID=1309522, sync=true },
            { time=13, eventID=798, physicalSpellID=1296050, sync=true },
            { time=45, eventID=795, physicalSpellID=1309522, sync=true },
            { time=23, eventID=899, physicalSpellID=1307894, sync=true },
            { time=24, eventID=797, physicalSpellID=1296220 },
        },
        weakAuraIDs = { 1296050, 1296216, 1296220, 1307894 },
    },
    [3457] = {
        name = "Altar of Fangs — The Writhing Coil",
        confidence = "MEDIUM",
        events = {
            [813] = { physicalSpellID=1299154 },
            [814] = { physicalSpellID=1298949 },
            [815] = { physicalSpellID=1299940 },
            [816] = { physicalSpellID=1299053 },
            [817] = { physicalSpellID=1300503 },
            [818] = { physicalSpellID=1300686 },
            [938] = { physicalSpellID=1310357 },
            [939] = { physicalSpellID=1310547 },
        },
        rules = {
            { time=1, eventID=813, physicalSpellID=1299154, phase="P1", sync=true },
            { time=7, eventID=814, physicalSpellID=1298949, phase="P1", sync=true },
            { time=44, eventID=816, physicalSpellID=1299053, phase="P1", sync=true },
            { time=14, eventID=938, physicalSpellID=1310357, phase="P1", sync=true },
            { time=30, eventID=815, physicalSpellID=1299940, phase="P1", sync=true },
            { time=10, eventID=939, physicalSpellID=1310547, phase="P2", sync=true },
            { time=25, eventID=818, physicalSpellID=1300686, phase="P2", sync=true },
            { time=10, eventID=813, physicalSpellID=1299154, phase="P3", sync=true },
            { time=53, eventID=816, physicalSpellID=1299053, phase="P3", sync=true },
            { time=23, eventID=938, physicalSpellID=1310357, phase="P3", sync=true },
            { time=16, eventID=814, physicalSpellID=1298949, phase="P3", sync=true },
            { time=39, eventID=815, physicalSpellID=1299940, phase="P3", sync=true },
        },
        weakAuraIDs = { 1298949, 1299053, 1299130, 1299154, 1299940, 1300044, 1300686, 1310358, 1310547 },
    },
    [3458] = {
        name = "Altar of Fangs — Zul'jan",
        confidence = "MEDIUM",
        events = {
            [821] = { physicalSpellID=1301413 },
            [822] = { physicalSpellID=1300876 },
            [823] = { physicalSpellID=1301111 },
            [824] = { physicalSpellID=1301350 },
        },
        rules = {
            { time=32, eventID=821, physicalSpellID=1301413, sync=true },
            { time=14, eventID=823, physicalSpellID=1301111, sync=true },
            { time=26, eventID=824, physicalSpellID=1301350, sync=true },
            { time=26, eventID=824, physicalSpellID=1301350, sync=true },
            { time=64, eventID=822, physicalSpellID=1300876 },
            { time=30, eventID=824, physicalSpellID=1301350 },
            { time=14, eventID=821, physicalSpellID=1301413 },
        },
        weakAuraIDs = { 1300876, 1301111, 1301350, 1301413 },
    },
}

local function isSecret(v)
    return type(issecretvalue) == "function" and issecretvalue(v) or false
end

local function safeNumber(v)
    if isSecret(v) or type(v) ~= "number" then return nil end
    if v ~= v or v <= -math.huge or v >= math.huge then return nil end
    return v
end

local function near(a, b, tol)
    return type(a) == "number" and type(b) == "number" and math.abs(a-b) <= (tol or 0.35)
end

local function listToSet(list)
    local out = {}
    for _, v in ipairs(list or {}) do out[tonumber(v) or v] = true end
    return out
end

local function countTable(t)
    local n=0; for _ in pairs(t or {}) do n=n+1 end; return n
end

function RC:GetEncounter(encID)
    return self.DATA[tonumber(encID) or encID]
end

function RC:Canonicalize(encID, spellID)
    spellID = tonumber(spellID) or spellID
    local row = self:GetEncounter(encID)
    if not row or not spellID then return spellID, false end
    for canonical, alias in pairs(row.aliases or {}) do
        if canonical == spellID then return canonical, false end
        for _, physical in ipairs(alias.physical or {}) do
            if physical == spellID then return canonical, true end
        end
    end
    return spellID, false
end

function RC:GetRuleCandidates(encID, duration, tolerance)
    duration = safeNumber(duration)
    local row = self:GetEncounter(encID)
    if not row or not duration then return {} end
    local out = {}
    for _, rule in ipairs(row.rules or {}) do
        if near(duration, tonumber(rule.time), tolerance or 0.40) then
            local canonical, aliased = self:Canonicalize(encID, rule.physicalSpellID)
            out[#out+1] = {
                time=rule.time, eventID=rule.eventID, physicalSpellID=rule.physicalSpellID,
                canonicalSpellID=canonical, aliasApplied=aliased, phase=rule.phase,
                sequenceGroup=rule.sequenceGroup, sequenceOrder=rule.sequenceOrder, sync=rule.sync,
            }
        end
    end
    return out
end

function RC:_EngineHasSpell(encID, spellID)
    if not NS.Engine or type(NS.Engine.GetEncounter) ~= "function" then return false end
    local def = NS.Engine:GetEncounter(tonumber(encID) or encID)
    if not def then return false end
    spellID = tonumber(spellID) or spellID
    for _, ev in ipairs(def.events or {}) do
        if (tonumber(ev.spellID) or ev.spellID) == spellID then return true end
    end
    return false
end

function RC:_WeakAuraHas(encID, spellID)
    local row = self:GetEncounter(encID)
    if not row then return false end
    spellID = tonumber(spellID) or spellID
    for _, id in ipairs(row.weakAuraIDs or {}) do if id == spellID then return true end end
    return false
end

function RC:_RememberExternal(source, encID, duration, eventID, spellID)
    encID = tonumber(encID) or encID
    duration = safeNumber(duration)
    eventID = tonumber(eventID) or eventID
    spellID = tonumber(spellID) or spellID
    if not encID or not duration then return end
    local canonical, aliased = self:Canonicalize(encID, spellID)
    self.recentExternal[#self.recentExternal+1] = {
        source=source, encounterID=encID, duration=duration, eventID=eventID,
        physicalSpellID=spellID, canonicalSpellID=canonical, aliasApplied=aliased, at=GetTime(),
    }
    local cutoff = GetTime() - 8
    local keep = {}
    for _, rec in ipairs(self.recentExternal) do if (rec.at or 0) >= cutoff then keep[#keep+1]=rec end end
    self.recentExternal = keep
end

function RC:OnBridge(kind, record)
    if kind ~= "start" and kind ~= "update" and kind ~= "merge" then return end
    if type(record) ~= "table" then return end
    local encID = self.currentEncounter
    if not encID then return end
    local row = self:GetEncounter(encID)
    if not row then return end
    local duration = safeNumber(record.duration)
    if not duration then return end
    local eventID, spellID
    local bw = record.sources and record.sources.bigwigs
    if type(bw) == "string" and not isSecret(bw) then
        local token = bw:match("^event|(%d+)$")
        if token then
            eventID = tonumber(token)
            local event = row.events and row.events[eventID]
            spellID = event and event.physicalSpellID or nil
        end
    end
    if not spellID then spellID = safeNumber(record.spellID) end
    if eventID or spellID then self:_RememberExternal("bigwigs", encID, duration, eventID, spellID) end
end

function RC:_ExternalMatch(encID, duration, canonicalSpellID)
    local now = GetTime()
    local sawComparable = false
    for i=#self.recentExternal,1,-1 do
        local rec = self.recentExternal[i]
        if now - (rec.at or 0) <= 3.0 and rec.encounterID == encID and near(rec.duration, duration, 1.5) then
            sawComparable = true
            if rec.canonicalSpellID and rec.canonicalSpellID == canonicalSpellID then return true, rec end
        end
    end
    return sawComparable and false or nil, nil
end

function RC:ObserveDecision(encID, duration, spellID, label, candidates)
    encID = tonumber(encID) or encID
    duration = safeNumber(duration)
    spellID = tonumber(spellID) or spellID
    if not encID or not duration or not spellID then return nil end
    local canonical, chosenAliased = self:Canonicalize(encID, spellID)
    local refs = self:GetRuleCandidates(encID, duration, 0.40)
    local ids, phases, aliasUsed = {}, {}, chosenAliased
    for _, ref in ipairs(refs) do
        if ref.canonicalSpellID then ids[ref.canonicalSpellID] = true end
        if ref.phase then phases[ref.phase] = true end
        if ref.aliasApplied then aliasUsed = true end
    end
    local nIDs = countTable(ids)
    local verdict
    if nIDs == 0 then verdict = "UNVERIFIED"
    elseif ids[canonical] then verdict = nIDs > 1 and "MATCH-MULTI" or "MATCH"
    else verdict = "CONFLICT" end
    local wa = self:_WeakAuraHas(encID, canonical)
    local tmb = self:_EngineHasSpell(encID, canonical)
    local external, externalRec = self:_ExternalMatch(encID, duration, canonical)
    local learnProfiles
    if NS.Learn and NS.Learn.ProfileEvidence and type(NS.Learn.ProfileEvidence.MatchDuration) == "function" then
        local ok, matchedProfiles = pcall(NS.Learn.ProfileEvidence.MatchDuration, NS.Learn.ProfileEvidence, encID, duration)
        if ok and type(matchedProfiles) == "table" and #matchedProfiles > 0 then learnProfiles = matchedProfiles end
    end
    local row = self:GetEncounter(encID)
    self.metrics.audited = (self.metrics.audited or 0) + 1
    if verdict == "MATCH" then self.metrics.matched=(self.metrics.matched or 0)+1
    elseif verdict == "MATCH-MULTI" then self.metrics.matched=(self.metrics.matched or 0)+1; self.metrics.ambiguous=(self.metrics.ambiguous or 0)+1
    elseif verdict == "CONFLICT" then self.metrics.conflicts=(self.metrics.conflicts or 0)+1
    else self.metrics.unverified=(self.metrics.unverified or 0)+1 end
    if aliasUsed then self.metrics.aliases=(self.metrics.aliases or 0)+1 end
    if external == true then self.metrics.externalMatched=(self.metrics.externalMatched or 0)+1 end
    if learnProfiles then self.metrics.learnProfileMatched=(self.metrics.learnProfileMatched or 0)+1 end
    self.lastDecision = {
        encounterID=encID, duration=duration, spellID=spellID, canonicalSpellID=canonical,
        label=label, candidates=candidates, verdict=verdict, referenceIDs=ids, phases=phases,
        exbossMatch=(verdict == "MATCH" or verdict == "MATCH-MULTI"), weakAuraMatch=wa,
        tomoBossMatch=tmb, externalMatch=external, externalEventID=externalRec and externalRec.eventID or nil,
        learnProfileMatch=learnProfiles ~= nil, learnProfiles=learnProfiles,
        aliasApplied=aliasUsed, confidence=row and row.confidence or "REFERENCE", at=GetTime(),
    }
    return self.lastDecision
end

function RC:ObserveFallback(encID, duration, label)
    self.metrics.fallbacks=(self.metrics.fallbacks or 0)+1
    encID=tonumber(encID) or encID; duration=safeNumber(duration)
    if encID and duration then
        self.lastFallback={encounterID=encID,duration=duration,label=label,referenceCandidates=#self:GetRuleCandidates(encID,duration,0.40),at=GetTime()}
    end
end

function RC:GetEncounterStatus(encID)
    encID=tonumber(encID) or encID
    local row=self:GetEncounter(encID)
    if not row then return nil end
    local engineTotal, exMatch, waMatch = 0,0,0
    if NS.Engine and type(NS.Engine.GetEncounter)=="function" then
        local def=NS.Engine:GetEncounter(encID)
        for _,ev in ipairs(def and def.events or {}) do
            local sid=tonumber(ev.spellID) or ev.spellID
            if sid then
                engineTotal=engineTotal+1
                local canonical=self:Canonicalize(encID,sid)
                local found=false
                for _,e in pairs(row.events or {}) do
                    if self:Canonicalize(encID,e.physicalSpellID)==canonical then found=true break end
                end
                if found then exMatch=exMatch+1 end
                if self:_WeakAuraHas(encID,canonical) then waMatch=waMatch+1 end
            end
        end
    end
    return {
        encounterID=encID,name=row.name,confidence=row.confidence,eventCount=countTable(row.events),
        ruleCount=#(row.rules or {}),weakAuraCount=#(row.weakAuraIDs or {}),aliasCount=countTable(row.aliases),
        tomoBossEvents=engineTotal,tomoExbossMatch=exMatch,tomoWeakAuraMatch=waMatch,
    }
end

function RC:GetStatus()
    local encID=self.currentEncounter or self.lastEncounter or (self.lastDecision and self.lastDecision.encounterID)
    return {
        mode=self.mode, encounterID=encID, active=self.currentEncounter~=nil, meta=self.META, metrics=self.metrics,
        encounter=encID and self:GetEncounterStatus(encID) or nil, lastDecision=self.lastDecision, lastFallback=self.lastFallback,
    }
end

function RC:Init()
    if self.frame then return end
    local f=CreateFrame("Frame"); self.frame=f
    f:RegisterEvent("ENCOUNTER_START"); f:RegisterEvent("ENCOUNTER_END")
    f:SetScript("OnEvent", function(_,event,a1)
        if event=="ENCOUNTER_START" then RC.currentEncounter=tonumber(a1) or a1
        elseif event=="ENCOUNTER_END" then RC.lastEncounter=RC.currentEncounter or tonumber(a1) or a1; RC.currentEncounter=nil end
    end)
    if NS.BossModBridge and type(NS.BossModBridge.RegisterListener)=="function" then
        NS.BossModBridge:RegisterListener(function(kind,record) RC:OnBridge(kind,record) end)
    end
end

RC:Init()
