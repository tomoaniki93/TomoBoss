---@diagnostic disable: undefined-global
-- TomoBoss — Barres de minuteur empilées (le cœur visuel).

local NS = select(2, ...)
NS.UI = NS.UI or {}
local TB = {}
NS.UI.TimerBars = TB

local WHITE = "Interface\\Buttons\\WHITE8X8"
local C

TB.active = {}   -- key -> bar
TB.pool = {}
TB.order = {}    -- liste triée pour la disposition

local function conf() return NS.db.profile.bars end

--------------------------------------------------------------------------
-- Cadre d'ancrage + ticker.
--------------------------------------------------------------------------
function TB:EnsureAnchor()
    if self.anchor then return self.anchor end
    C = NS.Theme.colors
    local cfg = conf()
    local a = CreateFrame("Frame", "TomoBossTimerBars", UIParent)
    a:SetSize(cfg.width, cfg.height)
    self.anchor = a

    self.ticker = CreateFrame("Frame", nil, a)
    self.ticker._acc = 0
    self.ticker:SetScript("OnUpdate", function(_, elapsed)
        self.ticker._acc = self.ticker._acc + elapsed
        if self.ticker._acc < 0.03 then return end
        self.ticker._acc = 0
        self:Tick()
    end)
    return a
end

--------------------------------------------------------------------------
-- Création / recyclage d'une barre.
--------------------------------------------------------------------------
local function newBar(self)
    local cfg = conf()
    local b = CreateFrame("Frame", nil, self.anchor)
    b:SetSize(cfg.width, cfg.height)

    b.bg = b:CreateTexture(nil, "BACKGROUND")
    b.bg:SetTexture(WHITE); b.bg:SetAllPoints(b)
    b.bg:SetVertexColor(C.bg2[1], C.bg2[2], C.bg2[3], 0.92)

    -- bordure fine
    b.brd = {}
    for _, p in ipairs({ "TOP", "BOTTOM", "LEFT", "RIGHT" }) do
        local t = b:CreateTexture(nil, "BORDER")
        t:SetTexture(WHITE); t:SetVertexColor(C.line[1], C.line[2], C.line[3], 1)
        b.brd[p] = t
    end
    b.brd.TOP:SetPoint("TOPLEFT"); b.brd.TOP:SetPoint("TOPRIGHT"); b.brd.TOP:SetHeight(1)
    b.brd.BOTTOM:SetPoint("BOTTOMLEFT"); b.brd.BOTTOM:SetPoint("BOTTOMRIGHT"); b.brd.BOTTOM:SetHeight(1)
    b.brd.LEFT:SetPoint("TOPLEFT"); b.brd.LEFT:SetPoint("BOTTOMLEFT"); b.brd.LEFT:SetWidth(1)
    b.brd.RIGHT:SetPoint("TOPRIGHT"); b.brd.RIGHT:SetPoint("BOTTOMRIGHT"); b.brd.RIGHT:SetWidth(1)

    b.iconBox = CreateFrame("Frame", nil, b)
    b.icon = b.iconBox:CreateTexture(nil, "ARTWORK")
    b.icon:SetAllPoints(b.iconBox)
    b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) -- rogne la bordure d'icône

    b.fill = b:CreateTexture(nil, "ARTWORK")
    b.fill:SetTexture(WHITE)

    b.spark = b:CreateTexture(nil, "OVERLAY")
    b.spark:SetTexture(WHITE)
    b.spark:SetVertexColor(1, 1, 1, 0.85)
    b.spark:SetWidth(2)

    b.name = b:CreateFontString(nil, "OVERLAY")
    b.name:SetJustifyH("LEFT")
    b.name:SetWordWrap(false)

    b.time = b:CreateFontString(nil, "OVERLAY")
    b.time:SetJustifyH("RIGHT")

    return b
end

local function styleBar(b)
    local cfg = conf()
    local h = cfg.height
    b:SetSize(cfg.width, h)

    if cfg.showIcon then
        b.iconBox:ClearAllPoints()
        b.iconBox:SetPoint("TOPLEFT", 0, 0)
        b.iconBox:SetSize(h, h)
        b.iconBox:Show()
        b.fill:ClearAllPoints()
        b.fill:SetPoint("TOPLEFT", b.iconBox, "TOPRIGHT", 1, -1)
        b.fill:SetPoint("BOTTOMLEFT", b.iconBox, "BOTTOMRIGHT", 1, 1)
        b.name:ClearAllPoints()
        b.name:SetPoint("LEFT", b.iconBox, "RIGHT", 6, 0)
    else
        b.iconBox:Hide()
        b.fill:ClearAllPoints()
        b.fill:SetPoint("TOPLEFT", 1, -1)
        b.fill:SetPoint("BOTTOMLEFT", 1, 1)
        b.name:ClearAllPoints()
        b.name:SetPoint("LEFT", 6, 0)
    end

    b.name:SetPoint("RIGHT", b.time, "LEFT", -4, 0)
    b.time:ClearAllPoints()
    b.time:SetPoint("RIGHT", -6, 0)

    NS.Theme:Font(b.name, cfg.fontSize, "text")
    NS.Theme:Font(b.time, cfg.fontSize, "text")

    b.spark:SetHeight(h - 2)
end

--------------------------------------------------------------------------
-- API publique.
--------------------------------------------------------------------------
function TB:AddOrUpdate(key, data)
    self:EnsureAnchor()
    local b = self.active[key]
    if not b then
        b = table.remove(self.pool) or newBar(self)
        self.active[key] = b
        b:Show()
    end
    styleBar(b)

    b.key = key
    b.title = data.name or "?"
    b.duration = math.max(0.1, data.duration or 1)
    b.endTime = data.endTime or (GetTime() + b.duration)
    b.severity = data.severity or 1

    local col = NS.Theme:Severity(b.severity)
    b.fill:SetVertexColor(col[1], col[2], col[3], 0.55)
    b.name:SetText(b.title)

    if conf().showIcon then
        b.icon:SetTexture(data.icon or 134400) -- point d'interrogation par défaut
    end
    self:Layout()
    return b
end

function TB:Remove(key)
    local b = self.active[key]
    if not b then return end
    self.active[key] = nil
    b:Hide()
    table.insert(self.pool, b)
    self:Layout()
end

function TB:Clear()
    for key in pairs(self.active) do self:Remove(key) end
end

function TB:Layout()
    if not self.anchor then return end
    local cfg = conf()
    wipe(self.order)
    for _, b in pairs(self.active) do self.order[#self.order + 1] = b end
    table.sort(self.order, function(x, y) return (x.endTime or 0) < (y.endTime or 0) end)

    local grow = cfg.grow == "up" and 1 or -1
    local shown = 0
    for i, b in ipairs(self.order) do
        if i <= cfg.maxBars then
            shown = shown + 1
            b:ClearAllPoints()
            local off = (shown - 1) * (cfg.height + cfg.spacing) * grow
            if grow == -1 then
                b:SetPoint("TOP", self.anchor, "TOP", 0, off)
            else
                b:SetPoint("BOTTOM", self.anchor, "BOTTOM", 0, -off)
            end
            b:Show()
        else
            b:Hide()
        end
    end
end

function TB:Tick()
    if not self.anchor then return end
    local now = GetTime()
    local cfg = conf()
    local removed = false
    for key, b in pairs(self.active) do
        local remaining = (b.endTime or now) - now
        if remaining <= -0.05 then
            self.active[key] = nil
            b:Hide()
            table.insert(self.pool, b)
            removed = true
        else
            local r = remaining < 0 and 0 or remaining
            local pct = NS.clamp(r / b.duration, 0, 1)
            local avail = cfg.showIcon and (cfg.width - cfg.height) or cfg.width
            avail = avail - 2
            local w = math.max(1, avail * pct)
            b.fill:SetWidth(w)
            b.spark:ClearAllPoints()
            b.spark:SetPoint("LEFT", b.fill, "LEFT", w - 1, 0)
            b.time:SetText(NS.fmtTime(r))
            -- passe le texte du temps en danger sous 5 s
            if r <= 5 then
                b.time:SetTextColor(NS.Theme:Color("danger"))
            else
                b.time:SetTextColor(NS.Theme:Color("text"))
            end
        end
    end
    if removed then self:Layout() end
end

--------------------------------------------------------------------------
-- Rafraîchit le style après changement d'options.
--------------------------------------------------------------------------
function TB:Restyle()
    if not self.anchor then return end
    local cfg = conf()
    self.anchor:SetSize(cfg.width, cfg.height)
    for _, b in pairs(self.active) do styleBar(b) end
    self:Layout()
end

--------------------------------------------------------------------------
-- Aperçu (mode édition / test des options).
--------------------------------------------------------------------------
function TB:ShowDemo(on)
    if on then
        local now = GetTime()
        self:AddOrUpdate("__demo1", { name = "Frappe de mine",      duration = 40, endTime = now + 12, severity = 0, icon = 135834 })
        self:AddOrUpdate("__demo2", { name = "Piétinement glacial",  duration = 40, endTime = now + 24, severity = 1, icon = 135843 })
        self:AddOrUpdate("__demo3", { name = "Surcharge glaciaire",  duration = 40, endTime = now + 36, severity = 2, icon = 135838 })
    else
        self:Remove("__demo1"); self:Remove("__demo2"); self:Remove("__demo3")
    end
end
