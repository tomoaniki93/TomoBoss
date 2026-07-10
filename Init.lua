---@diagnostic disable: undefined-global
-- TomoBoss — Démarrage : init du profil, ancres déplaçables, événements, commande /tmb.

local ADDON, NS = ...
local L = NS.L

--------------------------------------------------------------------------
-- Commande /tmb
--------------------------------------------------------------------------
local function PrintHelp()
    NS:Print("|cff33e6a6" .. L.HELP_HEADER .. "|r")
    for _, line in ipairs({
        L.HELP_OPTIONS, L.HELP_PULL, L.HELP_PULLSTOP, L.HELP_TEST, L.HELP_TESTSTOP,
        L.HELP_LOCK, L.HELP_RESET, L.HELP_VOICE, L.HELP_KICKS,
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
        if id then NS.Engine.Timeline:Start(id) end

    elseif event == "ENCOUNTER_END" then
        if not NS.Engine.Timeline.demo then NS.Engine.Timeline:Stop() end

    elseif event == "PLAYER_ENTERING_WORLD" then
        if not NS.Engine.Timeline.demo then NS.Engine.Timeline:Stop() end
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

        -- initialise les modules (crée leurs groupes de barres + événements)
        NS.InterruptTracker:Init()
        NS.TrashCD:Init()
        NS.InterruptTracker.group:EnsureAnchor()
        NS.TrashCD.group:EnsureAnchor()

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

        NS:ApplyScale()
        NS.UI.Countdown:ApplyScale()

        -- commande /tmb
        SLASH_TOMOBOSS1 = "/tmb"
        SLASH_TOMOBOSS2 = "/tomoboss"
        SlashCmdList["TOMOBOSS"] = HandleSlash

        -- événements de jeu
        local ev = CreateFrame("Frame")
        for _, e in ipairs({
            "ENCOUNTER_START", "ENCOUNTER_END", "PLAYER_ENTERING_WORLD",
            "START_PLAYER_COUNTDOWN", "CANCEL_PLAYER_COUNTDOWN", "STOP_PLAYER_COUNTDOWN",
        }) do
            ev:RegisterEvent(e)
        end
        ev:SetScript("OnEvent", OnCombatEvent)

        NS.Engine.Pull:TryRegisterPullAlias()

        NS:Print("|cff33e6a6" .. NS.version .. "|r " .. L.MSG_LOADED)
    end
end)
