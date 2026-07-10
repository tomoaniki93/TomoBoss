---@diagnostic disable: undefined-global
-- TomoBoss — Compte à rebours de pull (groupe ou solo) + voix du décompte.

local NS = select(2, ...)
NS.Engine = NS.Engine or {}
local P = {}
NS.Engine.Pull = P

local MAX_VOICE = 5  -- on ne possède que les fichiers 1..5
local DEFAULT = 10

local function voiceCfg() return NS.db.profile.voice end

--------------------------------------------------------------------------
-- Affichage (widget + voix). Piloté soit directement (solo), soit par
-- l'événement START_PLAYER_COUNTDOWN (groupe / DBM / natif).
--------------------------------------------------------------------------
function P:EnsureTicker()
    if self.ticker then return self.ticker end
    self.ticker = CreateFrame("Frame")
    self.ticker:Hide()
    self.ticker:SetScript("OnUpdate", function() self:VoiceTick() end)
    return self.ticker
end

function P:BeginDisplay(seconds)
    seconds = tonumber(seconds)
    if not seconds or seconds <= 0 then return end
    self.dispEnd = GetTime() + seconds
    self.played = {}
    NS.UI.Countdown:Start(seconds)
    self:EnsureTicker():Show()
end

function P:EndDisplay()
    self.dispEnd = nil
    NS.UI.Countdown:Stop()
    if self.ticker then self.ticker:Hide() end
end

function P:VoiceTick()
    if not self.dispEnd then return end
    local remaining = self.dispEnd - GetTime()
    if remaining <= 0 then
        self:EndDisplay()
        return
    end
    local n = math.ceil(remaining)
    if n >= 1 and n <= MAX_VOICE and not self.played[n] then
        self.played[n] = true
        if voiceCfg().countdown then NS.Voice:PlayCountdown(n) end
    end
end

--------------------------------------------------------------------------
-- Lancement.
--------------------------------------------------------------------------
function P:StartPull(seconds)
    seconds = math.floor((tonumber(seconds) or DEFAULT) + 0.0001)
    if seconds < 0 then return end

    if IsInGroup() and C_PartyInfo and type(C_PartyInfo.DoCountdown) == "function" then
        -- décompte de groupe Blizzard : START_PLAYER_COUNTDOWN pilotera l'affichage
        C_PartyInfo.DoCountdown(seconds)
    else
        self:BeginDisplay(seconds)
    end
end

function P:CancelPull()
    if IsInGroup() and C_PartyInfo and type(C_PartyInfo.DoCountdown) == "function" then
        C_PartyInfo.DoCountdown(0)
    end
    self:EndDisplay()
end

--------------------------------------------------------------------------
-- Événements du client (garde-fous secretvalue).
--------------------------------------------------------------------------
function P:OnStartCountdown(initiatedBy, timeRemaining, totalTime)
    if NS:IsSecret(initiatedBy) or NS:IsSecret(timeRemaining) or NS:IsSecret(totalTime) then return end
    local seconds = NS:SafeNumber(totalTime)
    if not seconds or seconds <= 0 then seconds = NS:SafeNumber(timeRemaining) end
    if not seconds or seconds <= 0 then return end
    self:BeginDisplay(seconds)
end

function P:OnCancelCountdown()
    self:EndDisplay()
end

--------------------------------------------------------------------------
-- Commande /tmb pull [n | stop]
--------------------------------------------------------------------------
function P:HandleSlash(rest)
    local text = tostring(rest or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if text == "" then
        self:StartPull(DEFAULT)
        return
    end
    local low = text:lower()
    if low == "stop" or low == "cancel" or low == "annuler" then
        self:CancelPull()
        return
    end
    local n = tonumber(text)
    if not n then
        NS:Print(NS.L.MSG_PULL_USAGE)
        return
    end
    self:StartPull(n)
end

-- Alias /pull si aucun autre addon ne l'utilise déjà.
function P:TryRegisterPullAlias()
    if self._alias then return end
    if type(SlashCmdList) ~= "table" then return end
    if _G.BigWigs or _G.DBM or SlashCmdList.PULL or SlashCmdList["DEADLYBOSSMODSPULL"] then return end
    SLASH_TOMOBOSSPULL1 = "/pull"
    SlashCmdList["TOMOBOSSPULL"] = function(input) P:HandleSlash(input) end
    self._alias = true
end
