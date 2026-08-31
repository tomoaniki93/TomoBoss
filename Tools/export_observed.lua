-- TomoBoss — Générateur de données OBSERVÉES pour les 8 donjons de la saison 2.
--
-- Ces huit donjons sont en `matchOnly` : le moteur prédictif ne démarre jamais
-- dessus (Engine/Timeline.lua, lignes 260 et 299) et `cdSeriesSec` n'est
-- consommé que par `BT:BuildMatchIndex`, qui empile `firstSeenSec` et la série
-- dans un sac de durées comparé aux événements de C_EncounterTimeline.
--
-- Autrement dit : ici, une durée est une CLÉ D'IDENTIFICATION, pas une
-- prédiction. Le minutage vient de Blizzard. On n'a donc besoin d'aucune
-- inférence de cycle — seulement des durées réellement vues en jeu.
--
-- Le script conserve la sémantique éditoriale (name, role, voice, severity) et
-- les identifiants du jeu (spellID, eventID), et ne remplace QUE les durées.
-- Les noms et spellID viennent de Blizzard, pas d'une base tierce ; les
-- minutages, eux, deviennent intégralement des observations TomoBoss.
--
-- Usage :
--   lua5.4 Tools/export_observed.lua <chemin/vers/TomoBoss.lua> [dossier_sortie]
--
-- Sans dossier de sortie, écrit dans Build/observed/ et n'écrase rien.

local svPath  = arg[1] or "/mnt/user-data/uploads/TomoBoss.lua"
local outDir  = arg[2] or "Build/observed"

local TOL      = 0.75  -- identique à BlizzTimeline
local MIN_SEEN = 3     -- une durée doit avoir été vue au moins 3 fois
local K_TL     = 3     -- Store.KIND_TIMELINE
local SENTINEL = 900   -- au-delà : signal d'état, jamais un timer joueur

-- Les 8 donjons S2 et leurs rencontres, avec le fichier cible.
local DUNGEONS = {
    { file = "murder_row",          label = "Murder Row / L'Allée du Meurtre",
      enc = { 3101, 3102, 3103, 3105 } },
    { file = "den_of_nalorakk",     label = "Den of Nalorakk / Antre de Nalorak",
      enc = { 3207, 3208, 3209 } },
    { file = "the_blinding_vale",   label = "The Blinding Vale / Le Val Aveuglant",
      enc = { 3199, 3200, 3201, 3202 } },
    { file = "voidscar_arena",      label = "Voidscar Arena / Arène de la cicatrice du vide",
      enc = { 3285, 3286, 3287 } },
    { file = "altar_of_fangs",      label = "Altar of Fangs / Autel des Crochets",
      enc = { 3456, 3457, 3458 } },
    { file = "temple_of_sethraliss", label = "Temple of Sethraliss / Temple de Sephraliss",
      enc = { 2124, 2125, 2126, 2127 } },
    { file = "kings_rest",          label = "Kings' Rest / Repos des rois",
      enc = { 2139, 2140, 2142, 2143 } },
    { file = "ruby_life_pools",     label = "Ruby Life Pools / Bassin de l'essence rubis",
      enc = { 2606, 2609, 2623 } },
}

--------------------------------------------------------------------------
-- 1. Définitions EFFECTIVES : on rejoue le vrai moteur, base + corrections.
--------------------------------------------------------------------------
local NS = { Engine = nil }
local ok, err = pcall(function()
    local chunk = assert(loadfile("Engine/Timeline.lua"))
    -- Engine/Timeline.lua enregistre aussi des handlers d'événements ; on lui
    -- fournit des stubs inoffensifs, seul le registre nous intéresse.
    _G.CreateFrame = _G.CreateFrame or function()
        return setmetatable({}, { __index = function() return function() end end })
    end
    _G.GetTime = _G.GetTime or function() return 0 end
    _G.UnitGUID = _G.UnitGUID or function() return nil end
    _G.C_Timer = _G.C_Timer or { After = function() end, NewTicker = function() return { Cancel = function() end } end }
    chunk("TomoBoss", NS)
end)
if not ok then
    io.stderr:write("impossible de charger le moteur : ", tostring(err), "\n")
    os.exit(1)
end
assert(NS.Engine, "NS.Engine absent")

local ORDER = {
    "murder_row", "den_of_nalorakk", "the_blinding_vale", "voidscar_arena",
    "altar_of_fangs", "temple_of_sethraliss", "kings_rest", "ruby_life_pools",
}
for _, f in ipairs(ORDER) do
    local c = loadfile("Engine/Encounters/" .. f .. ".lua")
    if c then c("TomoBoss", NS) end
end
local corr = loadfile("Engine/Encounters/Season2Corrections.lua")
if corr then corr("TomoBoss", NS) end

-- Les noms de capacité ne vivent que dans les commentaires de fin de ligne des
-- fichiers source ; la définition en mémoire ne les porte pas. On les récupère
-- par spellID pour garder des fichiers lisibles.
local SPELL_NAMES = {}
for _, f in ipairs(ORDER) do
    local fh = io.open("Engine/Encounters/" .. f .. ".lua")
    if fh then
        for line in fh:lines() do
            local sid, nm = line:match("spellID%s*=%s*(%d+).-%-%-%s*(.-)%s*$")
            if sid and nm and nm ~= "" then SPELL_NAMES[tonumber(sid)] = nm end
        end
        fh:close()
    end
end

--------------------------------------------------------------------------
-- 2. Observations : durées timeline par rencontre, avec compte.
--------------------------------------------------------------------------
assert(loadfile(svPath))()
local pulls = TomoBossDB and TomoBossDB.profile
    and TomoBossDB.profile.learn and TomoBossDB.profile.learn.pulls
assert(pulls, "learn.pulls introuvable dans " .. svPath)

local function observedFor(encID)
    local list = pulls[tostring(encID)] or pulls[encID]
    if not list then return nil, 0 end
    local seen, nPulls = {}, #list
    for _, p in ipairs(list) do
        for _, o in ipairs(p.obs or {}) do
            if o[2] == K_TL and type(o[3]) == "number" and o[3] < SENTINEL then
                local d = math.floor(o[3] * 100 + 0.5) / 100
                seen[d] = (seen[d] or 0) + 1
            end
        end
    end
    local out = {}
    for d, n in pairs(seen) do
        if n >= MIN_SEEN then out[#out + 1] = { dur = d, n = n } end
    end
    table.sort(out, function(a, b) return a.dur < b.dur end)
    return out, nPulls
end

--------------------------------------------------------------------------
-- 3. Rattachement d'une durée observée à un événement de la définition.
--------------------------------------------------------------------------
local function currentDurs(ev)
    local d = {}
    if ev.firstSeenSec then d[#d + 1] = ev.firstSeenSec end
    for _, v in ipairs(ev.cdSeriesSec or {}) do d[#d + 1] = v end
    return d
end

local report = {}
local function note(fmt, ...) report[#report + 1] = string.format(fmt, ...) end

local function attach(def, obs)
    local events = def.events or {}
    local assigned = {}         -- ev -> { durées observées }
    local orphans, ambiguous = {}, {}

    for _, o in ipairs(obs) do
        local best, bestDelta, tied = nil, nil, 0
        for _, ev in ipairs(events) do
            for _, d in ipairs(currentDurs(ev)) do
                local delta = math.abs(o.dur - d)
                if delta <= TOL then
                    if not bestDelta or delta < bestDelta - 0.01 then
                        best, bestDelta, tied = ev, delta, 1
                    elseif math.abs(delta - bestDelta) <= 0.01 and ev ~= best then
                        tied = tied + 1
                    end
                end
            end
        end
        if not best then
            orphans[#orphans + 1] = o
        elseif tied > 1 then
            -- Le moteur renvoie une alerte générique en cas d'égalité : on ne
            -- tranche pas non plus, on signale pour une règle DURATION_RULES.
            ambiguous[#ambiguous + 1] = o
            assigned[best] = assigned[best] or {}
            assigned[best][#assigned[best] + 1] = o
        else
            assigned[best] = assigned[best] or {}
            assigned[best][#assigned[best] + 1] = o
        end
    end
    return assigned, orphans, ambiguous
end

--------------------------------------------------------------------------
-- 4. Écriture des fichiers.
--------------------------------------------------------------------------
local function q(s) return '"' .. tostring(s):gsub('"', '\\"') .. '"' end
local function num(v)
    if v == math.floor(v) then return tostring(math.floor(v)) end
    return (string.format("%.2f", v):gsub("0+$", ""):gsub("%.$", ""))
end

os.execute("mkdir -p " .. outDir)
local stats = { enc = 0, kept = 0, dropped = 0, orphan = 0, ambig = 0, noData = 0 }

for _, dg in ipairs(DUNGEONS) do
    local lines = {}
    local function w(s) lines[#lines + 1] = s end
    w("---@diagnostic disable: undefined-global")
    w("-- TomoBoss — Donjon : " .. dg.label)
    w("--")
    w("-- Données de MATCHING générées depuis les captures TomoBoss (module Learn).")
    w("-- Chaque durée ci-dessous a été observée au moins " .. MIN_SEEN .. " fois sur")
    w("-- ENCOUNTER_TIMELINE_EVENT_ADDED en jeu. Aucune source tierce.")
    w("--")
    w("-- `matchOnly = true` : le minutage vient de C_EncounterTimeline, ces valeurs")
    w("-- ne servent qu'à identifier la capacité. Rôles, voix et sévérités sont des")
    w("-- choix éditoriaux conservés depuis la version précédente.")
    w("")
    w("local NS = select(2, ...)")
    w("local R = function(id, def) NS.Engine:RegisterEncounter(id, def) end")
    w("")

    for _, encID in ipairs(dg.enc) do
        local def = NS.Engine:GetEncounter(encID)
        local obs, nPulls = observedFor(encID)
        stats.enc = stats.enc + 1

        if not def then
            note("[%d] AUCUNE définition dans le dépôt — ignoré", encID)
        elseif not obs or #obs == 0 then
            stats.noData = stats.noData + 1
            note("[%d] %s : aucune durée observée %d+ fois (%d pull(s)) — fichier d'origine conservé",
                encID, def.name or "?", MIN_SEEN, nPulls)
        else
            local assigned, orphans, ambiguous = attach(def, obs)
            local nKept = 0
            for _, ev in ipairs(def.events or {}) do
                if assigned[ev] and #assigned[ev] > 0 then nKept = nKept + 1 end
            end
            if nKept == 0 and #orphans == 0 then
                -- Émettre une rencontre vide supprimerait toute correspondance :
                -- pire que de conserver la donnée d'origine. On laisse en l'état.
                note("[%d] %s : aucune durée rattachable — DÉFINITION D'ORIGINE CONSERVÉE",
                    encID, def.name or "?")
                goto continue
            end
            w(string.format("-- %s  (encounterID %d) — %d pull(s) capturé(s)",
                def.name or "?", encID, nPulls))
            w(string.format("R(%d, {", encID))
            w(string.format("    name = %s,", q(def.name or "?")))
            w('    provenance = "observed",')
            if def.dungeon then w(string.format("    dungeon = %s,", q(def.dungeon))) end
            w("    matchOnly = true,")
            w("    events = {")

            for _, ev in ipairs(def.events or {}) do
                local got = assigned[ev]
                if got and #got > 0 then
                    stats.kept = stats.kept + 1
                    local ds, cnt = {}, {}
                    for _, o in ipairs(got) do
                        ds[#ds + 1] = num(o.dur); cnt[#cnt + 1] = num(o.dur) .. "×" .. o.n
                    end
                    local bits = {}
                    if ev.role then bits[#bits + 1] = "role = " .. q(ev.role) end
                    if ev.voice then bits[#bits + 1] = "voice = " .. q(ev.voice) end
                    if ev.spellID then bits[#bits + 1] = "spellID = " .. num(ev.spellID) end
                    if ev.eventID then bits[#bits + 1] = "eventID = " .. num(ev.eventID) end
                    bits[#bits + 1] = "firstSeenSec = " .. ds[1]
                    bits[#bits + 1] = "cdSeriesSec = { " .. table.concat(ds, ", ") .. " }"
                    bits[#bits + 1] = "severity = " .. num(ev.severity or 1)
                    w(string.format("        { %s },  -- %s  [vu %s]",
                        table.concat(bits, ", "),
                        SPELL_NAMES[ev.spellID] or ev.name or "capacité",
                        table.concat(cnt, " ")))
                else
                    stats.dropped = stats.dropped + 1
                    note("[%d] %s : durée(s) %s jamais observée(s) — entrée RETIRÉE",
                        encID, tostring(ev.spellID or ev.eventID or "?"),
                        table.concat(currentDurs(ev), "/"))
                end
            end
            -- Une durée observée sans capacité connue est une VRAIE mécanique que
            -- la donnée tierce ne couvrait pas. La jeter reviendrait à perdre
            -- l'observation ; on l'émet avec une voix neutre et un marqueur.
            for _, o in ipairs(orphans) do
                stats.orphan = stats.orphan + 1
                w(string.format(
                    '        { role = "other", voice = "watch-dodge", firstSeenSec = %s, cdSeriesSec = { %s }, severity = 1 },  -- TODO identifier  [vu %s×%d]',
                    num(o.dur), num(o.dur), num(o.dur), o.n))
                note("[%d] durée %s vue %d fois, capacité inconnue — émise en TODO, rôle et voix à définir",
                    encID, num(o.dur), o.n)
            end
            w("    },")
            w("})")
            w("")
            for _, o in ipairs(ambiguous) do
                stats.ambig = stats.ambig + 1
                note("[%d] durée %s ambiguë entre plusieurs capacités — DURATION_RULES nécessaire",
                    encID, num(o.dur))
            end
        end
        ::continue::
    end

    local path = outDir .. "/" .. dg.file .. ".lua"
    local fh = assert(io.open(path, "w"))
    fh:write(table.concat(lines, "\n"), "\n")
    fh:close()
    print("écrit : " .. path)
end

local rp = outDir .. "/RAPPORT.txt"
local fh = assert(io.open(rp, "w"))
fh:write("TomoBoss — export des durées observées (saison 2, 8 donjons)\n")
fh:write(string.format("généré le %s depuis %s\n\n", os.date("%Y-%m-%d %H:%M"), svPath))
fh:write(string.format("rencontres traitées      : %d\n", stats.enc))
fh:write(string.format("entrées confirmées       : %d\n", stats.kept))
fh:write(string.format("entrées retirées         : %d  (durée jamais observée)\n", stats.dropped))
fh:write(string.format("durées orphelines        : %d  (observées, capacité inconnue)\n", stats.orphan))
fh:write(string.format("durées ambiguës          : %d  (règle de désambiguïsation à écrire)\n", stats.ambig))
fh:write(string.format("rencontres sans donnée   : %d\n\n", stats.noData))
fh:write(table.concat(report, "\n"), "\n")
fh:close()
print("rapport : " .. rp)
print(string.format("\n%d entrées confirmées, %d retirées, %d orphelines, %d ambiguës",
    stats.kept, stats.dropped, stats.orphan, stats.ambig))
