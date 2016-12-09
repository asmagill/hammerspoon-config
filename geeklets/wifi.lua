local configuration = require("hs.network.configuration")
local reachability  = require("hs.network.reachability")

local watchable     = require"hs.watchable"

local http          = require("hs.http")

local output = {
    external = "unknown",
    primary = {
        interface = "unknown",
        address   = "0.0.0.0",
        name      = nil,
    },
    secondary = {
        interface = "unknown",
        address   = "0.0.0.0",
        name      = nil,
    },
}

local module = {}

local cstore = configuration.open()

local updateExternalAddress = function(w, p, i, oldValue, value)
    if value then
        module._getExternalAddress = http.asyncGet("http://eth0.me", nil, function(s, b, h)
            output.external = b
        end)
    else
        output.external = "NO INTERNET CONNECTION"
    end
end

module.watchInternetStatus = watchable.watch("generalStatus.internet", updateExternalAddress)

module.cstore = cstore
module.output = output

updateExternalAddress(nil, nil, nil, nil, module.watchInternetStatus:value())

return module
