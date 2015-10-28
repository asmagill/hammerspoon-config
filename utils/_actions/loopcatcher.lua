local module = {}

local timer      = require("hs.timer")
local caffeinate = require("hs.caffeinate")

-- -- testing infinite loop detector with debug.sethook

module._loopTimeStamp = os.time()
module._loopTimer = timer.new(5, function() module._loopTimeStamp = os.time() end):start()
module._loopChecker = function(t,l)
    if (os.time() - module._loopTimeStamp) > 30 then
        module._loopTimeStamp = os.time()
        error("timeout -- infinite loop somewhere?\n\n"..debug.traceback())
    end
end

module._loopSleepWatcher = caffeinate.watcher.new(function(event)
    if event == caffeinate.watcher.systemDidWake then
        module._loopTimeStamp = os.time()
        debug.sethook(module._loopChecker, "", 100)
    elseif event == caffeinate.watcher.systemWillSleep then
        debug.sethook(nil)
    end
end):start()

debug.sethook(module._loopChecker, "", 100)

return module