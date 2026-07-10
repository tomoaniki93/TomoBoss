---@diagnostic disable: undefined-global
-- TomoBoss — Chaînes de l'interface (français).

local NS = select(2, ...)

NS.L = {
    -- Général
    ADDON_TITLE       = "TomoBoss",
    TAGLINE           = "Minuteurs de boss + voix française",
    OPEN_OPTIONS      = "Ouvrir les options",
    ENABLED           = "Addon activé",
    ENABLED_DESC      = "Active ou désactive complètement TomoBoss.",
    GLOBAL_SCALE      = "Échelle globale",
    TEST              = "Aperçu / Test",
    TEST_RUN          = "Lancer un aperçu",
    TEST_STOP         = "Arrêter l'aperçu",
    UNLOCK            = "Déverrouiller l'interface",
    LOCK              = "Verrouiller l'interface",
    UNLOCK_DESC       = "Affiche des poignées pour déplacer les éléments à l'écran.",
    RESET_POS         = "Réinitialiser les positions",

    -- Onglets
    TAB_GENERAL       = "Général",
    TAB_BARS          = "Barres",
    TAB_VOICE         = "Voix",
    TAB_COUNTDOWN     = "Compte à rebours",
    TAB_ABOUT         = "À propos",

    -- Barres
    BARS_TITLE        = "Barres de minuteur",
    BARS_WIDTH        = "Largeur",
    BARS_HEIGHT       = "Hauteur",
    BARS_MAX          = "Nombre de barres",
    BARS_SPACING      = "Espacement",
    BARS_GROW         = "Sens de croissance",
    BARS_GROW_UP      = "Vers le haut",
    BARS_GROW_DOWN    = "Vers le bas",
    BARS_ICON         = "Afficher l'icône",
    BARS_FONTSIZE     = "Taille du texte",
    BARS_TEXTURE      = "Texture de barre",

    -- Voix
    VOICE_TITLE       = "Voix",
    VOICE_ENABLED     = "Annonces vocales",
    VOICE_ENABLED_DESC= "Joue une voix française pour chaque capacité de boss.",
    VOICE_CHANNEL     = "Canal audio",
    VOICE_LEAD        = "Avance des annonces (s)",
    VOICE_LEAD_DESC   = "Joue l'annonce quelques instants avant l'incantation.",
    VOICE_PREVIEW     = "Tester une annonce",
    VOICE_PLAY        = "Jouer",
    VOICE_PACK        = "Pack vocal : VoixFrancaise02 (Melune)",

    -- Compte à rebours
    CD_TITLE          = "Compte à rebours de pull",
    CD_ENABLED        = "Grand compteur au centre",
    CD_SCALE          = "Échelle du compteur",
    CD_VOICE          = "Voix du décompte (5-4-3-2-1)",
    CD_USAGE          = "Commande : /tmb pull [secondes]  —  /tmb pull stop pour annuler",

    -- À propos
    ABOUT_VERSION     = "Version",
    ABOUT_CREDITS     = "Crédits",
    ABOUT_BODY        = "Addon personnel inspiré d'EXBoss. Moteur, interface et intégration vocale par Tomo. Pack audio français par VoixFrancaise02 (Melune).",
    ABOUT_COMMANDS    = "Commandes",

    -- Aperçu / poignées
    MOVER_BARS        = "Barres de minuteur",
    MOVER_COUNTDOWN   = "Compte à rebours",
    MOVER_FLASH       = "Alerte centrale",
    MOVER_HINT        = "Glissez pour déplacer",

    -- Messages console
    MSG_LOADED        = "chargé. Tapez /tmb pour les options.",
    MSG_UNLOCKED      = "Interface déverrouillée — glissez les éléments, puis /tmb lock.",
    MSG_LOCKED        = "Interface verrouillée.",
    MSG_RESET         = "Positions réinitialisées.",
    MSG_NOCOUNTDOWN   = "Le décompte de groupe n'est pas disponible sur ce client.",
    MSG_PULL_USAGE    = "Usage : /tmb pull [secondes]",
    MSG_UNKNOWN_VOICE = "Annonce inconnue :",

    -- Aide
    HELP_HEADER       = "Commandes TomoBoss :",
    HELP_OPTIONS      = "/tmb — ouvre les options",
    HELP_PULL         = "/tmb pull [n] — lance un décompte de pull (défaut 10 s)",
    HELP_PULLSTOP     = "/tmb pull stop — annule le décompte",
    HELP_TEST         = "/tmb test — lance un aperçu des minuteurs",
    HELP_TESTSTOP     = "/tmb test stop — arrête l'aperçu",
    HELP_LOCK         = "/tmb lock | unlock — verrouille/déverrouille les éléments",
    HELP_RESET        = "/tmb reset — réinitialise les positions",
    HELP_VOICE        = "/tmb voix <id> — teste une annonce vocale",
    HELP_KICKS        = "/tmb kicks — affiche le décompte d'interruptions (clé M+)",

    -- Interruptions
    TAB_INTERRUPTS    = "Interruptions",
    INT_TITLE         = "Suivi des interruptions",
    INT_ENABLED       = "Activer le suivi",
    INT_ENABLED_DESC  = "Affiche qui interrompt, en donjon 5 joueurs.",
    INT_SELFCD        = "Barre de recharge de votre interruption",
    INT_KICKS_BTN     = "Afficher le décompte (M+)",
    MOVER_INTERRUPTS  = "Interruptions",

    -- TrashCD
    TAB_TRASH         = "TrashCD",
    TRASH_TITLE       = "TrashCD — incantations des packs",
    TRASH_ENABLED     = "Activer TrashCD",
    TRASH_ENABLED_DESC= "Barres pour les capacités importantes des packs (donjon 5).",
    TRASH_VOICE_KICK  = "Annonce vocale sur incantation interruptible",
    MOVER_TRASH       = "TrashCD",
}
