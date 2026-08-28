---@diagnostic disable: undefined-global
-- TomoBoss — Lot 3 : choix du renderer de minuteurs dans le GUI.
--
-- Chargé après GUI/Config.lua. On remplace uniquement la page historique
-- "Barres" par une page "Affichage" : le reste du GUI reste inchangé.

local NS = select(2, ...)
if not (NS.GUI and NS.GUI.Config) then return end

local Config = NS.GUI.Config
local L = setmetatable({}, { __index = function(_, k) return NS.L[k] or k end })

-- ---------------------------------------------------------------------------
-- Localisation ajoutée sans modifier Core/Locale.lua.
-- Les tables existent déjà à ce stade ; NS.L pointe sur l'une d'elles (ou sur
-- frFR en repli), donc les nouvelles clés sont immédiatement disponibles.
-- ---------------------------------------------------------------------------
local fr = NS.Locales and NS.Locales.frFR
if fr then
    fr.TAB_BARS              = "Affichage"
    fr.BARS_TITLE            = "Affichage des minuteurs"
    fr.DISPLAY_MODE          = "Mode d'affichage"
    fr.DISPLAY_MODE_BARS     = "Barres"
    fr.DISPLAY_MODE_TIMELINE = "Timeline"
    fr.DISPLAY_MODE_HYBRID   = "Hybride"
    fr.DISPLAY_BARS_TITLE    = "Barres classiques"
    fr.DISPLAY_BARS_DESC     = "Affichage compact et familier. Chaque capacité possède sa barre avec icône, nom et compte à rebours."
    fr.DISPLAY_TL_TITLE      = "TomoTimeline"
    fr.DISPLAY_TL_DESC       = "Les capacités avancent vers NOW sur une ligne du temps. Idéal pour anticiper l'ordre des mécaniques à venir."
    fr.DISPLAY_HYBRID_TITLE  = "Mode hybride"
    fr.DISPLAY_HYBRID_DESC   = "Affiche les Boss Bars V2 et TomoTimeline en même temps : lecture immédiate + vision d'ensemble."
    fr.DISPLAY_SETTINGS      = "Réglages affichés"
    fr.DISPLAY_SETTINGS_BARS = "Régler les barres"
    fr.DISPLAY_SETTINGS_TL   = "Régler la timeline"
    fr.DISPLAY_BARS_OPTIONS  = "Réglages des barres"
    fr.DISPLAY_TL_OPTIONS    = "Réglages de TomoTimeline"
    fr.DISPLAY_UNAVAILABLE   = "TomoTimeline n'est pas chargée : TomoBoss reviendra automatiquement aux barres."
    fr.TL_WIDTH              = "Largeur de la timeline"
    fr.TL_HEIGHT             = "Hauteur de la timeline"
    fr.TL_WINDOW             = "Fenêtre temporelle"
    fr.TL_ICONSIZE           = "Taille des icônes"
    fr.TL_PRIORITY           = "Seuil d'urgence"
    fr.TL_SHOW_TICKS         = "Afficher les graduations"
    fr.TL_SHOW_NAME          = "Afficher le nom des capacités"
    fr.TL_SHOW_TIME          = "Afficher le temps restant"
    fr.VALUE_ALWAYS          = "Toujours"
    fr.BLIZZ_BAR             = "Afficher la source Blizzard en mode Barres"
end

local en = NS.Locales and NS.Locales.enUS
if en then
    en.TAB_BARS              = "Display"
    en.BARS_TITLE            = "Timer display"
    en.DISPLAY_MODE          = "Display mode"
    en.DISPLAY_MODE_BARS     = "Bars"
    en.DISPLAY_MODE_TIMELINE = "Timeline"
    en.DISPLAY_MODE_HYBRID   = "Hybrid"
    en.DISPLAY_BARS_TITLE    = "Classic bars"
    en.DISPLAY_BARS_DESC     = "Compact and familiar display. Each ability gets a bar with icon, name and countdown."
    en.DISPLAY_TL_TITLE      = "TomoTimeline"
    en.DISPLAY_TL_DESC       = "Abilities move toward NOW on a timeline. Best for anticipating the order of upcoming mechanics."
    en.DISPLAY_HYBRID_TITLE  = "Hybrid mode"
    en.DISPLAY_HYBRID_DESC   = "Shows Boss Bars V2 and TomoTimeline together: immediate readability plus the bigger picture."
    en.DISPLAY_SETTINGS      = "Settings shown"
    en.DISPLAY_SETTINGS_BARS = "Configure bars"
    en.DISPLAY_SETTINGS_TL   = "Configure timeline"
    en.DISPLAY_BARS_OPTIONS  = "Bar settings"
    en.DISPLAY_TL_OPTIONS    = "TomoTimeline settings"
    en.DISPLAY_UNAVAILABLE   = "TomoTimeline is not loaded: TomoBoss will automatically fall back to bars."
    en.TL_WIDTH              = "Timeline width"
    en.TL_HEIGHT             = "Timeline height"
    en.TL_WINDOW             = "Time window"
    en.TL_ICONSIZE           = "Icon size"
    en.TL_PRIORITY           = "Urgency threshold"
    en.TL_SHOW_TICKS         = "Show tick marks"
    en.TL_SHOW_NAME          = "Show ability names"
    en.TL_SHOW_TIME          = "Show remaining time"
    en.VALUE_ALWAYS          = "Always"
    en.BLIZZ_BAR             = "Show Blizzard source in Bars mode"
end

local function layout(frame, x, top)
    local o = { frame = frame, x = x or 0, y = -(top or 0) }
    function o:Add(ctrl, h, dx)
        ctrl:ClearAllPoints()
        ctrl:SetPoint("TOPLEFT", self.frame, "TOPLEFT", self.x + (dx or 0), self.y)
        self.y = self.y - (h or (ctrl.GetHeight and ctrl:GetHeight()) or 24) - 10
        return ctrl
    end
    function o:Gap(v) self.y = self.y - (v or 6) end
    return o
end

local function ensureTimelineDefaults()
    local p = NS.db and NS.db.profile
    if not p then return {} end
    p.timeline = p.timeline or {}
    local t = p.timeline
    if t.width == nil then t.width = 340 end
    if t.height == nil then t.height = 420 end
    if t.window == nil then t.window = 40 end
    if t.iconSize == nil then t.iconSize = 32 end
    if t.priorityThreshold == nil then t.priorityThreshold = 5 end
    if t.showTicks == nil then t.showTicks = true end
    if t.showName == nil then t.showName = true end
    if t.showTime == nil then t.showTime = true end
    return t
end

local function restyleTimeline()
    if NS.UI and NS.UI.TomoTimeline and NS.UI.TomoTimeline.Restyle then
        NS.UI.TomoTimeline:Restyle()
    end
end

local function modeLabel(mode)
    if mode == "timeline" then return L.DISPLAY_MODE_TIMELINE end
    if mode == "hybrid" then return L.DISPLAY_MODE_HYBRID end
    return L.DISPLAY_MODE_BARS
end

local function modeCopy(mode)
    if mode == "timeline" then return L.DISPLAY_TL_TITLE, L.DISPLAY_TL_DESC end
    if mode == "hybrid" then return L.DISPLAY_HYBRID_TITLE, L.DISPLAY_HYBRID_DESC end
    return L.DISPLAY_BARS_TITLE, L.DISPLAY_BARS_DESC
end

-- ---------------------------------------------------------------------------
-- Nouvelle page Affichage.
-- ---------------------------------------------------------------------------
function Config:BuildBars(page)
    local profile = NS.db.profile
    profile.display = profile.display or { timerMode = "bars", fallbackToBars = true }
    local display = profile.display
    local bars = profile.bars
    local timeline = ensureTimelineDefaults()
    local C = NS.Theme.colors

    local title = NS.Theme:SectionTitle(page, L.BARS_TITLE)
    title:SetPoint("TOPLEFT", 22, -18)

    local modeLbl = page:CreateFontString(nil, "OVERLAY")
    NS.Theme:Font(modeLbl, 12, "muted")
    modeLbl:SetPoint("TOPLEFT", 22, -54)
    modeLbl:SetText(L.DISPLAY_MODE)

    local modeDD
    modeDD = NS.Theme:CreateDropdown(page, {
        width = 240,
        items = {
            { value = "bars",     text = L.DISPLAY_MODE_BARS },
            { value = "timeline", text = L.DISPLAY_MODE_TIMELINE },
            { value = "hybrid",   text = L.DISPLAY_MODE_HYBRID },
        },
        onSelect = function(mode)
            local resolved = mode
            if NS.UI and NS.UI.DisplayController then
                resolved = NS.UI.DisplayController:SetMode(mode) or mode
            else
                display.timerMode = mode
            end
            modeDD:SetValue(resolved, modeLabel(resolved))
            if Config._displayRefresh then Config._displayRefresh(resolved) end
        end,
    })
    modeDD:SetPoint("TOPLEFT", 22, -74)
    self._displayModeDD = modeDD

    -- Carte explicative : le texte change immédiatement avec le mode choisi.
    local info = NS.Theme:CreateCard(page, { bg = C.bg1, border = C.line, shadowAlpha = 0.14 })
    info:SetPoint("TOPLEFT", 282, -54)
    info:SetSize(276, 76)

    local infoTitle = info:CreateFontString(nil, "OVERLAY")
    NS.Theme:Font(infoTitle, 13, "accentHi")
    infoTitle:SetPoint("TOPLEFT", 12, -11)
    infoTitle:SetPoint("TOPRIGHT", -12, -11)
    infoTitle:SetJustifyH("LEFT")

    local infoBody = info:CreateFontString(nil, "OVERLAY")
    NS.Theme:Font(infoBody, 11, "textSoft")
    infoBody:SetPoint("TOPLEFT", infoTitle, "BOTTOMLEFT", 0, -7)
    infoBody:SetPoint("RIGHT", -12, 0)
    infoBody:SetJustifyH("LEFT")
    infoBody:SetWordWrap(true)

    local unavailable = page:CreateFontString(nil, "OVERLAY")
    NS.Theme:Font(unavailable, 10, "warn")
    unavailable:SetPoint("TOPLEFT", 22, -116)
    unavailable:SetWidth(530)
    unavailable:SetJustifyH("LEFT")
    unavailable:SetText(L.DISPLAY_UNAVAILABLE)
    unavailable:Hide()

    -- En hybride, les deux renderers sont actifs mais le panneau ne peut pas
    -- afficher confortablement tous les sliders simultanément. Ce sélecteur ne
    -- change PAS le mode : il choisit seulement quel bloc de réglages éditer.
    local focusLbl = page:CreateFontString(nil, "OVERLAY")
    NS.Theme:Font(focusLbl, 11, "muted")
    focusLbl:SetPoint("TOPLEFT", 22, -143)
    focusLbl:SetText(L.DISPLAY_SETTINGS)

    local hybridFocus = "bars"
    local focusDD
    focusDD = NS.Theme:CreateDropdown(page, {
        width = 240,
        items = {
            { value = "bars", text = L.DISPLAY_SETTINGS_BARS },
            { value = "timeline", text = L.DISPLAY_SETTINGS_TL },
        },
        onSelect = function(v)
            hybridFocus = v
            if Config._displayRefresh then Config._displayRefresh("hybrid") end
        end,
    })
    focusDD:SetPoint("TOPLEFT", 22, -162)
    focusDD:SetValue("bars", L.DISPLAY_SETTINGS_BARS)

    local contentTop = -205
    local barsPage = CreateFrame("Frame", nil, page)
    barsPage:SetPoint("TOPLEFT", 22, contentTop)
    barsPage:SetPoint("BOTTOMRIGHT", -20, 18)

    local timelinePage = CreateFrame("Frame", nil, page)
    timelinePage:SetAllPoints(barsPage)

    -- -------------------------- réglages Bars -----------------------------
    do
        local lay = layout(barsPage, 0, 0)
        lay:Add(NS.Theme:SectionTitle(barsPage, L.DISPLAY_BARS_OPTIONS), 18)

        local function slider(label, key, min, max, step, fmt)
            local s = NS.Theme:CreateSlider(barsPage, {
                label = label, min = min, max = max, step = step,
                value = bars[key], width = 330, fmt = fmt,
            })
            s:SetCallback(function(v)
                bars[key] = (step >= 1) and math.floor(v + 0.5) or v
                if NS.UI and NS.UI.TimerBars then NS.UI.TimerBars:Restyle() end
            end)
            lay:Add(s, 42)
            return s
        end

        slider(L.BARS_WIDTH, "width", 120, 360, 2, function(v) return string.format("%d px", v) end)
        slider(L.BARS_HEIGHT, "height", 14, 40, 1, function(v) return string.format("%d px", v) end)
        slider(L.BARS_MAX, "maxBars", 1, 12, 1, function(v) return string.format("%d", v) end)
        slider(L.BARS_SPACING, "spacing", 0, 14, 1, function(v) return string.format("%d px", v) end)
        slider(L.BARS_FONTSIZE, "fontSize", 8, 22, 1, function(v) return string.format("%d", v) end)
        slider(L.BARS_WINDOW, "showWindow", 0, 60, 1, function(v)
            if v < 1 then return L.VALUE_ALWAYS end
            return string.format("%d s", v)
        end)

        local growLbl = barsPage:CreateFontString(nil, "OVERLAY")
        NS.Theme:Font(growLbl, 12, "muted")
        growLbl:SetText(L.BARS_GROW)
        lay:Add(growLbl, 14)

        local grow = NS.Theme:CreateDropdown(barsPage, {
            width = 220,
            items = {
                { value = "down", text = L.BARS_GROW_DOWN },
                { value = "up", text = L.BARS_GROW_UP },
            },
            onSelect = function(v)
                bars.grow = v
                if NS.UI and NS.UI.TimerBars then NS.UI.TimerBars:Restyle() end
            end,
        })
        grow:SetValue(bars.grow)
        lay:Add(grow, 28)

        local icon = NS.Theme:CreateCheck(barsPage, L.BARS_ICON)
        icon:SetChecked(bars.showIcon)
        icon:SetCallback(function(v)
            bars.showIcon = v
            if NS.UI and NS.UI.TimerBars then NS.UI.TimerBars:Restyle() end
        end)
        lay:Add(icon, 20)
    end

    -- ------------------------ réglages Timeline ---------------------------
    do
        local lay = layout(timelinePage, 0, 0)
        lay:Add(NS.Theme:SectionTitle(timelinePage, L.DISPLAY_TL_OPTIONS), 18)

        local function slider(label, key, min, max, step, fmt)
            local s = NS.Theme:CreateSlider(timelinePage, {
                label = label, min = min, max = max, step = step,
                value = timeline[key], width = 330, fmt = fmt,
            })
            s:SetCallback(function(v)
                timeline[key] = (step >= 1) and math.floor(v + 0.5) or v
                restyleTimeline()
            end)
            lay:Add(s, 42)
            return s
        end

        slider(L.TL_WIDTH, "width", 240, 520, 10, function(v) return string.format("%d px", v) end)
        slider(L.TL_HEIGHT, "height", 260, 620, 10, function(v) return string.format("%d px", v) end)
        slider(L.TL_WINDOW, "window", 15, 90, 5, function(v) return string.format("%d s", v) end)
        slider(L.TL_ICONSIZE, "iconSize", 24, 48, 2, function(v) return string.format("%d px", v) end)
        slider(L.TL_PRIORITY, "priorityThreshold", 2, 10, 1, function(v) return string.format("%d s", v) end)

        local ticks = NS.Theme:CreateCheck(timelinePage, L.TL_SHOW_TICKS)
        ticks:SetChecked(timeline.showTicks ~= false)
        ticks:SetCallback(function(v) timeline.showTicks = v; restyleTimeline() end)
        lay:Add(ticks, 20)

        local names = NS.Theme:CreateCheck(timelinePage, L.TL_SHOW_NAME)
        names:SetChecked(timeline.showName ~= false)
        names:SetCallback(function(v) timeline.showName = v; restyleTimeline() end)
        lay:Add(names, 20)

        local times = NS.Theme:CreateCheck(timelinePage, L.TL_SHOW_TIME)
        times:SetChecked(timeline.showTime ~= false)
        times:SetCallback(function(v) timeline.showTime = v; restyleTimeline() end)
        lay:Add(times, 20)
    end

    local function refresh(requestedMode)
        local mode = requestedMode or display.timerMode or "bars"
        local resolved = mode
        if NS.UI and NS.UI.DisplayController then
            resolved = NS.UI.DisplayController:GetResolvedMode()
            -- GetResolvedMode lit le profil ; si le GUI vient de changer le mode,
            -- SetMode l'a déjà sauvegardé. À l'ouverture, il resynchronise le choix.
            mode = display.timerMode or resolved
        end

        modeDD:SetValue(resolved, modeLabel(resolved))
        local heading, body = modeCopy(mode)
        infoTitle:SetText(heading)
        infoBody:SetText(body)

        local hasTimeline = NS.UI and NS.UI.DisplayController
            and NS.UI.DisplayController:HasRenderer("timeline")
        unavailable:SetShown((mode == "timeline" or mode == "hybrid") and not hasTimeline)

        local hybrid = mode == "hybrid"
        focusLbl:SetShown(hybrid)
        focusDD:SetShown(hybrid)

        local focus
        if mode == "timeline" then
            focus = "timeline"
        elseif hybrid then
            focus = hybridFocus
        else
            focus = "bars"
        end
        barsPage:SetShown(focus == "bars")
        timelinePage:SetShown(focus == "timeline")
    end

    self._displayRefresh = refresh
    refresh(display.timerMode or "bars")
end

-- Quand /tmbmode ou un autre code a changé le mode pendant que la fenêtre était
-- fermée, resynchroniser le dropdown au prochain affichage.
local originalToggle = Config.Toggle
function Config:Toggle()
    local result = originalToggle(self)
    if self.frame and self.frame:IsShown() and self._displayRefresh then
        self._displayRefresh()
    end
    return result
end
