local guitk   = require("hs._asm.guitk")
local image   = require("hs.image")
local inspect = require("hs.inspect")

local finspect = function(...) return (inspect({...}):gsub("%s+", " ")) end

local module = {}

local display = guitk.new{ x = 100, y = 100, h = 100, w = 100 }:show()
local manager = guitk.manager.new():passthroughCallback(function(...) print(finspect(...)) end)
display:contentManager(manager)

local types = {
    "momentaryLight",
    "toggle",
    "switch",
    "radio",
    "momentaryChange",
    "multiLevelAccelerator",
    "onOff",
    "pushOnPushOff",
    "accelerator",
    "momentaryPushIn"
}

for i, v in ipairs(types) do
    manager:add(guitk.element.button.buttonType(v):title(v), true)
end

local elements = manager:elements()
local location = manager:elementLocation(elements[#elements])

manager:add(guitk.element.button.buttonWithImage(image.imageFromName(image.systemImageNames.ApplicationIcon)), { x = 0, y = location.y + 2 * location.h })
manager:add(guitk.element.button.buttonWithTitle("buttonWithTitle"))
manager:add(guitk.element.button.buttonWithTitleAndImage("buttonWithTitleAndImage", image.imageFromName(image.systemImageNames.ApplicationIcon)))
manager:add(guitk.element.button.checkbox("checkbox"))
manager:add(guitk.element.button.radioButton("radioButton"))

manager:shrinkToFit(20, 10)

module.manager = manager

return module
