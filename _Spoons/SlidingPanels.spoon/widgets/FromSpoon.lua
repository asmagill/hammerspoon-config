--
-- function returned takes the following arguments:
--
--  * spoonName    - string
--  * frameDetails - table containing frameDetails describing where to place canvas within panel (see guitk.manager)
--  * spoonConfig  - table
--    * canvas     - string specifying the name of the canvas as stored within the spoon (usually "canvas" or similar)
--    * start      - string naming method to invoke to start/show/build the canvas or function(spoon) ... end which does the starting
--    * vars       - table of key-value pairs for spoon to be set before "start", if present, is invoked
--    * background - a table specifying a canvas element, e.g. a rectangle or an image, to use as the background for the spoon canvas. This can be useful to provide contrast if the spoon's coloring is hard to see against the panel's background.

local guitk  = require("hs._asm.guitk")
local canvas = require("hs.canvas")

return function(name, frameDetails, config)
    local s, spoon = pcall(hs.loadSpoon, name)
    if not s then error(string.format("no spoon with the name %s was found", tostring(name))) end
    config = config or {}

    for k, v in pairs(config.vars or {}) do
        if spoon[k] ~= nil and type(spoon[k]) ~= "function" then
            spoon[k] = v
        else
            hs.printf("~~ FromSpoon SlidingPanels widget: %s is not a valid variable for the %s spoon", k, MASTER_SPOON_NAME)
        end
    end

    local start = config.start
    if type(start) == "string" then
        spoon[start](spoon)
    elseif type(start) == "function" or (getmetatable(start) or {}).__call then
        start(spoon)
    end

    frameDetails = frameDetails or {}
    frameDetails.id = frameDetails.id or name

    local spoonCanvas = spoon[config.canvas or "canvas"]
    local spoonWrapper

    if config.background then
        local spoonCanvasSize = spoonCanvas:size()
        spoonWrapper = guitk.manager.new(spoonCanvasSize)
        spoonWrapper[1] = {
            id           = "background",
            frameDetails = { x = 0, y = 0, h = "100%", w = "100%" },
            _element     = canvas.new{}:insertElement(config.background),
        }
        spoonWrapper[2] = {
            id           = "spoon",
            frameDetails = { x = 0, y = 0, h = "100%", w = "100%" },
            _element     = spoonCanvas,
        }
        frameDetails.h  = frameDetails.h  or spoonCanvasSize.h
        frameDetails.w  = frameDetails.w  or spoonCanvasSize.w

-- The wrappers for canvas's :topLeft, :size, and :frame methods update the frameDetails for the canvas object.
-- If the spoon code changes the frame in any way (timers, changing content, etc.) we need to convert that into
-- a change to the guitk wrapper we've created to allow for the background could be inserted for this widget
-- instead.

        spoonWrapper:frameChangeCallback(function(manager, target)
            -- the spoon only knows about the canvas it created, so that's the only one we need to worry about
            -- in this callback
            if target == spoonCanvas then
                local managerFrameDetails = manager:frameDetails()
                local changedFrame = spoonCanvas:frame()
                -- even without the x and y keys, since guitk imports the table into an NSDictionary, including this key
                -- would cause LuaSkin to treat the partial rect table as a rect, filling in a 0 for the x and y keys.
                changedFrame.__luaSkinType = nil

--        NOTE: GUITK cannot distinguish between a change in size or a change in location or both -- they all
--              generate the same notification.
--
--              For SlidingPanels, it's safe to ignore the x and y components completely -- you're supposed
--              to only move the object by using SlidingPanel methods. However, if you're looking at this code
--              as an example for your own designs, be aware that this callback cannot determine *what* changed
--              unless you've saved the old frame information (frameDetails._effective) for comparison here.
--
--              Hopefully this will all become moot once GUITK is in core and canvas is updated to be more
--              tightly integrated with it.
--
                changedFrame.x, changedFrame.y = nil, nil

                -- change the manager first or you'll get multiple callbacks -- a callback is triggered *only*
                -- when the effective frame changes, not simply because frameDetails was invoked.
                manager:frameDetails(changedFrame)
                manager:elementFrameDetails(spoonCanvas, { x = 0, y = 0, h = "100%", w = "100%" })
            end
        end)
    end

    return (spoonWrapper or spoonCanvas), frameDetails
end
