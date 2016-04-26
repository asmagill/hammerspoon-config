--
-- local assets web server -- I don't want to have to rely on internet access all of the
-- time, so a local web server takes care of those things that I might need...

local module = {}

local hsminweb = require("hs.httpserver.hsminweb")
local serverPort = 7734
local documentRoot = hs.configdir.."/_localAssets"

module.server = hsminweb.new(documentRoot):port(serverPort)
                                          :allowDirectory(true)
                                          :name("localAssets")
                                          :bonjour(false)
                                          :cgiEnabled(true)
                                          :luaTemplateExtension("lp")
                                          :directoryIndex{
                                              "index.html", "index.lp", "index.cgi",
                                          }:accessList{
                                              {"X-Remote-Addr",  "::1",       false,   true},
                                              {"X-Remote-Addr",  "127.0.0.1", false,   true},
                                            -- technically optional, but I like being explicit
                                              {"*",              "*",         false,   false},
                                          }
                                          :start()

module.server._logBadTranslations       = true
module.server._logPageErrorTranslations = true
module.server._allowRenderTranslations  = true

module.hsdocs = require"hs.doc.hsdocs".start()

return module
