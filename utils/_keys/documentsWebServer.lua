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
