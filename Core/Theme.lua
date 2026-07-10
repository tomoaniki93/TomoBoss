---@diagnostic disable: undefined-global
-- TomoBoss — Thème visuel « dark black + menthe » et fabriques de widgets.

local NS = select(2, ...)
local Theme = {}
NS.Theme = Theme

local WHITE = "Interface\\Buttons\\WHITE8X8"  -- texture blanche 8x8 (fiable, teintable)
local FONT  = STANDARD_TEXT_FONT              -- supporte les accents français

-- Jetons de couleur {r, g, b}
local C = {
    bg0    = { 0.039, 0.047, 0.043 }, -- fond le plus sombre
    bg1    = { 0.067, 0.078, 0.071 }, -- panneaux
    bg2    = { 0.098, 0.114, 0.106 }, -- éléments surélevés
    bg3    = { 0.129, 0.149, 0.141 }, -- survol
    line   = { 0.157, 0.180, 0.169 }, -- bordures discrètes
    mint   = { 0.200, 0.902, 0.651 }, -- accent menthe
    mintLo = { 0.157, 0.706, 0.510 }, -- menthe atténuée
    text   = { 0.902, 0.929, 0.918 }, -- texte principal
    muted  = { 0.541, 0.588, 0.561 }, -- texte secondaire
    danger = { 1.000, 0.420, 0.420 }, -- danger / sévérité 2
    warn   = { 1.000, 0.780, 0.350 },
    tank   = { 0.400, 0.720, 1.000 }, -- bleu tank / sévérité 0
    heal   = { 0.400, 0.850, 0.520 },
    dps    = { 1.000, 0.620, 0.320 },
    mech   = { 0.720, 0.520, 1.000 },
    white  = { 1.000, 1.000, 1.000 },
    black  = { 0.000, 0.000, 0.000 },
}
Theme.colors = C

function Theme:Color(key) local c = C[key] or C.text; return c[1], c[2], c[3] end

function Theme:Severity(sev)
    if sev == 2 then return C.danger end
    if sev == 0 then return C.tank end
    return C.mint
end

function Theme:Role(role)
    return C[role] or C.mint
end

--------------------------------------------------------------------------
-- Habillage : fond plein + bordure 1px, via textures blanches teintées.
--------------------------------------------------------------------------
function Theme:Skin(frame, opts)
    opts = opts or {}
    local bg = opts.bg or C.bg1
    local br = opts.border or C.line
    local a  = opts.alpha or 1

    if not frame.__bg then
        frame.__bg = frame:CreateTexture(nil, "BACKGROUND")
        frame.__bg:SetTexture(WHITE)
        frame.__bg:SetAllPoints(frame)
    end
    frame.__bg:SetVertexColor(bg[1], bg[2], bg[3], a)

    if opts.border ~= false then
        if not frame.__brd then
            frame.__brd = {}
            for _, p in ipairs({ "TOP", "BOTTOM", "LEFT", "RIGHT" }) do
                local t = frame:CreateTexture(nil, "BORDER")
                t:SetTexture(WHITE)
                frame.__brd[p] = t
            end
        end
        local s = opts.borderSize or 1
        local t = frame.__brd
        t.TOP:ClearAllPoints();    t.TOP:SetPoint("TOPLEFT");    t.TOP:SetPoint("TOPRIGHT");    t.TOP:SetHeight(s)
        t.BOTTOM:ClearAllPoints(); t.BOTTOM:SetPoint("BOTTOMLEFT"); t.BOTTOM:SetPoint("BOTTOMRIGHT"); t.BOTTOM:SetHeight(s)
        t.LEFT:ClearAllPoints();   t.LEFT:SetPoint("TOPLEFT");   t.LEFT:SetPoint("BOTTOMLEFT");   t.LEFT:SetWidth(s)
        t.RIGHT:ClearAllPoints();  t.RIGHT:SetPoint("TOPRIGHT"); t.RIGHT:SetPoint("BOTTOMRIGHT"); t.RIGHT:SetWidth(s)
        for _, tx in pairs(t) do tx:SetVertexColor(br[1], br[2], br[3], opts.borderAlpha or 1) end
    end
    return frame
end

function Theme:Font(fs, size, colorKey, flags)
    fs:SetFont(FONT, size or 13, flags)
    local c = C[colorKey or "text"] or C.text
    fs:SetTextColor(c[1], c[2], c[3])
    return fs
end

-- Renvoie la police et la texture pour les autres modules.
function Theme.FONT() return FONT end
function Theme.BAR_TEXTURE() return WHITE end

--------------------------------------------------------------------------
-- Panneau habillé.
--------------------------------------------------------------------------
function Theme:CreatePanel(parent, opts)
    local f = CreateFrame("Frame", nil, parent)
    self:Skin(f, opts)
    return f
end

--------------------------------------------------------------------------
-- Bouton (accent menthe au survol).
--------------------------------------------------------------------------
function Theme:CreateButton(parent, text, w, h)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(w or 120, h or 26)
    self:Skin(b, { bg = C.bg2, border = C.line })
    b.text = b:CreateFontString(nil, "OVERLAY")
    b.text:SetPoint("CENTER")
    self:Font(b.text, 13, "text")
    b.text:SetText(text or "")

    b:SetScript("OnEnter", function(self)
        self.__bg:SetVertexColor(C.bg3[1], C.bg3[2], C.bg3[3], 1)
        for _, tx in pairs(self.__brd) do tx:SetVertexColor(C.mint[1], C.mint[2], C.mint[3], 1) end
        self.text:SetTextColor(C.mint[1], C.mint[2], C.mint[3])
    end)
    b:SetScript("OnLeave", function(self)
        self.__bg:SetVertexColor(C.bg2[1], C.bg2[2], C.bg2[3], 1)
        for _, tx in pairs(self.__brd) do tx:SetVertexColor(C.line[1], C.line[2], C.line[3], 1) end
        self.text:SetTextColor(C.text[1], C.text[2], C.text[3])
    end)
    function b:SetText(t) self.text:SetText(t) end
    return b
end

--------------------------------------------------------------------------
-- Case à cocher.
--------------------------------------------------------------------------
function Theme:CreateCheck(parent, text)
    local f = CreateFrame("Button", nil, parent)
    f:SetSize(22, 22)

    local box = self:CreatePanel(f, { bg = C.bg2, border = C.line })
    box:SetSize(18, 18)
    box:SetPoint("LEFT")
    f.box = box

    local tick = box:CreateTexture(nil, "OVERLAY")
    tick:SetTexture(WHITE)
    tick:SetPoint("CENTER")
    tick:SetSize(10, 10)
    tick:SetVertexColor(C.mint[1], C.mint[2], C.mint[3])
    tick:Hide()
    f.tick = tick

    f.label = f:CreateFontString(nil, "OVERLAY")
    f.label:SetPoint("LEFT", box, "RIGHT", 8, 0)
    self:Font(f.label, 13, "text")
    f.label:SetText(text or "")
    f:SetWidth(28 + f.label:GetStringWidth())

    f.checked = false
    function f:SetChecked(v) self.checked = v and true or false; if self.checked then tick:Show() else tick:Hide() end end
    function f:GetChecked() return self.checked end
    function f:SetCallback(fn) self._cb = fn end
    f:SetScript("OnClick", function(self)
        self:SetChecked(not self.checked)
        if self._cb then self._cb(self.checked) end
    end)
    f:SetScript("OnEnter", function(self) for _, tx in pairs(box.__brd) do tx:SetVertexColor(C.mint[1], C.mint[2], C.mint[3]) end end)
    f:SetScript("OnLeave", function(self) for _, tx in pairs(box.__brd) do tx:SetVertexColor(C.line[1], C.line[2], C.line[3]) end end)
    return f
end

--------------------------------------------------------------------------
-- Curseur (slider) horizontal, valeur + libellé.
--------------------------------------------------------------------------
function Theme:CreateSlider(parent, opts)
    opts = opts or {}
    local width = opts.width or 220
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(width, 42)

    f.label = f:CreateFontString(nil, "OVERLAY")
    f.label:SetPoint("TOPLEFT")
    self:Font(f.label, 12, "muted")
    f.label:SetText(opts.label or "")

    f.valText = f:CreateFontString(nil, "OVERLAY")
    f.valText:SetPoint("TOPRIGHT")
    self:Font(f.valText, 12, "mint")

    local track = self:CreatePanel(f, { bg = C.bg2, border = C.line })
    track:SetHeight(6)
    track:SetPoint("BOTTOMLEFT", 0, 4)
    track:SetPoint("BOTTOMRIGHT", 0, 4)
    f.track = track

    local fill = track:CreateTexture(nil, "ARTWORK")
    fill:SetTexture(WHITE)
    fill:SetVertexColor(C.mintLo[1], C.mintLo[2], C.mintLo[3])
    fill:SetPoint("TOPLEFT"); fill:SetPoint("BOTTOMLEFT")
    f.fill = fill

    local slider = CreateFrame("Slider", nil, track)
    slider:SetAllPoints(track)
    slider:SetOrientation("HORIZONTAL")
    slider:SetMinMaxValues(opts.min or 0, opts.max or 1)
    slider:SetValueStep(opts.step or 0.01)
    slider:SetObeyStepOnDrag(true)
    slider:SetValue(opts.value or opts.min or 0)

    local thumb = slider:CreateTexture(nil, "OVERLAY")
    thumb:SetTexture(WHITE)
    thumb:SetSize(6, 16)
    thumb:SetVertexColor(C.mint[1], C.mint[2], C.mint[3])
    slider:SetThumbTexture(thumb)

    f.slider = slider
    f._fmt = opts.fmt or function(v) return tostring(NS.round(v, 2)) end

    local function refresh(v)
        local lo, hi = slider:GetMinMaxValues()
        local pct = (hi > lo) and ((v - lo) / (hi - lo)) or 0
        fill:SetWidth(math.max(1, track:GetWidth() * pct))
        f.valText:SetText(f._fmt(v))
    end

    slider:SetScript("OnValueChanged", function(self, v, byUser)
        v = NS.round(v, 4)
        refresh(v)
        if f._cb and byUser then f._cb(v) end
    end)
    slider:SetScript("OnShow", function(self) refresh(self:GetValue()) end)

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
    f:SetSize(opts.width or 200, 26)
    self:Skin(f, { bg = C.bg2, border = C.line })

    f.text = f:CreateFontString(nil, "OVERLAY")
    f.text:SetPoint("LEFT", 8, 0)
    f.text:SetPoint("RIGHT", -22, 0)
    f.text:SetJustifyH("LEFT")
    self:Font(f.text, 12, "text")

    local chev = f:CreateFontString(nil, "OVERLAY")
    chev:SetPoint("RIGHT", -8, 0)
    self:Font(chev, 12, "mint")
    chev:SetText("v")

    local list = CreateFrame("Frame", nil, f)
    list:SetFrameStrata("FULLSCREEN_DIALOG")
    list:SetToplevel(true)
    self:Skin(list, { bg = C.bg1, border = C.mintLo })
    list:Hide()
    f.list = list

    f.items = opts.items or {}
    f._value = nil

    local function rebuild()
        if list.buttons then for _, b in ipairs(list.buttons) do b:Hide() end end
        list.buttons = list.buttons or {}
        local n = #f.items
        local rowH = 22
        list:SetSize(f:GetWidth(), math.max(rowH, n * rowH) + 6)
        for i, item in ipairs(f.items) do
            local b = list.buttons[i]
            if not b then
                b = CreateFrame("Button", nil, list)
                b:SetHeight(rowH)
                b.hl = b:CreateTexture(nil, "BACKGROUND")
                b.hl:SetTexture(WHITE); b.hl:SetAllPoints(b)
                b.hl:SetVertexColor(C.mint[1], C.mint[2], C.mint[3], 0.15); b.hl:Hide()
                b.t = b:CreateFontString(nil, "OVERLAY")
                b.t:SetPoint("LEFT", 8, 0)
                Theme:Font(b.t, 12, "text")
                b:SetScript("OnEnter", function(self) self.hl:Show() end)
                b:SetScript("OnLeave", function(self) self.hl:Hide() end)
                list.buttons[i] = b
            end
            b:ClearAllPoints()
            b:SetPoint("TOPLEFT", 3, -3 - (i - 1) * rowH)
            b:SetPoint("RIGHT", -3, 0)
            b.t:SetText(item.text)
            b:SetScript("OnClick", function()
                f:SetValue(item.value, item.text)
                list:Hide(); openDropdown = nil; closer:Hide()
                if opts.onSelect then opts.onSelect(item.value, item.text) end
            end)
            b:Show()
        end
    end

    f:SetScript("OnClick", function(self)
        if list:IsShown() then
            list:Hide(); openDropdown = nil; closer:Hide()
        else
            rebuild()
            list:ClearAllPoints()
            list:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -2)
            list:Show()
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
-- Titre de section (label menthe + trait).
--------------------------------------------------------------------------
function Theme:SectionTitle(parent, text)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    self:Font(fs, 15, "mint", nil)
    fs:SetText(text)
    return fs
end
