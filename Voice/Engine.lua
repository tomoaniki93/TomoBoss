---@diagnostic disable: undefined-global
-- TomoBoss — Moteur vocal : résout un id d'annonce vers un fichier et le joue.

local NS = select(2, ...)
local Voice = NS.Voice or {}
NS.Voice = Voice

local lastPlay = {}          -- id -> GetTime() du dernier passage (anti-doublon même annonce)
local lastAnyPlay = 0        -- GetTime() de la dernière annonce (espacement global)
local DEDUPE = 0.20          -- fenêtre anti-doublon (s) pour une même annonce

local function cfg()
    return NS.db and NS.db.profile and NS.db.profile.voice or nil
end

-- Résout un id vers l'entrée du catalogue.
function Voice:Resolve(id)
    if type(id) ~= "string" or id == "" then return nil end
    if self.Catalog[id] then return id, self.Catalog[id] end
    return nil
end

-- Joue une annonce par id. Renvoie true si un son a été lancé.
-- opts.force ignore l'anti-doublon ET l'espacement global (utilisé par le décompte).
function Voice:Play(id, opts)
    opts = opts or {}
    local c = cfg()
    if not (c and c.enabled) and not opts.force then return false end

    local id, entry = self:Resolve(id)
    if not id then
        NS:Debug("Voice:Play — id inconnu:", tostring(id))
        return false
    end

    local now = GetTime()
    if not opts.force then
        -- anti-doublon de la même annonce
        if lastPlay[id] and (now - lastPlay[id]) < DEDUPE then
            return false
        end
        -- espacement minimum entre deux annonces quelconques (anti-empilement)
        local minGap = (c and c.minGap) or 0
        if minGap > 0 and (now - lastAnyPlay) < minGap then
            return false
        end
    end
    lastPlay[id] = now

    local LSM = NS.LSM
    if not LSM then return false end
    local lang = NS.CurrentVoicePack and NS.CurrentVoicePack() or (NS.VOICE_DEFAULT_PACK or "frFR")
    local path = LSM:Fetch("sound", NS.VoiceKey(lang, id), true)
    if not path and lang ~= (NS.VOICE_DEFAULT_PACK or "frFR") then
        -- repli : pack par défaut si l'annonce manque dans la langue choisie
        path = LSM:Fetch("sound", NS.VoiceKey(NS.VOICE_DEFAULT_PACK or "frFR", id), true)
    end
    if not path then
        NS:Debug("Voice:Play — fichier introuvable pour:", id)
        return false
    end

    local channel = (c and c.channel) or "Master"
    if PlaySoundFile then
        -- boost de volume : empile le même son (100%=1, 200%=2, 300%=3 lectures).
        -- PlaySoundFile n'a pas de gain ; superposer additionne l'amplitude.
        local boost = (c and c.boost) or 100
        local copies = NS.clamp(math.floor(boost / 100 + 0.5), 1, 3)
        for _ = 1, copies do PlaySoundFile(path, channel) end
        lastAnyPlay = now
        return true
    end
    return false
end

-- Décompte vocal : joue le chiffre n (1..5) via countdown-N.
function Voice:PlayCountdown(n)
    n = tonumber(n)
    if not n or n < 1 or n > 5 then return false end
    return self:Play("countdown-" .. n, { force = true })
end

-- Liste ordonnée pour le menu déroulant des options (par catégorie puis nom FR).
function Voice:BuildList()
    local out = {}
    for id, e in pairs(self.Catalog) do
        out[#out + 1] = { value = id, text = "[" .. e.cat .. "] " .. e.fr, cat = e.cat, fr = e.fr }
    end
    table.sort(out, function(a, b)
        if a.cat ~= b.cat then return a.cat < b.cat end
        return a.fr < b.fr
    end)
    return out
end
