local module = {
--[=[
    _NAME        = 'hydra.lua',
    _VERSION     = '0.1',
    _URL         = 'https://github.com/asmagill/hammerspoon-config',
    _DESCRIPTION = [[ personal keybindings for hammerspoon ]],
    _TODO        = [[]],
    _LICENSE     = [[ See README.md ]]
--]=]
}

-- private variables and methods -----------------------------------------

local hotkey        = hs.hotkey
local mods          = require("hs._asm.extras").mods
local window        = hs.window
local fnutils       = hs.fnutils
local mouse         = hs.mouse
local alert         = hs.alert
local pasteboard    = hs.pasteboard
local devinfo       = require("utils.dev_info")

local point_in_rect = function(rect, point)
    return  point.x >= rect.x and
            point.y >= rect.y and
            point.x <= rect.x + rect.w and
            point.y <= rect.y + rect.h
end

local window_underneath_mouse = function()
    local pos = mouse.get()
    local win = fnutils.find(window.orderedWindows(), function(window)
        return point_in_rect(window:frame(), pos)
    end)
    return win or window.windowForID(0) or window.windowForID(nil)
end

local dev = hotkey.modal.new(mods.CAsC, "=")
     dev:bind(mods.Casc, "C",
        function()
            dev.clipboard = not dev.clipboard
            print("-- Clipping ----------------------------")
            print("Save to Clipboard = "..tostring(dev.clipboard))
            print("----------------------------------------")
        end
    )
    dev:bind(mods.casc, "W",
        function()
            local win = window_underneath_mouse()
            print("-- Window ------------------------------")
            print(devinfo.wininfo(win,dev.clipboard))
            print("----------------------------------------")
        end
    )
    dev:bind(mods.casc, "A",
        function()
            local win = window_underneath_mouse()
            print("-- Application -------------------------")
            print(devinfo.appinfo(win:application(),dev.clipboard))
            print("----------------------------------------")
        end
    )
    dev:bind(mods.casc, "M",
        function()
            local win = window_underneath_mouse()
            print("-- Monitor -----------------------------")
            print(devinfo.screeninfo(win:screen(),dev.clipboard))
            print("----------------------------------------")
        end
    )
--    dev:bind(mods.casc, "S",
--        function()
--            print(devinfo.spaceinfo(dev.clipboard))
--        end
--    )
    dev:bind(mods.casc, "B",
        function()
            print("-- Battery -----------------------------")
            print(devinfo.batteryinfo(dev.clipboard))
            print("----------------------------------------")
        end
    )
    dev:bind(mods.casc, "I",
        function()
            local results = devinfo.audioinfo(false).."\r"
                            ..devinfo.mouseinfo(false).."\r"
                            ..devinfo.brightnessinfo(false)
            print("-- Info --------------------------------")
            print(results)
            print("----------------------------------------")
            if dev.clipboard then
                pasteboard.setcontents(results)
            end
        end
    )
    dev:bind(mods.Casc, "V",
        function()
            print("-- Clipboard Contents ------------------")
            print(pasteboard.getcontents())
            print("----------------------------------------")
        end
    )

    function dev:entered()
        alert.show("Entering Information Mode")
        dev.clipboard = false
    end
    function dev:exited()
        alert.show("Leaving Information Mode")
        dev.clipboard = false
    end
dev:bind(mods.casc, "ESCAPE", function() dev:exit() end)

-- Public interface ------------------------------------------------------
-- Return Module Object --------------------------------------------------

return module
