local noises    = require("hs.noises")
local watchable = require("hs._asm.watchable")

local module = {}
module.watchables = watchable.new("popConsole", true)
module.watchables.enabled = true
local prevValue = true

module.callback = function(w)
    if w == 1 then     -- start "sssss" sound
    elseif w == 2 then -- end "sssss" sound
    elseif w == 3 then -- mouth popping sound
        hs.toggleConsole()
    end
end
module._noiseWatcher = noises.new(module.callback):start()

module.watchExternalToggle = watchable.watch("popConsole.enabled", function(w, p, i, oldValue, value)
    if value then
        module._noiseWatcher:start()
    else
        module._noiseWatcher:stop()
    end
--     print(module.watchables.enabled)
end)

module.watchCaffeinatedState = watchable.watch("generalStatus.caffeinatedState", function(w, p, i, old, new)
    if new == 1 then -- systemWillSleep
        prevValue = module.watchables.enabled
        module.watchables.enabled = false
--         print("%% willSleep")
    elseif new == 0 then -- systemDidWake
        module.watchables.enabled = prevValue
--         print("%% didWake")
    end
end)

return module
