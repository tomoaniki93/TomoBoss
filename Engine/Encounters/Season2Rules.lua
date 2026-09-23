local addonName, NS = ...
if type(NS) ~= "table" then return end

--------------------------------------------------------------------------
-- Règles de désambiguïsation des durées partagées.
--
-- Sous `matchOnly`, une capacité est identifiée par la durée que publie
-- C_EncounterTimeline. Quand deux capacités d'une même rencontre partagent une
-- durée, BlizzTimeline refuse de trancher et replie sur une alerte générique —
-- comportement voulu : une mauvaise voix vaut moins qu'une voix neutre.
--
-- Ces règles rendent le choix possible quand la PHASE dans le cycle sépare les
-- candidates. Elles ne devinent rien : chaque offset ci-dessous est mesuré sur
-- les captures, et ne doit être écrit que s'il est stable d'un pull à l'autre.
--------------------------------------------------------------------------

NS.DURATION_RULES = NS.DURATION_RULES or {}

-- Aucune règle active pour l'instant.
--
-- Galvazzt a été tenté puis RETIRÉ. Ses deux capacités partagent la durée 22,
-- et les instants de déclenchement semblaient former deux séries entrelacées
-- sur un cycle régulier, décalées d'une quinzaine de secondes :
--
--   5 · 20 · 27 · 43 · 50 · 66 · 72 · 89 · 95 · 112 · 117 · 134 · 139
--
-- Les ouvertures sont effectivement stables — 5 et 20 sur les sept pulls
-- capturés. Mais le cycle, lui, ne l'est pas : médiane 23,06 s, moyenne
-- 24,45 s, maximum 29,16 s, pour des écarts consécutifs allant de 4,9 à
-- 20,7 s. Deux phases séparées de sept secondes seulement dans un cycle de
-- vingt-deux ne survivent pas à cette dérive.
--
-- Mesuré par rejeu sur les observations réelles (Tools/test_rules.lua) :
--
--   décalages 5 / 20   -> 31 % d'attributions fausses
--   espacement régulier -> 65 %
--
-- Une annonce fausse une fois sur trois vaut moins que le repli générique.
-- La collision reste donc non tranchée, et c'est le bon résultat.
--
-- Toute règle ajoutée ici doit passer Tools/test_rules.lua avant livraison :
-- une régularité constatée sur un pull ne prouve rien sur sept.
