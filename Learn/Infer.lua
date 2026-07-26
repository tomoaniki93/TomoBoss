---@diagnostic disable: undefined-global
-- TomoBoss — Apprentissage / Inférence.
--
-- Transforme N pulls d'observations brutes en données de rencontre exploitables.
-- Tout est fait avec des statistiques ROBUSTES (médiane, MAD) et non des moyennes :
-- une observation manquée ou un pull raté ne doit pas déplacer le résultat.
--
-- Chaîne de traitement, établie sur capture réelle (Emberdawn, 233 s, 92 obs) :
--   1. déduplication des ADD timeline par leur instant de déclenchement `fire` —
--      la capture montrait 70 ADD bruts pour 36 événements réels ;
--   2. appariement ADD <-> incantation : l'instant de l'ADD EST l'instant de
--      DÉBUT de l'incantation (18/18 à ±0,01 s). Ce n'est pas `fire`, qui vaut
--      ADD + durée, c'est-à-dire l'occurrence SUIVANTE ;
--   3. regroupement par durée-identité de la timeline, confirmé par la durée
--      d'incantation mesurée (id-dur 15.5 <-> cast 1,49 s ; 13.0 <-> 2,98 s) ;
--   4. les incantations SANS ADD forment leurs propres groupes — l'intermède
--      canalisé de 16 s d'Emberdawn n'apparaît nulle part dans la timeline ;
--   5. détection de période par repliement de phase.
--
-- L'identité n'est ni un nom (masqué) ni un npcID (UnitGUID est masqué sur les
-- unités hostiles) : c'est la DURÉE.
--
-- Ce module ne fait AUCUN appel en combat.

local NS = select(2, ...)
local Infer = {}
NS.Learn = NS.Learn or {}
NS.Learn.Infer = Infer

local Store = NS.Learn.Store

local MAX_PERIOD  = 4      -- longueur maximale d'une série cyclique testée

-- Fenêtre d'appariement ADD <-> début d'incantation. La capture donne un écart
-- de 0,000 s dans 16 cas sur 18 et 0,010 s dans les deux autres : 0,05 s est
-- large sans être laxiste.
local PAIR_TOL    = 0.05

-- Déduplication. Deux formes de doublon coexistent dans la capture, et les
-- confondre casse tout — dédupliquer sur le seul `fire` faisait s'annuler deux
-- capacités DISTINCTES dont les déclenchements coïncident.
--   (a) doublon de lot : le serveur re-poste le même événement dans la foulée
--       (triplets 30/10/6 émis à 87,78 puis à nouveau à 87,87) ;
--   (b) ré-ADD : même déclenchement, mais `duration` réécrite avec le TEMPS
--       RESTANT au lieu de l'intervalle (15,50 -> 10,64 pour fire=128,77).
--       Le discriminant est la RÉCURRENCE : une durée nominale revient (15,50
--       apparaît 9 fois dans la capture), une réécriture est unique (10,64 une
--       seule fois). Sans ce test, deux capacités distinctes dont les
--       déclenchements coïncident s'annulaient mutuellement.
local BATCH_TOL   = 0.15   -- (a) écart d'instant toléré dans un même lot
local FIRE_TOL    = 0.05   -- (b) coïncidence de déclenchement

-- Regroupement des durées en classes d'identité.
local DUR_BUCKET  = 0.25

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

-- Quantile des écarts absolus au centre.
--
-- La MAD (quantile 0,5) ne convient PAS pour juger si un paquet est serré :
-- elle tolère jusqu'à 50 % de valeurs aberrantes. Or replier sur un cycle qui
-- vaut la MOITIÉ du vrai produit un paquet fait de deux amas, dont le plus
-- petit pèse ~43 % — juste sous le seuil de rupture. La MAD renvoyait alors
-- 0,78 s sur un paquet large de 19,67 s, et le faux cycle était accepté avec
-- la mention « bon ». Un quantile haut voit l'amas ignoré.
local function devQuantile(t, m, q)
    local n = #t
    if n == 0 then return nil end
    local dev = {}
    for i = 1, n do dev[i] = math.abs(t[i] - m) end
    table.sort(dev)
    return dev[math.max(1, math.min(n, math.ceil(q * n)))]
end

-- Fraction des points devant tenir dans la tolérance pour qu'un paquet soit
-- déclaré serré. 0,9 laisse passer le bruit de mesure sans laisser passer un
-- second amas.
local TIGHT_Q = 0.9

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
-- 1. Extraction : occurrences groupées par DURÉE.
--------------------------------------------------------------------------
local function bucket(v) return math.floor(v / DUR_BUCKET + 0.5) * DUR_BUCKET end

-- Déduplique les ADD d'un pull par leur instant de déclenchement.
-- Le PREMIER fait foi : sur un ré-ADD, `duration` ne contient plus l'intervalle
-- mais le temps restant (constaté : 15.50 réécrit en 10.64 pour le même `fire`).
local function dedupAdds(obs)
    -- passe 1 : combien de fois chaque durée nominale apparaît-elle ?
    local seen = {}
    for _, o in ipairs(obs) do
        if o[2] == Store.KIND_TIMELINE and o[3] then
            local b = bucket(o[3])
            seen[b] = (seen[b] or 0) + 1
        end
    end

    local out = {}
    for _, o in ipairs(obs) do
        if o[2] == Store.KIND_TIMELINE and o[3] then
            local t, dur, fire = o[1], o[3], o[6]
            local dup = false
            for _, u in ipairs(out) do
                -- (a) même instant, même durée nominale : re-post du même lot
                if math.abs(u.t - t) <= BATCH_TOL and math.abs(u.dur - dur) <= 0.01 then
                    dup = true; break
                end
                -- (b) durée vue UNE SEULE FOIS, déclenchement coïncidant et valeur
                --     réduite : c'est une réécriture en temps restant, pas une capacité
                if fire and u.fire and math.abs(u.fire - fire) <= FIRE_TOL
                    and dur < u.dur - 0.01 and (seen[bucket(dur)] or 0) <= 1 then
                    dup = true; break
                end
            end
            if not dup then out[#out + 1] = { t = t, dur = dur, fire = fire } end
        end
    end
    return out
end

-- Débuts d'incantation du pull. On enregistre à la FIN (SUCCEEDED) avec la durée
-- mesurée : le début se retrouve donc par soustraction.
local function castStarts(obs)
    local out = {}
    for _, o in ipairs(obs) do
        local k = o[2]
        if k == Store.KIND_CAST or k == Store.KIND_CHANNEL or k == Store.KIND_INSTANT then
            out[#out + 1] = { t = o[1] - (o[3] or 0), dur = o[3] or 0, kind = k, used = false }
        end
    end
    table.sort(out, function(a, b) return a.t < b.t end)
    return out
end

-- Renvoie { [clé] = { pulls = {{t,...},...}, durs = {...}, tlDur = n, kind = n, tl = bool } }
--   clé "tl:<durée>"   : capacité vue par la timeline (identité = durée-identité)
--   clé "cast:<durée>" : capacité vue UNIQUEMENT par le flux d'incantations
local function collectAbilities(pulls)
    local out = {}
    local function slot(key, init)
        local e = out[key]
        if not e then e = init; e.pulls = {}; e.durs = {}; out[key] = e end
        return e
    end

    for pullIdx, p in ipairs(pulls) do
        local adds  = dedupAdds(p.obs)
        local casts = castStarts(p.obs)

        -- a) événements timeline, appariés à leur incantation quand elle existe
        for _, a in ipairs(adds) do
            local key = string.format("tl:%.2f", bucket(a.dur))
            local e = slot(key, { tlDur = bucket(a.dur), tl = true })
            e.pulls[pullIdx] = e.pulls[pullIdx] or {}
            local list = e.pulls[pullIdx]
            list[#list + 1] = a.t
            for _, c in ipairs(casts) do
                if not c.used and math.abs(c.t - a.t) <= PAIR_TOL then
                    c.used = true
                    if c.dur > 0 then e.durs[#e.durs + 1] = c.dur end
                    e.kind = c.kind
                    break
                end
            end
        end

        -- b) incantations orphelines : invisibles pour la timeline, mais bien réelles
        for _, c in ipairs(casts) do
            if not c.used then
                local key = string.format("cast:%.2f", bucket(c.dur))
                local e = slot(key, { tl = false, kind = c.kind })
                e.pulls[pullIdx] = e.pulls[pullIdx] or {}
                local list = e.pulls[pullIdx]
                list[#list + 1] = c.t
                if c.dur > 0 then e.durs[#e.durs + 1] = c.dur end
            end
        end
    end

    -- compacte les indices de pull (une capacité peut manquer d'un pull)
    for _, e in pairs(out) do
        local dense = {}
        for i = 1, #pulls do
            if e.pulls[i] then table.sort(e.pulls[i]); dense[#dense + 1] = e.pulls[i] end
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
        local d = devQuantile(vals, m, TIGHT_Q) or 0
        if Infer._trace and Infer._traceDur == Infer._curDur then
            local sh = {}
            for i = 1, math.min(#c, 8) do sh[i] = string.format("%.1f", c[i]) end
            print(string.format("      [fold] paquet n=%d span=%.2f (T/2=%.2f) median=%.2f mad=%.2f  ph=%s",
                #c, span, T/2, m, d, table.concat(sh, " ")))
        end
        if d > worst then worst = d end
        centers[#centers + 1] = m % T
    end
    table.sort(centers)
    return centers, worst
end

-- times : tous les instants d'apparition, tous pulls confondus.
--
-- Le cycle T candidat et le nombre de positions p restent LIÉS : T est estimé à
-- partir des sommes de p intervalles consécutifs, et validé par un repliement en
-- p paquets. Découpler les deux (essayer chaque T avec chaque p) a été testé et
-- dégrade nettement — une mauvaise combinaison passe le repliement avant la
-- bonne. On garde donc la contrainte, et on retient la plus petite période.
local function detectSeries(perPullDeltas, times, firstSeen)
    local all = {}
    for _, deltas in ipairs(perPullDeltas) do
        for _, d in ipairs(deltas) do all[#all + 1] = d end
    end
    if #all == 0 then return nil end

    for p = 1, MAX_PERIOD do
        local T, nSums = estimateCycle(perPullDeltas, p)
        if T and nSums >= 2 then
            local centers, dispSec = foldPhases(times, T, p)
            if Infer._trace and Infer._traceDur == Infer._curDur then
                print(string.format("    [trace] p=%d T=%.2f centres=%s disp=%s tol=%.2f -> %s",
                    p, T, centers and #centers or 0,
                    dispSec and string.format("%.3f", dispSec) or "-", tolFor(T),
                    (centers and dispSec <= tolFor(T)) and "ACCEPTE" or "rejete"))
            end
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

                -- Canonisation : une série dont toutes les positions sont égales
                -- décrit en réalité un cooldown FIXE. { 41.5, 41.9 } et { 41.5 }
                -- prédisent la même chose ; la seconde forme est la bonne.
                -- Le cas se produit quand des pertes d'observations empêchent
                -- d'estimer le cycle simple et que seul le cycle double se replie.
                if p > 1 then
                    local m, flat = median(series), true
                    for _, v in ipairs(series) do
                        if math.abs(v - m) > tolFor(m) then flat = false; break end
                    end
                    if flat then series = { m }; T = m end
                end

                return { period = #series, series = series, cycle = T,
                         dispSec = dispSec, score = dispSec / T, ok = true }
            end
        end
    end

    -- aucune période stable : on rend la médiane des intervalles, explicitement
    -- marquée « weak » pour que le rapport le signale au lieu de faire illusion.
    return { period = 1, series = { median(all) }, score = spread(all),
             dispSec = mad(all) or 0, weak = true }
end

-- Exposé pour Tools/test_infer.lua : permet de tester la détection isolément.
Infer._detect = detectSeries
Infer._median = median

--------------------------------------------------------------------------
-- Analyse complète d'une rencontre.
--------------------------------------------------------------------------
-- Renvoie une liste triée par firstSeenSec :
--   { name, spellID, icon, castDuration, firstSeenSec, cdSeriesSec,
--     timelineDur, samples, pulls, spread, quality, warn }
function Infer:Analyze(key)
    local pulls, legacy = Store:GetPulls(key)
    if not pulls or #pulls == 0 then
        if legacy and legacy > 0 then
            return nil, string.format(
                "%d capture(s) au schéma v1 ignorée(s) pour %s — elles contenaient les sorts du joueur. "
                .. "Faites /tmb learn prune, puis de nouveaux pulls.", legacy, tostring(key))
        end
        return nil, "aucun pull enregistré pour " .. tostring(key)
    end

    local abilities = collectAbilities(pulls)
    local results = {}

    for akey, e in pairs(abilities) do
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

        -- Ancre de la série. On prend le MINIMUM et non la médiane : une
        -- observation perdue ne peut que faire paraître la première apparition
        -- PLUS TARDIVE, jamais plus précoce. La médiane se laissait entraîner
        -- quand plusieurs pulls rataient la première occurrence, et la série
        -- ressortait juste mais pivotée (ex. {20, 33, 12} au lieu de {12, 20, 33}).
        Infer._curDur = e.tlDur
        if Infer._trace and Infer._traceDur == e.tlDur then
            local ph = {}
            for i = 1, math.min(#allTimes, 12) do ph[i] = string.format("%.1f", allTimes[i]) end
            print("    [trace] instants = " .. table.concat(ph, " "))
        end
        local firstSeen = firsts[1] or 0
        for _, v in ipairs(firsts) do if v < firstSeen then firstSeen = v end end
        local det = detectSeries(perPullDeltas, allTimes, firstSeen)
        local series = {}
        if det then
            for i, v in ipairs(det.series) do series[i] = NS.round(v, 1) end
        end

        local nPulls = #e.pulls
        local cycle  = det and det.cycle or (series[1] or 0)
        local weak   = det and det.weak

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
            warn = string.format("pulls trop courts (%.0fs observées pour un cycle de %.0fs) — série non confirmée",
                horizon, cycle)
            if quality == "bon" then quality = "moyen" end
        end
        if e.tl and #e.durs == 0 then
            warn = (warn and (warn .. " ; ") or "")
                .. "aucune incantation appariée — mécanique sans cast visible (add, zone au sol...)"
        end

        results[#results + 1] = {
            key          = akey,
            timelineDur  = e.tlDur,
            fromTimeline = e.tl,
            castDuration = NS.round(median(e.durs) or 0, 2),
            castSpread   = e.durs[1] and NS.round(mad(e.durs) or 0, 2) or nil,
            firstSeenSec = NS.round(firstSeen, 1),
            cdSeriesSec  = series,
            cycle        = NS.round(cycle, 1),
            samples      = total,
            pulls        = nPulls,
            spread       = det and det.score or 1,
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

    NS:Print(string.format("Analyse de |cff8bd5ca%s|r — %d pull(s), %d capacité(s) :",
        tostring(key), Store:CountPulls(key), #res))

    for _, r in ipairs(res) do
        local col = QCOL[r.quality] or "|cffffffff"
        local ser = #r.cdSeriesSec > 0 and table.concat(r.cdSeriesSec, ", ") or "—"
        local ident = r.fromTimeline
            and string.format("timeline %.2fs", r.timelineDur or 0)
            or  "hors timeline"
        NS:Print(string.format("  %s%s|r  (%s)  t=%.1fs  cd={%s}  cycle=%.1fs",
            col, r.key, ident, r.firstSeenSec, ser, r.cycle))
        if r.castDuration and r.castDuration > 0 then
            NS:Print(string.format("      %s de %.2fs%s  —  %d obs / %d pull(s), %s",
                r.channel and "canalisation" or "incantation", r.castDuration,
                r.castSpread and r.castSpread > 0.05
                    and string.format(" (±%.2f)", r.castSpread) or "",
                r.samples, r.pulls, r.quality))
        else
            NS:Print(string.format("      %d obs / %d pull(s), %s", r.samples, r.pulls, r.quality))
        end
        if r.warn then NS:Print("      |cffe8c07d! " .. r.warn .. "|r") end
    end

    NS:Print("Rôle, sévérité et voix ne sont pas déductibles : à régler à la main.")
end
