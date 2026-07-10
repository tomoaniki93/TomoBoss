---@diagnostic disable: undefined-global
-- TomoBoss — Enregistrement des médias (textures de barre, audio français) dans LibSharedMedia.

local NS = select(2, ...)
local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
NS.LSM = LSM

local VOICE_BASE = "Interface\\AddOns\\TomoBoss\\Media\\Voice\\"
local SOUND_PREFIX = "[TomoBoss]"  -- préfixe des clés vocales dans LSM

NS.SOUND_PREFIX = SOUND_PREFIX

if not LSM then
    NS:Print("|cffff6b6bLibSharedMedia-3.0 introuvable — la voix sera indisponible.|r")
    return
end

-- Texture de barre plate (menthe) — la teinte est appliquée à l'exécution.
LSM:Register("statusbar", "TomoBoss Menthe", "Interface\\Buttons\\WHITE8X8")

-- Enregistre chaque fichier audio du pack français sous une clé stable.
local n = 0
for id, entry in pairs(NS.Voice and NS.Voice.Catalog or {}) do
    local key = SOUND_PREFIX .. id
    LSM:Register("sound", key, VOICE_BASE .. entry.file)
    n = n + 1
end
NS:Debug("Médias enregistrés :", n, "annonces vocales.")
