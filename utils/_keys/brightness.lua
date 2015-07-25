local module = {
--[=[

Sample code showing the use of eventtap to capture Screen Brightness keys and tie a
filter (black rectangle with changing alpha value) to it for external monitors with
a laptop.

Ideas for expansion --
    non-linear changes to alpha
    set color other than black for a "tint"
    per monitor differences
    pass-in/change name of reference (i.e. laptop) monitor
    changes over time that affect both laptop and monitors

--]=]
}

-- private variables and methods -----------------------------------------

-- change this to the name of your laptop LCD (the one which reports brightness)
-- probably should make this settable at load time, but this is a sample, not a finished
-- product.
local LaptopLCD   = "Color LCD"
local verbose     = false

local brightness  = require("hs.brightness")
local eventtap    = require("hs.eventtap")
local events      = eventtap.event
local space       = require("hs.spaces")
local screen      = require("hs.screen")
local drawing     = require("hs.drawing")

local myScreens = {}

-- defined out here, because we call it before relegating it to the watcher...
local screenWatchFunction = function()
    if verbose then print("++ screenChange",os.date()) end

    local currentScreens = screen.allScreens()
    local brightnessSetting = 1 - (brightness.get()/100)

    -- remove no longer existant screens
    for i,v in pairs(myScreens) do
        local found = false
        for j,k in ipairs(currentScreens) do
            if i == k:id() then
                found = true
                break
            end
        end
        if not found then
            myScreens[i].filter:delete()
            myScreens[i] = nil
        end
    end

    -- add new or update changed screens
    for i,v in ipairs(currentScreens) do
        local rect = v:fullFrame()
        local tag  = v:id()
        if not myScreens[tag] then
            if v:name() ~= LaptopLCD then
                myScreens[tag] = {
                    rect = rect,
                    filter = drawing.rectangle(rect):setStroke(false):setFill(true):
                                setFillColor{red=0, green=0, blue=0, alpha = brightnessSetting}:
                                setBehaviorByLabels{"canJoinAllSpaces", "stationary"}:show(),
                }
            end
        else
            if rect.x ~= myScreens[tag].rect.x or rect.y ~= myScreens[tag].rect.y or
               rect.h ~= myScreens[tag].rect.h or rect.w ~= myScreens[tag].rect.w then
                myScreens[tag].rect = rect
                myScreens[tag].filter:setFrame(rect):show()
            end
        end
    end
end

-- Public interface ------------------------------------------------------

screenWatchFunction() -- run the first time to setup any existing external monitors

-- now setup the watcher to detect when screens change...

module.screenWatcher = screen.watcher.new(screenWatchFunction):start()

-- not needed if hs.drawing.setBehavior is accepted into core...
--module.spaceWatcher = space.watcher.new(function(obj)
--    if verbose then print("++ spaceChange",os.date()) end
--    for i,v in pairs(myScreens) do
--        v.filter:hide():show()
--    end
--end)
--module.spaceWatcher:start()


-- We do this because starting any eventtap before accessibility is enabled causes eventtaps which
-- require keyUp/Down events to fail, even after accessibility is enabled until Hammerspoon is fully
-- quit and restarted... probably not a huge issue to most, but I rebuild HS a lot...
module.eventtap = hs.timer.new(1, function()
        if hs.accessibilityState() then
            module.eventtap:stop()
            print("++ Starting brightness eventtap")
            module.eventtap = eventtap.new({events.types.NSSystemDefined}, function(obj)
                local sysKey = obj:systemKey()

                -- exit ASAP if it isn't of interest to us
                if not next(sysKey) then return false end
                if sysKey.key ~= "BRIGHTNESS_UP" and sysKey.key ~= "BRIGHTNESS_DOWN" then return false end

                -- because receiving the event means it hasn't been processed yet, the keyDown and repeat
                -- events will always mean that the non-laptop monitors are a step behind the brightness the
                -- laptop screen is going to be (when the event is passed on)... by doing this even for
                -- keyDown == false, the key release will bring the external monitors in sync.

                -- in hotkey parlance (where this may ultimately go, or at least a wrapper made), same
                -- action for down, up, and repeat.

                local brightnessSetting = 1 - (brightness.get()/100)
                for i,v in pairs(myScreens) do
                    v.filter:setFillColor{red=0, green=0, blue=0, alpha = brightnessSetting}
                end

                return false -- allow event to fall through and do what it's gotta do
            end):start()
        end
    end):start()


-- Return Module Object --------------------------------------------------
module.myScreens = myScreens

return module
