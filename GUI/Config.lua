---@diagnostic disable: undefined-global
-- TomoBoss — Fenêtre d'options thémée (dark black + menthe).

local NS = select(2, ...)
NS.GUI = NS.GUI or {}
local Config = {}
NS.GUI.Config = Config

local L = setmetatable({}, { __index = function(_, k) return NS.L[k] or k end })
local C -- couleurs (résolues à la construction)

--------------------------------------------------------------------------
-- Aide à la disposition verticale d'une page.
--------------------------------------------------------------------------
local function Layout(page, x, top)
    local o = { page = page, x = x or 18, y = -(top or 16) }
    function o:Add(ctrl, h, dx)
        ctrl:ClearAllPoints()
        ctrl:SetPoint("TOPLEFT", page, "TOPLEFT", self.x + (dx or 0), self.y)
        self.y = self.y - (h or (ctrl.GetHeight and ctrl:GetHeight()) or 24) - 12
        return ctrl
    end
    function o:Gap(px) self.y = self.y - (px or 8) end
    return o
end

-- Options communes d'un groupe de barres (largeur, hauteur, etc.).
local function BarOptions(page, lay, group, barcfg)
    local function slider(label, key, min, max, step, fmt)
        local s = NS.Theme:CreateSlider(page, { label = label, min = min, max = max, step = step, value = barcfg[key], width = 300, fmt = fmt })
        s:SetCallback(function(v)
            barcfg[key] = (step >= 1) and math.floor(v + 0.5) or v
            if group then group:Restyle() end
        end)
        lay:Add(s, 46)
    end
    slider(L.BARS_WIDTH,    "width",    120, 360, 2, function(v) return string.format("%d px", v) end)
    slider(L.BARS_HEIGHT,   "height",   14,  40,  1, function(v) return string.format("%d px", v) end)
    slider(L.BARS_MAX,      "maxBars",  1,   12,  1, function(v) return string.format("%d", v) end)
    slider(L.BARS_SPACING,  "spacing",  0,   14,  1, function(v) return string.format("%d px", v) end)
    slider(L.BARS_FONTSIZE, "fontSize", 8,   22,  1, function(v) return string.format("%d", v) end)

    local growLbl = page:CreateFontString(nil, "OVERLAY")
    NS.Theme:Font(growLbl, 12, "muted"); growLbl:SetText(L.BARS_GROW)
    lay:Add(growLbl, 16)
    local grow = NS.Theme:CreateDropdown(page, {
        width = 200,
        items = { { value = "down", text = L.BARS_GROW_DOWN }, { value = "up", text = L.BARS_GROW_UP } },
        onSelect = function(v) barcfg.grow = v; if group then group:Restyle() end end,
    })
    grow:SetValue(barcfg.grow)
    lay:Add(grow, 32)

    local icon = NS.Theme:CreateCheck(page, L.BARS_ICON)
    icon:SetChecked(barcfg.showIcon)
    icon:SetCallback(function(v) barcfg.showIcon = v; if group then group:Restyle() end end)
    lay:Add(icon, 22)
end

--------------------------------------------------------------------------
-- Construction de la fenêtre.
--------------------------------------------------------------------------
function Config:Build()
    if self.frame then return self.frame end
    C = NS.Theme.colors
    local prof = NS.db.profile

    local f = CreateFrame("Frame", "TomoBossConfig", UIParent)
    f:SetSize(660, 470)
    f:SetPoint("CENTER")
    f:SetFrameStrata("HIGH")
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    NS.Theme:Skin(f, { bg = C.bg0, border = C.line })
    tinsert(UISpecialFrames, "TomoBossConfig") -- fermeture avec Échap
    self.frame = f

    -- Barre de titre
    local title = NS.Theme:CreatePanel(f, { bg = C.bg1, border = false })
    title:SetPoint("TOPLEFT", 1, -1); title:SetPoint("TOPRIGHT", -1, -1); title:SetHeight(40)
    local accent = title:CreateTexture(nil, "OVERLAY")
    accent:SetTexture(NS.Theme.BAR_TEXTURE())
    accent:SetVertexColor(C.mint[1], C.mint[2], C.mint[3])
    accent:SetPoint("BOTTOMLEFT"); accent:SetPoint("BOTTOMRIGHT"); accent:SetHeight(2)

    local tName = title:CreateFontString(nil, "OVERLAY")
    tName:SetPoint("LEFT", 16, 0)
    NS.Theme:Font(tName, 18, "text", nil)
    tName:SetText("|cff33e6a6Tomo|r|cffe6edeaBoss|r")

    local tTag = title:CreateFontString(nil, "OVERLAY")
    tTag:SetPoint("LEFT", tName, "RIGHT", 10, 0)
    NS.Theme:Font(tTag, 12, "muted")
    tTag:SetText("· " .. L.TAGLINE)

    local ver = title:CreateFontString(nil, "OVERLAY")
    ver:SetPoint("RIGHT", -40, 0)
    NS.Theme:Font(ver, 11, "muted")
    ver:SetText("v" .. NS.version)

    local close = NS.Theme:CreateButton(title, "X", 24, 24)
    close:SetPoint("RIGHT", -8, 0)
    close:SetScript("OnClick", function() f:Hide() end)

    -- Rail d'onglets (gauche)
    local rail = NS.Theme:CreatePanel(f, { bg = C.bg1, border = false })
    rail:SetPoint("TOPLEFT", 1, -41); rail:SetPoint("BOTTOMLEFT", 1, 1); rail:SetWidth(160)
    local sep = rail:CreateTexture(nil, "OVERLAY")
    sep:SetTexture(NS.Theme.BAR_TEXTURE()); sep:SetVertexColor(C.line[1], C.line[2], C.line[3])
    sep:SetPoint("TOPRIGHT"); sep:SetPoint("BOTTOMRIGHT"); sep:SetWidth(1)

    -- Zone de contenu (droite)
    local content = CreateFrame("Frame", nil, f)
    content:SetPoint("TOPLEFT", rail, "TOPRIGHT", 1, 0)
    content:SetPoint("BOTTOMRIGHT", -1, 1)
    self.content = content

    self.pages = {}
    self.tabs = {}
    self:BuildTabs(rail)

    return f
end

--------------------------------------------------------------------------
-- Onglets + pages.
--------------------------------------------------------------------------
function Config:BuildTabs(rail)
    local defs = {
        { key = "general",   label = L.TAB_GENERAL,    build = "BuildGeneral" },
        { key = "bars",      label = L.TAB_BARS,       build = "BuildBars" },
        { key = "voice",     label = L.TAB_VOICE,      build = "BuildVoice" },
        { key = "countdown", label = L.TAB_COUNTDOWN,  build = "BuildCountdown" },
        { key = "interrupts",label = L.TAB_INTERRUPTS, build = "BuildInterrupts" },
        { key = "trash",     label = L.TAB_TRASH,      build = "BuildTrash" },
        { key = "about",     label = L.TAB_ABOUT,      build = "BuildAbout" },
    }

    local y = -14
    for _, d in ipairs(defs) do
        local btn = CreateFrame("Button", nil, rail)
        btn:SetSize(150, 30)
        btn:SetPoint("TOPLEFT", 6, y)
        y = y - 34

        btn.hl = btn:CreateTexture(nil, "BACKGROUND")
        btn.hl:SetTexture(NS.Theme.BAR_TEXTURE())
        btn.hl:SetAllPoints(btn)
        btn.hl:SetVertexColor(C.mint[1], C.mint[2], C.mint[3], 0.14)
        btn.hl:Hide()

        btn.bar = btn:CreateTexture(nil, "OVERLAY")
        btn.bar:SetTexture(NS.Theme.BAR_TEXTURE())
        btn.bar:SetVertexColor(C.mint[1], C.mint[2], C.mint[3])
        btn.bar:SetPoint("TOPLEFT"); btn.bar:SetPoint("BOTTOMLEFT"); btn.bar:SetWidth(3)
        btn.bar:Hide()

        btn.text = btn:CreateFontString(nil, "OVERLAY")
        btn.text:SetPoint("LEFT", 14, 0)
        NS.Theme:Font(btn.text, 13, "muted")
        btn.text:SetText(d.label)

        btn.key = d.key
        btn:SetScript("OnEnter", function(self) if Config.current ~= self.key then self.hl:Show() end end)
        btn:SetScript("OnLeave", function(self) if Config.current ~= self.key then self.hl:Hide() end end)
        btn:SetScript("OnClick", function(self) Config:Select(self.key) end)

        -- page
        local page = CreateFrame("Frame", nil, self.content)
        page:SetAllPoints(self.content)
        page:Hide()
        self.pages[d.key] = page
        self[d.build](self, page)

        self.tabs[d.key] = btn
    end

    self:Select("general")
end

function Config:Select(key)
    self.current = key
    for k, btn in pairs(self.tabs) do
        local on = (k == key)
        btn.bar:SetShown(on)
        btn.hl:SetShown(on)
        btn.text:SetTextColor(on and NS.Theme:Color("mint") or NS.Theme:Color("muted"))
    end
    for k, page in pairs(self.pages) do page:SetShown(k == key) end
end

--------------------------------------------------------------------------
-- Page : Général
--------------------------------------------------------------------------
function Config:BuildGeneral(page)
    local prof = NS.db.profile
    local lay = Layout(page)

    lay:Add(NS.Theme:SectionTitle(page, L.TAB_GENERAL), 20)

    local en = NS.Theme:CreateCheck(page, L.ENABLED)
    en:SetChecked(prof.enabled)
    en:SetCallback(function(v)
        prof.enabled = v
        if not v then
            NS.Engine.Timeline:Stop()
            NS.UI.TimerBars:Clear()
        end
    end)
    lay:Add(en, 22)

    local sc = NS.Theme:CreateSlider(page, {
        label = L.GLOBAL_SCALE, min = 0.5, max = 2.0, step = 0.05, value = prof.scale, width = 300,
        fmt = function(v) return string.format("%.2f×", v) end,
    })
    sc:SetCallback(function(v) prof.scale = v; NS:ApplyScale() end)
    lay:Add(sc, 46)

    lay:Gap(4)

    -- Boutons d'action
    local testBtn = NS.Theme:CreateButton(page, L.TEST_RUN, 170, 28)
    testBtn:SetScript("OnClick", function(self)
        if NS.Engine.Timeline.demo then
            NS.Engine.Timeline:StopDemo()
            self:SetText(L.TEST_RUN)
        else
            NS.Engine.Timeline:RunDemo(1999)
            self:SetText(L.TEST_STOP)
        end
    end)
    lay:Add(testBtn, 34)
    self._testBtn = testBtn

    local lockBtn = NS.Theme:CreateButton(page, L.UNLOCK, 170, 28)
    lockBtn:SetScript("OnClick", function(self)
        local editing = NS.UI.Mover:Toggle()
        self:SetText(editing and L.LOCK or L.UNLOCK)
        NS:Print(editing and NS.L.MSG_UNLOCKED or NS.L.MSG_LOCKED)
    end)
    lay:Add(lockBtn, 34)
    self._lockBtn = lockBtn

    local hint = page:CreateFontString(nil, "OVERLAY")
    NS.Theme:Font(hint, 11, "muted")
    hint:SetText(L.UNLOCK_DESC)
    lay:Add(hint, 18)

    local resetBtn = NS.Theme:CreateButton(page, L.RESET_POS, 170, 26)
    resetBtn:SetScript("OnClick", function()
        wipe(NS.db.profile.positions)
        NS.UI.Mover:ApplyAll()
        NS:Print(NS.L.MSG_RESET)
    end)
    lay:Add(resetBtn, 30)
end

--------------------------------------------------------------------------
-- Page : Barres
--------------------------------------------------------------------------
function Config:BuildBars(page)
    local b = NS.db.profile.bars
    local lay = Layout(page)
    lay:Add(NS.Theme:SectionTitle(page, L.BARS_TITLE), 20)

    local function slider(label, key, min, max, step, fmt)
        local s = NS.Theme:CreateSlider(page, { label = label, min = min, max = max, step = step, value = b[key], width = 300, fmt = fmt })
        s:SetCallback(function(v)
            b[key] = (step >= 1) and math.floor(v + 0.5) or v
            NS.UI.TimerBars:Restyle()
        end)
        lay:Add(s, 46)
        return s
    end

    slider(L.BARS_WIDTH,    "width",    120, 360, 2, function(v) return string.format("%d px", v) end)
    slider(L.BARS_HEIGHT,   "height",   14,  40,  1, function(v) return string.format("%d px", v) end)
    slider(L.BARS_MAX,      "maxBars",  1,   12,  1, function(v) return string.format("%d", v) end)
    slider(L.BARS_SPACING,  "spacing",  0,   14,  1, function(v) return string.format("%d px", v) end)
    slider(L.BARS_FONTSIZE, "fontSize", 8,   22,  1, function(v) return string.format("%d", v) end)
    slider(L.BARS_WINDOW,   "showWindow", 0, 60, 1, function(v)
        if v < 1 then return "Toujours" else return string.format("%d s", v) end
    end)
    local winDesc = page:CreateFontString(nil, "OVERLAY")
    NS.Theme:Font(winDesc, 11, "muted"); winDesc:SetText(L.BARS_WINDOW_DESC)
    lay:Add(winDesc, 18)

    lay:Gap(2)
    local growLbl = page:CreateFontString(nil, "OVERLAY")
    NS.Theme:Font(growLbl, 12, "muted"); growLbl:SetText(L.BARS_GROW)
    lay:Add(growLbl, 16)
    local grow = NS.Theme:CreateDropdown(page, {
        width = 200,
        items = { { value = "down", text = L.BARS_GROW_DOWN }, { value = "up", text = L.BARS_GROW_UP } },
        onSelect = function(v) b.grow = v; NS.UI.TimerBars:Restyle() end,
    })
    grow:SetValue(b.grow)
    lay:Add(grow, 32)

    local icon = NS.Theme:CreateCheck(page, L.BARS_ICON)
    icon:SetChecked(b.showIcon)
    icon:SetCallback(function(v) b.showIcon = v; NS.UI.TimerBars:Restyle() end)
    lay:Add(icon, 22)
end

--------------------------------------------------------------------------
-- Page : Voix
--------------------------------------------------------------------------
function Config:BuildVoice(page)
    local v = NS.db.profile.voice
    local lay = Layout(page)
    lay:Add(NS.Theme:SectionTitle(page, L.VOICE_TITLE), 20)

    local en = NS.Theme:CreateCheck(page, L.VOICE_ENABLED)
    en:SetChecked(v.enabled)
    en:SetCallback(function(val) v.enabled = val end)
    lay:Add(en, 20)

    local enDesc = page:CreateFontString(nil, "OVERLAY")
    NS.Theme:Font(enDesc, 11, "muted"); enDesc:SetText(L.VOICE_ENABLED_DESC)
    lay:Add(enDesc, 18)

    local chLbl = page:CreateFontString(nil, "OVERLAY")
    NS.Theme:Font(chLbl, 12, "muted"); chLbl:SetText(L.VOICE_CHANNEL)
    lay:Add(chLbl, 16)
    local ch = NS.Theme:CreateDropdown(page, {
        width = 200,
        items = {
            { value = "Master",   text = "Master (principal)" },
            { value = "SFX",      text = "Effets (SFX)" },
            { value = "Dialog",   text = "Dialogues" },
            { value = "Music",    text = "Musique" },
            { value = "Ambience", text = "Ambiance" },
        },
        onSelect = function(val) v.channel = val end,
    })
    ch:SetValue(v.channel)
    lay:Add(ch, 32)

    local lead = NS.Theme:CreateSlider(page, {
        label = L.VOICE_LEAD, min = 0, max = 3, step = 0.1, value = v.lead, width = 300,
        fmt = function(val) return string.format("%.1f s", val) end,
    })
    lead:SetCallback(function(val) v.lead = val end)
    lay:Add(lead, 44)
    local leadDesc = page:CreateFontString(nil, "OVERLAY")
    NS.Theme:Font(leadDesc, 11, "muted"); leadDesc:SetText(L.VOICE_LEAD_DESC)
    lay:Add(leadDesc, 20)

    local gap = NS.Theme:CreateSlider(page, {
        label = L.VOICE_MINGAP, min = 0, max = 2, step = 0.1, value = v.minGap, width = 300,
        fmt = function(val) if val < 0.05 then return "Désactivé" else return string.format("%.1f s", val) end end,
    })
    gap:SetCallback(function(val) v.minGap = val end)
    lay:Add(gap, 44)
    local gapDesc = page:CreateFontString(nil, "OVERLAY")
    NS.Theme:Font(gapDesc, 11, "muted"); gapDesc:SetText(L.VOICE_MINGAP_DESC)
    lay:Add(gapDesc, 20)

    -- Aperçu d'une annonce
    local prevLbl = page:CreateFontString(nil, "OVERLAY")
    NS.Theme:Font(prevLbl, 12, "muted"); prevLbl:SetText(L.VOICE_PREVIEW)
    lay:Add(prevLbl, 16)

    local dd = NS.Theme:CreateDropdown(page, { width = 300, items = NS.Voice:BuildList() })
    dd:SetValue("interrupt-now", "[Général] Interromps !")
    lay:Add(dd, 32)

    local play = NS.Theme:CreateButton(page, L.VOICE_PLAY, 120, 26)
    play:SetScript("OnClick", function()
        local id = dd:GetValue()
        if id then NS.Voice:Play(id, { force = true }) end
    end)
    lay:Add(play, 34)

    local credit = page:CreateFontString(nil, "OVERLAY")
    NS.Theme:Font(credit, 11, "mintLo"); credit:SetText(L.VOICE_PACK)
    lay:Add(credit, 16)
end

--------------------------------------------------------------------------
-- Page : Compte à rebours
--------------------------------------------------------------------------
function Config:BuildCountdown(page)
    local cd = NS.db.profile.countdown
    local v = NS.db.profile.voice
    local lay = Layout(page)
    lay:Add(NS.Theme:SectionTitle(page, L.CD_TITLE), 20)

    local en = NS.Theme:CreateCheck(page, L.CD_ENABLED)
    en:SetChecked(cd.enabled)
    en:SetCallback(function(val) cd.enabled = val end)
    lay:Add(en, 22)

    local sc = NS.Theme:CreateSlider(page, {
        label = L.CD_SCALE, min = 0.5, max = 2.0, step = 0.05, value = cd.scale, width = 300,
        fmt = function(val) return string.format("%.2f×", val) end,
    })
    sc:SetCallback(function(val) cd.scale = val; NS.UI.Countdown:ApplyScale() end)
    lay:Add(sc, 46)

    local vc = NS.Theme:CreateCheck(page, L.CD_VOICE)
    vc:SetChecked(v.countdown)
    vc:SetCallback(function(val) v.countdown = val end)
    lay:Add(vc, 22)

    lay:Gap(6)
    local usage = page:CreateFontString(nil, "OVERLAY")
    NS.Theme:Font(usage, 12, "muted"); usage:SetText(L.CD_USAGE)
    lay:Add(usage, 18)

    local testCd = NS.Theme:CreateButton(page, "Tester le décompte (10 s)", 220, 28)
    testCd:SetScript("OnClick", function() NS.Engine.Pull:BeginDisplay(10) end)
    lay:Add(testCd, 30)
end

--------------------------------------------------------------------------
-- Page : Interruptions
--------------------------------------------------------------------------
function Config:BuildInterrupts(page)
    local c = NS.db.profile.interrupts
    local IT = NS.InterruptTracker
    local lay = Layout(page)
    lay:Add(NS.Theme:SectionTitle(page, L.INT_TITLE), 20)

    local en = NS.Theme:CreateCheck(page, L.INT_ENABLED)
    en:SetChecked(c.enabled)
    en:SetCallback(function(v) c.enabled = v; if IT and IT.UpdateEnv then IT:UpdateEnv() end end)
    lay:Add(en, 20)

    local desc = page:CreateFontString(nil, "OVERLAY")
    NS.Theme:Font(desc, 11, "muted"); desc:SetText(L.INT_ENABLED_DESC)
    lay:Add(desc, 18)

    local self_cd = NS.Theme:CreateCheck(page, L.INT_SELFCD)
    self_cd:SetChecked(c.showSelfCD)
    self_cd:SetCallback(function(v) c.showSelfCD = v end)
    lay:Add(self_cd, 24)

    BarOptions(page, lay, IT and IT.group, c)

    local kicks = NS.Theme:CreateButton(page, L.INT_KICKS_BTN, 200, 26)
    kicks:SetScript("OnClick", function() if IT then IT:PrintTally() end end)
    lay:Add(kicks, 30)
end

--------------------------------------------------------------------------
-- Page : TrashCD
--------------------------------------------------------------------------
function Config:BuildTrash(page)
    local c = NS.db.profile.trash
    local TC = NS.TrashCD
    local lay = Layout(page)
    lay:Add(NS.Theme:SectionTitle(page, L.TRASH_TITLE), 20)

    local en = NS.Theme:CreateCheck(page, L.TRASH_ENABLED)
    en:SetChecked(c.enabled)
    en:SetCallback(function(v) c.enabled = v; if TC and TC.UpdateEnv then TC:UpdateEnv() end end)
    lay:Add(en, 20)

    local desc = page:CreateFontString(nil, "OVERLAY")
    NS.Theme:Font(desc, 11, "muted"); desc:SetText(L.TRASH_ENABLED_DESC)
    lay:Add(desc, 18)

    local vk = NS.Theme:CreateCheck(page, L.TRASH_VOICE_KICK)
    vk:SetChecked(c.voiceOnKick)
    vk:SetCallback(function(v) c.voiceOnKick = v end)
    lay:Add(vk, 24)

    BarOptions(page, lay, TC and TC.group, c)
end

--------------------------------------------------------------------------
-- Page : À propos
--------------------------------------------------------------------------
function Config:BuildAbout(page)
    local lay = Layout(page)
    lay:Add(NS.Theme:SectionTitle(page, L.TAB_ABOUT), 22)

    local ver = page:CreateFontString(nil, "OVERLAY")
    NS.Theme:Font(ver, 13, "text")
    ver:SetText(L.ABOUT_VERSION .. " : |cff33e6a6" .. NS.version .. "|r")
    lay:Add(ver, 20)

    local body = page:CreateFontString(nil, "OVERLAY")
    NS.Theme:Font(body, 12, "muted")
    body:SetWidth(440); body:SetJustifyH("LEFT")
    body:SetText(L.ABOUT_BODY)
    lay:Add(body, 64)

    lay:Gap(4)
    local cmdTitle = page:CreateFontString(nil, "OVERLAY")
    NS.Theme:Font(cmdTitle, 13, "mint"); cmdTitle:SetText(L.ABOUT_COMMANDS)
    lay:Add(cmdTitle, 20)

    local cmds = {
        L.HELP_OPTIONS, L.HELP_PULL, L.HELP_PULLSTOP, L.HELP_TEST,
        L.HELP_LOCK, L.HELP_RESET, L.HELP_VOICE, L.HELP_KICKS,
    }
    for _, c in ipairs(cmds) do
        local fs = page:CreateFontString(nil, "OVERLAY")
        NS.Theme:Font(fs, 12, "text")
        fs:SetText("|cff8a968f•|r " .. c)
        lay:Add(fs, 16)
    end
end

--------------------------------------------------------------------------
-- Ouverture / fermeture.
--------------------------------------------------------------------------
function Config:Toggle()
    self:Build()
    if self.frame:IsShown() then
        self.frame:Hide()
    else
        -- resynchronise l'état des boutons dynamiques
        if self._testBtn then self._testBtn:SetText(NS.Engine.Timeline.demo and L.TEST_STOP or L.TEST_RUN) end
        if self._lockBtn then self._lockBtn:SetText(NS.UI.Mover.editing and L.LOCK or L.UNLOCK) end
        self.frame:Show()
    end
end
