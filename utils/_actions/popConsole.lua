local noises    = require("hs.noises")
local watchable = require("hs._asm.watchable")

local module = {}
module.watchables = watchable.new("popConsole", true)
module.watchables.enabled = true

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

return module
