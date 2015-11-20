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
-- monitor.  In some cases, depending upon size of display and graph size, pre 0.9.42 versions of Hammerspoon will display
-- some edge portions on the wrong monitor... we can't do anything about that without significant changes to this code.
-- Hammerspoon 0.9.42 and later, however, have a work around included here.  See the end of module.fillScreen for more details.

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

    local width    = math.ceil(whichRect.w / (x * availableLines))
    local height   = math.ceil(whichRect.h / (y * availableLines))
    local wOnRatio = (whichRect.w / (x * availableLines)) - (width - 1)
    local hOnRatio = (whichRect.h / (y * availableLines)) - (height - 1)

    for i = 1, width do
        for j = 1, height do
            local h, w = y * availableLines, x * availableLines

        -- correct for OS X's naive assumption that the monitor with "most" of the window visible is the one we want.
        -- only works with 0.9.42 and later.  Previous versions will *mostly* work, but in some cases, if an image
        -- making up part of the graph is *mostly* on another monitor, the windowserver automatically moves it and we
        -- can't stop it (at least I haven't found a way to).  So you'll have to upgrade or tweak the graph size.

            local v1,v2,v3 = hs.processInfo.version:match("^(%d+)%.(%d+)%.(%d+)$")
            local tooEarlyToCorrect = false

            if tonumber(v1) < 1 and tonumber(v2) < 10 and tonumber(v3) < 42 then tooEarlyToCorrect = true end
            if not tooEarlyToCorrect then
                if i == width then  w = w * wOnRatio end
                if j == height then h = h * hOnRatio end
            end

            table.insert(d, graphWithSpacing(x, y):setFrame{
                                                    x = whichRect.x + (i - 1) * (x * availableLines),
                                                    y = whichRect.y + (j - 1) * (y * availableLines),
                                                    h = h,
                                                    w = w
                                              })
            if not tooEarlyToCorrect then d[#d]:imageScaling("none") end

        end
    end

    return setmetatable(d, {__index = mt})
end

module.fillScreen = fillScreen
module.graphWithSpacing = graphWithSpacing
return module
