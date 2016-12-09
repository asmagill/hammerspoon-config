local module = {}

-- common watchers... why replicate what so many of my "modlets" care about?

local reachability = require"hs.network.reachability"
local screen       = require"hs.screen"
local watchable    = require"hs.watchable"
local caffeinate   = require"hs.caffeinate"
local configuration = require"hs.network.configuration"

module.generalStatus = watchable.new("generalStatus")

module.generalStatus.internet = (reachability.internet():status() & reachability.flags.reachable) > 0
module.internetWatcher = reachability.internet():setCallback(function(obj, status)
    module.generalStatus.internet = (status & reachability.flags.reachable) > 0
end):start()

module.generalStatus.activeScreenChanges = 0
module.generalStatus.activeSpaceChanges = 0
module.activeScreenSpaceWatcher = screen.watcher.newWithActiveScreen(function(screenOrSpace)
    if screenOrSpace then
        module.generalStatus.activeScreenChanges = module.generalStatus.activeScreenChanges + 1
    else
        module.generalStatus.activeSpaceChanges = module.generalStatus.activeSpaceChanges + 1
    end
end):start()

module.generalStatus.caffeinatedState = 0
module.caffeinatedStateWatcher = caffeinate.watcher.new(function(event)
    module.generalStatus.caffeinatedState = event
end):start()

local vpnQueryKey = "State:/Network/Interface/utun[0-9]+/IPv4"
local verifyOurVPNisUp = function()
    local status = false
    if module.vpnWatcher then
        for k, v in pairs(module.vpnWatcher:contents(vpnQueryKey, true)) do
            for i2, v2 in ipairs(v["Addresses"]) do
                if v2:match("^10%.161%.82%.") then
                    status = true
                    break
                end
            end
            if status then break end
        end
    end
    module.generalStatus.privateVPN = status
end
module.vpnWatcher = configuration.open():setCallback(verifyOurVPNisUp)
                                        :monitorKeys(vpnQueryKey, true)
                                        :start()
verifyOurVPNisUp()

return module
