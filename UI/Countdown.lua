---@diagnostic disable: undefined-global
-- TomoBoss — Grand compte à rebours central (pull).

local NS = select(2, ...)
NS.UI = NS.UI or {}
local CD = {}
NS.UI.Countdown = CD

local function conf() return NS.db.profile.countdown end

function CD:EnsureAnchor()
    if self.anchor then return self.anchor end
    local a = CreateFrame("Frame", "TomoBossCountdown", UIParent)
    a:SetSize(160, 110)
    self.anchor = a

    self.number = a:CreateFontString(nil, "OVERLAY")
    self.number:SetPoint("CENTER")
    NS.Theme:Font(self.number, 64, "mint", "THICKOUTLINE")

    self.label = a:CreateFontString(nil, "OVERLAY")
    self.label:SetPoint("TOP", self.number, "BOTTOM", 0, 2)
    NS.Theme:Font(self.label, 14, "muted")
    self.label:SetText("PULL")
    self.label:Hide()

    self.ticker = CreateFrame("Frame", nil, a)
    self.ticker:Hide()
    self.ticker._anim = 0
    self.ticker._lastInt = nil
    self.ticker:SetScript("OnUpdate", function(_, elapsed) self:OnUpdate(elapsed) end)

    self:ApplyScale()
    a:Hide()
    return a
end

function CD:ApplyScale()
    if not self.anchor then return end
    local s = conf().scale or 1
    self.number:SetFont(NS.Theme.FONT(), 64 * s, "THICKOUTLINE")
    self.label:SetFont(NS.Theme.FONT(), 14 * s, "")
end

function CD:Start(seconds)
    seconds = tonumber(seconds)
    if not (conf().enabled) or not seconds or seconds <= 0 then return end
    self:EnsureAnchor()
    self:ApplyScale()
    self.endTime = GetTime() + seconds
    self.ticker._lastInt = nil
    self.anchor:Show()
    self.number:Show()
    self.label:Show()
    self.ticker:Show()
end

function CD:Stop()
    if not self.anchor then return end
    self.endTime = nil
    self.ticker:Hide()
    self.number:Hide()
    self.label:Hide()
    self.anchor:Hide()
end

function CD:OnUpdate(elapsed)
    if not self.endTime then return end
    local remaining = self.endTime - GetTime()
    if remaining <= 0 then
        self:Stop()
        return
    end
    local n = math.ceil(remaining)
    if n ~= self.ticker._lastInt then
        self.ticker._lastInt = n
        self.ticker._anim = 0.45  -- relance l'animation de pulsation
        -- couleur selon le chiffre
        if n <= 1 then
            self.number:SetTextColor(NS.Theme:Color("danger"))
        elseif n <= 3 then
            self.number:SetTextColor(NS.Theme:Color("warn"))
        else
            self.number:SetTextColor(NS.Theme:Color("mint"))
        end
        self.number:SetText(n)
    end

    -- pulsation : grossit puis revient
    if self.ticker._anim > 0 then
        self.ticker._anim = math.max(0, self.ticker._anim - elapsed)
        local t = self.ticker._anim / 0.45      -- 1 -> 0
        local scale = 1 + 0.45 * t
        self.number:SetScale(scale)
        self.number:SetAlpha(0.55 + 0.45 * (1 - t))
    else
        self.number:SetScale(1)
        self.number:SetAlpha(1)
    end
end

-- Aperçu (mode édition).
function CD:ShowDemo(on)
    self:EnsureAnchor()
    if on then
        self.number:SetText("5")
        self.number:SetTextColor(NS.Theme:Color("mint"))
        self.number:SetScale(1)
        self.number:SetAlpha(1)
        self.number:Show(); self.label:Show(); self.anchor:Show()
        self.ticker:Hide()
        self.endTime = nil
    else
        if not self.endTime then self:Stop() end
    end
end
