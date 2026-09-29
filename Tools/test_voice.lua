-- TomoBoss — Tools/test_voice.lua
--
-- Vérifie que toute annonce référencée peut réellement être jouée.
--
-- Trois façons de rendre une voix muette sans qu'aucune erreur ne se produise :
--
--   1. une rencontre qui cite un `voice` absent du catalogue — Voice:Resolve
--      renvoie nil, l'annonce ne part pas, seul un message de debug le dit ;
--   2. une entrée du catalogue dont le .ogg manque dans un pack — LSM:Fetch
--      rend le chemin ENREGISTRÉ sans regarder le disque, donc le repli vers le
--      pack par défaut de Voice/Engine.lua ne se déclenche jamais dans ce cas :
--      il ne couvre que le pack non enregistré ;
--   3. deux clés qui pointent le même fichier — le catalogue croit offrir deux
--      annonces, le joueur en entend une seule.
--
-- Les trois sont silencieuses en jeu. Elles ne le sont pas ici.
--
--   lua5.4 Tools/test_voice.lua        (depuis la racine de l'addon)

local PACKS = { "enUS", "frFR" }

local NS = { Engine = { Encounters = {} }, Voice = {} }
function NS.Engine:RegisterEncounter(id, def) self.Encounters[id] = def end

assert(loadfile("Voice/Catalog.lua"))("TomoBoss", NS)
local Catalog = assert(NS.Voice.Catalog, "catalogue introuvable")

-- Toutes les rencontres du dépôt, quel que soit le fichier qui les porte.
local encFiles = {}
do
    local p = io.popen("ls Engine/Encounters/*.lua 2>/dev/null")
    if p then
        for line in p:lines() do encFiles[#encFiles + 1] = line end
        p:close()
    end
end
for _, f in ipairs(encFiles) do
    local chunk = loadfile(f)
    if chunk then pcall(chunk, "TomoBoss", NS) end
end

local fails, checks = 0, 0
local function check(ok, label, detail)
    checks = checks + 1
    if ok then
        print(string.format("  ok    %s", label))
    else
        fails = fails + 1
        print(string.format("  ÉCHEC %s%s", label, detail and ("\n        " .. detail) or ""))
    end
end

local function exists(path)
    local fh = io.open(path, "rb")
    if fh then fh:close() return true end
    return false
end

--------------------------------------------------------------------------
print("1. toute voix citée par une rencontre existe au catalogue")
local unknown, nRef = {}, 0
for encID, def in pairs(NS.Engine.Encounters) do
    for _, ev in ipairs(def.events or {}) do
        if ev.voice and ev.voice ~= "" then
            nRef = nRef + 1
            if not Catalog[ev.voice] then
                unknown[#unknown + 1] = string.format("%s (rencontre %s)", ev.voice, tostring(encID))
            end
        end
    end
end
check(#unknown == 0,
    string.format("%d références de voix vérifiées", nRef),
    #unknown > 0 and table.concat(unknown, "\n        ") or nil)

--------------------------------------------------------------------------
print("\n2. chaque entrée du catalogue a son fichier dans TOUS les packs livrés")
local missing, nEntries = {}, 0
for id, e in pairs(Catalog) do
    nEntries = nEntries + 1
    for _, lang in ipairs(PACKS) do
        if not exists("Media/Voice/" .. lang .. "/" .. e.file) then
            missing[#missing + 1] = lang .. "/" .. e.file .. "  (clé " .. id .. ")"
        end
    end
end
check(#missing == 0,
    string.format("%d entrées × %d packs", nEntries, #PACKS),
    #missing > 0 and table.concat(missing, "\n        ", 1, math.min(#missing, 12)) or nil)

--------------------------------------------------------------------------
print("\n3. aucun fichier partagé par deux clés")
local byFile, shared = {}, {}
for id, e in pairs(Catalog) do
    byFile[e.file] = byFile[e.file] or {}
    table.insert(byFile[e.file], id)
end
for f, ids in pairs(byFile) do
    if #ids > 1 then
        table.sort(ids)
        shared[#shared + 1] = f .. " : " .. table.concat(ids, ", ")
    end
end
check(#shared == 0, "un fichier par clé",
    #shared > 0 and table.concat(shared, "\n        ") or nil)

--------------------------------------------------------------------------
-- Rapport, pas assertion : une durée partagée par deux événements d'une même
-- rencontre est un choix assumé (BlizzTimeline retombe alors sur l'alerte
-- générique plutôt que de deviner). On les compte pour que le nombre se voie
-- bouger quand une entrée est ajoutée ou séparée.
print("\n4. durées ambiguës par rencontre (rapport — repli générique attendu)")
local amb = 0
for encID, def in pairs(NS.Engine.Encounters) do
    local seen = {}
    for _, ev in ipairs(def.events or {}) do
        for _, d in ipairs(ev.cdSeriesSec or {}) do
            if seen[d] then amb = amb + 1 else seen[d] = true end
        end
    end
end
print(string.format("  %d durée(s) partagée(s) par plusieurs événements d'une même rencontre", amb))

print(string.format("\n%d assertion(s), %d échec(s)", checks, fails))
os.exit(fails > 0 and 1 or 0)
