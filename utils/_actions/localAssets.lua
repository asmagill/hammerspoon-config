--
-- local assets web server -- I don't want to have to rely on internet access all of the
-- time, so a local web server takes care of those things that I might need...

local module = {}

local hsminweb = require("hs._asm.hsminweb")
local serverPort = 7734
local documentRoot = hs.configdir.."/_localAssets"

module.server = hsminweb.new(documentRoot):port(serverPort)
                                          :allowDirectory(true)
                                          :name("localAssets")
                                          :bonjour(false)
                                          :accessList{
                                              {"X-Remote-Addr",  "::1",       false,   true},
                                              {"X-Remote-Addr",  "127.0.0.1", false,   true},
                                            -- technically optional, but I like being explicit
                                              {"*",              "*",         false,   false},
                                          }
                                          :start()

-- modify GET so we can query the headers during testing
module.server._supportedMethods.GET = function(self, method, path, headers, body)
    if path:match(";headers$") then
        local fs   = require("hs.fs")
        local http = require("hs.http")

        local pathParts  = http.urlParts((self._ssl and "https" or "http") .. "://" .. headers.Host .. path)
        local targetFile = self._documentRoot .. pathParts.path
        local attr       = fs.attributes(targetFile)
        local data       = ""
        if attr and attr.mode == "file" then
            local finput = io.open(targetFile, "rb")
            data = data .. finput:read("a") .. "<br/><br/>"
            finput:close()
        elseif attr and attr.mode == "directory" then
            local targetPath = pathParts.path
            if not targetPath:match("/$") then targetPath = targetPath .. "/" end
            data = [[
                <html>
                  <head>
                    <title>Directory listing for ]] .. targetPath .. [[</title>
                  </head>
                  <body>
                    <h1>Directory listing for ]] .. targetPath .. [[</h1>
                    <hr>
                    <pre>]]
            for k in fs.dir(targetFile) do
                local fattr = fs.attributes(targetFile.."/"..k)
                if k:sub(1,1) ~= "." then
                    if fattr then
                        data = data .. string.format("    %-12s %s %7.2fK <a href=\"http%s://%s%s%s\">%s%s</a>\n", fattr.mode, fattr.permissions, fattr.size / 1024, (self._ssl and "s" or ""), headers.Host, targetPath, k, k, (fattr.mode == "directory" and "/" or ""))
                    else
                        data = data .. "    <i>unknown" .. string.rep(" ", 6) .. string.rep("-", 9) .. string.rep(" ", 10) .. "?? " .. k .. " ??</i>\n"
                    end
                end
            end
            data = data .. "</pre>"
        end

        data = data .. "<hr>URL Expansion<pre>" .. hs.inspect(pathParts) .. "</pre>"
        data = data .. "Message Method<pre>" .. method .. "</pre>"
        data = data .. "Message Path<pre>" .. path .. "</pre>"
        data = data .. "Message Header<pre>" .. hs.inspect(headers) .. "</pre>"
        data = data .. "Message Body<pre>" .. hs.utf8.hexDump(body) .. "</pre>"
        data = data .. [[
                <hr>
                <div align="right"><i>]] .. os.date() .. [[</i></div>
              </body>
            </html>]]

        return data, 200, {}
    else
        return false
    end
end

return module
