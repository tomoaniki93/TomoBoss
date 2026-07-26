---@diagnostic disable: undefined-global
-- TomoBoss — Règles de correspondance durée → eventID, par rencontre.
--
-- Elles tranchent ce que BT:MatchDuration ne peut pas trancher seul : deux
-- capacités de même durée dans la même rencontre. Trois mécanismes :
--   sync = true            → séquence d'ouverture, consommée une seule fois et
--                            uniquement dans les 10 s suivant le pull.
--   sequenceGroup / Order  → round-robin entre règles à égalité de durée.
--   sinon                  → plus proche dans la tolérance.
--
-- Une règle dont l'eventID ne se résout pas dans mes données reste inerte :
-- le moteur passe à la règle suivante puis à l'index historique par durée.

local NS = select(2, ...)

NS.DURATION_RULES = {
    [1698] = {  -- 7 règles, 7 résolues
        { time = 12, eventID = 299 },
        { time = 5, eventID = 298 },
        { time = 35, eventID = 301 },
        { time = 18, eventID = 300 },
        { time = 20, eventID = 299 },
        { time = 10, eventID = 300 },
        { time = 19.999, eventID = 299 },
    },
    [1699] = {  -- 6 règles, 4 résolues
        { time = 5, eventID = 302 },
        { time = 6, eventID = 303 },  -- inerte : eventID absent de mes données
        { time = 10, eventID = 302 },
        { time = 15, eventID = 302 },
        { time = 24, eventID = 303 },  -- inerte : eventID absent de mes données
        { time = 50, eventID = 304 },
    },
    [1700] = {  -- 5 règles, 5 résolues
        { time = 5, eventID = 306, sync = true },
        { time = 12, eventID = 305, sync = true },
        { time = 38, eventID = 308, sync = true },
        { time = 12, eventID = 306 },
        { time = 21, eventID = 305 },
    },
    [1701] = {  -- 6 règles, 6 résolues
        { time = 8, eventID = 311, sync = true },
        { time = 12, eventID = 310, sync = true },
        { time = 5, eventID = 309, sync = true },
        { time = 30, eventID = 312, sync = true },
        { time = 10, eventID = 309 },
        { time = 12, eventID = 311 },
    },
    [1999] = {  -- 5 règles, 5 résolues
        { time = 33, eventID = 147 },
        { time = 7, eventID = 146 },
        { time = 20, eventID = 144 },
        { time = 41.5, eventID = 145 },
        { time = 32.999, eventID = 147 },
    },
    [2000] = {  -- 8 règles, 8 résolues
        { time = 24, eventID = 168, sync = true },
        { time = 14, eventID = 164, sync = true },
        { time = 52, eventID = 165, sync = true },
        { time = 7, eventID = 166, sync = true },
        { time = 28, eventID = 166, sequenceGroup = "2000_post_sync_28", sequenceOrder = 1 },
        { time = 28, eventID = 164, sequenceGroup = "2000_post_sync_28", sequenceOrder = 2 },
        { time = 28, eventID = 167, sequenceGroup = "2000_post_sync_28", sequenceOrder = 3 },
        { time = 12, eventID = 375 },
    },
    [2001] = {  -- 6 règles, 6 résolues
        { time = 11, eventID = 206, sync = true },
        { time = 21, eventID = 205, sync = true },
        { time = 50, eventID = 203, sync = true },
        { time = 19, eventID = 206, sequenceGroup = "2001_post_sync_19", sequenceOrder = 1 },
        { time = 19, eventID = 205, sequenceGroup = "2001_post_sync_19", sequenceOrder = 2 },
        { time = 28.75, eventID = 204 },
    },
    [2065] = {  -- 7 règles, 7 résolues
        { time = 16, eventID = 223, sync = true },
        { time = 7, eventID = 224, sync = true },
        { time = 22, eventID = 225, sync = true },
        { time = 4, eventID = 226, sync = true },
        { time = 50, eventID = 238, sync = true },
        { time = 40, eventID = 226 },
        { time = 28, eventID = 224 },
    },
    [2066] = {  -- 7 règles, 4 résolues
        { time = 4, eventID = 237 },
        { time = 32, eventID = 243 },
        { time = 6, eventID = 234 },  -- inerte : eventID absent de mes données
        { time = 20, eventID = 235 },
        { time = 9.999, eventID = 234 },  -- inerte : eventID absent de mes données
        { time = 10, eventID = 234 },  -- inerte : eventID absent de mes données
        { time = 12, eventID = 237 },
    },
    [2067] = {  -- 11 règles, 9 résolues
        { time = 6, eventID = 376, sync = true },  -- inerte : eventID absent de mes données
        { time = 26, eventID = 246, sync = true },
        { time = 45, eventID = 247, sync = true },
        { time = 4, eventID = 244, sync = true },
        { time = 12, eventID = 245, sync = true },
        { time = 4, eventID = 244 },
        { time = 18, eventID = 376 },  -- inerte : eventID absent de mes données
        { time = 12, eventID = 244 },
        { time = 2, eventID = 244 },
        { time = 14, eventID = 244 },
        { time = 6, eventID = 244 },
    },
    [2068] = {  -- 9 règles, 9 résolues
        { time = 1.5, eventID = 249, sync = true },
        { time = 12, eventID = 251, sync = true },
        { time = 24, eventID = 250, sync = true },
        { time = 35, eventID = 252, sync = true },
        { time = 5, eventID = 251, sync = true },
        { time = 17, eventID = 250, sync = true },
        { time = 28, eventID = 252, sync = true },
        { time = 1.5, eventID = 253 },
        { time = 20, eventID = 254 },
    },
    [2562] = {  -- 7 règles, 7 résolues
        { time = 5, eventID = 276, sync = true },
        { time = 40, eventID = 277, sync = true },
        { time = 2, eventID = 274, sync = true },
        { time = 15, eventID = 275, sync = true },
        { time = 18, eventID = 274, sequenceGroup = "2562_post_sync_18", sequenceOrder = 1 },
        { time = 18, eventID = 276, sequenceGroup = "2562_post_sync_18", sequenceOrder = 2 },
        { time = 18, eventID = 275, sequenceGroup = "2562_post_sync_18", sequenceOrder = 3 },
    },
    [2563] = {  -- 7 règles, 7 résolues
        { time = 9, eventID = 282 },
        { time = 30, eventID = 283 },
        { time = 18, eventID = 284 },
        { time = 54, eventID = 285 },
        { time = 55, eventID = 285 },
        { time = 28, eventID = 282 },
        { time = 33, eventID = 284 },
    },
    [2564] = {  -- 3 règles, 3 résolues
        { time = 5, eventID = 278 },
        { time = 14, eventID = 279 },
        { time = 20, eventID = 280 },
    },
    [2565] = {  -- 6 règles, 4 résolues
        { time = 7, eventID = 293 },  -- inerte : eventID absent de mes données
        { time = 9, eventID = 294 },
        { time = 10, eventID = 293 },  -- inerte : eventID absent de mes données
        { time = 12, eventID = 294 },
        { time = 14, eventID = 295 },
        { time = 28, eventID = 296 },
    },
    [3056] = {  -- 6 règles, 6 résolues
        { time = 6, eventID = 241 },
        { time = 10, eventID = 239 },
        { time = 15, eventID = 242 },
        { time = 13, eventID = 239 },
        { time = 15.5, eventID = 241 },
        { time = 30, eventID = 242 },
    },
    [3057] = {  -- 5 règles, 4 résolues
        { time = 8, eventID = 28 },
        { time = 17.333, eventID = 25 },
        { time = 22.666, eventID = 26 },
        { time = 27.333, eventID = 28 },
        { time = 48, eventID = 27 },  -- inerte : eventID absent de mes données
    },
    [3058] = {  -- 8 règles, 4 résolues
        { time = 3, eventID = 210, sync = true },  -- inerte : eventID absent de mes données
        { time = 10, eventID = 212, sync = true },  -- inerte : eventID absent de mes données
        { time = 18, eventID = 213, sync = true },
        { time = 30, eventID = 210, sync = true },  -- inerte : eventID absent de mes données
        { time = 37, eventID = 212, sync = true },  -- inerte : eventID absent de mes données
        { time = 45, eventID = 213, sync = true },
        { time = 0.001, eventID = 215 },
        { time = 8, eventID = 216 },
    },
    [3059] = {  -- 7 règles, 5 résolues
        { time = 9, eventID = 23 },  -- inerte : eventID absent de mes données
        { time = 11, eventID = 23 },  -- inerte : eventID absent de mes données
        { time = 21, eventID = 24 },
        { time = 23.5, eventID = 538 },
        { time = 24, eventID = 21 },
        { time = 39, eventID = 22 },
        { time = 53, eventID = 21 },
    },
    [3071] = {  -- 6 règles, 6 résolues
        { time = 5, eventID = 286, sync = true },
        { time = 15, eventID = 288, sync = true },
        { time = 22, eventID = 287, sync = true },
        { time = 45, eventID = 281, sync = true },
        { time = 22.5, eventID = 286 },
        { time = 23, eventID = 288 },
    },
    [3072] = {  -- 5 règles, 5 résolues
        { time = 7, eventID = 95, sync = true },
        { time = 17, eventID = 93, sync = true },
        { time = 26, eventID = 94, sync = true },
        { time = 51, eventID = 96, sync = true },
        { time = 29, eventID = 95 },
    },
    [3073] = {  -- 4 règles, 4 résolues
        { time = 5, eventID = 100, sync = true },
        { time = 16, eventID = 97, sync = true },
        { time = 29, eventID = 98, sync = true },
        { time = 5, eventID = 635 },
    },
    [3074] = {  -- 6 règles, 6 résolues
        { time = 3, eventID = 420, sync = true },
        { time = 9, eventID = 290, sync = true },
        { time = 15, eventID = 292, sync = true },
        { time = 24, eventID = 420, sequenceGroup = "3074_loop_24", sequenceOrder = 1 },
        { time = 24, eventID = 290, sequenceGroup = "3074_loop_24", sequenceOrder = 2 },
        { time = 24, eventID = 292, sequenceGroup = "3074_loop_24", sequenceOrder = 3 },
    },
    [3101] = {  -- 3 règles, 0 résolues
        { time = 6, eventID = 122, sync = true },  -- inerte : eventID absent de mes données
        { time = 20, eventID = 202, sync = true },  -- inerte : eventID absent de mes données
        { time = 40, eventID = 120, sync = true },  -- inerte : eventID absent de mes données
    },
    [3102] = {  -- 6 règles, 0 résolues
        { time = 12, eventID = 124, sync = true },  -- inerte : eventID absent de mes données
        { time = 26, eventID = 193, sync = true },  -- inerte : eventID absent de mes données
        { time = 36, eventID = 125, sync = true },  -- inerte : eventID absent de mes données
        { time = 18, eventID = 123, sync = true },  -- inerte : eventID absent de mes données
        { time = 8, eventID = 127, sync = true },  -- inerte : eventID absent de mes données
        { time = 26, eventID = 124 },  -- inerte : eventID absent de mes données
    },
    [3103] = {  -- 4 règles, 0 résolues
        { time = 6, eventID = 30, sync = true },  -- inerte : eventID absent de mes données
        { time = 15, eventID = 559, sync = true },  -- inerte : eventID absent de mes données
        { time = 35, eventID = 32, sync = true },  -- inerte : eventID absent de mes données
        { time = 27, eventID = 30 },  -- inerte : eventID absent de mes données
    },
    [3105] = {  -- 6 règles, 0 résolues
        { time = 15, eventID = 37, sync = true },  -- inerte : eventID absent de mes données
        { time = 10, eventID = 38, sync = true },  -- inerte : eventID absent de mes données
        { time = 24, eventID = 207, sync = true },  -- inerte : eventID absent de mes données
        { time = 57, eventID = 38 },  -- inerte : eventID absent de mes données
        { time = 55, eventID = 37 },  -- inerte : eventID absent de mes données
        { time = 59, eventID = 207 },  -- inerte : eventID absent de mes données
    },
    [3159] = {  -- 11 règles, 11 résolues
        { time = 41, eventID = 428, sync = true },
        { time = 21, eventID = 427, sync = true },
        { time = 8, eventID = 426, sync = true },
        { time = 13, eventID = 425, sync = true },
        { time = 114, eventID = 424, sync = true },
        { time = 49, eventID = 425, sequenceGroup = "3159_loop_49", sequenceOrder = 1 },
        { time = 49, eventID = 426, sequenceGroup = "3159_loop_49", sequenceOrder = 2 },
        { time = 49, eventID = 428, sequenceGroup = "3159_loop_49", sequenceOrder = 3 },
        { time = 21, eventID = 426 },
        { time = 12, eventID = 427 },
        { time = 13, eventID = 427 },
    },
    [3200] = {  -- 3 règles, 0 résolues
        { time = 6, eventID = 178, sync = true },  -- inerte : eventID absent de mes données
        { time = 20, eventID = 179, sync = true },  -- inerte : eventID absent de mes données
        { time = 40, eventID = 180, sync = true },  -- inerte : eventID absent de mes données
    },
    [3202] = {  -- 6 règles, 0 résolues
        { time = 18, eventID = 190, sync = true },  -- inerte : eventID absent de mes données
        { time = 4, eventID = 189, sync = true },  -- inerte : eventID absent de mes données
        { time = 32, eventID = 191, sync = true },  -- inerte : eventID absent de mes données
        { time = 45, eventID = 189, sequenceGroup = "3202_loop_45", sequenceOrder = 1 },  -- inerte : eventID absent de mes données
        { time = 45, eventID = 190, sequenceGroup = "3202_loop_45", sequenceOrder = 2 },  -- inerte : eventID absent de mes données
        { time = 45, eventID = 191, sequenceGroup = "3202_loop_45", sequenceOrder = 3 },  -- inerte : eventID absent de mes données
    },
    [3212] = {  -- 12 règles, 12 résolues
        { time = 5, eventID = 150, sync = true },
        { time = 12, eventID = 154, sync = true },
        { time = 20, eventID = 152, sync = true },
        { time = 28, eventID = 151, sync = true },
        { time = 35, eventID = 153, sync = true },
        { time = 41, eventID = 155, sync = true },
        { time = 45, eventID = 150, sequenceGroup = "3212_loop_45", sequenceOrder = 1 },
        { time = 45, eventID = 154, sequenceGroup = "3212_loop_45", sequenceOrder = 2 },
        { time = 45, eventID = 152, sequenceGroup = "3212_loop_45", sequenceOrder = 3 },
        { time = 45, eventID = 151, sequenceGroup = "3212_loop_45", sequenceOrder = 4 },
        { time = 45, eventID = 153, sequenceGroup = "3212_loop_45", sequenceOrder = 5 },
        { time = 45, eventID = 155, sequenceGroup = "3212_loop_45", sequenceOrder = 6 },
    },
    [3213] = {  -- 7 règles, 6 résolues
        { time = 3, eventID = 16, sync = true },
        { time = 70, eventID = 20, sync = true },  -- inerte : eventID absent de mes données
        { time = 14.166, eventID = 19, sync = true },
        { time = 25.333, eventID = 17, sync = true },
        { time = 33.5, eventID = 16, sequenceGroup = "3213_post_sync_33_5", sequenceOrder = 1 },
        { time = 33.5, eventID = 19, sequenceGroup = "3213_post_sync_33_5", sequenceOrder = 2 },
        { time = 33.5, eventID = 17, sequenceGroup = "3213_post_sync_33_5", sequenceOrder = 3 },
    },
    [3214] = {  -- 6 règles, 6 résolues
        { time = 4, eventID = 156, sync = true },
        { time = 17, eventID = 157, sync = true },
        { time = 70, eventID = 158, sync = true },
        { time = 26, eventID = 156, sequenceGroup = "3214_loop_26", sequenceOrder = 1 },
        { time = 26, eventID = 157, sequenceGroup = "3214_loop_26", sequenceOrder = 2 },
        { time = 26, eventID = 156, sequenceGroup = "3214_loop_26", sequenceOrder = 3 },
    },
    [3286] = {  -- 7 règles, 0 résolues
        { time = 17, eventID = 46, sync = true },  -- inerte : eventID absent de mes données
        { time = 7, eventID = 47, sync = true },  -- inerte : eventID absent de mes données
        { time = 21, eventID = 54, sync = true },  -- inerte : eventID absent de mes données
        { time = 13, eventID = 55, sync = true },  -- inerte : eventID absent de mes données
        { time = 42, eventID = 297, sync = true },  -- inerte : eventID absent de mes données
        { time = 25, eventID = 47 },  -- inerte : eventID absent de mes données
        { time = 23, eventID = 55 },  -- inerte : eventID absent de mes données
    },
    [3287] = {  -- 6 règles, 0 résolues
        { time = 5, eventID = 56, sync = true },  -- inerte : eventID absent de mes données
        { time = 19, eventID = 57, sync = true },  -- inerte : eventID absent de mes données
        { time = 36, eventID = 58, sync = true },  -- inerte : eventID absent de mes données
        { time = 44.8, eventID = 57 },  -- inerte : eventID absent de mes données
        { time = 44, eventID = 58 },  -- inerte : eventID absent de mes données
        { time = 40, eventID = 56 },  -- inerte : eventID absent de mes données
    },
    [3328] = {  -- 7 règles, 5 résolues
        { time = 1, eventID = 108 },  -- inerte : eventID absent de mes données
        { time = 5, eventID = 107 },
        { time = 10, eventID = 172 },
        { time = 38, eventID = 106 },
        { time = 11, eventID = 108 },  -- inerte : eventID absent de mes données
        { time = 12, eventID = 107 },
        { time = 13, eventID = 172 },
    },
    [3332] = {  -- 7 règles, 5 résolues
        { time = 3, eventID = 35, sync = true },
        { time = 5, eventID = 33, sync = true },
        { time = 15, eventID = 36, sync = true },  -- inerte : eventID absent de mes données
        { time = 28, eventID = 34, sync = true },
        { time = 16.85, eventID = 35 },
        { time = 18, eventID = 33 },
        { time = 15, eventID = 313 },  -- inerte : eventID absent de mes données
    },
    [3333] = {  -- 7 règles, 7 résolues
        { time = 2, eventID = 111, sync = true },
        { time = 11, eventID = 109, sync = true },
        { time = 52, eventID = 110, sync = true },
        { time = 24, eventID = 112, sync = true },
        { time = 26, eventID = 111 },
        { time = 25, eventID = 109 },
        { time = 10, eventID = 112 },
    },
    [3456] = {  -- 6 règles, 0 résolues
        { time = 8, eventID = 797, sync = true },  -- inerte : eventID absent de mes données
        { time = 25, eventID = 795, sync = true },  -- inerte : eventID absent de mes données
        { time = 13, eventID = 798, sync = true },  -- inerte : eventID absent de mes données
        { time = 45, eventID = 795, sync = true },  -- inerte : eventID absent de mes données
        { time = 24, eventID = 899, sync = true },  -- inerte : eventID absent de mes données
        { time = 24, eventID = 797 },  -- inerte : eventID absent de mes données
    },
    [3457] = {  -- 7 règles, 0 résolues
        { time = 1, eventID = 813, sync = true },  -- inerte : eventID absent de mes données
        { time = 11, eventID = 814, sync = true },  -- inerte : eventID absent de mes données
        { time = 19, eventID = 816, sync = true },  -- inerte : eventID absent de mes données
        { time = 10, eventID = 813, sync = true },  -- inerte : eventID absent de mes données
        { time = 28, eventID = 816, sync = true },  -- inerte : eventID absent de mes données
        { time = 20, eventID = 814, sync = true },  -- inerte : eventID absent de mes données
        { time = 20, eventID = 818 },  -- inerte : eventID absent de mes données
    },
    [3458] = {  -- 6 règles, 0 résolues
        { time = 30, eventID = 821, sync = true },  -- inerte : eventID absent de mes données
        { time = 16, eventID = 823, sync = true },  -- inerte : eventID absent de mes données
        { time = 24, eventID = 824, sync = true },  -- inerte : eventID absent de mes données
        { time = 62, eventID = 822 },  -- inerte : eventID absent de mes données
        { time = 32, eventID = 824 },  -- inerte : eventID absent de mes données
        { time = 16, eventID = 821 },  -- inerte : eventID absent de mes données
    },
}
