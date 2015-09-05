local n = require("hs.notify")
local i = require("hs.image")
local t = require("hs.timer")
local c = require("hs.caffeinate")

local module = {}

-- won't auto clear if click causes HS to launch, since neither of the
-- HS delegates are in place yet.  Need to add support in
-- NSApplicationDelegate's applicationDidLaunch method one day

n.register("_crashWatcher", function(_)
    print("++ Hammerspoon crash watcher")
    _:withdraw() -- in case we're from a recreated userdata
end)

module.crashNotification = n.new(_crashWatcher):title("Crash?")
    :informativeText("This notification was not stopped by the timer.  Click here to restart Hammerspoon.")
    :contentImage(i.imageFromName(i.systemImageNames.Caution))
    :schedule(os.time()+45)

module.timer = t.doEvery(30, function()
    module.crashNotification:withdraw()
    module.crashNotification:schedule(os.time()+45)
end)

module.sleepWatcher = c.watcher.new(function(_)
    if _ == c.watcher.systemWillSleep then
        module.crashNotification:withdraw()
        module.timer:stop()
    elseif _ == c.watcher.systemDidWake then
        module.crashNotification:schedule(os.time()+45)
        module.timer:start()
    end
end):start()

return setmetatable(module, {
    __gc = function(_)
        _.crashNotification:withdraw()
        _.timer:stop()
    end,
})
