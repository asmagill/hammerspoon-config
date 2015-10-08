-- save file in ~/.hammerspoon and use as follows:
--
-- graph = require("graphpaper")
-- images = graph.fillScreen(x,y,screen)
--    all three parameters are optional.  x and y specify the graph size in screen points.
--    default 10 for x, default whatever x is for y, default hs.screen.mainScreen() for screen
--
-- so, on a MacBook Air with a 1920x900 non-retina screen: `images = graph.fillScreen(20)`
-- images will be an array of 6 images.  The array has a metatable set replicating the hs.drawing methods
-- and applies them to all elements of the array, so you can show the graph with:
--
-- images:setAlpha(.5):show()
--
-- which is just a shorthand for:
--
-- for i, v in ipairs(images) do v:setAlpha(.5):show() end
--
-- Note, in multi-monitor setups, this should only create drawings for the main (or specified, if the parameter is provided)
-- monitor (screen), but this is not yet tested...

local module = {}
local markers = {
      "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K",
      "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "a", "b", "c", "d", "e",
      "f", "g", "h", "i", "j", "k", "l", "m", "n", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"
}
local availableLines = math.floor(#markers / 2)

local mt = {}
for k, v in pairs(hs.getObjectMetatable("hs.drawing")) do
    mt[k] = function(_, ...) for a, b in ipairs(_) do v(b, ...) end return _ end
end

local graphWithSpacing = function(x,y)
    x = x or 10
    y = y or x

    local rows = {}
    rows[2] = ""
    for i = 1, availableLines do
        rows[1 + (i - 1) * y] = markers[i] .. string.rep(".", x * availableLines - 2) .. markers[i]
        rows[2] = rows[2] .. markers[i + availableLines] .. string.rep(".", x - 1)
    end
    rows[y * availableLines] = rows[2]
    for i = 1, (y * availableLines) do
        if not rows[i] then rows[i] = string.rep(".", x * availableLines) end
    end

    return hs.drawing.image({x = 0, y = 0, h = y * availableLines, w = x * availableLines},
                            hs.image.imageFromASCII(table.concat(rows, "\n"), {{
                                      strokeColor = {alpha = 1},
                                      fillColor   = {alpha = 0},
                                      strokeWidth = 1,
                                      shouldClose = false,
                                      antialias = false,
                                  }})) --:imageScaling("scaleToFit")
end

local fillScreen = function(x, y, which)
    if type(x) == "number" and type(y) ~= "number" then
        which = y
    elseif type(x) ~= "number" then
        which = x
    end

    x = type(x) == "number" and x or 10
    y = type(y) == "number" and y or x
    which = which or hs.screen.mainScreen()
    local whichRect = which:fullFrame()

    local d = {}

    local width = math.ceil(whichRect.w / (x * availableLines))
    local height = math.ceil(whichRect.h / (y * availableLines))

    for i = 1, width do
        for j = 1, height do
            table.insert(d, graphWithSpacing(x, y):setTopLeft{
                                                    x = whichRect.x + (i - 1) * (x * availableLines),
                                                    y = whichRect.y + (j - 1) * (y * availableLines)
                                              })
        end
    end

    return setmetatable(d, {__index = mt})
end

module.fillScreen = fillScreen
module.graphWithSpacing = graphWithSpacing
return module
