-- TomoBoss — Générateur de données OBSERVÉES pour les 8 donjons de la saison 2.
--
-- Ces huit donjons sont en `matchOnly` : le moteur prédictif ne démarre jamais
-- dessus (Engine/Timeline.lua, lignes 260 et 299) et `cdSeriesSec` n'est
-- consommé que par `BT:BuildMatchIndex`, qui empile `firstSeenSec` et la série
-- dans un sac de durées comparé aux événements de C_EncounterTimeline.
--
-- Autrement dit : ici, une durée est une CLÉ D'IDENTIFICATION, pas une
-- prédiction. Le minutage vient de Blizzard. On n'a donc besoin d'aucune
-- inférence de cycle — seulement des durées réellement vues en jeu.
--
-- Le script conserve la sémantique éditoriale (name, role, voice, severity) et
-- les identifiants du jeu (spellID, eventID), et ne remplace QUE les durées.
-- Les noms et spellID viennent de Blizzard, pas d'une base tierce ; les
-- minutages, eux, deviennent intégralement des observations TomoBoss.
--
-- Usage :
--   lua5.4 Tools/export_observed.lua <chemin/vers/TomoBoss.lua> [sortie] [--depuis AAAA-MM-JJ]
--
-- Sans dossier de sortie, écrit dans Build/observed/ et n'écrase rien.

local svPath  = arg[1] or "/mnt/user-data/uploads/TomoBoss.lua"
local outDir  = arg[2] or "Build/observed"
-- Seuil GLOBAL optionnel (AAAA-MM-JJ ou "AAAA-MM-JJ HH:MM").
local since   = arg[3]

-- Seuils PAR RENCONTRE. Une rupture n'est presque jamais globale : elle vient
-- soit d'un changement de difficulté (tous les boss d'un donjon basculent dans
-- la même soirée), soit d'une retouche Blizzard (un seul boss, à des semaines
-- d'écart). Dans les deux cas les captures antérieures décrivent une version
-- qu'on ne joue plus, et les mélanger produit un index de correspondance à
-- moitié mort.
--
-- Le rapport signale les ruptures détectées : reporter la date ici, relancer.
-- La comparaison est lexicographique, donc "AAAA-MM-JJ HH:MM" fonctionne et
-- permet de couper au milieu d'une soirée.
local CUTOFFS = {
    -- Le Val Aveuglant : bascule de difficulté le 22/08 entre 21:11 et 21:41.
    -- Les quatre boss changent au même instant.
    [3199] = "2026-08-22 21:30",
    [3200] = "2026-08-22 21:30",
    [3201] = "2026-08-22 21:30",
    [3202] = "2026-08-22 21:30",
    -- Zul'jan : rupture isolée à trois semaines d'écart, cinq pulls avant et
    -- trois après, une seule durée commune. Retouche de la rencontre.
    [3458] = "2026-09-05",
}

local TOL      = 0.75  -- identique à BlizzTimeline
local MIN_SEEN = 3     -- une durée doit avoir été vue au moins 3 fois
local K_TL     = 3     -- Store.KIND_TIMELINE
local SENTINEL = 900   -- au-delà : signal d'état, jamais un timer joueur
-- Taux de RÉSOLUTION minimal : proportion des occurrences d'une durée qui se
-- déclenchent effectivement avant la fin du combat.
--
-- Certaines rencontres publient des entrées à long horizon : la même capacité
-- annoncée plusieurs cycles à l'avance. Sur The Hoardmonger, les durées 99 et
-- 92.39 apparaissent 37 et 6 fois mais se résolvent dans 8 % et 0 % des cas —
-- alors que le vrai cycle est de 40 s avec les durées 6, 16 et 30, soit
-- exactement les trois capacités de la rencontre. Leur donner une voix
-- produirait une double annonce.
--
-- Une capacité réelle se résout dans la plupart des cas ; les exceptions sont
-- les annonces tombant juste avant la mort du boss. Mesuré sur les captures :
-- 37 à 100 % pour toutes les vraies durées, 0 et 8 % pour ces deux-là.
local MIN_RESOLVED = 0.20
-- Écart en deçà duquel deux durées observées sont la MÊME. Le serveur renvoie
-- des valeurs flottantes légèrement instables : 92.39 et 92.4 sont un seul
-- événement, mais comptées séparément chacune peut passer sous les seuils des
-- filtres et ressortir en orpheline. On les regroupe avant tout comptage.
-- Les durées réellement distinctes d'une rencontre sont des valeurs d'auteur,
-- jamais séparées d'un dixième de seconde.
local MERGE_EPS = 0.15
-- Seconde passe, ASYMÉTRIQUE. Le serveur poste parfois une annonce en retard et
-- publie alors le temps restant : la série à 16 s ressort à 16.8, celle à 45 s à
-- 43.5. L'écart dépasse la fusion serrée, mais ces valeurs n'apparaissent qu'une
-- ou deux fois face à des dizaines d'occurrences de la vraie durée.
--
-- Le rapport de fréquence est le discriminant, pas l'écart : sur ces captures,
-- 21 (×5) et 21.5 (×17) sont deux capacités distinctes séparées d'un demi-
-- dixième, avec un rapport de 3. Une fusion fondée sur la seule distance les
-- détruirait ; un rapport de 10 les préserve et absorbe le bruit.
-- Le bruit va dans LES DEUX SENS : une annonce tardive publie un temps restant
-- plus court (43.5 pour 45), mais le relevé peut aussi sortir plus long
-- (16.8 pour 16). C'est la garde « valeur ronde » ci-dessous qui protège les
-- vraies capacités, pas la direction.
--
-- Contrôle sur ces captures : 21 et 21.5 sont deux capacités distinctes de
-- Kyrakka, toutes deux rondes — préservées. 43.54, 44.19 et 16.8 ne le sont
-- pas — absorbées.
local MERGE_FAR = 1.5    -- écart maximal de cette passe
local MERGE_RATIO = 5    -- la voisine plus longue doit être 5 fois plus fréquente

-- Une durée d'auteur est toujours RONDE — entier ou demi-seconde. Un reste
-- d'annonce tardive ne l'est jamais : 43.54, 24.35, 10.96. Seules les valeurs
-- non rondes sont donc absorbables ; sans cette garde, la passe fusionnait
-- 19 dans 20 et 9 dans 10, qui sont des capacités distinctes.
local function isAuthored(d) return math.abs(d * 2 - math.floor(d * 2 + 0.5)) < 1e-6 end
-- Proportion d'occurrences coïncidant avec un autre événement au-delà de
-- laquelle une durée est jugée REDONDANTE.
--
-- Certaines rencontres annoncent le même cast deux fois : une entrée courte au
-- moment voulu, une entrée longue plusieurs cycles à l'avance. Sur Sentinel of
-- Winter, la durée 63 ajoutée à t=13 et la durée 13 ajoutée à t=63 se
-- déclenchent toutes deux à 76 s : un seul cast, deux entrées. Leur donner une
-- voix chacune produit une double annonce.
--
-- Le taux de résolution ne suffit pas à les repérer : sur un pull assez long
-- elles se résolvent normalement. La signature fiable est la coïncidence de
-- l'instant de déclenchement avec celui d'une durée PLUS COURTE.
local MAX_COINCIDENT = 0.60


-- Les 8 donjons S2 et leurs rencontres, avec le fichier cible.
local DUNGEONS = {
    { file = "murder_row",          label = "Murder Row / L'Allée du Meurtre",
      enc = { 3101, 3102, 3103, 3105 } },
    { file = "den_of_nalorakk",     label = "Den of Nalorakk / Antre de Nalorak",
      enc = { 3207, 3208, 3209 } },
    { file = "the_blinding_vale",   label = "The Blinding Vale / Le Val Aveuglant",
      enc = { 3199, 3200, 3201, 3202 } },
    { file = "voidscar_arena",      label = "Voidscar Arena / Arène de la cicatrice du vide",
      enc = { 3285, 3286, 3287 } },
    { file = "altar_of_fangs",      label = "Altar of Fangs / Autel des Crochets",
      enc = { 3456, 3457, 3458 } },
    { file = "temple_of_sethraliss", label = "Temple of Sethraliss / Temple de Sephraliss",
      enc = { 2124, 2125, 2126, 2127 } },
    { file = "kings_rest",          label = "Kings' Rest / Repos des rois",
      enc = { 2139, 2140, 2142, 2143 } },
    { file = "ruby_life_pools",     label = "Ruby Life Pools / Bassin de l'essence rubis",
      enc = { 2606, 2609, 2623 } },
}

-- IDENTIFICATION MANUELLE.
--
-- Une durée observée ne dit pas quelle capacité elle annonce. Le rattachement
-- automatique s'appuie sur la définition existante, ce qui échoue dès qu'une
-- rencontre a été retouchée : les anciennes durées ne correspondent plus à
-- rien et les nouvelles sortent en TODO.
--
-- Ce tableau permet de trancher à la main, une fois, à partir d'une
-- observation en jeu. Quand une rencontre y figure, il remplace entièrement le
-- rattachement automatique pour elle. `role`, `voice` et `severity` sont repris
-- de la définition existante si le spellID y est connu, sinon ils doivent être
-- fournis ici.
--
-- Une même durée peut être listée par plusieurs capacités : la collision est
-- alors conservée et le moteur repliera sur une alerte générique, ce qui est
-- le comportement voulu tant qu'aucune règle ne sait trancher.
-- Durées ÉCARTÉES à la main, quand le journal du donjon clôt la liste des
-- capacités et qu'une durée observée n'en désigne aucune. C'est le pendant
-- d'IDENTIFY : une décision prise sur source, pas une heuristique.
local EXCLUDE = {
    -- Sentinel of Winter n'a que quatre capacités au journal : Frozen Tempest,
    -- Shattering Frostspike, Raging Squall et Glacial Torment — toutes déjà
    -- rattachées. Les durées 61 et 63 annoncent donc à long horizon des casts
    -- du cycle suivant (63 ajoutée à t=13 et 13 ajoutée à t=63 se déclenchent
    -- toutes deux à 76 s). Le filtre automatique ne les attrape pas : sur les
    -- pulls courts la seconde annonce n'existe pas encore, ce qui dilue le taux.
    [3208] = { 61, 63 },
    -- Kyrakka & Erkheart : les cinq capacités du journal (Inferno Spit,
    -- Roaring Firebreath, Winds of Change, Interrupting Cloudburst, Stormslam)
    -- sont toutes déjà rattachées — Winds of Change porte les durées 10 et 21.5.
    -- La 13, vue 3 fois seulement, ne désigne donc aucune capacité connue.
    [2623] = { 13 },
    -- The Hoardmonger : trois capacités seulement, cycle de 40 s avec les durées
    -- 6, 16 et 30. Toute durée nettement au-delà du cycle est forcément une
    -- annonce à long horizon d'un tour suivant, pas une capacité distincte. Un
    -- plafond vaut mieux qu'une liste de valeurs : le bruit serveur en produit
    -- de nouvelles à chaque capture (67.4, 68.3, 69.3, 78.1, 79.0, 92.4, 99...).
    [3207] = { above = 60 },
}

-- Corrections éditoriales appliquées à des capacités déjà identifiées, quand la
-- source décrit un rôle différent de celui hérité. Clé : spellID.
local OVERRIDE = {
    -- Glacial Torment se dissipe par effet anti-Magie : c'est une consigne de
    -- soigneur, pas un dégât de zone.
    [1235548] = { role = "heal", voice = "prepare-dispel", why = "dissipable Magie (journal)" },

    -- Nalorakk. Le déroulé réel : Echoing Maul cible au moins trois joueurs qui
    -- posent la zone loin du boss, puis Overwhelming Onslaught est canalisé 3 s
    -- et TOUT LE MONDE soak, puis Forceful Slam frappe le tank seul. Les deux
    -- premières étaient marquées « tank » alors qu'elles concernent le groupe,
    -- et la seule vraie mécanique de tank manquait au fichier.
    [1242860] = { role = "other", voice = "std-drop", why = "zone à poser loin du boss, pas un tank buster" },
    [1243569] = { role = "other", voice = "prepare-soak", why = "soak de groupe (déroulé)" },
    [1243011] = { role = "tank", voice = "intercept-add", why = "le tank intercepte les adds d'Echoing Maul" },

    -- The Hoardmonger : cône esquivable par tout le monde, pas une frappe tank.
    [1253268] = { role = "other", voice = "watch-frontal", why = "cône esquivable (fiche)" },

    -- Lightwarden Ruia. Grievous Thrash inflige un saignement levé seulement à
    -- pleine vie : consigne de soigneur. Pulverizing Strikes marque plusieurs
    -- cibles avec des cônes frontaux : c'est un spread. Ni l'une ni l'autre
    -- n'est un tank buster.
    [1241058] = { role = "heal", voice = "prepare-dispel", why = "saignement levé à pleine vie (journal)" },
    [1240210] = { role = "other", voice = "spread-now", why = "cônes sur plusieurs cibles (journal)" },

    -- The Council of Tribes. Whirling Axes frappe tout le monde dans 10 m avec
    -- recul ; Severing Axe vise un joueur au hasard. Aucune n'est ciblée tank.
    [266206] = { role = "other", voice = "watch-knockback", why = "AoE + recul dans 10 m (journal)" },
    [266231] = { role = "other", voice = "prepare-target", why = "cible aléatoire (journal)" },

    -- Mchimba. Awakening Slam ouvre des cryptes et invoque des momies : c'est un
    -- switch sur adds. Drain Fluids est un DoT qui applique Desiccation jusqu'à
    -- guérison au-dessus de 90 % : consigne de soigneur.
    [1312146] = { role = "mechanic", voice = "switch-add", why = "invoque des momies (journal)" },
    [267618] = { role = "heal", voice = "prepare-dispel", why = "Desiccation levée par le soin (journal)" },

    -- Interruptions annoncées jusqu'ici en mécanique générique.
    [269369] = { role = "mechanic", voice = "prepare-interrupt", why = "interruptible (fiche)" },
    [1310547] = { role = "mechanic", voice = "prepare-interrupt", why = "trois casts d'affilée, interruptible (journal)" },

    -- Mécaniques de soin classées ailleurs.
    [1301202] = { role = "heal", voice = "special-mechanic", why = "ne pas soigner le boss (fiche)" },
    [265781] = { role = "heal", voice = "prepare-aoe", why = "gros pic de soin (fiche)" },
    [474478] = { role = "heal", voice = "prepare-aoe", why = "gros pic de soin (fiche)" },
}

-- Attribution d'eventID. Ce ne sont pas des valeurs du jeu : l'eventID des
-- définitions est une clé d'auteur, que BuildEventIDIndex relie aux règles de
-- DURATION_RULES. Les identifiants publiés par C_EncounterTimeline sont des
-- poignées séquentielles renumérotées à chaque pull (245, 246, 247...) et ne
-- peuvent donc pas servir ici.
local EVENT_IDS = {
    -- On indexe sur les DEUX identifiants — celui du dépôt et celui du client —
    -- puisque le second remplace le premier à l'écriture : une table calée sur
    -- un seul des deux rate silencieusement la moitié des attributions.
    [2126] = { [1291618] = 2601, [1309525] = 2602, [1290531] = 2602 },
}

local IDENTIFY = {
    -- Kystia Manaheart. Attribution établie par CORRÉLATION entre les instants
    -- de déclenchement timeline et les incantations enregistrées, avec l'unité
    -- qui les lance :
    --   timeline 8  -> cast boss1 3,0 s ×32/34   (Kystia)
    --   timeline 12 -> canal boss2 5,0 s ×33     (Nibbles — 5 s = le cône tournant)
    --   timeline 15 -> cast boss1 3,5 s ×29/34   (Kystia, pendant le cône)
    --
    -- La donnée héritée portait le spellID de Fel Spray (1253811) sur les durées
    -- 8/27.5, qui sont en réalité Chaos Barrage : Nibbles canalise Fel Spray
    -- pendant 5 s, or la 8 ne corrèle qu'avec des incantations de Kystia.
    --
    -- Corroding Spittle, le DoT de Nibbles sur le tank, n'a aucune entrée
    -- timeline — ce qui résout l'écart entre quatre capacités fréquentes et
    -- trois créneaux minutés. Felshield non plus : c'est un buff persistant sur
    -- Kystia, levé par Destabilized quand Nibbles est presque mort.
    [3101] = {
        { dur = { 8, 27.5 }, spellID = 1230298, name = "Chaos Barrage",
          role = "mechanic", voice = "prepare-interrupt", severity = 2 },
        { dur = { 12, 25 }, spellID = 1253811, name = "Fel Spray",
          role = "other", voice = "watch-frontal", severity = 1 },
        { dur = { 15, 30 }, spellID = 1264095, name = "Mirror Images",
          role = "mechanic", voice = "prepare-interrupt", severity = 1 },
    },
    -- Lightblossom Trinity. Ordre confirmé sur la timeline Blizzard :
    -- Bedrock Slam (tank) → Thornblade (zone posée à l'écart, Lekshi y dash et
    -- canalise Fan Of Thorns) → Lightsower Dash (sème les bulbes) →
    -- Lightblossom Beam (répartition sur les trois fleurs). Les durées 5, 8, 20
    -- et 35 suivent exactement cet ordre : le rattachement automatique est bon.
    -- Reste la 45, fréquente et irrégulière : c'est Light Bolt, que Kezkitt
    -- lance souvent et que les joueurs doivent couper.
    [3199] = {
        -- Light Bolt est le round-robin de Kezkitt. Son annonce arrive parfois
        -- en retard et sort alors à 42.8, 43.5 ou 44.3 au lieu de 45 : même
        -- série, déclenchements alignés sur 125 et 170, espacés de 45. La
        -- fenêtre élargie les rattache au lieu de les laisser en orphelines.
        { dur = { 45 }, spellID = 1235616, name = "Light Bolt",
          role = "mechanic", voice = "prepare-interrupt", severity = 1, keepOthers = true },
    },
    -- Lightwarden Ruia. Le combat se découpe par paliers de vie : Moonkin
    -- jusqu'à 70 %, Bear jusqu'à 40 %, Haranir jusqu'à la mort. En Haranir le
    -- boss invoque des adds en forme Moonkin et Bear sans discontinuer.
    --
    -- La durée 21 se déclenche entre 56 % et 78 % du combat sur les trois pulls
    -- retenus, soit la fenêtre Haranir, et 2 à 3 fois par pull — une invocation
    -- répétée, pas une transition de forme qui n'arriverait qu'une fois.
    -- Le journal nomme cette capacité Spirits of the Vale.
    [3201] = {
        { dur = { 21 }, spellID = 1241067, name = "Spirits of the Vale",
          role = "mechanic", voice = "summon-adds", severity = 2, keepOthers = true },
    },
    -- Nalorakk : Forceful Slam tombe juste après le soak d'Overwhelming
    -- Onslaught et ne vise que le tank. C'était la seule capacité manquante.
    -- spellID confirmés par le relevé de journal du 12/09 : le journal marque
    -- Heurt vigoureux « tank » et Trait de Lumière « interruptible », ce qui
    -- valide indépendamment le rôle et la voix posés à la main.
    [3209] = {
        { dur = { 10 }, spellID = 1297797, name = "Forceful Slam",
          role = "tank", voice = "tank-buster", severity = 2, keepOthers = true },
    },
    -- Mchimba : Burn Corruption vise un joueur au hasard et laisse une zone en
    -- feu. Seule capacité du journal absente du fichier.
    [2142] = {
        { dur = { 63 }, spellID = 267639, name = "Burn Corruption",
          role = "heal", voice = "std-drop", severity = 1, keepOthers = true },
    },
    -- Dazar : l'unité boss2 est un gros raptor qui incante un fear à couper.
    -- La durée 36 est la seule à corréler avec lui.
    [2143] = {
        { dur = { 36 }, name = "Fear du raptor (à nommer)",
          role = "mechanic", voice = "prepare-interrupt", severity = 2, keepOthers = true },
    },
    [3458] = {
        { dur = { 3, 65 }, spellID = 1300876, name = "Ritual of the Fang" },
        -- Absente de l'ancienne définition : la rencontre a gagné cette capacité.
        { dur = { 18 }, spellID = 1300901, name = "Ritual Venom",
          role = "other", voice = "watch-dodge", severity = 1 },
        { dur = { 16, 30, 36 }, spellID = 1301111, name = "Axegrinder" },
        -- Partage la durée 30 avec le premier Axegrinder (phases 0 et 30 d'un
        -- cycle de 65). Les règles sequenceGroup dérivent le cycle de la durée
        -- elle-même et ne savent pas exprimer ce cas : collision conservée.
        { dur = { 30 }, spellID = 1301413, name = "Boneslicer" },
    },
}

--------------------------------------------------------------------------
-- 1. Définitions EFFECTIVES : on rejoue le vrai moteur, base + corrections.
--------------------------------------------------------------------------
local NS = { Engine = nil }
local ok, err = pcall(function()
    local chunk = assert(loadfile("Engine/Timeline.lua"))
    -- Engine/Timeline.lua enregistre aussi des handlers d'événements ; on lui
    -- fournit des stubs inoffensifs, seul le registre nous intéresse.
    _G.CreateFrame = _G.CreateFrame or function()
        return setmetatable({}, { __index = function() return function() end end })
    end
    _G.GetTime = _G.GetTime or function() return 0 end
    _G.UnitGUID = _G.UnitGUID or function() return nil end
    _G.C_Timer = _G.C_Timer or { After = function() end, NewTicker = function() return { Cancel = function() end } end }
    chunk("TomoBoss", NS)
end)
if not ok then
    io.stderr:write("impossible de charger le moteur : ", tostring(err), "\n")
    os.exit(1)
end
assert(NS.Engine, "NS.Engine absent")

local ORDER = {
    "murder_row", "den_of_nalorakk", "the_blinding_vale", "voidscar_arena",
    "altar_of_fangs", "temple_of_sethraliss", "kings_rest", "ruby_life_pools",
}
for _, f in ipairs(ORDER) do
    local c = loadfile("Engine/Encounters/" .. f .. ".lua")
    if c then c("TomoBoss", NS) end
end
local corr = loadfile("Engine/Encounters/Season2Corrections.lua")
if corr then corr("TomoBoss", NS) end

-- Les noms de capacité ne vivent que dans les commentaires de fin de ligne des
-- fichiers source ; la définition en mémoire ne les porte pas. On les récupère
-- par spellID pour garder des fichiers lisibles.
local SPELL_NAMES = {}
for _, f in ipairs(ORDER) do
    local fh = io.open("Engine/Encounters/" .. f .. ".lua")
    if fh then
        for line in fh:lines() do
            local sid, nm = line:match("spellID%s*=%s*(%d+).-%-%-%s*(.-)%s*$")
            if sid and nm and nm ~= "" then SPELL_NAMES[tonumber(sid)] = nm end
        end
        fh:close()
    end
end

-- Le SavedVariables porte à la fois les pulls et le relevé de journal : il doit
-- donc être chargé avant l'un comme l'autre.
assert(loadfile(svPath))()

-- Garde-fou d'idempotence.
--
-- Le générateur part de la définition D'ORIGINE et y rattache les durées
-- observées. Relancé sur sa propre sortie, il repart d'une définition déjà
-- réduite : les durées se rattachent autrement, de nouvelles collisions
-- apparaissent et les tables OVERRIDE, indexées par spellID, cessent de
-- correspondre puisque les identifiants ont été repris du client.
-- Mesuré : 125 entrées et 22 collisions au lieu de 115 et 11.
--
-- L'erreur est facile à commettre — il suffit d'avoir installé une génération
-- précédente — et silencieuse. On la rend bruyante.
do
    local tainted = {}
    for id, def in pairs(NS.Engine.Encounters or {}) do
        if def.provenance == "observed" then tainted[#tainted + 1] = id end
    end
    if #tainted > 0 then
        io.stderr:write(string.format([[
ARRÊT : %d rencontres de Engine/Encounters/ portent déjà provenance = "observed".

Le générateur doit lire les définitions D'ORIGINE, pas une génération précédente.
Restaure Engine/Encounters/ depuis git avant de relancer :

    git checkout -- Engine/Encounters/

La sortie précédente reste disponible dans son dossier de build.
]], #tainted))
        os.exit(1)
    end
end

--------------------------------------------------------------------------
-- 1bis. Relevé du journal, si le joueur en a fait un (/tmb journal).
--
-- Le journal porte l'identité et le rôle ; les captures portent le minutage.
-- Aucune des deux sources n'est un tiers : l'une vient du client du joueur,
-- l'autre de ses propres pulls. Le relevé est facultatif — sans lui le
-- générateur retombe sur les tables tenues à la main.
--------------------------------------------------------------------------
local JOURNAL = TomoBossDB and TomoBossDB.journal

-- Le journal parle la langue du client. Les fichiers de rencontres sont en
-- anglais : sur un client francophone, les titres reviennent traduits et ne
-- doivent servir ni de nom affiché ni de clé d'appariement de repli. Le
-- spellID, lui, ne dépend pas de la locale — c'est le seul lien fiable.
local J_LOCALE = JOURNAL and JOURNAL.locale or nil
local J_ENGLISH = (J_LOCALE == nil) or (J_LOCALE == "enUS") or (J_LOCALE == "enGB")

-- Résolution de NOS spellID en noms du client, produite par le même relevé.
-- C'est le pont quand le spellID du dépôt et celui du journal diffèrent : les
-- deux noms viennent du même client, donc ils concordent quelle que soit la langue.
local J_SPELLNAMES = (JOURNAL and JOURNAL.spellNames) or {}

local jIndex = {}   -- encID -> { bySpell = {...}, byLocal = {...}, list = {...} }
if JOURNAL and JOURNAL.encounters then
    for encID, e in pairs(JOURNAL.encounters) do
        local idx = { bySpell = {}, byName = {}, byLocal = {}, list = e.abilities or {}, name = e.name }
        for _, a in ipairs(e.abilities or {}) do
            if a.spellID then idx.bySpell[a.spellID] = a end
            -- Index par nom seulement si le relevé est anglophone : sinon il
            -- n'apparierait jamais et pourrait créer de faux rapprochements.
            if a.title and J_ENGLISH then idx.byName[a.title:lower()] = a end
            -- Index par titre tel que le client le rend, toutes langues : il
            -- s'apparie avec les noms résolus de nos propres spellID.
            --
            -- Un même titre peut désigner deux capacités distinctes dans une
            -- rencontre (18 cas relevés). Si leurs indicateurs diffèrent, le
            -- nom ne tranche plus : on neutralise l'entrée plutôt que de
            -- rapporter au hasard les indicateurs de l'une ou de l'autre.
            if a.title then
                local k = a.title:lower()
                local prev = idx.byLocal[k]
                if prev == nil then
                    idx.byLocal[k] = a
                elseif prev ~= false then
                    local pf = prev.flags and table.concat(prev.flags, ",") or ""
                    local af = a.flags and table.concat(a.flags, ",") or ""
                    if pf ~= af then idx.byLocal[k] = false end
                end
            end
        end
        jIndex[tostring(encID)] = idx
    end
end

-- Traduction des indicateurs du journal vers le vocabulaire de voix de TomoBoss.
-- On ne renvoie que ce que les indicateurs établissent vraiment : le reste des
-- choix éditoriaux reste à l'auteur.
local function journalRole(a)
    if not a or not a.flags then return nil end
    local f = {}
    for _, v in ipairs(a.flags) do f[v] = true end
    local role, voice, sev
    if f.tank then role = "tank"; voice = "tank-buster" end
    if f.healer then role = "heal" end
    -- L'interruption prime sur tout : c'est une consigne d'action immédiate,
    -- et elle vaut quel que soit le rôle visé.
    if f.interruptible then role = "mechanic"; voice = "prepare-interrupt" end
    if f.deadly then sev = 2 elseif f.important then sev = sev or 2 end
    if not role and not voice then return nil end
    return role, voice, sev, table.concat(a.flags, ",")
end

--------------------------------------------------------------------------
-- 2. Observations : durées timeline par rencontre, avec compte.
--------------------------------------------------------------------------
local pulls = TomoBossDB and TomoBossDB.profile
    and TomoBossDB.profile.learn and TomoBossDB.profile.learn.pulls
assert(pulls, "learn.pulls introuvable dans " .. svPath)

local REJECTED, REJECTED_ENC, COINC_RATE, MERGED = {}, {}, {}, {}

local function observedFor(encID)
    local list = pulls[tostring(encID)] or pulls[encID]
    if not list then return nil, 0 end
    local cut = CUTOFFS[tonumber(encID)] or since
    -- Une durée identifiée à la main échappe aux filtres : c'est une décision
    -- prise sur observation en jeu, elle prime sur toute heuristique.
    local ex = EXCLUDE[tonumber(encID)] or {}
    local banned, ceiling = {}, ex.above
    for _, d in ipairs(ex) do banned[d] = true end
    local pinned = {}
    for _, rule in ipairs(IDENTIFY[tonumber(encID)] or {}) do
        for _, d in ipairs(rule.dur) do pinned[d] = true end
    end
    local seen, nPulls = {}, 0
    for _, p in ipairs(list) do
        if cut and p.date and p.date < cut then goto skip end
        nPulls = nPulls + 1
        for _, o in ipairs(p.obs or {}) do
            if o[2] == K_TL and type(o[3]) == "number" and o[3] < SENTINEL then
                local d = math.floor(o[3] * 100 + 0.5) / 100
                seen[d] = (seen[d] or 0) + 1
            end
        end
        ::skip::
    end
    -- Taux de résolution, mesuré sur les mêmes pulls que les comptes.
    local fired = {}
    for _, p in ipairs(list) do
        if not (cut and p.date and p.date < cut) then
            for _, o in ipairs(p.obs or {}) do
                if o[2] == K_TL and type(o[3]) == "number" and o[3] < SENTINEL then
                    local d = math.floor(o[3] * 100 + 0.5) / 100
                    if p.len and (o[1] + o[3]) <= p.len then fired[d] = (fired[d] or 0) + 1 end
                end
            end
        end
    end

    -- Coïncidences : pour chaque durée, part de ses occurrences dont l'instant
    -- de déclenchement tombe sur celui d'un événement de durée plus courte.
    local coinc = {}
    for _, p in ipairs(list) do
        if not (cut and p.date and p.date < cut) then
            local fires = {}
            for _, o in ipairs(p.obs or {}) do
                if o[2] == K_TL and type(o[3]) == "number" and o[3] < SENTINEL then
                    fires[#fires + 1] = { at = o[1] + o[3], dur = o[3] }
                end
            end
            for _, a in ipairs(fires) do
                local d = math.floor(a.dur * 100 + 0.5) / 100
                for _, b in ipairs(fires) do
                    if b.dur < a.dur - TOL and math.abs(a.at - b.at) <= TOL then
                        coinc[d] = (coinc[d] or 0) + 1
                        break
                    end
                end
            end
        end
    end

    COINC_RATE[encID] = {}
    for d, c in pairs(coinc) do
        if seen[d] and seen[d] > 0 then COINC_RATE[encID][d] = c / seen[d] end
    end

    -- Regroupement des quasi-doublons. Le représentant du groupe est la valeur
    -- la plus fréquente, pas la moyenne : c'est celle que le serveur renvoie
    -- le plus souvent, donc celle qui appariera le mieux en jeu.
    do
        local ds = {}
        for d in pairs(seen) do ds[#ds + 1] = d end
        table.sort(ds)
        local i = 1
        while i <= #ds do
            local group = { ds[i] }
            local j = i + 1
            while j <= #ds and (ds[j] - group[#group]) <= MERGE_EPS do
                group[#group + 1] = ds[j]; j = j + 1
            end
            if #group > 1 then
                local rep, best = group[1], -1
                local total, tf = 0, 0
                for _, d in ipairs(group) do
                    total = total + seen[d]
                    tf = tf + (fired[d] or 0)
                    if seen[d] > best then best, rep = seen[d], d end
                end
                local parts = {}
                for _, d in ipairs(group) do
                    parts[#parts + 1] = tostring(d)
                    if d ~= rep then seen[d] = nil; fired[d] = nil; coinc[d] = nil end
                end
                seen[rep], fired[rep] = total, tf
                MERGED[#MERGED + 1] = { enc = encID, rep = rep, parts = parts, n = total }
            end
            i = j
        end
    end

    do
        local ds = {}
        for d in pairs(seen) do ds[#ds + 1] = d end
        table.sort(ds, function(a, b) return seen[a] < seen[b] end)
        for _, d in ipairs(ds) do
            if seen[d] and not isAuthored(d) then
                local best, bestN
                for o, c in pairs(seen) do
                    if o ~= d and math.abs(o - d) <= MERGE_FAR
                        and c >= seen[d] * MERGE_RATIO
                        and (not bestN or c > bestN) then
                        best, bestN = o, c
                    end
                end
                if best then
                    MERGED[#MERGED + 1] = { enc = encID, rep = best,
                        parts = { tostring(d), tostring(best) }, n = seen[best] + seen[d], far = true }
                    seen[best] = seen[best] + seen[d]
                    fired[best] = (fired[best] or 0) + (fired[d] or 0)
                    seen[d], fired[d], coinc[d] = nil, nil, nil
                end
            end
        end
    end

    local out = {}
    for d, n in pairs(seen) do
        if n >= MIN_SEEN then
            local rate = (fired[d] or 0) / n
            local dup = (coinc[d] or 0) / n
            if banned[d] or (ceiling and d > ceiling) then
                REJECTED[#REJECTED + 1] = string.format(
                    "durée %s vue %d fois — écartée manuellement (%s)",
                    tostring(d), n,
                    banned[d] and "le journal ne lui associe aucune capacité"
                        or string.format("au-delà du plafond de %s s de la rencontre", tostring(ceiling)))
                REJECTED_ENC[#REJECTED_ENC + 1] = encID
            elseif pinned[d] then
                out[#out + 1] = { dur = d, n = n }
            elseif n >= 4 and rate < MIN_RESOLVED then
                REJECTED[#REJECTED + 1] = string.format(
                    "durée %s vue %d fois mais résolue dans %.0f %% des cas — annonce à long horizon, pas une capacité",
                    tostring(d), n, rate * 100)
                REJECTED_ENC[#REJECTED_ENC + 1] = encID
            elseif n >= 4 and dup > MAX_COINCIDENT then
                REJECTED[#REJECTED + 1] = string.format(
                    "durée %s vue %d fois, déclenchant dans %.0f %% des cas au même instant qu'une durée plus courte — annonce redondante du même cast",
                    tostring(d), n, dup * 100)
                REJECTED_ENC[#REJECTED_ENC + 1] = encID
            else
                out[#out + 1] = { dur = d, n = n }
            end
        end
    end
    table.sort(out, function(a, b) return a.dur < b.dur end)
    return out, nPulls
end

-- Détection de DÉRIVE. Si les captures récentes d'une rencontre ne partagent
-- presque aucune durée avec les plus anciennes, le boss a été retouché : les
-- deux jeux décrivent des versions différentes et les mélanger produirait un
-- index de correspondance à moitié mort. On ne tranche pas, on signale.
local function driftCheck(encID)
    local list = pulls[tostring(encID)] or pulls[encID]
    if not list then return nil end
    -- Une rupture déjà traitée par un seuil n'est plus un problème ouvert :
    -- on n'analyse que les pulls effectivement retenus.
    local cut = CUTOFFS[tonumber(encID)] or since
    local dated = {}
    for _, p in ipairs(list) do
        if p.date and not (cut and p.date < cut) then dated[#dated + 1] = p end
    end
    if #dated < 4 then return nil end
    table.sort(dated, function(a, b) return a.date < b.date end)

    -- On ne compare que les durées que l'export retiendrait vraiment. Certaines
    -- rencontres émettent des valeurs flottantes quasi uniques (67.42, 67.44,
    -- 78.08...) : les compter gonfle l'union et fait crier à la rupture sur un
    -- boss parfaitement stable.
    local keep = {}
    do
        local n = {}
        for _, p in ipairs(dated) do
            for _, o in ipairs(p.obs or {}) do
                if o[2] == K_TL and o[3] < SENTINEL then n[o[3]] = (n[o[3]] or 0) + 1 end
            end
        end
        for d, c in pairs(n) do if c >= MIN_SEEN then keep[d] = true end end
    end

    local function setOf(p)
        local s = {}
        for _, o in ipairs(p.obs or {}) do
            if o[2] == K_TL and keep[o[3]] then s[o[3]] = true end
        end
        return s
    end

    -- On cherche une RUPTURE dans la chronologie, pas un dernier pull isolé.
    -- Comparer la dernière capture au reste devient muet dès que la dérive est
    -- confirmée par plusieurs pulls — exactement quand l'alerte compte le plus.
    -- On teste donc chaque coupure possible, chaque côté ayant au moins 2 pulls.
    local best
    for cut = 2, #dated - 2 do
        local before, after = {}, {}
        for i = 1, cut do for d in pairs(setOf(dated[i])) do before[d] = true end end
        for i = cut + 1, #dated do for d in pairs(setOf(dated[i])) do after[d] = true end end
        local union, common = 0, 0
        local seen = {}
        for d in pairs(before) do seen[d] = true end
        for d in pairs(after) do seen[d] = true end
        for d in pairs(seen) do
            union = union + 1
            if before[d] and after[d] then common = common + 1 end
        end
        if union >= 4 then
            local overlap = common / union
            if not best or overlap < best.overlap then
                best = { overlap = overlap, date = dated[cut + 1].date,
                         nBefore = cut, nAfter = #dated - cut,
                         common = common, union = union }
            end
        end
    end
    if best and best.overlap <= 0.34 then return best end
    return nil
end

--------------------------------------------------------------------------
-- 3. Rattachement d'une durée observée à un événement de la définition.
--------------------------------------------------------------------------
local function currentDurs(ev)
    local d = {}
    if ev.firstSeenSec then d[#d + 1] = ev.firstSeenSec end
    for _, v in ipairs(ev.cdSeriesSec or {}) do d[#d + 1] = v end
    return d
end

local report = {}
local function note(fmt, ...) report[#report + 1] = string.format(fmt, ...) end

local function attach(def, obs)
    local events = def.events or {}
    local assigned = {}         -- ev -> { durées observées }
    local orphans, ambiguous = {}, {}

    for _, o in ipairs(obs) do
        -- On retient TOUS les événements à égalité, pas seulement le premier.
        --
        -- N'en garder qu'un supprimerait la collision des données : le moteur
        -- ne verrait plus d'ambiguïté et annoncerait cette capacité avec
        -- assurance, alors qu'il repliait volontairement sur une alerte
        -- générique. Une mauvaise voix est pire qu'une voix neutre.
        local bestDelta, winners = nil, {}
        for _, ev in ipairs(events) do
            local evDelta
            for _, d in ipairs(currentDurs(ev)) do
                local delta = math.abs(o.dur - d)
                if delta <= TOL and (not evDelta or delta < evDelta) then evDelta = delta end
            end
            if evDelta then
                if not bestDelta or evDelta < bestDelta - 0.01 then
                    bestDelta, winners = evDelta, { ev }
                elseif math.abs(evDelta - bestDelta) <= 0.01 then
                    winners[#winners + 1] = ev
                end
            end
        end

        if #winners == 0 then
            orphans[#orphans + 1] = o
        else
            if #winners > 1 then ambiguous[#ambiguous + 1] = { o = o, n = #winners } end
            for _, ev in ipairs(winners) do
                assigned[ev] = assigned[ev] or {}
                assigned[ev][#assigned[ev] + 1] = o
            end
        end
    end
    return assigned, orphans, ambiguous
end

--------------------------------------------------------------------------
-- 4. Écriture des fichiers.
--------------------------------------------------------------------------
local function q(s) return '"' .. tostring(s):gsub('"', '\\"') .. '"' end
local function num(v)
    if v == math.floor(v) then return tostring(math.floor(v)) end
    return (string.format("%.2f", v):gsub("0+$", ""):gsub("%.$", ""))
end

os.execute("mkdir -p " .. outDir)
local stats = { enc = 0, kept = 0, dropped = 0, orphan = 0, ambig = 0, noData = 0 }

for _, dg in ipairs(DUNGEONS) do
    local lines = {}
    local function w(s) lines[#lines + 1] = s end
    w("---@diagnostic disable: undefined-global")
    w("-- TomoBoss — Donjon : " .. dg.label)
    w("--")
    w("-- Données de MATCHING générées depuis les captures TomoBoss (module Learn).")
    w("-- Chaque durée ci-dessous a été observée au moins " .. MIN_SEEN .. " fois sur")
    w("-- ENCOUNTER_TIMELINE_EVENT_ADDED en jeu. Aucune source tierce.")
    w("--")
    w("-- `matchOnly = true` : le minutage vient de C_EncounterTimeline, ces valeurs")
    w("-- ne servent qu'à identifier la capacité. Rôles, voix et sévérités sont des")
    w("-- choix éditoriaux conservés depuis la version précédente.")
    w("")
    w("local NS = select(2, ...)")
    w("local R = function(id, def) NS.Engine:RegisterEncounter(id, def) end")
    w("")

    for _, encID in ipairs(dg.enc) do
        local def = NS.Engine:GetEncounter(encID)
        local obs, nPulls = observedFor(encID)
        stats.enc = stats.enc + 1

        if not def then
            note("[%d] AUCUNE définition dans le dépôt — ignoré", encID)
        elseif not obs or #obs == 0 then
            stats.noData = stats.noData + 1
            note("[%d] %s : aucune durée observée %d+ fois (%d pull(s)) — fichier d'origine conservé",
                encID, def.name or "?", MIN_SEEN, nPulls)
        else
            if CUTOFFS[tonumber(encID)] then
                note("[%d] %s : seuil appliqué — seuls les pulls à partir du %s sont retenus",
                    encID, def.name or "?", CUTOFFS[tonumber(encID)])
            end
            local d = driftCheck(encID)
            if d then
                note("[%d] %s : RUPTURE le %s — %d pull(s) avant, %d après, seulement %d durée(s) commune(s) sur %d. Rencontre retouchée ; les captures antérieures décrivent une version qui n'existe plus. Relancer avec --depuis %s.",
                    encID, def.name or "?", d.date, d.nBefore, d.nAfter,
                    d.common, d.union, (d.date:match("^%d+-%d+-%d+")))
            end
            for _, m in ipairs(MERGED) do
                if m.enc == encID then
                    note("[%d] durées %s regroupées sur %s (%d observations) — %s",
                        encID, table.concat(m.parts, " / "), tostring(m.rep), m.n,
                        m.far and "annonce tardive absorbée par la durée dominante" or "même événement, bruit serveur")
                end
            end
            for i, msg in ipairs(REJECTED) do
                if REJECTED_ENC[i] == encID then note("[%d] %s : %s", encID, def.name or "?", msg) end
            end
            local jIdx = jIndex[tostring(encID)]
            if jIdx then
                -- Capacités de premier niveau que le journal liste et que
                -- l'export ne couvre pas : candidates aux durées manquantes.
                local covered = {}
                for _, ev in ipairs(def.events or {}) do
                    if ev.spellID then covered[ev.spellID] = true end
                    local nm = SPELL_NAMES[ev.spellID]
                    if nm then covered[nm:lower()] = true end
                    local ln = ev.spellID and J_SPELLNAMES[ev.spellID]
                    if ln then covered[ln:lower()] = true end
                end
                -- Les capacités nommées à la main comptent aussi comme couvertes :
                -- sans ça le journal signalerait comme manquant ce qu'IDENTIFY
                -- vient justement de rattacher.
                for _, rule in ipairs(IDENTIFY[tonumber(encID)] or {}) do
                    if rule.spellID then covered[rule.spellID] = true end
                    if rule.name then covered[rule.name:lower()] = true end
                end
                local missing = {}
                for _, a in ipairs(jIdx.list) do
                    local byName = covered[(a.title or ""):lower()]
                    if a.depth == 1 and not covered[a.spellID] and not byName then
                        missing[#missing + 1] = a.title
                    end
                end
                if #missing > 0 then
                    -- Sur un relevé traduit, une capacité nommée à la main sans
                    -- spellID ne peut pas être appariée : elle ressortirait
                    -- « manquante » à tort. On le dit plutôt que de laisser
                    -- croire à un trou dans les données.
                    local blind = false
                    if not J_ENGLISH then
                        for _, rule in ipairs(IDENTIFY[tonumber(encID)] or {}) do
                            if not rule.spellID then blind = true end
                        end
                    end
                    note("[%d] %s : au journal mais absentes de l'export — %s%s",
                        encID, jIdx.name or def.name or "?", table.concat(missing, ", "),
                        blind and "  (relevé traduit : une entrée nommée à la main sans spellID peut apparaître ici à tort — reporter son spellID dans IDENTIFY)" or "")
                end
            end
            local manual = IDENTIFY[tonumber(encID)]
            local assigned, orphans, ambiguous = attach(def, obs)
            local nKept = 0
            for _, ev in ipairs(def.events or {}) do
                if assigned[ev] and #assigned[ev] > 0 then nKept = nKept + 1 end
            end
            if nKept == 0 and #orphans == 0 then
                -- Émettre une rencontre vide supprimerait toute correspondance :
                -- pire que de conserver la donnée d'origine. On laisse en l'état.
                note("[%d] %s : aucune durée rattachable — DÉFINITION D'ORIGINE CONSERVÉE",
                    encID, def.name or "?")
                goto continue
            end
            w(string.format("-- %s  (encounterID %d) — %d pull(s) capturé(s)",
                def.name or "?", encID, nPulls))
            w(string.format("R(%d, {", encID))
            w(string.format("    name = %s,", q(def.name or "?")))
            w('    provenance = "observed",')
            if def.dungeon then w(string.format("    dungeon = %s,", q(def.dungeon))) end
            w("    matchOnly = true,")
            w("    events = {")

            if manual then
                -- Index des métadonnées éditoriales de la définition existante.
                local meta = {}
                for _, ev in ipairs(def.events or {}) do
                    if ev.spellID then meta[ev.spellID] = ev end
                end
                local used = {}
                -- keepOthers : la règle ajoute une capacité sans remplacer le
                -- rattachement automatique du reste de la rencontre.
                local additive = false
                for _, rule in ipairs(manual) do if rule.keepOthers then additive = true end end
                for _, rule in ipairs(manual) do
                    local ds, cnt = {}, {}
                    -- `tol` élargit la fenêtre d'une règle. Utile quand le
                    -- serveur poste une annonce en retard : il publie alors le
                    -- temps restant, pas l'intervalle, et la valeur dérive de
                    -- plus que la tolérance de correspondance ordinaire.
                    for _, want in ipairs(rule.dur) do
                        for _, o in ipairs(obs) do
                            if math.abs(o.dur - want) <= (rule.tol or TOL) then
                                ds[#ds + 1] = num(o.dur)
                                cnt[#cnt + 1] = num(o.dur) .. "×" .. o.n
                                used[o.dur] = true
                            end
                        end
                    end
                    if #ds > 0 then
                        stats.kept = stats.kept + 1
                        -- firstSeenSec pointe sur la valeur la PLUS OBSERVÉE,
                        -- pas sur la plus petite : quand une règle absorbe des
                        -- annonces en retard, la plus petite est une dérive et
                        -- afficher 43.54 pour une capacité à 45 induit en erreur.
                        do
                            local bi, bn = 1, -1
                            for k = 1, #ds do
                                local c = tonumber(cnt[k]:match("×(%d+)$")) or 0
                                if c > bn then bn, bi = c, k end
                            end
                            if bi ~= 1 then ds[1], ds[bi] = ds[bi], ds[1] end
                        end
                        local base = (rule.spellID and meta[rule.spellID]) or {}
                        local bits = {}
                        bits[#bits + 1] = "role = " .. q(rule.role or base.role or "other")
                        bits[#bits + 1] = "voice = " .. q(rule.voice or base.voice or "watch-dodge")
                        if rule.spellID then bits[#bits + 1] = "spellID = " .. num(rule.spellID) end
                        if base.eventID then bits[#bits + 1] = "eventID = " .. num(base.eventID) end
                        bits[#bits + 1] = "firstSeenSec = " .. ds[1]
                        bits[#bits + 1] = "cdSeriesSec = { " .. table.concat(ds, ", ") .. " }"
                        bits[#bits + 1] = "severity = " .. num(rule.severity or base.severity or 1)
                        w(string.format("        { %s },  -- %s  [vu %s]",
                            table.concat(bits, ", "), rule.name or "?", table.concat(cnt, " ")))
                    else
                        note("[%d] identification manuelle : %s — aucune des durées %s n'est observée",
                            encID, rule.name or rule.spellID, table.concat(rule.dur, "/"))
                    end
                end
                if additive then
                    -- Les durées réservées par les règles manuelles sont
                    -- retirées, mais PAS celles partagées entre capacités du
                    -- rattachement automatique : une collision volontaire doit
                    -- survivre, sinon le moteur cesse de replier en générique.
                    local claimed = {}
                    for k, v in pairs(used) do claimed[k] = v end
                    for _, ev in ipairs(def.events or {}) do
                        local got = assigned[ev]
                        if got and #got > 0 then
                            local ds, cnt = {}, {}
                            for _, o in ipairs(got) do
                                if not claimed[o.dur] then
                                    ds[#ds + 1] = num(o.dur); cnt[#cnt + 1] = num(o.dur) .. "×" .. o.n
                                    used[o.dur] = true
                                end
                            end
                            if #ds > 0 then
                                stats.kept = stats.kept + 1
                                local ov = ev.spellID and OVERRIDE[ev.spellID]
                                if ov then
                                    note("[%d] %s : rôle corrigé en %s/%s — %s",
                                        encID, SPELL_NAMES[ev.spellID] or tostring(ev.spellID),
                                        ov.role, ov.voice, ov.why)
                                end
                                local bits = {}
                                bits[#bits + 1] = "role = " .. q((ov and ov.role) or ev.role or "other")
                                bits[#bits + 1] = "voice = " .. q((ov and ov.voice) or ev.voice or "watch-dodge")
                                if ev.spellID then bits[#bits + 1] = "spellID = " .. num(ev.spellID) end
                                if ev.eventID then bits[#bits + 1] = "eventID = " .. num(ev.eventID) end
                                bits[#bits + 1] = "firstSeenSec = " .. ds[1]
                                bits[#bits + 1] = "cdSeriesSec = { " .. table.concat(ds, ", ") .. " }"
                                bits[#bits + 1] = "severity = " .. num(ev.severity or 1)
                                w(string.format("        { %s },  -- %s  [vu %s]",
                                    table.concat(bits, ", "),
                                    SPELL_NAMES[ev.spellID] or "capacité", table.concat(cnt, " ")))
                            end
                        end
                    end
                end
                for _, o in ipairs(obs) do
                    if not used[o.dur] then
                        stats.orphan = stats.orphan + 1
                        w(string.format(
                            '        { role = "other", voice = "watch-dodge", firstSeenSec = %s, cdSeriesSec = { %s }, severity = 1 },  -- TODO identifier  [vu %s×%d]',
                            num(o.dur), num(o.dur), num(o.dur), o.n))
                        note("[%d] durée %s vue %d fois, hors identification manuelle — à compléter",
                            encID, num(o.dur), o.n)
                    end
                end
                w("    },")
                w("})")
                w("")
                goto continue
            end

            for _, ev in ipairs(def.events or {}) do
                local got = assigned[ev]
                if got and #got > 0 then
                    stats.kept = stats.kept + 1
                    local ds, cnt = {}, {}
                    for _, o in ipairs(got) do
                        ds[#ds + 1] = num(o.dur); cnt[#cnt + 1] = num(o.dur) .. "×" .. o.n
                    end
                    local ov = ev.spellID and OVERRIDE[ev.spellID]
                    if ov then
                        note("[%d] %s : rôle corrigé en %s/%s — %s",
                            encID, SPELL_NAMES[ev.spellID] or tostring(ev.spellID),
                            ov.role, ov.voice, ov.why)
                    end
                    -- Le journal ne parle que si aucune décision manuelle n'a
                    -- été prise : une correction posée sur observation en jeu
                    -- reste au-dessus d'un indicateur générique.
                    local jRole, jVoice, jSev, jFlags
                    local ja = jIdx and ev.spellID and jIdx.bySpell[ev.spellID]
                    -- Repli par nom client : couvre le cas sort d'affichage
                    -- contre sort déclencheur, où les identifiants divergent.
                    if not ja and jIdx and ev.spellID and J_SPELLNAMES[ev.spellID] then
                        local cand = jIdx.byLocal[(J_SPELLNAMES[ev.spellID]):lower()]
                        if cand == false then
                            note("[%d] %s : titre partagé par deux capacités aux indicateurs différents — journal ignoré pour cette entrée",
                                encID, J_SPELLNAMES[ev.spellID])
                            stats.jamb = (stats.jamb or 0) + 1
                        elseif cand then
                            ja = cand
                            stats.jname = (stats.jname or 0) + 1
                        end
                    end
                    if not ja and jIdx and J_ENGLISH and SPELL_NAMES[ev.spellID] then
                        ja = jIdx.byName[(SPELL_NAMES[ev.spellID]):lower()]
                    end
                    if ja and not ov then
                        jRole, jVoice, jSev, jFlags = journalRole(ja)
                        if jRole and (jRole ~= ev.role or (jVoice and jVoice ~= ev.voice)) then
                            note("[%d] %s : journal [%s] -> %s/%s (était %s/%s)",
                                encID, ja.title, jFlags, jRole, jVoice or ev.voice or "?",
                                ev.role or "?", ev.voice or "?")
                            stats.jrole = (stats.jrole or 0) + 1
                        end
                    end
                    -- Le spellID du journal fait foi quand il diffère.
                    --
                    -- Les identifiants hérités viennent d'une table tierce et
                    -- plusieurs sont démontrablement faux : « Fel Nova » portait
                    -- 474240, Overwhelming Onslaught 1243569 là où le client dit
                    -- 1297792. Adopter celui du journal rend la jointure directe
                    -- au lieu de dépendre du nom — jointure fragile, puisque
                    -- 18 titres désignent deux capacités distinctes.
                    local useID = ev.spellID
                    if ja and ja.spellID and ja.spellID ~= ev.spellID then
                        note("[%d] %s : spellID %s -> %s (celui du client)",
                            encID, SPELL_NAMES[ev.spellID] or ja.title,
                            tostring(ev.spellID), tostring(ja.spellID))
                        useID = ja.spellID
                        stats.jid = (stats.jid or 0) + 1
                    end
                    local bits = {}
                    bits[#bits + 1] = "role = " .. q((ov and ov.role) or jRole or ev.role or "other")
                    bits[#bits + 1] = "voice = " .. q((ov and ov.voice) or jVoice or ev.voice or "watch-dodge")
                    if useID then bits[#bits + 1] = "spellID = " .. num(useID) end
                    local eidMap = EVENT_IDS[tonumber(encID)] or {}
                    local assigned = eidMap[ev.spellID] or (ja and eidMap[ja.spellID])
                    local eid = assigned or ev.eventID
                    if eid then bits[#bits + 1] = "eventID = " .. num(eid) end
                    bits[#bits + 1] = "firstSeenSec = " .. ds[1]
                    bits[#bits + 1] = "cdSeriesSec = { " .. table.concat(ds, ", ") .. " }"
                    bits[#bits + 1] = "severity = " .. num((ov and ov.severity) or jSev or ev.severity or 1)
                    w(string.format("        { %s },  -- %s  [vu %s]",
                        table.concat(bits, ", "),
                        -- Nom affiché : celui du dépôt d'abord. Le titre du
                        -- journal ne prend le relais que s'il est anglophone et
                        -- que le dépôt n'a rien, pour ne pas semer du français
                        -- dans des fichiers anglais.
                        SPELL_NAMES[ev.spellID] or (J_ENGLISH and ja and ja.title)
                            or ev.name or "capacité",
                        table.concat(cnt, " ")))
                else
                    stats.dropped = stats.dropped + 1
                    note("[%d] %s : durée(s) %s jamais observée(s) — entrée RETIRÉE",
                        encID, tostring(ev.spellID or ev.eventID or "?"),
                        table.concat(currentDurs(ev), "/"))
                end
            end
            -- Une durée observée sans capacité connue est une VRAIE mécanique que
            -- la donnée tierce ne couvrait pas. La jeter reviendrait à perdre
            -- l'observation ; on l'émet avec une voix neutre et un marqueur.
            for _, o in ipairs(orphans) do
                stats.orphan = stats.orphan + 1
                w(string.format(
                    '        { role = "other", voice = "watch-dodge", firstSeenSec = %s, cdSeriesSec = { %s }, severity = 1 },  -- TODO identifier  [vu %s×%d]',
                    num(o.dur), num(o.dur), num(o.dur), o.n))
                local cr = (COINC_RATE[encID] or {})[o.dur]
                note("[%d] durée %s vue %d fois, capacité inconnue — émise en TODO%s",
                    encID, num(o.dur), o.n,
                    (cr and cr > 0.25)
                        and string.format(" ; ATTENTION : coïncide avec une durée plus courte dans %.0f %% des cas, possible doublon d'annonce", cr * 100)
                        or ", rôle et voix à définir")
            end
            w("    },")
            w("})")
            w("")
            for _, a in ipairs(ambiguous) do
                stats.ambig = stats.ambig + 1
                note("[%d] durée %s partagée par %d capacités — collision CONSERVÉE (repli générique), DURATION_RULES nécessaire pour trancher",
                    encID, num(a.o.dur), a.n)
            end
        end
        ::continue::
    end

    local path = outDir .. "/" .. dg.file .. ".lua"
    local fh = assert(io.open(path, "w"))
    fh:write(table.concat(lines, "\n"), "\n")
    fh:close()
    print("écrit : " .. path)
end

local rp = outDir .. "/RAPPORT.txt"
local fh = assert(io.open(rp, "w"))
fh:write("TomoBoss — export des durées observées (saison 2, 8 donjons)\n")
fh:write(string.format("généré le %s depuis %s%s\n\n", os.date("%Y-%m-%d %H:%M"), svPath,
    since and ("  (pulls à partir du " .. since .. ")") or ""))
fh:write(string.format("rencontres traitées      : %d\n", stats.enc))
fh:write(string.format("entrées confirmées       : %d\n", stats.kept))
fh:write(string.format("entrées retirées         : %d  (durée jamais observée)\n", stats.dropped))
fh:write(string.format("durées orphelines        : %d  (observées, capacité inconnue)\n", stats.orphan))
fh:write(string.format("durées ambiguës          : %d  (règle de désambiguïsation à écrire)\n", stats.ambig))
fh:write(string.format("rencontres sans donnée   : %d\n", stats.noData))
if JOURNAL then
    fh:write(string.format("relevé journal           : %s (%d rencontres, locale %s%s)\n",
        JOURNAL.scannedAt or "?",
        (function() local n=0 for _ in pairs(jIndex) do n=n+1 end return n end)(),
        tostring(J_LOCALE or "?"),
        J_ENGLISH and "" or " — titres traduits, appariement par spellID uniquement"))
    fh:write(string.format("rôles issus du journal   : %d\n", stats.jrole or 0))
    fh:write(string.format("appariés via nom client  : %d  (spellID divergents)\n", stats.jname or 0))
    fh:write(string.format("spellID repris du client : %d\n", stats.jid or 0))
    if (stats.jamb or 0) > 0 then
        fh:write(string.format("titres ambigus ignorés   : %d\n", stats.jamb))
    end
else
    fh:write("relevé journal           : ABSENT — lancer /tmb journal en jeu puis réexporter\n")
end
fh:write("\n")
fh:write(table.concat(report, "\n"), "\n")
fh:close()
print("rapport : " .. rp)
print(string.format("\n%d entrées confirmées, %d retirées, %d orphelines, %d ambiguës",
    stats.kept, stats.dropped, stats.orphan, stats.ambig))
