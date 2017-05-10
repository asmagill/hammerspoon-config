local noises      = require("hs.noises")
local watchable   = require("hs.watchable")
local window      = require("hs.window")
local application = require("hs.application")
local timer       = require("hs.timer")

local module = {}
module.watchables = watchable.new("popConsole", true)
module.watchables.enabled = true

module.popTimeout = 1
module.debug   = false

local prevWindowHolder

local popTimer
local popCount = 0

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

local handlePops = function()
    if module.debug then hs.printf("~~ heard %d pop(s) in %d second(s)", popCount, module.popTimeout) end
    if popCount == 2 then
        consoleToggleThingy()
    end
    popTimer = nil
    popCount = 0
end

local consolePopWatcher = function()
    if not popTimer then
        popTimer = timer.doAfter(module.popTimeout, handlePops)
    end
    popCount = popCount + 1
end

module.callback = function(w)
    if w == 1 then     -- start "sssss" sound
    elseif w == 2 then -- end "sssss" sound
    elseif w == 3 then -- mouth popping sound
        consolePopWatcher()
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
        module.wasActive = module.watchables.enabled
        module.watchables.enabled = false
    elseif new == 0 or new == 11 then -- systemDidWake or screensDidUnlock
        if type(module.wasActive) == "boolean" then
            module.watchables.enabled = module.wasActive
        else
            module.watchables.enabled = true
        end
    end
end)

return setmetatable(module, { __tostring = function(self)
    return "Adjust with `self`.watchables.enabled or using hs.watchables with path 'popConsole.enabled'"
end })
