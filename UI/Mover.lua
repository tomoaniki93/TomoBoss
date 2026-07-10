---@diagnostic disable: undefined-global
-- TomoBoss — Déplacement des éléments (mode édition léger).

local NS = select(2, ...)
NS.UI = NS.UI or {}
local Mover = {}
NS.UI.Mover = Mover

Mover.regs = {}
Mover.editing = false

-- Enregistre un cadre déplaçable.
--   name    : clé de sauvegarde
--   frame   : cadre d'ancrage (taille explicite requise)
--   label   : texte affiché sur la poignée
--   default : { point, relPoint, x, y }
--   demoFn  : fonction(bool) pour afficher un aperçu en mode édition
function Mover:Register(name, frame, label, default, demoFn)
    self.regs[name] = { name = name, frame = frame, label = label, default = default, demo = demoFn }
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    self:ApplyPosition(name)
end

function Mover:ApplyPosition(name)
    local r = self.regs[name]
    if not r then return end
    local pos = NS.db and NS.db.profile.positions and NS.db.profile.positions[name]
    r.frame:ClearAllPoints()
    if pos then
        r.frame:SetPoint(pos.point, UIParent, pos.relPoint or pos.point, pos.x, pos.y)
    else
        local d = r.default
        r.frame:SetPoint(d.point, UIParent, d.relPoint or d.point, d.x, d.y)
    end
end

function Mover:ApplyAll()
    for name in pairs(self.regs) do self:ApplyPosition(name) end
end

local function ensureHandle(r)
    if r.handle then return r.handle end
    local C = NS.Theme.colors
    local h = CreateFrame("Frame", nil, r.frame)
    h:SetAllPoints(r.frame)
    h:SetFrameStrata("FULLSCREEN_DIALOG")
    NS.Theme:Skin(h, { bg = C.mint, alpha = 0.10, border = C.mint, borderAlpha = 0.9 })

    h.label = h:CreateFontString(nil, "OVERLAY")
    h.label:SetPoint("CENTER")
    NS.Theme:Font(h.label, 12, "mint")
    h.label:SetText(r.label or r.name)

    h.hint = h:CreateFontString(nil, "OVERLAY")
    h.hint:SetPoint("TOP", h.label, "BOTTOM", 0, -2)
    NS.Theme:Font(h.hint, 10, "muted")
    h.hint:SetText(NS.L.MOVER_HINT)

    h:EnableMouse(true)
    h:RegisterForDrag("LeftButton")
    h:SetScript("OnDragStart", function() r.frame:StartMoving() end)
    h:SetScript("OnDragStop", function()
        r.frame:StopMovingOrSizing()
        local point, _, relPoint, x, y = r.frame:GetPoint(1)
        NS.db.profile.positions = NS.db.profile.positions or {}
        NS.db.profile.positions[r.name] = {
            point = point, relPoint = relPoint,
            x = NS.round(x, 1), y = NS.round(y, 1),
        }
    end)
    r.handle = h
    return h
end

function Mover:SetEditMode(on)
    self.editing = on and true or false
    for _, r in pairs(self.regs) do
        local h = ensureHandle(r)
        if self.editing then h:Show() else h:Hide() end
        if r.demo then pcall(r.demo, self.editing) end
    end
    if NS.db then NS.db.profile.locked = not self.editing end
end

function Mover:Toggle()
    self:SetEditMode(not self.editing)
    return self.editing
end
