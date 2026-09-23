--[[
LibTomoKeystoneSync-1.0
Lightweight Mythic+ keystone exchange library for World of Warcraft addons.

Protocol compatibility:
  Prefix: TOMOKEYS
  Request: 1:?
  Key:     1:K:<challengeMapID>:<level>:<classID>:<specID>:<rating>

Author: TomoAniki
License: MIT
]]

local MAJOR = "LibTomoKeystoneSync-1.0"
local MINOR = 1
local PREFIX = "TOMOKEYS"
local PROTO = "1"

local existing = _G[MAJOR]
if existing and (existing.MINOR or 0) >= MINOR then
    return
end

local Lib = existing or {}
_G[MAJOR] = Lib
_G.LibTomoKeystoneSync = Lib

Lib.MAJOR = MAJOR
Lib.MINOR = MINOR
Lib.PROTOCOL_PREFIX = PREFIX
Lib.PROTOCOL_VERSION = PROTO

local PUSH_THROTTLE = 5
local REPLY_JITTER = 2.5

Lib.Data = Lib.Data or setmetatable({}, {
    __index = function(t, key)
        if type(key) ~= "string" or key == "" or key:find("-", 1, true) then
            return nil
        end

        local realm = GetRealmName and GetRealmName()
        if not realm or realm == "" then return nil end
        return rawget(t, key .. "-" .. realm:gsub("%s+", ""))
    end,
})

Lib.callbacks = Lib.callbacks or {}
Lib.lastPush = Lib.lastPush or 0
Lib.pendingReply = Lib.pendingReply or false

local function SafeNum(value)
    if value == nil then return nil end

    local secretFn = rawget(_G, "issecretvalue")
    if type(secretFn) == "function" then
        local ok, secret = pcall(secretFn, value)
        if ok and secret then return nil end
    end

    return type(value) == "number" and value or nil
end

local function PlayerFullName()
    if not UnitName then return nil end

    local name = UnitName("player")
    local realm = GetRealmName and GetRealmName()
    if not name then return nil end

    if realm and realm ~= "" then
        return name .. "-" .. realm:gsub("%s+", "")
    end
    return name
end

local function GroupChannel()
    if IsInRaid and IsInRaid() then
        if IsInRaid(LE_PARTY_CATEGORY_INSTANCE) then
            return "INSTANCE_CHAT"
        end
        return "RAID"
    end

    if IsInGroup and IsInGroup() then
        if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
            return "INSTANCE_CHAT"
        end
        return "PARTY"
    end

    return nil
end

local function IsSupportedChannel(channel)
    return channel == "PARTY"
        or channel == "RAID"
        or channel == "INSTANCE_CHAT"
        or channel == "GUILD"
end

local function TomoModOwnsTransport()
    local native = rawget(_G, "TomoMod_KeySync")
    return type(native) == "table"
        and type(native.Broadcast) == "function"
        and type(native.RequestKeystoneDataFromParty) == "function"
end

local function RegisterPrefix()
    if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
        C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)
    end
end

local function Send(message, channel)
    if TomoModOwnsTransport() then return false end
    if not channel then return false end
    if channel == "GUILD" and (not IsInGuild or not IsInGuild()) then return false end
    if not (C_ChatInfo and C_ChatInfo.SendAddonMessage) then return false end

    C_ChatInfo.SendAddonMessage(PREFIX, message, channel)
    return true
end

local function Encode(entry)
    return string.format(
        "%s:K:%d:%d:%d:%d:%d",
        PROTO,
        entry.challengeMapID or entry.mythicPlusMapID or 0,
        entry.level or 0,
        entry.classID or 0,
        entry.specID or 0,
        entry.rating or 0
    )
end

local function Fire(fullName)
    for _, cb in ipairs(Lib.callbacks) do
        local ok, err = pcall(cb.fn, fullName, Lib.Data[fullName], Lib.Data)
        if not ok and geterrorhandler then
            local handler = geterrorhandler()
            if handler then
                handler(MAJOR .. " callback error (" .. tostring(cb.owner) .. "): " .. tostring(err))
            end
        end
    end
end

local function Store(fullName, entry)
    if not fullName or fullName == "" or type(entry) ~= "table" then return end

    entry.updated = time and time() or 0
    rawset(Lib.Data, fullName, entry)
    Fire(fullName)
end

function Lib.ReadOwnKeystone()
    local level = 0
    local mapID = 0

    if C_MythicPlus then
        if C_MythicPlus.GetOwnedKeystoneLevel then
            level = SafeNum(C_MythicPlus.GetOwnedKeystoneLevel()) or 0
        end
        if C_MythicPlus.GetOwnedKeystoneChallengeMapID then
            mapID = SafeNum(C_MythicPlus.GetOwnedKeystoneChallengeMapID()) or 0
        end
    end

    local classID = 0
    if UnitClass then
        local _, _, id = UnitClass("player")
        classID = SafeNum(id) or 0
    end

    local specID = 0
    if GetSpecialization and GetSpecializationInfo then
        local specIndex = GetSpecialization()
        if specIndex then
            specID = SafeNum(GetSpecializationInfo(specIndex)) or 0
        end
    end

    local rating = 0
    if C_PlayerInfo and C_PlayerInfo.GetPlayerMythicPlusRatingSummary then
        local summary = C_PlayerInfo.GetPlayerMythicPlusRatingSummary("player")
        rating = summary and SafeNum(summary.currentSeasonScore) or 0
    end

    return {
        challengeMapID = mapID,
        mythicPlusMapID = mapID,
        level = level,
        classID = classID,
        specID = specID,
        rating = rating,
    }
end

function Lib.RefreshOwnKeystone()
    local fullName = PlayerFullName()
    if not fullName then return nil end

    local entry = Lib.ReadOwnKeystone()
    local old = Lib.Data[fullName]

    if not old
        or old.level ~= entry.level
        or old.challengeMapID ~= entry.challengeMapID
        or old.classID ~= entry.classID
        or old.specID ~= entry.specID
        or old.rating ~= entry.rating then
        Store(fullName, entry)
    else
        rawset(Lib.Data, fullName, entry)
    end

    return entry
end

function Lib.Broadcast(force, requestedChannel)
    local entry = Lib.RefreshOwnKeystone()
    if not entry then return false end

    if TomoModOwnsTransport() then
        -- TomoMod is authoritative on this client. It already speaks exactly
        -- the same wire protocol, so never emit a duplicate packet.
        return false
    end

    local now = GetTime and GetTime() or 0
    if not force and (now - (Lib.lastPush or 0)) < PUSH_THROTTLE then
        return false
    end
    Lib.lastPush = now

    local message = Encode(entry)

    if requestedChannel then
        return Send(message, requestedChannel)
    end

    local sent = Send(message, GroupChannel())
    if IsInGuild and IsInGuild() then
        sent = Send(message, "GUILD") or sent
    end
    return sent
end

function Lib.RequestKeystoneDataFromParty()
    local native = rawget(_G, "TomoMod_KeySync")
    if TomoModOwnsTransport() then
        native.RequestKeystoneDataFromParty()
        Lib.RefreshOwnKeystone()
        return true
    end

    local channel = GroupChannel()
    if not channel then return false end

    Send(PROTO .. ":?", channel)
    Lib.Broadcast(true, channel)
    return true
end

function Lib.RequestKeystoneDataFromGuild()
    local native = rawget(_G, "TomoMod_KeySync")
    if TomoModOwnsTransport() and type(native.RequestKeystoneDataFromGuild) == "function" then
        native.RequestKeystoneDataFromGuild()
        return true
    end

    if not IsInGuild or not IsInGuild() then return false end
    Send(PROTO .. ":?", "GUILD")
    Lib.Broadcast(true, "GUILD")
    return true
end

function Lib.GetAllKeystonesInfo()
    return Lib.Data
end

function Lib.GetKeystoneInfo(unitOrName)
    if type(unitOrName) ~= "string" or unitOrName == "" then return nil end

    if unitOrName == "player" then
        local name = PlayerFullName()
        return name and Lib.Data[name] or nil
    end

    if UnitExists and UnitExists(unitOrName) and UnitName then
        local name, realm = UnitName(unitOrName)
        if not name then return nil end

        if realm and realm ~= "" then
            return Lib.Data[name .. "-" .. realm] or Lib.Data[name]
        end
        return Lib.Data[name]
    end

    return Lib.Data[unitOrName]
end

function Lib.RegisterCallback(owner, event, fn)
    if type(fn) ~= "function" then return false end
    event = event or "KeystoneUpdate"

    for _, cb in ipairs(Lib.callbacks) do
        if cb.owner == owner and cb.event == event then
            cb.fn = fn
            return true
        end
    end

    Lib.callbacks[#Lib.callbacks + 1] = {
        owner = owner,
        event = event,
        fn = fn,
    }
    return true
end

function Lib.UnregisterCallback(owner, event)
    event = event or "KeystoneUpdate"

    for i = #Lib.callbacks, 1, -1 do
        local cb = Lib.callbacks[i]
        if cb.owner == owner and cb.event == event then
            table.remove(Lib.callbacks, i)
        end
    end
end

function Lib.GetProtocolInfo()
    return {
        major = MAJOR,
        minor = MINOR,
        prefix = PREFIX,
        version = PROTO,
    }
end

function Lib:HandleAddonMessage(prefix, message, channel, sender)
    if prefix ~= PREFIX or type(message) ~= "string" then return end

    local proto, rest = message:match("^(%d+):(.+)$")
    if proto ~= PROTO then return end

    if rest == "?" then
        if TomoModOwnsTransport() then return end
        if not IsSupportedChannel(channel) then return end
        if self.pendingReply then return end

        self.pendingReply = true
        C_Timer.After(math.random() * REPLY_JITTER, function()
            self.pendingReply = false
            self.Broadcast(true, channel)
        end)
        return
    end

    local mapID, level, classID, specID, rating =
        rest:match("^K:(%-?%d+):(%-?%d+):(%-?%d+):(%-?%d+):(%-?%d+)$")

    if not mapID or not sender then return end

    mapID = tonumber(mapID) or 0
    level = tonumber(level) or 0

    if mapID < 0 or level < 0 or level > 100 then return end

    Store(sender, {
        challengeMapID = mapID,
        mythicPlusMapID = mapID,
        level = level,
        classID = tonumber(classID) or 0,
        specID = tonumber(specID) or 0,
        rating = tonumber(rating) or 0,
    })
end

function Lib:OnEvent(event, ...)
    if event == "CHAT_MSG_ADDON" then
        local prefix, message, channel, sender = ...
        self:HandleAddonMessage(prefix, message, channel, sender)
        return
    end

    if event == "PLAYER_LOGIN" then
        RegisterPrefix()
        self.RefreshOwnKeystone()

        if C_MythicPlus and C_MythicPlus.RequestRewards then
            C_MythicPlus.RequestRewards()
        end

        C_Timer.After(3, function()
            self.Broadcast(false)
        end)
        return
    end

    if event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_ENTERING_WORLD" then
        self.RefreshOwnKeystone()
        C_Timer.After(1, function()
            self.Broadcast(false)
        end)
        return
    end

    C_Timer.After(1, function()
        self.Broadcast(false)
    end)
end

RegisterPrefix()

if not Lib.eventFrame then
    Lib.eventFrame = CreateFrame("Frame")
    Lib.eventFrame:SetScript("OnEvent", function(_, event, ...)
        Lib:OnEvent(event, ...)
    end)

    local function SafeRegister(event)
        pcall(Lib.eventFrame.RegisterEvent, Lib.eventFrame, event)
    end

    SafeRegister("PLAYER_LOGIN")
    SafeRegister("PLAYER_ENTERING_WORLD")
    SafeRegister("GROUP_ROSTER_UPDATE")
    SafeRegister("BAG_UPDATE_DELAYED")
    SafeRegister("CHAT_MSG_ADDON")

    -- Not all WoW clients expose Mythic+ events. SafeRegister keeps embeds
    -- harmless on clients such as WoW: Forever.
    SafeRegister("CHALLENGE_MODE_COMPLETED")
    SafeRegister("WEEKLY_REWARDS_UPDATE")
end
