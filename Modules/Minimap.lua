---@diagnostic disable: undefined-global
-- TomoBoss — Bouton de minicarte (ouvre les options ; déplaçable autour du bord).

local NS = select(2, ...)
local M = {}
NS.Minimap = M

local ICON = "Interface\\AddOns\\TomoBoss\\Media\\Textures\\TomoBoss_TMB_Icon_64.tga"

local function cfg() return NS.db.profile.minimap end

local function showTooltip(owner, includeDragHint)
    if not owner then return end
    GameTooltip:SetOwner(owner, "ANCHOR_LEFT")
    GameTooltip:AddLine("|cff33e6a6Tomo|r|cffe6edeaBoss|r")
    GameTooltip:AddLine("Clic gauche : ouvrir les options", 0.9, 0.9, 0.9)
    GameTooltip:AddLine("Clic droit : versions du groupe", 0.9, 0.9, 0.9)
    if includeDragHint then
        GameTooltip:AddLine("Glisser : déplacer l'icône", 0.6, 0.6, 0.6)
    end
    GameTooltip:Show()
end

local function updatePos(btn)
    local angle = math.rad(cfg().angle or 210)
    local r = (Minimap:GetWidth() * 0.5) + 5
    local x, y = math.cos(angle), math.sin(angle)
    -- Follow the minimap shape: on a SQUARE minimap (e.g. TomoMod), project the
    -- point onto the square edge instead of the round radius so the button sits
    -- on the border, like LibDBIcon buttons. Round minimaps stay unchanged.
    local shape = (GetMinimapShape and GetMinimapShape()) or "ROUND"
    if shape == "SQUARE" then
        local m = math.max(math.abs(x), math.abs(y))
        if m > 0 then x, y = x / m, y / m end
    end
    btn:ClearAllPoints()
    btn:SetPoint("CENTER", Minimap, "CENTER", r * x, r * y)
end

function M:Init()
    if self.btn then
        self.btn:SetShown(not cfg().hide)
        return
    end
    if cfg().hide then return end

    local btn = CreateFrame("Button", "TomoBossMinimapButton", Minimap)
    btn:SetSize(31, 31)
    btn:SetFrameStrata("MEDIUM")
    btn:SetFrameLevel(8)
    self.btn = btn

    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(ICON)
    icon:SetAllPoints(btn)
    icon:SetTexCoord(0, 1, 0, 1)
    btn.icon = icon

    -- Le logo TMB possède déjà son propre anneau doré/violet.
    local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    highlight:SetBlendMode("ADD")
    highlight:SetAllPoints(btn)
    highlight:SetAlpha(0.55)

    btn:RegisterForDrag("LeftButton")
    btn:SetMovable(true)
    btn:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", function(self)
            local mx, my = Minimap:GetCenter()
            local scale = Minimap:GetEffectiveScale()
            local cx, cy = GetCursorPosition()
            cx, cy = cx / scale, cy / scale
            cfg().angle = math.deg(math.atan2(cy - my, cx - mx))
            updatePos(self)
        end)
    end)
    btn:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)

    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "RightButton" then
            if NS.Version then NS.Version:Query() end
        else
            NS.GUI.Config:Toggle()
        end
    end)

    btn:SetScript("OnEnter", function(self)
        showTooltip(self, true)
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    updatePos(btn)
end

-- Affiche / masque (depuis les options).
function M:SetShown(show)
    cfg().hide = not show
    if self.btn then
        self.btn:SetShown(show)
    elseif show then
        self:Init()
    end
end


----------------------------------------------------------------------
-- Blizzard Addon Compartment
--
-- L'icône du compartiment vient de ## IconTexture dans le TOC.
-- Les callbacks sont globaux car Blizzard les résout par leur nom.
----------------------------------------------------------------------

_G.TomoBoss_OnAddonCompartmentClick = function(_, mouseButton)
    if mouseButton == "RightButton" then
        if NS.Version then NS.Version:Query() end
    else
        if NS.GUI and NS.GUI.Config then
            NS.GUI.Config:Toggle()
        end
    end
end

_G.TomoBoss_OnAddonCompartmentEnter = function(owner)
    showTooltip(owner, false)
end

_G.TomoBoss_OnAddonCompartmentLeave = function()
    GameTooltip:Hide()
end
