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
            minGap    = 0.5,        -- espacement minimum entre deux annonces (s ; 0 = désactivé)
            boost     = 100,        -- volume des annonces en % (100-300 ; empile le son)
            pack      = "auto",     -- pack de langue vocale ("auto" | "frFR" | "enUS" | "deDE"...)
        },

        bars = {
            width      = 220,
            height     = 26,
            maxBars    = 8,
            spacing    = 4,
            grow       = "down",    -- "down" | "up"
            showIcon   = true,
            fontSize   = 13,
            showWindow = 0,         -- n'afficher que les barres à < X s (0 = toutes)
        },

        countdown = {
            enabled = true,
            scale   = 1.0,
        },

        flash = {
            enabled = true,
        },

        interrupts = {
            enabled    = true,
            showSelfCD = true,
            width      = 190,
            height     = 24,
            maxBars    = 6,
            spacing    = 2,
            grow       = "down",
            showIcon   = true,
            fontSize   = 13,
        },

        trash = {
            enabled     = true,
            voiceOnKick = false,
            width       = 200,
            height      = 24,
            maxBars     = 6,
            spacing     = 2,
            grow        = "down",
            showIcon    = true,
            fontSize    = 13,
        },

        rings = {
            size     = 44,
            spacing  = 8,
            maxRings = 6,
            grow     = "right",     -- "right" | "left"
            showName = true,
            fontSize = 11,
            autoRole = false,       -- anneau auto pour tank/soin/danger (style BossReminder)
        },

        minimap = {
            angle = 210,            -- position autour de la minicarte (degrés)
            hide  = false,
        },

        ringProgress = {
            enabled = true,         -- grand anneau central qui se referme
            size    = 180,
            alpha   = 0.85,
            edge    = true,         -- étincelle sur le bord qui avance
        },

        blizzTimeline = {
            enabled = true,         -- moteur timeline (C_EncounterTimeline) — principal sous Midnight
            bar     = true,
            ring    = false,
            voice   = true,
            cue     = false,        -- bip générique quand l'identité est masquée
            generic = true,         -- voix génériques par sévérité (contenu non couvert, ex. S2)
            genericTank   = "tank-buster",      -- sévérité 0 : coup tank
            genericOther  = "",                 -- sévérité 1 : "" = pas de voix (bip si activé)
            genericDanger = "special-mechanic", -- sévérité 2 : danger
        },

        custom = {
            entries = {},           -- entrées boss/trash créées par l'utilisateur
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
        self.InterruptTracker and self.InterruptTracker.group and self.InterruptTracker.group.anchor,
        self.TrashCD and self.TrashCD.group and self.TrashCD.group.anchor,
        self.UI.Rings and self.UI.Rings.anchor,
    }
    for _, a in ipairs(anchors) do if a then a:SetScale(s) end end
end
