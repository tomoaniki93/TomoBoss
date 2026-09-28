local addonName, NS = ...
if type(NS) ~= "table" then return end

--------------------------------------------------------------------------
-- JournalScan — relève l'identité et le rôle des capacités depuis le
-- journal du donjon du joueur.
--
-- Le journal porte ce que nos captures ne portent pas : le nom de chaque
-- capacité, son spellID et les indicateurs de rôle que Blizzard lui attache.
-- Nos captures portent l'inverse : le minutage réel. Les deux sources se
-- complètent exactement, et aucune des deux n'est un tiers.
--
--   journal   -> qui est cette capacité, et à qui elle s'adresse
--   captures  -> quand elle tombe
--
-- Le relevé est écrit dans TomoBossDB.journal, indexé par dungeonEncounterID,
-- soit le même identifiant que ENCOUNTER_START et que nos pulls. La jointure
-- est directe, sans table de correspondance à maintenir.
--
-- Commande : /tmb journal   (ou /tmbjournal)
--------------------------------------------------------------------------

local JS = {}
NS.JournalScan = JS

-- GetSectionIconFlags renvoie des INDICES dans la liste des indicateurs, pas
-- les valeurs de l'enum : Tank est le bit le plus bas (valeur 1) mais l'indice 0.
local FLAG_LABELS = {
    [0]  = "tank",
    [1]  = "dps",
    [2]  = "healer",
    [3]  = "heroic",
    [4]  = "deadly",
    [5]  = "important",
    [6]  = "interruptible",
    [7]  = "magic",
    [8]  = "curse",
    [9]  = "poison",
    [10] = "disease",
    [11] = "enrage",
    [12] = "mythic",
    [13] = "bleed",
}

local MAX_DEPTH    = 12   -- l'arbre est de la donnée d'auteur : un cycle mal formé gèlerait le client
local MAX_SIBLINGS = 200  -- même raison, sur le chaînage horizontal

local function say(fmt, ...)
    local msg = select("#", ...) > 0 and string.format(fmt, ...) or fmt
    if NS.Print then NS:Print(msg) else print("|cff33ff99TomoBoss|r: " .. msg) end
end

--------------------------------------------------------------------------
-- Disponibilité
--------------------------------------------------------------------------
-- Blizzard_EncounterJournal est en chargement à la demande : les globales EJ_
-- n'existent pas tant que rien ne l'a ouvert. On le charge nous-mêmes plutôt
-- que de demander au joueur d'aller ouvrir le journal.
local function ensureJournal()
    if EJ_GetCurrentTier and C_EncounterJournal and C_EncounterJournal.GetSectionInfo then
        return true
    end
    if C_AddOns and C_AddOns.LoadAddOn then
        pcall(C_AddOns.LoadAddOn, "Blizzard_EncounterJournal")
    elseif LoadAddOn then
        pcall(LoadAddOn, "Blizzard_EncounterJournal")
    end
    return EJ_GetCurrentTier ~= nil
        and C_EncounterJournal ~= nil
        and C_EncounterJournal.GetSectionInfo ~= nil
end

-- EJ_SelectTier et EJ_SelectInstance mutent un état que l'interface du journal
-- relit sans argument, avec son propre cache qui ne se resynchronise pas.
-- Relever pendant que le joueur a le journal ouvert corromprait son affichage.
local function journalBusy()
    return EncounterJournal ~= nil and EncounterJournal:IsShown()
end

--------------------------------------------------------------------------
-- Parcours de l'arbre des sections
--------------------------------------------------------------------------
-- La profondeur est conservée : le journal imbrique les conséquences sous la
-- capacité qui les provoque. Rimeshatter sous Shattering Frostspike n'est pas
-- une capacité minutée indépendante, et c'est l'arbre qui le dit.
local function walk(sectionID, out, depth, parentTitle, seen)
    if not sectionID or depth > MAX_DEPTH then return end
    seen = seen or {}
    local id, guard = sectionID, 0

    while id and guard < MAX_SIBLINGS do
        guard = guard + 1
        if seen[id] then break end
        seen[id] = true

        local info = C_EncounterJournal.GetSectionInfo(id)
        if not info then break end

        -- Une vraie capacité, pas un en-tête. Le journal groupe ses conseils
        -- sous des rubriques « Tank », « Healer »… qui portent les mêmes
        -- indicateurs mais n'ont aucun sort derrière : c'est ce qui les sépare.
        local isAbility = info.spellID and info.spellID > 0

        -- Les passifs ne sont jamais des événements : rien ne les annonce.
        if isAbility and C_Spell and C_Spell.IsSpellPassive then
            local ok, passive = pcall(C_Spell.IsSpellPassive, info.spellID)
            if ok and passive == true then isAbility = false end
        end

        if isAbility and info.title and info.title ~= "" then
            local flags, labels = C_EncounterJournal.GetSectionIconFlags(id), nil
            if flags then
                for i = 1, #flags do
                    local lbl = FLAG_LABELS[flags[i]]
                    if lbl then
                        labels = labels or {}
                        labels[#labels + 1] = lbl
                    end
                end
            end
            -- Icône du sort.
            --
            -- Sous Midnight, C_EncounterTimeline masque le nom serveur et le
            -- GUID du lanceur ; en raid il ne reste RIEN qui identifie la
            -- capacité — l'identifiant d'événement est un compteur de session,
            -- pas une identité (relevé : pull suivant du même combat, le
            -- compteur reprend là où il s'était arrêté).
            --
            -- L'icône, elle, n'est pas masquée : BlizzTimeline lit déjà
            -- info.iconFileID pour dessiner la barre générique. C'est donc le
            -- seul pont d'identité qui reste, et il ne vaut que si les deux
            -- côtés le portent : le journal ici, les captures dans le Store.
            local icon
            if C_Spell and C_Spell.GetSpellInfo then
                local ok, si = pcall(C_Spell.GetSpellInfo, info.spellID)
                if ok and type(si) == "table" then
                    icon = si.iconID or si.originalIconID
                end
            end

            out[#out + 1] = {
                title   = info.title,
                spellID = info.spellID,
                icon    = icon,
                flags   = labels,
                depth   = depth,
                parent  = parentTitle,
            }
            parentTitle = info.title
        end

        if info.firstChildSectionID then
            walk(info.firstChildSectionID, out, depth + 1, parentTitle, seen)
        end
        id = info.siblingSectionID
    end
end

--------------------------------------------------------------------------
-- Relevé d'une instance
--------------------------------------------------------------------------
local function scanInstance(journalID, instanceName, out)
    EJ_SelectInstance(journalID)
    local n = 0
    for i = 1, 40 do
        local bossName, _, bossID = EJ_GetEncounterInfoByIndex(i)
        if not bossName then break end
        if bossID then
            -- 7e retour : dungeonEncounterID, celui que rapporte ENCOUNTER_START
            -- et que portent nos pulls.
            local _, _, _, rootSectionID, _, _, encID = EJ_GetEncounterInfo(bossID)
            if encID and rootSectionID then
                local abilities = {}
                walk(rootSectionID, abilities, 1, nil, nil)
                out[tostring(encID)] = {
                    name      = bossName,
                    instance  = instanceName,
                    journalID = journalID,
                    abilities = abilities,
                }
                n = n + 1
            end
        end
    end
    return n
end

--------------------------------------------------------------------------
-- Relevé complet
--------------------------------------------------------------------------
function JS:Scan()
    if not ensureJournal() then
        say("journal indisponible — impossible de charger Blizzard_EncounterJournal.")
        return false
    end
    if journalBusy() then
        say("ferme le journal du donjon avant de lancer le relevé (son cache ne se resynchronise pas).")
        return false
    end
    if InCombatLockdown and InCombatLockdown() then
        say("relevé refusé en combat.")
        return false
    end

    local priorTier = EJ_GetCurrentTier and EJ_GetCurrentTier()
    local out, nEnc, nInst = {}, 0, 0

    -- Pool Mythique+ : la liste vivante de la saison, celle qu'utilise
    -- l'interface de clés. Aucune constante de saison de notre côté.
    if C_ChallengeMode and C_ChallengeMode.GetMapTable and C_EncounterJournal.GetInstanceForGameMap then
        local maps = C_ChallengeMode.GetMapTable() or {}
        for i = 1, #maps do
            local mapName, _, _, _, _, gameMapID = C_ChallengeMode.GetMapUIInfo(maps[i])
            local journalID = gameMapID and C_EncounterJournal.GetInstanceForGameMap(gameMapID)
            if journalID then
                nEnc = nEnc + scanInstance(journalID, mapName or "?", out)
                nInst = nInst + 1
            end
        end
    end

    -- Raids du palier courant. Aucune API ne donne « le dernier raid » : on
    -- prend la liste du palier, la plus récente en dernier.
    if EJ_SelectTier and EJ_GetInstanceByIndex and priorTier then
        EJ_SelectTier(priorTier)
        for i = 1, 20 do
            local instanceID, rname = EJ_GetInstanceByIndex(i, true)
            if not instanceID then break end
            nEnc = nEnc + scanInstance(instanceID, rname or "?", out)
            nInst = nInst + 1
        end
    end

    -- Restauration : on rend au journal l'état dans lequel on l'a trouvé.
    if priorTier and EJ_SelectTier then EJ_SelectTier(priorTier) end

    if nEnc == 0 then
        say("relevé vide — aucune rencontre lue. Le journal était peut-être encore en cours de chargement, réessaie.")
        return false
    end

    -- Résolution des spellID que porte déjà le dépôt.
    --
    -- Le journal expose le sort d'AFFICHAGE, souvent l'aura appliquée, alors
    -- que nos fichiers portent parfois le sort DÉCLENCHEUR : deux identifiants
    -- différents pour la même capacité, et la jointure par spellID échoue.
    -- Mesuré sur le premier relevé : 65 % d'appariement seulement.
    --
    -- On résout donc nos propres identifiants en noms du client. L'export peut
    -- alors joindre par le nom, qui est le même des deux côtés puisque les deux
    -- viennent du même client, quelle que soit sa langue.
    local names = {}
    local nResolved = 0
    if NS.Engine and NS.Engine.Encounters and C_Spell then
        local getName = C_Spell.GetSpellName
            or function(id) return (GetSpellInfo and GetSpellInfo(id)) end
        for _, def in pairs(NS.Engine.Encounters) do
            for _, ev in ipairs(def.events or {}) do
                if ev.spellID and not names[ev.spellID] then
                    local ok, nm = pcall(getName, ev.spellID)
                    if ok and type(nm) == "string" and nm ~= "" then
                        names[ev.spellID] = nm
                        nResolved = nResolved + 1
                    end
                end
            end
        end
    end

    NS.db = NS.db or {}
    NS.db.journal = {
        spellNames = names,
        version   = 1,
        scannedAt = date("%Y-%m-%d %H:%M"),
        client    = (GetBuildInfo and select(1, GetBuildInfo())) or "?",
        locale    = GetLocale and GetLocale() or "?",
        encounters = out,
    }

    local nAb = 0
    for _, e in pairs(out) do nAb = nAb + #e.abilities end
    say("relevé : %d instances, %d rencontres, %d capacités, %d spellID du dépôt résolus. Écrit dans TomoBossDB.journal.",
        nInst, nEnc, nAb, nResolved)
    return true
end

--------------------------------------------------------------------------
-- Aperçu d'une rencontre, pour vérifier sans quitter le jeu
--------------------------------------------------------------------------
function JS:Show(encID)
    local j = NS.db and NS.db.journal
    if not j then say("aucun relevé — lance /tmb journal d'abord.") return end
    local e = j.encounters[tostring(encID)]
    if not e then say("rencontre %s absente du relevé.", tostring(encID)) return end

    say("%s (%s) — %d capacités", e.name, e.instance, #e.abilities)
    for _, a in ipairs(e.abilities) do
        local tags = a.flags and (" [" .. table.concat(a.flags, ",") .. "]") or ""
        local nest = a.depth > 1 and string.rep("  ", a.depth - 1) .. "> " or ""
        print(string.format("   %s%s (%d)%s", nest, a.title, a.spellID or 0, tags))
    end
end

SLASH_TMB_JOURNAL1 = "/tmbjournal"
SlashCmdList["TMB_JOURNAL"] = function() JS:Scan() end
