local touchbar = require("hs._asm.undocumented.touchbar")
local canvas   = require("hs.canvas")
local window   = require("hs.window")
local screen   = require("hs.screen")

local module = {}

local _c = canvas.new{x = 0, y = 0, h = 30, w = 150}
_c[#_c + 1] = {
    type             = "rectangle",
    action           = "strokeAndFill",
    strokeColor      = { white = 1 },
    fillColor        = { white = .25 },
    roundedRectRadii = { xRadius = 5, yRadius = 5 },
}
_c[#_c + 1] = {
    id          = "zigzag",
    type        = "segments",
    action      = "stroke",
    strokeColor = { blue = 1, green = 1 },
    coordinates = {
        { x =   0, y = 15 },
        { x =  65, y = 15 },
        { x =  70, y =  5 },
        { x =  80, y = 25 },
        { x =  85, y = 15 },
        { x = 150, y = 15},
    }
}

local _i = touchbar.item.newCanvas(_c, "zigzagCanvas"):canvasClickColor{ alpha = 0.0 }

_c:canvasMouseEvents(true, true, false, true):mouseCallback(function(o,m,i,x,y)
    local max = _i:canvasWidth()
    local win = window.frontmostWindow()
    if not win then return end

    local screenFrame = screen.mainScreen():frame()
    local winFrame    = win:frame()

    local newCenterPos = screenFrame.x + (x / max) * screenFrame.w
    local newWinX      = newCenterPos - winFrame.w / 2

    if m == "mouseDown" or m == "mouseMove" then
        win:setTopLeft{ x = newWinX, y = winFrame.y }
        _c.zigzag.coordinates[2].x = x - 10
        _c.zigzag.coordinates[3].x = x - 5
        _c.zigzag.coordinates[4].x = x + 5
        _c.zigzag.coordinates[5].x = x + 10
    elseif m == "mouseUp" then
        _c.zigzag.coordinates[2].x = 65
        _c.zigzag.coordinates[3].x = 70
        _c.zigzag.coordinates[4].x = 80
        _c.zigzag.coordinates[5].x = 85
--     elseif m == "mouseEnter" then
--     elseif m == "mouseExit" then
    end
end)

local _b = touchbar.bar.new():templateItems{ _i }:defaultIdentifiers{ _i:identifier() }:presentModalBar(true)

module.canvas = _c
module.item   = _i
module.bar    = _b

return module
