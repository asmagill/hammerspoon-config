local guitk   = require("hs._asm.guitk")
local image   = require("hs.image")
local inspect = require("hs.inspect")

local finspect = function(...) return (inspect({...}):gsub("%s+", " ")) end

local module = {}

local display = guitk.new{ x = 100, y = 100, h = 100, w = 100 }:show():passthroughCallback(function(...) print(finspect(...)) end)
local manager = guitk.manager.new()
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
    manager:add(guitk.element.button.buttonType(v):title(v):alternateTitle("not " .. v), true)
end

local elements = manager:elements()
local location = manager:elementLocation(elements[#elements])

manager:add(guitk.element.button.buttonWithImage(image.imageFromName(image.systemImageNames.ApplicationIcon)), { x = 0, y = location.y + 2 * location.h })
manager:add(guitk.element.button.buttonWithTitle("buttonWithTitle"))
manager:add(guitk.element.button.buttonWithTitleAndImage("buttonWithTitleAndImage", image.imageFromName(image.systemImageNames.ApplicationIcon)))
manager:add(guitk.element.button.checkbox("checkbox"))
manager:add(guitk.element.button.radioButton("radioButton"))

local manager2 = guitk.manager.new()
manager2:add(guitk.element.button.radioButton("A"))
manager2:add(guitk.element.button.radioButton("B"))
manager2:add(guitk.element.button.radioButton("C"))
manager:add(manager2, true):elementLocation(manager2, { x = 200, y = 200 })

manager:sizeToFit(20, 10)

module.manager  = manager
module.manager2 = manager2

return module
