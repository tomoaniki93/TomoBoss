---@diagnostic disable: undefined-global
-- TomoBoss — Base TrashCD : capacités importantes des packs (par donjon).
-- Convertie depuis EXBoss (saison 12.0 S1). Aucun caractère non latin.
-- Le nom du sort est résolu en direct depuis le client ; nameEN sert de repli.
--
-- Structure : NS.TrashCD:RegisterDungeon(mapID, { mobs = { [npcID] = {
--     spells = { [spellID] = { nameEN, castTime, channelTime, first, cd = {..}, cdMode } } } } })

local NS = select(2, ...)
local R = function(mapID, def) NS.TrashCD:RegisterDungeon(mapID, def) end

-- Fosse de Saron (mapID 658) — 5 packs suivis
R(658, { mobs = {
    [252563] = { spells = {
        [1258820] = { nameEN = "Torrent of Misery", castTime = 0, channelTime = 6, first = 9.1, cd = { 19.5 } },
    } },
    [252564] = { spells = {
        [1259188] = { nameEN = "Cryoburst", castTime = 5, first = 8.1, cd = { 33.8 } },
        [1259226] = { nameEN = "Focused Guard", castTime = 2.5, channelTime = 12, first = 24.3, cd = { 24.3 } },
    } },
    [252606] = { spells = {
        [1258997] = { nameEN = "Plungegrip", castTime = 0, channelTime = 12, first = 9, cd = { 29 }, cdMode = "CAST_START" },
    } },
    [252610] = { spells = {
        [1258439] = { nameEN = "Frostbane Slash", castTime = 2.5, first = 4, cd = { 15.4 } },
        [1278963] = { nameEN = "Dark Rupture", castTime = 2.5, first = 2.6, cd = { 20.5 } },
    } },
    [257190] = { spells = {
        [1278986] = { nameEN = "Frost Breath", castTime = 4.5, first = 7.7, cd = { 19.4, 21 } },
    } },
} })

-- Cime-du-Ciel (mapID 1209) — 5 packs suivis
R(1209, { mobs = {
    [76087] = { spells = {
        [1253446] = { nameEN = "Solar Flame", castTime = 2, channelTime = 6, first = 7, cd = { 4.6, 4.1, 5, 4.1, 4.1, 4.1 } },
        [1253448] = { nameEN = "Solar Nova", castTime = 3.5, first = 14, cd = { 25 } },
    } },
    [76149] = { spells = {
        [1254566] = { nameEN = "Dire Screech", castTime = 2.5, channelTime = 1, first = 11.6, cd = { 23 } },
        [1258174] = { nameEN = "Dread Wind", castTime = 3, first = 4.4, cd = { 20 } },
    } },
    [76154] = { spells = {
        [1254686] = { nameEN = "Mark of Death", castTime = 2.5, first = 6.2, cd = { 19 } },
    } },
    [78933] = { spells = {
        [1254355] = { nameEN = "Solar Orb", castTime = 2, first = 12.2, cd = { 24 } },
        [1258217] = { nameEN = "Solar Fire", castTime = 0, channelTime = 6, first = 6.1, cd = { 10.2 } },
    } },
    [79303] = { spells = {
        [1254380] = { nameEN = "Shear", castTime = 3, first = 8, cd = { 22.5 } },
        [1254460] = { nameEN = "Blade Rush", castTime = 2, first = 12.2, cd = { 22.3 } },
    } },
} })

-- Siège du Triumvirat (mapID 1753) — 5 packs suivis
R(1753, { mobs = {
    [122421] = { spells = {
        [1280326] = { nameEN = "Void Bash", castTime = 2, first = 7.3, cd = { 19 } },
    } },
    [122423] = { spells = {
        [1262508] = { nameEN = "Void Infusion", castTime = 2, channelTime = 5, first = 12.4, cd = { 13.6 } },
        [1264286] = { nameEN = "Gate of the Abyss", castTime = 2, first = 6.3, cd = { 17 } },
    } },
    [122571] = { spells = {
        [1264499] = { nameEN = "Rift Tear", castTime = 2, channelTime = 3, first = 9.5, cd = { 39 } },
        [1280330] = { nameEN = "Rift Essence", castTime = 3, first = 6.4, cd = { 35.9 } },
    } },
    [124171] = { spells = {
        [1262506] = { nameEN = "Leeching Void", castTime = 2, first = 15.8, cd = { 22.3 } },
        [1262509] = { nameEN = "Chains of Subjugation", castTime = 2, channelTime = 6, first = 7.3, cd = { 15 } },
    } },
    [252756] = { spells = {
        [1262335] = { nameEN = "Void Cleave", castTime = 4.5, first = 10.2, cd = { 18.5, 18.2, 22.2 } },
        [1262429] = { nameEN = "Eruption", castTime = 3, first = 6.2, cd = { 20, 20.1, 22.5 } },
    } },
} })

-- Académie d'Algeth'ar (mapID 2526) — 5 packs suivis
R(2526, { mobs = {
    [192333] = { spells = {
        [377383] = { nameEN = "Gust", castTime = 2.5, first = 5.3, cd = { 15.3 } },
        [377389] = { nameEN = "Raging Screech", castTime = 3, first = 9, cd = { 23.3 } },
    } },
    [192680] = { spells = {
        [377912] = { nameEN = "Expel Intruders", castTime = 5.5, first = 10, cd = { 21.2 } },
        [377991] = { nameEN = "Storm Slash", castTime = 3, first = 2.8, cd = { 9 } },
        [378003] = { nameEN = "Deadly Winds", castTime = 2.5, first = 6.4, cd = { 8 } },
    } },
    [196200] = { spells = {
        [1270356] = { nameEN = "Arcane Smash", castTime = 3, first = 4.5, cd = { 22.5 } },
    } },
    [196671] = { spells = {
        [388942] = { nameEN = "Vicious Ambush", castTime = 3.5, first = 3.3, cd = { 14.5 }, cdMode = "CAST_START" },
        [388976] = { nameEN = "Riftbreath", castTime = 2.5, channelTime = 2.5, first = 7, cd = { 13.2 } },
    } },
    [197219] = { spells = {
        [1282244] = { nameEN = "Vile Bite", castTime = 3, first = 8, cd = { 10.3 } },
    } },
} })

-- Flèche des Coursevent (mapID 2805) — 8 packs suivis
R(2805, { mobs = {
    [232056] = { spells = {
        [1216848] = { nameEN = "Fire Spit", castTime = 0, channelTime = 9, first = 3.5, cd = { 17 }, cdMode = "CAST_START" },
    } },
    [232063] = { spells = {
        [1216985] = { nameEN = "Puncturing Bite", castTime = 3, first = 4, cd = { 21.3 } },
        [1217010] = { nameEN = "Ferocious Pounce", castTime = 3.5, first = 12, cd = { 18.4 } },
    } },
    [232113] = { spells = {
        [1216250] = { nameEN = "Arcane Salvo", castTime = 0, channelTime = 6, first = 5.8, cd = { 22 }, cdMode = "CAST_START" },
    } },
    [232122] = { spells = {
        [471643] = { nameEN = "Interrupting Screech", castTime = 5, first = 18.9, cd = { 36.3, 22.9 } },
        [471648] = { nameEN = "Break Ranks", castTime = 5, first = 5.5, cd = { 15.2 } },
    } },
    [232146] = { spells = {
        [1270618] = { nameEN = "Flame Nova", castTime = 4, first = 8, cd = { 20 } },
    } },
    [232175] = { spells = {
        [473672] = { nameEN = "Pulsing Shriek", castTime = 0, channelTime = 20, first = 10, cd = { 31 }, cdMode = "CAST_START" },
    } },
    [232176] = { spells = {
        [473776] = { nameEN = "Fetid Spew", castTime = 2.5, first = 12.7, cd = { 20.5 } },
        [1277799] = { nameEN = "Brutal Chop", castTime = 3.5, first = 6.2, cd = { 15.9 } },
    } },
    [236894] = { spells = {
        [1216963] = { nameEN = "Spore Dispersal", castTime = 4, first = 10, cd = { 21.5 } },
    } },
} })

-- Terrasse des Magistères (mapID 2811) — 5 packs suivis
R(2811, { mobs = {
    [234062] = { spells = {
        [473258] = { nameEN = "Crowd Dispersal", castTime = 3, first = 24, cd = { 24.9 } },
        [1282050] = { nameEN = "Arcane Beam", castTime = 3, channelTime = 5, first = 11.9, cd = { 18.7 } },
        [1282055] = { nameEN = "Ethereal Shackles", castTime = 2, first = 6.5, cd = { 25.9 } },
    } },
    [234066] = { spells = {
        [1264687] = { nameEN = "Devouring Strike", castTime = 2.5, first = 6, cd = { 15.3 } },
    } },
    [234068] = { spells = {
        [1255462] = { nameEN = "Call of the Void", castTime = 0, channelTime = 3, first = 6, cd = { 15.2, 11.5, 11.6, 11.6 } },
        [1265977] = { nameEN = "Consuming Shadows", castTime = 3, channelTime = 6, first = 16.5, cd = { 23.8 } },
    } },
    [240973] = { spells = {
        [1244907] = { nameEN = "Runic Glaive", castTime = 3, first = 4, cd = { 15.2 } },
        [1283901] = { nameEN = "Shield Slam", castTime = 3, first = 10, cd = { 16.4, 16.4, 18.9 } },
    } },
    [251861] = { spells = {
        [1254301] = { nameEN = "Flamestrike", castTime = 3.5, first = 9.4, cd = { 22 } },
        [1254336] = { nameEN = "Ignition", castTime = 2, first = 3.3, cd = { 20.7 } },
    } },
} })

-- Cavernes de Maisara (mapID 2874) — 8 packs suivis
R(2874, { mobs = {
    [248678] = { spells = {
        [1256047] = { nameEN = "Deafening Roar", castTime = 3.5, first = 15.7, cd = { 20.8 } },
        [1256059] = { nameEN = "Rending Gore", castTime = 2, first = 10.9, cd = { 22 } },
    } },
    [248686] = { spells = {
        [1257155] = { nameEN = "Rain of Toads", castTime = 1.5, channelTime = 8, first = 8, cd = { 11.1 } },
    } },
    [249020] = { spells = {
        [1257781] = { nameEN = "Shredding Talons", castTime = 0, channelTime = 5, first = 10, cd = { 15.5 }, cdMode = "CAST_START" },
    } },
    [249024] = { spells = {
        [1259677] = { nameEN = "Rend Souls", castTime = 0, channelTime = 6, first = 8.3, cd = { 16.7, 18.3 } },
        [1271623] = { nameEN = "Frost Nova", castTime = 3.2, first = 14.6, cd = { 21 } },
    } },
    [249025] = { spells = {
        [1257546] = { nameEN = "Vigilant Defense", castTime = 0, channelTime = 6, first = 18, cd = { 14.6, 14.6, 17.1, 17.1 } },
        [1259651] = { nameEN = "Soulstorms", castTime = 3, first = 8, cd = { 20.1 } },
    } },
    [249030] = { spells = {
        [1257895] = { nameEN = "Ancestral Crush", castTime = 3, first = 12, cd = { 12.8 } },
        [1259631] = { nameEN = "Staggering Blow", castTime = 3, first = 6, cd = { 23.7 } },
    } },
    [253302] = { spells = {
        [1258475] = { nameEN = "Magma Surge", castTime = 3.5, first = 5, cd = { 17 } },
        [1258806] = { nameEN = "Ritual Firebrand", castTime = 2.5, first = 13.5, cd = { 16.9 } },
    } },
    [253683] = { spells = {
        [1259786] = { nameEN = "Ritual Sacrifice", castTime = 0, channelTime = 1, first = 21.8, cd = { 30 } },
        [1262241] = { nameEN = "Invoke Shadow", castTime = 2.5, first = 14.4, cd = { 14.1 } },
    } },
} })

-- Point de Nexus : Xenas (mapID 2915) — 5 packs suivis
R(2915, { mobs = {
    [241642] = { spells = {
        [1257701] = { nameEN = "Searing Rend", castTime = 3, channelTime = 1, first = 2.8, cd = { 16.6 } },
        [1264354] = { nameEN = "Luciferin Flare", castTime = 4.5, first = 17.5, cd = { 21 } },
        [1281657] = { nameEN = "Blistering Smite", castTime = 3, first = 8.8, cd = { 22.5 } },
    } },
    [241660] = { spells = {
        [1252062] = { nameEN = "Entropic Leech", castTime = 3.4, channelTime = 12, first = 3.5, cd = { 17.4 } },
        [1252076] = { nameEN = "Dark Beckoning", castTime = 3, channelTime = 9, first = 14.2, cd = { 16.7, 19.2 } },
    } },
    [248373] = { spells = {
        [1249801] = { nameEN = "Arcing Mana", castTime = 0, channelTime = 7.5, first = 7.3, cd = { 17.6 } },
        [1262720] = { nameEN = "Energy Overflow", castTime = 1.5, channelTime = 2.5 },
    } },
    [248502] = { spells = {
        [1252406] = { nameEN = "Dreadbellow", castTime = 4.5, first = 13.3, cd = { 29.4 } },
        [1252417] = { nameEN = "Nullwark Blast", castTime = 1.5, channelTime = 3, first = 4.7, cd = { 21 } },
    } },
    [248506] = { spells = {
        [1252436] = { nameEN = "Void Lash", castTime = 2.4, first = 6.8, cd = { 29 } },
        [1252622] = { nameEN = "Flailstorm", castTime = 1.5, channelTime = 8.5, first = 22.5, cd = { 21.6 } },
    } },
} })

