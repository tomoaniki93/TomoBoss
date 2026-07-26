---@diagnostic disable: undefined-global
-- TomoBoss — Fabrique de groupes de barres (réutilisable : boss, trash, interruptions).

local NS = select(2, ...)
NS.UI = NS.UI or {}

local WHITE = "Interface\\Buttons\\WHITE8X8"

-- Crée un groupe de barres empilées.
--   name : identifiant (nom de cadre)
--   cfg  : table de config (référence DB) avec width,height,maxBars,spacing,grow,showIcon,fontSize
function NS.UI.CreateBarGroup(name, cfg)
    local C = NS.Theme.colors
    local g = { name = name, cfg = cfg, active = {}, pool = {}, order = {}, styleGen = 1 }

    function g:EnsureAnchor()
        if self.anchor then return self.anchor end
        local a = CreateFrame("Frame", "TomoBoss" .. self.name .. "Anchor", UIParent)
        a:SetSize(self.cfg.width, self.cfg.height)
        self.anchor = a
        self.ticker = CreateFrame("Frame", nil, a)
        self.ticker._acc = 0
        self.ticker:SetScript("OnUpdate", function(_, e)
            self.ticker._acc = self.ticker._acc + e
            if self.ticker._acc < 0.03 then return end
            self.ticker._acc = 0
            self:Tick()
        end)
        return a
    end

    local function newBar()
        local cfg = g.cfg
        local b = CreateFrame("Frame", nil, g.anchor)
        b:SetSize(cfg.width, cfg.height)

        b.bg = b:CreateTexture(nil, "BACKGROUND")
        b.bg:SetTexture(WHITE); b.bg:SetAllPoints(b)
        b.bg:SetVertexColor(C.bg2[1], C.bg2[2], C.bg2[3], 0.92)

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
        b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        b.fill = b:CreateTexture(nil, "ARTWORK")
        b.fill:SetTexture(WHITE)

        b.spark = b:CreateTexture(nil, "OVERLAY")
        b.spark:SetTexture(WHITE); b.spark:SetVertexColor(1, 1, 1, 0.85); b.spark:SetWidth(2)
        -- ancré une fois pour toutes sur le bord droit du remplissage : il suit
        -- automatiquement les SetWidth, plus aucun SetPoint par frame.
        b.spark:SetPoint("CENTER", b.fill, "RIGHT", 0, 0)

        b.name = b:CreateFontString(nil, "OVERLAY"); b.name:SetJustifyH("LEFT"); b.name:SetWordWrap(false)
        b.time = b:CreateFontString(nil, "OVERLAY"); b.time:SetJustifyH("RIGHT")
        return b
    end

    local function styleBar(b)
        local cfg = g.cfg
        local h = cfg.height
        b:SetSize(cfg.width, h)
        if cfg.showIcon then
            b.iconBox:ClearAllPoints(); b.iconBox:SetPoint("TOPLEFT", 0, 0); b.iconBox:SetSize(h, h); b.iconBox:Show()
            b.fill:ClearAllPoints()
            b.fill:SetPoint("TOPLEFT", b.iconBox, "TOPRIGHT", 1, -1)
            b.fill:SetPoint("BOTTOMLEFT", b.iconBox, "BOTTOMRIGHT", 1, 1)
            b.name:ClearAllPoints(); b.name:SetPoint("LEFT", b.iconBox, "RIGHT", 6, 0)
        else
            b.iconBox:Hide()
            b.fill:ClearAllPoints(); b.fill:SetPoint("TOPLEFT", 1, -1); b.fill:SetPoint("BOTTOMLEFT", 1, 1)
            b.name:ClearAllPoints(); b.name:SetPoint("LEFT", 6, 0)
        end
        b.name:SetPoint("RIGHT", b.time, "LEFT", -4, 0)
        b.time:ClearAllPoints(); b.time:SetPoint("RIGHT", -6, 0)
        NS.Theme:Font(b.name, cfg.fontSize, "text")
        NS.Theme:Font(b.time, cfg.fontSize, "text")
        b.spark:SetHeight(h - 2)
    end

    -- data : { name, icon, duration, endTime, color = {r,g,b}, severity, showTime }
    function g:AddOrUpdate(key, data)
        self:EnsureAnchor()
        local b = self.active[key]
        local isNew = false
        if not b then
            b = table.remove(self.pool) or newBar()
            self.active[key] = b
            b:Show()
            isNew = true
        end
        -- restyle uniquement si la config a changé depuis le dernier passage
        -- (styleGen est incrémenté par Restyle), pas à chaque mise à jour.
        if b.__styleGen ~= self.styleGen then
            styleBar(b)
            b.__styleGen = self.styleGen
        end
        b.key = key
        b.duration = math.max(0.1, data.duration or 1)
        local newEnd = data.endTime or (GetTime() + b.duration)
        local orderChanged = isNew or (b.endTime ~= newEnd)
        b.endTime = newEnd
        b.showTime = (data.showTime ~= false)
        b.ignoreWindow = data.ignoreWindow and true or false

        local col = data.color or NS.Theme:Severity(data.severity or 1)
        local alpha = data.fillAlpha or 0.55
        if b.__cr ~= col[1] or b.__cg ~= col[2] or b.__cb ~= col[3] or b.__ca ~= alpha then
            b.fill:SetVertexColor(col[1], col[2], col[3], alpha)
            b.__cr, b.__cg, b.__cb, b.__ca = col[1], col[2], col[3], alpha
        end
        local nm = data.name or "?"
        if b.__nameStr ~= nm then b.name:SetText(nm); b.__nameStr = nm end
        if self.cfg.showIcon then
            local tex = data.icon or 134400
            if b.__iconTex ~= tex then b.icon:SetTexture(tex); b.__iconTex = tex end
        end
        -- la disposition ne dépend que de endTime : inutile de trier si rien n'a bougé
        if orderChanged then self:Layout() end
        return b
    end

    function g:Remove(key)
        local b = self.active[key]
        if not b then return end
        self.active[key] = nil
        b:Hide()
        table.insert(self.pool, b)
        self:Layout()
    end

    function g:Clear()
        for key in pairs(self.active) do self:Remove(key) end
    end

    function g:Has(key) return self.active[key] ~= nil end

    function g:Layout()
        if not self.anchor then return end
        local cfg = self.cfg
        local window = cfg.showWindow or 0   -- 0 = tout afficher ; >0 = seulement si reste <= window
        local now = GetTime()
        wipe(self.order)
        for _, b in pairs(self.active) do self.order[#self.order + 1] = b end
        table.sort(self.order, function(x, y) return (x.endTime or 0) < (y.endTime or 0) end)
        local grow = cfg.grow == "up" and 1 or -1
        local shown = 0
        for _, b in ipairs(self.order) do
            local remaining = (b.endTime or now) - now
            local eligible = b.ignoreWindow or window <= 0 or remaining <= window
            if eligible and shown < cfg.maxBars then
                shown = shown + 1
                b:ClearAllPoints()
                local off = (shown - 1) * (cfg.height + cfg.spacing) * grow
                if grow == -1 then b:SetPoint("TOP", self.anchor, "TOP", 0, off)
                else b:SetPoint("BOTTOM", self.anchor, "BOTTOM", 0, -off) end
                b:Show()
            else
                b:Hide()
            end
        end
    end

    function g:Tick()
        if not self.anchor then return end
        if next(self.active) == nil then return end
        local now = GetTime()
        local cfg = self.cfg
        local removed = false
        local avail = (cfg.showIcon and (cfg.width - cfg.height) or cfg.width) - 2
        for key, b in pairs(self.active) do
            local remaining = (b.endTime or now) - now
            if remaining <= -0.05 then
                self.active[key] = nil; b:Hide(); table.insert(self.pool, b); removed = true
            else
                local r = remaining < 0 and 0 or remaining
                local pct = NS.clamp(r / b.duration, 0, 1)
                b.fill:SetWidth(math.max(1, avail * pct))  -- le spark suit (ancré sur le bord droit)
                if b.showTime then
                    -- fmtTime renvoie la même chaîne pendant ~1 s au-delà de 10 s :
                    -- on évite ~30 SetText identiques par seconde et par barre.
                    local txt = NS.fmtTime(r)
                    if b.__timeStr ~= txt then b.time:SetText(txt); b.__timeStr = txt end
                    local state = (r <= 5) and "danger" or "text"
                    if b.__timeState ~= state then
                        b.time:SetTextColor(NS.Theme:Color(state))
                        b.time.__tmbColor = nil   -- invalide le cache de Theme:Font
                        b.__timeState = state
                    end
                elseif b.__timeStr ~= "" then
                    b.time:SetText(""); b.__timeStr = ""
                end
            end
        end
        -- recalcule la disposition si une barre a disparu, ou en continu quand la
        -- fenêtre « barres < X s » est active (des barres entrent/sortent avec le temps)
        if removed or (cfg.showWindow and cfg.showWindow > 0) then self:Layout() end
    end

    function g:Restyle()
        if not self.anchor then return end
        self.anchor:SetSize(self.cfg.width, self.cfg.height)
        -- nouvelle génération : les barres du pool seront restylées à leur réemploi
        self.styleGen = self.styleGen + 1
        for _, b in pairs(self.active) do
            styleBar(b)
            b.__styleGen = self.styleGen
        end
        self:Layout()
    end

    function g:ShowDemo(on)
        if self.demoFn then self.demoFn(self, on) end
    end

    return g
end
