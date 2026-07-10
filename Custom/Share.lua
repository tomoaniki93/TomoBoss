---@diagnostic disable: undefined-global
-- TomoBoss — Partage : sérialisation JSON + base64, chaînes export/import (style WeakAura).
-- Aucune dépendance, aucun loadstring : décodeur JSON maison (sûr).

local NS = select(2, ...)
local Share = {}
NS.Share = Share

local PREFIX = "!TMB:1!"

--========================================================================
-- Encodeur JSON
--========================================================================
local function encStr(s)
    s = s:gsub('[%z\1-\31\\"]', function(c)
        local map = { ['"'] = '\\"', ['\\'] = '\\\\', ['\n'] = '\\n', ['\r'] = '\\r', ['\t'] = '\\t' }
        return map[c] or string.format("\\u%04x", string.byte(c))
    end)
    return '"' .. s .. '"'
end

local encVal
local function isArray(t)
    local n = 0
    for k in pairs(t) do
        if type(k) ~= "number" then return false end
        n = n + 1
    end
    -- contiguë 1..n ?
    for i = 1, n do if t[i] == nil then return false end end
    return true, n
end

encVal = function(v, out)
    local tp = type(v)
    if v == nil then
        out[#out + 1] = "null"
    elseif tp == "boolean" then
        out[#out + 1] = v and "true" or "false"
    elseif tp == "number" then
        if v ~= v or v == math.huge or v == -math.huge then
            out[#out + 1] = "null"
        else
            out[#out + 1] = string.format("%.14g", v)
        end
    elseif tp == "string" then
        out[#out + 1] = encStr(v)
    elseif tp == "table" then
        local arr, n = isArray(v)
        if arr then
            out[#out + 1] = "["
            for i = 1, n do
                if i > 1 then out[#out + 1] = "," end
                encVal(v[i], out)
            end
            out[#out + 1] = "]"
        else
            out[#out + 1] = "{"
            local first = true
            local keys = {}
            for k in pairs(v) do keys[#keys + 1] = k end
            table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
            for _, k in ipairs(keys) do
                if not first then out[#out + 1] = "," end
                first = false
                out[#out + 1] = encStr(tostring(k))
                out[#out + 1] = ":"
                encVal(v[k], out)
            end
            out[#out + 1] = "}"
        end
    else
        out[#out + 1] = "null"
    end
end

function Share:EncodeJSON(tbl)
    local out = {}
    encVal(tbl, out)
    return table.concat(out)
end

--========================================================================
-- Décodeur JSON (récursif, sans loadstring)
--========================================================================
local function skipWS(s, i)
    local _, j = s:find("^[ \t\r\n]*", i)
    return (j or i - 1) + 1
end

local parseValue

local function parseString(s, i)
    -- s[i] == '"'
    i = i + 1
    local buf = {}
    while i <= #s do
        local c = s:sub(i, i)
        if c == '"' then
            return table.concat(buf), i + 1
        elseif c == '\\' then
            local n = s:sub(i + 1, i + 1)
            if n == 'n' then buf[#buf + 1] = '\n'
            elseif n == 't' then buf[#buf + 1] = '\t'
            elseif n == 'r' then buf[#buf + 1] = '\r'
            elseif n == '"' then buf[#buf + 1] = '"'
            elseif n == '\\' then buf[#buf + 1] = '\\'
            elseif n == '/' then buf[#buf + 1] = '/'
            elseif n == 'u' then
                local hex = s:sub(i + 2, i + 5)
                local code = tonumber(hex, 16) or 63
                if code < 128 then
                    buf[#buf + 1] = string.char(code)
                else
                    -- encode UTF-8 (jusqu'à U+FFFF)
                    if code < 2048 then
                        buf[#buf + 1] = string.char(192 + math.floor(code / 64), 128 + (code % 64))
                    else
                        buf[#buf + 1] = string.char(
                            224 + math.floor(code / 4096),
                            128 + (math.floor(code / 64) % 64),
                            128 + (code % 64))
                    end
                end
                i = i + 4
            else
                buf[#buf + 1] = n
            end
            i = i + 2
        else
            buf[#buf + 1] = c
            i = i + 1
        end
    end
    return nil, i, "chaîne non terminée"
end

local function parseNumber(s, i)
    local pat = "^%-?%d+%.?%d*[eE]?[%+%-]?%d*"
    local a, b = s:find(pat, i)
    if not a then return nil, i, "nombre invalide" end
    local num = tonumber(s:sub(a, b))
    return num, b + 1
end

parseValue = function(s, i)
    i = skipWS(s, i)
    local c = s:sub(i, i)
    if c == '{' then
        local obj = {}
        i = skipWS(s, i + 1)
        if s:sub(i, i) == '}' then return obj, i + 1 end
        while true do
            i = skipWS(s, i)
            if s:sub(i, i) ~= '"' then return nil, i, "clé attendue" end
            local key; key, i = parseString(s, i)
            if key == nil then return nil, i, "clé invalide" end
            i = skipWS(s, i)
            if s:sub(i, i) ~= ':' then return nil, i, "':' attendu" end
            local val; val, i = parseValue(s, i + 1)
            if val == nil and type(val) ~= "boolean" then
                -- val peut légitimement être false/0/"" ; on distingue via l'erreur
            end
            -- convertit les clés numériques en nombres (ids)
            local nk = tonumber(key)
            obj[nk or key] = val
            i = skipWS(s, i)
            local ch = s:sub(i, i)
            if ch == ',' then i = i + 1
            elseif ch == '}' then return obj, i + 1
            else return nil, i, "',' ou '}' attendu" end
        end
    elseif c == '[' then
        local arr = {}
        i = skipWS(s, i + 1)
        if s:sub(i, i) == ']' then return arr, i + 1 end
        while true do
            local val; val, i = parseValue(s, i)
            arr[#arr + 1] = val
            i = skipWS(s, i)
            local ch = s:sub(i, i)
            if ch == ',' then i = i + 1
            elseif ch == ']' then return arr, i + 1
            else return nil, i, "',' ou ']' attendu" end
        end
    elseif c == '"' then
        return parseString(s, i)
    elseif c == 't' then
        if s:sub(i, i + 3) == 'true' then return true, i + 4 end
        return nil, i, "littéral invalide"
    elseif c == 'f' then
        if s:sub(i, i + 4) == 'false' then return false, i + 5 end
        return nil, i, "littéral invalide"
    elseif c == 'n' then
        if s:sub(i, i + 3) == 'null' then return false, i + 4 end -- null -> false (placeholder)
        return nil, i, "littéral invalide"
    else
        return parseNumber(s, i)
    end
end

function Share:DecodeJSON(str)
    if type(str) ~= "string" then return nil, "entrée invalide" end
    local ok, val, _, err = pcall(function()
        local v, i, e = parseValue(str, 1)
        return v, i, e
    end)
    if not ok then return nil, "erreur d'analyse" end
    if val == nil then return nil, err or "analyse échouée" end
    return val
end

--========================================================================
-- Base64
--========================================================================
local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local B64DEC = {}
for i = 1, #B64 do B64DEC[B64:sub(i, i)] = i - 1 end

function Share:Base64Encode(data)
    local out = {}
    local n = #data
    local i = 1
    while i <= n do
        local a = data:byte(i) or 0
        local b = data:byte(i + 1)
        local c = data:byte(i + 2)
        local b1 = math.floor(a / 4)
        local b2 = (a % 4) * 16 + math.floor((b or 0) / 16)
        local b3 = ((b or 0) % 16) * 4 + math.floor((c or 0) / 64)
        local b4 = (c or 0) % 64
        out[#out + 1] = B64:sub(b1 + 1, b1 + 1)
        out[#out + 1] = B64:sub(b2 + 1, b2 + 1)
        out[#out + 1] = b and B64:sub(b3 + 1, b3 + 1) or "="
        out[#out + 1] = c and B64:sub(b4 + 1, b4 + 1) or "="
        i = i + 3
    end
    return table.concat(out)
end

function Share:Base64Decode(str)
    str = str:gsub("[^%w%+%/=]", "")
    local out = {}
    local i = 1
    local n = #str
    while i <= n do
        local c1 = B64DEC[str:sub(i, i)]
        local c2 = B64DEC[str:sub(i + 1, i + 1)]
        local s3 = str:sub(i + 2, i + 2)
        local s4 = str:sub(i + 3, i + 3)
        local c3 = B64DEC[s3]
        local c4 = B64DEC[s4]
        if c1 == nil or c2 == nil then break end
        out[#out + 1] = string.char(c1 * 4 + math.floor(c2 / 16))
        if s3 ~= "=" and c3 ~= nil then
            out[#out + 1] = string.char((c2 % 16) * 16 + math.floor(c3 / 4))
            if s4 ~= "=" and c4 ~= nil then
                out[#out + 1] = string.char((c3 % 4) * 64 + c4)
            end
        end
        i = i + 4
    end
    return table.concat(out)
end

--========================================================================
-- Export / Import de haut niveau
--========================================================================
function Share:Export(tbl)
    return PREFIX .. self:Base64Encode(self:EncodeJSON(tbl))
end

function Share:Import(str)
    if type(str) ~= "string" then return nil, "chaîne vide" end
    str = str:gsub("^%s+", ""):gsub("%s+$", "")
    if str:sub(1, #PREFIX) ~= PREFIX then
        return nil, "préfixe TomoBoss manquant"
    end
    local payload = str:sub(#PREFIX + 1)
    local json = self:Base64Decode(payload)
    if not json or json == "" then return nil, "décodage base64 échoué" end
    local tbl, err = self:DecodeJSON(json)
    if not tbl then return nil, err or "JSON invalide" end
    return tbl
end
