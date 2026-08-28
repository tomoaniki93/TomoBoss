---@diagnostic disable: undefined-global
-- TomoBoss — Fabrique de groupes de barres (réutilisable : boss, trash, interruptions).
-- Lot 2B : renderer Modern opt-in pour les boss bars, Legacy conservé pour les autres groupes.

local NS = select(2, ...)
NS.UI = NS.UI or {}

local WHITE = "Interface\\Buttons\\WHITE8X8"

local function isModern(cfg)
    return cfg and cfg.style == "modern"
end

local function setBorderColor(border, color, alpha)
    for _, t in pairs(border) do
        t:SetVertexColor(color[1], color[2], color[3], alpha or 1)
    end
end

local function applyBarColor(b, r, g, blue, alpha, modern)
    b.fill:SetVertexColor(r, g, blue, alpha)
    if modern then
        b.accent:SetVertexColor(r, g, blue, 0.95)
        b.topLine:SetVertexColor(r, g, blue, 0.20)
        for _, t in pairs(b.iconBrd) do
            t:SetVertexColor(r, g, blue, 0.78)
        end
    end
end

-- Crée un groupe de barres empilées.
--   name : identifiant (nom de cadre)
--   cfg  : table de config (référence DB) avec width,height,maxBars,spacing,grow,showIcon,fontSize
--          + style="modern" pour activer le renderer Boss Bars V2.
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

        -- Ombre discrète du renderer Modern. Elle reste cachée en Legacy.
        b.shadow = b:CreateTexture(nil, "BACKGROUND")
        b.shadow:SetTexture(WHITE)
        b.shadow:SetVertexColor(C.shadow[1], C.shadow[2], C.shadow[3], 0.38)
        b.shadow:Hide()

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

        -- Accent de sévérité et reflet supérieur, visibles uniquement en Modern.
        b.accent = b:CreateTexture(nil, "OVERLAY")
        b.accent:SetTexture(WHITE)
        b.accent:Hide()

        b.topLine = b:CreateTexture(nil, "OVERLAY")
        b.topLine:SetTexture(WHITE)
        b.topLine:Hide()

        b.iconBox = CreateFrame("Frame", nil, b)
        b.iconBg = b.iconBox:CreateTexture(nil, "BACKGROUND")
        b.iconBg:SetTexture(WHITE); b.iconBg:SetAllPoints(b.iconBox)
        b.iconBg:SetVertexColor(C.track[1], C.track[2], C.track[3], 1)
        b.iconBg:Hide()

        b.icon = b.iconBox:CreateTexture(nil, "ARTWORK")
        b.icon:SetAllPoints(b.iconBox)
        b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        b.iconBrd = {}
        for _, p in ipairs({ "TOP", "BOTTOM", "LEFT", "RIGHT" }) do
            local t = b.iconBox:CreateTexture(nil, "OVERLAY")
            t:SetTexture(WHITE)
            t:Hide()
            b.iconBrd[p] = t
        end
        b.iconBrd.TOP:SetPoint("TOPLEFT"); b.iconBrd.TOP:SetPoint("TOPRIGHT"); b.iconBrd.TOP:SetHeight(1)
        b.iconBrd.BOTTOM:SetPoint("BOTTOMLEFT"); b.iconBrd.BOTTOM:SetPoint("BOTTOMRIGHT"); b.iconBrd.BOTTOM:SetHeight(1)
        b.iconBrd.LEFT:SetPoint("TOPLEFT"); b.iconBrd.LEFT:SetPoint("BOTTOMLEFT"); b.iconBrd.LEFT:SetWidth(1)
        b.iconBrd.RIGHT:SetPoint("TOPRIGHT"); b.iconBrd.RIGHT:SetPoint("BOTTOMRIGHT"); b.iconBrd.RIGHT:SetWidth(1)

        -- Piste sombre dédiée : en Modern le remplissage n'est plus posé directement
        -- sur le fond de la frame, ce qui donne une lecture plus nette de la progression.
        b.track = b:CreateTexture(nil, "ARTWORK")
        b.track:SetTexture(WHITE)
        b.track:Hide()

        b.fill = b:CreateTexture(nil, "ARTWORK")
        b.fill:SetTexture(WHITE)

        -- Surbrillance statique d'urgence (< seuil configuré), sans animation ni ticker supplémentaire.
        b.urgent = b:CreateTexture(nil, "ARTWORK")
        b.urgent:SetTexture(WHITE)
        b.urgent:Hide()

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
        local modern = isModern(cfg)
        b:SetSize(cfg.width, h)

        if modern then
            local pad = math.max(2, math.min(3, math.floor(h * 0.12)))
            local iconSize = math.max(8, h - (pad * 2))
            local rightInset = 3
            local trackLeft

            b.shadow:ClearAllPoints()
            b.shadow:SetPoint("TOPLEFT", b, "TOPLEFT", 2, -2)
            b.shadow:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 2, -2)
            b.shadow:SetVertexColor(C.shadow[1], C.shadow[2], C.shadow[3], 0.38)
            b.shadow:Show()

            b.bg:SetVertexColor(C.bg1[1], C.bg1[2], C.bg1[3], 0.97)
            setBorderColor(b.brd, C.line, 0.86)

            b.accent:ClearAllPoints()
            b.accent:SetPoint("TOPLEFT", b, "TOPLEFT", 1, -2)
            b.accent:SetPoint("BOTTOMLEFT", b, "BOTTOMLEFT", 1, 2)
            b.accent:SetWidth(2)
            b.accent:Show()

            b.topLine:ClearAllPoints()
            b.topLine:SetPoint("TOPLEFT", b, "TOPLEFT", 3, -1)
            b.topLine:SetPoint("TOPRIGHT", b, "TOPRIGHT", -1, -1)
            b.topLine:SetHeight(1)
            b.topLine:Show()

            if cfg.showIcon then
                b.iconBox:ClearAllPoints()
                b.iconBox:SetPoint("TOPLEFT", b, "TOPLEFT", 4, -pad)
                b.iconBox:SetSize(iconSize, iconSize)
                b.iconBox:Show()
                b.iconBg:Show()
                for _, t in pairs(b.iconBrd) do t:Show() end
                b.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
                trackLeft = 4 + iconSize + 4
            else
                b.iconBox:Hide()
                b.iconBg:Hide()
                for _, t in pairs(b.iconBrd) do t:Hide() end
                trackLeft = 4
            end

            b.track:ClearAllPoints()
            b.track:SetPoint("TOPLEFT", b, "TOPLEFT", trackLeft, -3)
            b.track:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -rightInset, 3)
            b.track:SetVertexColor(C.track[1], C.track[2], C.track[3], cfg.trackAlpha or 0.92)
            b.track:Show()

            b.fill:ClearAllPoints()
            b.fill:SetPoint("TOPLEFT", b.track, "TOPLEFT", 0, 0)
            b.fill:SetPoint("BOTTOMLEFT", b.track, "BOTTOMLEFT", 0, 0)

            b.urgent:ClearAllPoints()
            b.urgent:SetAllPoints(b.track)
            b.urgent:SetVertexColor(C.danger[1], C.danger[2], C.danger[3], 0.09)
            b.urgent:SetShown(b.__urgent == true)

            b.name:ClearAllPoints()
            b.name:SetPoint("LEFT", b.track, "LEFT", 7, 0)
            b.name:SetPoint("RIGHT", b.time, "LEFT", -6, 0)

            b.time:ClearAllPoints()
            b.time:SetPoint("RIGHT", b, "RIGHT", -8, 0)

            NS.Theme:Font(b.name, cfg.fontSize, "text")
            NS.Theme:Font(b.time, cfg.fontSize, "textSoft")
            b.spark:SetWidth(1)
            b.spark:SetHeight(math.max(4, h - 6))
            b.spark:SetVertexColor(1, 1, 1, 0.72)

            b._fillWidth = math.max(1, cfg.width - trackLeft - rightInset)
        else
            -- Renderer historique inchangé pour interruptions/trash et preset Legacy.
            b.shadow:Hide()
            b.accent:Hide()
            b.topLine:Hide()
            b.track:Hide()
            b.urgent:Hide()
            b.iconBg:Hide()
            for _, t in pairs(b.iconBrd) do t:Hide() end

            b.bg:SetVertexColor(C.bg2[1], C.bg2[2], C.bg2[3], 0.92)
            setBorderColor(b.brd, C.line, 1)

            if cfg.showIcon then
                b.iconBox:ClearAllPoints(); b.iconBox:SetPoint("TOPLEFT", 0, 0); b.iconBox:SetSize(h, h); b.iconBox:Show()
                b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
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
            b.spark:SetWidth(2)
            b.spark:SetHeight(h - 2)
            b.spark:SetVertexColor(1, 1, 1, 0.85)
            b._fillWidth = (cfg.showIcon and (cfg.width - cfg.height) or cfg.width) - 2
        end

        -- Restyle peut être appelé sans nouvel AddOrUpdate : réapplique donc la
        -- couleur déjà mémorisée aux couches nouvellement affichées.
        if b.__cr then
            applyBarColor(b, b.__cr, b.__cg, b.__cb, b.__ca or 0.55, modern)
        end
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
        local modern = isModern(self.cfg)
        local alpha = data.fillAlpha
        if alpha == nil then alpha = modern and (self.cfg.fillAlpha or 0.72) or 0.55 end
        if b.__cr ~= col[1] or b.__cg ~= col[2] or b.__cb ~= col[3] or b.__ca ~= alpha then
            applyBarColor(b, col[1], col[2], col[3], alpha, modern)
            b.__cr, b.__cg, b.__cb, b.__ca = col[1], col[2], col[3], alpha
        end

        local nm = data.name or "?"
        if b.__nameStr ~= nm then b.name:SetText(nm); b.__nameStr = nm end

        -- Conserve toujours l'icône, même si elle est temporairement masquée :
        -- un changement showIcon + Restyle l'affiche ainsi immédiatement sans
        -- attendre qu'un producteur renvoie le timer.
        local tex = data.icon or b.__iconTex or 134400
        if b.__iconTex ~= tex then b.icon:SetTexture(tex); b.__iconTex = tex end
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
        local modern = isModern(cfg)
        local dangerThreshold = cfg.dangerThreshold or 5
        local removed = false

        for key, b in pairs(self.active) do
            local remaining = (b.endTime or now) - now
            if remaining <= -0.05 then
                self.active[key] = nil; b:Hide(); table.insert(self.pool, b); removed = true
            else
                local r = remaining < 0 and 0 or remaining
                local pct = NS.clamp(r / b.duration, 0, 1)
                b.fill:SetWidth(math.max(1, (b._fillWidth or 1) * pct))

                -- L'urgence est un changement d'état, pas une animation : aucune
                -- écriture de texture supplémentaire tant que le seuil ne change pas.
                local urgent = modern and r <= dangerThreshold
                if b.__urgent ~= urgent then
                    b.__urgent = urgent
                    b.urgent:SetShown(urgent)
                    if modern then
                        if urgent then
                            b.topLine:SetVertexColor(C.danger[1], C.danger[2], C.danger[3], 0.40)
                        elseif b.__cr then
                            b.topLine:SetVertexColor(b.__cr, b.__cg, b.__cb, 0.20)
                        end
                    end
                end

                if b.showTime then
                    -- fmtTime renvoie la même chaîne pendant ~1 s au-delà de 10 s :
                    -- on évite ~30 SetText identiques par seconde et par barre.
                    local txt = NS.fmtTime(r)
                    if b.__timeStr ~= txt then b.time:SetText(txt); b.__timeStr = txt end
                    local state = (r <= dangerThreshold) and "danger" or (modern and "textSoft" or "text")
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
