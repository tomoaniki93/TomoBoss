---@diagnostic disable: undefined-global
-- TomoBoss — Façade historique des minuteurs de boss + renderer BarGroup.
--
-- Les producteurs existants continuent d'appeler NS.UI.TimerBars sans changement.
-- La façade envoie désormais les données au DisplayController, qui alimente le
-- TimerModel commun puis le renderer actif. Cela permet d'ajouter TomoTimeline
-- sans dupliquer le moteur de prédiction ou la source Blizzard.

local NS = select(2, ...)
NS.UI = NS.UI or {}

-- Crée l'instance des barres de boss (appelé au login, après l'init de la base).
function NS.UI.InitBossBars()
    if NS.UI.TimerBars then return NS.UI.TimerBars end

    local renderer = NS.UI.CreateBarGroup("TimerBars", NS.db.profile.bars)
    renderer.demoFn = function(self, on)
        if on then
            local now = GetTime()
            self:AddOrUpdate("__demo1", { name = "Frappe de mine",       duration = 40, endTime = now + 12, severity = 0, icon = 135834, ignoreWindow = true })
            self:AddOrUpdate("__demo2", { name = "Piétinement glacial", duration = 40, endTime = now + 24, severity = 1, icon = 135843, ignoreWindow = true })
            self:AddOrUpdate("__demo3", { name = "Surcharge glaciaire", duration = 40, endTime = now + 36, severity = 2, icon = 135838, ignoreWindow = true })
        else
            self:Remove("__demo1"); self:Remove("__demo2"); self:Remove("__demo3")
        end
    end

    NS.UI.BossBarsRenderer = renderer
    NS.UI.DisplayController:RegisterRenderer("bars", renderer)

    -- API de compatibilité. Les méthodes liées aux données transitent par le
    -- contrôleur ; les méthodes purement visuelles restent déléguées aux barres.
    local facade = {}

    function facade:EnsureAnchor()
        local anchor = renderer:EnsureAnchor()
        self.anchor = anchor
        return anchor
    end

    function facade:AddOrUpdate(key, data)
        return NS.UI.DisplayController:Upsert(key, data)
    end

    function facade:Remove(key)
        return NS.UI.DisplayController:Remove(key)
    end

    function facade:Clear()
        return NS.UI.DisplayController:Clear()
    end

    function facade:Has(key)
        return NS.UI.TimerModel:Has(key)
    end

    function facade:Layout()
        return renderer:Layout()
    end

    function facade:Tick()
        return renderer:Tick()
    end

    function facade:Restyle()
        NS.UI.DisplayController:RestyleRenderer("bars")
        self.anchor = renderer.anchor
    end

    -- Le mode édition doit toujours pouvoir prévisualiser la zone des barres,
    -- indépendamment du futur mode Timeline sélectionné dans le profil.
    function facade:ShowDemo(on)
        return renderer:ShowDemo(on)
    end

    setmetatable(facade, { __index = renderer })
    NS.UI.TimerBars = facade
    return facade
end
