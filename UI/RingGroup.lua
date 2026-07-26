---@diagnostic disable: undefined-global
-- TomoBoss — Groupe d'anneaux (cooldown radial). Alternative visuelle aux barres.

local NS = select(2, ...)
NS.UI = NS.UI or {}

local WHITE = "Interface\\Buttons\\WHITE8X8"

-- cfg : size, spacing, maxRings, grow ("right"|"left"), showName, fontSize
function NS.UI.CreateRingGroup(name, cfg)
    local C = NS.Theme.colors
    local g = { name = name, cfg = cfg, active = {}, pool = {}, order = {} }

    function g:EnsureAnchor()
        if self.anchor then return self.anchor end
        local a = CreateFrame("Frame", "TomoBoss" .. self.name .. "Anchor", UIParent)
        a:SetSize(self.cfg.size, self.cfg.size + 16)
        self.anchor = a
        self.ticker = CreateFrame("Frame", nil, a)
        self.ticker._acc = 0
        self.ticker:SetScript("OnUpdate", function(_, e)
            self.ticker._acc = self.ticker._acc + e
            if self.ticker._acc < 0.05 then return end
            self.ticker._acc = 0
            self:Tick()
        end)
        return a
    end

    local function newRing()
        local size = g.cfg.size
        local f = CreateFrame("Frame", nil, g.anchor)
        f:SetSize(size, size + 16)

        f.iconFrame = CreateFrame("Frame", nil, f)
        f.iconFrame:SetSize(size, size)
        f.iconFrame:SetPoint("TOP")

        f.icon = f.iconFrame:CreateTexture(nil, "ARTWORK")
        f.icon:SetAllPoints(f.iconFrame)
        f.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        -- bordure teintée (identité couleur)
        f.brd = {}
        for _, p in ipairs({ "TOP", "BOTTOM", "LEFT", "RIGHT" }) do
            local t = f.iconFrame:CreateTexture(nil, "OVERLAY")
            t:SetTexture(WHITE)
            f.brd[p] = t
        end
        f.brd.TOP:SetPoint("TOPLEFT"); f.brd.TOP:SetPoint("TOPRIGHT"); f.brd.TOP:SetHeight(2)
        f.brd.BOTTOM:SetPoint("BOTTOMLEFT"); f.brd.BOTTOM:SetPoint("BOTTOMRIGHT"); f.brd.BOTTOM:SetHeight(2)
        f.brd.LEFT:SetPoint("TOPLEFT"); f.brd.LEFT:SetPoint("BOTTOMLEFT"); f.brd.LEFT:SetWidth(2)
        f.brd.RIGHT:SetPoint("TOPRIGHT"); f.brd.RIGHT:SetPoint("BOTTOMRIGHT"); f.brd.RIGHT:SetWidth(2)

        f.cd = CreateFrame("Cooldown", nil, f.iconFrame, "CooldownFrameTemplate")
        f.cd:SetAllPoints(f.iconFrame)
        f.cd:SetDrawEdge(true)
        f.cd:SetHideCountdownNumbers(true)
        f.cd:SetReverse(false)

        f.time = f.iconFrame:CreateFontString(nil, "OVERLAY")
        f.time:SetPoint("CENTER")
        NS.Theme:Font(f.time, math.max(11, math.floor(size / 3)), "text", "THICKOUTLINE")

        f.label = f:CreateFontString(nil, "OVERLAY")
        f.label:SetPoint("TOP", f.iconFrame, "BOTTOM", 0, -2)
        f.label:SetWidth(size + 20)
        NS.Theme:Font(f.label, g.cfg.fontSize or 11, "muted")
        f.label:SetWordWrap(false)

        return f
    end

    function g:AddOrUpdate(key, data)
        self:EnsureAnchor()
        local f = self.active[key]
        local isNew = false
        if not f then
            f = table.remove(self.pool) or newRing()
            self.active[key] = f
            f:Show()
            isNew = true
        end
        f.key = key
        f.duration = math.max(0.1, data.duration or 1)
        local newEnd = data.endTime or (GetTime() + f.duration)
        local changed = isNew or (f.endTime ~= newEnd) or (f.__cdDur ~= f.duration)
        f.endTime = newEnd

        local col = data.color or NS.Theme:Severity(data.severity or 1)
        if f.__cr ~= col[1] or f.__cg ~= col[2] or f.__cb ~= col[3] then
            for _, t in pairs(f.brd) do t:SetVertexColor(col[1], col[2], col[3], 1) end
            f.cd:SetSwipeColor(col[1], col[2], col[3], 0.55)
            f.__cr, f.__cg, f.__cb = col[1], col[2], col[3]
        end
        local tex = data.icon or 134400
        if f.__iconTex ~= tex then f.icon:SetTexture(tex); f.__iconTex = tex end
        f.label:SetShown(self.cfg.showName ~= false)
        if self.cfg.showName ~= false then
            local nm = data.name or ""
            if f.__nameStr ~= nm then f.label:SetText(nm); f.__nameStr = nm end
        end
        -- SetCooldown relance l'animation du balayage : ne l'appeler QUE si la
        -- fenêtre a réellement changé, sinon l'anneau saccade à chaque frame.
        if changed then
            f.cd:SetCooldown(f.endTime - f.duration, f.duration)
            f.__cdDur = f.duration
            self:Layout()
        end
        return f
    end

    function g:Remove(key)
        local f = self.active[key]
        if not f then return end
        self.active[key] = nil
        f:Hide()
        table.insert(self.pool, f)
        self:Layout()
    end

    function g:Clear()
        for key in pairs(self.active) do self:Remove(key) end
    end

    function g:Has(key) return self.active[key] ~= nil end

    function g:Layout()
        if not self.anchor then return end
        local cfg = self.cfg
        wipe(self.order)
        for _, f in pairs(self.active) do self.order[#self.order + 1] = f end
        table.sort(self.order, function(x, y) return (x.endTime or 0) < (y.endTime or 0) end)
        local dir = cfg.grow == "left" and -1 or 1
        local shown = 0
        for _, f in ipairs(self.order) do
            if shown < (cfg.maxRings or 6) then
                shown = shown + 1
                f:ClearAllPoints()
                local off = (shown - 1) * (cfg.size + (cfg.spacing or 8)) * dir
                if dir == 1 then f:SetPoint("TOPLEFT", self.anchor, "TOPLEFT", off, 0)
                else f:SetPoint("TOPRIGHT", self.anchor, "TOPRIGHT", off, 0) end
                f:Show()
            else
                f:Hide()
            end
        end
    end

    function g:Tick()
        if not self.anchor then return end
        if next(self.active) == nil then return end
        local now = GetTime()
        local removed = false
        for key, f in pairs(self.active) do
            local remaining = (f.endTime or now) - now
            if remaining <= -0.05 then
                self.active[key] = nil; f:Hide(); table.insert(self.pool, f); removed = true
            else
                local r = remaining < 0 and 0 or remaining
                local txt = NS.fmtTime(r)
                if f.__timeStr ~= txt then f.time:SetText(txt); f.__timeStr = txt end
                local state = (r <= 5) and "danger" or "text"
                if f.__timeState ~= state then
                    f.time:SetTextColor(NS.Theme:Color(state))
                    f.time.__tmbColor = nil
                    f.__timeState = state
                end
            end
        end
        if removed then self:Layout() end
    end

    function g:Restyle()
        if not self.anchor then return end
        self.anchor:SetSize(self.cfg.size, self.cfg.size + 16)
        self:Layout()
    end

    function g:ShowDemo(on)
        if self.demoFn then self.demoFn(self, on) end
    end

    return g
end
