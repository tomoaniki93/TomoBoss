---@diagnostic disable: undefined-global
-- TomoBoss — GUI stable / RC1.
--
-- Objectifs :
--   * réduire le nombre d'onglets "techniques" visibles au premier niveau ;
--   * fusionner Voix + Compte à rebours dans "Audio" ;
--   * conserver la page Affichage contextuelle Barres / Timeline / Hybride ;
--   * remplacer l'ancien onglet TrashCD par les alertes de packs réellement
--     compatibles Midnight (anneau ciblé secret-safe) ;
--   * déplacer Timeline Blizzard et anneaux de rôle dans "Avancé" ;
--   * ajouter une page Données pour piloter la sortie des minutages tierces.
--
-- Ce fichier est chargé APRES Config.lua et DisplayMode.lua et remplace
-- uniquement la composition des pages. Les moteurs runtime restent inchangés.

local NS = select(2, ...)
if not (NS.GUI and NS.GUI.Config) then return end

local Config = NS.GUI.Config

local Original = {
    Voice      = Config.BuildVoice,
    Countdown  = Config.BuildCountdown,
    Interrupts = Config.BuildInterrupts,
    Custom     = Config.BuildCustom,
    Blizz      = Config.BuildBlizz,
    About      = Config.BuildAbout,
}

--------------------------------------------------------------------------
-- Localisation.
-- Les locales qui n'ont pas encore leur traduction reçoivent l'anglais au
-- lieu d'afficher la clé brute. frFR est surchargée ci-dessous.
--------------------------------------------------------------------------
local EN = {
    STABLE_TAB_AUDIO       = "Audio",
    STABLE_TAB_DATA        = "Data",
    STABLE_TAB_ADVANCED    = "Advanced",
    STABLE_TAB_TRASH       = "Trash warnings",
    STABLE_GENERAL_TITLE   = "General",
    STABLE_INTERFACE       = "Interface",
    STABLE_AUDIO_TITLE     = "Audio & countdown",
    STABLE_AUDIO_VOICE     = "Voice",
    STABLE_AUDIO_PULL      = "Pull countdown",
    STABLE_TRASH_TITLE     = "Trash warnings",
    STABLE_TRASH_DESC      = "Midnight-safe warning for enemy casts targeting you. TomoBoss never reads the restricted target boolean in Lua.",
    STABLE_TRASH_ENABLE    = "Targeted cast ring",
    STABLE_TRASH_SIZE      = "Targeted ring size",
    STABLE_TRASH_NOTE      = "Orange/red ring = the current enemy cast targets you. No predictive TrashCD or secret spell identification is used.",
    STABLE_DATA_TITLE      = "Data & learning",
    STABLE_DATA_DESC       = "Track and replace third-party timing data with timings regenerated from your own Learn pulls.",
    STABLE_DATA_THRESHOLD  = "Minimum Learn quality",
    STABLE_DATA_REFRESH    = "Refresh",
    STABLE_DATA_REPORT     = "Detailed report",
    STABLE_DATA_EXPORT     = "Export ready encounters",
    STABLE_DATA_CHAT       = "Print provenance",
    STABLE_DATA_HELP       = "Export does not rewrite addon files. It generates observed Lua blocks to review and integrate into Engine/Encounters.",
    STABLE_ADV_TITLE       = "Advanced",
    STABLE_ADV_BLIZZ       = "Blizzard timeline",
    STABLE_ADV_RINGS       = "Role rings",
    STABLE_ROLE_TITLE      = "Role / danger rings",
    STABLE_ABOUT_BODY      = "TomoBoss owns player-facing boss timer and voice decisions. Blizzard C_EncounterTimeline is the native runtime input. BigWigs/DBM are audit-only; EXBoss/WeakAura are reference-only.",
    STABLE_ABOUT_DATA      = "Timing provenance is tracked separately in the Data tab until every third-party encounter has been regenerated from Learn pulls.",
    STABLE_STATUS_CLEAN    = "Clean / Blizzard",
    STABLE_STATUS_THIRD    = "Third-party",
    STABLE_STATUS_READY    = "Ready to export",
    STABLE_STATUS_PULLS    = "With Learn pulls",
    QUALITY_LOW            = "Low",
    QUALITY_MEDIUM         = "Medium",
    QUALITY_GOOD           = "Good",
}

local FR = {
    STABLE_TAB_AUDIO       = "Audio",
    STABLE_TAB_DATA        = "Données",
    STABLE_TAB_ADVANCED    = "Avancé",
    STABLE_TAB_TRASH       = "Alertes de packs",
    STABLE_GENERAL_TITLE   = "Général",
    STABLE_INTERFACE       = "Interface",
    STABLE_AUDIO_TITLE     = "Audio & décompte",
    STABLE_AUDIO_VOICE     = "Voix",
    STABLE_AUDIO_PULL      = "Compte à rebours",
    STABLE_TRASH_TITLE     = "Alertes de packs",
    STABLE_TRASH_DESC      = "Alerte Midnight-safe pour les incantations ennemies qui vous ciblent. TomoBoss ne lit jamais le booléen de cible restreint en Lua.",
    STABLE_TRASH_ENABLE    = "Anneau quand un sort me cible",
    STABLE_TRASH_SIZE      = "Taille de l'anneau ciblé",
    STABLE_TRASH_NOTE      = "Anneau orange/rouge = l'incantation ennemie actuelle vous cible. Aucune prédiction TrashCD ni identification de spellID secret.",
    STABLE_DATA_TITLE      = "Données & apprentissage",
    STABLE_DATA_DESC       = "Suivez et remplacez les minutages tierces par des minutages régénérés depuis vos propres pulls Learn.",
    STABLE_DATA_THRESHOLD  = "Qualité Learn minimale",
    STABLE_DATA_REFRESH    = "Actualiser",
    STABLE_DATA_REPORT     = "Rapport détaillé",
    STABLE_DATA_EXPORT     = "Exporter les rencontres prêtes",
    STABLE_DATA_CHAT       = "Afficher la provenance",
    STABLE_DATA_HELP       = "L'export n'écrit pas les fichiers de l'addon. Il génère des blocs Lua observés à relire puis intégrer dans Engine/Encounters.",
    STABLE_ADV_TITLE       = "Avancé",
    STABLE_ADV_BLIZZ       = "Timeline Blizzard",
    STABLE_ADV_RINGS       = "Anneaux de rôle",
    STABLE_ROLE_TITLE      = "Anneaux de rôle / danger",
    STABLE_ABOUT_BODY      = "TomoBoss décide de tous les timers et voix visibles par le joueur. Blizzard C_EncounterTimeline reste l'entrée native runtime. BigWigs/DBM = audit uniquement ; EXBoss/WeakAura = référence uniquement.",
    STABLE_ABOUT_DATA      = "La provenance des minutages est suivie séparément dans l'onglet Données jusqu'à régénération de toutes les rencontres tierces depuis Learn.",
    STABLE_STATUS_CLEAN    = "Propres / Blizzard",
    STABLE_STATUS_THIRD    = "Tierces",
    STABLE_STATUS_READY    = "Prêtes à exporter",
    STABLE_STATUS_PULLS    = "Avec pulls Learn",
    QUALITY_LOW            = "Faible",
    QUALITY_MEDIUM         = "Moyen",
    QUALITY_GOOD           = "Bon",
}

if NS.Locales then
    for _, tbl in pairs(NS.Locales) do
        if type(tbl) == "table" then
            for k, v in pairs(EN) do
                if tbl[k] == nil then tbl[k] = v end
            end
        end
    end
    if NS.Locales.frFR then
        for k, v in pairs(FR) do NS.Locales.frFR[k] = v end
        -- Noms des onglets existants réorganisés.
        NS.Locales.frFR.TAB_BARS = "Alertes boss"
        NS.Locales.frFR.BARS_TITLE = "Alertes de boss"
        NS.Locales.frFR.TAB_TRASH = FR.STABLE_TAB_TRASH
    end
    if NS.Locales.enUS then
        NS.Locales.enUS.TAB_BARS = "Boss alerts"
        NS.Locales.enUS.BARS_TITLE = "Boss alerts"
        NS.Locales.enUS.TAB_TRASH = EN.STABLE_TAB_TRASH
    end
end

local L = setmetatable({}, { __index = function(_, k) return NS.L[k] or EN[k] or k end })

local function Layout(page, x, top, gap)
    local o = { page = page, x = x or 22, y = -(top or 18), gap = gap or 11 }
    function o:Add(ctrl, h, dx)
        ctrl:ClearAllPoints()
        ctrl:SetPoint("TOPLEFT", self.page, "TOPLEFT", self.x + (dx or 0), self.y)
        self.y = self.y - (h or (ctrl.GetHeight and ctrl:GetHeight()) or 24) - self.gap
        return ctrl
    end
    function o:Gap(px) self.y = self.y - (px or 8) end
    return o
end

local function section(page, text)
    return NS.Theme:SectionTitle(page, text)
end

local function ensureTrashWarningCfg()
    local p = NS.db and NS.db.profile
    if not p then return { enabled = true, size = 220 } end
    p.trashWarnings = p.trashWarnings or {}
    if p.trashWarnings.enabled == nil then p.trashWarnings.enabled = true end
    if p.trashWarnings.size == nil then
        p.trashWarnings.size = (NS.TargetedCastRing and NS.TargetedCastRing.diameter)
            or (p.ringProgress and p.ringProgress.size) or 220
    end

    local r = NS.TargetedCastRing
    if r then
        r.enabled = p.trashWarnings.enabled
        r.diameter = p.trashWarnings.size
    end
    return p.trashWarnings
end

local function restyleTargetRing(size)
    local r = NS.TargetedCastRing
    if not r then return end
    r.diameter = size
    for _, rec in pairs(r.active or {}) do
        if rec.overlay then rec.overlay:SetSize(size, size) end
    end
    for _, overlay in ipairs(r.pool or {}) do
        if overlay then overlay:SetSize(size, size) end
    end
end

ensureTrashWarningCfg()

--------------------------------------------------------------------------
-- Nouveau rail stable.
--------------------------------------------------------------------------
function Config:BuildTabs(rail)
    local defs = {
        { key = "general",    label = L.TAB_GENERAL,          build = "BuildStableGeneral" },
        { key = "bars",       label = L.TAB_BARS,             build = "BuildBars" },
        { key = "audio",      label = L.STABLE_TAB_AUDIO,     build = "BuildStableAudio" },
        { key = "interrupts", label = L.TAB_INTERRUPTS,       build = "BuildInterrupts" },
        { key = "trash",      label = L.STABLE_TAB_TRASH,     build = "BuildStableTrash" },
        { key = "custom",     label = L.TAB_CUSTOM,           build = "BuildCustom" },
        { key = "data",       label = L.STABLE_TAB_DATA,      build = "BuildStableData" },
        { key = "advanced",   label = L.STABLE_TAB_ADVANCED,  build = "BuildStableAdvanced" },
        { key = "about",      label = L.TAB_ABOUT,            build = "BuildStableAbout" },
    }

    local C = NS.Theme.colors
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

        local page = CreateFrame("Frame", nil, self.content)
        page:SetAllPoints(self.content)
        page:Hide()
        self.pages[d.key] = page
        self[d.build](self, page)
        self.tabs[d.key] = btn
    end

    self:Select("general")
end

--------------------------------------------------------------------------
-- Général : uniquement réglages globaux + actions d'interface.
--------------------------------------------------------------------------
function Config:BuildStableGeneral(page)
    local prof = NS.db.profile
    local lay = Layout(page)
    lay:Add(section(page, L.STABLE_GENERAL_TITLE), 22)

    local en = NS.Theme:CreateCheck(page, L.ENABLED)
    en:SetChecked(prof.enabled)
    en:SetCallback(function(v)
        prof.enabled = v
        if not v then
            if NS.Engine and NS.Engine.Timeline then NS.Engine.Timeline:Stop() end
            if NS.UI and NS.UI.TimerBars then NS.UI.TimerBars:Clear() end
        end
    end)
    lay:Add(en, 22)

    local sc = NS.Theme:CreateSlider(page, {
        label = L.GLOBAL_SCALE, min = 0.5, max = 2.0, step = 0.05,
        value = prof.scale, width = 330,
        fmt = function(v) return string.format("%.2f×", v) end,
    })
    sc:SetCallback(function(v) prof.scale = v; NS:ApplyScale() end)
    lay:Add(sc, 46)

    local mini = NS.Theme:CreateCheck(page, L.MINIMAP_SHOW)
    mini:SetChecked(not prof.minimap.hide)
    mini:SetCallback(function(v)
        prof.minimap.hide = not v
        if NS.Minimap then NS.Minimap:SetShown(v) end
    end)
    lay:Add(mini, 22)

    lay:Gap(12)
    lay:Add(section(page, L.STABLE_INTERFACE), 22)

    local row = CreateFrame("Frame", nil, page)
    row:SetSize(500, 30)

    local testBtn = NS.Theme:CreateButton(row, L.TEST_RUN, 150, 28)
    testBtn:SetPoint("LEFT", 0, 0)
    testBtn:SetScript("OnClick", function(self)
        if NS.Engine.Timeline.demo then
            NS.Engine.Timeline:StopDemo()
            self:SetText(L.TEST_RUN)
        else
            NS.Engine.Timeline:RunDemo(1999)
            self:SetText(L.TEST_STOP)
        end
    end)
    self._testBtn = testBtn

    local lockBtn = NS.Theme:CreateButton(row, L.UNLOCK, 150, 28)
    lockBtn:SetPoint("LEFT", testBtn, "RIGHT", 8, 0)
    lockBtn:SetScript("OnClick", function(self)
        local editing = NS.UI.Mover:Toggle()
        self:SetText(editing and L.LOCK or L.UNLOCK)
        NS:Print(editing and NS.L.MSG_UNLOCKED or NS.L.MSG_LOCKED)
    end)
    self._lockBtn = lockBtn

    local resetBtn = NS.Theme:CreateButton(row, L.RESET_POS, 150, 28)
    resetBtn:SetPoint("LEFT", lockBtn, "RIGHT", 8, 0)
    resetBtn:SetScript("OnClick", function()
        wipe(NS.db.profile.positions)
        NS.UI.Mover:ApplyAll()
        NS:Print(NS.L.MSG_RESET)
    end)

    lay:Add(row, 32)

    local hint = page:CreateFontString(nil, "OVERLAY")
    NS.Theme:Font(hint, 11, "muted")
    hint:SetWidth(500); hint:SetJustifyH("LEFT")
    hint:SetText(L.UNLOCK_DESC)
    lay:Add(hint, 30)
end

--------------------------------------------------------------------------
-- Audio : volume global + sous-pages Voix / Pull.
--------------------------------------------------------------------------
function Config:BuildStableAudio(page)
    local prof = NS.db.profile
    local title = section(page, L.STABLE_AUDIO_TITLE)
    title:SetPoint("TOPLEFT", 22, -18)

    local boost = NS.Theme:CreateSlider(page, {
        label = L.VOICE_BOOST, min = 100, max = 300, step = 25,
        value = prof.voice.boost or 100, width = 330,
        fmt = function(v) return string.format("%d %%", v) end,
    })
    boost:SetPoint("TOPLEFT", 22, -54)
    boost:SetCallback(function(v)
        prof.voice.boost = math.floor(v + 0.5)
        if NS.EventBridge then NS.EventBridge:Refresh("volume") end
    end)

    local voiceBtn = NS.Theme:CreateButton(page, L.STABLE_AUDIO_VOICE, 150, 26)
    voiceBtn:SetPoint("TOPLEFT", 22, -112)
    local pullBtn = NS.Theme:CreateButton(page, L.STABLE_AUDIO_PULL, 170, 26)
    pullBtn:SetPoint("LEFT", voiceBtn, "RIGHT", 8, 0)

    local voiceView = CreateFrame("Frame", nil, page)
    voiceView:SetPoint("TOPLEFT", 0, -150); voiceView:SetPoint("BOTTOMRIGHT", 0, 0)
    local pullView = CreateFrame("Frame", nil, page)
    pullView:SetAllPoints(voiceView)

    Original.Voice(self, voiceView)
    Original.Countdown(self, pullView)

    local function show(which)
        voiceView:SetShown(which == "voice")
        pullView:SetShown(which == "pull")
        if voiceBtn.text then voiceBtn.text:SetTextColor(NS.Theme:Color(which == "voice" and "mint" or "text")) end
        if pullBtn.text then pullBtn.text:SetTextColor(NS.Theme:Color(which == "pull" and "mint" or "text")) end
    end

    voiceBtn:SetScript("OnClick", function() show("voice") end)
    pullBtn:SetScript("OnClick", function() show("pull") end)
    show("voice")
end

--------------------------------------------------------------------------
-- Trash stable : uniquement la fonctionnalité prouvée sous Midnight.
--------------------------------------------------------------------------
function Config:BuildStableTrash(page)
    local cfg = ensureTrashWarningCfg()
    local lay = Layout(page)
    lay:Add(section(page, L.STABLE_TRASH_TITLE), 22)

    local desc = page:CreateFontString(nil, "OVERLAY")
    NS.Theme:Font(desc, 11, "muted")
    desc:SetWidth(500); desc:SetJustifyH("LEFT"); desc:SetWordWrap(true)
    desc:SetText(L.STABLE_TRASH_DESC)
    lay:Add(desc, 44)

    local en = NS.Theme:CreateCheck(page, L.STABLE_TRASH_ENABLE)
    en:SetChecked(cfg.enabled)
    en:SetCallback(function(v)
        cfg.enabled = v
        local r = NS.TargetedCastRing
        if r then
            r.enabled = v
            if not v and r.ReleaseAll then r:ReleaseAll() end
        end
    end)
    lay:Add(en, 24)

    local size = NS.Theme:CreateSlider(page, {
        label = L.STABLE_TRASH_SIZE, min = 100, max = 360, step = 10,
        value = cfg.size, width = 330,
        fmt = function(v) return string.format("%d px", v) end,
    })
    size:SetCallback(function(v)
        cfg.size = math.floor(v + 0.5)
        restyleTargetRing(cfg.size)
    end)
    lay:Add(size, 46)

    local note = page:CreateFontString(nil, "OVERLAY")
    NS.Theme:Font(note, 11, "muted")
    note:SetWidth(500); note:SetJustifyH("LEFT"); note:SetWordWrap(true)
    note:SetText(L.STABLE_TRASH_NOTE)
    lay:Add(note, 54)
end

--------------------------------------------------------------------------
-- Données : provenance + export groupé des rencontres Learn prêtes.
--------------------------------------------------------------------------
function Config:BuildStableData(page)
    local M = NS.Learn and NS.Learn.Migration
    local threshold = "moyen"
    local lay = Layout(page)
    lay:Add(section(page, L.STABLE_DATA_TITLE), 22)

    local intro = page:CreateFontString(nil, "OVERLAY")
    NS.Theme:Font(intro, 11, "muted")
    intro:SetWidth(500); intro:SetJustifyH("LEFT"); intro:SetWordWrap(true)
    intro:SetText(L.STABLE_DATA_DESC)
    lay:Add(intro, 42)

    local qLabel = page:CreateFontString(nil, "OVERLAY")
    NS.Theme:Font(qLabel, 12, "muted")
    qLabel:SetText(L.STABLE_DATA_THRESHOLD)
    lay:Add(qLabel, 16)

    local qdd = NS.Theme:CreateDropdown(page, {
        width = 220,
        items = {
            { value = "faible", text = L.QUALITY_LOW },
            { value = "moyen", text = L.QUALITY_MEDIUM },
            { value = "bon", text = L.QUALITY_GOOD },
        },
        onSelect = function(v)
            threshold = v
            if Config._stableDataRefresh then Config._stableDataRefresh() end
        end,
    })
    qdd:SetValue("moyen", L.QUALITY_MEDIUM)
    lay:Add(qdd, 32)

    local card = NS.Theme:CreateCard(page, {
        bg = NS.Theme.colors.bg1,
        border = NS.Theme.colors.line,
        shadowAlpha = 0.12,
    })
    card:SetSize(500, 118)
    lay:Add(card, 118)

    local summary = card:CreateFontString(nil, "OVERLAY")
    NS.Theme:Font(summary, 12, "text")
    summary:SetPoint("TOPLEFT", 14, -12)
    summary:SetPoint("BOTTOMRIGHT", -14, 12)
    summary:SetJustifyH("LEFT")
    summary:SetJustifyV("TOP")

    local row = CreateFrame("Frame", nil, page)
    row:SetSize(510, 28)
    local refresh = NS.Theme:CreateButton(row, L.STABLE_DATA_REFRESH, 110, 26)
    refresh:SetPoint("LEFT", 0, 0)
    local report = NS.Theme:CreateButton(row, L.STABLE_DATA_REPORT, 130, 26)
    report:SetPoint("LEFT", refresh, "RIGHT", 8, 0)
    local chat = NS.Theme:CreateButton(row, L.STABLE_DATA_CHAT, 140, 26)
    chat:SetPoint("LEFT", report, "RIGHT", 8, 0)
    lay:Add(row, 30)

    local export = NS.Theme:CreateButton(page, L.STABLE_DATA_EXPORT, 250, 28)
    lay:Add(export, 32)

    local help = page:CreateFontString(nil, "OVERLAY")
    NS.Theme:Font(help, 11, "muted")
    help:SetWidth(500); help:SetJustifyH("LEFT"); help:SetWordWrap(true)
    help:SetText(L.STABLE_DATA_HELP)
    lay:Add(help, 52)

    local function update()
        if not M then
            summary:SetText("|cffe06c75Migration module unavailable.|r")
            return
        end
        local s = M:Scan(threshold)
        summary:SetText(string.format(
            "|cff33e6a6%s|r  %d / %d\n%s  %d\n%s  %d\n%s  %d",
            L.STABLE_STATUS_CLEAN, s.clean or 0, s.total or 0,
            L.STABLE_STATUS_THIRD, s.thirdParty or 0,
            L.STABLE_STATUS_PULLS, s.withPulls or 0,
            L.STABLE_STATUS_READY, s.ready or 0
        ))
    end

    refresh:SetScript("OnClick", update)
    report:SetScript("OnClick", function()
        if M then M:ShowReport(threshold) end
    end)
    chat:SetScript("OnClick", function()
        if NS.Learn and NS.Learn.Provenance then NS.Learn.Provenance:Print(true) end
    end)
    export:SetScript("OnClick", function()
        if M then M:ShowReadyExport(threshold) end
    end)

    self._stableDataRefresh = update
    update()
end

--------------------------------------------------------------------------
-- Avancé : Blizzard + anneaux de rôle.
--------------------------------------------------------------------------
function Config:BuildStableAdvanced(page)
    local title = section(page, L.STABLE_ADV_TITLE)
    title:SetPoint("TOPLEFT", 22, -18)

    local blizzBtn = NS.Theme:CreateButton(page, L.STABLE_ADV_BLIZZ, 170, 26)
    blizzBtn:SetPoint("TOPLEFT", 22, -52)
    local ringsBtn = NS.Theme:CreateButton(page, L.STABLE_ADV_RINGS, 160, 26)
    ringsBtn:SetPoint("LEFT", blizzBtn, "RIGHT", 8, 0)

    local blizzView = CreateFrame("Frame", nil, page)
    blizzView:SetPoint("TOPLEFT", 0, -88); blizzView:SetPoint("BOTTOMRIGHT", 0, 0)
    local ringsView = CreateFrame("Frame", nil, page)
    ringsView:SetAllPoints(blizzView)

    Original.Blizz(self, blizzView)

    do
        local prof = NS.db.profile
        local lay = Layout(ringsView)
        lay:Add(section(ringsView, L.STABLE_ROLE_TITLE), 22)

        local ringChk = NS.Theme:CreateCheck(ringsView, L.RING_AUTOROLE)
        ringChk:SetChecked(prof.rings.autoRole)
        ringChk:SetCallback(function(v) prof.rings.autoRole = v end)
        lay:Add(ringChk, 22)

        local ringDesc = ringsView:CreateFontString(nil, "OVERLAY")
        NS.Theme:Font(ringDesc, 11, "muted")
        ringDesc:SetWidth(480); ringDesc:SetJustifyH("LEFT")
        ringDesc:SetText(L.RING_AUTOROLE_DESC)
        lay:Add(ringDesc, 36)

        local ringSize = NS.Theme:CreateSlider(ringsView, {
            label = L.RING_SIZE, min = 28, max = 72, step = 2,
            value = prof.rings.size, width = 330,
            fmt = function(v) return string.format("%d px", v) end,
        })
        ringSize:SetCallback(function(v)
            prof.rings.size = math.floor(v + 0.5)
            if NS.UI.Rings then NS.UI.Rings:Restyle() end
        end)
        lay:Add(ringSize, 46)
    end

    local function show(which)
        blizzView:SetShown(which == "blizz")
        ringsView:SetShown(which == "rings")
        if blizzBtn.text then blizzBtn.text:SetTextColor(NS.Theme:Color(which == "blizz" and "mint" or "text")) end
        if ringsBtn.text then ringsBtn.text:SetTextColor(NS.Theme:Color(which == "rings" and "mint" or "text")) end
    end
    blizzBtn:SetScript("OnClick", function() show("blizz") end)
    ringsBtn:SetScript("OnClick", function() show("rings") end)
    show("blizz")
end

--------------------------------------------------------------------------
-- À propos stable : plus de formulation ambiguë sur l'autorité des sources.
--------------------------------------------------------------------------
function Config:BuildStableAbout(page)
    local lay = Layout(page)
    lay:Add(section(page, L.TAB_ABOUT), 22)

    local ver = page:CreateFontString(nil, "OVERLAY")
    NS.Theme:Font(ver, 13, "text")
    ver:SetText(L.ABOUT_VERSION .. " : |cff33e6a6" .. NS.version .. "|r")
    lay:Add(ver, 20)

    local body = page:CreateFontString(nil, "OVERLAY")
    NS.Theme:Font(body, 12, "muted")
    body:SetWidth(500); body:SetJustifyH("LEFT"); body:SetWordWrap(true)
    body:SetText(L.STABLE_ABOUT_BODY)
    lay:Add(body, 70)

    local data = page:CreateFontString(nil, "OVERLAY")
    NS.Theme:Font(data, 12, "muted")
    data:SetWidth(500); data:SetJustifyH("LEFT"); data:SetWordWrap(true)
    data:SetText(L.STABLE_ABOUT_DATA)
    lay:Add(data, 64)

    lay:Gap(6)
    local cmdTitle = page:CreateFontString(nil, "OVERLAY")
    NS.Theme:Font(cmdTitle, 13, "mint")
    cmdTitle:SetText(L.ABOUT_COMMANDS)
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

-- Rafraîchit automatiquement la page Données quand elle est sélectionnée.
local originalSelect = Config.Select
function Config:Select(key)
    originalSelect(self, key)
    if key == "data" and self._stableDataRefresh then
        self._stableDataRefresh()
    end
end
