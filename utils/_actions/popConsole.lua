local noises      = require("hs.noises")
local watchable   = require("hs.watchable")
local window      = require("hs.window")
local application = require("hs.application")
local timer       = require("hs.timer")

local consoleToggleTime = 1.5

local module = {}
module.watchables = watchable.new("popConsole", true)
module.watchables.enabled = true

local prevWindowHolder

local consoleToggleThingy = function()
-- this attempts to keep track of the previously focused window and return us to it
    local conswin = window.get("Hammerspoon Console")
    if conswin and application.get("Hammerspoon"):isFrontmost() then
        conswin:close()
        if prevWindowHolder and #prevWindowHolder:role() ~= 0 then
            prevWindowHolder:becomeMain():focus()
            prevWindowHolder = nil
        end
    else
        prevWindowHolder = window.frontmostWindow()
        hs.openConsole()
    end
end

local startTime = nil

module.callback = function(w)
    if w == 1 then     -- start "sssss" sound
--        hs.redshift.toggleInvert()
--        startTime = timer.secondsSinceEpoch()
----       print(timestamp(), "S")
    elseif w == 2 then -- end "sssss" sound
--        hs.redshift.toggleInvert()
----       print(timestamp(), "s")
--        local duration = timer.secondsSinceEpoch() - startTime
--        if duration >= consoleToggleTime and duration <= (consoleToggleTime + 1) then
--            consoleToggleThingy()
--        end
--        startTime = nil
    elseif w == 3 then -- mouth popping sound
--       print(timestamp(), "pop!")
       consoleToggleThingy()
        startTime = nil
    end
end

module._noiseWatcher = noises.new(module.callback):start()

module.toggleForWatchablesEnabled = watchable.watch("popConsole.enabled", function(w, p, i, oldValue, value)
    if value then
        module._noiseWatcher:start()
    else
        module._noiseWatcher:stop()
    end
end)

local caffeinate = require("hs.caffeinate")
-- the listener can prevent or delay system sleep, so disable as appropriate
module.watchCaffeinatedState = watchable.watch("generalStatus.caffeinatedState", function(w, p, i, old, new)
--     print(string.format("~~~ %s popConsole caffeinatedWatcher called with %s (%d), was %s (%d), currently %s", timestamp(), caffeinate.watcher[new], new, caffeinate.watcher[old], old, module.watchables.enabled))
    if new == 1 or new == 10 then -- systemWillSleep or screensDidLock
        module.watchables.enabled = false
    elseif new == 0 or new == 11 then -- systemDidWake or screensDidUnlock
        module.watchables.enabled = true
    end
end)

return setmetatable(module, { __tostring = function(self)
    return "Adjust with `self`.watchables.enabled or using hs.watchables with path 'popConsole.enabled'"
end })
