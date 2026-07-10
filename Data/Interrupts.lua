---@diagnostic disable: undefined-global
-- TomoBoss — Sorts d'interruption par spécialisation.
-- [specID] = { id = <spellID de l'interruption>, cd = <recharge en s>, role = <tank|heal|dps> }
-- id = 0 : la spécialisation n'a pas d'interruption suivie.
-- Le nom du sort est résolu en direct depuis le client (spellID).

local NS = select(2, ...)
NS.Data = NS.Data or {}
NS.Data.Interrupts = {
    [62] = { id = 2139, cd = 20, role = "dps" },
    [63] = { id = 2139, cd = 20, role = "dps" },
    [64] = { id = 2139, cd = 20, role = "dps" },
    [65] = { id = 0, cd = 0, role = "heal" },
    [66] = { id = 96231, cd = 15, role = "tank" },
    [70] = { id = 96231, cd = 15, role = "dps" },
    [71] = { id = 6552, cd = 15, role = "dps" },
    [72] = { id = 6552, cd = 15, role = "dps" },
    [73] = { id = 6552, cd = 15, role = "tank" },
    [102] = { id = 0, cd = 0, role = "dps" },
    [103] = { id = 106839, cd = 15, role = "dps" },
    [104] = { id = 106839, cd = 15, role = "tank" },
    [105] = { id = 0, cd = 0, role = "heal" },
    [250] = { id = 47528, cd = 12, role = "tank" },
    [251] = { id = 47528, cd = 12, role = "dps" },
    [252] = { id = 47528, cd = 12, role = "dps" },
    [253] = { id = 147362, cd = 24, role = "dps" },
    [254] = { id = 147362, cd = 24, role = "dps" },
    [255] = { id = 187707, cd = 15, role = "dps" },
    [256] = { id = 0, cd = 0, role = "heal" },
    [257] = { id = 0, cd = 0, role = "heal" },
    [258] = { id = 15487, cd = 30, role = "dps" },
    [259] = { id = 1766, cd = 15, role = "dps" },
    [260] = { id = 1766, cd = 15, role = "dps" },
    [261] = { id = 1766, cd = 15, role = "dps" },
    [262] = { id = 57994, cd = 12, role = "dps" },
    [263] = { id = 57994, cd = 12, role = "dps" },
    [264] = { id = 57994, cd = 30, role = "heal" },
    [265] = { id = 19647, cd = 24, role = "dps" },
    [266] = { id = 19647, cd = 30, role = "dps" },
    [267] = { id = 19647, cd = 24, role = "dps" },
    [268] = { id = 116705, cd = 15, role = "tank" },
    [269] = { id = 116705, cd = 15, role = "dps" },
    [270] = { id = 0, cd = 0, role = "heal" },
    [577] = { id = 183752, cd = 15, role = "dps" },
    [581] = { id = 183752, cd = 15, role = "tank" },
    [1467] = { id = 351338, cd = 20, role = "dps" },
    [1468] = { id = 0, cd = 0, role = "heal" },
    [1473] = { id = 351338, cd = 18, role = "dps" },
    [1480] = { id = 183752, cd = 15, role = "dps" },
}
