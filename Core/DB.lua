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
        -- Fondation visuelle V2. Les options sont volontairement simples au Lot 1 ;
        -- elles seront exposées dans le GUI lors du Lot 3.
        appearance = {
            theme      = "obsidian", -- "obsidian" | "legacy"
            panelAlpha = 0.97,       -- opacité des surfaces du GUI
        },
        -- Couche de rendu des minuteurs de boss. Le Lot 2A garde les barres
        -- comme mode actif par défaut ; les renderers Timeline/Hybride seront
        -- branchés sur ce contrôleur sans modifier les producteurs de timers.
        display = {
            timerMode      = "bars", -- "bars" | "timeline" | "hybrid"
            fallbackToBars = true,   -- sécurité si un renderer demandé n'est pas chargé
        },
        -- TomoTimeline V1 : second renderer natif des minuteurs de boss.
        -- Le Lot 3 exposera ces valeurs dans le GUI ; le mode reste "bars" par
        -- défaut pour ne pas modifier l'interface des profils existants.
        timeline = {
            orientation       = "vertical", -- V1 : vertical ; horizontal prévu ensuite
            direction         = "down",     -- futur en haut -> NOW en bas
            width             = 340,
            height            = 420,
            window            = 40,         -- fenêtre temporelle visible (secondes)
            iconSize          = 32,
            maxEvents         = 10,
            tickEvery         = 5,
            showTicks         = true,
            showName          = true,
            showTime          = true,
            priorityThreshold = 5,          -- accent danger sous ce seuil
            updateRate        = 0.05,       -- 20 Hz seulement quand le renderer est visible
        },
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
            width           = 220,
            height          = 26,
            maxBars         = 8,
            spacing         = 4,
            grow            = "down",    -- "down" | "up"
            showIcon        = true,
            fontSize        = 13,
            showWindow      = 0,         -- n'afficher que les barres à < X s (0 = toutes)
            style           = "modern",  -- "modern" | "legacy" (Boss Bars V2)
            fillAlpha       = 0.72,       -- opacité du remplissage Modern
            trackAlpha      = 0.92,       -- opacité de la piste sombre Modern
            dangerThreshold = 5,          -- état urgence / temps rouge sous ce seuil (s)
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
            voiceOnMe   = false,    -- annoncer quand une incantation de pack vous vise
            onlyImportant = false,  -- n'afficher que les sorts classés importants par le jeu
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
            hideBlizzardUI = true,  -- rendre la timeline NATIVE invisible (doublon de TomoBoss)
            ring    = false,
            voice   = true,
            cue     = false,        -- bip générique quand l'identité est masquée
            generic = true,         -- voix génériques par sévérité (contenu non couvert, ex. S2)
            genericTank   = "tank-buster",      -- sévérité 0 : coup tank
            genericOther  = "",                 -- sévérité 1 : "" = pas de voix (bip si activé)
            genericDanger = "special-mechanic", -- sévérité 2 : danger
        },
        eventBridge = {
            enabled  = true,        -- confier la voix au jeu (C_EncounterEvents)
            sounds   = true,        -- poser les fichiers son
            colors   = true,        -- teinter les barres Blizzard par sévérité
            trigger  = 2,           -- 0 avertissement texte | 1 capacité lancée | 2 ~5 s avant
            genericFallback = true, -- events sans voix propre : voix générique par sévérité
            forceCVar = true,       -- forcer encounterWarningsEnabled à 1
        },
        recorder = {
            enabled = false,        -- enregistreur de timeline (/tmb rec on)
        },

        custom = {
            entries = {},           -- entrées boss/trash créées par l'utilisateur
        },

        learn = {
            enabled  = true,        -- enregistrement des pulls (source de données propre)
            announce = true,        -- message en fin de pull
            pulls    = {},          -- observations brutes, par rencontre
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
        self.UI.TomoTimeline and self.UI.TomoTimeline.anchor,
        self.UI.Countdown and self.UI.Countdown.anchor,
        self.UI.FlashText and self.UI.FlashText.anchor,
        self.InterruptTracker and self.InterruptTracker.group and self.InterruptTracker.group.anchor,
        self.TrashCD and self.TrashCD.group and self.TrashCD.group.anchor,
        self.UI.Rings and self.UI.Rings.anchor,
    }
    for _, a in ipairs(anchors) do if a then a:SetScale(s) end end
end
