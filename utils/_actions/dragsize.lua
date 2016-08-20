-- modified from code found at https://gist.github.com/kizzx2/e542fa74b80b7563045a

-- local application = require("hs.application")
local window   = require("hs.window")
local geometry = require("hs.geometry")
local fnutils  = require("hs.fnutils")
local mouse    = require("hs.mouse")
local eventtap = require("hs.eventtap")
local hotkey   = require("hs.hotkey")
local timer    = require("hs.timer")

local module = {}

local function get_window_under_mouse()
    local my_pos = geometry.new(mouse.getAbsolutePosition())
    local my_screen = mouse.getCurrentScreen()


    local myWindow

    if eventtap.checkKeyboardModifiers().cmd then
        myWindow = fnutils.find(window.orderedWindows(), function(w)
            return my_screen == w:screen() and my_pos:inside(w:frame())
        end)
    else
        myWindow = window.frontmostWindow()
    end

    if myWindow then
        module.savedWindow = myWindow
        module.savedFrame  = myWindow:frame()
    end
    return myWindow
end

local resetDraggingInfo = function()
    if module.dragging_win then
        module.escapeKey = hotkey.bind({}, "escape", function()
            if module.savedWindow then
                module.savedWindow:setFrame(module.savedFrame)
                module.escapeKey:disable()
                if module.removeEscapeKey then module.removeEscapeKey:stop() end
                module.savedWindow     = nil
                module.savedFrame      = nil
                module.escapeKey       = nil
                module.removeEscapeKey = nil
            end
        end)
        module.removeEscapeKey = timer.doAfter(1, function()
            if module.escapeKey then module.escapeKey:disable() end
            module.savedWindow     = nil
            module.savedFrame      = nil
            module.escapeKey       = nil
            module.removeEscapeKey = nil
        end)
    end
    module.dragging_win = nil
    module.dragging_mode = 0
    module.drag_event:stop()
end

module.dragging_win  = nil
module.dragging_mode = 0

module.drag_event = eventtap.new({ eventtap.event.types.mouseMoved }, function(e)
    if module.dragging_win then
        local dx = e:getProperty(eventtap.event.properties.mouseEventDeltaX)
        local dy = e:getProperty(eventtap.event.properties.mouseEventDeltaY)

        if module.dragging_mode == 0 then
            resetDraggingInfo()
        elseif module.dragging_mode == 1 then
            module.dragging_win:move({dx, dy}, nil, false, 0)
        elseif module.dragging_mode == 2 then
            local sz = module.dragging_win:_size()
            module.dragging_win:_setSize({ w = sz.w + dx, h = sz.h + dy })
        end
    end
    return nil
end)

module.flags_event = eventtap.new({ eventtap.event.types.flagsChanged }, function(e)
    local flags = e:getFlags()

    if flags.alt and flags.shift and module.dragging_win == nil then
        module.dragging_win = get_window_under_mouse()
        if module.dragging_win then
            module.dragging_mode = 1
            module.drag_event:start()
        end
    elseif flags.ctrl and flags.shift and module.dragging_win == nil then
        module.dragging_win = get_window_under_mouse()
        if module.dragging_win then
            module.dragging_mode = 2
            module.drag_event:start()
        end
    else
        if module.dragging_win then resetDraggingInfo() end
    end
    return nil
end)
module.flags_event:start()

return module
