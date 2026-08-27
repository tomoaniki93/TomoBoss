local addonName, NS = ...
if type(NS) ~= "table" or not NS.BossModBridge then return end

local Provider = { name = "blizzard", enabled = false }
NS.BossModBridge:RegisterProvider("blizzard", Provider)

function Provider:TryEnable()
    local available = type(C_EncounterTimeline) == "table"
        and type(C_EncounterTimeline.GetEventInfo) == "function"
    self.enabled = available and true or false
    self.detail = available and "native-authority (Modules/BlizzTimeline.lua)" or "API unavailable"
    NS.BossModBridge:SetProviderStatus("blizzard", self.enabled, self.detail)
    return self.enabled
end
