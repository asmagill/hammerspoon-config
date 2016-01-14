local wifi = require("hs.wifi")

local module = {}
module.status = {
    wifi = false,
}

-- wifi status

module.updateWifiActive = function()
    local result = true
    for i, v in ipairs(wifi.interfaces()) do
        local details = wifi.interfaceDetails(v)
        result = result and details.power and (details.interfaceMode == "Station")
        if not result then break end
    end
    module.status.wifi = result
    return result
end

module.wifiWatcher = wifi.watcher.new(function()
    module.updateWifiActive()
end):start()

return module
