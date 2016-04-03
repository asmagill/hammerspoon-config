--
-- local assets web server -- I don't want to have to rely on internet access all of the
-- time, so a local web server takes care of those things that I might need...

local module = {}

module.documentRoot = hs.configdir.."/_localAssets"

local httpserver = require("hs.httpserver")
local fs         = require("hs.fs")
local utf8       = require("hs.utf8")
local inspect    = require("hs.inspect")

local serverPort = 7734

-- private variables and methods -----------------------------------------

module.server = httpserver.new(false, false):setPort(serverPort):setCallback(function(method, path, headers, body)
--     if headers.Host ~= "localhost:"..tostring(serverPort) then
--     return "<html><head><title>Forbidden</title><head><body><H1>HTTP/1.1 403 Forbidden</H1></body></html>", 403, {}
--     end

    local file = module.documentRoot .. path
    local attr = fs.attributes(file)
    if attr and attr.mode == "file" then
        local finput = io.open(file, "rb")
        local data   = finput:read("a")
        finput:close()
        return data, 200, {}
    elseif attr and attr.mode == "directory" then
        local data = [[
            <html>
              <head>
                <title>Directory listing for ]] .. path .. [[</title>
              </head>
              <body>
                <h1>Directory listing for ]] .. path .. [[</h1>
                <hr>
                <pre>]]

        for k in fs.dir(file) do
            local fattr = fs.attributes(file.."/"..k)
            if k:sub(1,1) ~= "." then
                if fattr then
                    data = data .. string.format("    %-12s %s %7.2fK <a href=\"http://%s%s%s\">%s</a>\n", fattr.mode, fattr.permissions, fattr.size / 1024, headers.Host, path, k, k)
                else
                    data = data .. "    ?? " .. k .. " ??\n"
                end
            end
        end
        data = data .. "</pre>"
        data = data .. "<hr>Message Body<br><pre>" .. utf8.hexDump(body) .. "</pre>"
        data = data .. "<hr>Message Header<pre>" .. inspect(headers) .. "</pre>"
        data = data .. [[
                <hr>
                <div align="right"><i>Minimalist Hammerspoon Local Assets Server; ]] .. os.date() .. [[</i></div>
              </body>
            </html>]]
        return data, 200, {}
    else
        return "<html><head><title>Object Not Found</title><head><body><H1>HTTP/1.1 404 Object Not Found</H1><br/>The requested URL, http://" .. headers.Host .. path .. ", was not found on this server.<br/><hr/></body></html>", 404, {}
    end
end):start()

-- Public Changes ------------------------------------------------------

-- Return Module Object --------------------------------------------------

return module