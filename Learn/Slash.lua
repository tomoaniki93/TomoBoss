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
    NS:Print("  |cff8bd5ca/tmb learn show <clé>|r         rapport d'analyse détaillé")
    NS:Print("  |cff8bd5ca/tmb learn apply <clé> [seuil]|r  appliquer pour la session (test immédiat)")
    NS:Print("  |cff8bd5ca/tmb learn export <clé> [seuil]|r bloc Lua à coller dans Engine/Encounters/")
    NS:Print("  |cff8bd5ca/tmb learn rekey <clé> <encID>|r  relier une clé synthétique à un encounterID")
    NS:Print("  |cff8bd5ca/tmb learn clear [clé]|r        effacer une rencontre (ou tout)")
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
    for _, k in ipairs(keys) do
        local list = Store:GetPulls(k)
        local label = tonumber(k) and (Learn.Journal:EncounterName(tonumber(k)) or k) or (list[1].boss or k)
        local kills = 0
        for _, p in ipairs(list) do if p.outcome == "kill" then kills = kills + 1 end end
        NS:Print(string.format("  |cff8bd5ca%s|r  %s  — %d pull(s), %d kill(s)%s",
            k, tostring(label), #list, kills,
            Store:IsSynthetic(k) and "  |cffe8c07d(clé à relier)|r" or ""))
    end
    NS:Print("Détail : |cff8bd5ca/tmb learn show <clé>|r")
end

function Learn:HandleSlash(rest)
    local sub, arg1, arg2 = tostring(rest or ""):match("^(%S*)%s*(%S*)%s*(%S*)$")

    if sub == "" then
        status()
    elseif sub == "on" or sub == "off" then
        NS.db.profile.learn.enabled = (sub == "on")
        NS:Print("Enregistrement " .. (sub == "on" and "|cff8bd5caactivé|r" or "|cffe06c75coupé|r") .. ".")
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
