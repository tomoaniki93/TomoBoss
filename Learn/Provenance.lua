---@diagnostic disable: undefined-global
-- TomoBoss — Provenance des données de rencontre.
--
-- Chaque définition porte un champ `provenance` qui dit d'où viennent ses
-- valeurs de minutage. L'objectif n'est pas décoratif : il s'agit de rendre
-- MESURABLE le remplacement des données tierces par des données observées.
--
--   "exboss"       durées converties depuis la suite EXBoss (saison 12.0 S1)
--   "littlewigs"   branches de durée extraites de LittleWigs (S2 hors-saison)
--   "bossreminder" reprises de BossReminder (raids), même origine en amont
--   "observed"     produites par /tmb learn depuis mes propres pulls
--   "journal"      issues du Journal des rencontres (API Blizzard)
--
-- Les trois premières sont des données tierces. Ni EXBoss ni LittleWigs ne
-- publient de licence permissive — le dépôt LittleWigs n'a aucun fichier
-- LICENSE, ce qui signifie « tous droits réservés » par défaut, et non
-- « librement réutilisable ». Le champ existe pour piloter leur sortie, pas
-- pour la justifier.
--
-- Effacer les commentaires d'attribution ne changerait rien à l'origine des
-- valeurs : ça supprimerait seulement la trace. La seule sortie propre est de
-- REGÉNÉRER, rencontre par rencontre, et ce module compte ce qu'il reste.

local NS = select(2, ...)
local P = {}
NS.Learn = NS.Learn or {}
NS.Learn.Provenance = P

P.THIRD_PARTY = { exboss = true, littlewigs = true, bossreminder = true }

P.LABEL = {
    exboss       = "EXBoss",
    littlewigs   = "LittleWigs",
    bossreminder = "BossReminder",
    observed     = "mes pulls",
    journal      = "Journal Blizzard",
    unknown      = "non renseignée",
}

--------------------------------------------------------------------------
-- Inventaire.
--------------------------------------------------------------------------
function P:Scan()
    local bySrc, total, third = {}, 0, 0
    local list = {}
    for encID, def in pairs(NS.Engine:AllEncounters()) do
        local src = def.provenance or "unknown"
        bySrc[src] = (bySrc[src] or 0) + 1
        total = total + 1
        if self.THIRD_PARTY[src] then third = third + 1 end
        list[#list + 1] = { id = encID, name = def.name, src = src, dungeon = def.dungeon }
    end
    table.sort(list, function(a, b)
        if a.src ~= b.src then return a.src < b.src end
        return (a.dungeon or "") < (b.dungeon or "")
    end)
    return { bySource = bySrc, total = total, thirdParty = third, list = list }
end

--------------------------------------------------------------------------
-- Rapport.
--------------------------------------------------------------------------
function P:Print(verbose)
    local r = self:Scan()
    if r.total == 0 then NS:Print("Aucune rencontre enregistrée."); return end

    local pct = 100 * (r.total - r.thirdParty) / r.total
    NS:Print(string.format("Provenance des données — %d rencontre(s), |cff8bd5ca%.0f %%|r issues de mes propres pulls :",
        r.total, pct))

    local order = { "observed", "journal", "exboss", "littlewigs", "bossreminder", "unknown" }
    for _, src in ipairs(order) do
        local n = r.bySource[src]
        if n then
            local col = self.THIRD_PARTY[src] and "|cffe8c07d" or "|cff8bd5ca"
            NS:Print(string.format("  %s%-18s|r %3d", col, self.LABEL[src] or src, n))
        end
    end

    if r.thirdParty > 0 then
        NS:Print(string.format("|cffe8c07d%d rencontre(s) reposent encore sur des données tierces.|r", r.thirdParty))
        NS:Print("Enregistrez des pulls puis |cff8bd5ca/tmb learn apply <clé>|r : la rencontre")
        NS:Print("bascule alors automatiquement en « mes pulls ».")
    else
        NS:Print("|cff8bd5caAucune donnée tierce restante.|r")
    end

    if verbose then
        NS:Print("Détail :")
        for _, e in ipairs(r.list) do
            NS:Print(string.format("  %-6s %-28s %-22s %s",
                tostring(e.id), tostring(e.name), tostring(e.dungeon),
                self.LABEL[e.src] or e.src))
        end
    end
end

-- Rencontres encore tierces, triées : la liste de travail.
function P:Remaining()
    local r = self:Scan()
    local out = {}
    for _, e in ipairs(r.list) do
        if self.THIRD_PARTY[e.src] then out[#out + 1] = e end
    end
    return out
end
