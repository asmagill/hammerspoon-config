--
-- CircleClock widget for SlidingPanels spoon
--
-- This widget uses the CircleClock spoon as a widget
--

-- A widget is composed of two values:
--    * the userdata element representing the widget
--      * currently only `hs.canvas`, `hs._asm.guitk.manager`, and `hs._asm.guitk.element.*` submodules are supported
--    * a table containing frame detail properties as defined for `hs._asm.guitk.manager:elementFrameDetails` or nil
--
-- A widget definition file (like this one) should either return the two values defined above
-- (e.g. `return element, details`) or a function which will be invoked with additional arguments provided
--  by `SlidingPanel:panel("name"):addWidget("widget", ...)`; the function should return the two values
-- defined above when invoked.

local MASTER_SPOON_NAME   = "CircleClock" -- name of the spoon we are "borrowing" the canvas from
local MASTER_SPOON_CANVAS = "canvas"      -- name of the field in the spoon which contains the canvas element

local guitk  = require("hs._asm.guitk")
local canvas = require("hs.canvas")

-- adding a face like this works well because the spoon clock never changes its size once created, and it couldn't be
-- injected into the spoon canvas itself because the spoon uses index numbers rather then id names to identify the
-- changing position of the "hands"
--
-- this wouldn't work well with HCalendar since its size changes to accommodate changing month length

return function(frameDetails, faceColor)
    frameDetails = frameDetails or {}
    faceColor    = faceColor    or { red = .4, blue = .32, green = .32, alpha = .7 }

    local spoonCanvas     = hs.loadSpoon(MASTER_SPOON_NAME)[MASTER_SPOON_CANVAS]
    local spoonCanvasSize = spoonCanvas:size()

    local element = guitk.manager.new(spoonCanvasSize)
    element[1] = {
        id           = "clockFace",
        frameDetails = { x = 0, y = 0, h = "100%", w = "100%" },
        _element     = canvas.new{}:insertElement{
            type             = "rectangle",
            action           = "fill",
            roundedRectRadii = { xRadius = 20, yRadius = 20 },
            fillColor        = faceColor,
        },
    }
    element[2] = {
        id           = "spoonCanvas",
        frameDetails = { x = 0, y = 0, h = "100%", w = "100%" },
        _element     = spoonCanvas,
    }

    frameDetails.id = frameDetails.id or MASTER_SPOON_NAME
    frameDetails.h  = frameDetails.h  or spoonCanvasSize.h
    frameDetails.w  = frameDetails.w  or spoonCanvasSize.w
    return element, frameDetails
end
