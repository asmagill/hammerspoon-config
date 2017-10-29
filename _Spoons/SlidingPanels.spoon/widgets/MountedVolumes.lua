--
-- MountedVolumes widget for SlidingPanels spoon
--
-- This widget uses the MountedVolumes spoon as a widget
--
-- Add this to your sliding panel with :addWidget("mountedVolumes", [frameDetails], [additionalVariables])
-- e.g. `slidingPanels:panel("infoPanel"):addWidget("mountedVolumes", { x = 0, bY = 0 }, { growsDownwards = false })``

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

local MASTER_SPOON_NAME   = "MountedVolumes" -- name of the spoon we are "borrowing" the canvas from
local MASTER_SPOON_CANVAS = "canvas"    -- name of the field in the spoon which contains the canvas element

return function(frameDetails, additionalVariables)
    frameDetails = frameDetails or {}
    frameDetails.id = frameDetails.id or MASTER_SPOON_NAME

    additionalVariables = additionalVariables or {}

    local spoon = hs.loadSpoon(MASTER_SPOON_NAME)
    for k, v in pairs(additionalVariables) do
        if spoon[k] ~= nil and type(spoon[k]) ~= "function" then
            spoon[k] = v
        else
            hs.printf("~~ %s widget: %s is not a valid variable for the spoon", MASTER_SPOON_NAME, k)
        end
    end
    return spoon:show()[MASTER_SPOON_CANVAS], frameDetails
end
