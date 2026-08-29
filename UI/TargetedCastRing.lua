---@diagnostic disable: undefined-global
-- TomoBoss -- Midnight secret-safe targeted cast ring.
--
-- Visual-only targeted warning:
--   * no CLEU;
--   * no spellID inspection;
--   * no target-name inspection;
--   * never branches on PlayerIsSpellTarget() because its boolean may be secret;
--   * forwards that boolean directly to Frame:SetAlphaFromBoolean();
--   * cast progress is driven entirely by Blizzard LuaDurationObject APIs.
--
-- IMPORTANT: enemy cast start/end timestamps are secret in Midnight. Do NOT
-- convert them to Lua numbers to animate the ring. UnitCastingDuration() and
-- UnitChannelDuration() return duration objects that can be passed directly to
-- Cooldown:SetCooldownFromDurationObject(), which keeps the whole progress path
-- secret-safe inside Blizzard's C++ UI engine.

local addonName, NS = ...
if type(NS) ~= "table" then return end

local R = NS.TargetedCastRing or {}
NS.TargetedCastRing = R

R.mode = "secret-safe-duration-ring"
R.enabled = true
R.offsetX = 0
R.offsetY = 0
R.diameter = 220
R.targetColor = { 1.00, 0.28, 0.12, 0.92 }
R.ringTexture = "Interface\\AddOns\\TomoBoss\\Media\\Textures\\TomoRing"
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

-- Only the NeverSecret castBarID is read from UnitCastingInfo/UnitChannelInfo.
-- Return positions are empirically validated by TrashObservatory on Retail 12.x:
-- cast=10, channel=11.
local function currentCastState(unit)
    if type(UnitCastingInfo) == "function" then
        local ok, v1,v2,v3,v4,v5,v6,v7,v8,v9,castBarID = pcall(UnitCastingInfo, unit)
        if ok then
            local id = safeNumber(castBarID)
            if id then return "cast", id end
        end
    end

    if type(UnitChannelInfo) == "function" then
        local ok, v1,v2,v3,v4,v5,v6,v7,v8,v9,v10,castBarID = pcall(UnitChannelInfo, unit)
        if ok then
            local id = safeNumber(castBarID)
            if id then return "channel", id end
        end
    end

    return nil, nil
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
        overlay = CreateFrame("Frame", nil, self:GetRoot())
        overlay:SetFrameStrata("HIGH")

        local cd = CreateFrame("Cooldown", nil, overlay, "CooldownFrameTemplate")
        cd:SetAllPoints(overlay)
        cd:SetHideCountdownNumbers(true)
        cd:SetDrawBling(false)
        cd:SetDrawSwipe(true)
        cd:SetDrawEdge(false)
        cd:SetReverse(true)
        cd:SetSwipeTexture(self.ringTexture)
        local c = self.targetColor
        cd:SetSwipeColor(c[1], c[2], c[3], c[4])
        overlay.cd = cd
    end

    overlay:ClearAllPoints()
    overlay:SetPoint("CENTER", self:GetRoot(), "CENTER", 0, 0)
    overlay:SetSize(self.diameter or 220, self.diameter or 220)
    overlay:SetAlpha(0)
    overlay:Show()

    if overlay.cd then
        overlay.cd:Clear()
        overlay.cd:Show()
    end

    return overlay
end

function R:ReleaseOverlay(key)
    local record = self.active[key]
    if not record then return end
    self.active[key] = nil

    local overlay = record.overlay
    if overlay then
        if overlay.cd then overlay.cd:Clear() end
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

    local ok, secretTarget = pcall(PlayerIsSpellTarget, record.unit)
    if not ok then
        record.overlay:SetAlpha(0)
        return
    end

    local applied = pcall(record.overlay.SetAlphaFromBoolean, record.overlay, secretTarget, 1, 0)
    if not applied then record.overlay:SetAlpha(0) end
end

function R:ApplyDuration(record)
    if not record or not record.overlay or not record.overlay.cd then return false end

    local durationFn
    if record.kind == "channel" then
        durationFn = UnitChannelDuration
    else
        durationFn = UnitCastingDuration
    end
    if type(durationFn) ~= "function" then return false end

    -- Duration may contain secret timing. Never read it in Lua.
    local ok, durationObj = pcall(durationFn, record.unit)
    if not ok then return false end

    local applied = pcall(
        record.overlay.cd.SetCooldownFromDurationObject,
        record.overlay.cd,
        durationObj,
        true
    )
    return applied and true or false
end

function R:Probe(key, refreshDuration)
    local record = self.active[key]
    if not record then return end

    local kind, currentID = currentCastState(record.unit)
    if not currentID or currentID ~= record.castBarID then
        self:ReleaseOverlay(key)
        return
    end

    record.kind = kind or record.kind
    self:ApplySecretTarget(record)
    if refreshDuration then self:ApplyDuration(record) end
end

function R:StartCast(unit, eventCastBarID)
    if not self.enabled or self.encounterActive or not inPartyInstance() then return end
    unit = acceptedUnit(unit)
    if not unit then return end

    local kind, currentID = currentCastState(unit)
    local castBarID = safeNumber(eventCastBarID) or currentID
    if not castBarID then return end

    local key = unit .. "|" .. tostring(castBarID)
    if self.active[key] then
        self:Probe(key, true)
        return
    end

    local record = {
        unit = unit,
        castBarID = castBarID,
        kind = kind or "cast",
        overlay = self:AcquireOverlay(),
    }
    self.active[key] = record

    self:ApplySecretTarget(record)
    self:ApplyDuration(record)

    -- Target refreshes only; the Cooldown widget animates progress itself.
    C_Timer.After(0.05, function() if R then R:Probe(key, false) end end)
    C_Timer.After(0.15, function() if R then R:Probe(key, false) end end)
    C_Timer.After(0.30, function() if R then R:Probe(key, false) end end)
end

function R:RefreshCast(unit, eventCastBarID)
    unit = acceptedUnit(unit)
    if not unit then return end

    local castBarID = safeNumber(eventCastBarID)
    if castBarID then
        local key = unit .. "|" .. tostring(castBarID)
        if self.active[key] then self:Probe(key, true) end
        return
    end

    local kind, currentID = currentCastState(unit)
    if currentID then
        local key = unit .. "|" .. tostring(currentID)
        local record = self.active[key]
        if record then
            record.kind = kind or record.kind
            self:Probe(key, true)
        end
    end
end

function R:StopCast(unit, eventCastBarID)
    unit = acceptedUnit(unit)
    if not unit then return end

    local castBarID = safeNumber(eventCastBarID)
    if castBarID then
        self:ReleaseOverlay(unit .. "|" .. tostring(castBarID))
    else
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

    if event == "UNIT_SPELLCAST_DELAYED" or event == "UNIT_SPELLCAST_CHANNEL_UPDATE" then
        self:RefreshCast(a1, a4)
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
        "UNIT_SPELLCAST_DELAYED", "UNIT_SPELLCAST_CHANNEL_UPDATE",
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
