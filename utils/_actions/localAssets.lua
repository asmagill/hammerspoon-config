--
-- local assets web server -- I don't want to have to rely on internet access all of the
-- time, so a local web server takes care of those things that I might need...

local module = {}

local hsminweb = require("hs._asm.hsminweb")
local serverPort = 7734

module.documentRoot = hs.configdir.."/_localAssets"

module.server = hsminweb.new():port(serverPort)
                              :documentRoot(module.documentRoot)
                              :allowDirectory(true)
                              :name("localAssets")
                              :bonjour(false)
                              :start()

-- -- Still need to implement accessList
--                               :accessList{
--                               --  Header          Matches     isPattern Accept/Reject
--                                   {"X-Client-IP",  "::1",       false,   true},
--                                   {"X-Client-IP",  "127.0.0.1", false,   true},
--                                   {"*",            "*",         false,   false},
--                               }

return module
