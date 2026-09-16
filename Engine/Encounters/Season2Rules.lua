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

-- Galvazzt (Temple de Sethraliss).
--
-- Ses deux seules capacités partagent la durée 22, qui représente 45 des 55
-- observations : le combat était donc annoncé en générique presque de bout en
-- bout. Les instants de déclenchement montrent deux séries entrelacées sur un
-- même cycle, décalées d'environ quinze secondes :
--
--   5 · 20 · 28 · 42 · 51 · 65 · 74 · 95 · 103 · 118 · 126
--   A    B    A    B    A    B    A     ...
--
-- Lightning Spire ouvre à 5 s, Induction à 20 s, et ces deux ouvertures sont
-- identiques sur les six pulls capturés — c'est ce qui autorise des offsets
-- fixes plutôt que l'espacement régulier de repli, qui supposerait 0 et 11 et
-- désignerait la mauvaise capacité une fois sur deux.
--
-- Le cycle réel est d'environ 23 s alors que la durée annoncée est 22 : l'écart
-- est absorbé par la correction de dérive de BlizzTimeline, qui s'applique au
-- groupe entier et non à chaque membre.
NS.DURATION_RULES[2126] = {
    { time = 22, eventID = 2601, sequenceGroup = "galvazzt", sequenceOrder = 1 },
    { time = 22, eventID = 2602, sequenceGroup = "galvazzt", sequenceOrder = 2 },

    -- Offsets de phase, mesurés : premier déclenchement de chaque série.
    { sync = true, eventID = 2601, time = 5 },
    { sync = true, eventID = 2602, time = 20 },
}
