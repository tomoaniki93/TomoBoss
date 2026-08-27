local addonName, NS = ...
if type(NS) ~= "table" or not NS.BossModBridge then return end

local Provider = { name = "bettertimeline", enabled = false }
NS.BossModBridge:RegisterProvider("bettertimeline", Provider)

local function isLoaded(name)
    if C_AddOns and C_AddOns.IsAddOnLoaded then
        return C_AddOns.IsAddOnLoaded(name)
    end
    return IsAddOnLoaded and IsAddOnLoaded(name)
end

function Provider:TryEnable()
    -- Better Timeline's addon folder/project name is AbilityTimeline.
    -- It already injects supported external boss-mod timers into the native
    -- C_EncounterTimeline. We therefore treat it as a native proxy and do NOT
    -- register a second timer feed here; doing so would create duplicates.
    local loaded = isLoaded("AbilityTimeline") or _G.AbilityTimeline ~= nil
    self.enabled = loaded and true or false
    self.detail = loaded and "native-proxy via C_EncounterTimeline" or "not loaded"
    NS.BossModBridge:SetProviderStatus("bettertimeline", self.enabled, self.detail)
    return self.enabled
end
