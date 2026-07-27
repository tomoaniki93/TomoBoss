-- Analyseur statique : comparaisons sur des valeurs potentiellement masquées.
--
-- Sous Midnight, TOUTE opération sur un secretvalue lève une erreur de taint —
-- y compris la comparaison censée l'écarter. Le piège est toujours le même :
--
--     if n and n ~= "" and not NS:IsSecret(n) then ...   -- plante
--     if NS:SafeString(n) then ...                       -- correct
--
-- Lua évalue `and` de gauche à droite : `n ~= ""` s'exécute AVANT le garde.
-- Cette erreur est passée deux fois (readCast, puis la résolution tardive du
-- nom de boss trois versions plus tard), d'où ce contrôle automatique.
--
-- Distinction essentielle, établie sur un rapport de plantage réel : dans
--     if n and n ~= "" and not NS:IsSecret(n) then
-- le test de véracité `n and` n'a PAS planté, seul `n ~= ""` a planté. Comparer
-- une valeur masquée à `nil` est donc sûr (types différents), la comparer à une
-- valeur du MÊME type ne l'est pas. On ne signale que le second cas — sans quoi
-- l'analyseur crierait sur `if x ~= nil and not IsSecret(x)`, qui est correct.
--
-- Lancer : lua5.1 Tools/test_taint.lua

local FILES = {
    "Core/Namespace.lua", "Engine/Timeline.lua", "Modules/BlizzTimeline.lua",
    "Modules/EventBridge.lua", "Learn/Store.lua", "Learn/Journal.lua",
    "Learn/Recorder.lua", "Learn/Infer.lua", "Learn/Export.lua",
    "Learn/Dump.lua", "Learn/Slash.lua", "Learn/Provenance.lua",
    "Debug/TimelineRecorder.lua", "Custom/Custom.lua",
}

-- Fonctions dont la valeur de retour peut être masquée par le serveur.
local TAINTED_SOURCES = {
    "UnitName", "UnitGUID", "UnitCastingInfo", "UnitChannelInfo",
    "GetEventInfo", "GetEventTimeRemaining",
}

local problems, scanned = 0, 0

for _, path in ipairs(FILES) do
    local f = io.open(path, "r")
    if f then
        local lineNo = 0
        for line in f:lines() do
            lineNo = lineNo + 1
            scanned = scanned + 1
            local code = line:gsub("%-%-.*$", "")   -- ignore les commentaires

            -- une ligne qui appelle IsSecret sur X ET compare X avant, dans la
            -- même expression, est suspecte
            local guarded = code:match("IsSecret%(%s*([%w_%.]+)%s*%)")
            if guarded then
                local before = code:sub(1, code:find("IsSecret") or 1)
                local pat = guarded:gsub("([%.%-])", "%%%1")
                -- opérande droite de la comparaison : nil est inoffensif
                local rhs = before:match(pat .. "%s*[~=<>]=%s*([%w_\"'%.]+)")
                        or before:match(pat .. "%s*[<>]%s*([%w_\"'%.]+)")
                if rhs and rhs ~= "nil" then
                    problems = problems + 1
                    print(("  %s:%d"):format(path, lineNo))
                    print(("     comparaison « %s %s ... » AVANT le garde IsSecret")
                        :format(guarded, rhs))
                    print("     -> " .. (line:gsub("^%s+", "")))
                end
            end

            -- affectation depuis une source masquable, puis comparaison directe
            for _, src in ipairs(TAINTED_SOURCES) do
                local var = code:match("local%s+([%w_]+)%s*=%s*" .. src .. "%(")
                if var then
                    local rest = code:match(src .. "%b()(.*)$") or ""
                    local pat = var:gsub("([%.%-])", "%%%1")
                    local rhs2 = rest:match(pat .. "%s*[~=]=%s*([%w_\"'%.]+)")
                    if rhs2 and rhs2 ~= "nil" then
                        problems = problems + 1
                        print(("  %s:%d"):format(path, lineNo))
                        print("     « " .. var .. " » vient de " .. src
                            .. "() et est comparé sans garde")
                        print("     -> " .. (line:gsub("^%s+", "")))
                    end
                end
            end
        end
        f:close()
    end
end

print(("\n%d ligne(s) analysée(s) sur %d fichiers."):format(scanned, #FILES))
if problems == 0 then
    print(">>> Aucune comparaison non gardée. Utiliser NS:SafeString / NS:SafeNumber.")
else
    print((">>> %d PROBLÈME(S) — corriger avec NS:SafeString / NS:SafeNumber."):format(problems))
end
os.exit(problems == 0 and 0 or 1)
