-- Banc d'essai des règles de désambiguïsation par PHASE.
--
-- Une règle sequenceGroup suppose que les capacités partageant une durée
-- occupent des positions stables dans un cycle régulier. Cette hypothèse se
-- vérifie sur les captures, pas à l'œil : une régularité constatée sur un pull
-- ne prouve rien sur sept.
--
-- Le banc rejoue la logique exacte de BlizzTimeline — même cycle, même
-- correction de dérive, même bornage — sur les observations réelles, et compte
-- les attributions fausses. Au-delà de quelques pour cent, la règle nuit : le
-- repli générique de l'addon vaut mieux qu'une voix erronée.
--
--   lua5.4 Tools/test_rules.lua <chemin/vers/TomoBoss.lua>
local sv = arg[1] or "/mnt/user-data/uploads/TomoBoss.lua"
assert(loadfile(sv))()
local pulls = TomoBossDB.profile.learn.pulls["2126"]

local CYCLE, DRIFT_GAIN = 22, 0.25
local function phaseDelta(a,b,c) local d=(a-b)%c; if d>c/2 then d=d-c end return d end

local function run(offA, offB)
  local phases = { offA % CYCLE, offB % CYCLE }
  local okAll, total, wrong = true, 0, 0
  for _, pl in ipairs(pulls) do
    -- verite terrain : les entrees de duree 22 alternent A, B, A, B...
    -- la premiere recurrente appartient a la serie A (duree 5 ouvre a 5 s).
    local adds = {}
    for _, o in ipairs(pl.obs or {}) do
      if o[2]==3 and math.abs(o[3]-22)<0.01 then adds[#adds+1]=o[1] end
    end
    table.sort(adds)
    local drift = 0
    for i, t in ipairs(adds) do
      local truth = (i % 2 == 1) and 1 or 2      -- A puis B en alternance
      local ph = (t - drift) % CYCLE
      local bestI, bestD
      for k = 1, 2 do
        local d = math.abs(phaseDelta(ph, phases[k], CYCLE))
        if not bestD or d < bestD then bestI, bestD = k, d end
      end
      total = total + 1
      if bestI ~= truth then wrong = wrong + 1; okAll = false end
      local resid = phaseDelta(ph, phases[bestI], CYCLE)
      local lim = (CYCLE/2)*0.25
      if resid > lim then resid = lim elseif resid < -lim then resid = -lim end
      drift = drift + resid*DRIFT_GAIN
    end
  end
  return total, wrong
end

print(string.format("Galvazzt (2126) — %d pull(s)\n", #pulls))
print("decalages sync -> erreurs d'attribution")
for _, p in ipairs({ {5,20}, {5,21}, {6,21}, {5,22}, {0,11} }) do
  local tot, wrong = run(p[1], p[2])
  print(string.format("   A=%-3d B=%-3d : %d/%d erreurs (%.0f%%)%s",
    p[1], p[2], wrong, tot, wrong/tot*100,
    (p[1]==0 and p[2]==11) and "   <- espacement regulier, sans regle sync" or ""))
end

local _, wrongBest = run(5, 20)
local tot = select(1, run(5, 20))
print(string.format("\nverdict : %.0f %% d'erreurs avec les meilleurs decalages — regle NON livrable.",
  wrongBest / tot * 100))
print("le repli generique de BlizzTimeline reste le bon comportement.")
