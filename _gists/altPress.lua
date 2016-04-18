local alert    = require("hs.alert")
local timer    = require("hs.timer")
local eventtap = require("hs.eventtap")

local events   = eventtap.event.types

local module   = {}

-- You either override these here or after including this file from another, e.g.
--
-- altHold = require("altHold")
-- altHold.timeFrame = 2
-- altHold.action = function()
--    do something special
-- end

-- how long must the alt key be held?
module.timeFrame = 2

-- what to do when the alt key has been held that long
module.action = function()
    alert("You held the Alt/Option key!")
end


-- Synopsis:

-- what we're looking for is the alt key down event and no other
-- key or flag change event before the specified time has passed

-- verify that *only* the ctrl key flag is being pressed
local onlyAlt = function(ev)
    local result = ev:getFlags().alt
    for k,v in pairs(ev:getFlags()) do
        if k ~= "alt" and v then
            result = false
            break
        end
    end
    return result
end

module.eventwatcher = eventtap.new({events.flagsChanged, events.keyDown}, function(ev)
    -- if we're called and a time is running, something changed -- unset the timer
    if module.countDownTimer then
        module.countDownTimer:stop()
        module.countDownTimer = nil
    end

    if ev:getType() == events.flagsChanged then
        if onlyAlt(ev) then
            module.countDownTimer = timer.doAfter(module.timeFrame, function()
                module.countDownTimer = nil
                if module.action then module.action() end
            end)
        end
    end

    return false ;
end):start()
