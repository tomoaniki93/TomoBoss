-- TomoBoss — Tools/raid_worksheet.lua
--
-- Produit le relevé de correspondance d'un raid : pour chaque rencontre, les
-- durées de timeline réellement observées, leur place dans le cycle, et la
-- liste des capacités du journal avec leur rôle.
--
-- Les captures donnent le minutage, le journal donne l'identité, et rien ne les
-- relie automatiquement en raid (voir Tools/test_identity.lua). Ce relevé met
-- les deux colonnes côte à côte pour que la jointure se fasse à la main, une
-- fois, sur des chiffres mesurés plutôt que de mémoire.
--
--   lua5.4 Tools/raid_worksheet.lua <chemin/vers/TomoBoss.lua>

local svPath = ... or "TomoBoss.lua"
assert(loadfile(svPath))()
local pulls = TomoBossDB.profile.learn.pulls
local enc   = TomoBossDB.journal.encounters
local MIN_SEEN = 3

local ORDER = {
  {3497,"L'expedition perdue"},{3455,"Vashnik le Malveillant"},{3470,"Nek'zali l'Entortillame"},
  {3421,"Les crochets jumeaux"},{3420,"Sszorak"},{3445,"Sentinelles inhumees"},
  {3429,"L'Autel annele"},{3492,"Ula'tek"},
}

-- Detection de cycle : on cherche le decalage C qui superpose le mieux la
-- sequence des instants de declenchement sur elle-meme.
local function findCycle(rows)
  if #rows < 8 then return nil end
  local span = rows[#rows].f - rows[1].f
  local hi = math.floor(span * 0.6)
  if hi < 20 then return nil end
  local best, bestScore
  for c = 20, hi do
    local hit, n = 0, 0
    for _, a in ipairs(rows) do
      if a.f + c <= rows[#rows].f + 1.5 then
        n = n + 1
        for _, b in ipairs(rows) do
          -- meme duree ET meme place : un cycle doit reproduire la capacite,
          -- pas seulement un instant. Sans ca, tout petit decalage marque.
          if b.d == a.d and math.abs(b.f - (a.f + c)) <= 2.5 then hit = hit + 1; break end
        end
      end
    end
    local score = n > 0 and hit / n or 0
    if not bestScore or score > bestScore then best, bestScore = c, score end
  end
  if not bestScore or bestScore < 0.30 then return nil end
  -- le plus petit cycle qui explique presque aussi bien : un multiple du vrai
  -- cycle marque tout aussi fort, on veut la periode fondamentale.
  for c = 20, best do
    local hit, n = 0, 0
    for _, a in ipairs(rows) do
      if a.f + c <= rows[#rows].f + 1.5 then
        n = n + 1
        for _, b in ipairs(rows) do
          if b.d == a.d and math.abs(b.f - (a.f + c)) <= 2.5 then hit = hit + 1; break end
        end
      end
    end
    if n > 0 and hit / n >= bestScore - 0.03 then return c, hit / n end
  end
  return best, bestScore
end

local out = {}
local function w(f, ...) out[#out+1] = select("#", ...) > 0 and string.format(f, ...) or f end

w("# L'Abîme Venimeux — relevé de correspondance")
w("")
w("Généré depuis %s. Instance 3004, 8 rencontres.", svPath)
w("")
w("Les captures donnent le MINUTAGE, et il est bon. Elles ne donnent aucune")
w("IDENTITÉ : en raid sous Midnight le nom serveur et le GUID du lanceur sont")
w("masqués, et l'identifiant d'événement de `C_EncounterTimeline` est un compteur")
w("de session — un identifiant qui réapparaît porte une autre capacité dans 198")
w("cas sur 292 (`Tools/test_identity.lua`).")
w("")
w("Le relevé de journal (`/tmb journal`) porte l'inverse : l'identité et le rôle,")
w("aucun minutage. Le pont entre les deux se fait à la main — pour chaque durée")
w("ci-dessous, écrire la capacité correspondante dans la dernière colonne.")
w("")
w("Une durée sans nom n'apporte rien : BlizzTimeline sait déjà afficher une barre")
w("générique avec la sévérité que le serveur donne. Ce qu'une définition ajoute,")
w("c'est le nom, le rôle et la voix — donc l'identité, et rien d'autre.")
w("")

for _, e in ipairs(ORDER) do
  local id, nm = e[1], e[2]
  local list = pulls[tostring(id)] or pulls[id] or {}
  -- agregat toutes captures
  local dur, tot = {}, 0
  for _, p in ipairs(list) do
    for _, o in ipairs(p.obs or {}) do
      if o[2] == 3 then tot = tot + 1; dur[o[3]] = (dur[o[3]] or 0) + 1 end
    end
  end
  -- pull de reference
  local ref, rn = nil, -1
  for _, p in ipairs(list) do
    local n = 0
    for _, o in ipairs(p.obs or {}) do if o[2] == 3 then n = n + 1 end end
    if n > rn then ref, rn = p, n end
  end
  local rows = {}
  for _, o in ipairs(ref.obs or {}) do
    if o[2] == 3 then rows[#rows+1] = { f = o[6] or o[1] or 0, d = o[3] } end
  end
  table.sort(rows, function(a,b) return a.f < b.f end)
  local cyc, score = findCycle(rows)

  local kept = {}
  for d, c in pairs(dur) do if c >= MIN_SEEN then kept[#kept+1] = d end end
  table.sort(kept)
  local keptObs = 0
  for _, d in ipairs(kept) do keptObs = keptObs + dur[d] end

  w("")
  w("## %d — %s", id, (list[1] and list[1].name) or nm)
  w("")
  local kills, wipes = 0, 0
  for _, p in ipairs(list) do
    if p.outcome == "kill" then kills = kills + 1 elseif p.outcome == "wipe" then wipes = wipes + 1 end
  end
  w("%d pull(s), %d kill(s), %d wipe(s) — %d événements de timeline capturés.",
    #list, kills, wipes, tot)
  if cyc and score >= 0.6 then
    w("Cycle détecté : **%d s** (%.0f%% des déclenchements le reproduisent à l’identique).", cyc, score * 100)
  elseif cyc then
    w("Cycle **partiel** : %d s, reproduit par %.0f%% des déclenchements — le combat répète"
      .. " son schéma puis en change (phases).", cyc, score * 100)
  else
    w("**Aucun cycle stable** — le minutage ne se reproduit pas.")
  end
  w("%d durées distinctes, dont **%d vues au moins %d fois** (%.0f%% des observations).",
    (function() local n = 0 for _ in pairs(dur) do n = n + 1 end return n end)(), #kept, MIN_SEEN,
    tot > 0 and keptObs / tot * 100 or 0)
  w("")
  w("| durée | vue | position(s) dans le cycle | capacité (à remplir) |")
  w("|------:|----:|---------------------------|----------------------|")
  for _, d in ipairs(kept) do
    local pos = {}
    local seenPos = {}
    for _, r in ipairs(rows) do
      if r.d == d then
        local p = cyc and (r.f % cyc) or r.f
        p = math.floor(p + 0.5)
        local dup = false
        for _, q in ipairs(seenPos) do if math.abs(q - p) <= 2 then dup = true break end end
        if not dup then seenPos[#seenPos+1] = p; pos[#pos+1] = p .. "s" end
      end
    end
    table.sort(pos, function(a,b) return tonumber(a:match("%d+")) < tonumber(b:match("%d+")) end)
    w("| %s | %d | %s | |", tostring(d), dur[d],
      #pos > 0 and table.concat(pos, ", ") or "—")
  end
  w("")
  -- capacites du journal, filtrees
  local je = enc[id] or enc[tostring(id)]
  if je then
    w("Capacités au journal (%d sections brutes, doublons de difficulté retirés) :", #(je.abilities or {}))
    w("")
    local seen = {}
    for _, a in ipairs(je.abilities or {}) do
      local f = {}
      for _, v in ipairs(a.flags or {}) do f[v] = true end
      if not f.heroic and not f.mythic and (a.depth or 1) <= 2 and a.title and not seen[a.title] then
        seen[a.title] = true
        local role = f.tank and "TANK" or f.healer and "SOIN" or f.interruptible and "INTERRUPT"
          or f.dps and "DPS" or ""
        local sev = f.deadly and "MORTEL" or f.important and "IMPORTANT" or ""
        local tag = (role ~= "" or sev ~= "")
          and ("  [" .. role .. (role ~= "" and sev ~= "" and " / " or "") .. sev .. "]") or ""
        w("- `%s`  %s%s", tostring(a.spellID), a.title, tag)
      end
    end
  end
end

local outPath = "RELEVE-ABIME-VENIMEUX.md"
local fh = io.open(outPath, "w")
fh:write(table.concat(out, "\n"), "\n")
fh:close()
print("écrit : " .. outPath .. " (" .. #out .. " lignes)")
