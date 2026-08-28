---@diagnostic disable: undefined-global
-- TomoBoss — TomoTimeline V1.
--
-- Second renderer natif des minuteurs de boss. Il consomme directement les
-- entrées canoniques de TimerModel via DisplayController : aucun calcul de boss,
-- aucune voix et aucune source de timeline ne sont dupliqués ici.
--
-- V1 : timeline verticale, futur en haut -> NOW en bas, cartes alternées gauche /
-- droite, graduations et accent d'urgence. L'orientation horizontale viendra dans
-- un lot ultérieur sans modifier le modèle commun.

local NS = select(2, ...)
NS.UI = NS.UI or {}

local WHITE = "Interface\\Buttons\\WHITE8X8"
local Timeline = {
    active = {},
    pool = {},
    order = {},
    tickPool = {},
    _edit = false,
}
NS.UI.TomoTimeline = Timeline

local function cfg()
    local profile = NS.db and NS.db.profile
    return profile and profile.timeline or nil
end

local function colorOf(entry)
    if entry and type(entry.color) == "table" then return entry.color end
    return NS.Theme:Severity(entry and entry.severity or 1)
end

local function countTable(t)
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    return n
end

local function stableSide(key)
    local s = tostring(key or "")
    local sum = 0
    for i = 1, #s do sum = sum + s:byte(i) end
    return (sum % 2 == 0) and "left" or "right"
end

local function setBorder(border, color, alpha)
    for _, tex in pairs(border) do
        tex:SetVertexColor(color[1], color[2], color[3], alpha or 1)
    end
end

local function makeBorder(frame, layer)
    local border = {}
    for _, p in ipairs({ "TOP", "BOTTOM", "LEFT", "RIGHT" }) do
        local t = frame:CreateTexture(nil, layer or "OVERLAY")
        t:SetTexture(WHITE)
        border[p] = t
    end
    border.TOP:SetPoint("TOPLEFT"); border.TOP:SetPoint("TOPRIGHT"); border.TOP:SetHeight(1)
    border.BOTTOM:SetPoint("BOTTOMLEFT"); border.BOTTOM:SetPoint("BOTTOMRIGHT"); border.BOTTOM:SetHeight(1)
    border.LEFT:SetPoint("TOPLEFT"); border.LEFT:SetPoint("BOTTOMLEFT"); border.LEFT:SetWidth(1)
    border.RIGHT:SetPoint("TOPRIGHT"); border.RIGHT:SetPoint("BOTTOMRIGHT"); border.RIGHT:SetWidth(1)
    return border
end

function Timeline:EnsureAnchor()
    if self.anchor then return self.anchor end

    local d = cfg() or {}
    local C = NS.Theme.colors
    local f = CreateFrame("Frame", "TomoBossTimelineAnchor", UIParent)
    f:SetSize(d.width or 340, d.height or 420)
    f:SetPoint("CENTER", UIParent, "CENTER", 280, 40)
    f:SetFrameStrata("MEDIUM")
    f:Hide()
    self.anchor = f

    -- Colonne centrale : une ombre douce puis un trait jade discret.
    local railShadow = f:CreateTexture(nil, "BACKGROUND")
    railShadow:SetTexture(WHITE)
    railShadow:SetWidth(5)
    railShadow:SetPoint("TOP", 0, -12)
    railShadow:SetPoint("BOTTOM", 0, 24)
    railShadow:SetVertexColor(C.shadow[1], C.shadow[2], C.shadow[3], 0.45)
    self.railShadow = railShadow

    local rail = f:CreateTexture(nil, "ARTWORK")
    rail:SetTexture(WHITE)
    rail:SetWidth(2)
    rail:SetPoint("TOP", 0, -12)
    rail:SetPoint("BOTTOM", 0, 24)
    rail:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 0.34)
    self.rail = rail

    local nowLine = f:CreateTexture(nil, "OVERLAY")
    nowLine:SetTexture(WHITE)
    nowLine:SetSize(30, 2)
    nowLine:SetPoint("BOTTOM", f, "BOTTOM", 0, 20)
    nowLine:SetVertexColor(C.accentHi[1], C.accentHi[2], C.accentHi[3], 0.95)
    self.nowLine = nowLine

    local nowText = f:CreateFontString(nil, "OVERLAY")
    NS.Theme:Font(nowText, 10, "accentHi", "OUTLINE")
    nowText:SetPoint("TOP", nowLine, "BOTTOM", 0, -2)
    nowText:SetText("NOW")
    self.nowText = nowText

    -- Le ticker est attaché à l'ancre : une frame cachée ne reçoit pas OnUpdate.
    -- Il ne tourne donc que lorsque TomoTimeline affiche réellement des timers ou
    -- un aperçu de déplacement.
    f._acc = 0
    f:SetScript("OnUpdate", function(_, elapsed)
        f._acc = f._acc + elapsed
        local rate = (cfg() and cfg().updateRate) or 0.05
        if f._acc < rate then return end
        f._acc = 0
        Timeline:Tick()
    end)

    self:Restyle()
    return f
end

local function newTick(parent)
    local C = NS.Theme.colors
    local t = CreateFrame("Frame", nil, parent)
    t:SetSize(48, 14)

    t.line = t:CreateTexture(nil, "ARTWORK")
    t.line:SetTexture(WHITE)
    t.line:SetSize(14, 1)
    t.line:SetPoint("CENTER", t, "CENTER", 0, 0)
    t.line:SetVertexColor(C.lineStrong[1], C.lineStrong[2], C.lineStrong[3], 0.55)

    t.text = t:CreateFontString(nil, "OVERLAY")
    NS.Theme:Font(t.text, 9, "muted", "OUTLINE")
    t.text:SetPoint("RIGHT", t.line, "LEFT", -4, 0)
    t.text:SetJustifyH("RIGHT")
    return t
end

function Timeline:RebuildTicks()
    if not self.anchor then return end
    local d = cfg() or {}
    local window = math.max(5, d.window or 40)
    local step = math.max(1, d.tickEvery or 5)
    local show = d.showTicks ~= false
    local usable = math.max(40, (d.height or 420) - 52)
    local bottom = 26
    local needed = show and math.floor(window / step) or 0

    for i = 1, needed do
        local t = self.tickPool[i]
        if not t then
            t = newTick(self.anchor)
            self.tickPool[i] = t
        end
        local seconds = i * step
        local y = bottom + (seconds / window) * usable
        t:ClearAllPoints()
        t:SetPoint("CENTER", self.anchor, "BOTTOM", 0, y)
        t.text:SetText(tostring(seconds))
        t:Show()
    end
    for i = needed + 1, #self.tickPool do self.tickPool[i]:Hide() end
end

local function newEvent(self)
    local d = cfg() or {}
    local C = NS.Theme.colors
    local iconSize = d.iconSize or 32
    local width = math.max(116, math.floor(((d.width or 340) / 2) - 24))

    local e = CreateFrame("Frame", nil, self.anchor)
    e:SetSize(width, iconSize + 4)

    e.shadow = e:CreateTexture(nil, "BACKGROUND")
    e.shadow:SetTexture(WHITE)
    e.shadow:SetPoint("TOPLEFT", 2, -2)
    e.shadow:SetPoint("BOTTOMRIGHT", 2, -2)
    e.shadow:SetVertexColor(C.shadow[1], C.shadow[2], C.shadow[3], 0.38)

    e.bg = e:CreateTexture(nil, "BACKGROUND")
    e.bg:SetTexture(WHITE)
    e.bg:SetAllPoints(e)
    e.bg:SetVertexColor(C.bg1[1], C.bg1[2], C.bg1[3], 0.94)

    e.brd = makeBorder(e, "BORDER")
    setBorder(e.brd, C.line, 0.88)

    e.accent = e:CreateTexture(nil, "OVERLAY")
    e.accent:SetTexture(WHITE)
    e.accent:SetWidth(2)

    e.topLine = e:CreateTexture(nil, "OVERLAY")
    e.topLine:SetTexture(WHITE)
    e.topLine:SetHeight(1)

    e.connector = e:CreateTexture(nil, "ARTWORK")
    e.connector:SetTexture(WHITE)
    e.connector:SetHeight(1)

    e.iconFrame = CreateFrame("Frame", nil, e)
    e.iconBg = e.iconFrame:CreateTexture(nil, "BACKGROUND")
    e.iconBg:SetTexture(WHITE); e.iconBg:SetAllPoints(e.iconFrame)
    e.iconBg:SetVertexColor(C.track[1], C.track[2], C.track[3], 1)
    e.icon = e.iconFrame:CreateTexture(nil, "ARTWORK")
    e.icon:SetPoint("TOPLEFT", 1, -1); e.icon:SetPoint("BOTTOMRIGHT", -1, 1)
    e.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    e.iconBrd = makeBorder(e.iconFrame, "OVERLAY")

    e.name = e:CreateFontString(nil, "OVERLAY")
    NS.Theme:Font(e.name, 11, "text")
    e.name:SetWordWrap(false)

    e.time = e:CreateFontString(nil, "OVERLAY")
    NS.Theme:Font(e.time, 11, "textSoft", "OUTLINE")

    e.urgent = e:CreateTexture(nil, "ARTWORK")
    e.urgent:SetTexture(WHITE)
    e.urgent:SetAllPoints(e)
    e.urgent:SetVertexColor(C.danger[1], C.danger[2], C.danger[3], 0.08)
    e.urgent:Hide()

    return e
end

function Timeline:StyleEvent(e, side, color, urgent)
    local d = cfg() or {}
    local C = NS.Theme.colors
    local iconSize = d.iconSize or 32
    local width = math.max(116, math.floor(((d.width or 340) / 2) - 24))
    local h = iconSize + 4

    e:SetSize(width, h)
    e.iconFrame:SetSize(iconSize, iconSize)
    e.iconFrame:ClearAllPoints()
    e.name:ClearAllPoints()
    e.time:ClearAllPoints()
    e.accent:ClearAllPoints()
    e.topLine:ClearAllPoints()
    e.connector:ClearAllPoints()

    if side == "left" then
        e.iconFrame:SetPoint("RIGHT", e, "RIGHT", -2, 0)
        e.name:SetPoint("LEFT", e, "LEFT", 7, 6)
        e.name:SetPoint("RIGHT", e.iconFrame, "LEFT", -6, 6)
        e.name:SetJustifyH("RIGHT")
        e.time:SetPoint("RIGHT", e.iconFrame, "LEFT", -6, -7)
        e.time:SetJustifyH("RIGHT")
        e.accent:SetPoint("TOPRIGHT", e, "TOPRIGHT", -1, -2)
        e.accent:SetPoint("BOTTOMRIGHT", e, "BOTTOMRIGHT", -1, 2)
        e.topLine:SetPoint("TOPLEFT", e, "TOPLEFT", 1, -1)
        e.topLine:SetPoint("TOPRIGHT", e, "TOPRIGHT", -2, -1)
        e.connector:SetPoint("LEFT", e, "RIGHT", 0, 0)
        e.connector:SetWidth(14)
    else
        e.iconFrame:SetPoint("LEFT", e, "LEFT", 2, 0)
        e.name:SetPoint("LEFT", e.iconFrame, "RIGHT", 6, 6)
        e.name:SetPoint("RIGHT", e, "RIGHT", -7, 6)
        e.name:SetJustifyH("LEFT")
        e.time:SetPoint("LEFT", e.iconFrame, "RIGHT", 6, -7)
        e.time:SetJustifyH("LEFT")
        e.accent:SetPoint("TOPLEFT", e, "TOPLEFT", 1, -2)
        e.accent:SetPoint("BOTTOMLEFT", e, "BOTTOMLEFT", 1, 2)
        e.topLine:SetPoint("TOPLEFT", e, "TOPLEFT", 2, -1)
        e.topLine:SetPoint("TOPRIGHT", e, "TOPRIGHT", -1, -1)
        e.connector:SetPoint("RIGHT", e, "LEFT", 0, 0)
        e.connector:SetWidth(14)
    end

    local c = urgent and C.danger or color
    e.accent:SetVertexColor(c[1], c[2], c[3], urgent and 1 or 0.92)
    e.topLine:SetVertexColor(c[1], c[2], c[3], urgent and 0.55 or 0.20)
    e.connector:SetVertexColor(c[1], c[2], c[3], urgent and 0.82 or 0.42)
    setBorder(e.iconBrd, c, urgent and 1 or 0.78)
    setBorder(e.brd, urgent and C.dangerSoft or C.line, urgent and 0.95 or 0.82)
    e.urgent:SetShown(urgent)
end

function Timeline:AddOrUpdate(key, entry)
    if key == nil or type(entry) ~= "table" then return nil end
    self:EnsureAnchor()

    local e = self.active[key]
    if not e then
        e = table.remove(self.pool) or newEvent(self)
        self.active[key] = e
    end
    e.key = key
    e.entry = entry

    local tex = entry.icon or 134400
    if e.__icon ~= tex then e.icon:SetTexture(tex); e.__icon = tex end
    local name = entry.name or "?"
    if e.__name ~= name then e.name:SetText(name); e.__name = name end

    -- Garder l'ancre active même si tous les événements sont encore au-delà de la
    -- fenêtre ; le ticker les fera entrer naturellement dans la timeline.
    self.anchor:Show()
    self:Tick(true)
    return e
end

function Timeline:Remove(key)
    local e = self.active[key]
    if not e then return end
    self.active[key] = nil
    e.entry = nil
    e:Hide()
    table.insert(self.pool, e)

    if next(self.active) == nil and not self._edit then
        if self.anchor then self.anchor:Hide() end
    else
        self:Tick(true)
    end
end

function Timeline:Clear()
    for key in pairs(self.active) do self:Remove(key) end
    wipe(self.order)
    if self.anchor and not self._edit then self.anchor:Hide() end
end

function Timeline:Tick(force)
    if not self.anchor then return end
    local d = cfg() or {}
    local now = GetTime()
    local window = math.max(5, d.window or 40)
    local maxEvents = math.max(1, d.maxEvents or 10)
    local threshold = math.max(0, d.priorityThreshold or 5)
    local usable = math.max(40, (d.height or 420) - 52)
    local bottom = 26
    local minGap = math.max(18, (d.iconSize or 32) + 5)

    wipe(self.order)
    for _, e in pairs(self.active) do
        local entry = e.entry
        local remaining = entry and ((entry.endTime or now) - now) or -1
        if remaining >= -0.05 and remaining <= window then
            e._remaining = math.max(0, remaining)
            self.order[#self.order + 1] = e
        else
            e:Hide()
        end
    end

    table.sort(self.order, function(a, b)
        if a._remaining == b._remaining then return tostring(a.key) < tostring(b.key) end
        return a._remaining < b._remaining
    end)

    local lastY = { left = -1000, right = -1000 }
    local shown = 0
    for _, e in ipairs(self.order) do
        if shown >= maxEvents then
            e:Hide()
        else
            shown = shown + 1
            local entry = e.entry
            local rem = e._remaining
            local y = bottom + (rem / window) * usable
            local preferred = stableSide(e.key)
            local other = preferred == "left" and "right" or "left"
            local side = preferred

            if (y - lastY[preferred]) < minGap and (y - lastY[other]) >= minGap then
                side = other
            end
            if (y - lastY[side]) < minGap then
                y = math.min(bottom + usable, lastY[side] + minGap)
            end
            lastY[side] = y

            local urgent = rem <= threshold
            local color = colorOf(entry)
            if e.__side ~= side or e.__urgentState ~= urgent
                or e.__cr ~= color[1] or e.__cg ~= color[2] or e.__cb ~= color[3]
            then
                self:StyleEvent(e, side, color, urgent)
                e.__side, e.__urgentState = side, urgent
                e.__cr, e.__cg, e.__cb = color[1], color[2], color[3]
            end

            e:ClearAllPoints()
            if side == "left" then
                e:SetPoint("RIGHT", self.anchor, "BOTTOM", -14, y)
            else
                e:SetPoint("LEFT", self.anchor, "BOTTOM", 14, y)
            end

            e.name:SetShown(d.showName ~= false)
            e.time:SetShown(d.showTime ~= false)
            if d.showTime ~= false then
                local txt = NS.fmtTime(rem)
                if e.__time ~= txt then e.time:SetText(txt); e.__time = txt end
                local state = urgent and "danger" or "textSoft"
                if e.__timeState ~= state then
                    e.time:SetTextColor(NS.Theme:Color(state))
                    e.time.__tmbColor = nil
                    e.__timeState = state
                end
            end
            e:Show()
        end
    end

    if next(self.active) == nil and not self._edit then self.anchor:Hide() end
end

function Timeline:Restyle()
    if not self.anchor then return end
    local d = cfg() or {}
    local C = NS.Theme.colors
    self.anchor:SetSize(d.width or 340, d.height or 420)
    self.anchor:SetScale((NS.db and NS.db.profile and NS.db.profile.scale) or 1)

    self.rail:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 0.34)
    self.nowLine:SetVertexColor(C.accentHi[1], C.accentHi[2], C.accentHi[3], 0.95)
    self:RebuildTicks()

    -- Invalide seulement le style ; les frames restent poolées.
    for _, e in pairs(self.active) do
        e.__side = nil
        e.__urgentState = nil
        e.__cr, e.__cg, e.__cb = nil, nil, nil
    end
    self:Tick(true)
end

function Timeline:ShowDemo(on)
    self:EnsureAnchor()
    self._edit = on and true or false
    if on then
        local now = GetTime()
        self:AddOrUpdate("__tl_demo1", { name = "Brise-minerai",      icon = 135834, endTime = now + 13, duration = 40, severity = 0 })
        self:AddOrUpdate("__tl_demo2", { name = "Surcharge glaciaire", icon = 135838, endTime = now + 26, duration = 40, severity = 2 })
        self:AddOrUpdate("__tl_demo3", { name = "Cryo-piétinement",    icon = 135843, endTime = now + 36, duration = 40, severity = 1 })
        self.anchor:Show()
    else
        self:Remove("__tl_demo1")
        self:Remove("__tl_demo2")
        self:Remove("__tl_demo3")
        self._edit = false
        if next(self.active) == nil then self.anchor:Hide() end
    end
end

-- Alias attendu par Mover et cohérent avec les autres widgets.
Timeline.Demo = Timeline.ShowDemo

-- Enregistre le renderer immédiatement : il n'accède à la DB qu'au premier rendu.
if NS.UI.DisplayController then
    NS.UI.DisplayController:RegisterRenderer("timeline", Timeline)
end

-- Le GUI du Lot 3 exposera le choix. Pour le Lot 2C, cette commande autonome
-- permet de tester le renderer sans modifier la commande /tmb existante.
SLASH_TOMOBOSSMODE1 = "/tmbmode"
SlashCmdList["TOMOBOSSMODE"] = function(msg)
    local mode = tostring(msg or ""):lower():match("^%s*(%S*)") or ""
    if mode == "bar" then mode = "bars" end
    if mode == "tl" then mode = "timeline" end
    if mode == "mix" then mode = "hybrid" end

    if mode ~= "bars" and mode ~= "timeline" and mode ~= "hybrid" then
        local current = NS.UI.DisplayController and NS.UI.DisplayController:GetResolvedMode() or "bars"
        NS:Print("Affichage actuel : |cff33e6a6" .. current .. "|r — /tmbmode bars|timeline|hybrid")
        return
    end

    local resolved = NS.UI.DisplayController:SetMode(mode)
    NS:Print("Affichage minuteurs : |cff33e6a6" .. tostring(resolved or mode) .. "|r")
end

-- Ancre déplaçable dédiée. Cette frame est chargée avant Init.lua mais PLAYER_LOGIN
-- arrive après InitDB(), donc la configuration et Mover sont disponibles ici.
local boot = CreateFrame("Frame")
boot:RegisterEvent("PLAYER_LOGIN")
boot:SetScript("OnEvent", function(self)
    self:UnregisterAllEvents()
    Timeline:EnsureAnchor()
    if NS.UI.Mover then
        NS.UI.Mover:Register("timeline", Timeline.anchor, "TomoTimeline",
            { point = "CENTER", x = 280, y = 40 }, function(on) Timeline:ShowDemo(on) end)
    end
end)
