local addonName, NS = ...
if type(NS) ~= "table" then return end

NS.Learn = NS.Learn or {}
local Confidence = NS.Learn.Confidence or {}
NS.Learn.Confidence = Confidence

local Store = NS.Learn.Store
local Infer = NS.Learn.Infer

-- Rencontres S2 pour lesquelles TomoBoss possède déjà des données ou dont
-- l'apprentissage est utile. Les deux raids ne sont inclus que pour les
-- encounterIDs déjà réellement observés dans les captures utilisateur.
local TRACKED = {
    [3101]=true,[3102]=true,[3103]=true,[3105]=true,
    [3207]=true,[3208]=true,[3209]=true,
    [3199]=true,[3200]=true,[3201]=true,[3202]=true,
    [3285]=true,[3286]=true,[3287]=true,
    [3456]=true,[3457]=true,[3458]=true,
    [2606]=true,[2609]=true,[2623]=true,
    [2124]=true,[2125]=true,[2126]=true,[2127]=true,
    [2139]=true,[2140]=true,[2142]=true,[2143]=true,
    [3379]=true,[3470]=true,
}
Confidence.TRACKED = TRACKED

local function safeCount(key)
    if not Store or type(Store.CountPulls) ~= "function" then return 0 end
    local ok, n = pcall(Store.CountPulls, Store, key)
    return ok and tonumber(n) or 0
end

local function keyFor(encounterID)
    local s = tostring(encounterID)
    local a = safeCount(s)
    if a > 0 then return s, a end
    local n = tonumber(encounterID)
    if n then
        local b = safeCount(n)
        if b > a then return n, b end
    end
    return s, a
end

local QUALITY = { bon = 1.0, ["moyen"] = 0.60, ["faible"] = 0.25 }

function Confidence:GetEncounter(encounterID)
    encounterID = tonumber(encounterID) or encounterID
    local key, pulls = keyFor(encounterID)
    local out = {
        encounterID = encounterID,
        key = key,
        pulls = pulls or 0,
        abilities = 0,
        good = 0,
        medium = 0,
        weak = 0,
        warnings = 0,
        score = 0,
        label = "LOW",
    }
    if out.pulls <= 0 or not Infer or type(Infer.Analyze) ~= "function" then return out end

    -- Infer annonce explicitement qu'il ne doit pas être exécuté en combat.
    if InCombatLockdown and InCombatLockdown() then
        out.deferred = true
        return out
    end

    local ok, res = pcall(Infer.Analyze, Infer, key)
    if not ok or type(res) ~= "table" then
        out.analysisError = true
        return out
    end

    local qualitySum = 0
    for _, r in ipairs(res) do
        out.abilities = out.abilities + 1
        local q = r.quality or "faible"
        if q == "bon" then out.good = out.good + 1
        elseif q == "moyen" then out.medium = out.medium + 1
        else out.weak = out.weak + 1 end
        qualitySum = qualitySum + (QUALITY[q] or 0.25)
        if r.warn then out.warnings = out.warnings + 1 end
    end

    local qScore = out.abilities > 0 and (qualitySum / out.abilities) or 0
    local pullScore = math.min(1, out.pulls / 3)
    local warningRatio = out.abilities > 0 and (out.warnings / out.abilities) or 1
    local score = (pullScore * 0.55 + qScore * 0.45) * 100
    score = score - math.min(15, warningRatio * 15)
    if score < 0 then score = 0 elseif score > 100 then score = 100 end
    out.score = math.floor(score + 0.5)

    if out.pulls >= 3 and out.score >= 80 and out.weak == 0 then
        out.label = "HIGH"
    elseif out.pulls >= 2 and out.score >= 55 then
        out.label = "MEDIUM"
    else
        out.label = "LOW"
    end
    return out
end

function Confidence:ScanTracked()
    local out = { learned=0, pulls=0, high=0, medium=0, low=0, details={} }
    for encID in pairs(TRACKED) do
        local c = self:GetEncounter(encID)
        if c.pulls > 0 then
            out.learned = out.learned + 1
            out.pulls = out.pulls + c.pulls
            if c.label == "HIGH" then out.high = out.high + 1
            elseif c.label == "MEDIUM" then out.medium = out.medium + 1
            else out.low = out.low + 1 end
            out.details[#out.details+1] = c
        end
    end
    table.sort(out.details, function(a,b) return tostring(a.encounterID) < tostring(b.encounterID) end)
    return out
end
