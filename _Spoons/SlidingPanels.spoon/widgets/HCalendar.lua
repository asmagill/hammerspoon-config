--
-- HCalendar widget for SlidingPanels spoon
--
-- This widget uses the HCalendar spoon as a widget
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

local MASTER_SPOON_NAME   = "HCalendar" -- name of the spoon we are "borrowing" the canvas from
local MASTER_SPOON_CANVAS = "canvas"    -- name of the field in the spoon which contains the canvas element

return function(frameDetails)
    frameDetails = frameDetails or {}
    frameDetails.id = frameDetails.id or MASTER_SPOON_NAME
    return hs.loadSpoon(MASTER_SPOON_NAME)[MASTER_SPOON_CANVAS], frameDetails
end
