---@diagnostic disable: undefined-global
-- TomoBoss — Lot 3 : pont Blizzard Encounter Timeline -> renderer sélectionné.
--
-- Avant TomoTimeline, blizzTimeline.bar servait à décider si la source officielle
-- Blizzard devait créer des barres. Avec le DisplayController, ce verrou legacy ne
-- doit pas empêcher le renderer Timeline/Hybride de recevoir les mêmes événements.
--
-- Ce fichier est chargé juste après BlizzTimeline.lua et adapte son comportement
-- sans dupliquer le moteur de matching, de voix ou de resynchronisation.

local NS = select(2, ...)
local BT = NS.BlizzTimeline
local Display = NS.UI and NS.UI.DisplayController
if not (BT and Display) or BT.__displayModeBridge then return end
BT.__displayModeBridge = true

local function cfg()
    return NS.db and NS.db.profile and NS.db.profile.blizzTimeline
end

local function wantsTimelineFeed()
    local mode = Display:GetRequestedMode()
    return mode == "timeline" or mode == "hybrid"
end

-- Exécute une fonction historique comme si "Afficher en barres" était activé,
-- uniquement lorsque Timeline/Hybride en a besoin. TimerBars est désormais une
-- façade : DisplayController enverra ensuite vers le bon renderer, pas
-- nécessairement vers les barres.
local function runWithDisplayFeed(fn, self, ...)
    local c = cfg()
    if not (c and c.bar == false and wantsTimelineFeed()) then
        return fn(self, ...)
    end

    c.bar = true
    local ok, err = pcall(fn, self, ...)
    c.bar = false
    if not ok then error(err, 0) end
end

local originalRender = BT.Render
if originalRender then
    function BT:Render(...)
        return runWithDisplayFeed(originalRender, self, ...)
    end
end

-- Tick contient le recalage périodique C_EncounterTimeline -> TimerBars. Le même
-- pont est nécessaire ici pour que TomoTimeline conserve le minutage serveur
-- exact lorsque l'ancien checkbox "bar" est désactivé.
local originalTick = BT.Tick
if originalTick then
    function BT:Tick(...)
        return runWithDisplayFeed(originalTick, self, ...)
    end
end

-- Republie les événements déjà actifs. Cela couvre le cas où le joueur passe de
-- Bars à Timeline au milieu d'un combat : le modèle commun n'attend pas le prochain
-- ENCOUNTER_TIMELINE_EVENT_ADDED pour remplir la nouvelle vue.
function BT:RepublishTimerDisplay()
    if not (NS.UI and NS.UI.TimerBars and self.active) then return end
    local now = GetTime()
    for id, e in pairs(self.active) do
        local remaining = (e.endTime or now) - now
        if remaining > 0 then
            NS.UI.TimerBars:AddOrUpdate("bt:" .. tostring(id), {
                name = e.name,
                icon = e.icon or 134400,
                duration = math.max(0.1, e.total or remaining),
                endTime = e.endTime,
                severity = e.severity,
            })
        end
    end
end

-- Centraliser le comportement : cela fonctionne pour le dropdown du GUI mais aussi
-- pour /tmbmode du Lot 2C et pour tout futur appel au DisplayController.
local originalSetMode = Display.SetMode
if originalSetMode then
    function Display:SetMode(mode)
        local resolved = originalSetMode(self, mode)
        if resolved == "timeline" or resolved == "hybrid" then
            BT:RepublishTimerDisplay()
        end
        return resolved
    end
end
