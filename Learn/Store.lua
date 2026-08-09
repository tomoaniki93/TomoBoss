---@diagnostic disable: undefined-global
-- TomoBoss — Apprentissage / Stockage.
--
-- Conserve les observations brutes de combat, par rencontre et par pull.
-- Aucune interprétation ici : le Store ne fait qu'accumuler et élaguer.
-- L'agrégation est faite hors combat par Learn/Infer.lua.
--
-- Format compact (les SavedVariables sont relues à chaque /reload) :
-- SCHÉMA v2 — l'identité n'est plus un NOM (illisible sous Midnight) mais le
-- couple (npcID, durée mesurée), plus la durée-identité de la timeline.
--
--   obs[i] = { t, kind, dur, npc, unit, fire, sname }
--     t     : secondes depuis le début du pull (2 décimales)
--     kind  : 1 incantation | 2 canalisation | 3 timeline | 4 instantané | 5 interrompu
--     dur   : durée MESURÉE au chronomètre (kind 1/2/5), durée-identité (kind 3), 0 (kind 4)
--     npc   : npcID du lanceur, extrait de UnitGUID (nil pour la timeline)
--     unit  : jeton d'unité — diagnostic, permet de voir d'où vient une observation
--     fire  : kind 3 uniquement — instant prévu de déclenchement, depuis t0
--     sname : nom serveur, UNIQUEMENT quand il est lisible. Bonus, jamais une dépendance.

local NS = select(2, ...)
local Store = {}
NS.Learn = NS.Learn or {}
NS.Learn.Store = Store

Store.KIND_CAST        = 1
Store.KIND_CHANNEL     = 2
Store.KIND_TIMELINE    = 3
Store.KIND_INSTANT     = 4
Store.KIND_INTERRUPTED = 5

Store.KIND_NAME = { "incantation", "canalisation", "timeline", "instantané", "interrompu" }

-- Version de schéma. Les pulls d'une autre version sont ignorés à la lecture :
-- la v1 enregistrait des noms de sorts du joueur, ces données sont inutilisables.
Store.SCHEMA = 2

local MAX_PULLS_PER_ENC   = 12   -- au-delà, on jette le plus ancien
local MAX_OBS_PER_PULL    = 400  -- garde-fou anti-boucle folle
local MIN_OBS_TO_KEEP     = 4    -- un pull avec moins que ça n'apprend rien

--------------------------------------------------------------------------
-- Accès à la base.
--------------------------------------------------------------------------
function Store:DB()
    local db = NS.db.profile.learn
    db.pulls = db.pulls or {}
    return db
end

-- Clé de rencontre. On préfère l'encounterID réel ; à défaut une clé synthétique
-- « i<instanceMapID>:<nom du boss> » que l'utilisateur pourra relier plus tard.
function Store:MakeKey(encounterID, instanceID, npcID)
    if encounterID then return tostring(encounterID) end
    -- clé de repli bâtie sur le npcID (lisible et stable) et non sur un nom localisé
    return "i" .. tostring(instanceID or 0) .. ":n" .. tostring(npcID or 0)
end

function Store:IsSynthetic(key)
    return type(key) == "string" and key:sub(1, 1) == "i"
end

--------------------------------------------------------------------------
-- Cycle de vie d'un pull.
--------------------------------------------------------------------------

-- Ouvre un pull en mémoire. Rien n'est écrit en base avant Commit().
function Store:BeginPull(key, meta)
    self.current = {
        key   = key,
        t0    = GetTime(),
        meta  = meta or {},
        obs   = {},
        over  = false,
    }
    return self.current
end

function Store:Abort()
    self.current = nil
end

function Store:IsRecording()
    return self.current ~= nil
end

-- Ajoute une observation au pull courant. Coût constant, appelable en combat.
function Store:Add(kind, dur, npc, unit, fire, sname)
    local cur = self.current
    if not cur or cur.over then return end
    local n = #cur.obs
    if n >= MAX_OBS_PER_PULL then
        cur.over = true
        NS:Debug("Apprentissage : plafond d'observations atteint, enregistrement figé.")
        return
    end
    cur.obs[n + 1] = {
        NS.round(GetTime() - cur.t0, 2),
        kind,
        dur and NS.round(dur, 2) or nil,
        npc,
        unit,
        fire,
        sname,
    }
end

-- Ferme le pull courant et l'écrit en base s'il est exploitable.
-- outcome : "kill" | "wipe" | "abandon" — informatif, sert au tri dans l'IHM.
function Store:Commit(outcome)
    local cur = self.current
    self.current = nil
    if not cur then return nil end
    if #cur.obs < MIN_OBS_TO_KEEP then
        -- Perte visible, pas silencieuse : un pull écarté sans message donne
        -- l'impression que la rencontre n'a jamais été enregistrée, et on ne
        -- rejoue pas un boss pour vérifier.
        NS:Print(string.format(
            "|cffe8c07dPull écarté|r (%s) — %d observation(s), minimum %d. "
            .. "Combat trop court ou trop peu d'événements.",
            tostring(cur.key), #cur.obs, MIN_OBS_TO_KEEP))
        return nil
    end

    local db = self:DB()
    local list = db.pulls[cur.key]
    if not list then list = {}; db.pulls[cur.key] = list end

    list[#list + 1] = {
        schema  = self.SCHEMA,
        date    = date("%Y-%m-%d %H:%M"),
        len     = NS.round(GetTime() - cur.t0, 1),
        outcome = outcome or "wipe",
        boss    = cur.meta.boss,
        name    = cur.meta.name,      -- nom de la rencontre, livré par ENCOUNTER_START
        npc     = cur.meta.npc,
        inst    = cur.meta.inst,
        obs     = cur.obs,
    }

    -- élagage : on garde les plus récents (les tunings de boss changent en cours de saison)
    while #list > MAX_PULLS_PER_ENC do table.remove(list, 1) end

    NS:Debug("Apprentissage : pull enregistré pour", cur.key, "—", #cur.obs, "observations,",
        #list, "pull(s) en base.")
    return cur.key, #list
end

--------------------------------------------------------------------------
-- Consultation / entretien.
--------------------------------------------------------------------------
-- Ne rend QUE les pulls du schéma courant. Les captures v1 contenaient les
-- sorts du joueur et fausseraient toute analyse : mieux vaut zéro donnée
-- qu'une donnée fausse qui a l'air correcte.
function Store:GetPulls(key)
    local raw = self:DB().pulls[tostring(key)]
    if not raw then return nil end
    local out, legacy = {}, 0
    for _, p in ipairs(raw) do
        if p.schema == self.SCHEMA then out[#out + 1] = p else legacy = legacy + 1 end
    end
    if #out == 0 then return nil, legacy end
    return out, legacy
end

-- Toutes les captures, schéma confondu (pour le dump et l'entretien).
function Store:GetPullsRaw(key)
    return self:DB().pulls[tostring(key)]
end

-- Supprime les captures d'un schéma périmé.
function Store:PruneLegacy()
    local n = 0
    for key, list in pairs(self:DB().pulls) do
        for i = #list, 1, -1 do
            if list[i].schema ~= self.SCHEMA then table.remove(list, i); n = n + 1 end
        end
        if #list == 0 then self:DB().pulls[key] = nil end
    end
    return n
end

function Store:Keys()
    local out = {}
    for k in pairs(self:DB().pulls) do out[#out + 1] = k end
    table.sort(out)
    return out
end

function Store:CountPulls(key)
    local l = self:GetPulls(key)
    return l and #l or 0
end

function Store:IsSyntheticKey(key) return self:IsSynthetic(key) end

function Store:Clear(key)
    if key then
        self:DB().pulls[tostring(key)] = nil
    else
        wipe(self:DB().pulls)
    end
end

-- Rebranche une clé synthétique sur un encounterID réel (fusionne si besoin).
function Store:Rekey(oldKey, newKey)
    local db = self:DB()
    local src = db.pulls[tostring(oldKey)]
    if not src then return false end
    local dst = db.pulls[tostring(newKey)]
    if dst then
        for _, p in ipairs(src) do dst[#dst + 1] = p end
        while #dst > MAX_PULLS_PER_ENC do table.remove(dst, 1) end
    else
        db.pulls[tostring(newKey)] = src
    end
    db.pulls[tostring(oldKey)] = nil
    return true
end

-- Poids approximatif en base (pour avertir avant que le SavedVariables n'enfle).
function Store:ApproxSize()
    local n = 0
    for _, list in pairs(self:DB().pulls) do
        for _, p in ipairs(list) do n = n + #p.obs end
    end
    return n
end
