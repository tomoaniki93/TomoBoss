---@diagnostic disable: undefined-global
-- TomoBoss — Contrôleur commun des renderers de minuteurs.
--
-- Flux cible : producteurs (Engine/BlizzTimeline/Custom) -> TimerModel -> ici ->
-- renderer(s). Le Lot 2A enregistre uniquement "bars" ; TomoTimeline pourra se
-- brancher ensuite via RegisterRenderer("timeline", renderer).

local NS = select(2, ...)
NS.UI = NS.UI or {}

local Display = {
    renderers = {},
    model = NS.UI.TimerModel,
}
NS.UI.DisplayController = Display

local VALID_MODES = {
    bars = true,
    timeline = true,
    hybrid = true,
}

local function config()
    local profile = NS.db and NS.db.profile
    return profile and profile.display
end

function Display:GetRequestedMode()
    local c = config()
    local mode = c and c.timerMode or "bars"
    if not VALID_MODES[mode] then return "bars" end
    return mode
end

function Display:HasRenderer(id)
    return type(self.renderers[id]) == "table"
end

function Display:GetResolvedMode()
    local requested = self:GetRequestedMode()
    if requested == "bars" then return "bars" end
    if requested == "timeline" and self:HasRenderer("timeline") then return "timeline" end
    if requested == "hybrid" and self:HasRenderer("timeline") then return "hybrid" end

    local c = config()
    if not c or c.fallbackToBars ~= false then return "bars" end
    return requested
end

function Display:RegisterRenderer(id, renderer)
    if type(id) ~= "string" or type(renderer) ~= "table" then return false end
    self.renderers[id] = renderer

    -- Si le renderer arrive après que le modèle contient déjà des événements,
    -- une simple réconciliation suffit ; aucun producteur n'a besoin de rejouer.
    self:RefreshAll()
    return true
end

function Display:UnregisterRenderer(id)
    local renderer = self.renderers[id]
    if not renderer then return end
    if renderer.Clear then renderer:Clear() end
    self.renderers[id] = nil
end

local function wantsRenderer(mode, id)
    if mode == "bars" then return id == "bars" end
    if mode == "timeline" then return id == "timeline" end
    if mode == "hybrid" then return id == "bars" or id == "timeline" end
    return false
end

function Display:RenderEntry(entry)
    if not entry then return end
    local mode = self:GetResolvedMode()

    for id, renderer in pairs(self.renderers) do
        if wantsRenderer(mode, id) then
            if renderer.AddOrUpdate then
                local payload = (id == "bars" and self.model:ToBarData(entry)) or entry
                renderer:AddOrUpdate(entry.key, payload)
            end
        elseif renderer.Remove then
            renderer:Remove(entry.key)
        end
    end
end

function Display:Upsert(key, data, meta)
    local entry = self.model:Upsert(key, data, meta)
    if not entry then return nil end
    self:RenderEntry(entry)
    return entry
end

function Display:Remove(key)
    local entry = self.model:Remove(key)
    for _, renderer in pairs(self.renderers) do
        if renderer.Remove then renderer:Remove(key) end
    end
    return entry
end

function Display:Clear()
    self.model:Clear()
    for _, renderer in pairs(self.renderers) do
        if renderer.Clear then renderer:Clear() end
    end
end

function Display:RefreshAll()
    for _, renderer in pairs(self.renderers) do
        if renderer.Clear then renderer:Clear() end
    end
    self.model:Each(function(entry)
        self:RenderEntry(entry)
    end)
end

function Display:SetMode(mode)
    if not VALID_MODES[mode] then return false end
    local c = config()
    if c then c.timerMode = mode end
    self:RefreshAll()
    return self:GetResolvedMode()
end

function Display:RestyleRenderer(id)
    local renderer = self.renderers[id]
    if renderer and renderer.Restyle then renderer:Restyle() end
end

function Display:GetRenderer(id)
    return self.renderers[id]
end
