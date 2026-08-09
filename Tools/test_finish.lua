-- Banc hors-jeu : issue du pull et course entre PLAYER_REGEN_ENABLED et
-- ENCOUNTER_END.
--
-- Sur un kill, le combat retombe avant qu'ENCOUNTER_END n'arrive. Clore
-- immédiatement faisait passer les kills pour des « abandon ».
--
-- Lancer : lua5.1 Tools/test_finish.lua

local NS = { db = { profile = { learn = { enabled = true, announce = false, pulls = {} } } } }
function NS.round(x, d) local m = 10 ^ (d or 0) return math.floor(x * m + 0.5) / m end
function NS:SafeNumber(v) return tonumber(v) end
function NS:SafeString(v) return type(v) == "string" and v ~= "" and v or nil end
function NS:IsSecret() return false end
function NS:Debug() end
function NS:Print() end
NS.Learn = {}
NS.Engine = { GetEncounter = function() end }
NS.CurrentEncounterCandidates = function() end

local NOW, TIMERS = 0, {}
_G.GetTime = function() return NOW end
_G.C_Timer = { After = function(d, fn) TIMERS[#TIMERS + 1] = { at = NOW + d, fn = fn } end }
local function advance(dt)
    local target = NOW + dt
    while true do
        local nxt, idx
        for i, t in ipairs(TIMERS) do
            if t.at <= target and (not nxt or t.at < nxt.at) then nxt, idx = t, i end
        end
        if not nxt then break end
        NOW = nxt.at; table.remove(TIMERS, idx); nxt.fn()
    end
    NOW = target
end
_G.date = function() return "t" end
_G.wipe = function(t) for k in pairs(t) do t[k] = nil end return t end
_G.GetInstanceInfo = function() return "Donjon", "party", nil, nil, nil, nil, nil, 2874 end
_G.GetNumGroupMembers = function() return 5 end
_G.UnitName = function() return "Boss" end
_G.UnitGUID = function() return nil end
_G.UnitExists = function() return false end
_G.CreateFrame = function() return { RegisterEvent = function() end, SetScript = function() end } end

assert(loadfile("Learn/Store.lua"))("T", NS)
assert(loadfile("Learn/Journal.lua"))("T", NS)
assert(loadfile("Learn/Recorder.lua"))("T", NS)
local R, Store = NS.Learn.Recorder, NS.Learn.Store

local ok = true
local function check(label, got, want)
    local good = got == want
    want, got = tostring(want), tostring(got)
    if not good then ok = false end
    print(("  %s %-44s attendu=%-8s obtenu=%s"):format(good and "OK   " or "ÉCHEC", label, want, got))
end

local function pull()
    NS.db.profile.learn.pulls = {}
    R._pendingEncID, R._pendingEncName, R._closing = 3212, "Boss", nil
    R:Begin("test")
    for i = 1, 6 do Store:Add(Store.KIND_TIMELINE, 45, nil, nil, NOW + 45) end
end
local function outcome()
    local l = Store:GetPulls("3212")
    return l and l[1] and l[1].outcome or "aucun pull"
end

-- 1. kill : le combat retombe, ENCOUNTER_END suit de peu
pull()
R:FinishSoon("abandon")        -- PLAYER_REGEN_ENABLED
advance(0.4)
R:Finish("kill")               -- ENCOUNTER_END
advance(5)
check("kill (combat retombe avant ENCOUNTER_END)", outcome(), "kill")

-- 2. wipe : idem, mais succès = 0
pull()
R:FinishSoon("abandon")
advance(0.4)
R:Finish("wipe")
advance(5)
check("wipe annoncé par ENCOUNTER_END", outcome(), "wipe")

-- 3. fuite : ENCOUNTER_END n'arrive jamais
pull()
R:FinishSoon("abandon")
advance(5)
check("abandon (aucun ENCOUNTER_END)", outcome(), "abandon")

-- 4. ENCOUNTER_END seul, sans chute de combat préalable
pull()
R:Finish("kill")
advance(5)
check("kill direct", outcome(), "kill")

-- 5. le pull reste ouvert pendant le délai de grâce
pull()
R:FinishSoon("abandon")
advance(0.5)
check("enregistrement encore ouvert pendant la grâce", Store:IsRecording(), true)
advance(5)
check("clos après la grâce", Store:IsRecording(), false)

-- 6. RÉGRESSION : une rencontre qui démarre pendant le délai de grâce.
-- En clé, le combat retombe puis le groupe enchaîne : si le pull précédent est
-- encore ouvert, Begin abandonnait et la rencontre entière était perdue.
NS.db.profile.learn.pulls = {}
R._pendingEncID, R._pendingEncName, R._closing = 3212, "Boss A", nil
R:Begin("test")
for i = 1, 6 do Store:Add(Store.KIND_TIMELINE, 45, nil, nil, NOW + 45) end
R:FinishSoon("abandon")          -- combat retombe
advance(1.0)                     -- toujours dans la grâce
-- le boss suivant démarre : ENCOUNTER_START doit clore puis rouvrir
if Store:IsRecording() then R:Finish("abandon") end
R._pendingEncID, R._pendingEncName = 3213, "Boss B"
R:Begin("ENCOUNTER_START")
check("nouvelle rencontre ouverte pendant la grâce", Store:IsRecording(), true)
for i = 1, 6 do Store:Add(Store.KIND_TIMELINE, 30, nil, nil, NOW + 30) end
R:Finish("kill")
advance(5)
local l = Store:GetPulls("3213")
check("le boss suivant est bien enregistré", l and #l or 0, 1)
check("et son issue est correcte", l and l[1] and l[1].outcome, "kill")

print(ok and "\n>>> TOUS LES CAS PASSENT" or "\n>>> ÉCHEC")
os.exit(ok and 0 or 1)
