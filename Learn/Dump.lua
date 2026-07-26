---@diagnostic disable: undefined-global
-- TomoBoss — Apprentissage / Dump.
--
-- Recrache une capture BRUTE, ligne par ligne, avec la provenance de chaque
-- observation (jeton d'unité, npcID). Objectif : ne plus jamais déduire ce que
-- le serveur envoie — le lire.
--
-- Si des sorts du joueur apparaissent ici, le filtre d'unité fuit.
-- Si la colonne « incantations » reste vide alors que la timeline se remplit,
-- c'est que les événements de cast n'arrivent pas du tout sur les unités boss —
-- et l'identité devra reposer entièrement sur la durée-identité de la timeline.

local NS = select(2, ...)
local Dump = {}
NS.Learn = NS.Learn or {}
NS.Learn.Dump = Dump

local Store = NS.Learn.Store

local KIND_LABEL = {
    [1] = "CAST    ",
    [2] = "CHANNEL ",
    [3] = "TIMELINE",
    [4] = "INSTANT ",
    [5] = "INTERROMPU",
}

local function fmtLine(o)
    local t, kind, dur, npc, unit, fire, sname = o[1], o[2], o[3], o[4], o[5], o[6], o[7]
    local label = KIND_LABEL[kind] or ("?" .. tostring(kind))
    if kind == Store.KIND_TIMELINE then
        return string.format("[%7.2f] %s  id-dur=%-7s fire=%-8s %s",
            t or 0, label,
            dur and string.format("%.2f", dur) or "-",
            fire and string.format("%.2f", fire) or "-",
            sname and ("nom serveur: " .. sname) or "(nom masqué)")
    end
    return string.format("[%7.2f] %s  npc=%-9s unit=%-7s dur=%s",
        t or 0, label,
        npc and tostring(npc) or "-",
        unit or "-",
        dur and string.format("%.2f", dur) or "-")
end

--------------------------------------------------------------------------
-- Construction du texte.
--------------------------------------------------------------------------
function Dump:Build(key, index)
    local list = Store:GetPullsRaw(key)
    if not list or #list == 0 then
        return nil, "aucune capture pour " .. tostring(key)
    end
    index = tonumber(index) or #list          -- par défaut : la plus récente
    local p = list[index]
    if not p then return nil, "index hors bornes (1.." .. #list .. ")" end

    local out = {}
    local function w(s) out[#out + 1] = s end

    w(("TomoBoss — capture brute  clé=%s  pull %d/%d"):format(tostring(key), index, #list))
    w(("date=%s  durée=%.1fs  issue=%s  schéma=%s")
        :format(tostring(p.date), p.len or 0, tostring(p.outcome), tostring(p.schema or "v1 (périmé)")))
    w(("boss=%s  npc=%s  instance=%s")
        :format(tostring(p.boss), tostring(p.npc), tostring(p.inst)))
    w(("observations=%d"):format(#p.obs))
    w(string.rep("-", 76))

    local counts = {}
    for _, o in ipairs(p.obs) do
        counts[o[2]] = (counts[o[2]] or 0) + 1
        w(fmtLine(o))
    end

    w(string.rep("-", 76))
    local parts = {}
    for k = 1, 5 do
        parts[#parts + 1] = string.format("%s=%d", (KIND_LABEL[k] or k):gsub("%s+$", ""), counts[k] or 0)
    end
    w("Totaux : " .. table.concat(parts, "  "))

    -- verdict lisible, pour éviter d'interpréter à la main
    local casts = (counts[1] or 0) + (counts[2] or 0) + (counts[4] or 0)
    local tl    = counts[3] or 0
    w("")
    if casts == 0 and tl > 0 then
        w("VERDICT : aucun événement d'incantation sur les unités boss, mais la")
        w("timeline est alimentée. L'identité doit donc reposer sur la durée-identité")
        w("de C_EncounterTimeline seule.")
    elseif casts > 0 and tl > 0 then
        w("VERDICT : les deux flux répondent. La corrélation timeline <-> incantation")
        w("est possible ; l'identité peut être le couple (npcID, durée mesurée).")
    elseif casts > 0 then
        w("VERDICT : incantations reçues mais timeline muette — vérifier que")
        w("C_EncounterTimeline est disponible sur ce contenu.")
    else
        w("VERDICT : aucun des deux flux n'a produit d'observation.")
    end

    return table.concat(out, "\n")
end

--------------------------------------------------------------------------
-- Fenêtre copiable (réutilise celle de l'export).
--------------------------------------------------------------------------
function Dump:Show(key, index)
    local text, err = self:Build(key, index)
    if not text then NS:Print("|cffe06c75" .. tostring(err) .. "|r"); return end
    NS.Learn.Export:ShowWindow(text, "TomoBoss — capture brute " .. tostring(key))
end

-- Version chat, pour un coup d'œil rapide (bornée, le chat sature vite).
function Dump:Print(key, index, maxLines)
    local text, err = self:Build(key, index)
    if not text then NS:Print("|cffe06c75" .. tostring(err) .. "|r"); return end
    maxLines = tonumber(maxLines) or 40
    local n = 0
    for line in text:gmatch("[^\n]+") do
        n = n + 1
        if n > maxLines then
            NS:Print(("... (%d lignes de plus — |cff8bd5ca/tmb learn dump %s|r pour la fenêtre copiable)")
                :format(select(2, text:gsub("\n", "")) - maxLines + 1, tostring(key)))
            break
        end
        NS:Print(line)
    end
end
