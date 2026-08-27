---@diagnostic disable: undefined-global
-- TomoBoss — Modèle canonique des minuteurs affichables.
--
-- Cette couche ne crée AUCUNE frame et n'utilise AUCUN OnUpdate. Elle conserve
-- seulement l'état courant des événements afin que plusieurs renderers (barres,
-- timeline, hybride) puissent consommer exactement les mêmes données.

local NS = select(2, ...)
NS.UI = NS.UI or {}

local Model = {
    entries = {},
    revision = 0,
}
NS.UI.TimerModel = Model

local function copyColor(c)
    if type(c) ~= "table" then return c end
    return { c[1], c[2], c[3], c[4] }
end

local function inferSource(key, meta)
    if type(meta) == "table" and meta.source then return meta.source end
    local s = tostring(key or "")
    if s:sub(1, 3) == "bt:" then return "blizzard" end
    if s:sub(1, 7) == "custom:" then return "custom" end
    return "tomoboss"
end

function Model:Normalize(key, data, meta, previous)
    if key == nil or type(data) ~= "table" then return nil end

    local entry = previous or {}
    local m = type(meta) == "table" and meta or nil
    entry.key = key
    entry.source = inferSource(key, m)
    entry.name = data.name or entry.name or "?"
    entry.icon = data.icon or entry.icon or 134400
    entry.duration = math.max(0.1, data.duration or entry.duration or 1)
    entry.endTime = data.endTime or entry.endTime or (GetTime() + entry.duration)
    entry.severity = data.severity
    if entry.severity == nil then entry.severity = 1 end
    entry.role = data.role or (m and m.role) or entry.role
    entry.spellID = data.spellID or (m and m.spellID) or entry.spellID
    entry.eventID = data.eventID or (m and m.eventID) or entry.eventID
    entry.showTime = data.showTime ~= false
    entry.ignoreWindow = data.ignoreWindow and true or false
    entry.fillAlpha = data.fillAlpha
    entry.color = copyColor(data.color)

    -- Données complémentaires libres pour les futurs renderers, sans faire
    -- dépendre le modèle d'une implémentation visuelle particulière.
    entry.meta = m or entry.meta

    self.revision = self.revision + 1
    entry.revision = self.revision
    return entry
end

function Model:Upsert(key, data, meta)
    local entry = self:Normalize(key, data, meta, self.entries[key])
    if not entry then return nil end
    self.entries[key] = entry
    return entry
end

function Model:Remove(key)
    local entry = self.entries[key]
    self.entries[key] = nil
    if entry then
        self.revision = self.revision + 1
    end
    return entry
end

function Model:Clear()
    wipe(self.entries)
    self.revision = self.revision + 1
end

function Model:Get(key)
    return self.entries[key]
end

function Model:Has(key)
    return self.entries[key] ~= nil
end

function Model:Count()
    local n = 0
    for _ in pairs(self.entries) do n = n + 1 end
    return n
end

function Model:Each(fn)
    if type(fn) ~= "function" then return end
    for key, entry in pairs(self.entries) do
        fn(entry, key)
    end
end

-- Vue ordonnée utile à TomoTimeline : aucune allocation permanente, uniquement
-- à la demande du renderer qui en a besoin.
function Model:GetOrdered(now)
    now = now or GetTime()
    local out = {}
    for _, entry in pairs(self.entries) do
        if (entry.endTime or now) >= now then
            out[#out + 1] = entry
        end
    end
    table.sort(out, function(a, b)
        local ae, be = a.endTime or 0, b.endTime or 0
        if ae == be then return tostring(a.key) < tostring(b.key) end
        return ae < be
    end)
    return out
end

-- Convertit l'entrée canonique vers le format historique attendu par BarGroup.
-- Le futur renderer Timeline pourra lire directement l'entrée canonique.
function Model:ToBarData(entry)
    if not entry then return nil end
    return {
        name = entry.name,
        icon = entry.icon,
        duration = entry.duration,
        endTime = entry.endTime,
        severity = entry.severity,
        role = entry.role,
        spellID = entry.spellID,
        eventID = entry.eventID,
        showTime = entry.showTime,
        ignoreWindow = entry.ignoreWindow,
        fillAlpha = entry.fillAlpha,
        color = copyColor(entry.color),
    }
end
