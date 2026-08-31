-- TomoBoss — banc d'essai anti-clignotement.
--
-- Rejoue le scénario réel : le compte à rebours serveur se fige à 0 dès que la
-- capacité part, alors que le recalage n'a lieu que toutes les 0,3 s et que le
-- rendu tourne à 20 Hz. On compte les transitions visible <-> masqué entre
-- l'instant de l'échéance et l'arrivée du REMOVED serveur.
--
-- lua5.4 Tools/test_noblink.lua

local RESYNC_EPS, RESYNC_FLOOR = 0.15, 0.75
local HOLD_AT_NOW, UNPARK_ABOVE = 1.5, 1.0

-- Compte à rebours serveur : décroît, puis se fige à 0 pendant l'incantation.
local function serverRemaining(t, fireAt)
    local r = fireAt - t
    if r < 0 then return 0 end
    return math.floor(r * 10 + 0.5) / 10 -- quantification observée
end

local function run(withFix)
    local fireAt, removedAt = 10.0, 12.4
    local endTime, acc = fireAt, 0
    local parked, visible, flips = nil, nil, 0

    for step = 0, math.floor(removedAt / 0.05) do
        local now = step * 0.05

        -- Producteur : recalage toutes les 0,3 s.
        acc = acc + 0.05
        if acc >= 0.3 - 1e-9 then
            acc = 0
            local tr = serverRemaining(now, fireAt)
            local cur = endTime - now
            if withFix then
                local quiet = (cur <= RESYNC_FLOOR and tr <= RESYNC_FLOOR)
                if not quiet and math.abs(tr - cur) > RESYNC_EPS then endTime = now + tr end
            else
                endTime = now + tr
            end
        end

        -- Rendu.
        local rem, shown = endTime - now, nil
        if withFix then
            if rem <= 0 then parked = parked or now
            elseif parked and rem > UNPARK_ABOVE then parked = nil end
            shown = parked and ((now - parked) <= HOLD_AT_NOW) or (not parked and rem <= 40)
        else
            shown = (rem >= -0.05 and rem <= 40)
        end

        if visible ~= nil and shown ~= visible and now >= fireAt - 0.5 then
            flips = flips + 1
        end
        visible = shown
    end
    return flips
end

local before, after = run(false), run(true)
print(string.format("Avant  : %d transitions visible/masque apres l'echeance", before))
print(string.format("Apres  : %d transition%s", after, after == 1 and "" or "s"))
assert(before >= 4, "le scenario doit reproduire le clignotement")
assert(after <= 1, "la carte ne doit plus clignoter")
print("OK — clignotement reproduit puis supprime.")
