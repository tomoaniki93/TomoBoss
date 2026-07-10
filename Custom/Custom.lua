---@diagnostic disable: undefined-global
-- TomoBoss — Entrées personnalisées (boss / trash) créées par l'utilisateur.
-- Sauvegardées dans la base (profile.custom.entries), enregistrées dans le moteur
-- au login, et partageables via Share (import/export).

local NS = select(2, ...)
local Custom = {}
NS.Custom = Custom

Custom.trashIndex = {}   -- [mapID][npcID] = { { spellID, voice, display }, ... }

local function store()
    NS.db.profile.custom = NS.db.profile.custom or {}
    NS.db.profile.custom.entries = NS.db.profile.custom.entries or {}
    return NS.db.profile.custom.entries
end

local function SpellName(spellID)
    if spellID and C_Spell and C_Spell.GetSpellInfo then
        local ok, info = pcall(C_Spell.GetSpellInfo, spellID)
        if ok and type(info) == "table" and info.name and info.name ~= "" then return info.name end
    end
    return nil
end

--------------------------------------------------------------------------
-- Identifiants uniques.
--------------------------------------------------------------------------
function Custom:NewID()
    local entries = store()
    local id
    repeat
        id = string.format("e%d%03d", math.floor(GetTime() * 1000) % 100000000, math.random(0, 999))
        local dup = false
        for _, e in ipairs(entries) do if e.id == id then dup = true break end end
    until not dup
    return id
end

--------------------------------------------------------------------------
-- Enregistrement d'une entrée dans les moteurs.
--------------------------------------------------------------------------
function Custom:RegisterEntry(entry)
    if type(entry) ~= "table" or not entry.spellID then return end
    local disp = entry.display or { bar = true, sound = true }

    if entry.kind == "boss" and entry.encounterID then
        local ev = {
            spellID      = entry.spellID,
            voice        = entry.voice,
            castType     = entry.castType or "cast",
            castDuration = entry.castDuration,
            firstSeenSec = entry.firstSeenSec or 5,
            cdSeriesSec  = entry.cdSeriesSec or { 30 },
            severity     = entry.severity or 1,
            display      = disp,
            name         = entry.name,
            __custom     = true,
        }
        NS.Engine:MergeEncounter(entry.encounterID, {
            name = entry.name or ("Boss " .. entry.encounterID),
            dungeon = entry.zone,
            events = { ev },
        })

    elseif entry.kind == "trash" and entry.mapID and entry.npcID then
        local isChannel = (entry.castType == "channel")
        NS.TrashCD:RegisterDungeon(entry.mapID, {
            mobs = {
                [entry.npcID] = {
                    spells = {
                        [entry.spellID] = {
                            nameEN      = entry.name,
                            castTime    = (not isChannel) and (entry.castDuration or 0) or 0,
                            channelTime = isChannel and (entry.castDuration or 0) or nil,
                            first       = entry.firstSeenSec,
                            cd          = entry.cdSeriesSec,
                        },
                    },
                },
            },
        })
        -- index pour voix / anneau côté trash
        self.trashIndex[entry.mapID] = self.trashIndex[entry.mapID] or {}
        local byNpc = self.trashIndex[entry.mapID]
        byNpc[entry.npcID] = byNpc[entry.npcID] or {}
        table.insert(byNpc[entry.npcID], { spellID = entry.spellID, voice = entry.voice, display = disp })
    end
end

--------------------------------------------------------------------------
-- Init : enregistre toutes les entrées sauvegardées.
--------------------------------------------------------------------------
function Custom:Init()
    wipe(self.trashIndex)
    for _, entry in ipairs(store()) do
        self:RegisterEntry(entry)
    end
    NS:Debug("Entrées personnalisées chargées :", #store())
end

--------------------------------------------------------------------------
-- CRUD.
--------------------------------------------------------------------------
function Custom:GetAll() return store() end

function Custom:Add(entry)
    entry.id = entry.id or self:NewID()
    table.insert(store(), entry)
    self:RegisterEntry(entry) -- prend effet immédiatement (ajout)
    return entry
end

function Custom:Remove(id)
    local entries = store()
    for i = #entries, 1, -1 do
        if entries[i].id == id then table.remove(entries, i) end
    end
    -- le désenregistrement moteur propre nécessite un /reload
end

function Custom:Clear()
    wipe(store())
end

--------------------------------------------------------------------------
-- Extras trash : retrouve l'entrée custom correspondant à une incantation.
-- Match par spellID lisible, sinon par nom résolu (robuste sous Midnight).
--------------------------------------------------------------------------
function Custom:TrashExtras(mapID, npcID, liveName, liveSid)
    local byMap = self.trashIndex[mapID]
    if not byMap then return nil end
    local list = byMap[npcID]
    if not list then return nil end
    for _, c in ipairs(list) do
        if liveSid and c.spellID == liveSid then
            return c
        elseif liveName and SpellName(c.spellID) == liveName then
            return c
        end
    end
    return nil
end

--------------------------------------------------------------------------
-- Export / Import.
--------------------------------------------------------------------------
function Custom:ExportString()
    local entries = store()
    if #entries == 0 then return nil, "aucune entrée à exporter" end
    -- copie propre (sans champs internes)
    local out = { version = 1, entries = {} }
    for _, e in ipairs(entries) do
        out.entries[#out.entries + 1] = {
            kind = e.kind, zone = e.zone, name = e.name,
            encounterID = e.encounterID, mapID = e.mapID, npcID = e.npcID,
            spellID = e.spellID, castType = e.castType, castDuration = e.castDuration,
            firstSeenSec = e.firstSeenSec, cdSeriesSec = e.cdSeriesSec, severity = e.severity,
            voice = e.voice, display = e.display,
        }
    end
    return NS.Share:Export(out)
end

-- mode "append" (par défaut) ou "replace"
function Custom:ApplyImport(str, mode)
    local data, err = NS.Share:Import(str)
    if not data then return false, err end
    if type(data.entries) ~= "table" then return false, "format inattendu" end

    if mode == "replace" then self:Clear() end

    local n = 0
    for _, e in ipairs(data.entries) do
        if type(e) == "table" and e.spellID and (e.encounterID or (e.mapID and e.npcID)) then
            e.id = self:NewID()
            -- normalise le display
            if type(e.display) ~= "table" then e.display = { bar = true, sound = true } end
            table.insert(store(), e)
            self:RegisterEntry(e)
            n = n + 1
        end
    end
    return true, n
end
