-- Banc hors-jeu pour EB:Refresh — anti-rebond et report hors combat.
local NS = { db = { profile = {
  eventBridge = { enabled=true, sounds=true, colors=true, trigger=2, genericFallback=true, forceCVar=false },
  voice = { enabled=true, boost=100, channel="Master" } } } }
function NS.round(x,d) local m=10^(d or 0) return math.floor(x*m+0.5)/m end
function NS.clamp(x,a,b) return math.max(a, math.min(b,x)) end
function NS:SafeNumber(v) return tonumber(v) end
function NS:IsSecret() return false end
local DEBUG = {}
function NS:Debug(...) local t={} for i=1,select("#",...) do t[i]=tostring(select(i,...)) end
  DEBUG[#DEBUG+1]=table.concat(t," ") end
function NS:Print() end
NS.Engine = { AllEncounters=function() return {} end, GetEncounter=function() end }

-- horloge simulée
local NOW, TIMERS = 0, {}
_G.C_Timer = { After = function(d, fn) TIMERS[#TIMERS+1] = { at = NOW + d, fn = fn } end }
local function advance(dt)
  local target = NOW + dt
  while true do
    local nxt, idx
    for i, t in ipairs(TIMERS) do if t.at <= target and (not nxt or t.at < nxt.at) then nxt, idx = t, i end end
    if not nxt then break end
    NOW = nxt.at; table.remove(TIMERS, idx); nxt.fn()
  end
  NOW = target
end
local COMBAT = false
_G.InCombatLockdown = function() return COMBAT end
_G.GetInstanceInfo = function() return "Donjon", "party" end
_G.CreateFrame = function() return { RegisterEvent=function() end, SetScript=function() end } end
_G.wipe = function(t) for k in pairs(t) do t[k]=nil end return t end
_G.C_EncounterEvents = { SetEventSound=function() end, SetEventColor=function() end,
                          HasEventInfo=function() return true end }
_G.CreateColor = function() return {} end
_G.LibStub = function() return { Fetch=function() return nil end } end
_G.GetLocale = function() return "frFR" end
NS.VOICE_PACKS = { { value="frFR" } }; NS.VOICE_DEFAULT_PACK = "frFR"
NS.CurrentVoicePack = function() return "frFR" end
NS.VoiceKey = function(l,i) return l..":"..i end

assert(loadfile("Modules/EventBridge.lua"))("T", NS)
local EB = NS.EventBridge
EB.frame = {}                    -- simule un module initialisé

local applied = {}
EB.Apply = function(self, reason) applied[#applied+1] = reason; return true end

local function reset() applied = {}; EB._scheduled=false; EB._pending=nil; EB._deferred=nil end
local function check(label, cond) print((cond and "  OK    " or "  ÉCHEC ")..label); return cond end
local ok = true

-- 1. anti-rebond : 20 appels rapides -> une seule pose
reset()
for _ = 1, 20 do EB:Refresh("curseur") end
advance(1.0)
ok = check(("anti-rebond : 20 appels -> %d pose(s)"):format(#applied), #applied == 1) and ok

-- 2. report hors combat
reset(); COMBAT = true
EB:Refresh("pack vocal")
advance(1.0)
ok = check(("en combat : %d pose(s) immédiate(s)"):format(#applied), #applied == 0) and ok
ok = check("motif mis de côté pour la sortie de combat", EB._deferred == "pack vocal") and ok

-- 3. rejeu à la fin du combat
COMBAT = false
local r = EB._deferred; EB._deferred = nil
C_Timer.After(0.2, function() EB:Apply(r) end)
advance(0.5)
ok = check(("sortie de combat : %d pose(s)"):format(#applied), #applied == 1) and ok

-- 4. le dernier motif l'emporte
reset()
EB:Refresh("volume"); EB:Refresh("pack vocal"); EB:Refresh("déclencheur")
advance(1.0)
ok = check(("dernier motif retenu : %s"):format(applied[1] or "-"), applied[1] == "déclencheur") and ok

-- 5. module inactif : aucun effet, aucune erreur
reset(); EB.frame = nil
EB:Refresh("x"); advance(1.0)
ok = check("module inactif : silencieux", #applied == 0) and ok

print(ok and "\n>>> TOUS LES CAS PASSENT" or "\n>>> ÉCHEC")
