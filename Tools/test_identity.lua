-- TomoBoss — Tools/test_identity.lua
--
-- Prouve, sur les captures du joueur, quel champ d'une timeline peut servir de
-- CLÉ D'IDENTITÉ et lequel ne le peut pas.
--
-- Pourquoi ce test existe : la version 2.8.4 a ajouté l'identifiant d'événement
-- de C_EncounterTimeline au Store, sur l'idée qu'il désignait une capacité. Les
-- captures de raid montrent l'inverse — c'est un compteur de session. S'en
-- servir comme clé aurait produit des annonces fausses sans jamais lever
-- d'erreur, et la faute ne se voit pas à la lecture du code : elle ne se voit
-- que dans les données. D'où ce test.
--
--   lua5.4 Tools/test_identity.lua <chemin/vers/TomoBoss.lua>
--
-- Sortie : une ligne par assertion, code de retour non nul au premier échec.

local svPath = ...
if not svPath then
    io.stderr:write("usage : lua5.4 Tools/test_identity.lua <SavedVariables/TomoBoss.lua>\n")
    os.exit(2)
end

local chunk, err = loadfile(svPath)
if not chunk then
    io.stderr:write("lecture impossible : ", tostring(err), "\n")
    os.exit(2)
end
chunk()

local pulls = TomoBossDB and TomoBossDB.profile
    and TomoBossDB.profile.learn and TomoBossDB.profile.learn.pulls
if not pulls then
    io.stderr:write("learn.pulls introuvable dans ", svPath, "\n")
    os.exit(2)
end

local KIND_TIMELINE = 3
local I_KIND, I_DUR, I_EVID = 2, 3, 8

local fails, checks = 0, 0
local function check(ok, label, detail)
    checks = checks + 1
    if ok then
        print(string.format("  ok   %s", label))
    else
        fails = fails + 1
        print(string.format("  ÉCHEC %s%s", label, detail and ("  — " .. detail) or ""))
    end
end

--------------------------------------------------------------------------
-- Collecte
--------------------------------------------------------------------------
-- Une rencontre n'entre dans le test que si elle porte des identifiants
-- d'événement sur au moins deux pulls : avant 2.8.4 le champ n'existait pas, et
-- un seul pull ne peut rien dire d'une répétition.
local usable = {}
for encID, list in pairs(pulls) do
    local withEv = {}
    for _, p in ipairs(list) do
        local ev, dur = {}, {}
        for _, o in ipairs(p.obs or {}) do
            if o[I_KIND] == KIND_TIMELINE then
                if o[I_EVID] then ev[#ev + 1] = o[I_EVID] end
                if o[I_DUR] then dur[#dur + 1] = o[I_DUR] end
            end
        end
        if #ev > 0 then
            withEv[#withEv + 1] = { date = p.date, ev = ev, dur = dur }
        end
    end
    if #withEv >= 2 then usable[tonumber(encID) or encID] = withEv end
end

local nUsable = 0
for _ in pairs(usable) do nUsable = nUsable + 1 end

print(string.format("captures : %s", svPath))
print(string.format("rencontres avec identifiant d'événement sur >= 2 pulls : %d\n", nUsable))

if nUsable == 0 then
    print("  (rien à tester — capture antérieure à 2.8.4)")
    os.exit(0)
end

--------------------------------------------------------------------------
-- 1. Un identifiant qui revient ne désigne pas la même capacité.
--
-- C'est l'assertion décisive. L'identifiant revient parfois d'un pull à l'autre
-- — le compteur repart de zéro au /reload ou au changement d'instance — et cette
-- réapparition est précisément le piège : elle ressemble à une identité stable.
-- Si c'en était une, la durée portée serait la même. Elle ne l'est pas.
--
-- Relevé sur la rencontre 2125, pulls 7 et 8 : les identifiants 45 à 52 portent
-- 13/36/5/25/44/49 d'un côté et 36/5/25/44/49/13 de l'autre — la même séquence
-- décalée d'un cran, parce que le compteur avance avec les événements et que les
-- deux pulls n'en ont pas vu le même nombre.
--------------------------------------------------------------------------
print("1. un identifiant qui revient ne porte pas la même capacité")
local same, differ, firstEx = 0, 0, nil
for encID, list in pairs(usable) do
    local byEv = {}
    for pi, p in ipairs(list) do
        for i = 1, #p.ev do
            local e = p.ev[i]
            byEv[e] = byEv[e] or {}
            if byEv[e][pi] == nil then byEv[e][pi] = p.dur[i] end
        end
    end
    for e, perPull in pairs(byEv) do
        local n, ref, uniform = 0, nil, true
        for _, d in pairs(perPull) do
            n = n + 1
            if ref == nil then ref = d elseif d ~= ref then uniform = false end
        end
        if n >= 2 then
            if uniform then same = same + 1 else
                differ = differ + 1
                if not firstEx then
                    local parts = {}
                    for pi, d in pairs(perPull) do
                        parts[#parts + 1] = string.format("pull %d : %s", pi, tostring(d))
                    end
                    table.sort(parts)
                    firstEx = string.format("rencontre %s, id %d — %s",
                        tostring(encID), e, table.concat(parts, " / "))
                end
            end
        end
    end
end
check(differ > same,
    string.format("%d identifiant(s) réapparus portent une AUTRE durée, %d la même", differ, same),
    firstEx)
if firstEx then print("       exemple : " .. firstEx) end

--------------------------------------------------------------------------
-- 2. La numérotation CONTINUE d'un pull au suivant.
--
-- C'est la signature d'un compteur : le pull suivant reprend au-dessus du
-- maximum du précédent au lieu de repartir de zéro.
--------------------------------------------------------------------------
print("\n2. la numérotation continue d'un pull au suivant (signature d'un compteur)")
local continues, restarts = 0, 0
for _, list in pairs(usable) do
    for i = 2, #list do
        local prevMax = -math.huge
        for _, e in ipairs(list[i - 1].ev) do if e > prevMax then prevMax = e end end
        local curMin = math.huge
        for _, e in ipairs(list[i].ev) do if e < curMin then curMin = e end end
        if curMin > prevMax then continues = continues + 1 else restarts = restarts + 1 end
    end
end
check(continues > 0,
    string.format("%d enchaînement(s) de pulls reprennent la numérotation (%d repartent plus bas)",
        continues, restarts))

--------------------------------------------------------------------------
-- 3. La DURÉE, elle, se répète.
--
-- C'est le contre-exemple qui donne son sens aux deux premiers : la clé
-- utilisée par BT:BuildMatchIndex est bien stable d'un pull à l'autre, sur les
-- mêmes captures où l'identifiant d'événement ne l'est pas.
--------------------------------------------------------------------------
print("\n3. la durée, elle, se répète d'un pull à l'autre")
local shared, isolated = 0, 0
for _, list in pairs(usable) do
    local first = {}
    for _, d in ipairs(list[1].dur) do first[d] = true end
    local hit = false
    for i = 2, #list do
        for _, d in ipairs(list[i].dur) do if first[d] then hit = true break end end
        if hit then break end
    end
    if hit then shared = shared + 1 else isolated = isolated + 1 end
end
check(shared > isolated,
    string.format("%d rencontre(s) partagent des durées entre pulls, %d n'en partagent aucune",
        shared, isolated))

--------------------------------------------------------------------------
-- 4. Aucun fichier de rencontre ne doit porter d'eventID venu d'une capture.
--
-- Les eventID présents dans Engine/Encounters/ viennent de la table tenue à la
-- main (source EventBridge). Ce test ne peut pas distinguer les deux origines ;
-- il rappelle seulement l'invariant, et échoue si le générateur se met un jour
-- à recopier le champ du Store.
--------------------------------------------------------------------------
print("\n4. rappel d'invariant")
print("  note  un eventID de capture ne doit jamais être écrit dans Engine/Encounters/ :")
print("        seuls les identifiants de l'EventBridge y ont leur place.")

print(string.format("\n%d assertion(s), %d échec(s)", checks, fails))
os.exit(fails > 0 and 1 or 0)
