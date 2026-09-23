-- Banc d'essai du métronome : on vérifie les bascules, pas le son.
local played, tickers = 0, {}
_G.PlaySoundFile = function() played = played + 1 return true end
_G.InCombatLockdown = function() return _G.__combat end
_G.IsEncounterInProgress = function() return _G.__enc end
_G.IsInRaid = function() return false end
_G.IsInGroup = function() return _G.__grouped end
_G.UnitExists = function(u) return _G.__grouped and u == "party1" end
_G.GetUnitName = function(u) if u == "party1" then return _G.__name end
                             if u == "player" then return "Moi-Varimathras" end end
_G.UnitName = _G.GetUnitName
_G.GetNumGroupMembers = function() return _G.__grouped and 2 or 0 end
_G.C_Timer = { NewTicker = function(p, fn)
    local t = { period = p, fn = fn, cancelled = false }
    t.Cancel = function(self) self.cancelled = true end
    tickers[#tickers+1] = t; return t
end }
_G.CreateFrame = function()
    local f = {}
    f.RegisterEvent = function() end
    f.SetScript = function(_, _, fn) f._on = fn end
    return f
end
_G.GetTime = function() return _G.__now or 0 end
local NS = { db = { profile = { metronome = {
    enabled = true, interval = 10, sound = "Top",
    names = { ["Taluani-Varimathras"] = true } } } } }
function NS:SafeString(v) return type(v)=="string" and v or nil end
function NS:IsSecret() return false end
function NS:Print(m) print("   [print] "..m) end
assert(loadfile("Modules/Metronome.lua"))("TomoBoss", NS)
local M, fire = NS.Metronome, nil
fire = function(e) M._frame._on(nil, e) end

local function state() return (M._ticker ~= nil and not M._ticker.cancelled) end
local fails = 0
local function check(lbl, got, want)
  if got == want then print(string.format("  %-52s OK", lbl))
  else fails = fails + 1; print(string.format("  %-52s ECHEC (%s)", lbl, tostring(got))) end
end

print("\n=== bascules ===")
_G.__grouped, _G.__name, _G.__combat, _G.__enc = true, "Taluani-Varimathras", false, false
fire("GROUP_ROSTER_UPDATE")
check("groupe ok mais hors combat -> silence", state(), false)

_G.__combat = true; fire("PLAYER_REGEN_DISABLED")
check("combat + joueur present -> battement", state(), true)
check("premier battement immediat", played >= 1, true)
check("periode de 10 s", M._ticker.period, 10)

fire("ENCOUNTER_START")
check("debut de boss -> arret", state(), false)
fire("ENCOUNTER_END")
check("fin de boss -> reprise", state(), true)

_G.__enc = true; M._encounter = false; M:Update()
check("IsEncounterInProgress seul suffit a arreter", state(), false)
_G.__enc = false; M:Update()

_G.__name = "Quelquun-Autre"; fire("GROUP_ROSTER_UPDATE")
check("joueur absent -> arret", state(), false)
_G.__name = "Taluani-Varimathras"; fire("GROUP_ROSTER_UPDATE")
check("retour du joueur -> reprise", state(), true)

_G.__name = "taluani"; fire("GROUP_ROSTER_UPDATE")
check("nom court, meme royaume, casse differente", state(), true)

_G.__combat = false; fire("PLAYER_REGEN_ENABLED")
check("fin de combat -> arret", state(), false)

NS.db.profile.metronome.enabled = false
_G.__combat = true; fire("PLAYER_REGEN_DISABLED")
check("desactive -> silence", state(), false)

print("")
if fails > 0 then error(fails.." echec(s)", 0) end
print("OK — toutes les bascules sont correctes.")
