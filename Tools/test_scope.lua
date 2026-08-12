-- Analyseur statique : `local` utilisé AVANT sa ligne de déclaration.
--
-- En Lua, un `local` n'existe qu'à partir de la ligne où il est déclaré. Une
-- fonction écrite plus haut dans le fichier qui le référence ne voit donc pas
-- cette variable : elle lit un GLOBAL nil, au moment de l'exécution seulement.
--
-- Le fichier compile, l'analyse de syntaxe ne dit rien, et l'erreur ne survient
-- qu'à l'exécution — en cassant tout ce qui suit. Cas réel : une constante de
-- période déclarée ligne 260 et utilisée ligne 96 rendait C_Timer.NewTicker(nil)
-- et interrompait toute l'initialisation de l'addon, /tmb compris.
--
-- Lancer : lua5.1 Tools/test_scope.lua

local function files()
    local out = {}
    local p = io.popen("find . -name '*.lua' -not -path './Libs/*' -not -path './Tools/*'")
    if not p then return out end
    for line in p:lines() do out[#out + 1] = line end
    p:close()
    return out
end

local problems, scanned = 0, 0

for _, path in ipairs(files()) do
    local f = io.open(path, "r")
    if f then
        local lines = {}
        for line in f:lines() do lines[#lines + 1] = line end
        f:close()
        scanned = scanned + 1

        -- constantes locales de fichier : `local NOM = ...` en colonne 0
        local decl = {}
        for i, line in ipairs(lines) do
            local name = line:match("^local%s+([%u][%u%d_]+)%s*=")
            if name and not decl[name] then decl[name] = i end
        end

        for name, declLine in pairs(decl) do
            for i = 1, declLine - 1 do
                local code = lines[i]:gsub("%-%-.*$", "")
                -- usage du nom, hors déclaration elle-même
                if code:match("[^%w_]" .. name .. "[^%w_]") or code:match("^" .. name .. "[^%w_]") then
                    problems = problems + 1
                    print(("  %s:%d"):format(path, i))
                    print(("     « %s » utilisé ici, mais déclaré ligne %d -> vaut nil"):format(name, declLine))
                    print("     -> " .. (lines[i]:gsub("^%s+", "")))
                    break
                end
            end
        end
    end
end

print(("\n%d fichier(s) analysé(s)."):format(scanned))
if problems == 0 then
    print(">>> Aucune constante utilisée avant sa déclaration.")
else
    print((">>> %d PROBLEME(S) — deplacer la declaration au-dessus du premier usage."):format(problems))
end
os.exit(problems == 0 and 0 or 1)
