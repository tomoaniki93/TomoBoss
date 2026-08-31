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
-- LIMITE CONNUE — cooldowns MIS EN PAUSE par les phases.
--
-- Le désalignement entre pulls est traité : le repliement se fait pull par pull
-- quand le repliement groupé échoue (voir detectSeries).
--
-- Ce qui reste ouvert est différent, et ma première analyse s'était trompée de
-- cause. Sur Emberdawn, les écarts d'une même capacité valent 36,4 / 15,8 /
-- 36,4 / 18,2 / 31,6… Ce n'est pas une série cyclique bruitée : le cooldown vaut
-- ~15,8 s et il est SUSPENDU pendant l'intermède canalisé de 16 s. Les écarts
-- longs sont donc « cooldown + durée de pause », et la pause varie.
--
-- Aucun repliement, groupé ou non, ne peut décrire cela : le modèle « série
-- cyclique » est le mauvais modèle. Il faudrait détecter les intervalles de
-- pause (les intermèdes sont déjà identifiés comme capacités) et les retrancher
-- avant de mesurer le cycle.
--
-- En attendant, ces rencontres retombent sur la médiane, dûment signalée
-- « aucune période stable trouvée » — déclarer l'incertitude plutôt que
-- l'affirmer.
--
-- Ce module ne fait AUCUN appel en combat.

local NS = select(2, ...)
local Infer = {}
NS.Learn = NS.Learn or {}
NS.Learn.Infer = Infer

local Store = NS.Learn.Store

-- Longueur maximale d'une série cyclique testée. Portée de 4 à 8 sur corpus
-- réel : à l'Académie (2562), les 15 instantanés d'un boss suivent une série de
-- CINQ valeurs — { 8.5, 9.5, 8.5, 7.5, 10.0 }, dont la somme fait exactement la
-- boucle de 44 s. Plafonner à 4 rendait ce motif inexprimable et le faisait
-- retomber sur un cooldown moyen de 8,5 s, faux une fois sur deux.
local MAX_PERIOD  = 8

-- MARQUEUR : événement dont la « durée » sert d'identifiant et non de compte à
-- rebours. Le `fire` annoncé tombe alors hors du combat et n'est pas un
-- minutage exploitable ; c'est l'instant de l'ADD qui l'est.
--
-- Ces événements ne sont PAS à jeter : sur 3058, les durées 999 et 1004
-- s'apparient à une incantation à chaque fois (3,0 s et 5,0 s) et reviennent
-- toutes les ~66 s. Ce sont de vraies capacités.
--
-- Le critère est OBSERVÉ, pas supposé. Un seuil fixe (300 s) manquait les
-- marqueurs à 102 et 104 s vus au Siège du Triumvirat et à la Terrasse, et
-- aurait un jour rejeté un vrai minuteur long. On regarde donc si le `fire`
-- retombe réellement dans le combat : sur le corpus, 8 groupes sur 129 ne le
-- font jamais, et ce sont exactement les marqueurs.
--
-- Le seuil ne subsiste que comme garde-fou pour un groupe vu une seule fois,
-- où l'observation ne peut pas trancher.
local SENTINEL_DUR = 300

-- Observations minimales par position de série, contre le surajustement.
local MIN_PER_CLUSTER = 2

-- Écart de durée d'incantation au-delà duquel deux positions d'une même série
-- sont considérées comme deux capacités distinctes. Corpus : 0,02 s pour une
-- capacité unique, 3,52 s pour six capacités confondues.
local SPLIT_CAST_TOL = 0.50

-- Une capacité dont l'écart entre deux occurrences dépasse à peine sa propre
-- durée d'incantation n'a pas de cooldown : le boss la RÉENCHAÎNE en continu.
-- Relevé sur 3101 — une incantation de 3,00 s revenant toutes les 3,65 s, soit
-- 0,65 s de pause. L'annoncer à chaque fois serait intenable en jeu ; il faut
-- pouvoir la distinguer d'un vrai cooldown court avant de lui donner une voix.
local CHAINED_RATIO = 1.5

-- Fenêtre d'appariement ADD <-> début d'incantation.
--
-- Elle valait 0,05 s, calibrée sur Emberdawn où la coïncidence est exacte
-- (0,000 s dans 16 cas sur 18). D'autres rencontres décalent le début de
-- l'incantation de plus d'un demi-seconde après l'ADD — relevé jusqu'à 0,61 s
-- sur Maisara. Une fenêtre trop serrée laissait ces positions sans durée
-- mesurée et empêchait toute analyse d'identité.
--
-- Élargir impose de choisir le cast le PLUS PROCHE et non le premier venu,
-- sans quoi une fenêtre large apparie n'importe quoi.
local PAIR_TOL    = 0.75

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
-- Durée nulle : l'événement se déclenche à l'instant même où il est posté
-- (fire == t, relevé sur 3058 — trois exemplaires au même instant). Ce n'est
-- pas une annonce mais un signal de déclenchement immédiat, sans identité de
-- durée exploitable. On l'écarte de l'analyse de cycle.
local ZERO_DUR = 0.01

-- Repère les durées dont AUCUNE occurrence ne retombe dans le combat.
local function markerDurations(obs)
    local last = 0
    for _, o in ipairs(obs) do
        if o[1] and o[1] > last then last = o[1] end
    end
    local seen, inside = {}, {}
    for _, o in ipairs(obs) do
        if o[2] == Store.KIND_TIMELINE and o[3] and o[3] > ZERO_DUR then
            local b = bucket(o[3])
            seen[b] = (seen[b] or 0) + 1
            if o[6] and o[6] <= last then inside[b] = true end
        end
    end
    local out = {}
    for b, n in pairs(seen) do
        -- observé sur au moins deux occurrences, aucune ne retombant dans le
        -- combat ; ou vu une seule fois avec une durée hors de toute échelle
        if (n >= 2 and not inside[b]) or (n < 2 and b >= SENTINEL_DUR) then
            out[b] = true
        end
    end
    return out
end

local function dedupAdds(obs)
    -- passe 1 : combien de fois chaque durée nominale apparaît-elle ?
    local seen = {}
    local markers = markerDurations(obs)
    for _, o in ipairs(obs) do
        if o[2] == Store.KIND_TIMELINE and o[3] and o[3] > ZERO_DUR then
            local b = bucket(o[3])
            seen[b] = (seen[b] or 0) + 1
        end
    end

    local out = {}
    for _, o in ipairs(obs) do
        if o[2] == Store.KIND_TIMELINE and o[3] and o[3] > ZERO_DUR then
            local t, dur, fire = o[1], o[3], o[6]
            local isMarker = markers[bucket(dur)]
            -- marqueur : la durée identifie, elle ne décompte pas
            if isMarker then fire = nil end
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
            if not dup then
                out[#out + 1] = { t = t, dur = dur, fire = fire,
                                  marker = isMarker or nil }
            end
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
            out[#out + 1] = { t = o[1] - (o[3] or 0), dur = o[3] or 0, kind = k,
                              unit = o[5], used = false }
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

        -- a) événements timeline, appariés à leur incantation quand elle existe.
        --
        -- L'occurrence retenue est l'instant où la MÉCANIQUE TOMBE, pas celui où
        -- le serveur poste l'événement :
        --   * incantation appariée -> fin de l'incantation (t_ADD + durée mesurée),
        --     c'est le moment où l'effet part ;
        --   * sinon -> `fire`, l'instant que le serveur annonce et vers lequel la
        --     barre décompte déjà.
        -- Sans ça, les capacités amorcées par le lot initial se voyaient attribuer
        -- firstSeenSec = 0, alors que rien ne tombe au pull : la mécanique arrive
        -- à `fire`.
        for _, a in ipairs(adds) do
            local key = string.format("tl:%.2f", bucket(a.dur))
            local e = slot(key, { tlDur = bucket(a.dur), tl = true,
                                  marker = a.marker })
            e.pulls[pullIdx] = e.pulls[pullIdx] or {}
            local list = e.pulls[pullIdx]

            local landed, cdur
            local pick, pickD
            for _, c in ipairs(casts) do
                if not c.used then
                    local d = math.abs(c.t - a.t)
                    if d <= PAIR_TOL and (not pickD or d < pickD) then pick, pickD = c, d end
                end
            end
            if pick then
                pick.used = true
                if pick.dur > 0 then e.durs[#e.durs + 1] = pick.dur end
                e.kind = pick.kind
                cdur = pick.dur
                landed = a.t + pick.dur          -- fin d'incantation
            end
            -- la durée d'incantation est conservée AVEC l'occurrence : c'est
            -- elle qui permettra de distinguer « une capacité qui revient N
            -- fois » de « N capacités partageant une durée-identité ».
            -- pour un marqueur, ni `fire` ni `t + dur` n'ont de sens :
            -- l'instant de l'ADD est le seul ancrage valable
            local anchor = landed or a.fire or (a.marker and a.t) or (a.t + a.dur)
            list[#list + 1] = { t = anchor, dur = cdur,
                                seed = a.t <= 0.5 and a.fire or nil }
        end

        -- b) incantations orphelines : invisibles pour la timeline, mais bien réelles
        for _, c in ipairs(casts) do
            if not c.used then
                -- Une incantation instantanée a une durée de 0 : elle ne porte
                -- AUCUNE identité. Sans distinction supplémentaire, tous les
                -- instantanés d'une rencontre s'agglutinent en un seul groupe
                -- (relevé : 29 instantanés de cinq membres d'un conseil fondus
                -- ensemble). Le jeton d'unité les sépare.
                local key
                if c.dur <= 0.01 then
                    key = "instant:" .. (c.unit or "?")
                else
                    key = string.format("cast:%.2f", bucket(c.dur))
                end
                local e = slot(key, { tl = false, kind = c.kind, unit = c.unit })
                e.pulls[pullIdx] = e.pulls[pullIdx] or {}
                local list = e.pulls[pullIdx]
                -- même principe : on retient la FIN de l'incantation
                list[#list + 1] = { t = c.t + c.dur, dur = c.dur }
                if c.dur > 0 then e.durs[#e.durs + 1] = c.dur end
            end
        end
    end

    -- compacte les indices de pull (une capacité peut manquer d'un pull)
    for _, e in pairs(out) do
        local dense = {}
        for i = 1, #pulls do
            if e.pulls[i] then
                table.sort(e.pulls[i], function(x, y) return x.t < y.t end)
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

-- Vérification par REJEU (voir replayFit).
local REPLAY_TOL     = 0.90 -- tolérance d'appariement d'un écart observé (s)
local FIT_GOOD       = 0.90 -- au-dessus : la série décrit bien les observations
local FIT_WEAK       = 0.75 -- en dessous : les données contredisent la série
local FIT_MIN_DELTAS = 6    -- sous ce nombre d'écarts, le rejeu ne conclut rien

-- Preuve minimale exigée pour un label de qualité.
--
-- Le nombre de PULLS est un mauvais indicateur de preuve. Mesuré sur 255 pulls
-- réels : longueur médiane 91 s. Une capacité à 60 s de cooldown n'y produit
-- qu'UN intervalle par pull, donc « 4 pulls » peut ne représenter que 4
-- intervalles. Résultat avant ce garde-fou : 81 des 129 capacités classées
-- « bon » reposaient sur moins de 6 intervalles, et le rejeu s'abstenait
-- justement là, faute de matière — l'absence de contradiction était prise pour
-- une confirmation.
--
-- On compte donc les INTERVALLES OBSERVÉS, seule quantité qui mesure vraiment
-- ce que les données peuvent démontrer.
local MIN_INTERVALS_GOOD   = 8
local MIN_INTERVALS_MEDIUM = 4

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

-- Écart circulaire signé entre deux phases.
local function phaseDelta(a, b, cycle)
    local d = (a - b) % cycle
    if d > cycle / 2 then d = d - cycle end
    return d
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

    -- Garde-fou de SURAJUSTEMENT. Chaque position de la série est un paramètre
    -- libre : sans preuve suffisante par position, une longue série « explique »
    -- n'importe quel bruit. Relevé sur Emberdawn — 9 occurrences repliées en 6
    -- positions sur 3 cycles donnaient 1,5 point par paquet et une série à six
    -- valeurs, là où { 35.2, 15.8 } sur un seul cycle décrit la même chose.
    -- Exiger 2 observations par position élimine ces descriptions creuses.
    for _, c in ipairs(clusters) do
        if #c < MIN_PER_CLUSTER then return nil end
    end

    -- Centres et dispersion, en SECONDES.
    --
    -- Un paquet est un ARC circulaire et il est construit dans l'ordre du
    -- parcours, pas trié : `c[#c] - c[1]` pouvait donc être négatif, le test de
    -- chevauchement ne se déclenchait pas, et un groupe parfaitement régulier
    -- était rejeté. Cas relevé sur corpus réel : des instants à 0 / 44,00 /
    -- 88,02 avec un cycle estimé à 44,01 — la phase 44,00 ne se replie pas sur
    -- 0 puisqu'elle lui est inférieure.
    --
    -- On déroule donc chaque valeur PAR RAPPORT AU PREMIER élément de l'arc.
    -- C'est exact par construction et sans heuristique de demi-cycle.
    local centers, worst = {}, 0
    for _, c in ipairs(clusters) do
        local base = c[1]
        local vals = {}
        for i, v in ipairs(c) do vals[i] = base + ((v - base) % T) end
        local m = median(vals)
        local d = devQuantile(vals, m, TIGHT_Q) or 0
        if Infer._trace and Infer._traceDur == Infer._curDur then
            -- `span` était un reliquat du calcul `c[#c] - c[1]` supprimé ci-dessus :
            -- la variable n'existait plus et la trace plantait sur string.format.
            -- L'étendue utile est désormais celle des valeurs DÉROULÉES.
            local lo, hi = vals[1], vals[1]
            for i = 2, #vals do
                if vals[i] < lo then lo = vals[i] end
                if vals[i] > hi then hi = vals[i] end
            end
            local sh = {}
            for i = 1, math.min(#c, 8) do sh[i] = string.format("%.1f", c[i]) end
            print(string.format("      [fold] paquet n=%d span=%.2f (T/2=%.2f) median=%.2f mad=%.2f  ph=%s",
                #c, (hi - lo), T/2, m, d, table.concat(sh, " ")))
        end
        if d > worst then worst = d end
        centers[#centers + 1] = m % T
    end
    table.sort(centers)
    return centers, worst
end

-- Construit la série cyclique depuis les centres de paquets, en démarrant au
-- paquet le plus proche de l'ancre.
local function seriesFromCenters(centers, T, anchor)
    local p = #centers
    local phase0 = anchor % T
    local startIdx, bestD = 1, nil
    for i, c in ipairs(centers) do
        local d = math.min(math.abs(c - phase0), T - math.abs(c - phase0))
        if not bestD or d < bestD then startIdx, bestD = i, d end
    end
    local series = {}
    for i = 1, p do
        local x = centers[((startIdx - 1 + i - 1) % p) + 1]
        local y = centers[((startIdx - 1 + i) % p) + 1]
        local d = y - x
        if d <= 0 then d = d + T end
        series[i] = d
    end
    return series
end

-- Canonisation puis emballage, commun aux deux stratégies de repliement.
local function finish(series, T, dispSec, centers, folded)
    if #series > 1 then
        -- toutes les positions égales -> cooldown fixe
        local m, flat = median(series), true
        for _, v in ipairs(series) do
            if math.abs(v - m) > tolFor(m) then flat = false; break end
        end
        if flat then
            series, T = { m }, m
        else
            -- répétition entière d'un préfixe -> ce préfixe
            for q = 1, math.floor(#series / 2) do
                if #series % q == 0 then
                    local ok = true
                    for i = q + 1, #series do
                        local ref = series[((i - 1) % q) + 1]
                        if math.abs(series[i] - ref) > tolFor(ref) then ok = false; break end
                    end
                    if ok then
                        local short, sum = {}, 0
                        for i = 1, q do short[i] = series[i]; sum = sum + series[i] end
                        series, T = short, sum
                        break
                    end
                end
            end
        end
    end
    return { period = #series, series = series, cycle = T, centers = centers,
             dispSec = dispSec, pullsFolded = folded,
             score = dispSec / T, ok = true }
end

-- perPullTimes : instants d'apparition SÉPARÉS PAR PULL.
--
-- Deux stratégies, dans cet ordre :
--
--   1. repliement GROUPÉ, tous pulls confondus. Quand les phases s'alignent
--      d'un pull à l'autre — boss à cycle régulier — c'est le plus solide :
--      toutes les observations appuient les mêmes paquets.
--
--   2. repliement PULL PAR PULL, puis combinaison des séries. Un intermède de
--      durée variable décale la suite du combat, et les phases absolues ne
--      coïncident plus (relevé sur Emberdawn : 7,6 s dans un pull, 13,3 s dans
--      un autre). Une SÉRIE, elle, est invariante par décalage — c'est une
--      suite d'intervalles, pas de positions. On replie donc chaque pull
--      séparément et on combine position par position.
--
-- Sans la seconde, accumuler des pulls sur ces rencontres n'apportait rien.
local function detectSeries(perPullDeltas, perPullTimes, firstSeen)
    local all = {}
    for _, deltas in ipairs(perPullDeltas) do
        for _, d in ipairs(deltas) do all[#all + 1] = d end
    end
    if #all == 0 then return nil end

    local pooled = {}
    for _, times in ipairs(perPullTimes) do
        for _, t in ipairs(times) do pooled[#pooled + 1] = t end
    end

    for p = 1, MAX_PERIOD do
        local T, nSums = estimateCycle(perPullDeltas, p)
        if T and nSums >= 2 then
            -- 1. groupé
            if #pooled >= p * MIN_PER_CLUSTER then
                local c, disp = foldPhases(pooled, T, p)
                if c and disp <= tolFor(T) then
                    return finish(seriesFromCenters(c, T, firstSeen), T, disp, c, #perPullTimes)
                end
            end

            -- 2. pull par pull
            local list, worst, used, ref = {}, 0, 0, nil
            for _, times in ipairs(perPullTimes) do
                if #times >= p * MIN_PER_CLUSTER then
                    local c, disp = foldPhases(times, T, p)
                    if c and disp <= tolFor(T) then
                        list[#list + 1] = seriesFromCenters(c, T, times[1])
                        ref = ref or c
                        if disp > worst then worst = disp end
                        used = used + 1
                    end
                end
            end
            if used > 0 then
                local series = {}
                for i = 1, p do
                    local col = {}
                    for _, sr in ipairs(list) do
                        if sr[i] then col[#col + 1] = sr[i] end
                    end
                    series[i] = median(col)
                end
                return finish(series, T, worst, ref, used)
            end
        end
    end

    return { period = 1, series = { median(all) }, score = spread(all),
             dispSec = mad(all) or 0, weak = true }
end

-- Exposé pour Tools/test_infer.lua : permet de tester la détection isolément.
Infer._detect = detectSeries
Infer._median = median

-- Fidélité de la série aux observations, par REJEU.
--
-- Le repliement peut produire des paquets parfaitement SERRÉS sur un cycle
-- FAUX : il suffit que les rares instants survivants tombent en coïncidence.
-- Relevé sur le banc « échec sûr » (45 % de pertes) : {32.7, 44.4, 20.4}
-- annoncé en qualité « bon » sans avertissement là où la vérité est
-- {12, 20, 33}. Aucune mesure de dispersion ne peut voir ça — les paquets SONT
-- serrés ; c'est le cycle qui est faux.
--
-- On teste donc la série contre les données plutôt que contre elle-même. Un
-- écart observé doit être une somme d'entrées CONSÉCUTIVES de la série (une
-- somme de plusieurs entrées = des occurrences manquées, ce qui est normal
-- sous perte), et les positions doivent s'enchaîner. Un écart qu'aucune somme
-- n'explique est orphelin : la série est contredite.
--
-- Le test est local à chaque écart, donc insensible à la dérive cumulée, et
-- indépendant de la façon dont la série a été construite.
local function replayFit(series, cycle, perPullTimes)
    if type(series) ~= "table" or #series == 0 then return nil, 0 end
    local p = #series
    for _, v in ipairs(series) do
        if type(v) ~= "number" or v <= 0 then return nil, 0 end
    end
    local maxRun = math.min(math.max(2 * p, 6), 12)
    local total, explained = 0, 0

    for _, times in ipairs(perPullTimes or {}) do
        if #times >= 2 then
            local best = -1
            -- La première observation d'un pull peut occuper n'importe quelle
            -- position du cycle : on essaie les p départs et on garde le meilleur.
            for off = 0, p - 1 do
                local pos, hit = off, 0
                for a = 2, #times do
                    local delta = times[a] - times[a - 1]
                    local acc, found = 0, nil
                    for k = 1, maxRun do
                        acc = acc + series[((pos + k - 1) % p) + 1]
                        local tol = math.max(REPLAY_TOL, TOL_REL * acc)
                        if math.abs(acc - delta) <= tol then found = k; break end
                        if acc - delta > tol then break end
                    end
                    if found then
                        hit = hit + 1
                        pos = (pos + found) % p
                    end
                    -- Écart orphelin : on ne propage pas l'erreur de phase, la
                    -- position courante reste celle du dernier appariement.
                end
                if hit > best then best = hit end
            end
            total = total + (#times - 1)
            explained = explained + math.max(best, 0)
        end
    end

    if total < 1 then return nil, 0 end
    return explained / total, total
end

-- Accès au rejeu pour le banc d'essai (Tools/test_fit.lua). Aucun appel en jeu.
function Infer._testReplayFit(series, cycle, perPullTimes)
    return (replayFit(series, cycle, perPullTimes))
end

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

        local allOcc = {}
        for _, occ in ipairs(e.pulls) do
            firsts[#firsts + 1] = occ[1].t
            total = total + #occ
            if occ[#occ].t > horizon then horizon = occ[#occ].t end
            for _, o in ipairs(occ) do
                allTimes[#allTimes + 1] = o.t
                allOcc[#allOcc + 1] = o
            end
            local d = {}
            for i = 2, #occ do d[#d + 1] = occ[i].t - occ[i - 1].t end
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
        -- instants séparés par pull : le repliement groupé échoue dès qu'un
        -- intermède décale les phases d'un pull à l'autre.
        local perPullTimes = {}
        for _, occ in ipairs(e.pulls) do
            local ts = {}
            for _, o in ipairs(occ) do ts[#ts + 1] = o.t end
            perPullTimes[#perPullTimes + 1] = ts
        end
        local det = detectSeries(perPullDeltas, perPullTimes, firstSeen)
        local series = {}
        if det then
            for i, v in ipairs(det.series) do series[i] = NS.round(v, 1) end
        end

        local nPulls = #e.pulls
        local cycle  = det and det.cycle or (series[1] or 0)
        local weak   = det and det.weak

        -- `fitN` est le nombre d'intervalles réellement exploitables : c'est à
        -- la fois la matière du rejeu et la mesure de la preuve disponible.
        local fit, fitN = replayFit(series, cycle, perPullTimes)

        local quality
        if det and det.ok and nPulls >= 3 and fitN >= MIN_INTERVALS_GOOD then
            quality = "bon"
        elseif det and det.ok and nPulls >= 2 and fitN >= MIN_INTERVALS_MEDIUM then
            quality = "moyen"
        else
            quality = "faible"
        end

        -- Le rejeu a ensuite le DERNIER MOT : une série que les écarts observés
        -- contredisent ne peut pas sortir en « bon », quel que soit le nombre
        -- de pulls qui l'ont produite.
        if fit and fitN >= FIT_MIN_DELTAS then
            if fit < FIT_WEAK then quality = "faible"
            elseif fit < FIT_GOOD and quality == "bon" then quality = "moyen" end
        end

        -- incantation enchaînée : le cycle n'excède guère la durée du sort
        local castMed = median(e.durs)
        local chained = false
        if castMed and castMed > 0 and cycle > 0 and total >= 4 then
            chained = cycle < castMed * CHAINED_RATIO
        end

        local warn
        if chained then
            warn = string.format(
                "incantation ENCHAÎNÉE — %.2fs de sort pour %.2fs de cycle, soit %.2fs de pause. "
                .. "Le boss la relance en continu : à ne pas annoncer à chaque fois.",
                castMed, cycle, cycle - castMed)
        elseif #series == 0 then
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
        if fitN < MIN_INTERVALS_MEDIUM then
            warn = (warn and (warn .. " ; ") or "")
                .. string.format("preuve insuffisante : %d intervalle(s) observé(s) — pulls trop courts pour ce cooldown", fitN)
        end
        if fit and fitN >= FIT_MIN_DELTAS and fit < FIT_GOOD then
            warn = (warn and (warn .. " ; ") or "")
                .. string.format("série contredite par %.0f %% des écarts observés (rejeu %d/%d)",
                    (1 - fit) * 100, math.floor(fit * fitN + 0.5), fitN)
        end
        if e.tl and #e.durs == 0 then
            warn = (warn and (warn .. " ; ") or "")
                .. "aucune incantation appariée — mécanique sans cast visible (add, zone au sol...)"
        end

        -- ── Une capacité, ou plusieurs partageant une durée-identité ? ──
        --
        -- Relevé sur capture réelle (Maisara, rencontre 3212) : dix-huit
        -- événements de durée 45 s correspondent en fait à SIX capacités
        -- distinctes, chacune revenant toutes les 45 s à sa propre phase
        -- (5, 12, 20, 28, 35 et 41 s). Les modéliser comme une seule capacité
        -- à six positions décrit correctement le MINUTAGE mais fausse
        -- l'identité — et c'est l'identité qui porte le rôle, la sévérité et
        -- la voix.
        --
        -- Le discriminant est la DURÉE D'INCANTATION par position : six sorts
        -- différents ont six durées différentes. Mesuré sur le corpus, la
        -- séparation est nette — 3,52 s d'étendue pour 3212 contre 0,02 s
        -- partout où il s'agit réellement d'une capacité unique.
        local split
        if det and det.ok and det.centers and #det.centers > 1 then
            local byPos, firstAt = {}, {}
            for i = 1, #det.centers do byPos[i] = {} end
            for _, o in ipairs(allOcc) do
                local ph, best, bestD = o.t % det.cycle, 1, nil
                for i, cpos in ipairs(det.centers) do
                    local d = math.abs(phaseDelta(ph, cpos, det.cycle))
                    if not bestD or d < bestD then best, bestD = i, d end
                end
                if o.dur and o.dur > 0 then table.insert(byPos[best], o.dur) end
                -- première retombée RÉELLE de ce membre : le centre de phase ne
                -- convient pas, il peut franchir la fin du cycle et rendre 0,5 s
                -- pour une capacité qui tombe en réalité à 45,5 s.
                if not firstAt[best] or o.t < firstAt[best] then firstAt[best] = o.t end
            end
            -- Il suffit que DEUX positions soient documentées pour trancher :
            -- exiger que toutes le soient rendait la règle inapplicable dès
            -- qu'une seule incantation n'avait pas été appariée.
            local meds, known = {}, 0
            local lo, hi
            for i = 1, #det.centers do
                if #byPos[i] > 0 then
                    meds[i] = median(byPos[i])
                    known = known + 1
                    if not lo or meds[i] < lo then lo = meds[i] end
                    if not hi or meds[i] > hi then hi = meds[i] end
                end
            end
            if known >= 2 and (hi - lo) > SPLIT_CAST_TOL then
                -- positions sans mesure : on leur laisse la médiane globale
                local fallback = median(e.durs) or 0
                for i = 1, #det.centers do meds[i] = meds[i] or fallback end
                split = { centers = det.centers, meds = meds, firstAt = firstAt }
            end
        end

        if split then
            for i, cpos in ipairs(split.centers) do
                results[#results + 1] = {
                    key          = string.format("%s#%d", akey, i),
                    timelineDur  = e.tlDur,
                    fromTimeline = e.tl,
                    castDuration = NS.round(split.meds[i], 2),
                    firstSeenSec = NS.round(split.firstAt[i] or cpos, 1),
                    cdSeriesSec  = { NS.round(det.cycle, 1) },
                    cycle        = NS.round(det.cycle, 1),
                    samples      = total,
                    pulls        = nPulls,
                    spread       = det.score,
                    fit          = fit and NS.round(fit, 3) or nil,
            intervals    = fitN,
                    intervals    = fitN,
                    quality      = quality,
                    warn         = warn,
                    channel      = e.kind == Store.KIND_CHANNEL,
                    splitOf      = akey,
                    -- instant de DÉBUT d'incantation : c'est lui que le lot
                    -- d'amorçage annonce, et donc lui qui sert à repérer les
                    -- doublons de première occurrence.
                    offset       = NS.round((split.firstAt[i] or cpos) - (split.meds[i] or 0), 1),
                }
            end
        else
        -- (pas de goto en Lua 5.1 : le cas non découpé est le bloc else)
        results[#results + 1] = {
            key          = akey,
            timelineDur  = e.tlDur,
            fromTimeline = e.tl,
            marker       = e.marker,
            castDuration = NS.round(median(e.durs) or 0, 2),
            castSpread   = e.durs[1] and NS.round(mad(e.durs) or 0, 2) or nil,
            firstSeenSec = NS.round(firstSeen, 1),
            cdSeriesSec  = series,
            cycle        = NS.round(cycle, 1),
            samples      = total,
            pulls        = nPulls,
            spread       = det and det.score or 1,
            fit          = fit and NS.round(fit, 3) or nil,
            intervals    = fitN,
            quality      = quality,
            warn         = warn,
            channel      = e.kind == Store.KIND_CHANNEL,
            chained      = chained or nil,
        }
        end
    end

    -- Les singletons du lot d'amorçage annoncent la PREMIÈRE occurrence d'une
    -- capacité, avec sa latence initiale et non son cooldown. Quand leur
    -- déclenchement retombe sur l'offset d'un membre issu d'un découpage,
    -- c'est la même capacité : on écarte le doublon.
    local offsets = {}
    for _, r in ipairs(results) do
        if r.offset then offsets[#offsets + 1] = r.offset end
    end
    if #offsets > 0 then
        local keep = {}
        for _, r in ipairs(results) do
            local dup = false
            if not r.offset and r.samples == 1 and r.fromTimeline then
                for _, off in ipairs(offsets) do
                    if math.abs(r.firstSeenSec - off) <= 0.6 then dup = true; break end
                end
            end
            if not dup then keep[#keep + 1] = r end
        end
        results = keep
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
