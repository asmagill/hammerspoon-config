local module = {}

-- common watchers... why replicate what so many of my "modlets" care about?

local reachability = require"hs.network.reachability"
local screen       = require"hs.screen"
local watchable    = require"hs._asm.watchable"
local caffeinate   = require"hs.caffeinate"

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

return module
