--
-- uses debug.sethook and a timer to break out of infinite loops in lua code within Hammerspoon
--
-- Haven't had any problems with it or false positives, but YMMV -- standard disclaimers, etc.
--
-- Updates 2015-12-21:
--      should play nicely with other hooks by storing info about it and chaining
--      you can force an "immediate" break by holding down CMD-CTRL-SHIFT-ALT-CAPSLOCK-FN all at once
--          you'll need to remove "and mods.fn" where noted below if your keyboard does not have this
--          modifier (non-laptops, I suspect)
--
-- See https://gist.github.com/asmagill/cf1d6398aecc2cee37af for additional release notes
--
-- You can disable this (and all debug hooks) at any time by typing `debug.sethook(nil)` into the
-- Hammerspoon Console.

local module = {}

local timer      = require("hs.timer")
-- local caffeinate = require("hs.caffeinate")
local eventtap   = require("hs.eventtap")

-- -- testing infinite loop detector with debug.sethook

local lastFn, lastMask, lastCount = debug.gethook()

local setHook = function(ourFn, ourMask, ourCount)
    if ourFn then
        lastFn, lastMask, lastCount = debug.gethook()
        if lastCount > 0 and lastCount < ourCount then ourCount = lastCount end
        for i = 1, #lastMask, 1 do
            if not ourMask:match(lastMask:sub(i,i)) then
                ourMask = ourMask..lastMask:sub(i,i)
            end
        end
--     print("*** setting Hook:", ourFn, ourMask.."("..#ourMask..")", ourCount)
        debug.sethook(ourFn, ourMask, ourCount)
    else
        debug.sethook(lastFn, lastMask, lastCount)
    end
end

-- module._loopTimeStamp = os.time()
-- module._loopTimer = timer.new(5, function() module._loopTimeStamp = os.time() end):start()
module._loopChecker = function(t,l)
    if lastFn then lastFn(t, l) end
--     if (os.time() - module._loopTimeStamp) > 60 then
--         module._loopTimeStamp = os.time()
--         error("*** timeout -- infinite loop somewhere?\n\n"..debug.traceback(), 0)
--     end
    local mods = eventtap.checkKeyboardModifiers()
-- remove "and mods.fn" if your keyboard does not have this key (non laptops most likely)
    if mods.capslock and mods.fn and mods.cmd and mods.ctrl and mods.alt and mods.shift then
        error("*** forced break\n\n"..debug.traceback(), 0)
    end
end

-- module._loopSleepWatcher = caffeinate.watcher.new(function(event)
--     if event == caffeinate.watcher.systemDidWake then
--         module._loopTimeStamp = os.time()
--         setHook(module._loopChecker, "", 1000)
--     elseif event == caffeinate.watcher.systemWillSleep then
--         setHook(nil)
--     end
-- end):start()

setHook(module._loopChecker, "", 100)

return module
