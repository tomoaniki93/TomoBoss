---@diagnostic disable: undefined-global
-- TomoBoss -- Midnight secret-safe targeted cast ring.
--
-- Visual-only prototype:
--   * no CLEU;
--   * no spellID inspection;
--   * no target-name inspection;
--   * never branches on PlayerIsSpellTarget() because its boolean may be secret;
--   * forwards that boolean directly to Region:SetAlphaFromBoolean().
--
-- One overlay texture is allocated per active cast. This matters when several
-- enemies cast at once: a non-targeting cast cannot clear the red/orange ring
-- produced by another cast that is targeting the player.

local addonName, NS = ...
if type(NS) ~= "table" then return end

local R = NS.TargetedCastRing or {}
NS.TargetedCastRing = R

R.mode = "secret-safe-visual"
R.enabled = true
R.size = 84
R.offsetX = 0
R.offsetY = 0
R.texturePath = "Interface\\Common\\RingBorder"
R.targetColor = { 1.00, 0.22, 0.04, 1.00 } -- TomoBoss warning orange/red
R.active = R.active or {}
R.pool = R.pool or {}
R.encounterActive = false

local function isSecret(v)
    return type(issecretvalue) == "function" and issecretvalue(v) or false
end

local function safeNumber(v)
    if isSecret(v) then return nil end
    return type(v) == "number" and v or nil
end

local function acceptedUnit(unit)
    if isSecret(unit) or type(unit) ~= "string" then return nil end
    if unit:match("^nameplate%d+$") then return unit end
    return nil
end

-- Read only the NeverSecret castBarID return. All other values returned by
-- UnitCastingInfo / UnitChannelInfo are intentionally ignored.
local function currentCastBarID(unit)
    if type(UnitCastingInfo) == "function" then
        local ok, v1,v2,v3,v4,v5,v6,v7,v8,v9,barID = pcall(UnitCastingInfo, unit)
        if ok then
            local id = safeNumber(barID)
            if id then return id end
        end
    end
    if type(UnitChannelInfo) == "function" then
        local ok, v1,v2,v3,v4,v5,v6,v7,v8,v9,v10,barID = pcall(UnitChannelInfo, unit)
        if ok then
            local id = safeNumber(barID)
            if id then return id end
        end
    end
    return nil
end

local function inPartyInstance()
    if type(GetInstanceInfo) ~= "function" then return false end
    local ok, _, instanceType = pcall(GetInstanceInfo)
    return ok and not isSecret(instanceType) and instanceType == "party"
end

function R:GetRoot()
    if self.root then return self.root end
    local root = CreateFrame("Frame", nil, UIParent)
    root:SetSize(1, 1)
    root:SetPoint("CENTER", UIParent, "CENTER", self.offsetX or 0, self.offsetY or 0)
    root:SetFrameStrata("HIGH")
    self.root = root
    return root
end

function R:AcquireOverlay()
    local overlay = table.remove(self.pool)
    if not overlay then
        overlay = self:GetRoot():CreateTexture(nil, "OVERLAY", nil, 6)
        overlay:SetTexture(self.texturePath)
        overlay:SetBlendMode("BLEND")
    end

    overlay:ClearAllPoints()
    overlay:SetPoint("CENTER", self:GetRoot(), "CENTER", 0, 0)
    overlay:SetSize(self.size or 84, self.size or 84)
    local c = self.targetColor
    overlay:SetVertexColor(c[1], c[2], c[3], c[4])
    overlay:SetAlpha(0)
    overlay:Show()
    return overlay
end

function R:ReleaseOverlay(key)
    local record = self.active[key]
    if not record then return end
    self.active[key] = nil
    local overlay = record.overlay
    if overlay then
        overlay:SetAlpha(0)
        overlay:Hide()
        self.pool[#self.pool + 1] = overlay
    end
end

function R:ReleaseUnit(unit)
    local keys = {}
    for key, record in pairs(self.active) do
        if record.unit == unit then keys[#keys + 1] = key end
    end
    for i = 1, #keys do self:ReleaseOverlay(keys[i]) end
end

function R:ReleaseAll()
    local keys = {}
    for key in pairs(self.active) do keys[#keys + 1] = key end
    for i = 1, #keys do self:ReleaseOverlay(keys[i]) end
end

function R:ApplySecretTarget(record)
    if not record or not record.overlay or type(PlayerIsSpellTarget) ~= "function" then return end

    -- IMPORTANT: do not inspect, compare, stringify or branch on this value.
    -- PlayerIsSpellTarget() may return a secret boolean in Midnight.
    local ok, secretTarget = pcall(PlayerIsSpellTarget, record.unit)
    if not ok then
        record.overlay:SetAlpha(0)
        return
    end

    -- The secret boolean is consumed directly by Blizzard's C-level Region API.
    -- pcall only guards API availability/errors; its result is not derived from
    -- the secret boolean itself.
    local applied = pcall(record.overlay.SetAlphaFromBoolean, record.overlay, secretTarget, 1, 0)
    if not applied then record.overlay:SetAlpha(0) end
end

function R:Probe(key)
    local record = self.active[key]
    if not record then return end

    if record.castBarID then
        local current = currentCastBarID(record.unit)
        if current ~= record.castBarID then
            self:ReleaseOverlay(key)
            return
        end
    end

    self:ApplySecretTarget(record)
end

function R:StartCast(unit, eventCastBarID)
    if not self.enabled or self.encounterActive or not inPartyInstance() then return end
    unit = acceptedUnit(unit)
    if not unit then return end

    local castBarID = safeNumber(eventCastBarID) or currentCastBarID(unit)
    if not castBarID then return end

    local key = unit .. "|" .. tostring(castBarID)
    if self.active[key] then
        self:ApplySecretTarget(self.active[key])
        return
    end

    local record = {
        unit = unit,
        castBarID = castBarID,
        overlay = self:AcquireOverlay(),
    }
    self.active[key] = record

    -- Immediate + short deferred refreshes. We never read the target result;
    -- this only re-forwards PlayerIsSpellTarget() to SetAlphaFromBoolean().
    self:Probe(key)
    C_Timer.After(0.05, function() if R then R:Probe(key) end end)
    C_Timer.After(0.15, function() if R then R:Probe(key) end end)
    C_Timer.After(0.30, function() if R then R:Probe(key) end end)
end

function R:StopCast(unit, eventCastBarID)
    unit = acceptedUnit(unit)
    if not unit then return end

    local castBarID = safeNumber(eventCastBarID)
    if castBarID then
        self:ReleaseOverlay(unit .. "|" .. tostring(castBarID))
    else
        -- Defensive cleanup when an event does not expose castBarID.
        self:ReleaseUnit(unit)
    end
end

function R:OnEvent(event, a1, a2, a3, a4, a5)
    if event == "PLAYER_ENTERING_WORLD" then
        self:ReleaseAll()
        return
    elseif event == "ENCOUNTER_START" then
        self.encounterActive = true
        self:ReleaseAll()
        return
    elseif event == "ENCOUNTER_END" then
        self.encounterActive = false
        return
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        self:ReleaseUnit(a1)
        return
    end

    if event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" then
        self:StartCast(a1, a4)
        return
    end

    if event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_CHANNEL_STOP" then
        self:StopCast(a1, a5)
    elseif event == "UNIT_SPELLCAST_STOP"
        or event == "UNIT_SPELLCAST_FAILED"
        or event == "UNIT_SPELLCAST_FAILED_QUIET"
        or event == "UNIT_SPELLCAST_SUCCEEDED" then
        self:StopCast(a1, a4)
    end
end

function R:Init()
    if self.frame then return end
    local f = CreateFrame("Frame")
    self.frame = f

    local events = {
        "PLAYER_ENTERING_WORLD",
        "ENCOUNTER_START", "ENCOUNTER_END",
        "NAME_PLATE_UNIT_REMOVED",
        "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_CHANNEL_START",
        "UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_CHANNEL_STOP",
        "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_FAILED",
        "UNIT_SPELLCAST_FAILED_QUIET", "UNIT_SPELLCAST_SUCCEEDED",
    }
    for i = 1, #events do pcall(f.RegisterEvent, f, events[i]) end
    f:SetScript("OnEvent", function(_, event, ...)
        R:OnEvent(event, ...)
    end)
end

R:Init()
