local guitk      = require("hs._asm.guitk")
local styledtext = require("hs.styledtext")

local module = {}

local gui = guitk.new{x = 100, y = 100, h = 300, w = 300 }:show()
local manager = guitk.manager.new()
gui:contentManager(manager)

manager:add(guitk.element.textfield.newLabel("I am a label, not selectable"))
manager:add(guitk.element.textfield.newLabel(styledtext.new({
    "I am a StyledText selectable label",
    { starts = 8,  ends = 13, attributes = { color = { red  = 1 }, font = { name = "Helvetica-Bold", size = 12 } } },
    { starts = 14, ends = 17, attributes = { color = { blue = 1 }, font = { name = "Helvetica-Oblique", size = 12 } } },
    { starts = 19, ends = 28, attributes = { strikethroughStyle = styledtext.lineAppliesTo.word | styledtext.lineStyles.single } },
})))
manager:add(guitk.element.textfield.newTextField("I am a text field"))
manager:add(guitk.element.textfield.newWrappingLabel("I am a wrapping label\nthe only difference so far is that I'm selectable"))


module.manager = manager

return module
