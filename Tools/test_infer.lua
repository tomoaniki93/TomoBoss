-- Banc d'essai hors-jeu pour Learn/Infer.lua (schéma v2).
--
-- Deux familles de cas :
--   A. pulls synthétiques (bruit, observations perdues, wipes précoces) ;
--   B. la CAPTURE RÉELLE d'Emberdawn (3056, 233 s, 92 observations), qui sert
--      de référence : l'inférence doit y retrouver la structure que l'analyse
--      manuelle du dump avait établie.
--
-- Lancer :  lua5.1 Tools/test_infer.lua

local NS = { db = { profile = { learn = { enabled = true, pulls = {} } } } }
function NS.round(x, d) local m = 10 ^ (d or 0) return math.floor(x * m + 0.5) / m end
function NS:SafeNumber(v) return tonumber(v) end
function NS:IsSecret() return false end
function NS:Debug() end
function NS:Print(...) local t = {} for i = 1, select("#", ...) do t[i] = tostring(select(i, ...)) end
    print((table.concat(t, " "):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))) end
NS.Learn = {}
NS.CurrentEncounterCandidates = function() return nil end
_G.GetTime = function() return 0 end
_G.date = function() return "test" end
_G.wipe = function(t) for k in pairs(t) do t[k] = nil end return t end
_G.GetInstanceInfo = function() return "Test", nil, nil, nil, nil, nil, nil, 2805 end
_G.UnitName = function() return nil end

local function load_module(path) return assert(loadfile(path))("TomoBoss", NS) end
load_module("Learn/Store.lua")
load_module("Learn/Journal.lua")
load_module("Learn/Infer.lua")

local Store = NS.Learn.Store
local K_CAST, K_CHAN, K_TL = Store.KIND_CAST, Store.KIND_CHANNEL, Store.KIND_TIMELINE

-- obs = { t, kind, dur, npc, unit, fire, sname }
local function obsTL(t, interval)   return { t, K_TL, interval, nil, nil, t + interval } end
local function obsCast(start, dur, chan)
    return { start + dur, chan and K_CHAN or K_CAST, dur, nil, "boss1" }
end

local function mkPull(obs, len)
    table.sort(obs, function(a, b) return a[1] < b[1] end)
    return { schema = Store.SCHEMA, date = "test", len = len, outcome = "wipe", obs = obs }
end

local function record(key, pulls) NS.db.profile.learn.pulls[key] = pulls end

--========================================================================
-- A. cas synthétiques
--========================================================================
math.randomseed(20260726)
local function jitter(v, a) return v + (math.random() * 2 - 1) * a end

-- `id` = durée-identité annoncée par la timeline. La capture réelle montre
-- qu'elle est CONSTANTE par capacité (tl:15.50 la porte sur ses 9 occurrences)
-- : c'est le cooldown NOMINAL, pas l'intervalle réel jusqu'à la prochaine.
-- Les écarts observés s'en écartent quand une phase met le cycle en pause.
local truth = {
    { id = 41.5, first = 7,  series = { 41.5 },       cast = 2.0 },
    { id = 19.0, first = 11, series = { 19, 63.8 },   cast = 4.0 },
    { id = 12.0, first = 5,  series = { 12, 20, 33 }, cast = 1.5 },
}

local function synth(length, opts)
    local obs = {}
    for _, a in ipairs(truth) do
        local t, i = a.first, 1
        while t < length do
            if not (opts.dropRate and math.random() < opts.dropRate) then
                local start = jitter(t, opts.noise or 0)
                obs[#obs + 1] = obsTL(NS.round(start, 2), a.id)
                obs[#obs + 1] = obsCast(NS.round(start, 2), a.cast)
            end
            t = t + a.series[((i - 1) % #a.series) + 1]
            i = i + 1
        end
    end
    return mkPull(obs, length)
end

local function runSynth(label, n, length, opts)
    local pulls = {}
    for _ = 1, n do pulls[#pulls + 1] = synth(length, opts) end
    record("synth", pulls)
    local res = NS.Learn.Infer:Analyze("synth")
    print(("\n=== %s (%d pulls de %ds, bruit ±%.2f, pertes %d%%) ==="):format(
        label, n, length, opts.noise or 0, (opts.dropRate or 0) * 100))
    local by = {}
    for _, r in ipairs(res or {}) do by[r.timelineDur or 0] = r end
    local ok = true
    for _, t in ipairs(truth) do
        local r = by[t.id]
        if not r then print(("  id-dur %-6s MANQUANTE"):format(t.id)); ok = false
        else
            local good = #r.cdSeriesSec == #t.series
            if good then
                for i, v in ipairs(t.series) do
                    if math.abs(r.cdSeriesSec[i] - v) > math.max(0.6, v * 0.05) then good = false end
                end
            end
            -- L'occurrence est ancrée sur l'instant où la mécanique TOMBE,
            -- donc sur la FIN de l'incantation : la première apparition
            -- attendue est décalée de la durée d'incantation.
            local firstOk = math.abs(r.firstSeenSec - (t.first + t.cast)) <= 1.0
            local castOk  = math.abs(r.castDuration - t.cast) <= 0.15
            local under   = opts.horizonShort and #t.series > 1 and r.warn
            if not (good and firstOk and castOk) and not under then ok = false end
            local verdict = (good and firstOk and castOk) and "OK   " or (under and "TOLÉRÉ" or "ÉCHEC")
            print(("  id-dur %-6s %s  cd={%s} attendu {%s}  first=%.1f (attendu %.1f)  cast=%.2f"):format(
                t.id, verdict,
                table.concat(r.cdSeriesSec, ", "), table.concat(t.series, ", "),
                r.firstSeenSec, t.first + t.cast, r.castDuration))
            -- sur échec : le système s'est-il DÉCLARÉ incertain, ou a-t-il affirmé
            -- une valeur fausse avec assurance ? C'est toute la différence.
            if verdict == "ÉCHEC" then
                NS.Learn.Infer._trace = true
                NS.Learn.Infer._traceDur = t.id
                NS.Learn.Infer:Analyze("synth")
                NS.Learn.Infer._trace = nil
                print(("           -> qualité=%s  avertissement=%s"):format(
                    r.quality, r.warn and ("« " .. r.warn .. " »") or "AUCUN  << faux positif"))
            end
        end
    end
    return ok
end

local pass = true
pass = runSynth("Conditions idéales",      5, 300, { noise = 0.05 }) and pass
pass = runSynth("Bruit réaliste",          5, 300, { noise = 0.35 }) and pass
pass = runSynth("15 % d'obs perdues",      5, 300, { noise = 0.35, dropRate = 0.15 }) and pass
pass = runSynth("Peu de données",          2, 150, { noise = 0.35 }) and pass
pass = runSynth("Pulls courts",            6, 90,  { noise = 0.35, dropRate = 0.10, horizonShort = true }) and pass

--========================================================================
-- B. capture réelle — Emberdawn (3056)
--========================================================================
print("\n=== CAPTURE RÉELLE — Emberdawn 3056 (233 s, 92 observations) ===")
local raw = [[
0.00 T 15.00 15.00
0.00 T 10.00 10.00
0.00 T 6.00 6.00
6.42 T 15.50 21.92
7.91 C 1.49
10.06 T 13.00 23.06
13.05 C 2.99
36.00 H 15.99
36.76 T 30.00 66.76
36.76 T 10.00 46.76
36.76 T 6.00 42.76
36.76 T 30.00 66.76
36.76 T 10.00 46.76
36.76 T 6.00 42.76
36.76 T 30.00 66.76
36.76 T 10.00 46.76
36.76 T 6.00 42.76
42.85 T 15.50 58.35
44.34 C 1.49
47.69 T 13.00 60.69
50.68 C 2.99
58.64 T 15.50 74.14
60.12 C 1.48
61.07 T 13.00 74.07
64.05 C 2.97
86.82 H 16.00
87.78 T 30.00 117.78
87.78 T 10.00 97.78
87.78 T 6.00 93.78
87.87 T 30.00 117.87
87.87 T 10.00 97.87
87.87 T 6.00 93.87
95.04 T 15.50 110.54
96.53 C 1.49
98.68 T 13.00 111.68
101.65 C 2.97
109.64 T 13.00 122.64
112.61 C 2.97
113.27 T 15.50 128.77
114.75 C 1.48
118.13 T 10.64 128.77
138.06 H 15.99
138.75 T 30.00 168.75
138.75 T 10.00 148.75
138.75 T 6.00 144.75
144.83 T 15.50 160.33
146.32 C 1.49
149.68 T 13.00 162.68
152.67 C 2.99
160.61 T 15.50 176.11
162.10 C 1.49
163.02 T 13.00 176.02
166.01 C 2.99
188.94 H 16.01
189.75 T 30.00 219.75
189.75 T 10.00 199.75
189.75 T 6.00 195.75
195.81 T 15.50 211.31
197.31 C 1.49
200.66 T 13.00 213.66
203.65 C 2.99
211.60 T 15.50 227.10
213.10 C 1.50
214.02 T 13.00 227.02
217.02 C 3.00
]]
local obs = {}
for line in raw:gmatch("[^\n]+") do
    local t, k, d, f = line:match("^(%S+)%s+(%a)%s+(%S+)%s*(%S*)$")
    if t then
        t, d = tonumber(t), tonumber(d)
        if k == "T" then obs[#obs + 1] = { t, K_TL, d, nil, nil, tonumber(f) }
        else obs[#obs + 1] = { t, k == "H" and K_CHAN or K_CAST, d, nil, "boss1" } end
    end
end
-- ACCUMULATION : le pull d'origine (233 s, wipe) + celui du 1er août
-- (119 s, kill). C'est le scénario réel d'usage — l'inférence doit gagner en
-- confiance à mesure que les pulls s'ajoutent, pas seulement fonctionner sur un.
local corpusEarly = assert(loadfile("Tools/corpus_real.lua"))()
local second = corpusEarly["3056"]
if second then
    second.schema, second.date = Store.SCHEMA, "corpus"
    record("3056", { mkPull(obs, 233), second })
    print("  (2 pulls : 233 s wipe + 119 s kill)")
else
    record("3056", { mkPull(obs, 233) })
end
NS.Learn.Infer:PrintReport("3056")

print(("\n%s"):format(pass and ">>> CAS SYNTHÉTIQUES : TOUS PASSENT" or ">>> AU MOINS UN CAS SYNTHÉTIQUE ÉCHOUE"))

-- Un cycle non trouvé doit se DÉCLARER, jamais faire illusion.
-- On force la situation avec un taux de perte élevé : à 45 %, la structure
-- cyclique n'est plus reconstructible, et c'est précisément ce que le système
-- doit dire au lieu de rendre une moyenne présentée comme fiable.
print("\n=== ÉCHEC SÛR (45 % d'observations perdues) ===")
math.randomseed(4242)
local pulls = {}
for _ = 1, 4 do pulls[#pulls + 1] = synth(300, { noise = 0.8, dropRate = 0.45 }) end
record("safe", pulls)
local weak, confident = 0, 0
for _, r in ipairs(NS.Learn.Infer:Analyze("safe") or {}) do
    -- une série RÉPÉTÉE décrit la même chose que la série de base
    -- ({41.5, 41.5} == {41.5}) : ce n'est pas une erreur.
    local truthFor = { [41.5] = { 41.5 }, [19] = { 19, 63.8 }, [12] = { 12, 20, 33 } }
    local ref = truthFor[r.timelineDur or 0]
    local wrong = false
    if ref then
        if #r.cdSeriesSec == 0 or #r.cdSeriesSec % #ref ~= 0 then wrong = true
        else
            for i, v in ipairs(r.cdSeriesSec) do
                local want = ref[((i - 1) % #ref) + 1]
                if math.abs(v - want) > math.max(0.8, want * 0.08) then wrong = true end
            end
        end
    end
    if wrong then
        if r.warn or r.quality == "faible" then weak = weak + 1
        else confident = confident + 1 end
        print(("  id-dur %-6s série={%s} -> qualité=%s  warn=%s"):format(
            tostring(r.timelineDur), table.concat(r.cdSeriesSec, ", "),
            r.quality, r.warn and "oui" or "AUCUN"))
    end
end
print(("  %d résultat(s) faux signalé(s), %d affirmé(s) à tort."):format(weak, confident))
assert(confident == 0, "REGRESSION : une série fausse a été présentée comme fiable")
print("  OK — aucun faux positif.")


--========================================================================
-- C. Corpus réel — 8 rencontres, 2 donjons (Académie 2526, Terrasse 2811)
--========================================================================
-- Ces captures viennent de pulls réels et servent de garde-fou de régression :
-- elles contiennent des motifs qu'aucun jeu de données synthétique n'avait
-- produits (séries de 5 valeurs, incantations toutes instantanées, durées
-- sentinelles, conseils à cinq unités, amorçage par lots).
print("\n=== CORPUS RÉEL (22 rencontres, 6 donjons) ===")
local corpus = assert(loadfile("Tools/corpus_real.lua"))()
local expect = {
    -- clé, groupe attendu, série attendue (les cas verifies a la main)
    { "2562", "instant:boss1", { 8.5, 9.5, 8.5, 7.5, 10 } },
    { "2565", "instant:boss1", { 11, 3.5, 8.5, 10 } },
    { "2562", "tl:18.00",      { 3, 10, 31 } },
    -- Maisara 3212 : six capacités partageant une durée-identité de 45 s.
    -- Chacune doit ressortir séparément avec un cooldown de 45 s, et non
    -- fondue en une capacité unique à six positions.
    { "3212", "tl:45.00#3",    { 45 } },
    { "3328", "tl:12.00",      { 12 } },
    -- Siège du Triumvirat : marqueur à 102 s sur un pull de 124 s. Un seuil
    -- fixe à 300 s le manquait ; la règle observationnelle le rattrape.
    { "2065", "tl:102.00",     { 24.9, 32.2 } },
}
local corpusOK = true
for key, c in pairs(corpus) do
    c.schema, c.date = Store.SCHEMA, "corpus"
    NS.db.profile.learn.pulls[key] = { c }
end
for _, e in ipairs(expect) do
    local key, want, series = e[1], e[2], e[3]
    local found
    for _, r in ipairs(NS.Learn.Infer:Analyze(key) or {}) do
        if r.key == want then found = r end
    end
    local ok = found and #found.cdSeriesSec == #series
    if ok then
        for i, v in ipairs(series) do
            if math.abs(found.cdSeriesSec[i] - v) > 0.35 then ok = false end
        end
    end
    if not ok then corpusOK = false end
    print(("  %s / %-14s %s  {%s}"):format(key, want, ok and "OK   " or "ÉCHEC",
        found and table.concat(found.cdSeriesSec, ", ") or "absent"))
end

-- aucune rencontre ne doit faire planter l'analyse
local total, nEnc = 0, 0
for key in pairs(corpus) do
    nEnc = nEnc + 1
    local res = NS.Learn.Infer:Analyze(key)
    assert(res, "analyse vide pour " .. key)
    total = total + #res
end
print(("  %d capacités extraites sur les %d rencontres, sans erreur."):format(total, nEnc))

-- Contrôle d'identité : le groupe à 45 s de Maisara doit donner SIX membres,
-- dont les débuts d'incantation retombent sur 5, 12, 20, 28, 35 et 41 s.
local members, starts = 0, {}
for _, r in ipairs(NS.Learn.Infer:Analyze("3212") or {}) do
    if r.splitOf == "tl:45.00" then
        members = members + 1
        starts[#starts + 1] = math.floor((r.firstSeenSec - r.castDuration) + 0.5)
    end
end
table.sort(starts)
print(("  3212 : %d membres, débuts d'incantation = {%s}")
    :format(members, table.concat(starts, ", ")))
assert(members == 6, "le groupe à 45 s doit donner six capacités")
assert(table.concat(starts, ",") == "5,12,20,28,35,41",
    "les offsets doivent correspondre aux valeurs relevées en jeu")
print("  OK — identités séparées et offsets conformes.")
assert(corpusOK, "REGRESSION sur le corpus réel")
print("  OK — corpus réel conforme.")
