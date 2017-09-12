local guitk = require("hs._asm.guitk")
local timer = require("hs.timer")

local module = {}

local gui = guitk.new{ x = 100, y = 100, h = 84, w = 204 }:show()
local manager = guitk.manager.new()
gui:contentManager(manager)

local backgroundSpinner = guitk.element.progress.new():circular(true):start()
local foregroundSpinner = guitk.element.progress.new():circular(true):threaded(false):start()
local backgroundBar     = guitk.element.progress.new():start()
local foregroundBar     = guitk.element.progress.new():threaded(false):start()


local hoursBar   = guitk.element.progress.new():min(0):max(23):indeterminate(false):indicatorSize("small"):color{ red   = 1 }
local minutesBar = guitk.element.progress.new():min(0):max(60):indeterminate(false):indicatorSize("small"):color{ green = 1 }
local secondsBar = guitk.element.progress.new():min(0):max(60):indeterminate(false):indicatorSize("small"):color{ blue  = 1 }

manager:add(backgroundBar,     { x =  10, y = 10, h = 20, w = 184 })
manager:add(backgroundSpinner, { x =  10, y = 30, h = 32, w =  32 })
manager:add(foregroundSpinner, { x = 162, y = 30, h = 32, w =  32 })
manager:add(hoursBar,          { x =  42, y = 28, h = 12, w = 120 })
manager:add(minutesBar,        { x =  42, y = 40, h = 12, w = 120 })
manager:add(secondsBar,        { x =  42, y = 52, h = 12, w = 120 })
manager:add(foregroundBar,     { x =  10, y = 64, h = 20, w = 184 })


local updateTimeBars = function()
    local t = os.date("*t")
    hoursBar:value(t.hour)
    minutesBar:value(t.min)
    secondsBar:value(t.sec)
end

module.timer   = timer.doEvery(1, updateTimeBars):start()
module.manager = manager

updateTimeBars()

return module

