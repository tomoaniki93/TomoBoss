---@diagnostic disable: undefined-global
-- TomoBoss — final locale selection and completeness audit.

local NS = select(2, ...)
local supported = { "enUS", "enGB", "frFR", "deDE", "esES", "esMX", "itIT", "ptBR", "ruRU", "koKR", "zhCN", "zhTW" }
local reference = NS.Locales.enUS
NS.LocaleAudit = { missing = {}, extra = {} }
for _, code in ipairs(supported) do
    local t = NS.Locales[code]
    if t then
        for key in pairs(reference) do
            if t[key] == nil then NS.LocaleAudit.missing[#NS.LocaleAudit.missing + 1] = code .. ":" .. key end
        end
        for key in pairs(t) do
            if reference[key] == nil then NS.LocaleAudit.extra[#NS.LocaleAudit.extra + 1] = code .. ":" .. key end
        end
    end
end
local code = GetLocale and GetLocale() or "enUS"
NS.L = NS.Locales[code] or NS.Locales.enUS
