local addonName, NS = ...
if type(NS) ~= "table" or not NS.BossModBridge then return end

local function tryProviders()
    for _, provider in pairs(NS.BossModBridge.providers or {}) do
        if type(provider.TryEnable) == "function" then
            pcall(provider.TryEnable, provider)
        end
    end
end

tryProviders()

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("ENCOUNTER_END")
frame:SetScript("OnEvent", function(_, event)
    if event == "ADDON_LOADED" or event == "PLAYER_LOGIN" then
        tryProviders()
    elseif event == "ENCOUNTER_END" then
        NS.BossModBridge:ResetSource("bigwigs")
        NS.BossModBridge:ResetSource("dbm")
    end
end)
