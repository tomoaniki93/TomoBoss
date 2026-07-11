---@diagnostic disable: undefined-global
-- TomoBoss — Enregistrement des médias (texture de barre + packs vocaux) dans LibSharedMedia.

local NS = select(2, ...)
local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
NS.LSM = LSM

local VOICE_ROOT = "Interface\\AddOns\\TomoBoss\\Media\\Voice\\"
local SOUND_PREFIX = "[TomoBoss]" -- préfixe des clés vocales dans LSM
NS.SOUND_PREFIX = SOUND_PREFIX

-- Packs de langue livrés avec l'addon.
-- Pour AJOUTER une langue :
--   1) déposez les .ogg (mêmes noms de fichiers que le pack français) dans
--      Media\Voice\<locale>\   (ex. Media\Voice\enUS\ , Media\Voice\deDE\)
--   2) dé-commentez / ajoutez la ligne correspondante ci-dessous.
NS.VOICE_PACKS = {
    { value = "frFR", text = "Français — VoixFrancaise02 (Melune)" },
    { value = "enUS", text = "English — TTS (Pico)" },
    -- { value = "deDE", text = "Deutsch — <Autor>" },
}
NS.VOICE_DEFAULT_PACK = "frFR"

-- Clé LSM d'une annonce pour un pack de langue donné.
function NS.VoiceKey(lang, id) return SOUND_PREFIX .. lang .. ":" .. id end

-- Pack effectif (gère "auto" -> locale du client si disponible, sinon défaut).
function NS.CurrentVoicePack()
    local c = NS.db and NS.db.profile and NS.db.profile.voice
    local p = c and c.pack
    if not p or p == "auto" then
        local loc = GetLocale and GetLocale() or NS.VOICE_DEFAULT_PACK
        for _, pk in ipairs(NS.VOICE_PACKS) do
            if pk.value == loc then return loc end
        end
        return NS.VOICE_DEFAULT_PACK
    end
    return p
end

if not LSM then
    NS:Print("|cffff6b6bLibSharedMedia-3.0 introuvable — la voix sera indisponible.|r")
    return
end

-- Texture de barre plate (menthe) — la teinte est appliquée à l'exécution.
LSM:Register("statusbar", "TomoBoss Menthe", "Interface\\Buttons\\WHITE8X8")

-- Enregistre chaque annonce, pour chaque pack de langue livré.
local n = 0
for _, pack in ipairs(NS.VOICE_PACKS) do
    local lang = pack.value
    for id, entry in pairs(NS.Voice and NS.Voice.Catalog or {}) do
        LSM:Register("sound", NS.VoiceKey(lang, id), VOICE_ROOT .. lang .. "\\" .. entry.file)
        n = n + 1
    end
end
NS:Debug("Médias enregistrés :", n, "clés vocales sur", #NS.VOICE_PACKS, "pack(s).")
