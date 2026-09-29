---@diagnostic disable: undefined-global
-- TomoBoss — Donjon : Murder Row / L'Allée du Meurtre
--
-- Données de MATCHING générées depuis les captures TomoBoss (module Learn).
-- Chaque durée ci-dessous a été observée au moins 3 fois sur
-- ENCOUNTER_TIMELINE_EVENT_ADDED en jeu. Aucune source tierce.
--
-- `matchOnly = true` : le minutage vient de C_EncounterTimeline, ces valeurs
-- ne servent qu'à identifier la capacité. Rôles, voix et sévérités sont des
-- choix éditoriaux conservés depuis la version précédente.

local NS = select(2, ...)
local R = function(id, def) NS.Engine:RegisterEncounter(id, def) end

-- Kystia Manaheart  (encounterID 3101) — 12 pull(s) capturé(s)
R(3101, {
    name = "Kystia Manaheart",
    provenance = "observed",
    dungeon = "Murder Row",
    matchOnly = true,
    events = {
        { role = "mechanic", voice = "prepare-interrupt", spellID = 1230298, firstSeenSec = 8, cdSeriesSec = { 8, 27.5 }, severity = 2 },  -- Chaos Barrage  [vu 8×36 27.5×34]
        { role = "other", voice = "watch-frontal", spellID = 1253811, firstSeenSec = 12, cdSeriesSec = { 12, 25 }, severity = 1 },  -- Fel Spray  [vu 12×74 25×3]
        { role = "mechanic", voice = "prepare-interrupt", spellID = 1264095, firstSeenSec = 15, cdSeriesSec = { 15, 30 }, severity = 1 },  -- Mirror Images  [vu 15×36 30×27]
    },
})

-- Zaen Bladesorrow  (encounterID 3102) — 12 pull(s) capturé(s)
R(3102, {
    name = "Zaen Bladesorrow",
    provenance = "observed",
    dungeon = "Murder Row",
    matchOnly = true,
    events = {
        { role = "heal", voice = "prepare-aoe", spellID = 474478, eventID = 835, firstSeenSec = 8, cdSeriesSec = { 8 }, severity = 1 },  -- Killing Spree  [vu 8×38]
        -- Les durées 12 et 16 étaient rattachées à une seule entrée : la
        -- définition d'origine ne portait que cinq capacités, le générateur y a
        -- versé six durées. Les captures les séparent — à l'instant de
        -- déclenchement, la 12 correspond à une CANALISATION de 3 s de boss1
        -- (36 relevés) et la 16 à une INCANTATION de 3 s (30 relevés). Une
        -- canalisation et une incantation ne sont pas la même capacité.
        --
        -- L'ordre du cycle de 42 s le confirme : 8 Killing Spree, 12, 18 Fire
        -- Bomb, 26 Envenom, 28 (durée 16), 36 Murder in a Row. Fire Bomb fait
        -- apparaître les trois tonneaux ; la capacité qui sert à en détruire un
        -- vient APRÈS, c'est donc la 16. Le journal donne le couple : Fel-Infused
        -- Freight (1201553) est l'enfant mythique de Same-Day Delivery (474765).
        --
        -- Cette livraison-ci NE prend PAS l'annonce du tonneau vert : relevé en
        -- jeu, les tonneaux rappelés au cycle suivant ne sont pas verts. Une
        -- seule occurrence par cycle mérite donc la consigne, celle de la 16.
        { role = "mechanic", voice = "watch-dodge", spellID = 474765, eventID = 836, firstSeenSec = 12, cdSeriesSec = { 12 }, severity = 1 },  -- Same-Day Delivery  [vu 12×38]
        -- Deux joueurs sont ciblés et s'en servent pour détruire un tonneau :
        -- seul le VERT doit tomber. L'annonce doit arriver avant le choix de la
        -- cible, d'où la pré-alerte. Pas d'eventID : celui du dépôt appartient à
        -- Same-Day Delivery, et un eventID partagé ferait jouer la mauvaise
        -- annonce par le jeu (EventBridge:WillPlaySound indexe dessus).
        { role = "mechanic", voice = "prep-green-barrel", spellID = 1201553, firstSeenSec = 16, cdSeriesSec = { 16 }, severity = 2, preAlertSec = 3 },  -- Fel-Infused Freight  [vu 16×36]
        -- Fait apparaître les trois tonneaux et demande de s'écarter, pas
        -- d'esquiver : « watch-dodge » venait de la donnée héritée.
        { role = "other", voice = "prep-spread", spellID = 1214357, eventID = 837, firstSeenSec = 18, cdSeriesSec = { 18 }, severity = 2 },  -- Fire Bomb  [vu 18×38]
        { role = "tank", voice = "tank-buster", spellID = 1222795, eventID = 838, firstSeenSec = 26, cdSeriesSec = { 26 }, severity = 1 },  -- Envenom  [vu 26×38]
        -- Chaque joueur doit se mettre à couvert derrière un tonneau ; le tir les
        -- détruit, puis le cycle repart sur Killing Spree. C'est une coupure de
        -- ligne de vue, pas un frontal à contourner — « watch-frontal » venait de
        -- la donnée héritée et décrivait mal la parade. Pré-alerte : il faut être
        -- derrière le tonneau AVANT le tir, pas au moment où il part.
        { role = "mechanic", voice = "std-los", spellID = 1218347, eventID = 839, firstSeenSec = 36, cdSeriesSec = { 36 }, severity = 2, preAlertSec = 3 },  -- Murder in a Row  [vu 36×38]
    },
})

-- Xathuux the Annihilator  (encounterID 3103) — 11 pull(s) capturé(s)
R(3103, {
    name = "Xathuux the Annihilator",
    provenance = "observed",
    dungeon = "Murder Row",
    matchOnly = true,
    events = {
        { role = "tank", voice = "tank-buster", spellID = 473898, eventID = 845, firstSeenSec = 6, cdSeriesSec = { 6, 27 }, severity = 2 },  -- Legion Strike  [vu 6×30 27×50]
        { role = "other", voice = "watch-knockback", spellID = 1214663, firstSeenSec = 15, cdSeriesSec = { 15 }, severity = 2 },  -- Axe Toss  [vu 15×30]
        { role = "tank", voice = "tank-buster", spellID = 1295455, firstSeenSec = 30, cdSeriesSec = { 30 }, severity = 1 },  -- Infernal Crush  [vu 30×30]
        { role = "other", voice = "watch-dodge", spellID = 474197, firstSeenSec = 35, cdSeriesSec = { 35 }, severity = 1 },  -- Demonic Rage  [vu 35×30]
    },
})

-- Lithiel Cinderfury  (encounterID 3105) — 12 pull(s) capturé(s)
R(3105, {
    name = "Lithiel Cinderfury",
    provenance = "observed",
    dungeon = "Murder Row",
    matchOnly = true,
    events = {
        { role = "other", voice = "summon-adds", spellID = 474408, firstSeenSec = 10, cdSeriesSec = { 10, 57 }, severity = 0 },  -- Summon Vilefiend  [vu 10×12 57×28]
        { role = "other", voice = "watch-dodge", spellID = 474457, firstSeenSec = 15, cdSeriesSec = { 15, 55 }, severity = 1 },  -- Fingers of Gul'dan  [vu 15×12 55×27]
        { role = "other", voice = "watch-dodge", spellID = 1217384, firstSeenSec = 24, cdSeriesSec = { 24, 59 }, severity = 2 },  -- Malefic Wave  [vu 24×12 59×22]
    },
})

