---@diagnostic disable: undefined-global
-- TomoBoss — Migration de provenance des minutages.
--
-- Module additif chargé APRES Slash.lua :
--   * ne modifie jamais une définition Engine/Encounters automatiquement ;
--   * mesure quelles rencontres tierces disposent de pulls Learn exploitables ;
--   * génère un export groupé "observed" depuis les pulls du joueur ;
--   * corrige le rapport de provenance pour distinguer réellement
--     observed/journal des sources tierces/unknown ;
--   * ajoute /tmb learn migration et /tmb learn exportready sans modifier
--     Learn/Slash.lua.
--
-- /tmb learn apply reste un test DE SESSION. La disparition réelle d'une
-- provenance tierce exige l'intégration du bloc exporté dans le dépôt.

local NS = select(2, ...)
NS.Learn = NS.Learn or {}

local M = {}
NS.Learn.Migration = M

local Store = NS.Learn.Store
local Export = NS.Learn.Export
local Provenance = NS.Learn.Provenance

local VALID_QUALITY = { faible = true, moyen = true, bon = true }

local function quality(v)
    return VALID_QUALITY[v] and v or "moyen"
end

local function pullsFor(id)
    return Store:GetPulls(tostring(id)) or Store:GetPulls(id)
end

local function countKills(pulls)
    local n = 0
    for _, p in ipairs(pulls or {}) do
        if p.outcome == "kill" then n = n + 1 end
    end
    return n
end

local function cleanCount(scan)
    local by = scan and scan.bySource or {}
    return (by.observed or 0) + (by.journal or 0)
end

local function unknownCount(scan)
    local by = scan and scan.bySource or {}
    return by.unknown or 0
end

--------------------------------------------------------------------------
-- Scan migration.
--------------------------------------------------------------------------
function M:Scan(minQuality)
    minQuality = quality(minQuality)
    local p = Provenance:Scan()
    local out = {
        total = p.total or 0,
        thirdParty = p.thirdParty or 0,
        clean = cleanCount(p),
        unknown = unknownCount(p),
        withPulls = 0,
        ready = 0,
        minQuality = minQuality,
        entries = {},
    }

    for _, e in ipairs(p.list or {}) do
        if Provenance.THIRD_PARTY[e.src] then
            local pulls = pullsFor(e.id)
            local pullCount = pulls and #pulls or 0
            local kills = countKills(pulls)
            if pullCount > 0 then out.withPulls = out.withPulls + 1 end

            local def, err, skipped = Export:BuildDef(tostring(e.id), minQuality)
            local eventCount = def and def.events and #def.events or 0
            local ready = eventCount > 0
            if ready then out.ready = out.ready + 1 end

            out.entries[#out.entries + 1] = {
                id = e.id,
                name = e.name,
                dungeon = e.dungeon,
                source = e.src,
                pulls = pullCount,
                kills = kills,
                ready = ready,
                events = eventCount,
                skipped = skipped or 0,
                err = err,
            }
        end
    end

    table.sort(out.entries, function(a, b)
        if a.ready ~= b.ready then return a.ready end
        if (a.dungeon or "") ~= (b.dungeon or "") then
            return (a.dungeon or "") < (b.dungeon or "")
        end
        return (tonumber(a.id) or 0) < (tonumber(b.id) or 0)
    end)

    return out
end

--------------------------------------------------------------------------
-- Rapport copiable.
--------------------------------------------------------------------------
function M:BuildReport(minQuality)
    local s = self:Scan(minQuality)
    local lines = {}
    local function w(v) lines[#lines + 1] = v end

    w("TomoBoss — Rapport de migration des minutages")
    w("Seuil Learn : " .. tostring(s.minQuality))
    w("")
    w(string.format("Rencontres totales ........ %d", s.total))
    w(string.format("Propres / Blizzard ........ %d", s.clean))
    w(string.format("Tierces restantes ......... %d", s.thirdParty))
    w(string.format("Avec pulls Learn .......... %d", s.withPulls))
    w(string.format("Prêtes à exporter ......... %d", s.ready))
    if s.unknown > 0 then
        w(string.format("Provenance inconnue ....... %d", s.unknown))
    end
    w("")
    w("PRÊT = au moins une capacité Learn passe le seuil demandé.")
    w("L'export ne reprend AUCUN minutage de la source tierce.")
    w("spellID / rôle / voix / sévérité restent à relire avant publication.")
    w("")

    for _, e in ipairs(s.entries) do
        local status
        if e.ready then
            status = "PRÊT"
        elseif e.pulls > 0 then
            status = "À RENFORCER"
        else
            status = "À CAPTURER"
        end
        w(string.format(
            "[%-10s] %s  %-30s  %-24s  pulls=%d kills=%d events=%d src=%s",
            status, tostring(e.id), tostring(e.name or "?"), tostring(e.dungeon or "?"),
            e.pulls, e.kills, e.events, tostring(e.source)
        ))
    end

    return table.concat(lines, "\n"), s
end

function M:ShowReport(minQuality)
    local text = self:BuildReport(minQuality)
    Export:ShowWindow(text, "TomoBoss — migration des données")
end

--------------------------------------------------------------------------
-- Export groupé.
--------------------------------------------------------------------------
local function fixMetadata(text, entry)
    if type(text) ~= "string" then return text end

    -- Export:BuildDef utilise GetInstanceInfo() pour le champ dungeon. Quand on
    -- exporte une ancienne capture depuis une autre zone, cette métadonnée peut
    -- être fausse. La provenance possède déjà le nom de donjon de la définition
    -- existante : on corrige UNIQUEMENT cette chaîne descriptive.
    if entry and entry.dungeon and entry.dungeon ~= "" then
        local replacement = string.format("    dungeon = %q,", entry.dungeon)
        text = text:gsub('    dungeon = "[^"]*",', replacement, 1)
    end
    return text
end

function M:BuildReadyExport(minQuality)
    local s = self:Scan(minQuality)
    local out = {}
    local function w(v) out[#out + 1] = v end

    w("-- TomoBoss — bundle de migration OBSERVED")
    w("-- Généré uniquement depuis les pulls Learn du joueur.")
    w("-- Aucun minutage EXBoss/LittleWigs/BossReminder n'est copié ici.")
    w("-- IMPORTANT : spellID / role / voice / severity doivent être relus avant intégration.")
    w(string.format("-- Seuil Learn : %s ; rencontres prêtes : %d", s.minQuality, s.ready))
    w("")

    local exported = 0
    for _, e in ipairs(s.entries) do
        if e.ready then
            local text, err = Export:Emit(tostring(e.id), s.minQuality)
            if text then
                text = fixMetadata(text, e)
                exported = exported + 1
                w("-- =====================================================================")
                w(string.format("-- Encounter %s — %s — ancienne provenance: %s",
                    tostring(e.id), tostring(e.name or "?"), tostring(e.source)))
                w(string.format("-- Pulls Learn: %d ; kills: %d ; événements exportés: %d",
                    e.pulls, e.kills, e.events))
                w("-- =====================================================================")
                w(text)
                w("")
            else
                w(string.format("-- ÉCHEC export %s : %s", tostring(e.id), tostring(err)))
            end
        end
    end

    return table.concat(out, "\n"), exported, s
end

function M:ShowReadyExport(minQuality)
    local text, exported = self:BuildReadyExport(minQuality)
    if exported == 0 then
        NS:Print("|cffe8c07dAucune rencontre tierce n'est encore exportable à ce seuil.|r")
        return
    end
    Export:ShowWindow(text, string.format(
        "TomoBoss — %d rencontre(s) observée(s) prête(s)", exported))
end

--------------------------------------------------------------------------
-- Rapport provenance corrigé, sans modifier Learn/Provenance.lua.
--------------------------------------------------------------------------
if Provenance then
    function Provenance:Print(verbose)
        local r = self:Scan()
        if r.total == 0 then
            NS:Print("Aucune rencontre enregistrée.")
            return
        end

        local clean = cleanCount(r)
        local unknown = unknownCount(r)
        local pct = 100 * clean / r.total

        NS:Print(string.format(
            "Provenance des minutages — %d rencontre(s), |cff8bd5ca%.0f %%|r non tierces vérifiées :",
            r.total, pct))

        local order = { "observed", "journal", "exboss", "littlewigs", "bossreminder", "unknown" }
        for _, src in ipairs(order) do
            local n = r.bySource[src]
            if n then
                local col = self.THIRD_PARTY[src] and "|cffe8c07d"
                    or (src == "unknown" and "|cffe8c07d" or "|cff8bd5ca")
                NS:Print(string.format("  %s%-18s|r %3d", col, self.LABEL[src] or src, n))
            end
        end

        if r.thirdParty > 0 then
            NS:Print(string.format(
                "|cffe8c07d%d rencontre(s) reposent encore sur des minutages tierces.|r",
                r.thirdParty))
            NS:Print("|cff8bd5ca/tmb learn apply <clé>|r teste uniquement pour la session.")
            NS:Print("|cff8bd5ca/tmb learn exportready [seuil]|r génère les blocs observés prêts à intégrer.")
        else
            NS:Print("|cff8bd5caAucune donnée de minutage tierce restante.|r")
        end

        if unknown > 0 then
            NS:Print(string.format(
                "|cffe8c07d%d rencontre(s) ont une provenance non renseignée et restent à auditer.|r",
                unknown))
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
end

--------------------------------------------------------------------------
-- Extension de /tmb learn, additive et chargée après Slash.lua.
--------------------------------------------------------------------------
local originalHandleSlash = NS.Learn.HandleSlash
if type(originalHandleSlash) == "function" then
    function NS.Learn:HandleSlash(rest)
        local sub, arg1 = tostring(rest or ""):match("^(%S*)%s*(%S*)")
        if sub == "migration" then
            M:ShowReport(arg1 ~= "" and arg1 or "moyen")
            return
        elseif sub == "exportready" then
            M:ShowReadyExport(arg1 ~= "" and arg1 or "moyen")
            return
        end
        return originalHandleSlash(self, rest)
    end
end
