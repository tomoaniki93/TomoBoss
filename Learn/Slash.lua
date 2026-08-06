---@diagnostic disable: undefined-global
-- TomoBoss — Apprentissage / Commandes.
-- Point d'entrée /tmb learn. L'IHM viendra ensuite ; en attendant tout le
-- système est pilotable au clavier, ce qui suffit pour produire des données.

local NS = select(2, ...)
local Learn = NS.Learn

local Store  = Learn.Store
local Infer  = Learn.Infer
local Export = Learn.Export

local function help()
    NS:Print("|cff8bd5caApprentissage TomoBoss|r — construit tes données depuis tes propres pulls.")
    NS:Print("  |cff8bd5ca/tmb learn|r                    état et rencontres en base")
    NS:Print("  |cff8bd5ca/tmb learn on|off|r             activer / couper l'enregistrement")
    NS:Print("  |cff8bd5ca/tmb learn dump <clé> [n]|r     capture BRUTE du pull (fenêtre copiable)")
    NS:Print("  |cff8bd5ca/tmb learn dumpc <clé> [n]|r    idem, dans le chat")
    NS:Print("  |cff8bd5ca/tmb learn show <clé>|r         rapport d'analyse détaillé")
    NS:Print("  |cff8bd5ca/tmb learn apply <clé> [seuil]|r  appliquer pour la session (test immédiat)")
    NS:Print("  |cff8bd5ca/tmb learn export <clé> [seuil]|r bloc Lua à coller dans Engine/Encounters/")
    NS:Print("  |cff8bd5ca/tmb learn rekey <clé> <encID>|r  relier une clé synthétique à un encounterID")
    NS:Print("  |cff8bd5ca/tmb learn clear [clé]|r        effacer une rencontre (ou tout)")
    NS:Print("  |cff8bd5ca/tmb learn purge|r               effacer les rencontres hors contenu couvert")
    NS:Print("  |cff8bd5ca/tmb learn journal [clé|nom]|r  diagnostic de résolution des noms")
    NS:Print("  |cff8bd5ca/tmb learn provenance [tout]|r  d'où viennent mes données de minutage")
    NS:Print("  seuil = |cff8bd5cafaible|r | |cff8bd5camoyen|r (défaut) | |cff8bd5cabon|r")
end

local function status()
    local db = NS.db.profile.learn
    local keys = Store:Keys()
    NS:Print("Enregistrement : " .. (db.enabled and "|cff8bd5caactif|r" or "|cffe06c75coupé|r")
        .. string.format("  —  %d observation(s) en base", Store:ApproxSize()))
    if #keys == 0 then
        NS:Print("Aucun pull enregistré. Fais un boss, les données arrivent toutes seules.")
        return
    end
    local known, foreign = {}, {}
    for _, k in ipairs(keys) do
        local list = Store:GetPulls(k)
        if list then
            local id = tonumber(k)
            -- Le nom vient de l'enregistrement (ENCOUNTER_START le fournit
            -- localisé). Le Journal ne peut PAS le donner : sa table ne relie
            -- pas les JournalEncounterID aux DungeonEncounterID.
            local name = list[1].name or list[1].boss
            local kills = 0
            for _, p in ipairs(list) do if p.outcome == "kill" then kills = kills + 1 end end
            local inst = list[1].inst
            -- une rencontre que le moteur connaît est du contenu visé ; les
            -- autres sont probablement des restes d'ancien contenu ou de
            -- rencontres enregistrées avant le filtre de périmètre.
            local entry = {
                -- « ? » : capture antérieure à l'enregistrement du nom.
                k = k, name = name, inst = inst,
                n = #list, kills = kills,
                mine = NS.Engine:GetEncounter(id) ~= nil,
            }
            if entry.mine then known[#known + 1] = entry else foreign[#foreign + 1] = entry end
        end
    end

    local function show(e)
        NS:Print(string.format("  |cff8bd5ca%s|r  %-26s inst %-6s — %d pull(s), %d kill(s)",
            e.k, tostring(e.name or "?"), tostring(e.inst or "?"), e.n, e.kills))
    end
    for _, e in ipairs(known) do show(e) end
    if #foreign > 0 then
        NS:Print(string.format("|cffe8c07d%d rencontre(s) hors du contenu couvert|r "
            .. "(ancien contenu, ou enregistrées avant le filtre de périmètre) :", #foreign))
        for _, e in ipairs(foreign) do show(e) end
        NS:Print("  Nettoyage : |cff8bd5ca/tmb learn purge|r")
    end
    NS:Print("Détail : |cff8bd5ca/tmb learn show <clé>|r")
end

function Learn:HandleSlash(rest)
    local sub, arg1, arg2 = tostring(rest or ""):match("^(%S*)%s*(%S*)%s*(%S*)$")

    if sub == "" then
        status()
    elseif sub == "on" or sub == "off" then
        NS.db.profile.learn.enabled = (sub == "on")
        -- réarme le rappel : couper puis oublier de rallumer est le cas visé
        Learn.Recorder._warnedOff = nil
        NS:Print("Enregistrement " .. (sub == "on" and "|cff8bd5caactivé|r" or "|cffe06c75coupé|r") .. ".")
        if sub == "off" then
            NS:Print("Un rappel s'affichera au prochain boss de donjon ou de raid.")
        end
    elseif sub == "dump" then
        if arg1 == "" then NS:Print("Précise une clé. |cff8bd5ca/tmb learn|r pour la liste."); return end
        NS.Learn.Dump:Show(arg1, arg2 ~= "" and arg2 or nil)
    elseif sub == "dumpc" then
        if arg1 == "" then NS:Print("Précise une clé."); return end
        NS.Learn.Dump:Print(arg1, arg2 ~= "" and arg2 or nil)
    elseif sub == "journal" then
        -- accepte une clé (le nom est alors lu dans la capture) ou un nom direct
        local probe = arg1 ~= "" and arg1 or nil
        if probe and tonumber(probe) then
            local l = Store:GetPulls(probe)
            probe = l and l[1] and (l[1].name or l[1].boss) or nil
            if not probe then NS:Print("Cette capture ne porte pas de nom de rencontre.") end
        end
        Learn.Journal:Diagnose(probe)
    elseif sub == "purge" then
        local removed = {}
        for _, k in ipairs(Store:Keys()) do
            local id = tonumber(k)
            if not id or not NS.Engine:GetEncounter(id) then
                removed[#removed + 1] = k
                Store:Clear(k)
            end
        end
        if #removed == 0 then
            NS:Print("Rien à purger : toutes les rencontres sont dans le contenu couvert.")
        else
            NS:Print(string.format("%d rencontre(s) effacée(s) : %s",
                #removed, table.concat(removed, ", ")))
        end
    elseif sub == "prune" then
        local n = Store:PruneLegacy()
        NS:Print(string.format("%d capture(s) de schéma périmé supprimée(s).", n))
    elseif sub == "show" or sub == "voir" then
        if arg1 == "" then NS:Print("Précise une clé. |cff8bd5ca/tmb learn|r pour la liste."); return end
        Infer:PrintReport(arg1)
    elseif sub == "apply" or sub == "appliquer" then
        if arg1 == "" then NS:Print("Précise une clé."); return end
        Export:Apply(arg1, arg2 ~= "" and arg2 or nil)
    elseif sub == "export" then
        if arg1 == "" then NS:Print("Précise une clé."); return end
        Export:ShowFor(arg1, arg2 ~= "" and arg2 or nil)
    elseif sub == "rekey" or sub == "relier" then
        if arg1 == "" or tonumber(arg2) == nil then
            NS:Print("Usage : |cff8bd5ca/tmb learn rekey <clé> <encounterID>|r")
            return
        end
        if Store:Rekey(arg1, tonumber(arg2)) then
            NS:Print(string.format("Clé |cff8bd5ca%s|r reliée à la rencontre %s.", arg1, arg2))
        else
            NS:Print("|cffe06c75Clé inconnue.|r")
        end
    elseif sub == "provenance" then
        NS.Learn.Provenance:Print(arg1 == "tout" or arg1 == "all")
    elseif sub == "clear" or sub == "effacer" then
        if arg1 == "" then
            Store:Clear()
            NS:Print("|cffe06c75Toutes|r les observations ont été effacées.")
        else
            Store:Clear(arg1)
            NS:Print("Observations effacées pour " .. arg1 .. ".")
        end
    else
        help()
    end
end
