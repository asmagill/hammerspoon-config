--
-- I was under the impression hs.http did not support methods for accessing servers wit BASIC or DIGEST
-- authentication... I suppose sometime I should actually try these things out before going to this much
-- trouble... oh well, I learned something about how to manipulate header keys with wrappers that may
-- prove helpful if I ever decide to try manipulating cookies without relying on Obj-C's NSURL's classes.
--
-- To use user/passwords with the existing hs.http, just put them into the URL, e.g.
--   http://user:pass@host.com/path...
--
-- OS X handles the rest for us.  Note that user or pass can be empty, but the : and @ must be present.
--

-- NOTES
-- see https://tools.ietf.org/html/rfc7235#section-4.1 re multiple authentication methods
-- see https://tools.ietf.org/html/rfc7616 and https://tools.ietf.org/html/rfc7617 too see what additions to
--     auth headers we might need to make (e.g. SHA256 hash
local module = {}

module.debug = true
local debugPrint = function(...) if module.debug then print(...) end end

local http       = require("hs.http")
local base64     = require("hs.base64")
local host       = require("hs.host")
local fnutils    = require("hs.fnutils")

local MD5        = require"hs.hash".MD5
local parseURL   = require"hs.httpserver.hsminweb".urlParts

local parseAuthenticationRequest = function(input)
    input = input or "basic"
    local authType, restOfLine = input:match("^(%g+) ?(.-)$")
    local authParameters = {}

    local pos = 1
    local key, value = "", ""
    local keyStart, keyEnd, valueStart, valueEnd = 0, 0, 0, 0
    local inQuotes = false
    while pos <= #restOfLine do
        local c = restOfLine:sub(pos, pos)
        if keyStart == 0 and c ~= " " then keyStart = pos end
        if not inQuotes and c == "=" then
            keyEnd = pos - 1
            valueStart = pos + 1
        end
        if not inQuotes and c == "," then valueEnd = pos - 1 end
        if c == "\"" then inQuotes = not inQuotes end
        if keyStart ~= 0 and keyEnd ~= 0 and valueStart ~= 0 then
            if pos == #restOfLine then valueEnd = #restOfLine end
            if valueEnd ~= 0 then
                if restOfLine:sub(valueStart, valueStart) == "\"" then valueStart = valueStart + 1 end
                if restOfLine:sub(valueEnd, valueEnd) == "\"" then valueEnd = valueEnd - 1 end

                authParameters[restOfLine:sub(keyStart, keyEnd)] = restOfLine:sub(valueStart, valueEnd)
                keyStart, keyEnd, valueStart, valueEnd = 0, 0, 0, 0
            end
        end
        pos = pos + 1
    end

    return authType:lower(), authParameters
end

local oneOf = function(...)
    local results = {}
    for i, v in ipairs(table.pack(...)) do results[v] = 1 end
    return results
end

local caseInsensitiveKeys = function(self, key)
    local value = rawget(self, key)
    if not value and type(key) == "string" then
        for k, v in pairs(self) do
            if type(k) == "string" then
                if k:lower() == key:lower() then
                    value = v
                    break
                end
            end
        end
    end
    return value
end

local requestHandler = function(url, meth, data, hdrs, call, user, pass)
    assert(oneOf("string")       [type(url)],  "url must be a string")
    assert(oneOf("string")       [type(meth)], "method must be a string")
    assert(oneOf("nil", "string")[type(data)], "data must be nil or a string")
    assert(oneOf("nil", "table") [type(hdrs)], "headers must be nil or a table")
    -- call is validated in doAsyncRequest since this worker function uses return when call is nil
    assert(oneOf("nil", "string")[type(user)], "user must be nil or a string")
    assert(oneOf("nil", "string")[type(pass)], "password must be nil or a string")

    -- now correct the ones which can be nil to their "default" in case we need them
    -- data gets a pass since we just pass it on
    local hasCred = (user or pass) and true or false
    hdrs = hdrs or {}
    user = user or ""
    pass = pass or ""

    -- defined as a local function within this function because we need the up-values from requestHandler
    local handleAuthentication = function(stat, body, rhdr)
        -- if it's not a 401 status or if no credential specified, then we don't handle it
        if stat ~= 401 or not hasCred then
            if call then
                call(stat, body, rhdr)
                return
            else
                return stat, body, rhdr
            end
        end

        -- the HTTP spec says all header keys are case insensitive, but lua don't play that way
        rhdr = setmetatable(rhdr, { __index = caseInsensitiveKeys })

        local authType, authParameters = parseAuthenticationRequest(rhdr["WWW-Authenticate"])
        debugPrint("++ " .. tostring(rhdr["WWW-Authenticate"]))

        if authType == "basic" then

            -- see https://tools.ietf.org/html/rfc2617#section-2

            hdrs["Authorization"] = "Basic " .. base64.encode(user .. ":" .. pass)

            debugPrint("++ Authorization: " .. hdrs["Authorization"])
            if call then
                http.doAsyncRequest(url, meth, data, hdrs, call)
            else
                return http.doRequest(url, meth, data, hdrs)
            end

        elseif authType == "digest" then -- now it gets fun...

            -- see https://tools.ietf.org/html/rfc2617#section-3.2
            -- and https://en.wikipedia.org/wiki/Digest_access_authentication

            -- If the algorithm directive's value is "MD5" or unspecified, then HA1 is
            --     HA1=MD5(username:realm:password)
            --
            -- If the algorithm directive's value is "MD5-sess", then HA1 is
            --     HA1=MD5(MD5(username:realm:password):nonce:cnonce)
            local HA1 = MD5(user .. ":" .. authParameters["realm"] .. ":" .. pass)
            local nonce, algorithm, cnonce = authParameters["nonce"], authParameters["algorithm"], MD5(host.uuid())
            if algorithm == "MD5-sess" then
                HA1 = MD5(HA1 .. ":" .. nonce .. ":" .. cnonce)
            end

            -- If the qop directive's value is "auth" or is unspecified, then HA2 is
            --     HA2=MD5(method:digestURI)
            --
            -- If the qop directive's value is "auth-int", then HA2 is
            --     HA2=MD5(method:digestURI:MD5(entityBody))
            local HA2, qop = nil, fnutils.split(authParameters["qop"] or "", ",")
            local uri = parseURL(url).path
            if uri == "" then uri = "/" end
            if #qop == 0 or fnutils.contains(qop, "auth") then
                HA2 = MD5(meth .. ":" .. uri)
                qop = qop and "auth" or nil
            elseif fnutils.contains(qop, "auth-int") then
                HA2 = MD5(meth .. ":" .. uri .. ":" .. MD5(data or ""))
                qop = "auth-int"
            else -- invalid or undocumented, but since we don't do multiple WWW-Authenticate entries yet, try anyways
                HA2 = MD5(meth .. ":" .. uri .. ":" .. MD5(data or ""))
                qop = "auth-int"
            end

            -- If the qop directive's value is "auth" or "auth-int", then compute the response as follows:
            --     response=MD5(HA1:nonce:nonceCount:cnonce:qop:HA2)
            --
            -- If the qop directive is unspecified, then compute the response as follows:
            --     response=MD5(HA1:nonce:HA2)
            local response =
                qop and ( MD5(HA1 .. ":" .. nonce .. ":00000001:" .. cnonce .. ":" .. qop .. ":" .. HA2) )
                    or  ( MD5(HA1 .. ":" .. nonce .. ":" .. HA2) )

            -- always included in response
            local authResponse = {
                username  = '"' .. user .. '"',
                realm     = '"' .. authParameters["realm"] .. '"',
                nonce     = '"' .. nonce .. '"',
                response  = '"' .. response .. '"',
                uri       = '"' .. uri .. '"',
            }

            -- only included if specified in WWW-Authenticate header
            if authParameters["opaque"] then authResponse["opaque"]    = '"' .. authParameters["opaque"] .. '"' end
            if algorithm                then authResponse["algorithm"] = '"' .. algorithm .. '"' end

            -- only included if qop specified in WWW-Authenticate header
            if qop then
                authResponse["qop"]    = qop
                authResponse["cnonce"] = '"' .. cnonce .. '"'
                authResponse["nc"]     = "00000001"
            end

            local authString = "Digest "
            for k, v in pairs(authResponse) do authString = authString .. k .. "=" .. v ..", " end
            authString = authString:sub(1, -3)
            hdrs["Authorization"] = authString
            debugPrint("++ Authorization: " .. hdrs["Authorization"])
            if call then
                http.doAsyncRequest(url, meth, data, hdrs, call)
            else
                return http.doRequest(url, meth, data, hdrs)
            end
        else
            -- we can't handle it, maybe they can, but unset metatable changes so they get what we got
            setmetatable(rhdr, nil)
            if call then
                call(stat, body, rhdr)
            else
                return stat, body, rhdr
            end
        end
    end

    -- now invoke the functions that do the actual work
    if call then
        http.doAsyncRequest(url, meth, data, hdrs, handleAuthentication)
    else
        return handleAuthentication(http.doRequest(url, meth, data, hdrs))
    end
end

module.doAsyncRequest = function(url, meth, data, hdrs, call, user, pass)
    assert(oneOf("function") [type(call)], "callback must be a function")
    requestHandler(url, meth, data, hdrs, call, user, pass)
end

module.asyncGet = function(url, hdrs, call, user, pass)
    module.doAsyncRequest(url, "GET", nil, hdrs, call, user, pass)
end

module.asyncPost = function(url, data, hdrs, call, user, pass)
    module.doAsyncRequest(url, "POST", data, hdrs, call, user, pass)
end

module.doRequest = function(url, meth, data, hdrs, user, pass)
    return requestHandler(url, meth, data, hdrs, nil, user, pass)
end

module.get = function(url, hdrs, user, pass)
    return module.doRequest(url, "GET", nil, hdrs, user, pass)
end

module.post = function(url, data, hdrs, user, pass)
    return module.doRequest(url, "POST", data, hdrs, user, pass)
end

-- for testing, but you have to enable it if you want it
module.webServer = require"hs.httpserver".new(false, false):setCallback(function(...)
    debugPrint("++ Made it to the web server callback")
    return inspect(table.pack(...)), 200, { ["Content-Type"] = "text/plain; charset=UTF-8" }
end):setPort(50103):setPassword("aPassword")

return module