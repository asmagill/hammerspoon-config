local slidingPanels = hs.loadSpoon("SlidingPanels")

slidingPanels:addPanel("infoPanel", {
    size              = 1/3,
    modifiers         = { "fn" },
    persistent        = true,
    animationDuration = 0.1,
    color             = { white = .35 },
    fillAlpha         = .95,
}):enable()

slidingPanels:panel("infoPanel"):addWidget("FromSpoon", "HCalendar",      { rX = "100%", bY = "100%" })
slidingPanels:panel("infoPanel"):addWidget("FromSpoon", "CircleClock",    { rX = "100%",  y = 0      })
slidingPanels:panel("infoPanel"):addWidget("FromSpoon", "MountedVolumes", {  x = 0,      bY = "100%" }, {
    start = "show",
    vars  = { cornerRadius = 20 },
})

return slidingPanels:panel("infoPanel")
