--
-- Toggle private webserver for documentation... smaller footprint than Apache, but even so, not needed often

local module = {}

local hsminweb = require("hs.httpserver.hsminweb")
local hotkey   = require("hs.hotkey")
local alert    = require("hs.alert").show

local serverPort = 8192
local documentRoot = os.getenv("HOME") .. "/Sites"

module.server = hsminweb.new(documentRoot):port(serverPort)
                                          :allowDirectory(true)
                                          :name("Sites")
                                          :bonjour(true)
                                          :cgiEnabled(true)
                                          :luaTemplateExtension("lp")
                                          :directoryIndex{
                                              "index.html", "index.lp", "index.cgi",
                                          }:accessList{
                                              {"X-Remote-Addr", "::1",            false, true},
                                              {"X-Remote-Addr", "127.0.0.1",      false, true},
                                              {"X-Remote-Addr", "^10%.0%.1%.",    true,  true},
                                              {"X-Remote-Addr", "^10%.161%.81%.", true,  true},
                                              {"*",             "*",              false, false},
                                          }

module.server._logBadTranslations       = true
module.server._logPageErrorTranslations = true
module.server._allowRenderTranslations  = true
module.debugging = function(value)
    if type(value) == "boolean" then
        module.server._logBadTranslations       = value
        module.server._logPageErrorTranslations = value
        module.server._allowRenderTranslations  = value
    end
    print("** translation debugging:", module.server._logBadTranslations and "enabled" or "disabled")
end

module.hotkey = hotkey.bind({"cmd", "alt"}, "f10", function()
    if module.server._server then
        alert("Turning Documentation Server Off...")
        module.server:stop()
    else
        alert("Turning Documentation Server On...")
        module.server:start()
    end
end)

module.server:start() -- using it quite a bit right now; may change default or remove key sequence toggle in the future depending upon my usage
return module

-- -- modify GET so we can query the headers during testing
-- module.server._supportedMethods.GET = function(self, method, path, headers, body)
--     if path:match(";headers$") then
--         local fs   = require("hs.fs")
--         local http = require("hs.http")
--
--         local pathParts  = http.urlParts((self._ssl and "https" or "http") .. "://" .. headers.Host .. path)
--         local targetFile = self._documentRoot .. pathParts.path
--         local attr       = fs.attributes(targetFile)
--         local data       = ""
--         if attr and attr.mode == "file" then
--             local finput = io.open(targetFile, "rb")
--             data = data .. finput:read("a") .. "<br/><br/>"
--             finput:close()
--         elseif attr and attr.mode == "directory" then
--             local targetPath = pathParts.path
--             if not targetPath:match("/$") then targetPath = targetPath .. "/" end
--             data = [[
--                 <html>
--                   <head>
--                     <title>Directory listing for ]] .. targetPath .. [[</title>
--                   </head>
--                   <body>
--                     <h1>Directory listing for ]] .. targetPath .. [[</h1>
--                     <hr>
--                     <pre>]]
--             for k in fs.dir(targetFile) do
--                 local fattr = fs.attributes(targetFile.."/"..k)
--                 if k:sub(1,1) ~= "." then
--                     if fattr then
--                         data = data .. string.format("    %-12s %s %7.2fK <a href=\"http%s://%s%s%s\">%s%s</a>\n", fattr.mode, fattr.permissions, fattr.size / 1024, (self._ssl and "s" or ""), headers.Host, targetPath, k, k, (fattr.mode == "directory" and "/" or ""))
--                     else
--                         data = data .. "    <i>unknown" .. string.rep(" ", 6) .. string.rep("-", 9) .. string.rep(" ", 10) .. "?? " .. k .. " ??</i>\n"
--                     end
--                 end
--             end
--             data = data .. "</pre>"
--         end
--
--         data = data .. "<hr>URL Expansion<pre>" .. hs.inspect(pathParts) .. "</pre>"
--         data = data .. "Message Method<pre>" .. method .. "</pre>"
--         data = data .. "Message Path<pre>" .. path .. "</pre>"
--         data = data .. "Message Header<pre>" .. hs.inspect(headers) .. "</pre>"
--         data = data .. "Message Body<pre>" .. hs.utf8.hexDump(body) .. "</pre>"
--         data = data .. [[
--                 <hr>
--                 <div align="right"><i>]] .. os.date() .. [[</i></div>
--               </body>
--             </html>]]
--
--         return data, 200, {}
--     else
--         return false
--     end
-- end
