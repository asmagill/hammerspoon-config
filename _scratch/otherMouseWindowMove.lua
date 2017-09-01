-- alternative to https://github.com/Hammerspoon/hammerspoon/issues/1519

local eventtap = require("hs.eventtap")
local window   = require("hs.window")
local geometry = require("hs.geometry")
local mouse    = require("hs.mouse")
local fnutils  = require("hs.fnutils")
local screen   = require("hs.screen")
local alert    = require("hs.alert")

local eventTypes = eventtap.event.types
local eventProps = eventtap.event.properties

local function get_window_under_mouse()
    local my_pos    = geometry.new(mouse.getAbsolutePosition())
    local my_screen = mouse.getCurrentScreen()
    local myWindow  = nil

    -- some windows don't appear in `hs.window.orderedWindows` because of their style or application type
    -- this allows us to use the Cmd key as a way to say use the topmost window rather then try to figure
    -- out which window is beneath the current mouse position
    if eventtap.checkKeyboardModifiers().cmd then
        myWindow = window.frontmostWindow()
    else
        myWindow = fnutils.find(window.orderedWindows(), function(w)
            return my_screen == w:screen() and my_pos:inside(w:frame())
        end)
    end
    return myWindow
end

-- establish these as local, since we need to set them in the callback but have them persist between multiple callbacks
local targetWindow, targetTopLeft = nil, nil

eventtapOtherMouseDragged = eventtap.new( {
    eventTypes.otherMouseDown, eventTypes.otherMouseUp, eventTypes.otherMouseDragged
}, function(event)
    -- we only want to override the third mouse button; if they have more, let those procede normally
    if event:getProperty(eventProps.mouseEventButtonNumber) == 2 then
        local receivedEvent = event:getType()
        if receivedEvent == eventTypes.otherMouseDown then
            targetWindow = get_window_under_mouse()
            if targetWindow then
                alert("Target Window: " .. (targetWindow:title() or "<no-title>"))
                targetTopLeft = targetWindow:topLeft()
            else
                alert("no window at current mouse location")
            end
        elseif receivedEvent == eventTypes.otherMouseUp then
            targetWindow = nil
        elseif receivedEvent == eventTypes.otherMouseDragged then
            if targetWindow then
                local dx = event:getProperty(eventProps.mouseEventDeltaX)
                local dy = event:getProperty(eventProps.mouseEventDeltaY)
                targetTopLeft = { x = targetTopLeft.x + dx, y = targetTopLeft.y + dy }
                targetWindow:setTopLeft(targetTopLeft)
            end
        else
            -- this should never happen
            alert("unexpected event: " .. (eventTypes[receivedEvent] or ("eventID " .. tostring(receivedEvent))))
            return false
        end
        return true
    else
        return false
    end
end):start()
