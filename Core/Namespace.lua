---@diagnostic disable: undefined-global
-- TomoBoss — Espace de noms global, version, bus d'événements, utilitaires.

local ADDON, NS = ...

NS.name    = ADDON
NS.version = C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(ADDON, "Version") or "2.2.0"

-- Table globale accessible en jeu (pour /run, debug, autres addons).
TomoBoss = NS

--------------------------------------------------------------------------
-- Petit bus d'événements interne (pub/sub), indépendant du moteur WoW.
--------------------------------------------------------------------------
NS.Bus = NS.Bus or { _h = {} }

function NS.Bus:On(evt, fn)
    self._h[evt] = self._h[evt] or {}
    table.insert(self._h[evt], fn)
end

function NS.Bus:Emit(evt, ...)
    local list = self._h[evt]
    if not list then return end
    for i = 1, #list do
        local ok, err = pcall(list[i], ...)
        if not ok then
            NS:Debug("Erreur dans un abonné de", evt, ":", err)
        end
    end
end

--------------------------------------------------------------------------
-- Impression console (préfixe coloré menthe).
--------------------------------------------------------------------------
local PREFIX = "|cff33e6a6TomoBoss|r"

function NS:Print(...)
    local parts = {}
    for i = 1, select("#", ...) do parts[i] = tostring(select(i, ...)) end
    print(PREFIX .. " " .. table.concat(parts, " "))
end

function NS:Debug(...)
    if not (self.db and self.db.profile and self.db.profile.debug) then return end
    local parts = {}
    for i = 1, select("#", ...) do parts[i] = tostring(select(i, ...)) end
    print("|cff8a968f[TMB dbg]|r " .. table.concat(parts, " "))
end

--------------------------------------------------------------------------
-- Garde-fous « secretvalue » (WoW Midnight) — jamais comparer directement.
--------------------------------------------------------------------------
function NS:IsSecret(v)
    return type(issecretvalue) == "function" and issecretvalue(v) == true
end

-- Convertit en nombre en sécurité (renvoie nil si masqué / invalide).
function NS:SafeNumber(v)
    if self:IsSecret(v) then return nil end
    local ok, n = pcall(tonumber, v)
    if ok then return n end
    return nil
end

--------------------------------------------------------------------------
-- Utilitaires divers.
--------------------------------------------------------------------------
function NS.round(x, dec)
    local m = 10 ^ (dec or 0)
    return math.floor(x * m + 0.5) / m
end

function NS.clamp(x, lo, hi)
    if x < lo then return lo elseif x > hi then return hi end
    return x
end

-- Formate une durée en secondes de façon lisible (m:ss ou s.d).
function NS.fmtTime(t)
    if t >= 60 then
        return string.format("%d:%02d", math.floor(t / 60), math.floor(t % 60))
    elseif t >= 10 then
        return string.format("%d", math.floor(t + 0.5))
    else
        return string.format("%.1f", t)
    end
end
