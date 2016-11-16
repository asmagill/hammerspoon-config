
local module   = {}
local touchbar = require("hs._asm.touchbar")
local eventtap = require("hs.eventtap")
local timer    = require("hs.timer")

local events   = eventtap.event.types

local createTouchbarIfNeeded = function()
    if not module.touchbar then
        module.touchbar = touchbar.new():centered()
    end
end

-- should add a cleaner way to detect right modifiers then checking their flags, but for now,
-- ev:getRawEventData().CGEventData.flags == 524608 works for right alt
-- You can check for others with this in the console:
--  a = hs.eventtap.new({12}, function(e) print(inspect(e:getFlags()), inspect(e:getRawEventData())) ; return false end):start()

module.rightOptPressed   = false
module.rightOptPressTime = 2

-- we only care about events other than flagsChanged that should *stop* a current count down
module.eventwatcher = eventtap.new({events.flagsChanged, events.keyDown, events.leftMouseDown}, function(ev)
    module.rightOptPressed = false
    if ev:getType() == events.flagsChanged and ev:getRawEventData().CGEventData.flags == 524608 then
        module.rightOptPressed = true
        module.countDown = timer.doAfter(module.rightOptPressTime, function()
            if module.rightOptPressed then
                createTouchbarIfNeeded()
                module.touchbar:toggle()
            end
        end)
    else
        if module.countDown then
            module.countDown:stop()
            module.countDown = nil
        end
    end
    return false
end):start()

module.toggle = function()
    createTouchbarIfNeeded()
    module.touchbar:toggle()
end

return module
