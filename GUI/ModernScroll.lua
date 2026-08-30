---@diagnostic disable: undefined-global
-- TomoBoss — Scrollbar moderne Obsidian + Jade.
--
-- Remplace les UIPanelScrollFrameTemplate du GUI stable par un composant
-- entièrement TomoBoss :
--   * rail sombre fin ;
--   * thumb jade ;
--   * hover / drag accentués ;
--   * clic sur le rail ;
--   * molette ;
--   * thumb proportionnel à la zone visible ;
--   * masquage automatique si aucun scroll n'est nécessaire ;
--   * aucun OnUpdate permanent (uniquement pendant un drag du thumb).

local NS = select(2, ...)
NS.GUI = NS.GUI or {}

local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

local function cursorY(frame)
    local _, y = GetCursorPosition()
    local scale = frame:GetEffectiveScale()
    if not scale or scale <= 0 then
        scale = UIParent:GetEffectiveScale() or 1
    end
    return y / scale
end

function NS.GUI.CreateModernScroll(parent, opts)
    opts = opts or {}
    local C = NS.Theme.colors

    local scroll = CreateFrame("ScrollFrame", nil, parent)
    scroll:EnableMouseWheel(true)

    local child
    if opts.createChild ~= false then
        child = CreateFrame("Frame", nil, scroll)
        child:SetSize(opts.childWidth or 520, opts.childHeight or 10)
        scroll:SetScrollChild(child)
    end

    local rail = CreateFrame("Button", nil, parent)
    rail:SetWidth(opts.barWidth or 10)
    rail:SetPoint("TOPLEFT", scroll, "TOPRIGHT", opts.gap or 5, 0)
    rail:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", opts.gap or 5, 0)
    rail:SetFrameLevel((scroll:GetFrameLevel() or 1) + 5)
    NS.Theme:Skin(rail, {
        bg = C.track,
        border = C.line,
        shadow = false,
        alpha = 0.96,
        borderAlpha = 0.85,
    })

    local thumb = CreateFrame("Button", nil, rail)
    thumb:SetWidth(opts.thumbWidth or 6)
    thumb:SetFrameLevel((rail:GetFrameLevel() or 1) + 1)
    NS.Theme:Skin(thumb, {
        bg = C.accentLo,
        border = C.accent,
        shadow = false,
        alpha = 1,
        borderAlpha = 0.90,
    })

    scroll._tmbRail = rail
    scroll._tmbThumb = thumb
    scroll._tmbChild = child
    scroll._tmbWheelStep = opts.wheelStep or 48

    local function metrics()
        local visible = math.max(1, scroll:GetHeight() or 1)
        local content = scroll._tmbChild
        local contentH = content and math.max(1, content:GetHeight() or 1) or visible
        local maximum = math.max(0, contentH - visible)
        return visible, contentH, maximum
    end

    local function setThumbNormal()
        if not thumb.__bg then return end
        thumb.__bg:SetVertexColor(C.accentLo[1], C.accentLo[2], C.accentLo[3], 1)
        NS.Theme:SetBorderColor(thumb, "accent", 0.90)
    end

    local function setThumbHot()
        if not thumb.__bg then return end
        thumb.__bg:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 1)
        NS.Theme:SetBorderColor(thumb, "accentHi", 1)
    end

    local function updateThumb()
        local visible, contentH, maximum = metrics()
        local trackH = rail:GetHeight() or 0

        if maximum <= 0 or trackH <= 2 then
            if scroll:GetVerticalScroll() ~= 0 then
                scroll:SetVerticalScroll(0)
            end
            rail:Hide()
            return
        end

        rail:Show()

        local thumbH = math.max(opts.minThumbHeight or 30, trackH * (visible / contentH))
        thumbH = math.min(trackH - 2, thumbH)
        local travel = math.max(0, trackH - thumbH - 2)

        local current = clamp(scroll:GetVerticalScroll() or 0, 0, maximum)
        local pct = maximum > 0 and (current / maximum) or 0
        local y = 1 + (travel * pct)

        thumb:ClearAllPoints()
        thumb:SetPoint("TOP", rail, "TOP", 0, -y)
        thumb:SetHeight(thumbH)

        scroll._tmbMaxScroll = maximum
        scroll._tmbThumbTravel = travel
    end

    function scroll:SetTomoVerticalScroll(value)
        local _, _, maximum = metrics()
        value = clamp(tonumber(value) or 0, 0, maximum)
        self:SetVerticalScroll(value)
        updateThumb()
    end

    function scroll:RefreshTomoScroll()
        updateThumb()
    end

    function scroll:SetTomoScrollChild(frame)
        if not frame then return end
        self._tmbChild = frame
        self:SetScrollChild(frame)
        if frame.HookScript and not frame.__tmbScrollHooked then
            frame.__tmbScrollHooked = true
            frame:HookScript("OnSizeChanged", updateThumb)
            frame:HookScript("OnShow", updateThumb)
        end
        updateThumb()
    end

    if child and child.HookScript then
        child.__tmbScrollHooked = true
        child:HookScript("OnSizeChanged", updateThumb)
        child:HookScript("OnShow", updateThumb)
    end

    scroll:SetScript("OnMouseWheel", function(self, delta)
        self:SetTomoVerticalScroll(
            (self:GetVerticalScroll() or 0) - delta * self._tmbWheelStep
        )
    end)

    scroll:HookScript("OnVerticalScroll", updateThumb)
    scroll:HookScript("OnSizeChanged", updateThumb)
    scroll:HookScript("OnHide", function()
        rail:Hide()
    end)
    scroll:HookScript("OnShow", function()
        C_Timer.After(0, function()
            if scroll and scroll:IsShown() then updateThumb() end
        end)
    end)

    thumb:SetScript("OnEnter", function()
        if not thumb._dragging then setThumbHot() end
    end)
    thumb:SetScript("OnLeave", function()
        if not thumb._dragging then setThumbNormal() end
    end)

    local function stopDrag()
        if not thumb._dragging then return end
        thumb._dragging = false
        thumb:SetScript("OnUpdate", nil)
        if thumb:IsMouseOver() then
            setThumbHot()
        else
            setThumbNormal()
        end
    end

    thumb:SetScript("OnMouseDown", function(self, button)
        if button ~= "LeftButton" then return end
        local _, _, maximum = metrics()
        local travel = scroll._tmbThumbTravel or 0
        if maximum <= 0 or travel <= 0 then return end

        self._dragging = true
        self._dragStartY = cursorY(rail)
        self._dragStartScroll = scroll:GetVerticalScroll() or 0
        setThumbHot()

        self:SetScript("OnUpdate", function()
            if not IsMouseButtonDown("LeftButton") then
                stopDrag()
                return
            end

            local _, _, maxNow = metrics()
            local travelNow = scroll._tmbThumbTravel or 0
            if maxNow <= 0 or travelNow <= 0 then return end

            local deltaY = self._dragStartY - cursorY(rail)
            local value = self._dragStartScroll + (deltaY / travelNow) * maxNow
            scroll:SetTomoVerticalScroll(value)
        end)
    end)
    thumb:SetScript("OnMouseUp", stopDrag)
    thumb:SetScript("OnHide", stopDrag)

    rail:SetScript("OnMouseDown", function(self, button)
        if button ~= "LeftButton" then return end
        local _, _, maximum = metrics()
        if maximum <= 0 then return end

        local top = self:GetTop()
        local height = self:GetHeight()
        if not top or not height or height <= 0 then return end

        local pct = clamp((top - cursorY(self)) / height, 0, 1)
        scroll:SetTomoVerticalScroll(maximum * pct)
    end)

    updateThumb()
    return scroll, child, rail
end
