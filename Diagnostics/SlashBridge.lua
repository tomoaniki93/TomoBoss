local addonName, NS = ...
if type(NS) ~= "table" or not NS.Doctor then return end

local function trimLower(s)
    s = type(s) == "string" and s or ""
    s = s:gsub("^%s+", ""):gsub("%s+$", "")
    return s:lower()
end

local installed = false
local function installDoctorSubcommand()
    if installed then return true end
    local handler = SlashCmdList and SlashCmdList["TOMOBOSS"]
    if type(handler) ~= "function" then return false end

    -- Init.lua registers /tmb on PLAYER_LOGIN. This file is loaded before that
    -- event, so wrapping at file-load time is too early. Install after the
    -- original handler exists and preserve every existing command unchanged.
    local original = handler
    SlashCmdList["TOMOBOSS"] = function(msg, editBox)
        local clean = trimLower(msg)
        local first, second = clean:match("^(%S+)%s*(%S*)")
        if first == "doctor" or first == "diag" or first == "diagnostic" then
            NS.Doctor:Run()
            return
        elseif first == "trashdoctor" and NS.TrashObservatory then
            NS.TrashObservatory:RunDoctor()
            return
        elseif first == "trashdump" and NS.TrashObservatory then
            NS.TrashObservatory:ShowDump()
            return
        elseif first == "trashreset" and NS.TrashObservatory then
            NS.TrashObservatory:Reset()
            return
        elseif first == "trashpreview" and NS.TrashObservatory then
            if second == "on" or second == "1" then
                NS.TrashObservatory:SetPreview(true)
            elseif second == "off" or second == "0" then
                NS.TrashObservatory:SetPreview(false)
            else
                NS.TrashObservatory:RunDoctor()
            end
            return
        elseif first == "statedump" and NS.StateResolver and type(NS.StateResolver.ShowEvidenceDump) == "function" then
            NS.StateResolver:ShowEvidenceDump()
            return
        end
        return original(msg, editBox)
    end
    installed = true
    return true
end

-- Standalone rescue alias: available even if another addon replaces /tmb.
SLASH_TMB_DOCTOR1 = "/tmbdoctor"
SlashCmdList["TMB_DOCTOR"] = function()
    NS.Doctor:Run()
end

SLASH_TMB_TRASHDOCTOR1 = "/tmbtrashdoctor"
SlashCmdList["TMB_TRASHDOCTOR"] = function()
    if NS.TrashObservatory then NS.TrashObservatory:RunDoctor() end
end

SLASH_TMB_TRASHDUMP1 = "/tmbtrashdump"
SlashCmdList["TMB_TRASHDUMP"] = function()
    if NS.TrashObservatory then NS.TrashObservatory:ShowDump() end
end

SLASH_TMB_STATEDUMP1 = "/tmbstatedump"
SlashCmdList["TMB_STATEDUMP"] = function()
    if NS.StateResolver and type(NS.StateResolver.ShowEvidenceDump) == "function" then
        NS.StateResolver:ShowEvidenceDump()
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function(self)
    -- Init.lua also reacts to PLAYER_LOGIN and installs /tmb there. Defer one
    -- frame so its assignment is guaranteed to have happened first.
    C_Timer.After(0, function()
        if not installDoctorSubcommand() then
            -- Very defensive retry for delayed/lazy startup paths.
            C_Timer.After(0.5, installDoctorSubcommand)
        end
    end)
    self:UnregisterEvent("PLAYER_LOGIN")
end)
