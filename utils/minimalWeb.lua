--
-- Minimalist Web Server for Hammerspoon
--
-- Planned Features
--
--   [X] object based approach
--   [X] custom error pages
--   [X] functions for methods
--   [X] default page for directory
--   [X] text references to "http://" need to check _ssl status
--   [ ] Additional errors to add?
--   [-] verify read access to file
--   [ ] access list/general header check for go ahead?
--   [-] CGI Variables (still need query string)
--   [ ] CGI file types, check executable extensions
--   [ ] Hammerspoon aware pages (files, functions?)
--   [ ] Decode query strings
--   [ ] Decode form POST data
--   [ ] Allow adding alternate POST encodings (JSON)
--   [ ] add type validation, or at least wrap setters so we can reset internals when they fail
--   [ ] documentation
--   [ ] additional response headers?
--   [ ] proper content-type detection for GET
--
--   [ ] basic/digest auth via lua only?
--   [ ] cookie support? other than passing to/from dynamic pages, do we need to do anything?
--
--   [ ] For full WebDav support, some other methods may also require a body
--

local serverVersionString = "HSMinWeb/0.0.1"
local module = {}

local httpserver = require("hs.httpserver")
local http       = require("hs.http")
local fs         = require("hs.fs")
local nethost    = require("hs.network.host")
local log        = require("hs.logger").new(serverVersionString, "warning")
module.log = log

local HTTPdateFormatString = "!%a, %d %b %Y %T GMT"
local HTTPformattedDate = function(x) return os.date(HTTPdateFormatString, x and x or os.time()) end

local shallowCopy = function(t1)
    local t2 = {}
    for k, v in pairs(t1) do t2[k] = v end
    return t2
end

local directoryIndex = {
    "index.html", "index.htm"
}

local errorHandlers = setmetatable({
-- https://en.wikipedia.org/wiki/List_of_HTTP_status_codes
    [403] = function(method, path, headers)
        return "<html><head><title>Forbidden</title><head><body><H1>HTTP/1.1 403 Forbidden</H1></body></html>", 403, {}
    end,

    [403.2] = function(method, path, headers)
        return "<html><head><title>Read Access is Forbidden</title><head><body><H1>HTTP/1.1 403.2 Read Access is Forbidden</H1><br/>Read access for the requested URL, http" .. (headers._SSL and "s" or "") .. "://" .. headers.Host .. path .. ", is forbidden.<br/><hr/></body></html>", 403, {}
    end,

    [404] = function(method, path, headers)
        return "<html><head><title>Object Not Found</title><head><body><H1>HTTP/1.1 404 Object Not Found</H1><br/>The requested URL, http" .. (headers._SSL and "s" or "") .. "://" .. headers.Host .. path .. ", was not found on this server.<br/><hr/></body></html>", 404, {}
    end,

    [405] = function(method, path, headers)
        return "<html><head><title>Method Not Allowed</title><head><body><H1>HTTP/1.1 405 Method Not Allowed</H1><br/>The requested method, " .. method .. ", is not supported by this server or for the requested URL, http" .. (headers._SSL and "s" or "") .. "://" .. headers.Host .. path .. ".<br/><hr/></body></html>", 405, {}
    end,

    default = function(code, method, path, headers)
        return "<html><head><title>Internal Server Error</title><head><body><H1>HTTP/1.1 500 Internal Server Error</H1><br/>Error code " .. tostring(code) .. " has no handler<br/><hr/></body></html>", 500, {}
    end,
}, {
    __index = function(_, key)
        return function(...) return _.default(key, ...) end
    end
})

local supportedMethods = {
-- https://en.wikipedia.org/wiki/Hypertext_Transfer_Protocol
    GET       = true,
    HEAD      = true,
    POST      = true,
    PUT       = false,
    DELETE    = false,
    TRACE     = false,
    OPTIONS   = false,
    CONNECT   = false,
    PATCH     = false,
-- https://en.wikipedia.org/wiki/WebDAV
    PROPFIND  = false,
    PROPPATCH = false,
    MKCOL     = false,
    COPY      = false,
    MOVE      = false,
    LOCK      = false,
    UNLOCK    = false,
}

local webServerHandler = function(self, method, path, headers, body)
    method = method:upper()

    -- to help make proper URL in error functions
    headers._SSL = self._ssl and true or false

    local action = self._supportedMethods[method]
    if not action then return self._errorHandlers[405](method, path, headers) end

-- if the method is a function, we make no assumptions -- the function gets the raw input
    if type(action) == "function" then
    -- allow the action to ignore the request by returning false or nil to fall back to built-in methods
        local responseBody, responseCode, responseHeaders = action(self, method, path, headers, body)
        if responseBody then return responseBody, responseCode, responseHeaders end
    end

-- otherwise, figure out what specific file/directory is being targetted

    local pathParts  = http.urlParts((self._ssl and "https" or "http") .. "://" .. headers.Host .. path)
    local targetFile = self._documentRoot .. pathParts.path
    local attributes = fs.attributes(targetFile)
    if not attributes then return self._errorHandlers[404](method, path, headers) end

    if attributes.mode == "directory" and self._directoryIndex then
        if type(self._directoryIndex) ~= "table" then
            log.wf("directoryIndex: expected table, found %s", type(self._directoryIndex))
        else
            for i, v in ipairs(self._directoryIndex) do
                local attr = fs.attributes(targetFile .. "/" .. v)
                if attr and attr.mode == "file" then
                    attributes = attr
                    pathParts = http.urlParts((self._ssl and "https" or "http") .. "://" .. headers.Host .. pathParts.path .. "/" .. v .. (pathParts.query and ("?" .. pathParts.query) or ""))
                    targetFile = targetFile .. "/" .. v
                    break
                elseif attr then
                    log.wf("default directoryIndex %s for %s is not a file; skipping", v, targetFile)
                end
            end
        end
    end

    local responseBody, responseCode, responseHeaders = "", 200, {}

    -- remember to change Last-Modified for generated content
    responseHeaders["Last-Modified"] = HTTPformattedDate(attributes.modified)
    responseHeaders["Server"]        = serverVersionString .. " (OSX)"

    if (method == "HEAD") or (method == "GET") or (method == "POST") then

    -- determine if target is dynamically generated

        -- if so, we'll need these:
            -- per https://tools.ietf.org/html/rfc3875
                local CGIVariables = {
                    AUTH_TYPE         = self:password() and "Basic" or nil,
                    CONTENT_TYPE      = headers["Content-Type"],
                    CONTENT_LENGTH    = headers["Content-Length"],
                    GATEWAY_INTERFACE = "CGI/1.1",
            --         PATH_INFO         = , -- path portion after script (e.g. ../info.php/path/info/portion)
            --         PATH_TRANSLATED   = , -- real path to "virtual-path" specified by PATH_INFO
                    QUERY_STRING      = pathParts.query,
                    REQUEST_METHOD    = method,
                    REMOTE_ADDR       = header["X-Client-Ip"],
            --         REMOTE_HOST       = , -- see below
            --         REMOTE_IDENT      = , -- we don't support IDENT protocol
                    REMOTE_USER       = self:password() and "" or nil,
                    SCRIPT_NAME       = pathParts.path,
                    SERVER_NAME       = headers.host,
                    SERVER_PORT       = headers.port and headers.port or (self._ssl and 443 or 80),
                    SERVER_PROTOCOL   = "HTTP/1.1",
                    SERVER_SOFTWARE   = serverVersionString,
                }
                for k, v in pairs(headers) do
                    local k2 = k:upper()
                    if not {"AUTHORIZATION" = true, "PROXY-AUTHORIZATION" = true, "_SSL" = true}[k2] then
                        CGIVariables["HTTP_" .. k2] = v
                    end
                end
                if self._dnsLookup then
                    local good, val = pcall(nethost.hostnamesForAddress, CGIVariables.REMOTE_ADDR)
                    if good then
                        CGIVariables.REMOTE_HOST = val[1]
                    else
                        log.vf("unable to resolve %s", CGIVariables.REMOTE_ADDR)
                    end
                end
                if not CGIVariables.REMOTE_HOST then
                    CGIVariables.REMOTE_HOST = CGIVariables.REMOTE_HOST = CGIVariables.REMOTE_ADDR
                end

            -- commonly added
                CGIVariables.DOCUMENT_URI    = CGIVariables.SCRIPT_NAME .. (CGIVariables.PATH_INFO and CGIVariables.PATH_INFO or "")
                CGIVariables.REQUEST_URI     = CGIVariables.DOCUMENT_URI .. (CGIVariables.QUERY_STRING and ("?" .. CGIVariables.QUERY_STRING) or ""
                CGIVariables.DOCUMENT_ROOT   = self._documentRoot
                CGIVariables.SCRIPT_FILENAME = targetFile
                CGIVariables.REQUEST_TIME    = os.time()
                CGIVariables.USER            = os.getenv("USER")
                CGIVariables.HOME            = os.getenv("HOME")
                CGIVariables.HTTPS           = self._ssl and "on" or nil

            -- do dynamic content thingy...

        -- otherwise, we can't truly POST, so treat POST as GET; it will ignore the content body which a static page can't get to anyways; POST should be handled by a function or dynamic support above -- this is a fallback for an improper form action, etc.

            if method == "POST" then method = "GET" end
            if method == "GET" or method == "HEAD" then -- and not executable type then
                if attributes.mode == "file" then
                    local finput = io.open(file, "rb")
                    if finput then
                        if method == "GET" then -- don't actually do work for HEAD
                            responseBody = finput:read("a")
                        end
                        finput:close()
                    else
                        return self._errorHandlers[403.2](method, path, headers)
                    end
                elseif attributes.mode == "directory" and self._allowDirectory then
                    if fs.dir(targetFile) then
                        if method == "GET" then -- don't actually do work for HEAD
                            responseBody = [[
                                <html>
                                  <head>
                                    <title>Directory listing for ]] .. path .. [[</title>
                                  </head>
                                  <body>
                                    <h1>Directory listing for ]] .. path .. [[</h1>
                                    <hr>
                                    <pre>]]
                            for k in fs.dir(targetFile) do
                                local fattr = fs.attributes(targetFile.."/"..k)
                                if k:sub(1,1) ~= "." then
                                    if fattr then
                                        responseBody = responseBody .. string.format("    %-12s %s %7.2fK <a href=\"http%s://%s%s%s\">%s</a>\n", fattr.mode, fattr.permissions, fattr.size / 1024, (self._ssl and "s" or ""), headers.Host, path, k, k)
                                    else
                                        responseBody = responseBody .. "    ?? " .. k .. " ??\n"
                                    end
                                end
                            end
                            responseBody = responseBody [[</pre>
                                    <hr>
                                    <div align="right"><i>]] .. responseHeaders["Server"] .. [[ at ]] .. os.date() .. [[</i></div>
                                  </body>
                                </html>]]
                        end
                    else
                        return self._errorHandlers[403.2](method, path, headers)
                    end
                elseif attributes.mode == "directory" then
                    return self._errorHandlers[403.2](method, path, headers)
                end
            end

        if method == "HEAD" then responseBody = "" end -- in case it was dynamic and code gave us a body
        return responseBody, responseCode, responseHeaders
    else
        return self._errorHandlers[405](method, path, headers)
    end
end

local objectMethods = {}
local mt_table = {
    __passwords = {},
    __index     = objectMethods,
    __metatable = objectMethods, -- getmetatable should only list the available methods
}

objectMethods.port = function(self, ...)
    local args = table.pack(...)
    if args.n > 0 then
        self._port = args[1]
        if self._server then
            self._server:setPort(self._port)
        end
        return self
    else
        return self._server and self._server:getPort() or self._port
    end
end

objectMethods.documentRoot = function(self, ...)
    local args = table.pack(...)
    if args.n > 0 then
        self._documentRoot = args[1]
        return self
    else
        return self._documentRoot
    end
end

objectMethods.name  = function(self, ...)
    local args = table.pack(...)
    if args.n > 0 then
        self._name = args[1]
        if self._server then
            self._server:setName(self._name)
        end
        return self
    else
        return self._server and self._server:getName() or self._name
    end
end

objectMethods.maxBodySize = function(self, ...)
    local args = table.pack(...)
    if args.n > 0 then
        self._maxBodySize = args[1]
        if self._server then
            self._server:maxBodySize(self._maxBodySize)
        end
        return self
    else
        return self._server and self._server:maxBodySize() or self._maxBodySize
    end
end

objectMethods.start = function(self)
    if not self._server then
        self._ssl     = self._ssl or false
        self._bonjour = (type(self._bonjour) == "nil") and true or self._bonjour
        self._server  = httpserver.new(self._ssl, self._bonjour):setCallback(function(...)
            return webServerHandler(self, ...)
        end)

        if self._port                 then self._server:setPort(self._port) end
        if self._name                 then self._server:setName(self._name) end
        if self._maxBodySize          then self._server:maxBodySize(self._maxBodySize) end
        if mt_table.__passwords[self] then self._server:setPassword(mt_table.__passwords[self]) end

        self._server:start()

        return self
    else
        error("server already started", 2)
    end
end

objectMethods.stop = function(self)
    if self._server then
        self._server:stop()
        self._server = nil
        return self
    else
        error("server not currently running", 2)
    end
end

objectMethods.__gc = function(self)
    if self._server then self:stop() end
end

objectMethods.ssl = function(self, ...)
    local args = table.pack(...)
    if args.n > 0 then
        if not self._server then
            self._ssl = args[1]
            return self
        else
            error("ssl cannot be set for a running server", 2)
        end
    else
        return self._ssl
    end
end

objectMethods.bonjour = function(self, ...)
    local args = table.pack(...)
    if args.n > 0 then
        if not self._bonjour then
            self._bonjour = args[1]
            return self
        else
            error("bonjour cannot be set for a running server", 2)
        end
    else
        return self._bonjour
    end
end

objectMethods.allowDirectory = function(self, ...)
    local args = table.pack(...)
    if args.n > 0 then
        self._allowDirectory = args[1]
        return self
    else
        return self._allowDirectory
    end
end

objectMethods.dnsLookup = function(self, ...)
    local args = table.pack(...)
    if args.n > 0 then
        self._dnsLookup = args[1]
        return self
    else
        return self._dnsLookup
    end
end

objectMethods.directoryIndex = function(self, ...)
    local args = table.pack(...)
    if args.n > 0 then
        self._directoryIndex = args[1]
        return self
    else
        return self._directoryIndex
    end
end

objectMethods.password = function(self, ...)
    local args = table.pack(...)
    if args.n > 0 then
        mt_table.__passwords[self] = args[1]
        if self._server then
            self._server:setPassword(mt_table.__passwords[self])
        end
        return self
    else
        return  mt_table.__passwords[self] and true or false
    end
end


module.new = function(documentRoot)
    local instance = {
        _documentRoot     = documentRoot or os.getenv("HOME").."/Sites",
        _directoryIndex   = shallowCopy(directoryIndex),
        _errorHandlers    = setmetatable({}, { __index = errorHandlers }),
        _supportedMethods = setmetatable({}, { __index = supportedMethods }),
    }

    -- make it easy to see which methods are supported
    for k, v in pairs(supportedMethods) do if v then instance._supportedMethods[k] = v end end

    return setmetatable(instance, mt_table)
end

module.dateFormatString = HTTPdateFormatString
module.formattedDate    = HTTPformattedDate

return module
