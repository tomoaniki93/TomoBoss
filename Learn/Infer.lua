---@diagnostic disable: undefined-global
-- TomoBoss — Apprentissage / Inférence.
--
-- Transforme N pulls d'observations brutes en données de rencontre exploitables.
-- Tout est fait avec des statistiques ROBUSTES (médiane, MAD) et non des moyennes :
-- une observation manquée ou un pull raté ne doit pas déplacer le résultat.
--
-- Chaîne de traitement, par capacité :
--   1. regroupement des incantations par nom
--   2. réparation des observations manquées (un intervalle ~ k x médiane -> k intervalles)
--   3. détection de période (cooldown constant, ou série de 2 à 4 valeurs)
--   4. corrélation avec la timeline Blizzard pour récupérer la durée-identité
--   5. résolution du spellID via le Journal des rencontres
--
-- Ce module ne fait AUCUN appel en combat.

local NS = select(2, ...)
local Infer = {}
NS.Learn = NS.Learn or {}
NS.Learn.Infer = Infer

local Store = NS.Learn.Store

local MAX_PERIOD       = 4     -- longueur maximale d'une série cyclique testée
local CORRELATE_WINDOW = 2.0   -- fenêtre (s) entre le déclenchement timeline et le cast observé

--------------------------------------------------------------------------
-- Statistiques robustes.
--------------------------------------------------------------------------
local function median(t)
    local n = #t
    if n == 0 then return nil end
    local s = {}
    for i = 1, n do s[i] = t[i] end
    table.sort(s)
    if n % 2 == 1 then return s[(n + 1) / 2] end
    return (s[n / 2] + s[n / 2 + 1]) / 2
end

-- Écart absolu médian : dispersion insensible aux valeurs aberrantes.
local function mad(t, med)
    local n = #t
    if n == 0 then return nil end
    med = med or median(t)
    local dev = {}
    for i = 1, n do dev[i] = math.abs(t[i] - med) end
    return median(dev)
end

-- Dispersion relative, comparable entre capacités de cooldown différent.
local function spread(t)
    local med = median(t)
    if not med or med == 0 then return 1 end
    return (mad(t, med) or 0) / med
end

--------------------------------------------------------------------------
-- 1. Extraction : incantations groupées par nom, par pull.
--------------------------------------------------------------------------
-- Renvoie { [nom] = { pulls = { {t1,t2,...}, ... }, durs = {...} } }
local function collectCasts(pulls)
    local out = {}
    for pullIdx, p in ipairs(pulls) do
        for _, o in ipairs(p.obs) do
            local t, kind, dur, name = o[1], o[2], o[3], o[4]
            if (kind == Store.KIND_CAST or kind == Store.KIND_CHANNEL) and type(name) == "string" then
                local e = out[name]
                if not e then e = { pulls = {}, durs = {}, kind = kind }; out[name] = e end
                local list = e.pulls[pullIdx]
                if not list then list = {}; e.pulls[pullIdx] = list end
                list[#list + 1] = t
                if dur and dur > 0 then e.durs[#e.durs + 1] = dur end
            end
        end
    end
    -- compacte les trous d'indices de pull (un pull peut ne pas contenir la capacité)
    for _, e in pairs(out) do
        local dense = {}
        for i = 1, #pulls do
            if e.pulls[i] then
                table.sort(e.pulls[i])
                dense[#dense + 1] = e.pulls[i]
            end
        end
        e.pulls = dense
    end
    return out
end

--------------------------------------------------------------------------
-- 2. Détection de période, par repliement de phase.
--------------------------------------------------------------------------
-- Découper les intervalles par « indice modulo p » est tentant mais faux : une
-- seule observation manquée décale tous les indices suivants et détruit la série.
-- On procède donc en deux temps :
--
--   a) estimer la durée du CYCLE complet T (somme d'une série entière), via la
--      médiane des sommes glissantes de p intervalles consécutifs — la médiane
--      encaisse les fenêtres corrompues par une perte ;
--   b) replier tous les instants d'apparition modulo T. Si T est juste, ils se
--      regroupent en p paquets serrés. Une observation manquée ne fait que
--      dégarnir un paquet : elle ne déplace RIEN. C'est ce qui rend la méthode
--      robuste là où l'indexation échoue.
--
-- On retient la plus PETITE période qui passe le seuil : un cooldown fixe de
-- 41,5 s se replie aussi bien sur T = 83 (deux paquets), mais { 41.5 } est la
-- description honnête, pas { 41.5, 41.5 }.

-- Tolérance de regroupement. Elle doit être ABSOLUE en premier lieu : le bruit
-- de mesure (latence, arrondi serveur) vaut quelques dixièmes de seconde quelle
-- que soit la longueur du cycle. Une tolérance purement proportionnelle jugerait
-- un cycle de 9 s dix fois plus sévèrement qu'un cycle de 90 s, et rejetterait
-- à tort le cooldown fixe court au profit d'une fausse série de deux.
local TOL_ABS = 0.60   -- secondes
local TOL_REL = 0.02   -- fraction de T, prend le relais sur les longs cycles

local function tolFor(T) return math.max(TOL_ABS, TOL_REL * T) end

-- Médiane des sommes de p intervalles consécutifs -> estimation du cycle.
local function estimateCycle(perPullDeltas, p)
    local sums = {}
    for _, deltas in ipairs(perPullDeltas) do
        for i = 1, #deltas - p + 1 do
            local s = 0
            for j = i, i + p - 1 do s = s + deltas[j] end
            sums[#sums + 1] = s
        end
    end
    if #sums == 0 then return nil end
    return median(sums), #sums
end

-- Replie les instants modulo T et renvoie p paquets ordonnés, ou nil si le
-- repliement ne tient pas la route.
local function foldPhases(times, T, p)
    if not T or T <= 0 then return nil end
    local ph = {}
    for _, t in ipairs(times) do ph[#ph + 1] = t % T end
    table.sort(ph)
    if #ph < p then return nil end

    -- coupures aux p plus grands écarts CIRCULAIRES
    local gaps = {}
    for i = 1, #ph do
        local nxt = (i == #ph) and (ph[1] + T) or ph[i + 1]
        gaps[#gaps + 1] = { size = nxt - ph[i], after = i }
    end
    table.sort(gaps, function(a, b) return a.size > b.size end)
    if p > #gaps then return nil end

    local cutAfter = {}
    for i = 1, p do cutAfter[gaps[i].after] = true end

    -- construit les paquets en partant juste après une coupure
    local start
    for i = 1, #ph do if cutAfter[i] then start = i % #ph + 1; break end end
    if not start then return nil end

    local clusters, cur = {}, {}
    for k = 0, #ph - 1 do
        local i = ((start - 1 + k) % #ph) + 1
        cur[#cur + 1] = ph[i]
        if cutAfter[i] then clusters[#clusters + 1] = cur; cur = {} end
    end
    if #cur > 0 then clusters[#clusters + 1] = cur end
    if #clusters ~= p then return nil end

    -- centres et dispersion, en SECONDES. Un paquet peut chevaucher 0
    -- (ex. phases 0.1 et T-0.1) : on le déroule avant de calculer la médiane.
    local centers, worst = {}, 0
    for _, c in ipairs(clusters) do
        local span = c[#c] - c[1]
        local vals = c
        if span > T / 2 then
            vals = {}
            for _, v in ipairs(c) do vals[#vals + 1] = (v < T / 2) and (v + T) or v end
        end
        local m = median(vals)
        local d = mad(vals, m) or 0
        if d > worst then worst = d end
        centers[#centers + 1] = m % T
    end
    table.sort(centers)
    return centers, worst
end

-- times : tous les instants d'apparition, tous pulls confondus.
local function detectSeries(perPullDeltas, times, firstSeen)
    local all = {}
    for _, deltas in ipairs(perPullDeltas) do
        for _, d in ipairs(deltas) do all[#all + 1] = d end
    end
    if #all == 0 then return nil end

    local fallback = { period = 1, series = { median(all) }, score = spread(all),
                       dispSec = mad(all) or 0, weak = true }

    for p = 1, MAX_PERIOD do
        local T, nSums = estimateCycle(perPullDeltas, p)
        if T and nSums >= 2 then
            local centers, dispSec = foldPhases(times, T, p)
            if centers and dispSec <= tolFor(T) then
                -- ordonne la série à partir du paquet contenant la première apparition
                local phase0 = firstSeen % T
                local startIdx, bestD = 1, nil
                for i, c in ipairs(centers) do
                    local d = math.min(math.abs(c - phase0), T - math.abs(c - phase0))
                    if not bestD or d < bestD then startIdx, bestD = i, d end
                end
                local series = {}
                for i = 1, p do
                    local a = centers[((startIdx - 1 + i - 1) % p) + 1]
                    local b = centers[((startIdx - 1 + i) % p) + 1]
                    local d = b - a
                    if d <= 0 then d = d + T end
                    series[i] = d
                end
                return { period = p, series = series, cycle = T,
                         dispSec = dispSec, score = dispSec / T, ok = true }
            end
        end
    end
    return fallback
end

--------------------------------------------------------------------------
-- 4. Corrélation avec la timeline Blizzard.
--------------------------------------------------------------------------
-- Pour chaque événement de timeline dont on connaît l'instant de déclenchement,
-- on cherche l'incantation observée la plus proche. Cela lie « durée-identité »
-- (ce que voit BlizzTimeline) à « nom de capacité » (ce que voit le joueur).
local function correlateTimeline(pulls)
    local byName = {}
    for _, p in ipairs(pulls) do
        local casts = {}
        for _, o in ipairs(p.obs) do
            if (o[2] == Store.KIND_CAST or o[2] == Store.KIND_CHANNEL) and type(o[4]) == "string" then
                casts[#casts + 1] = { t = o[1], name = o[4] }
            end
        end
        for _, o in ipairs(p.obs) do
            if o[2] == Store.KIND_TIMELINE and o[5] then
                local fire, idDur = o[5], o[3]
                local bestName, bestDelta
                for _, c in ipairs(casts) do
                    local delta = math.abs(c.t - fire)
                    if delta <= CORRELATE_WINDOW and (not bestDelta or delta < bestDelta) then
                        bestName, bestDelta = c.name, delta
                    end
                end
                if bestName and idDur then
                    byName[bestName] = byName[bestName] or {}
                    table.insert(byName[bestName], idDur)
                end
            end
        end
    end
    local out = {}
    for name, list in pairs(byName) do
        out[name] = { dur = median(list), n = #list }
    end
    return out
end

--------------------------------------------------------------------------
-- Analyse complète d'une rencontre.
--------------------------------------------------------------------------
-- Renvoie une liste triée par firstSeenSec :
--   { name, spellID, icon, castDuration, firstSeenSec, cdSeriesSec,
--     timelineDur, samples, pulls, spread, quality, warn }
function Infer:Analyze(key)
    local pulls = Store:GetPulls(key)
    if not pulls or #pulls == 0 then return nil, "aucun pull enregistré pour " .. tostring(key) end

    local encID = tonumber(key)   -- nil si clé synthétique
    local casts = collectCasts(pulls)
    local tlByName = correlateTimeline(pulls)
    local results = {}

    for name, e in pairs(casts) do
        local firsts, perPullDeltas, allTimes, total, horizon = {}, {}, {}, 0, 0

        for _, times in ipairs(e.pulls) do
            firsts[#firsts + 1] = times[1]
            total = total + #times
            if times[#times] > horizon then horizon = times[#times] end
            for _, t in ipairs(times) do allTimes[#allTimes + 1] = t end
            local d = {}
            for i = 2, #times do d[#d + 1] = times[i] - times[i - 1] end
            if #d > 0 then perPullDeltas[#perPullDeltas + 1] = d end
        end

        local firstSeen = median(firsts) or 0
        local det = detectSeries(perPullDeltas, allTimes, firstSeen)
        local series = {}
        if det then
            for i, v in ipairs(det.series) do series[i] = NS.round(v, 1) end
        end

        local nPulls = #e.pulls
        local disp = det and det.score or 1
        local cycle = det and det.cycle or (series[1] or 0)
        local weak = det and det.weak

        -- La qualité ne dépend pas d'un seuil arbitraire de dispersion : le
        -- repliement a déjà tranché (ok / weak). Ce qui reste à juger, c'est la
        -- quantité de preuves : combien de pulls, et sur quelle durée.
        local quality
        if det and det.ok and nPulls >= 3 then quality = "bon"
        elseif det and det.ok and nPulls >= 2 then quality = "moyen"
        else quality = "faible" end

        local warn
        if #series == 0 then
            warn = "aucun cycle observé (capacité unique ou de phase ?)"
        elseif weak then
            warn = "aucune période stable trouvée — cooldown moyen, à vérifier"
        elseif nPulls < 2 then
            warn = "un seul pull — série non vérifiée"
        elseif cycle > 0 and horizon < 2 * cycle then
            -- garde-fou honnête : sur des pulls plus courts que deux cycles, la
            -- série est une extrapolation, pas une observation.
            warn = string.format("pulls trop courts (%.0fs observées pour un cycle de %.0fs) — série non confirmée",
                horizon, cycle)
            if quality == "bon" then quality = "moyen" end
        end

        local tl = tlByName[name]
        local jr = encID and NS.Learn.Journal:ResolveSpell(encID, name) or nil

        results[#results + 1] = {
            name         = name,
            spellID      = jr and jr.spellID or nil,
            icon         = jr and jr.icon or nil,
            castDuration = NS.round(median(e.durs) or 0, 1),
            firstSeenSec = NS.round(median(firsts) or 0, 1),
            cdSeriesSec  = series,
            timelineDur  = tl and NS.round(tl.dur, 1) or nil,
            samples      = total,
            pulls        = nPulls,
            spread       = disp,
            quality      = quality,
            warn         = warn,
            channel      = e.kind == Store.KIND_CHANNEL,
        }
    end

    table.sort(results, function(a, b) return a.firstSeenSec < b.firstSeenSec end)
    return results
end

--------------------------------------------------------------------------
-- Diagnostic lisible en jeu.
--------------------------------------------------------------------------
local QCOL = { bon = "|cff8bd5ca", ["moyen"] = "|cffe8c07d", ["faible"] = "|cffe06c75" }

function Infer:PrintReport(key)
    local res, err = self:Analyze(key)
    if not res then NS:Print("|cffe06c75" .. tostring(err) .. "|r"); return end

    local nPulls = Store:CountPulls(key)
    NS:Print(string.format("Analyse de |cff8bd5ca%s|r — %d pull(s), %d capacité(s) détectée(s) :",
        tostring(key), nPulls, #res))

    for _, r in ipairs(res) do
        local col = QCOL[r.quality] or "|cffffffff"
        local ser = #r.cdSeriesSec > 0 and table.concat(r.cdSeriesSec, ", ") or "—"
        NS:Print(string.format("  %s%s|r  t=%.1fs  cd={%s}  cast=%.1fs  (%d obs / %d pulls, %s)",
            col, r.name, r.firstSeenSec, ser, r.castDuration, r.samples, r.pulls, r.quality))
        if r.spellID then
            NS:Print(string.format("      spellID %d (Journal)%s", r.spellID,
                r.timelineDur and string.format(", durée timeline %.1fs", r.timelineDur) or ""))
        else
            NS:Print("      |cffe8c07dspellID non résolu|r — le Journal ne connaît pas ce nom")
        end
        if r.warn then NS:Print("      |cffe8c07d! " .. r.warn .. "|r") end
    end

    if Store:IsSynthetic(key) then
        NS:Print("|cffe8c07dClé synthétique|r : reliez-la à un encounterID avec |cff8bd5ca/tmb learn rekey "
            .. key .. " <encounterID>|r pour résoudre les spellID.")
    end
end
