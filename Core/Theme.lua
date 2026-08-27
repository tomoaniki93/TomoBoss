---@diagnostic disable: undefined-global
-- TomoBoss — Design system visuel.
-- Lot 1 : fondation UI « Obsidian + Jade » compatible avec les anciens widgets.

local NS = select(2, ...)
local Theme = {}
NS.Theme = Theme

local WHITE = "Interface\\Buttons\\WHITE8X8"  -- texture blanche 8x8 (fiable, teintable)
local FONT  = STANDARD_TEXT_FONT              -- supporte les accents français

-- Les anciennes clés (bg0/bg1/bg2/bg3/mint/mintLo/...) sont volontairement
-- conservées : tous les modules existants continuent donc à fonctionner.
local PALETTES = {
    obsidian = {
        bg0        = { 0.020, 0.025, 0.033 }, -- fenêtre / fond profond
        bg1        = { 0.033, 0.041, 0.052 }, -- panneau principal
        bg2        = { 0.052, 0.063, 0.078 }, -- surface élevée / contrôle
        bg3        = { 0.075, 0.089, 0.108 }, -- survol / surface active
        track      = { 0.027, 0.034, 0.044 }, -- pistes de progression
        line       = { 0.118, 0.139, 0.165 }, -- bordure discrète
        lineStrong = { 0.200, 0.235, 0.275 }, -- bordure active
        shadow     = { 0.000, 0.000, 0.000 },

        accent     = { 0.180, 0.835, 0.745 }, -- jade-cyan principal
        accentLo   = { 0.115, 0.610, 0.545 },
        accentHi   = { 0.420, 0.960, 0.875 },

        text       = { 0.925, 0.945, 0.965 },
        textSoft   = { 0.735, 0.780, 0.825 },
        muted      = { 0.500, 0.555, 0.615 },
        disabled   = { 0.330, 0.365, 0.405 },

        danger     = { 0.980, 0.325, 0.365 },
        dangerSoft = { 0.560, 0.155, 0.185 },
        warn       = { 1.000, 0.705, 0.285 },
        tank       = { 0.330, 0.650, 1.000 },
        heal       = { 0.340, 0.860, 0.550 },
        dps        = { 1.000, 0.585, 0.285 },
        mech       = { 0.690, 0.510, 1.000 },
        white      = { 1.000, 1.000, 1.000 },
        black      = { 0.000, 0.000, 0.000 },
    },

    -- Repli conservateur pour permettre un futur preset « Legacy » dans le GUI.
    legacy = {
        bg0        = { 0.039, 0.047, 0.043 },
        bg1        = { 0.067, 0.078, 0.071 },
        bg2        = { 0.098, 0.114, 0.106 },
        bg3        = { 0.129, 0.149, 0.141 },
        track      = { 0.050, 0.058, 0.053 },
        line       = { 0.157, 0.180, 0.169 },
        lineStrong = { 0.250, 0.300, 0.275 },
        shadow     = { 0.000, 0.000, 0.000 },

        accent     = { 0.200, 0.902, 0.651 },
        accentLo   = { 0.157, 0.706, 0.510 },
        accentHi   = { 0.420, 0.980, 0.760 },

        text       = { 0.902, 0.929, 0.918 },
        textSoft   = { 0.720, 0.760, 0.740 },
        muted      = { 0.541, 0.588, 0.561 },
        disabled   = { 0.350, 0.390, 0.370 },

        danger     = { 1.000, 0.420, 0.420 },
        dangerSoft = { 0.560, 0.210, 0.210 },
        warn       = { 1.000, 0.780, 0.350 },
        tank       = { 0.400, 0.720, 1.000 },
        heal       = { 0.400, 0.850, 0.520 },
        dps        = { 1.000, 0.620, 0.320 },
        mech       = { 0.720, 0.520, 1.000 },
        white      = { 1.000, 1.000, 1.000 },
        black      = { 0.000, 0.000, 0.000 },
    },
}

local C = {}
Theme.colors = C
Theme.palettes = PALETTES
Theme.paletteName = "obsidian"

local function copyColor(dst, src)
    dst[1], dst[2], dst[3] = src[1], src[2], src[3]
end

local function rebuildAliases()
    -- Alias historiques : garder exactement les noms déjà consommés par le code.
    C.mint = C.mint or { 0, 0, 0 }
    C.mintLo = C.mintLo or { 0, 0, 0 }
    copyColor(C.mint, C.accent)
    copyColor(C.mintLo, C.accentLo)
end

function Theme:SetPalette(name)
    local palette = PALETTES[name] or PALETTES.obsidian
    name = PALETTES[name] and name or "obsidian"

    for key, value in pairs(palette) do
        if not C[key] then C[key] = { 0, 0, 0 } end
        copyColor(C[key], value)
    end

    rebuildAliases()
    self.paletteName = name
    return name
end

function Theme:GetPaletteName()
    return self.paletteName
end

function Theme:SurfaceAlpha()
    local profile = NS.db and NS.db.profile
    local appearance = profile and profile.appearance
    local alpha = appearance and appearance.panelAlpha
    if type(alpha) ~= "number" then return 0.97 end
    if alpha < 0.60 then return 0.60 end
    if alpha > 1.00 then return 1.00 end
    return alpha
end

Theme:SetPalette("obsidian")

function Theme:Color(key)
    local c = C[key] or C.text
    return c[1], c[2], c[3]
end

function Theme:ColorTable(key)
    return C[key] or C.text
end

function Theme:Severity(sev)
    sev = NS:SafeNumber(sev) -- nil si valeur masquée (secret) -> couleur par défaut
    if sev == 2 then return C.danger end
    if sev == 0 then return C.tank end
    return C.accent
end

function Theme:Role(role)
    return C[role] or C.accent
end

--------------------------------------------------------------------------
-- Primitives de dessin.
--------------------------------------------------------------------------
local function setRect(tex, frame, inset)
    inset = inset or 0
    tex:ClearAllPoints()
    tex:SetPoint("TOPLEFT", frame, "TOPLEFT", inset, -inset)
    tex:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -inset, inset)
end

local function ensureBorder(frame)
    if frame.__brd then return frame.__brd end
    frame.__brd = {}
    for _, p in ipairs({ "TOP", "BOTTOM", "LEFT", "RIGHT" }) do
        local t = frame:CreateTexture(nil, "BORDER")
        t:SetTexture(WHITE)
        frame.__brd[p] = t
    end
    return frame.__brd
end

local function colorBorder(border, color, alpha)
    for _, tx in pairs(border) do
        tx:SetVertexColor(color[1], color[2], color[3], alpha or 1)
    end
end

-- Habillage commun : surface + bordure + ombre interne + highlight supérieur.
-- Les options historiques continuent à fonctionner.
function Theme:Skin(frame, opts)
    opts = opts or {}
    local bg = opts.bg or C.bg1
    local br = opts.border or C.line
    local a = opts.alpha
    if a == nil then a = self:SurfaceAlpha() end

    if not frame.__bg then
        frame.__bg = frame:CreateTexture(nil, "BACKGROUND")
        frame.__bg:SetTexture(WHITE)
    end
    setRect(frame.__bg, frame, 0)
    frame.__bg:SetVertexColor(bg[1], bg[2], bg[3], a)

    if opts.shadow ~= false then
        if not frame.__shadow then
            frame.__shadow = frame:CreateTexture(nil, "BACKGROUND", nil, -1)
            frame.__shadow:SetTexture(WHITE)
        end
        setRect(frame.__shadow, frame, 1)
        frame.__shadow:SetVertexColor(C.shadow[1], C.shadow[2], C.shadow[3], opts.shadowAlpha or 0.22)
        frame.__shadow:Show()
    elseif frame.__shadow then
        frame.__shadow:Hide()
    end

    if opts.highlight then
        if not frame.__topHighlight then
            frame.__topHighlight = frame:CreateTexture(nil, "ARTWORK")
            frame.__topHighlight:SetTexture(WHITE)
            frame.__topHighlight:SetPoint("TOPLEFT", 1, -1)
            frame.__topHighlight:SetPoint("TOPRIGHT", -1, -1)
            frame.__topHighlight:SetHeight(1)
        end
        local hc = opts.highlightColor or C.lineStrong
        frame.__topHighlight:SetVertexColor(hc[1], hc[2], hc[3], opts.highlightAlpha or 0.28)
        frame.__topHighlight:Show()
    elseif frame.__topHighlight then
        frame.__topHighlight:Hide()
    end

    if opts.border ~= false then
        local border = ensureBorder(frame)
        local s = opts.borderSize or 1
        border.TOP:ClearAllPoints();    border.TOP:SetPoint("TOPLEFT");    border.TOP:SetPoint("TOPRIGHT");    border.TOP:SetHeight(s)
        border.BOTTOM:ClearAllPoints(); border.BOTTOM:SetPoint("BOTTOMLEFT"); border.BOTTOM:SetPoint("BOTTOMRIGHT"); border.BOTTOM:SetHeight(s)
        border.LEFT:ClearAllPoints();   border.LEFT:SetPoint("TOPLEFT");   border.LEFT:SetPoint("BOTTOMLEFT");   border.LEFT:SetWidth(s)
        border.RIGHT:ClearAllPoints();  border.RIGHT:SetPoint("TOPRIGHT"); border.RIGHT:SetPoint("BOTTOMRIGHT"); border.RIGHT:SetWidth(s)
        colorBorder(border, br, opts.borderAlpha or 1)
        for _, tx in pairs(border) do tx:Show() end
    elseif frame.__brd then
        for _, tx in pairs(frame.__brd) do tx:Hide() end
    end
    return frame
end

function Theme:SetBorderColor(frame, colorKey, alpha)
    if not frame or not frame.__brd then return end
    colorBorder(frame.__brd, C[colorKey] or C.line, alpha or 1)
end

-- Applique police + couleur, en évitant les appels redondants.
-- SetFont/SetTextColor sont coûteux ; on mémorise le dernier état appliqué.
-- NB : si un module change la couleur directement (SetTextColor), il doit
-- invalider fs.__tmbColor pour que le prochain Font() la réapplique.
function Theme:Font(fs, size, colorKey, flags)
    size     = size or 13
    flags    = flags or ""
    colorKey = colorKey or "text"
    if fs.__tmbSize ~= size or fs.__tmbFlags ~= flags then
        fs:SetFont(FONT, size, flags)
        fs.__tmbSize, fs.__tmbFlags = size, flags
    end
    if fs.__tmbColor ~= colorKey then
        local c = C[colorKey] or C.text
        fs:SetTextColor(c[1], c[2], c[3])
        fs.__tmbColor = colorKey
    end
    return fs
end

-- Renvoie la police et la texture pour les autres modules.
function Theme.FONT() return FONT end
function Theme.BAR_TEXTURE() return WHITE end

--------------------------------------------------------------------------
-- Panneaux / cartes.
--------------------------------------------------------------------------
function Theme:CreatePanel(parent, opts)
    local f = CreateFrame("Frame", nil, parent)
    self:Skin(f, opts)
    return f
end

function Theme:CreateCard(parent, opts)
    opts = opts or {}
    if opts.bg == nil then opts.bg = C.bg1 end
    if opts.border == nil then opts.border = C.line end
    if opts.highlight == nil then opts.highlight = true end
    return self:CreatePanel(parent, opts)
end

function Theme:CreateDivider(parent, width)
    local t = parent:CreateTexture(nil, "ARTWORK")
    t:SetTexture(WHITE)
    t:SetHeight(1)
    if width then t:SetWidth(width) end
    t:SetVertexColor(C.line[1], C.line[2], C.line[3], 0.85)
    return t
end

--------------------------------------------------------------------------
-- Bouton : surface élevée, accent jade-cyan au survol.
--------------------------------------------------------------------------
function Theme:CreateButton(parent, text, w, h)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(w or 120, h or 26)
    self:Skin(b, { bg = C.bg2, border = C.line, highlight = true, shadowAlpha = 0.16 })

    b.text = b:CreateFontString(nil, "OVERLAY")
    b.text:SetPoint("CENTER", 0, 1)
    self:Font(b.text, 13, "text")
    b.text:SetText(text or "")

    b._enabled = true

    local function applyNormal(self)
        if not self._enabled then
            self.__bg:SetVertexColor(C.bg1[1], C.bg1[2], C.bg1[3], 0.85)
            self.text:SetTextColor(C.disabled[1], C.disabled[2], C.disabled[3])
            if self.__brd then colorBorder(self.__brd, C.line, 0.55) end
            return
        end
        self.__bg:SetVertexColor(C.bg2[1], C.bg2[2], C.bg2[3], Theme:SurfaceAlpha())
        self.text:SetTextColor(C.text[1], C.text[2], C.text[3])
        if self.__brd then colorBorder(self.__brd, C.line, 1) end
    end

    b:SetScript("OnEnter", function(self)
        if not self._enabled then return end
        self.__bg:SetVertexColor(C.bg3[1], C.bg3[2], C.bg3[3], 1)
        if self.__brd then colorBorder(self.__brd, C.accent, 0.95) end
        self.text:SetTextColor(C.accentHi[1], C.accentHi[2], C.accentHi[3])
    end)
    b:SetScript("OnLeave", applyNormal)
    b:SetScript("OnMouseDown", function(self)
        if self._enabled then self.text:SetPoint("CENTER", 0, 0) end
    end)
    b:SetScript("OnMouseUp", function(self)
        self.text:SetPoint("CENTER", 0, 1)
    end)

    function b:SetText(t) self.text:SetText(t) end
    function b:SetEnabledState(enabled)
        self._enabled = enabled and true or false
        self:EnableMouse(self._enabled)
        applyNormal(self)
    end

    return b
end

--------------------------------------------------------------------------
-- Case à cocher.
--------------------------------------------------------------------------
function Theme:CreateCheck(parent, text)
    local f = CreateFrame("Button", nil, parent)
    f:SetSize(22, 22)

    local box = self:CreatePanel(f, { bg = C.track, border = C.line, shadowAlpha = 0.12 })
    box:SetSize(18, 18)
    box:SetPoint("LEFT")
    f.box = box

    local tickBg = box:CreateTexture(nil, "ARTWORK")
    tickBg:SetTexture(WHITE)
    tickBg:SetPoint("CENTER")
    tickBg:SetSize(12, 12)
    tickBg:SetVertexColor(C.accentLo[1], C.accentLo[2], C.accentLo[3], 0.28)
    tickBg:Hide()
    f.tickBg = tickBg

    local tick = box:CreateTexture(nil, "OVERLAY")
    tick:SetTexture(WHITE)
    tick:SetPoint("CENTER")
    tick:SetSize(8, 8)
    tick:SetVertexColor(C.accentHi[1], C.accentHi[2], C.accentHi[3])
    tick:Hide()
    f.tick = tick

    f.label = f:CreateFontString(nil, "OVERLAY")
    f.label:SetPoint("LEFT", box, "RIGHT", 8, 0)
    self:Font(f.label, 13, "text")
    f.label:SetText(text or "")
    f:SetWidth(28 + f.label:GetStringWidth())
    f.checked = false

    function f:SetChecked(v)
        self.checked = v and true or false
        tick:SetShown(self.checked)
        tickBg:SetShown(self.checked)
        if self.checked then
            Theme:SetBorderColor(box, "accentLo", 1)
        else
            Theme:SetBorderColor(box, "line", 1)
        end
    end
    function f:GetChecked() return self.checked end
    function f:SetCallback(fn) self._cb = fn end

    f:SetScript("OnClick", function(self)
        self:SetChecked(not self.checked)
        if self._cb then self._cb(self.checked) end
    end)
    f:SetScript("OnEnter", function(self)
        Theme:SetBorderColor(box, "accent", 1)
        self.label:SetTextColor(C.accentHi[1], C.accentHi[2], C.accentHi[3])
    end)
    f:SetScript("OnLeave", function(self)
        Theme:SetBorderColor(box, self.checked and "accentLo" or "line", 1)
        self.label:SetTextColor(C.text[1], C.text[2], C.text[3])
    end)
    return f
end

--------------------------------------------------------------------------
-- Curseur horizontal, valeur + libellé.
--------------------------------------------------------------------------
function Theme:CreateSlider(parent, opts)
    opts = opts or {}
    local width = opts.width or 220
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(width, 42)

    f.label = f:CreateFontString(nil, "OVERLAY")
    f.label:SetPoint("TOPLEFT")
    self:Font(f.label, 12, "textSoft")
    f.label:SetText(opts.label or "")

    f.valText = f:CreateFontString(nil, "OVERLAY")
    f.valText:SetPoint("TOPRIGHT")
    self:Font(f.valText, 12, "accentHi")

    local track = self:CreatePanel(f, { bg = C.track, border = C.line, shadow = false, alpha = 1 })
    track:SetHeight(8)
    track:SetPoint("BOTTOMLEFT", 0, 4)
    track:SetPoint("BOTTOMRIGHT", 0, 4)
    f.track = track

    local fill = track:CreateTexture(nil, "ARTWORK")
    fill:SetTexture(WHITE)
    fill:SetVertexColor(C.accentLo[1], C.accentLo[2], C.accentLo[3])
    fill:SetPoint("TOPLEFT", 1, -1)
    fill:SetPoint("BOTTOMLEFT", 1, 1)
    f.fill = fill

    local shine = track:CreateTexture(nil, "OVERLAY")
    shine:SetTexture(WHITE)
    shine:SetPoint("TOPLEFT", fill, "TOPLEFT", 0, 0)
    shine:SetPoint("TOPRIGHT", fill, "TOPRIGHT", 0, 0)
    shine:SetHeight(1)
    shine:SetVertexColor(C.accentHi[1], C.accentHi[2], C.accentHi[3], 0.55)
    f.shine = shine

    local slider = CreateFrame("Slider", nil, track)
    slider:SetAllPoints(track)
    slider:SetOrientation("HORIZONTAL")
    slider:SetMinMaxValues(opts.min or 0, opts.max or 1)
    slider:SetValueStep(opts.step or 0.01)
    slider:SetObeyStepOnDrag(true)
    slider:SetValue(opts.value or opts.min or 0)

    local thumb = slider:CreateTexture(nil, "OVERLAY")
    thumb:SetTexture(WHITE)
    thumb:SetSize(7, 18)
    thumb:SetVertexColor(C.accent[1], C.accent[2], C.accent[3])
    slider:SetThumbTexture(thumb)
    f.slider = slider
    f._fmt = opts.fmt or function(v) return tostring(NS.round(v, 2)) end

    local function refresh(v)
        local lo, hi = slider:GetMinMaxValues()
        local pct = (hi > lo) and ((v - lo) / (hi - lo)) or 0
        fill:SetWidth(math.max(1, (track:GetWidth() - 2) * pct))
        f.valText:SetText(f._fmt(v))
    end

    slider:SetScript("OnValueChanged", function(self, v, byUser)
        v = NS.round(v, 4)
        refresh(v)
        if f._cb and byUser then f._cb(v) end
    end)
    slider:SetScript("OnShow", function(self) refresh(self:GetValue()) end)
    slider:SetScript("OnEnter", function() Theme:SetBorderColor(track, "lineStrong", 1) end)
    slider:SetScript("OnLeave", function() Theme:SetBorderColor(track, "line", 1) end)

    function f:SetValue(v) slider:SetValue(v); refresh(v) end
    function f:GetValue() return slider:GetValue() end
    function f:SetCallback(fn) self._cb = fn end
    refresh(slider:GetValue())
    return f
end

--------------------------------------------------------------------------
-- Menu déroulant léger (personnalisé, thème sombre).
--------------------------------------------------------------------------
local openDropdown
local closer = CreateFrame("Frame")
closer:Hide()
closer:SetScript("OnUpdate", function()
    if openDropdown and openDropdown.list and openDropdown.list:IsShown() then
        if not (openDropdown:IsMouseOver() or openDropdown.list:IsMouseOver()) and IsMouseButtonDown() then
            openDropdown.list:Hide()
            openDropdown = nil
            closer:Hide()
        end
    else
        closer:Hide()
    end
end)

function Theme:CreateDropdown(parent, opts)
    opts = opts or {}
    local f = CreateFrame("Button", nil, parent)
    f:SetSize(opts.width or 200, 27)
    self:Skin(f, { bg = C.bg2, border = C.line, highlight = true, shadowAlpha = 0.12 })

    f.text = f:CreateFontString(nil, "OVERLAY")
    f.text:SetPoint("LEFT", 9, 0)
    f.text:SetPoint("RIGHT", -24, 0)
    f.text:SetJustifyH("LEFT")
    self:Font(f.text, 12, "text")

    local chev = f:CreateFontString(nil, "OVERLAY")
    chev:SetPoint("RIGHT", -9, 1)
    self:Font(chev, 11, "accentHi")
    chev:SetText("v")

    local list = CreateFrame("Frame", nil, f)
    list:SetFrameStrata("FULLSCREEN_DIALOG")
    list:SetToplevel(true)
    list:SetClipsChildren(true)
    self:Skin(list, { bg = C.bg1, border = C.lineStrong, shadowAlpha = 0.35, alpha = 1 })
    list:Hide()
    f.list = list

    local content = CreateFrame("Frame", nil, list)
    content:SetPoint("TOPLEFT", 0, 0)
    content:SetPoint("TOPRIGHT", 0, 0)
    list.content = content
    list._offset = 0
    list:EnableMouseWheel(true)

    f.items = opts.items or {}
    f._value = nil

    local ROWH = 23
    local MAXH = 300
    list:SetScript("OnMouseWheel", function(self, delta)
        local maxOff = math.max(0, (self._contentH or 0) - self:GetHeight())
        self._offset = math.min(maxOff, math.max(0, self._offset - delta * ROWH * 3))
        content:ClearAllPoints()
        content:SetPoint("TOPLEFT", 0, self._offset)
        content:SetPoint("TOPRIGHT", 0, self._offset)
    end)

    local function rebuild()
        if list.buttons then for _, b in ipairs(list.buttons) do b:Hide() end end
        list.buttons = list.buttons or {}
        local n = #f.items
        local contentH = math.max(ROWH, n * ROWH) + 6
        list._contentH = contentH
        list._offset = 0
        content:ClearAllPoints()
        content:SetPoint("TOPLEFT", 0, 0)
        content:SetPoint("TOPRIGHT", 0, 0)
        content:SetHeight(contentH)
        list:SetSize(f:GetWidth(), math.min(contentH, MAXH))

        for i, item in ipairs(f.items) do
            local b = list.buttons[i]
            if not b then
                b = CreateFrame("Button", nil, content)
                b:SetHeight(ROWH)
                b.hl = b:CreateTexture(nil, "BACKGROUND")
                b.hl:SetTexture(WHITE)
                b.hl:SetAllPoints(b)
                b.hl:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 0.12)
                b.hl:Hide()
                b.t = b:CreateFontString(nil, "OVERLAY")
                b.t:SetPoint("LEFT", 9, 0)
                Theme:Font(b.t, 12, "text")
                b:SetScript("OnEnter", function(self)
                    self.hl:Show()
                    self.t:SetTextColor(C.accentHi[1], C.accentHi[2], C.accentHi[3])
                end)
                b:SetScript("OnLeave", function(self)
                    self.hl:Hide()
                    self.t:SetTextColor(C.text[1], C.text[2], C.text[3])
                end)
                list.buttons[i] = b
            end
            b:ClearAllPoints()
            b:SetPoint("TOPLEFT", content, "TOPLEFT", 3, -3 - (i - 1) * ROWH)
            b:SetPoint("RIGHT", content, "RIGHT", -3, 0)
            b.t:SetText(item.text)
            b:SetScript("OnClick", function()
                f:SetValue(item.value, item.text)
                list:Hide(); openDropdown = nil; closer:Hide()
                Theme:SetBorderColor(f, "line", 1)
                if opts.onSelect then opts.onSelect(item.value, item.text) end
            end)
            b:Show()
        end
    end

    f:SetScript("OnEnter", function(self) Theme:SetBorderColor(self, "lineStrong", 1) end)
    f:SetScript("OnLeave", function(self)
        if not self.list:IsShown() then Theme:SetBorderColor(self, "line", 1) end
    end)
    f:SetScript("OnClick", function(self)
        if list:IsShown() then
            list:Hide(); openDropdown = nil; closer:Hide()
            Theme:SetBorderColor(self, "line", 1)
        else
            rebuild()
            list:ClearAllPoints()
            list:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -3)
            list:Show()
            Theme:SetBorderColor(self, "accentLo", 1)
            openDropdown = self; closer:Show()
        end
    end)

    function f:SetItems(items) self.items = items end
    function f:SetValue(value, text)
        self._value = value
        if not text then
            for _, it in ipairs(self.items) do if it.value == value then text = it.text break end end
        end
        self.text:SetText(text or tostring(value or ""))
    end
    function f:GetValue() return self._value end
    return f
end

--------------------------------------------------------------------------
-- Titres / libellés.
--------------------------------------------------------------------------
function Theme:SectionTitle(parent, text)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    self:Font(fs, 15, "accentHi")
    fs:SetText(text)
    return fs
end

function Theme:CreateEyebrow(parent, text)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    self:Font(fs, 10, "muted")
    fs:SetText(text or "")
    return fs
end

--------------------------------------------------------------------------
-- Zone de saisie (une ligne).
--------------------------------------------------------------------------
function Theme:CreateEditBox(parent, width, height)
    local f = CreateFrame("EditBox", nil, parent)
    f:SetSize(width or 180, height or 24)
    f:SetAutoFocus(false)
    f:SetFont(FONT, 12, "")
    f:SetTextColor(C.text[1], C.text[2], C.text[3])
    f:SetTextInsets(7, 7, 0, 0)
    self:Skin(f, { bg = C.track, border = C.line, shadowAlpha = 0.10 })
    f:SetScript("OnEscapePressed", f.ClearFocus)
    f:SetScript("OnEnterPressed", f.ClearFocus)
    f:SetScript("OnEditFocusGained", function(self)
        Theme:SetBorderColor(self, "accentLo", 1)
    end)
    f:SetScript("OnEditFocusLost", function(self)
        Theme:SetBorderColor(self, "line", 1)
    end)
    return f
end

--------------------------------------------------------------------------
-- Zone de saisie multiligne (avec défilement) — pour import/export.
--------------------------------------------------------------------------
function Theme:CreateMultiLineEditBox(parent, width, height)
    local container = self:CreatePanel(parent, { bg = C.track, border = C.line, shadowAlpha = 0.12 })
    container:SetSize(width, height)
    local scroll = CreateFrame("ScrollFrame", nil, container)
    scroll:SetPoint("TOPLEFT", 7, -7)
    scroll:SetPoint("BOTTOMRIGHT", -7, 7)
    scroll:EnableMouseWheel(true)

    local edit = CreateFrame("EditBox", nil, scroll)
    edit:SetMultiLine(true)
    edit:SetAutoFocus(false)
    edit:SetFont(FONT, 11, "")
    edit:SetTextColor(C.text[1], C.text[2], C.text[3])
    edit:SetWidth(width - 18)
    edit:SetScript("OnEscapePressed", edit.ClearFocus)
    edit:SetScript("OnEditFocusGained", function() Theme:SetBorderColor(container, "accentLo", 1) end)
    edit:SetScript("OnEditFocusLost", function() Theme:SetBorderColor(container, "line", 1) end)
    scroll:SetScrollChild(edit)
    scroll:SetScript("OnMouseWheel", function(self, delta)
        local maxS = math.max(0, edit:GetHeight() - self:GetHeight())
        local cur = self:GetVerticalScroll()
        self:SetVerticalScroll(math.min(maxS, math.max(0, cur - delta * 24)))
    end)
    edit:SetScript("OnCursorChanged", function(_, _, y, _, cursorH)
        local top = scroll:GetVerticalScroll()
        local cy = -y
        if cy < top then scroll:SetVerticalScroll(cy)
        elseif cy + cursorH > top + scroll:GetHeight() then
            scroll:SetVerticalScroll(cy + cursorH - scroll:GetHeight())
        end
    end)

    container.edit = edit
    function container:GetText() return edit:GetText() end
    function container:SetText(t) edit:SetText(t or ""); scroll:SetVerticalScroll(0) end
    function container:Focus() edit:SetFocus(); edit:HighlightText() end
    return container
end
