-- Banc d'essai hors-jeu pour Learn/Infer.lua
-- Simule des pulls avec bruit, observations manquées et wipes précoces,
-- puis vérifie que l'inférence retrouve les séries d'origine.

local NS = { db = { profile = { learn = { enabled = true, pulls = {} } } } }
function NS.round(x, d) local m = 10 ^ (d or 0) return math.floor(x * m + 0.5) / m end
function NS:SafeNumber(v) return tonumber(v) end
function NS:Debug() end
function NS:Print(...) local t = {} for i = 1, select("#", ...) do t[i] = tostring(select(i, ...)) end print(table.concat(t, " ")) end
NS.Learn = {}
NS.CurrentEncounterCandidates = function() return nil end
_G.GetTime = function() return 0 end
_G.date = function() return "test" end
_G.wipe = function(t) for k in pairs(t) do t[k] = nil end return t end
_G.GetInstanceInfo = function() return "Test", nil, nil, nil, nil, nil, nil, 658 end
_G.C_EncounterJournal = nil
_G.EJ_SelectEncounter, _G.EJ_GetEncounterInfo = nil, nil
_G.C_Spell = nil
_G.UnitName = function() return nil end

local function load_module(path)
    local chunk = assert(loadfile(path))
    return chunk("TomoBoss", NS)
end

load_module("Learn/Store.lua")
load_module("Learn/Journal.lua")
load_module("Learn/Infer.lua")

local Store = NS.Learn.Store
local K_CAST, K_TL = Store.KIND_CAST, Store.KIND_TIMELINE

--------------------------------------------------------------------------
-- Générateur de pulls.
--------------------------------------------------------------------------
math.randomseed(20260726)
local function jitter(v, amp) return v + (math.random() * 2 - 1) * amp end

-- abilities : { name = , first = , series = { ... }, cast = }
local function makePull(abilities, length, opts)
    opts = opts or {}
    local obs = {}
    for _, a in ipairs(abilities) do
        local t, i = a.first, 1
        while t < length do
            local drop = opts.dropRate and math.random() < opts.dropRate
            if not drop then
                obs[#obs + 1] = { NS.round(jitter(t, opts.noise or 0.25), 2), K_CAST, a.cast, a.name }
                -- l'événement timeline correspondant, ajouté un cycle plus tôt
                obs[#obs + 1] = { NS.round(t - 5, 2), K_TL, a.series[((i - 2) % #a.series) + 1], nil, NS.round(t, 2) }
            end
            t = t + a.series[((i - 1) % #a.series) + 1]
            i = i + 1
        end
    end
    table.sort(obs, function(x, y) return x[1] < y[1] end)
    return { date = "test", len = length, outcome = "wipe", boss = "Test", inst = 658, obs = obs }
end

local function record(key, pulls)
    NS.db.profile.learn.pulls[key] = pulls
end

--------------------------------------------------------------------------
-- Cas de test.
--------------------------------------------------------------------------
local truth = {
    { name = "Cooldown fixe",     first = 7,  series = { 41.5 },     cast = 2.0 },
    { name = "Serie de deux",     first = 11, series = { 19, 63.8 }, cast = 4.0 },
    { name = "Serie de trois",    first = 5,  series = { 12, 20, 33 }, cast = 1.5 },
    { name = "Cycle rapide",      first = 3,  series = { 9 },        cast = 0.0 },
}

local function runCase(label, nPulls, length, opts)
    local pulls = {}
    for _ = 1, nPulls do pulls[#pulls + 1] = makePull(truth, length, opts) end
    record("test", pulls)

    local res = NS.Learn.Infer:Analyze("test")
    print(("\n=== %s (%d pulls de %ds, bruit ±%.2fs, pertes %d%%) ==="):format(
        label, nPulls, length, opts.noise or 0, (opts.dropRate or 0) * 100))

    local byName = {}
    for _, r in ipairs(res) do byName[r.name] = r end

    local allOk = true
    for _, t in ipairs(truth) do
        local r = byName[t.name]
        if not r then
            print(("  %-16s MANQUANTE"):format(t.name)); allOk = false
        else
            local expected = table.concat(t.series, ", ")
            local got = table.concat(r.cdSeriesSec, ", ")
            -- tolérance : 5 % sur chaque valeur, et bonne longueur de série
            local ok = (#r.cdSeriesSec == #t.series)
            if ok then
                for i, v in ipairs(t.series) do
                    if math.abs(r.cdSeriesSec[i] - v) > math.max(0.6, v * 0.05) then ok = false end
                end
            end
            local firstOk = math.abs(r.firstSeenSec - t.first) <= 1.0
            local underDet = opts.horizonShort and #t.series > 1
            if not (ok and firstOk) and not (underDet and r.warn) then allOk = false end
            print(("  %-16s %s  cd attendu {%s}  obtenu {%s}  first %.1f (attendu %d)  [%s, disp %.3f]"):format(
                t.name, (ok and firstOk) and "OK  " or "ECHEC", expected, got,
                r.firstSeenSec, t.first, r.quality, r.spread))
            if r.timelineDur then
                print(("      -> duree timeline correlee : %.1f"):format(r.timelineDur))
            end
        end
    end
    return allOk
end

local pass = true
pass = runCase("Conditions idéales",      5, 300, { noise = 0.05 }) and pass
pass = runCase("Bruit réaliste",          5, 300, { noise = 0.35 }) and pass
pass = runCase("Avec 15 % d'obs perdues", 5, 300, { noise = 0.35, dropRate = 0.15 }) and pass
pass = runCase("Peu de données",          2, 150, { noise = 0.35 }) and pass
pass = runCase("Pulls courts (wipes)",    6, 90,  { noise = 0.35, dropRate = 0.10, horizonShort = true }) and pass

print(("\n%s"):format(pass and ">>> TOUS LES CAS PASSENT" or ">>> AU MOINS UN CAS ECHOUE"))
