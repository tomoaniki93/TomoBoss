-- Banc d'essai du garde-fou de REJEU (Learn/Infer.lua, replayFit).
--
-- Le repliement peut produire des paquets parfaitement serrés sur un cycle
-- FAUX : la dispersion ne voit rien, puisque les paquets SONT serrés. Le rejeu
-- teste la série contre les données plutôt que contre elle-même.
--
-- Ce banc verrouille la propriété dans LES DEUX SENS, parce qu'un garde-fou
-- trop strict est aussi nuisible qu'un garde-fou absent : il condamnerait des
-- données correctes au moment de l'export.
--
--   1. données propres          -> la série juste n'est PAS déclassée
--   2. cycle faux               -> la série est déclassée et signalée
--   3. occurrences manquantes   -> la perte seule ne déclasse pas
--
-- Lancer :  lua5.4 Tools/test_fit.lua

local NS = { db = { profile = { learn = { enabled = true, pulls = {} } } } }
function NS.round(x, d) local m = 10 ^ (d or 0) return math.floor(x * m + 0.5) / m end
function NS:SafeNumber(v) return tonumber(v) end
function NS:IsSecret() return false end
function NS:Debug() end
function NS:Print() end
NS.Learn = {}
NS.CurrentEncounterCandidates = function() return nil end
_G.GetTime = function() return 0 end
_G.date = function() return "test" end
_G.wipe = function(t) for k in pairs(t) do t[k] = nil end return t end
_G.GetInstanceInfo = function() return "Test", nil, nil, nil, nil, nil, nil, 2805 end
_G.UnitName = function() return nil end

local function load_module(p) return assert(loadfile(p))("TomoBoss", NS) end
load_module("Learn/Store.lua")
load_module("Learn/Journal.lua")
load_module("Learn/Infer.lua")

local Store, Infer = NS.Learn.Store, NS.Learn.Infer
local K_CAST, K_TL = Store.KIND_CAST, Store.KIND_TIMELINE

local function obsTL(t, interval) return { t, K_TL, interval, nil, nil, t + interval } end
local function obsCast(start, dur) return { start + dur, K_CAST, dur, nil, "boss1" } end

local function mkPull(obs, len)
    table.sort(obs, function(a, b) return a[1] < b[1] end)
    return { schema = Store.SCHEMA, date = "test", len = len, outcome = "wipe", obs = obs }
end

-- Une seule capacité : cycle {12, 20, 33}, identité timeline 12 s.
local ID, CAST, FIRST = 12.0, 1.5, 5
local SERIES = { 12, 20, 33 }

local function buildPull(length, noise, dropRate, rng)
    local obs, t, i = {}, FIRST, 1
    while t < length do
        if not (dropRate and rng() < dropRate) then
            local s = NS.round(t + (rng() * 2 - 1) * (noise or 0), 2)
            obs[#obs + 1] = obsTL(s, ID)
            obs[#obs + 1] = obsCast(s, CAST)
        end
        t = t + SERIES[((i - 1) % #SERIES) + 1]
        i = i + 1
    end
    return mkPull(obs, length)
end

local function analyze(pulls)
    NS.db.profile.learn.pulls["fit"] = pulls
    local res = Infer:Analyze("fit") or {}
    NS.db.profile.learn.pulls["fit"] = nil
    for _, r in ipairs(res) do
        if r.timelineDur == ID then return r end
    end
    return res[1]
end

local fails = 0
local function check(label, cond, detail)
    if cond then
        print(string.format("  %-46s OK", label))
    else
        fails = fails + 1
        print(string.format("  %-46s ECHEC   %s", label, detail or ""))
    end
end

math.randomseed(31415)
local rng = math.random

print("\n=== 1. donnees propres : pas de faux positif ===")
local clean = {}
for _ = 1, 4 do clean[#clean + 1] = buildPull(300, 0.30, nil, rng) end
local r = analyze(clean)
check("serie retrouvee", r and #r.cdSeriesSec == 3,
    r and ("{" .. table.concat(r.cdSeriesSec, ", ") .. "}") or "aucun resultat")
check("rejeu concluant", r and r.fit ~= nil, "fit absent")
check("fidelite >= 90%", r and r.fit and r.fit >= 0.90,
    r and r.fit and string.format("fit=%.0f%%", r.fit * 100) or "?")
check("qualite conservee en 'bon'", r and r.quality == "bon",
    r and ("quality=" .. tostring(r.quality)) or "?")

print("\n=== 2. pertes moderees : la perte seule ne declasse pas ===")
local lossy = {}
for _ = 1, 5 do lossy[#lossy + 1] = buildPull(300, 0.30, 0.10, rng) end
local r2 = analyze(lossy)
local right2 = r2 and #r2.cdSeriesSec == 3
if right2 then
    for i, v in ipairs(r2.cdSeriesSec) do
        if math.abs(v - SERIES[i]) > 0.8 then right2 = false end
    end
end
if right2 then
    check("serie juste non declassee", r2.quality ~= "faible",
        "quality=" .. tostring(r2.quality))
    check("fidelite >= 75%", r2.fit and r2.fit >= 0.75,
        r2.fit and string.format("fit=%.0f%%", r2.fit * 100) or "?")
else
    -- Si l'inference se trompe a ce taux de perte, le rejeu DOIT le voir :
    -- c'est precisement le cas dangereux.
    check("serie fausse signalee", r2 and (r2.quality ~= "bon" or r2.warn ~= nil),
        r2 and ("quality=" .. tostring(r2.quality)) or "?")
end

print("\n=== 3. cycle faux impose : declassement obligatoire ===")
-- On force une serie fausse mais parfaitement reguliere : le repliement la
-- valide (paquets serres), seul le rejeu peut la contredire.
local fake = { 32.7, 44.4, 20.4 }
local times = {}
do
    local t, i = FIRST, 1
    while t < 300 do
        times[#times + 1] = t
        t = t + SERIES[((i - 1) % #SERIES) + 1]
        i = i + 1
    end
end
local fit = Infer._testReplayFit and Infer._testReplayFit(fake, 97.5, { times })
check("replayFit expose pour le banc", fit ~= nil, "accesseur absent")
if fit then
    check("cycle faux contredit (fit < 75%)", fit < 0.75,
        string.format("fit=%.0f%%", fit * 100))
    local good = Infer._testReplayFit(SERIES, 65, { times })
    check("cycle juste confirme (fit = 100%)", good and good >= 0.99,
        good and string.format("fit=%.0f%%", good * 100) or "?")
end

print("")
if fails > 0 then
    error(string.format("%d verification(s) en echec", fails), 0)
end
print("OK — le rejeu declasse le faux sans condamner le juste.")
