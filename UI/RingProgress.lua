---@diagnostic disable: undefined-global
-- TomoBoss — Anneau de progression central. Grand anneau (autour du personnage)
-- qui SE REFERME à l'approche de la prochaine capacité : cercle complet = ça tombe.
-- Technique : Cooldown frame + texture d'anneau en swipe + SetReverse (comme BossReminder).

local NS = select(2, ...)
NS.UI = NS.UI or {}
local Ring = {}
NS.UI.RingProgress = Ring

local RING_TEX = "Interface\\AddOns\\TomoBoss\\Media\\Textures\\TomoRing"

local function db() return NS.db.profile.ringProgress end

function Ring:Ensure()
    if self.anchor then return self.anchor end
    local d = db() or {}
    local size = d.size or 180

    local f = CreateFrame("Frame", "TomoBossRingProgress", UIParent)
    f:SetSize(size, size)
    f:SetPoint("CENTER")
    f:Hide()
    self.anchor = f

    local cd = CreateFrame("Cooldown", nil, f, "CooldownFrameTemplate")
    cd:SetAllPoints()
    cd:SetHideCountdownNumbers(true)
    cd:SetDrawBling(false)
    cd:SetDrawSwipe(true)
    cd:SetDrawEdge(d.edge ~= false)
    cd:SetReverse(true) -- le cercle se complète (se referme) à l'approche
    cd:SetSwipeTexture(RING_TEX)
    self.cd = cd

    local nm = f:CreateFontString(nil, "OVERLAY")
    NS.Theme:Font(nm, 14, "text", "THICKOUTLINE")
    nm:SetPoint("TOP", f, "BOTTOM", 0, -2)
    self.nameFS = nm

    return f
end

function Ring:ApplyColor(sev)
    if not self.cd then return end
    local c = NS.Theme:Severity(sev) or NS.Theme.colors.mint
    local a = (db() and db().alpha) or 0.85
    self.cd:SetSwipeColor(c[1], c[2], c[3], a)
end

-- Suit la prochaine capacité : key = identifiant, remaining/total en secondes.
function Ring:Track(key, remaining, total, name, sev)
    if self._edit then return end
    if not (db() and db().enabled) then return end
    if not remaining or remaining <= 0 then return self:Stop(key) end
    self:Ensure()
    total = total or remaining
    local now = GetTime()
    if self._key ~= key then
        self._key = key
        self._total = total
        self._expires = now + remaining
        self:ApplyColor(sev)
        self.cd:SetCooldown(now - (total - remaining), total)
        self.nameFS:SetText(name or "")
        self.anchor:Show()
    else
        -- recale si l'écart de temps restant dépasse 0,5 s (anti-dérive)
        local expected = self._expires - now
        if math.abs(expected - remaining) > 0.5 then
            self._expires = now + remaining
            self.cd:SetCooldown(now - (total - remaining), total)
        end
    end
end

function Ring:Stop(key)
    if self._edit then return end
    if key and self._key ~= key then return end
    self._key = nil
    if self.cd then self.cd:Clear() end
    if self.anchor then self.anchor:Hide() end
end

function Ring:Restyle()
    if not self.anchor then return end
    local d = db() or {}
    self.anchor:SetSize(d.size or 180, d.size or 180)
    if self.cd then self.cd:SetDrawEdge(d.edge ~= false) end
end

-- Aperçu en mode édition (déplacement).
function Ring:Demo(on)
    self:Ensure()
    self._edit = on and true or false
    if on then
        self._key = "__demo"
        self:ApplyColor(2)
        self.cd:SetCooldown(GetTime(), 8)
        self.nameFS:SetText("Aperçu")
        self.anchor:Show()
        if not self._demoTicker and C_Timer then
            self._demoTicker = C_Timer.NewTicker(8, function()
                if self._edit and self.cd then self.cd:SetCooldown(GetTime(), 8) end
            end)
        end
    else
        if self._demoTicker then self._demoTicker:Cancel(); self._demoTicker = nil end
        self._key = nil
        if self.cd then self.cd:Clear() end
        if self.anchor then self.anchor:Hide() end
    end
end
