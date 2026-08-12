---@diagnostic disable: undefined-global
-- TomoBoss — Démarrage : init du profil, ancres déplaçables, événements, commande /tmb.

local ADDON, NS = ...
local L = NS.L

--------------------------------------------------------------------------
-- Commande /tmb
--------------------------------------------------------------------------
-- Initialise un module en isolant ses erreurs.
--
-- Les modules étaient initialisés à la suite, sans filet : une erreur dans l'un
-- interrompait la fonction entière et emportait TOUS les suivants — y compris
-- l'enregistrement des commandes, ce qui rendait /tmb totalement muet. Un défaut
-- dans un module secondaire ne doit pas priver l'utilisateur de l'addon.
--
-- On signale le module fautif dans le chat plutôt que de laisser un silence
-- inexplicable : sans message, il n'y a aucun moyen de deviner lequel a cassé.
local function SafeInit(name, obj, fn)
    if type(obj) ~= "table" or type(obj[fn or "Init"]) ~= "function" then
        NS:Debug("Module absent : ", name)
        return false
    end
    local ok, err = pcall(obj[fn or "Init"], obj)
    if not ok then
        NS:Print("|cffe06c75Module " .. name .. " : échec d'initialisation.|r "
            .. "Le reste de l'addon fonctionne.")
        NS:Debug(name, "->", tostring(err))
        return false
    end
    return true
end

local function PrintHelp()
    NS:Print("|cff33e6a6" .. L.HELP_HEADER .. "|r")
    for _, line in ipairs({
        L.HELP_OPTIONS, L.HELP_PULL, L.HELP_PULLSTOP, L.HELP_TEST, L.HELP_TESTSTOP,
        L.HELP_LOCK, L.HELP_RESET, L.HELP_VOICE, L.HELP_KICKS,
        L.HELP_BRIDGE, L.HELP_LEARN, L.HELP_VERSION,
    }) do
        print("  |cff8a968f•|r " .. line)
    end
end

local function HandleSlash(input)
    local cmd, rest = tostring(input or ""):match("^(%S*)%s*(.-)$")
    cmd = (cmd or ""):lower()

    if cmd == "" then
        NS.GUI.Config:Toggle()
    elseif cmd == "pull" then
        NS.Engine.Pull:HandleSlash(rest)
    elseif cmd == "test" or cmd == "demo" or cmd == "apercu" then
        if rest:lower():find("stop") then
            NS.Engine.Timeline:StopDemo()
        else
            NS.Engine.Timeline:RunDemo(1999)
        end
    elseif cmd == "lock" or cmd == "verrouiller" then
        NS.UI.Mover:SetEditMode(false); NS:Print(L.MSG_LOCKED)
    elseif cmd == "unlock" or cmd == "deverrouiller" then
        NS.UI.Mover:SetEditMode(true); NS:Print(L.MSG_UNLOCKED)
    elseif cmd == "reset" then
        wipe(NS.db.profile.positions); NS.UI.Mover:ApplyAll(); NS:Print(L.MSG_RESET)
    elseif cmd == "voix" or cmd == "voice" then
        if rest ~= "" then
            if not NS.Voice:Play(rest, { force = true }) then
                NS:Print(L.MSG_UNKNOWN_VOICE, rest)
            end
        else
            NS:Print("/tmb voix <id>")
        end
    elseif cmd == "kicks" or cmd == "interruptions" then
        if NS.InterruptTracker then NS.InterruptTracker:PrintTally() end
    elseif cmd == "version" or cmd == "v" then
        if NS.Version then NS.Version:Query() end
    elseif cmd == "glow" or cmd == "halo" then
        NS.NameplateGlow:Report()

    elseif cmd == "rec" or cmd == "enregistreur" then
        NS.Recorder:Handle(rest)

    elseif cmd == "bridge" or cmd == "pont" then
        NS.EventBridge:HandleSlash(rest)

    elseif cmd == "debug" then
        NS.db.profile.debug = not NS.db.profile.debug
        NS:Print("Debug " .. (NS.db.profile.debug and "|cff33e6a6activé|r" or "|cffff6b6bdésactivé|r") ..
            ". Refais un pull et regarde les lignes [diag].")
    elseif cmd == "minimap" or cmd == "mini" then
        if NS.Minimap then NS.Minimap:SetShown(NS.db.profile.minimap.hide) end
    elseif cmd == "learn" or cmd == "apprendre" then
        NS.Learn:HandleSlash(rest)
    elseif cmd == "help" or cmd == "aide" then
        PrintHelp()
    else
        NS.GUI.Config:Toggle()
    end
end

--------------------------------------------------------------------------
-- Événements de combat / décompte.
--------------------------------------------------------------------------
local function OnCombatEvent(_, event, a1, a2, a3, a4, a5)
    if event == "ENCOUNTER_START" then
        if not NS.db.profile.enabled then return end
        local id = NS:SafeNumber(a1)
        NS:Debug("ENCOUNTER_START: a1=", tostring(a1), "secret=", tostring(NS:IsSecret(a1)), "-> id=", tostring(id))
        if id then
            local ok = NS.Engine.Timeline:Start(id)
            NS:Debug("Timeline:Start(", id, ") ->", tostring(ok),
                ok and "" or "(pas de données pour cet encounterID)")
        else
            NS:Print("|cffff6b6b[diag]|r encounterID illisible sur ENCOUNTER_START (masqué par Midnight) — le moteur ne peut pas démarrer par cet événement.")
        end

    elseif event == "ENCOUNTER_END" then
        if not NS.Engine.Timeline.demo then NS.Engine.Timeline:Stop() end

    elseif event == "PLAYER_REGEN_ENABLED" then
        -- sortie de combat : arrête le moteur (ENCOUNTER_END ne parvient pas non plus
        -- aux addons sous Midnight). Le prochain sort de boss reconnu relancera.
        if NS.Engine.Timeline.running and not NS.Engine.Timeline.demo then
            NS.Engine.Timeline:Stop()
        end

    elseif event == "PLAYER_ENTERING_WORLD" then
        if not NS.Engine.Timeline.demo then NS.Engine.Timeline:Stop() end
        if NS.EventBridge then C_Timer.After(0.3, function() NS.EventBridge:Apply("PEW") end) end
        NS.Engine.Pull:EndDisplay()
        NS.Engine.Pull:TryRegisterPullAlias()

    elseif event == "START_PLAYER_COUNTDOWN" then
        NS.Engine.Pull:OnStartCountdown(a1, a2, a3)

    elseif event == "CANCEL_PLAYER_COUNTDOWN" or event == "STOP_PLAYER_COUNTDOWN" then
        NS.Engine.Pull:OnCancelCountdown()
    end
end

--------------------------------------------------------------------------
-- Séquence de démarrage.
--------------------------------------------------------------------------
local boot = CreateFrame("Frame")
boot:RegisterEvent("ADDON_LOADED")
boot:RegisterEvent("PLAYER_LOGIN")
boot:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON then
        NS:InitDB()

    elseif event == "PLAYER_LOGIN" then
        -- crée l'instance des barres de boss (via la fabrique BarGroup)
        NS.UI.InitBossBars()

        -- crée les ancres pour pouvoir les rendre déplaçables
        NS.UI.TimerBars:EnsureAnchor()
        NS.UI.Countdown:EnsureAnchor()
        NS.UI.FlashText:EnsureAnchor()

        -- Commandes enregistrées EN PREMIER, avant tout module.
        --
        -- Elles étaient déclarées en fin d'initialisation : la moindre erreur en
        -- amont laissait /tmb totalement muet, sans le moindre indice sur la
        -- cause. C'est exactement ce qui s'est produit. Une commande qui répond
        -- est le minimum vital pour diagnostiquer quoi que ce soit.
        SLASH_TOMOBOSS1 = "/tmb"
        SLASH_TOMOBOSS2 = "/tomoboss"
        SlashCmdList["TOMOBOSS"] = HandleSlash

        SLASH_TOMOBOSSVER1 = "/tmbv"
        SlashCmdList["TOMOBOSSVER"] = function() if NS.Version then NS.Version:Query() end end

        -- initialise les modules (crée leurs groupes de barres + événements)
        SafeInit("InterruptTracker", NS.InterruptTracker)
        SafeInit("TrashCD", NS.TrashCD)
        if NS.InterruptTracker.group then NS.InterruptTracker.group:EnsureAnchor() end
        if NS.TrashCD.group then NS.TrashCD.group:EnsureAnchor() end

        -- groupe d'anneaux (affichage radial : entrées personnalisées, boss ou trash)
        NS.UI.Rings = NS.UI.CreateRingGroup("Rings", NS.db.profile.rings)
        NS.UI.Rings.demoFn = function(g, on)
            if on then
                local now = GetTime()
                g:AddOrUpdate("__r1", { name = "Anneau démo", duration = 12, endTime = now + 8, severity = 1, icon = 135808 })
                g:AddOrUpdate("__r2", { name = "Danger",      duration = 12, endTime = now + 5, severity = 2, icon = 135807 })
            else
                g:Remove("__r1"); g:Remove("__r2")
            end
        end
        NS.UI.Rings:EnsureAnchor()

        -- entrées personnalisées (moteur + trash désormais prêts)
        SafeInit("Custom", NS.Custom)

        -- module version (comparaison dans le groupe) + bouton minicarte
        SafeInit("Version", NS.Version)
        SafeInit("Minimap", NS.Minimap)
        SafeInit("BlizzTimeline", NS.BlizzTimeline)
        SafeInit("EventBridge", NS.EventBridge)
        NS.Recorder:Init()
        SafeInit("NameplateGlow", NS.NameplateGlow)
        SafeInit("Learn.Recorder", NS.Learn and NS.Learn.Recorder)

        NS.UI.Mover:Register("bars", NS.UI.TimerBars.anchor, L.MOVER_BARS,
            { point = "CENTER", x = -280, y = 80 }, function(on) NS.UI.TimerBars:ShowDemo(on) end)
        NS.UI.Mover:Register("countdown", NS.UI.Countdown.anchor, L.MOVER_COUNTDOWN,
            { point = "CENTER", x = 0, y = 160 }, function(on) NS.UI.Countdown:ShowDemo(on) end)
        NS.UI.Mover:Register("flash", NS.UI.FlashText.anchor, L.MOVER_FLASH,
            { point = "CENTER", x = 0, y = 240 }, function(on) NS.UI.FlashText:ShowDemo(on) end)
        NS.UI.Mover:Register("interrupts", NS.InterruptTracker.group.anchor, L.MOVER_INTERRUPTS,
            { point = "CENTER", x = 300, y = -60 }, function(on) NS.InterruptTracker.group:ShowDemo(on) end)
        NS.UI.Mover:Register("trash", NS.TrashCD.group.anchor, L.MOVER_TRASH,
            { point = "CENTER", x = -300, y = -60 }, function(on) NS.TrashCD.group:ShowDemo(on) end)
        NS.UI.Mover:Register("rings", NS.UI.Rings.anchor, L.MOVER_RINGS,
            { point = "CENTER", x = 0, y = -160 }, function(on) NS.UI.Rings:ShowDemo(on) end)
        NS.UI.RingProgress:Ensure()
        NS.UI.Mover:Register("ringprogress", NS.UI.RingProgress.anchor, L.MOVER_RINGPROG,
            { point = "CENTER", x = 0, y = 0 }, function(on) NS.UI.RingProgress:Demo(on) end)

        NS:ApplyScale()
        NS.UI.Countdown:ApplyScale()

        -- surveillance permanente des incantations de boss (auto-démarrage du moteur,
        -- indispensable car ENCOUNTER_START ne parvient pas aux addons sous Midnight)
        NS.Engine.Timeline:RegisterCastEvents()

        -- événements de jeu
        local ev = CreateFrame("Frame")
        for _, e in ipairs({
            "ENCOUNTER_START", "ENCOUNTER_END", "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_ENABLED",
            "START_PLAYER_COUNTDOWN", "CANCEL_PLAYER_COUNTDOWN", "STOP_PLAYER_COUNTDOWN",
        }) do
            ev:RegisterEvent(e)
        end
        ev:SetScript("OnEvent", OnCombatEvent)

        NS.Engine.Pull:TryRegisterPullAlias()

        NS:Print("|cff33e6a6" .. NS.version .. "|r " .. L.MSG_LOADED)
    end
end)
