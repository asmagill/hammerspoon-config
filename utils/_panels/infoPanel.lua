local slidingPanels = hs.loadSpoon("SlidingPanels")

slidingPanels:addPanel("infoPanel", {
    side              = "top",
    size              = 1/3,
    modifiers         = { "fn" },
    persistent        = true,
    animationDuration = 0.1,
    color             = { white = .35 },
    fillAlpha         = .95,
}):enable()

-- the "FromSpoon" widget takes the following arguments:
--
--  * spoonName    - string
--  * frameDetails - table containing frameDetails describing where to place canvas within panel (see guitk.manager)
--  * spoonConfig  - table
--    * canvas     - string specifying the name of the canvas as stored within the spoon (usually "canvas" or similar)
--    * start      - string naming method to invoke to start/show/build the canvas or function(spoon) ... end which does the starting
--    * vars       - table of key-value pairs for spoon to be set before "start", if present, is invoked
--    * background - a table specifying a canvas element, e.g. a rectangle or an image, to use as the background for the spoon canvas. This can be useful to provide contrast if the spoon's coloring is hard to see against the panel's background.

slidingPanels:panel("infoPanel"):addWidget("FromSpoon", "HCalendar",      { rX = "100%", bY = "100%" })

slidingPanels:panel("infoPanel"):addWidget("FromSpoon", "CircleClock",    { rX = "100%",  y = 0 }, {
    background = {
        type             = "rectangle",
        action           = "fill",
        roundedRectRadii = { xRadius = 20, yRadius = 20 },
        fillColor        = { red = .4, blue = .32, green = .32, alpha = .7 },
    },
})

slidingPanels:panel("infoPanel"):addWidget("FromSpoon", "MountedVolumes", {  x = 0, bY = "100%" }, {
    start = function(spoon)
        spoon.textStyle.font.size = 9 -- easier then spelling out entire style in vars
                                      -- need to think about separating out font from style in spoon
        spoon:show()
    end,
    vars  = { cornerRadius = 20, },
})

slidingPanels:panel("infoPanel"):addWidget("FromSpoon", "CPUMEMBAT", {  x = 0, y = 0 }, {
    start = "show", -- could also be `function(spoon) spoon:show() end`
    vars  = {
        checkInterval = 10,
        baseFont = { name = "Menlo", size = 10 },
    },
})

return slidingPanels:panel("infoPanel")
