--
-- local assets web server -- I don't want to have to rely on internet access all of the
-- time, so a local web server takes care of those things that I might need...

local module = {}

module.documentRoot = hs.configdir.."/_localAssets"

local httpserver = require("hs.httpserver")
local fs         = require("hs.fs")

local serverPort = 7734

-- private variables and methods -----------------------------------------

module.server = httpserver.new():setPort(serverPort):setCallback(function(method, path)
    local file = module.documentRoot..path
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
                <title>Directory listing for "..path.."</title>
              </head>
              <body>
                <h1>Directory listing for ]]..path..[[</h1>
                <hr>
                <pre>]]

        for k in fs.dir(file) do
            local fattr = fs.attributes(file.."/"..k)
            if fattr then
                data = data .. string.format("    %s %s %7.2fK %s\n", fattr.mode:sub(1,1), fattr.permissions, fattr.size / 1024, k)
            else
                data = data .. "    ?? "..k.." ??\n"
            end
        end
        data = data .. [[</pre>
                <hr>
                <div align="right"><i>Minimalist Hammerspoon Local Assets Server; ]]..os.date()..[[</i></div>
              </body>
            </html>]]
        return data, 200, {}
    else
        return "<html><head><title>Object Not Found</title><head><body><H1>HTTP/1.1 404 Object Not Found</H1><br/>The requested URL was not found on this server.<br/><hr/></body></html>", 404, {}
    end
end):start()

-- Public Changes ------------------------------------------------------

-- Return Module Object --------------------------------------------------

return module
