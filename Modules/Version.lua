---@diagnostic disable: undefined-global
-- TomoBoss — Module version. /tmbv affiche votre version et celle des membres du
-- groupe qui possèdent l'addon (rien pour ceux qui ne l'ont pas), via messages d'addon.

local NS = select(2, ...)
local V = {}
NS.Version = V

local PREFIX = "TomoBoss"
V.peers = {} -- nom court -> version

local function myVersion() return NS.version or "?" end
local function myName() return (UnitName("player")) or "Vous" end

-- Canal de groupe adapté (instance / raid / groupe).
local function groupChannel()
    if IsInGroup(LE_PARTY_CATEGORY_INSTANCE or 2) then return "INSTANCE_CHAT" end
    if IsInRaid() then return "RAID" end
    if IsInGroup() then return "PARTY" end
    return nil
end

local function send(msg)
    local ch = groupChannel()
    if not ch then return end
    if C_ChatInfo and C_ChatInfo.SendAddonMessage then
        C_ChatInfo.SendAddonMessage(PREFIX, msg, ch)
    end
end

function V:Broadcast()
    send("V:" .. myVersion())
end

-- Interroge le groupe puis affiche après un court délai.
function V:Query()
    wipe(self.peers)
    self.peers[myName()] = myVersion()
    send("Q?")        -- demande aux autres de répondre
    self:Broadcast()  -- annonce aussi la nôtre
    if C_Timer and C_Timer.After then
        C_Timer.After(1.5, function() self:PrintList() end)
    else
        self:PrintList()
    end
end

function V:PrintList()
    local list = {}
    for name, ver in pairs(self.peers) do list[#list + 1] = { name = name, ver = ver } end
    table.sort(list, function(a, b) return a.name < b.name end)

    NS:Print(string.format("|cff33e6a6Version %s|r — TomoBoss dans le groupe :", myVersion()))
    if #list <= 1 and not IsInGroup() then
        print("  |cff8a968fVous êtes seul.|r")
        return
    end
    for _, e in ipairs(list) do
        local mark = (e.ver == myVersion()) and "|cff33e6a6" or "|cffffcc66"
        print(string.format("  %s%s|r : %s%s|r", "|cffe6edea", e.name, mark, e.ver))
    end
    if #list == 1 then
        print("  |cff8a968f(Personne d'autre dans le groupe n'a l'addon.)|r")
    end
end

function V:OnMessage(prefix, msg, _, sender)
    if prefix ~= PREFIX or type(msg) ~= "string" then return end
    local name = Ambiguate and Ambiguate(sender, "short") or sender
    if msg == "Q?" then
        self:Broadcast() -- quelqu'un demande : on répond
    elseif msg:sub(1, 2) == "V:" then
        self.peers[name] = msg:sub(3)
    end
end

function V:Init()
    if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
        C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)
    end
    local f = CreateFrame("Frame")
    f:RegisterEvent("CHAT_MSG_ADDON")
    f:RegisterEvent("GROUP_ROSTER_UPDATE")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:SetScript("OnEvent", function(_, event, a1, a2, a3, a4)
        if event == "CHAT_MSG_ADDON" then
            self:OnMessage(a1, a2, a3, a4)
        else
            -- (ré)annonce notre version à l'entrée/aux changements de groupe
            self.peers[myName()] = myVersion()
            self:Broadcast()
        end
    end)
end
