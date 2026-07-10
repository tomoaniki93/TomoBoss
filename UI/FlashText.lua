---@diagnostic disable: undefined-global
-- TomoBoss — Alerte texte centrale (mécaniques importantes).

local NS = select(2, ...)
NS.UI = NS.UI or {}
local FT = {}
NS.UI.FlashText = FT

local function conf() return NS.db.profile.flash end

function FT:EnsureAnchor()
    if self.anchor then return self.anchor end
    local a = CreateFrame("Frame", "TomoBossFlashText", UIParent)
    a:SetSize(440, 56)
    self.anchor = a

    self.text = a:CreateFontString(nil, "OVERLAY")
    self.text:SetPoint("CENTER")
    self.text:SetJustifyH("CENTER")
    NS.Theme:Font(self.text, 30, "danger", "THICKOUTLINE")
    self.text:SetText("")

    self.ticker = CreateFrame("Frame", nil, a)
    self.ticker:Hide()
    self.ticker:SetScript("OnUpdate", function(_, elapsed) self:OnUpdate(elapsed) end)

    a:Hide()
    return a
end

-- Affiche un message pendant `duration` secondes, avec fondu final.
function FT:Show(msg, colorKey, duration)
    if not conf().enabled then return end
    self:EnsureAnchor()
    duration = duration or 2.2
    local c = NS.Theme.colors[colorKey or "danger"] or NS.Theme.colors.danger
    self.text:SetTextColor(c[1], c[2], c[3])
    self.text:SetText(msg or "")
    self.text:SetAlpha(1)
    self.endTime = GetTime() + duration
    self.fadeStart = self.endTime - 0.6
    self.anchor:Show()
    self.ticker:Show()
end

function FT:OnUpdate()
    if not self.endTime then return end
    local now = GetTime()
    if now >= self.endTime then
        self.ticker:Hide()
        self.anchor:Hide()
        self.endTime = nil
        return
    end
    if now >= self.fadeStart then
        local a = 1 - (now - self.fadeStart) / 0.6
        self.text:SetAlpha(NS.clamp(a, 0, 1))
    end
end

-- Aperçu (mode édition).
function FT:ShowDemo(on)
    self:EnsureAnchor()
    if on then
        self.ticker:Hide()
        self.text:SetAlpha(1)
        self.text:SetTextColor(NS.Theme:Color("danger"))
        self.text:SetText("Surcharge glaciaire !")
        self.anchor:Show()
        self.endTime = nil
    else
        if not self.endTime then
            self.anchor:Hide()
        end
    end
end
