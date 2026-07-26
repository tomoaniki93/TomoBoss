---@diagnostic disable: undefined-global
-- TomoBoss — Enregistreur de timeline.
--
-- `/tmb debug` n'affiche que des print volatils. Ici on PERSISTE la capture dans
-- une SavedVariable, horodatée depuis le pull, et surtout on ANNOTE chaque
-- ENCOUNTER_TIMELINE_EVENT_ADDED avec :
--   - la durée brute vue par le serveur,
--   - l'événement identifié par le moteur (ou <aucun>),
--   - COMMENT il a été identifié (sync / round-robin / règle / durée),
--   - srv:Y|N — le jeu joue-t-il DÉJÀ le son via l'EventBridge ?
-- Ce dernier indicateur est ce qui rend les doublons d'annonce visibles en une
-- lecture : srv:Y accompagné d'une annonce Lua = doublon.
--
-- Sous Midnight, certains champs de eventInfo arrivent en secretvalue. Les
-- formater ne lève pas tout de suite : on obtient une chaîne TAINTÉE qui
-- n'explose qu'au table.concat de l'export. On neutralise donc à l'écriture
-- (NS:SafeNumber / masque) et à nouveau à la sérialisation.

local NS = select(2, ...)
local R = {}
NS.Recorder = R

local MAX_CAPTURES = 20     -- captures conservées
local MAX_LINES    = 3000   -- garde-fou mémoire par capture
local MIN_LENGTH   = 5      -- captures plus courtes = jetées

local _cur = nil            -- capture en cours

--------------------------------------------------------------------------
-- Stockage.
--------------------------------------------------------------------------
local function store()
    if type(_G.TomoBossRecorderDB) ~= "table" then _G.TomoBossRecorderDB = {} end
    return _G.TomoBossRecorderDB
end

local function cfg()
    local d = NS.db and NS.db.profile
    if not d then return {} end
    d.recorder = d.recorder or {}
    return d.recorder
end

function R:IsRecording() return cfg().enabled == true and _cur ~= nil end
function R:IsArmed()     return cfg().enabled == true end

--------------------------------------------------------------------------
-- Écriture sûre.
--------------------------------------------------------------------------
local function num(v, fmt)
    local n = NS:SafeNumber(v)
    if n == nil then return "<secret>" end
    local ok, s = pcall(string.format, fmt or "%.2f", n)
    return ok and s or "<err>"
end

local function field(v)
    if v == nil then return "?" end
    if NS:IsSecret(v) then return "<secret>" end
    return tostring(v)
end

local function push(fmt, ...)
    if not _cur then return end
    local lines = _cur.lines
    if #lines >= MAX_LINES then
        if not _cur.truncated then
            _cur.truncated = true
            lines[#lines + 1] = "... capture tronquée (MAX_LINES atteint) ..."
        end
        return
    end
    local ok, line = pcall(string.format, fmt, ...)
    lines[#lines + 1] = ok and line or "<ligne illisible>"
end

local function stamp()
    if not _cur then return 0 end
    return GetTime() - (_cur.pullTime or GetTime())
end

--------------------------------------------------------------------------
-- Capture.
--------------------------------------------------------------------------
function R:Begin(label)
    local name, itype, diffName = GetInstanceInfo()
    _cur = {
        lines = {},
        pullTime = GetTime(),
        date = date("%Y-%m-%d %H:%M:%S"),
        zone = field(name),
        itype = field(itype),
        diff = field(diffName),
        version = NS.version,
        label = label or "?",
    }
    push("[%6.2f]  DÉBUT  %s", 0, field(label))
end

function R:End(reason)
    if not _cur then return end
    local len = GetTime() - (_cur.pullTime or GetTime())
    if len < MIN_LENGTH then _cur = nil; return end
    _cur.length = len
    push("[%6.2f]  FIN  %s", stamp(), field(reason))
    local s = store()
    table.insert(s, 1, _cur)
    while #s > MAX_CAPTURES do table.remove(s) end
    NS:Debug("Recorder : capture close (", string.format("%.0f", len), "s,", #_cur.lines, "lignes)")
    _cur = nil
end

-- Appelé par BlizzTimeline sur chaque ADDED, après identification.
function R:OnAdded(id, matchDur, fireDur, ev, how, info)
    if not _cur then return end
    local tail
    if ev then
        local srv = "-"
        if NS.EventBridge and NS.EventBridge.WillPlaySound then
            srv = NS.EventBridge:WillPlaySound(ev) and "Y" or "N"
        end
        tail = string.format("  » %s  sort:%s eventID:%s sév:%s voix:%s srv:%s",
            field(how), field(ev.spellID), field(ev.eventID),
            field(ev.severity), field(ev.voice), srv)
    else
        tail = string.format("  » <aucun>  (nom serveur : %s)",
            info and field(info.spellName) or "?")
    end
    push("[%6.2f]  ADDED    id:%-6s match:%-8s réel:%-8s%s",
        stamp(), field(id), num(matchDur, "%.3f"), num(fireDur, "%.3f"), tail)
end

function R:OnRemoved(id)
    if not _cur then return end
    push("[%6.2f]  REMOVED  id:%s", stamp(), field(id))
end

function R:Note(...)
    if not _cur then return end
    local parts = {}
    for i = 1, select("#", ...) do parts[i] = field((select(i, ...))) end
    push("[%6.2f]  NOTE     %s", stamp(), table.concat(parts, " "))
end

--------------------------------------------------------------------------
-- Sérialisation.
--------------------------------------------------------------------------
function R:Serialize(cap)
    if type(cap) ~= "table" then return "" end
    local out = {
        "== TomoBoss — capture de timeline ==",
        ("Zone      : %s (%s, %s)"):format(field(cap.zone), field(cap.itype), field(cap.diff)),
        ("Date      : %s"):format(field(cap.date)),
        ("Durée     : %s s    Déclencheur : %s"):format(num(cap.length, "%.1f"), field(cap.label)),
        ("Version   : %s      Lignes : %s"):format(field(cap.version), tostring(#(cap.lines or {}))),
        string.rep("-", 74),
    }
    -- Une ligne ayant contenu un secret n'est pas persistée par le client :
    -- ipairs s'arrêterait au premier trou, on balaie donc par index.
    local maxIdx, missing = 0, 0
    for k in pairs(cap.lines or {}) do
        if type(k) == "number" and k > maxIdx then maxIdx = k end
    end
    local function flush()
        if missing > 0 then
            out[#out + 1] = ("... %d ligne(s) perdue(s) (valeurs masquées non persistées) ...")
                :format(missing)
            missing = 0
        end
    end
    for i = 1, maxIdx do
        local l = cap.lines[i]
        if l == nil or NS:IsSecret(l) then missing = missing + 1
        else flush(); out[#out + 1] = tostring(l) end
    end
    flush()
    return table.concat(out, "\n")
end

--------------------------------------------------------------------------
-- Fenêtre de copie.
--------------------------------------------------------------------------
local exportFrame
local function ensureFrame()
    if exportFrame then return exportFrame end
    local f = CreateFrame("Frame", "TomoBossRecorderExport", UIParent, "BasicFrameTemplateWithInset")
    f:SetSize(760, 520)
    f:SetPoint("CENTER")
    f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetFrameStrata("DIALOG")
    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.title:SetPoint("TOP", 0, -6)
    f.title:SetText("TomoBoss — capture (Ctrl+A puis Ctrl+C)")
    local sf = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT", 12, -32)
    sf:SetPoint("BOTTOMRIGHT", -32, 12)
    local eb = CreateFrame("EditBox", nil, sf)
    eb:SetMultiLine(true); eb:SetFontObject(ChatFontNormal)
    eb:SetWidth(700); eb:SetAutoFocus(false)
    eb:SetScript("OnEscapePressed", function() f:Hide() end)
    sf:SetScrollChild(eb)
    f.edit = eb
    f:Hide()
    exportFrame = f
    return f
end

function R:OpenExport(text)
    local f = ensureFrame()
    f.edit:SetText(text or "")
    f.edit:HighlightText()
    f:Show()
    f.edit:SetFocus()
end

--------------------------------------------------------------------------
-- Commandes : /tmb rec [on|off|list|show N|export N|clear]
--------------------------------------------------------------------------
function R:Count() return #store() end

function R:Handle(arg)
    arg = (arg or ""):lower():gsub("^%s+", "")
    local sub, n = arg:match("^(%a*)%s*(%d*)$")
    n = tonumber(n)

    if sub == "" or sub == "status" then
        NS:Print("Enregistreur — ", self:IsArmed() and "|cff33e6a6armé|r" or "|cffff6b6bcoupé|r",
            " | capture en cours : ", _cur and "oui" or "non",
            " | captures gardées : ", self:Count())
        NS:Print("  /tmb rec on|off  ·  list  ·  show [n]  ·  export [n]  ·  clear")

    elseif sub == "on" then
        cfg().enabled = true
        NS:Print("Enregistreur |cff33e6a6armé|r — il démarre au premier événement de timeline.")

    elseif sub == "off" then
        cfg().enabled = false
        if _cur then self:End("arrêt manuel") end
        NS:Print("Enregistreur |cffff6b6bcoupé|r.")

    elseif sub == "list" then
        local s = store()
        if #s == 0 then NS:Print("Aucune capture.") return end
        for i, c in ipairs(s) do
            NS:Print(("  %d. %s — %s (%s s, %d lignes)"):format(
                i, field(c.date), field(c.zone), num(c.length, "%.0f"), #(c.lines or {})))
        end

    elseif sub == "show" then
        local c = store()[n or 1]
        if not c then NS:Print("Capture introuvable.") return end
        for line in self:Serialize(c):gmatch("[^\n]+") do print(line) end

    elseif sub == "export" then
        local c = store()[n or 1]
        if not c then NS:Print("Capture introuvable.") return end
        self:OpenExport(self:Serialize(c))

    elseif sub == "clear" then
        _G.TomoBossRecorderDB = {}
        _cur = nil
        NS:Print("Captures effacées.")

    else
        NS:Print("Sous-commande inconnue. /tmb rec status|on|off|list|show|export|clear")
    end
end

--------------------------------------------------------------------------
-- Init : la capture suit la vie du moteur timeline.
--------------------------------------------------------------------------
function R:Init()
    NS.Bus:On("TMB_TIMELINE_PULL", function(label) if self:IsArmed() then self:Begin(label) end end)
    NS.Bus:On("TMB_TIMELINE_RESET", function(reason) self:End(reason) end)
end
