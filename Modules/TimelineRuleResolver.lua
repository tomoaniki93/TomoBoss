---@diagnostic disable: undefined-global
-- TomoBoss 2.8.0-beta5b — static spellID + guarded state resolver for DurationRules.
-- Loaded after Modules/BlizzTimeline.lua so P0-01 remains untouched.

local NS = select(2, ...)
if type(NS) ~= "table" then return end
local BT = NS.BlizzTimeline or NS.BT
if type(BT) ~= "table" or type(BT.MatchRules) ~= "function" then return end

local oldMatchRules = BT.MatchRules
local TOL = 0.75
local SYNC_WINDOW = 10

local function resolveSpell(encID, spellID)
    if not spellID or not NS.Engine or not NS.Engine.GetEncounter then return nil end
    local def = NS.Engine:GetEncounter(encID)
    if not def then return nil end
    spellID = tonumber(spellID) or spellID
    for _, ev in ipairs(def.events or {}) do
        if (tonumber(ev.spellID) or ev.spellID) == spellID then return ev end
    end
    return nil
end

local function bestCandidates(rules, duration, syncOnly)
    local bestDelta
    local out = {}
    for _, rule in ipairs(rules or {}) do
        if rule.spellID and ((not syncOnly) or rule.sync) then
            local t = tonumber(rule.time)
            if t then
                local delta = math.abs(duration - t)
                if delta <= TOL then
                    if not bestDelta or delta < bestDelta - 0.001 then
                        bestDelta = delta
                        wipe(out)
                        out[1] = rule
                    elseif math.abs(delta - bestDelta) <= 0.001 then
                        out[#out + 1] = rule
                    end
                end
            end
        end
    end
    return out
end

local function pickCounter(self, encID, candidates)
    if #candidates < 2 then return candidates[1] end
    local group
    for _, r in ipairs(candidates) do
        if not r.sequenceGroup or r.strategy ~= "counter" then return nil end
        if group and group ~= r.sequenceGroup then return nil end
        group = r.sequenceGroup
    end
    if not group then return nil end

    table.sort(candidates, function(a, b)
        return (tonumber(a.sequenceOrder) or 999) < (tonumber(b.sequenceOrder) or 999)
    end)

    local key = tostring(encID) .. "|" .. tostring(group)
    self._seqCounters = self._seqCounters or {}
    local n = (self._seqCounters[key] or 0) + 1
    if n > #candidates then n = 1 end
    self._seqCounters[key] = n
    return candidates[n]
end

function BT:MatchRules(encID, duration)
    -- State-aware rules get first refusal, but only when their runtime guard is
    -- complete. Returning nil is intentional and preserves P0-01 generic-safe.
    if NS.StateResolver and type(NS.StateResolver.Resolve) == "function" then
        local ev, how = NS.StateResolver:Resolve(encID, duration)
        if ev then return ev, how end
    end

    local rules = NS.DURATION_RULES and NS.DURATION_RULES[encID]
    if type(rules) ~= "table" then
        return oldMatchRules(self, encID, duration)
    end

    -- Preserve the legacy eventID resolver for non-migrated encounters.
    local hasSpellRules = false
    for _, r in ipairs(rules) do
        if r.spellID then hasSpellRules = true break end
    end
    if not hasSpellRules then
        return oldMatchRules(self, encID, duration)
    end

    local elapsed = self._pullTime and (GetTime() - self._pullTime) or math.huge
    local syncCandidates = elapsed <= SYNC_WINDOW and bestCandidates(rules, duration, true) or {}
    local candidates = (#syncCandidates > 0) and syncCandidates or bestCandidates(rules, duration, false)
    if #candidates == 0 then return nil end

    local pick = pickCounter(self, encID, candidates)
    if not pick then
        NS:Debug("Timeline rules: collision spellID non déterministe enc=", tostring(encID),
            " durée=", tostring(duration), " — repli générique.")
        return nil
    end

    local ev = resolveSpell(encID, pick.spellID)
    if not ev then
        NS:Debug("Timeline rules: spellID introuvable enc=", tostring(encID),
            " spell=", tostring(pick.spellID), " — repli générique.")
        if NS.ReferenceCatalog and type(NS.ReferenceCatalog.ObserveFallback) == "function" then
            pcall(NS.ReferenceCatalog.ObserveFallback, NS.ReferenceCatalog, encID, duration, "static spellID missing")
        end
        return nil
    end
    if NS.ReferenceCatalog and type(NS.ReferenceCatalog.ObserveDecision) == "function" then
        local spellCandidates = {}
        for _, rule in ipairs(candidates or {}) do
            if rule.spellID then spellCandidates[#spellCandidates + 1] = tonumber(rule.spellID) or rule.spellID end
        end
        pcall(NS.ReferenceCatalog.ObserveDecision, NS.ReferenceCatalog, encID, duration, tonumber(pick.spellID) or pick.spellID, "static spellID", spellCandidates)
    end
    return ev, "règle spellID"
end
