-- Banc hors-jeu : désambiguïsation par PHASE contre round-robin.
--
-- Rejoue la capture réelle de la rencontre 3074 (Terrasse des Magistères,
-- groupe 3074_loop_24 : trois capacités partageant une durée de 24 s, offsets
-- 3 / 9 / 15 s). On compare les deux stratégies, d'abord sur le flux intact,
-- puis en supprimant un événement — le cas qui arrive en jeu quand un joueur
-- meurt, rejoint en cours de pull ou qu'une phase saute.
--
-- Lancer : lua5.1 Tools/test_phase.lua

local CYCLE   = 24
local OFFSETS = { [1] = 3, [2] = 9, [3] = 15 }        -- eventID 420 / 290 / 292
local NAMES   = { [1] = "420", [2] = "290", [3] = "292" }

-- instants d'ADD relevés dans la capture (id-dur = 24.00)
local ADDS = { 3.64, 9.72, 15.77, 27.90, 33.96, 40.04, 52.20, 58.25, 64.33,
               76.48, 82.54, 88.62, 100.76, 106.85, 112.96, 125.11, 131.18, 137.25 }

-- vérité terrain : la capacité attendue est celle dont l'offset est le plus
-- proche de la phase réelle, cycle mesuré compris (l'ADD arrive à l'instant du
-- déclenchement, la dérive nominale/réelle est donc incluse dans les instants).
local function truth(i) return ((i - 1) % 3) + 1 end

local function phaseDelta(a, b, c)
    local d = (a - b) % c
    if d > c / 2 then d = d - c end
    return d
end

local function runRoundRobin(adds, skip)
    local n, wrong = 0, 0
    for i, _ in ipairs(adds) do
        if i ~= skip then
            local pick = (n % 3) + 1
            n = n + 1
            if pick ~= truth(i) then wrong = wrong + 1 end
        end
    end
    return wrong
end

local function runPhase(adds, skip)
    local drift, wrong = 0, 0
    local pull = 0
    for i, t in ipairs(adds) do
        if i ~= skip then
            local ph = (t - pull - drift) % CYCLE
            local bestI, bestD
            for k = 1, 3 do
                local d = math.abs(phaseDelta(ph, OFFSETS[k], CYCLE))
                if not bestD or d < bestD then bestI, bestD = k, d end
            end
            if bestI ~= truth(i) then wrong = wrong + 1 end
            local resid = phaseDelta(ph, OFFSETS[bestI], CYCLE)
            local lim = (CYCLE / 3) * 0.25
            if resid > lim then resid = lim elseif resid < -lim then resid = -lim end
            drift = drift + resid * 0.25
        end
    end
    return wrong
end

local total = #ADDS
print(("Capture réelle 3074 — %d événements, 3 capacités à 24 s (offsets 3 / 9 / 15)"):format(total))
print()
print("  scénario                     round-robin      phase")
print("  ---------------------------------------------------------")
local rr, ph = runRoundRobin(ADDS), runPhase(ADDS)
print(("  flux intact                  %2d erreur(s)     %2d erreur(s)"):format(rr, ph))

local worstRR, worstPH = 0, 0
for skip = 1, total do
    local a = runRoundRobin(ADDS, skip)
    local b = runPhase(ADDS, skip)
    if a > worstRR then worstRR = a end
    if b > worstPH then worstPH = b end
end
print(("  1 événement perdu (pire cas) %2d erreur(s)     %2d erreur(s)"):format(worstRR, worstPH))

local sumRR, sumPH = 0, 0
for skip = 1, total do
    sumRR = sumRR + runRoundRobin(ADDS, skip)
    sumPH = sumPH + runPhase(ADDS, skip)
end
print(("  1 événement perdu (moyenne)  %4.1f erreur(s)   %4.1f erreur(s)")
    :format(sumRR / total, sumPH / total))
print()

local ok = (ph == 0) and (worstPH == 0) and (worstRR > 0)
print(ok and ">>> La phase est immunisée aux pertes ; le round-robin ne l'est pas."
         or  ">>> RÉSULTAT INATTENDU")
os.exit(ok and 0 or 1)
