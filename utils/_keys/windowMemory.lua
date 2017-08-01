local mods           = require("hs._asm.extras").mods
local hotkey         = require("hs.hotkey")
local fnutils        = require("hs.fnutils")
local mouse          = require("hs.mouse")
local geometry       = require("hs.geometry")
local window         = require("hs.window")
local alert          = require("hs.alert")

local alertStyle = { fillColor = { blue = .6, green = .5 } }

local pickWindow = function()
    return window.frontmostWindow()
--     return fnutils.find(window.orderedWindows(), function(_)
--         return geometry.isPointInRect(mouse.getAbsolutePosition(), _:frame()) and _:isStandard()
--     end)
end

local _firstTime = true

local module = {}
module._savedWindows = {}

local saveWindow = function(key)
    local win = pickWindow()
    if win then
        module._savedWindows[key] = win
        local app = win:application():name() or "<no-app>"
        local win = win:title()              or "<no-title>"
        alert(app .. ":" .. win .. " saved to slot " .. tostring(key), alertStyle)
    else
        alert("Unable to get window object", alertStyle)
    end
end

local gotoWindow = function(key)
    local win = module._savedWindows[key]
    if win then
        if win:role() ~= "" then
            win:focus()
        else
            module._savedWindows[key] = nil
            alert("Window in slot " .. tostring(key) .. " is no longer valid", alertStyle)
        end
    else
        alert("No window saved in slot " .. tostring(key), alertStyle)
    end
end

module._keys = hotkey.modal.new()
module._keys.entered = function(self)
    if not _firstTime then
        alert("Window slot saver enable", alertStyle)
        _firstTime = false
    end
end
for i = 0, 9, 1 do
    module._keys:bind(mods.CASC, tostring(i), function() saveWindow(i) end)
    module._keys:bind(mods.CAsC, tostring(i), function() gotoWindow(i) end)
end
module._keys.exited = function(self)
    alert("Window slot saver disabled", alertStyle)
end

module.start = function() module._keys:enter() end
module.stop  = function() module._keys:exit()  end

module.start()

return module
