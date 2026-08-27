local addonName, NS = ...
if type(NS) ~= "table" then return end

local Validator = NS.Validator or {}
NS.Validator = Validator

local S2 = {
    [3101]=true,[3102]=true,[3103]=true,[3105]=true, -- Murder Row
    [3207]=true,[3208]=true,[3209]=true,             -- Den of Nalorakk
    [3199]=true,[3200]=true,[3201]=true,[3202]=true, -- The Blinding Vale
    [3285]=true,[3286]=true,[3287]=true,             -- Voidscar Arena
    [3456]=true,[3457]=true,[3458]=true,             -- Altar of Fangs
    [2606]=true,[2609]=true,[2623]=true,             -- Ruby Life Pools
    [2124]=true,[2125]=true,[2126]=true,[2127]=true, -- Temple of Sethraliss
    [2139]=true,[2140]=true,[2142]=true,[2143]=true, -- King's Rest
}

local function addDuration(bucket, d, ev)
    if type(d) ~= "number" or d <= 0 or d >= 900 then return end
    local key = string.format("%.3f", d)
    local t = bucket[key]
    if not t then t = {}; bucket[key] = t end
    t[ev] = true
end

local function eventSets(def)
    local byEvent, bySpell = {}, {}
    if not def or type(def.events) ~= "table" then return byEvent, bySpell end
    for _, ev in ipairs(def.events) do
        if ev.eventID ~= nil then byEvent[tonumber(ev.eventID) or ev.eventID] = true end
        if ev.spellID ~= nil then bySpell[tonumber(ev.spellID) or ev.spellID] = true end
    end
    return byEvent, bySpell
end

function Validator:ScanDurationRules(onlyS2)
    local result = { encounters=0, rules=0, resolved=0, unresolved=0, missingEncounter=0, details={} }
    local rulesByEnc = NS.DURATION_RULES or {}
    local engine = NS.Engine
    for encID, rules in pairs(rulesByEnc) do
        if (not onlyS2) or S2[tonumber(encID)] then
            result.encounters = result.encounters + 1
            local def = engine and engine.GetEncounter and engine:GetEncounter(encID) or nil
            if not def then result.missingEncounter = result.missingEncounter + 1 end
            local eventIDs, spellIDs = eventSets(def)
            for _, rule in ipairs(rules or {}) do
                result.rules = result.rules + 1
                local ok, targetType, target
                if rule.spellID ~= nil then
                    targetType, target = "spellID", tonumber(rule.spellID) or rule.spellID
                    ok = def and spellIDs[target]
                else
                    targetType, target = "eventID", tonumber(rule.eventID) or rule.eventID
                    ok = def and eventIDs[target]
                end
                if ok then
                    result.resolved = result.resolved + 1
                else
                    result.unresolved = result.unresolved + 1
                    result.details[#result.details+1] = {
                        encounterID = tonumber(encID) or encID,
                        time = rule.time,
                        targetType = targetType,
                        target = target,
                        missingEncounter = not def,
                    }
                end
            end
        end
    end
    table.sort(result.details, function(a,b)
        if a.encounterID == b.encounterID then return (a.time or 0) < (b.time or 0) end
        return tostring(a.encounterID) < tostring(b.encounterID)
    end)
    return result
end

local function rulesCoverCollision(encID, duration, events)
    local rules = NS.DURATION_RULES and NS.DURATION_RULES[encID]
    if type(rules) ~= "table" or #rules == 0 then return false end
    local wanted = {}
    for _, ev in ipairs(events) do
        if ev.spellID then wanted[tonumber(ev.spellID) or ev.spellID] = false end
    end
    for _, r in ipairs(rules) do
        if r.spellID and type(r.time) == "number" and math.abs(r.time - duration) <= 0.05 then
            local sid = tonumber(r.spellID) or r.spellID
            if wanted[sid] ~= nil then wanted[sid] = true end
        end
    end
    local any = false
    for _, covered in pairs(wanted) do
        any = true
        if not covered then return false end
    end
    return any
end

function Validator:ScanDurationCollisions(onlyS2)
    local result = {
        encounters=0, collisionGroups=0, covered=0, staticCovered=0,
        stateCovered=0, gatedState=0, genericSafe=0, details={}
    }
    local engine = NS.Engine
    local all = engine and engine.AllEncounters and engine:AllEncounters() or {}
    for encID, def in pairs(all or {}) do
        if (not onlyS2) or S2[tonumber(encID)] then
            result.encounters = result.encounters + 1
            local bucket = {}
            for _, ev in ipairs(def.events or {}) do
                addDuration(bucket, ev.firstSeenSec, ev)
                for _, d in ipairs(ev.cdSeriesSec or {}) do addDuration(bucket, d, ev) end
            end
            for duration, set in pairs(bucket) do
                local count, events = 0, {}
                for ev in pairs(set) do count = count + 1; events[#events+1] = ev end
                if count > 1 then
                    local d = tonumber(duration)
                    local eid = tonumber(encID) or encID
                    local staticCovered = rulesCoverCollision(eid, d, events)
                    local stateMeta = NS.StateResolver and type(NS.StateResolver.GetCoverage) == "function"
                        and NS.StateResolver:GetCoverage(eid, d) or nil
                    local stateCovered = (not staticCovered) and stateMeta and stateMeta.armed or false
                    local gatedState = (not staticCovered) and stateMeta and not stateMeta.armed or false
                    local covered = staticCovered or stateCovered
                    result.collisionGroups = result.collisionGroups + 1
                    if staticCovered then result.staticCovered = result.staticCovered + 1 end
                    if stateCovered then result.stateCovered = result.stateCovered + 1 end
                    if gatedState then result.gatedState = result.gatedState + 1 end
                    if covered then result.covered = result.covered + 1 else result.genericSafe = result.genericSafe + 1 end
                    local spells = {}
                    for _, ev in ipairs(events) do spells[#spells+1] = tonumber(ev.spellID) or ev.spellID or "?" end
                    table.sort(spells, function(a,b) return tostring(a) < tostring(b) end)
                    result.details[#result.details+1] = {
                        encounterID = tonumber(encID) or encID,
                        duration = d,
                        events = events,
                        spells = spells,
                        covered = covered,
                        staticCovered = staticCovered,
                        stateCovered = stateCovered,
                        gatedState = gatedState,
                        stateLabel = stateMeta and stateMeta.label or nil,
                    }
                end
            end
        end
    end
    table.sort(result.details, function(a,b)
        if a.encounterID == b.encounterID then return (a.duration or 0) < (b.duration or 0) end
        return tostring(a.encounterID) < tostring(b.encounterID)
    end)
    return result
end

function Validator:RunS2()
    return { rules = self:ScanDurationRules(true), collisions = self:ScanDurationCollisions(true) }
end
