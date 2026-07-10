---@diagnostic disable: undefined-global
-- TomoBoss — Valeurs par défaut et initialisation du profil sauvegardé (TomoBossDB).

local NS = select(2, ...)

NS.defaults = {
    profile = {
        enabled   = true,
        scale     = 1.0,
        locked    = true,
        debug     = false,
        positions = {},

        voice = {
            enabled   = true,
            channel   = "Master",   -- Master | SFX | Dialog | Music | Ambience
            lead      = 0.0,        -- avance des annonces (s)
            countdown = true,       -- voix du décompte de pull
        },

        bars = {
            width    = 220,
            height   = 26,
            maxBars  = 8,
            spacing  = 4,
            grow     = "down",      -- "down" | "up"
            showIcon = true,
            fontSize = 13,
        },

        countdown = {
            enabled = true,
            scale   = 1.0,
        },

        flash = {
            enabled = true,
        },
    },
}

-- Fusion récursive : complète les clés manquantes sans écraser l'existant.
local function fill(dst, src)
    for k, v in pairs(src) do
        if type(v) == "table" then
            if type(dst[k]) ~= "table" then dst[k] = {} end
            fill(dst[k], v)
        elseif dst[k] == nil then
            dst[k] = v
        end
    end
end

function NS:InitDB()
    TomoBossDB = TomoBossDB or {}
    self.db = TomoBossDB
    self.db.profile = self.db.profile or {}
    fill(self.db.profile, self.defaults.profile)
end

-- Applique l'échelle globale aux ancres des widgets.
function NS:ApplyScale()
    local s = self.db.profile.scale or 1
    local anchors = {
        self.UI.TimerBars and self.UI.TimerBars.anchor,
        self.UI.Countdown and self.UI.Countdown.anchor,
        self.UI.FlashText and self.UI.FlashText.anchor,
    }
    for _, a in ipairs(anchors) do if a then a:SetScale(s) end end
end
