---@diagnostic disable: undefined-global
-- TomoBoss 2.8.0-beta5c — persisted Learn profile evidence (diagnostic only).
--
-- The signatures below come from user-recorded Learn dumps. They never choose
-- an event identity and never affect bars/voices. They only describe which
-- native Timeline duration profile was actually observed in stored pulls.

local addonName, NS = ...
if type(NS) ~= "table" then return end

NS.Learn = NS.Learn or {}
local PE = NS.Learn.ProfileEvidence or {}
NS.Learn.ProfileEvidence = PE
PE.mode = "observation-only"
PE.cache = PE.cache or {}

local Store = NS.Learn.Store
local SENTINEL_MIN = 900
local DEFAULT_TOL = 0.45

local function near(a, b, tol)
    return type(a) == "number" and type(b) == "number" and math.abs(a-b) <= (tol or DEFAULT_TOL)
end

local function getPulls(encounterID)
    if not Store or type(Store.GetPulls) ~= "function" then return {} end
    local key = tostring(encounterID)
    local ok, pulls = pcall(Store.GetPulls, Store, key)
    if (not ok or type(pulls) ~= "table" or #pulls == 0) and tonumber(encounterID) then
        ok, pulls = pcall(Store.GetPulls, Store, tonumber(encounterID))
    end
    return ok and type(pulls) == "table" and pulls or {}
end

local function durationsFromPull(pull)
    local out = {}
    local obs = pull and pull.obs
    if type(obs) ~= "table" or not Store then return out end
    for _, o in ipairs(obs) do
        if o[2] == Store.KIND_TIMELINE and type(o[3]) == "number" and o[3] > 0 then
            out[#out+1] = { t=type(o[1]) == "number" and o[1] or 0, duration=o[3] }
        end
    end
    return out
end

local function hasDuration(rows, target, tol)
    for _, row in ipairs(rows or {}) do
        if row.duration < SENTINEL_MIN and near(row.duration, target, tol) then return true end
    end
    return false
end

local function allDurations(rows, list, tol)
    for _, d in ipairs(list or {}) do
        if not hasDuration(rows, d, tol) then return false end
    end
    return true
end

local function oneOfDurations(rows, list, tol)
    for _, d in ipairs(list or {}) do
        if hasDuration(rows, d, tol) then return true end
    end
    return false
end

local PROFILE_DEFS = {
    [3199] = {
        { id="ALT", label="ALT", all={5,20,35,45}, oneOf={4,10}, durations={4,5,10,20,35,45} },
        { id="MYTHIC", label="MYTHIC", all={5,8,20,35,45}, durations={5,8,20,35,45} },
    },
    [3200] = {
        { id="ALT", label="ALT", all={6,20,40}, durations={6,20,40,60,62,63} },
        { id="MYTHIC", label="MYTHIC", all={6,22,50,29}, durations={6,22,29,50} },
    },
    [3202] = {
        { id="ALT", label="ALT", all={4,18,32,45}, durations={4,18,32,45} },
        { id="MYTHIC", label="MYTHIC", all={4,14,26,40,50}, durations={4,14,26,40,50} },
    },
}
PE.PROFILE_DEFS = PROFILE_DEFS

local function matchProfile(rows, def)
    if not allDurations(rows, def.all, def.tolerance) then return false end
    if def.oneOf and not oneOfDurations(rows, def.oneOf, def.tolerance) then return false end
    return true
end

local function sentinelSummary(pulls)
    local count, values = 0, {}
    for _, pull in ipairs(pulls or {}) do
        for _, row in ipairs(durationsFromPull(pull)) do
            if row.duration >= SENTINEL_MIN then
                count = count + 1
                local key = math.floor(row.duration + 0.5)
                values[key] = (values[key] or 0) + 1
            end
        end
    end
    return count, values
end

local function ruiaEvidence(pulls)
    local out = { p1Pulls=0, p2Pulls=0, p3Pulls=0, cycle32Pulls=0 }
    for _, pull in ipairs(pulls or {}) do
        local rows = durationsFromPull(pull)
        if allDurations(rows, {0.5,5,18}) then out.p1Pulls = out.p1Pulls + 1 end
        if allDurations(rows, {3,9}) then out.p2Pulls = out.p2Pulls + 1 end
        local p3Bootstrap = allDurations(rows, {2.5,7.3,15.3,23.3,31.3}, 0.50)
        local cycle32 = hasDuration(rows, 32, 0.50)
        if p3Bootstrap then out.p3Pulls = out.p3Pulls + 1 end
        if p3Bootstrap and cycle32 then out.cycle32Pulls = out.cycle32Pulls + 1 end
    end
    out.p3Confirmed = out.p3Pulls > 0
    out.cycle32Confirmed = out.cycle32Pulls > 0
    return out
end

function PE:_AnalyzeEncounter(encounterID)
    encounterID = tonumber(encounterID) or encounterID
    local pulls = getPulls(encounterID)
    local out = {
        encounterID=encounterID,
        pulls=#pulls,
        profiles={},
        sentinelCount=0,
        sentinelValues={},
    }
    local defs = PROFILE_DEFS[encounterID]
    if defs then
        for _, def in ipairs(defs) do out.profiles[def.id] = 0 end
        for _, pull in ipairs(pulls) do
            local rows = durationsFromPull(pull)
            -- Profiles are deliberately exclusive where the dumps distinguish
            -- them. Prefer the explicit MYTHIC signature if both ever match.
            local matched
            for i=#defs,1,-1 do
                local def = defs[i]
                if matchProfile(rows, def) then matched=def.id; break end
            end
            if matched then out.profiles[matched] = (out.profiles[matched] or 0) + 1 end
        end
    end
    out.sentinelCount, out.sentinelValues = sentinelSummary(pulls)
    if encounterID == 3201 then out.ruia = ruiaEvidence(pulls) end
    return out
end

function PE:RefreshEncounter(encounterID)
    encounterID = tonumber(encounterID) or encounterID
    local row = self:_AnalyzeEncounter(encounterID)
    self.cache[encounterID] = row
    return row
end

function PE:RefreshVal()
    for _, encID in ipairs({3199,3200,3201,3202}) do self:RefreshEncounter(encID) end
end

function PE:GetEncounter(encounterID)
    encounterID = tonumber(encounterID) or encounterID
    if InCombatLockdown and InCombatLockdown() then
        return self.cache[encounterID] or { encounterID=encounterID,pulls=0,profiles={},sentinelCount=0,sentinelValues={} }
    end
    return self:RefreshEncounter(encounterID)
end

function PE:GetRuiaEvidence()
    local out = self:GetEncounter(3201)
    return out.ruia or { p1Pulls=0,p2Pulls=0,p3Pulls=0,cycle32Pulls=0,p3Confirmed=false,cycle32Confirmed=false }
end

function PE:MatchDuration(encounterID, duration)
    encounterID = tonumber(encounterID) or encounterID
    duration = tonumber(duration)
    if not duration or duration >= SENTINEL_MIN then return nil end
    local defs = PROFILE_DEFS[encounterID]
    if not defs then
        if encounterID == 3201 then
            local ev = self:GetRuiaEvidence()
            if ev.p3Confirmed and (near(duration,2.5,0.50) or near(duration,7.3,0.50) or near(duration,15.3,0.50)
                or near(duration,23.3,0.50) or near(duration,31.3,0.50) or near(duration,32,0.50)) then
                return { "P3" }
            end
            if ev.p2Pulls > 0 and (near(duration,3) or near(duration,9) or (duration >= 19.8 and duration <= 21.2)) then
                return { "P2" }
            end
            if ev.p1Pulls > 0 and (near(duration,0.5) or near(duration,5) or near(duration,18) or (duration >= 19.8 and duration <= 21.2)) then
                return { "P1" }
            end
        end
        return nil
    end
    local evidence = self:GetEncounter(encounterID)
    local matches = {}
    for _, def in ipairs(defs) do
        if (evidence.profiles[def.id] or 0) > 0 then
            for _, d in ipairs(def.durations or {}) do
                if near(duration, d, 0.55) then matches[#matches+1]=def.id; break end
            end
        end
    end
    return #matches > 0 and matches or nil
end

function PE:ScanVal()
    local out = { encounters={}, sentinels=0, sentinelValues={} }
    for _, encID in ipairs({3199,3200,3201,3202}) do
        local row = self:GetEncounter(encID)
        out.encounters[encID] = row
        out.sentinels = out.sentinels + (row.sentinelCount or 0)
        for value, n in pairs(row.sentinelValues or {}) do
            out.sentinelValues[value] = (out.sentinelValues[value] or 0) + n
        end
    end
    return out
end

function PE:Init()
    if self.frame then return end
    self:RefreshVal()
    local f = CreateFrame("Frame")
    self.frame = f
    f:RegisterEvent("PLAYER_LOGIN")
    f:RegisterEvent("ENCOUNTER_END")
    f:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_LOGIN" then
            PE:RefreshVal()
        elseif event == "ENCOUNTER_END" then
            C_Timer.After(0.6, function() if PE and PE.RefreshVal then PE:RefreshVal() end end)
        end
    end)
end

PE:Init()
