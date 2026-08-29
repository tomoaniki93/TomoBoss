---@diagnostic disable: undefined-global
-- TomoBoss — Masquage de la timeline NATIVE de Blizzard.
--
-- `encounterWarningsEnabled` n'est PAS un simple réglage d'affichage : c'est lui
-- qui arme tout le système d'avertissements de rencontre du client, donc à la
-- fois les déclencheurs C_EncounterEvents utilisés par EventBridge ET la source
-- ENCOUNTER_TIMELINE_EVENT_* qui alimente TomoTimeline et les barres. Le couper
-- pour se débarrasser du cadre natif vide donc TomoTimeline en même temps.
--
-- C'est exactement le piège que ce module existe pour éviter. Masquer, ici, veut
-- dire « invisible et insensible à la souris », rien de plus :
--   * on ne coupe pas le CVar — on le remet même à 1 tant que la source
--     Blizzard est activée, sinon plus aucun minuteur n'arrive ;
--   * on n'appelle pas Hide() — un cadre caché ne reçoit plus d'OnUpdate, et le
--     déclencheur « highlight » (~5 s avant l'incantation) dont dépend le pont
--     sonore ne partirait plus.
--
-- Côté jeu, le cadre continue donc de tourner exactement comme avant : seul le
-- joueur ne le voit plus.

local NS = select(2, ...)
local H = {}
NS.BlizzardTimelineUI = H

-- Le nom du cadre natif n'est pas garanti d'une build à l'autre : on essaie les
-- noms connus, puis on balaie les enfants nommés d'UIParent en repli.
local NAMES = {
    "EncounterTimelineFrame",
    "EncounterTimelineContainerFrame",
    "EncounterTimelineContainer",
    "EncounterTimelineBar",
    "EncounterTimeline",
    "BossAbilityTimelineFrame",
}

local CVAR = "encounterWarningsEnabled"
local RESCAN_INTERVAL = 2.0
local ENFORCE_INTERVAL = 0.2
local FEED_INTERVAL = 5.0

local function isFrame(f)
    return type(f) == "table"
        and type(f.SetAlpha) == "function"
        and type(f.GetAlpha) == "function"
        and type(f.GetObjectType) == "function"
end

local function hideWanted()
    local c = NS.db and NS.db.profile and NS.db.profile.blizzTimeline
    return c and c.hideBlizzardUI ~= false
end

function H:Find()
    if self.frame then return self.frame end

    for _, n in ipairs(NAMES) do
        local f = _G[n]
        if isFrame(f) then
            self.frame, self.frameName = f, n
            NS:Debug("Timeline native : cadre trouvé -> ", n)
            return f
        end
    end

    local ok, kids = pcall(function() return { UIParent:GetChildren() } end)
    if ok and kids then
        for _, f in ipairs(kids) do
            local n = isFrame(f) and f.GetName and f:GetName()
            if type(n) == "string" and n:find("EncounterTimeline", 1, true) then
                self.frame, self.frameName = f, n
                NS:Debug("Timeline native : cadre trouvé par balayage -> ", n)
                return f
            end
        end
    end
    return nil
end

-- Le hook rend le masquage immédiat quand le jeu remonte l'alpha lui-même. Les
-- animations d'alpha ne passent pas par SetAlpha : le ticker reste nécessaire.
function H:Hook(f)
    if self._hooked or type(hooksecurefunc) ~= "function" then return end
    self._hooked = true
    hooksecurefunc(f, "SetAlpha", function()
        if H._applying or not hideWanted() then return end
        if f:GetAlpha() > 0.01 then
            H._applying = true
            f:SetAlpha(0)
            H._applying = false
        end
    end)
end

-- Garantit que la SOURCE des minuteurs reste armée. Indépendant d'EventBridge :
-- le pont peut être coupé, ou le joueur hors instance, TomoTimeline a quand même
-- besoin du CVar. Tant que « Activer la timeline Blizzard » est coché, on le
-- remet à 1 ; le décocher rend la main complète au joueur.
function H:EnsureFeed()
    local c = NS.db and NS.db.profile and NS.db.profile.blizzTimeline
    if not (c and c.enabled) then return end
    if not (C_CVar and C_CVar.GetCVar and C_CVar.SetCVar) then return end

    local ok, val = pcall(C_CVar.GetCVar, CVAR)
    if not ok or val == nil or tostring(val) ~= "0" then return end

    pcall(C_CVar.SetCVar, CVAR, "1")
    if not self._feedNotified then
        self._feedNotified = true
        NS:Print("Les avertissements de rencontre étaient coupés : ils fournissent "
            .. "le minutage de TomoTimeline, TomoBoss les a réactivés et masque "
            .. "seulement la timeline native. Pour tout rendre à Blizzard, décochez "
            .. "|cff8bd5caActiver la timeline Blizzard|r.")
    end
end

function H:Enforce()
    self:EnsureFeed()

    local f = self:Find()
    if not f then return false end
    self:Hook(f)

    if hideWanted() then
        if self._restore == nil then
            -- Capturé une seule fois. Un alpha nul au moment de la capture est
            -- un fondu en cours, pas la valeur de repos : on retient 1.
            local a = f:GetAlpha() or 1
            self._restore = {
                alpha = (a > 0.05) and a or 1,
                mouse = (f.IsMouseEnabled == nil) or (f:IsMouseEnabled() ~= false),
            }
        end
        if f:GetAlpha() > 0.01 then
            self._applying = true
            f:SetAlpha(0)
            self._applying = false
        end
        if f.IsMouseEnabled and f:IsMouseEnabled() then pcall(f.EnableMouse, f, false) end
    elseif self._restore then
        self._applying = true
        f:SetAlpha(self._restore.alpha)
        self._applying = false
        pcall(f.EnableMouse, f, self._restore.mouse)
        self._restore = nil
    end
    return true
end

function H:Init()
    if self.ticker then return end
    local t = CreateFrame("Frame")
    self.ticker = t
    t._acc = 0
    t._scan = 0
    t._feed = 0
    t:SetScript("OnUpdate", function(_, elapsed)
        t._acc = t._acc + elapsed
        if t._acc < ENFORCE_INTERVAL then return end
        t._acc = 0

        -- La source doit être vérifiée même quand le cadre natif reste
        -- introuvable : c'est elle qui fait vivre TomoTimeline, pas le cadre.
        t._feed = t._feed + ENFORCE_INTERVAL
        if t._feed >= FEED_INTERVAL then
            t._feed = 0
            H:EnsureFeed()
        end

        if not H.frame then
            -- Le cadre natif peut appartenir à un addon Blizzard chargé à la
            -- demande : on retente périodiquement, sans balayer à chaque image.
            t._scan = t._scan + ENFORCE_INTERVAL
            if t._scan < RESCAN_INTERVAL then return end
            t._scan = 0
            -- Le nom du cadre natif peut changer d'une build à l'autre : on le
            -- signale une fois plutôt que de balayer en silence pour toujours.
            t._waited = (t._waited or 0) + RESCAN_INTERVAL
            if t._waited > 20 and not t._warned then
                t._warned = true
                NS:Debug("Timeline native : cadre introuvable, masquage sans effet.")
            end
        end
        H:Enforce()
    end)
    self:Enforce()
end

local boot = CreateFrame("Frame")
boot:RegisterEvent("PLAYER_LOGIN")
boot:RegisterEvent("PLAYER_ENTERING_WORLD")
boot:RegisterEvent("ENCOUNTER_START")
-- CVAR_UPDATE : le joueur vient peut-être de couper les avertissements dans les
-- options du jeu. On le rattrape tout de suite plutôt qu'au prochain tick lent.
boot:RegisterEvent("CVAR_UPDATE")
boot:SetScript("OnEvent", function(_, event, arg1)
    if event == "PLAYER_LOGIN" then
        H:Init()
    elseif event == "CVAR_UPDATE" then
        if arg1 == nil or arg1 == CVAR then H:EnsureFeed() end
    else
        H:EnsureFeed()
    end
end)
