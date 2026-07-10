---@diagnostic disable: undefined-global
-- TomoBoss — Barres de minuteur de boss (instance de BarGroup).

local NS = select(2, ...)
NS.UI = NS.UI or {}

-- Crée l'instance des barres de boss (appelé au login, après l'init de la base).
function NS.UI.InitBossBars()
    if NS.UI.TimerBars then return NS.UI.TimerBars end
    local g = NS.UI.CreateBarGroup("TimerBars", NS.db.profile.bars)
    g.demoFn = function(self, on)
        if on then
            local now = GetTime()
            self:AddOrUpdate("__demo1", { name = "Frappe de mine",      duration = 40, endTime = now + 12, severity = 0, icon = 135834, ignoreWindow = true })
            self:AddOrUpdate("__demo2", { name = "Piétinement glacial",  duration = 40, endTime = now + 24, severity = 1, icon = 135843, ignoreWindow = true })
            self:AddOrUpdate("__demo3", { name = "Surcharge glaciaire",  duration = 40, endTime = now + 36, severity = 2, icon = 135838, ignoreWindow = true })
        else
            self:Remove("__demo1"); self:Remove("__demo2"); self:Remove("__demo3")
        end
    end
    NS.UI.TimerBars = g
    return g
end
