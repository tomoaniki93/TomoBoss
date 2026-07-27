---@diagnostic disable: undefined-global
-- TomoBoss — Apprentissage / Export.
--
-- Deux sorties depuis une analyse :
--
--   Apply()  : injecte les données dans le moteur pour la session en cours,
--              via Engine:MergeEncounter. Permet de tester immédiatement,
--              sans /reload et sans toucher aux fichiers.
--
--   Emit()   : produit un bloc Lua au format exact de Engine/Encounters/*.lua,
--              affiché dans une zone de texte sélectionnable, prêt à coller.
--
-- La sévérité, le rôle et la voix ne sont PAS déductibles des observations :
-- ce sont des choix d'auteur. L'export les remplit avec des valeurs neutres
-- explicitement marquées « À RÉGLER » pour qu'aucune donnée non relue ne
-- se retrouve publiée par inadvertance.
--
-- Le spellID et l'eventID ne sont pas déductibles non plus : sous Midnight le
-- serveur ne livre ni nom ni GUID exploitable. Ce que l'apprentissage produit,
-- c'est le MINUTAGE (firstSeenSec / cdSeriesSec) et la durée-identité — soit
-- exactement ce que consomme BT:BuildMatchIndex.

local NS = select(2, ...)
local Export = {}
NS.Learn = NS.Learn or {}
NS.Learn.Export = Export

local Infer = NS.Learn.Infer

local MIN_QUALITY_ORDER = { faible = 1, ["moyen"] = 2, bon = 3 }

--------------------------------------------------------------------------
-- Conversion analyse -> définition de rencontre.
--------------------------------------------------------------------------
-- minQuality : "faible" | "moyen" | "bon" — filtre les capacités trop incertaines.
function Export:BuildDef(key, minQuality)
    local res, err = Infer:Analyze(key)
    if not res then return nil, err end

    local floor = MIN_QUALITY_ORDER[minQuality or "moyen"] or 2
    local encID = tonumber(key)
    local events, skipped = {}, 0

    for _, r in ipairs(res) do
        local q = MIN_QUALITY_ORDER[r.quality] or 1
        if q < floor or #r.cdSeriesSec == 0 then
            skipped = skipped + 1
        else
            events[#events + 1] = {
                role         = "other",          -- À RÉGLER
                voice        = "",               -- À RÉGLER
                spellID      = nil,              -- À RÉGLER (non déductible)
                castType     = r.channel and "channel" or "begincast",
                castDuration = r.castDuration,
                firstSeenSec = r.firstSeenSec,
                cdSeriesSec  = r.cdSeriesSec,
                severity     = 1,                -- À RÉGLER
                __key        = r.key,
                __tlDur      = r.timelineDur,
                __quality    = r.quality,
                __cycle      = r.cycle,
            }
        end
    end

    local def = {
        name    = (encID and NS.Learn.Journal:EncounterName(encID)) or tostring(key),
        dungeon = select(1, GetInstanceInfo()) or "?",
        -- Toute donnée produite ici vient de mes propres pulls : l'estampille
        -- fait avancer le compteur de /tmb learn provenance sans intervention.
        provenance = "observed",
        events  = events,
    }
    return def, nil, skipped
end

--------------------------------------------------------------------------
-- Application immédiate (session en cours).
--------------------------------------------------------------------------
function Export:Apply(key, minQuality)
    local encID = tonumber(key)
    if not encID then
        NS:Print("|cffe06c75Clé synthétique|r : reliez-la d'abord avec |cff8bd5ca/tmb learn rekey "
            .. tostring(key) .. " <encounterID>|r.")
        return false
    end
    local def, err, skipped = self:BuildDef(key, minQuality)
    if not def then NS:Print("|cffe06c75" .. tostring(err) .. "|r"); return false end
    if #def.events == 0 then
        NS:Print("|cffe8c07dAucune capacité ne passe le seuil de qualité.|r Refaites des pulls, "
            .. "ou baissez le seuil : |cff8bd5ca/tmb learn apply " .. key .. " faible|r")
        return false
    end

    NS.Engine:MergeEncounter(encID, def)
    -- l'index de correspondance de BlizzTimeline est mis en cache par rencontre
    if NS.BlizzTimeline then
        NS.BlizzTimeline._index[encID] = nil
        NS.BlizzTimeline._byEventID[encID] = nil
    end
    -- le pont a posé ses sons à partir de l'ancienne définition : sans re-pose,
    -- les données fraîchement apprises n'atteignent pas le jeu
    if NS.EventBridge then NS.EventBridge:Refresh("apprentissage appliqué") end

    NS:Print(string.format("|cff8bd5ca%d capacité(s)|r appliquée(s) à la rencontre %d pour cette session%s.",
        #def.events, encID, skipped > 0 and string.format(" (%d écartée(s))", skipped) or ""))
    NS:Print("Rôle, sévérité et voix restent neutres : réglez-les avant publication.")
    return true
end

--------------------------------------------------------------------------
-- Génération du bloc Lua.
--------------------------------------------------------------------------
local function fmtNum(n)
    if n == math.floor(n) then return tostring(math.floor(n)) end
    return string.format("%.1f", n)
end

function Export:Emit(key, minQuality)
    local def, err, skipped = self:BuildDef(key, minQuality)
    if not def then return nil, err end

    local encID = tonumber(key) or 0
    local out = {}
    local function w(s) out[#out + 1] = s end

    w("-- Généré par TomoBoss (apprentissage) le " .. date("%Y-%m-%d %H:%M"))
    w("-- Source : observations de MES propres pulls. Aucune donnée tierce.")
    w("-- provenance = \"observed\" : suivi par /tmb learn provenance.")
    w("-- Identité = durée (le serveur ne livre ni nom ni GUID sous Midnight).")
    w("-- À RÉGLER avant publication : spellID, role, voice, severity, preAlertSec.")
    w("")
    w(string.format("R(%d, {", encID))
    w(string.format("    name = %q,", def.name))
    w('    provenance = "observed",')
    w(string.format("    dungeon = %q,", def.dungeon))
    w("    events = {")

    for _, ev in ipairs(def.events) do
        local sid = ev.spellID and tostring(ev.spellID) or "nil"
        local comment = string.format("  -- %s%s [%s, cycle %.0fs] spellID À RENSEIGNER",
            ev.__key,
            ev.__tlDur and string.format(" (timeline %.2fs)", ev.__tlDur) or " (hors timeline)",
            ev.__quality, ev.__cycle or 0)
        w(string.format(
            '        { role = "other", voice = "", spellID = %s, castType = %q, castDuration = %s, '
            .. 'firstSeenSec = %s, cdSeriesSec = { %s }, severity = 1 },%s',
            sid, ev.castType, fmtNum(ev.castDuration), fmtNum(ev.firstSeenSec),
            table.concat((function()
                local t = {}
                for i, v in ipairs(ev.cdSeriesSec) do t[i] = fmtNum(v) end
                return t
            end)(), ", "),
            comment))
    end

    w("    },")
    w("})")

    return table.concat(out, "\n"), nil, skipped
end

--------------------------------------------------------------------------
-- Fenêtre de copie.
--------------------------------------------------------------------------
function Export:ShowWindow(text, title)
    local f = self._win
    if not f then
        f = CreateFrame("Frame", "TomoBossLearnExport", UIParent, "BackdropTemplate")
        f:SetSize(620, 460)
        f:SetPoint("CENTER")
        f:SetFrameStrata("DIALOG")
        f:EnableMouse(true)
        f:SetMovable(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", f.StartMoving)
        f:SetScript("OnDragStop", f.StopMovingOrSizing)
        -- opts.border attend une COULEUR ({r,g,b}), pas un booléen : passer `true`
        -- ferait planter Skin à l'indexation. Défauts du thème = comportement voulu.
        NS.Theme:Skin(f, {})

        f.title = f:CreateFontString(nil, "OVERLAY")
        f.title:SetPoint("TOPLEFT", 12, -10)
        NS.Theme:Font(f.title, 14, "accent")

        f.hint = f:CreateFontString(nil, "OVERLAY")
        f.hint:SetPoint("TOPLEFT", 12, -30)
        NS.Theme:Font(f.hint, 11, "muted")
        f.hint:SetText("Ctrl+A puis Ctrl+C pour copier, puis collez dans Engine/Encounters/<donjon>.lua")

        local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", -4, -4)

        local scroll = CreateFrame("ScrollFrame", "TomoBossLearnExportScroll", f, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 12, -52)
        scroll:SetPoint("BOTTOMRIGHT", -32, 12)

        local eb = CreateFrame("EditBox", nil, scroll)
        eb:SetMultiLine(true)
        eb:SetFontObject("GameFontHighlightSmall")
        eb:SetWidth(560)
        eb:SetAutoFocus(false)
        eb:SetScript("OnEscapePressed", function() f:Hide() end)
        scroll:SetScrollChild(eb)
        f.edit = eb

        f:Hide()
    end
    f.title:SetText(title or "TomoBoss — export d'apprentissage")
    f.edit:SetText(text or "")
    f:Show()
    f.edit:SetFocus()
    f.edit:HighlightText()
end

function Export:ShowFor(key, minQuality)
    local text, err, skipped = self:Emit(key, minQuality)
    if not text then NS:Print("|cffe06c75" .. tostring(err) .. "|r"); return end
    self:ShowWindow(text, string.format("TomoBoss — rencontre %s (%d écartée(s))", tostring(key), skipped or 0))
end
