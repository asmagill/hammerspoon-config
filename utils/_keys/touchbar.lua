
--
-- Sample Use of hs._asm.undocumented.touchbar
--
-- Copy this file into your ~/.hammerspoon/ directory and then type (or add to your init.lua) the
-- following: myToolbar = require("touchbar")
--
--
-- This example uses the hs._asm.undocumented.touchbar module to create an on-screen visible representation of the
-- Apple Touch Bar on your screen.
--
-- When you press and hold the right Option key for at least 2 seconds, the touch bar's visibility
-- will toggle.  When the touch bar becomes visible, it will appear centered at the bottom of your
-- main screen.
--
-- While the touch bar is visible, if you move your mouse pointer within the bounds of the visible
-- touch bar window and then press and hold the left Option key, you can then click and drag the
-- touch bar to another location on the screen.  Release the option key to start using it again.
--

local module   = {}

-- set the amount of time the right opt has to be down with no other interrupting events
module.rightOptPressTime = 2

-- set the "normal" border
module.normalBorderColor = { white = 0 }

-- set the "movable" border
module.movableBorderColor = { red = 1 }

-- set the default inactiveAlpha
module.inactiveAlpha = .4

local touchbar = require("hs._asm.undocumented.touchbar")
local eventtap = require("hs.eventtap")
local timer    = require("hs.timer")
local screen   = require("hs.screen")

local events   = eventtap.event.types

local showMovableState = function()
    module.touchbar:backgroundColor(module.movableBorderColor)
                   :movable(true)
                   :acceptsMouseEvents(false)
end

local showNormalState = function()
    module.touchbar:backgroundColor(module.normalBorderColor)
                   :movable(false)
                   :acceptsMouseEvents(true)
end

local mouseInside = false
local touchbarWatcher = function(obj, message)
    if message == "didEnter" then
        mouseInside = true
    elseif message == "didExit" then
        mouseInside = false
    -- just in case we got here before the eventtap returned the touch bar to normal
        showNormalState()
    end
end

local createTouchbarIfNeeded = function()
    if not module.touchbar then
        module.touchbar = touchbar.new():inactiveAlpha(module.inactiveAlpha)
                                        :setCallback(touchbarWatcher)
        showNormalState()
    end
end

-- should add a cleaner way to detect right modifiers then checking their flags, but for now,
-- ev:getRawEventData().CGEventData.flags  & 0xdffffeff == 524352 works for right alt, 524320 for left alt
--
-- You can check for others with this in the console:
--  a = hs.eventtap.new({12}, function(e) print(hs.inspect(e:getFlags()),e:getRawEventData().CGEventData.flags & 0xdffffeff) ; return false end):start()
--
-- This filters out what appears to be a "this is a synthesized event" bit (0x20000000) and the
-- non-coallesced bit (0x100), because these are beyond our control

local rightOptPressed = false

local initialFrame = { x = 0, y = 0 }

-- might want to call this from the "outside" of our normal watcher
module.toggle = function()
    createTouchbarIfNeeded()
    module.touchbar:toggle()
    if module.touchbar:isVisible() then
        module.touchbar:centered()
        initialFrame = module.touchbar:getFrame()
        module.screenWatcher:start()
    else
        module.screenWatcher:stop()
    end
end

-- we only care about events other than flagsChanged that should *stop* a current count down
module.eventwatcher = eventtap.new({events.flagsChanged, events.keyDown, events.leftMouseDown}, function(ev)
    -- synthesized events set 0x20000000 and we may or may not get the nonCoalesced bit, so filter them out
    local rawFlags = ev:getRawEventData().CGEventData.flags & 0xdffffeff
--    print(rawFlags)
    rightOptPressed = false
    if ev:getType() == events.flagsChanged and rawFlags == 524352 then
        rightOptPressed = true
        module.countDown = timer.doAfter(module.rightOptPressTime, function()
            if rightOptPressed then module.toggle() end
        end)
    else
        if module.countDown then
            module.countDown:stop()
            module.countDown = nil
        end
        if mouseInside then
            if ev:getType() == events.flagsChanged and rawFlags == 524320 then
                showMovableState()
            elseif ev:getType() ~= events.leftMouseDown then
                showNormalState()
            end
        end
    end
    return false
end):start()

module.screenWatcher = screen.watcher.newWithActiveScreen(function(flag)
    if module.touchbar:isVisible() then
        local currentFrame = module.touchbar:getFrame()
        if currentFrame.x == initialFrame.x and currentFrame.y == initialFrame.y then
            module.touchbar:centered()
            initialFrame = module.touchbar:getFrame()
        end
    end
end)

return module
