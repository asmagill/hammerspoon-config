
local i = [[ASCII:
 · · · · · · · · · · · · · · ·
 · · · · 1 · · · · · · 1 · · ·
 · · · · · · · · · · · · · · ·
 · · · · · · · · · · · · · · ·
 · · · · · · · · · · · · · · ·
 · · 3 · 1 · · · · · · 1 · 4 ·
 · · · · · · · · · · · · · · ·
 · · · · · · A · · A · · · · ·
 · · · · 1 · · · · · · 1 · · ·
 · · · · · · · C D · · · · · ·
 · · · · · · A · · A · · · · ·
 · · · · · · · · · · · · · · ·
 · · · · · · · B E · · · · · ·
 · · · · · · · · · · · · · · ·
 · · 6 · · · · · · · · · · 5 ·
]]

local black  = { red = 0, blue = 0, green = 0, alpha = 1 }
local clear  = { red = 0, blue = 0, green = 0, alpha = 0 }
local white  = { red = 1, blue = 1, green = 1, alpha = 1 }
local gray   = { red = .2, blue = .2, green = .2, alpha = 1 }

local c = {
    {
        strokeColor = black,
        fillColor = clear,
    },
    {
        strokeColor = black,
        fillColor = gray,
    },
    {
        strokeColor = white,
        fillColor = white,
        antialias = true,
        shouldClose = true
    }
}

local d = hs.drawing.image({x = 100, y = 100, h = 500, w = 500},
              hs.image.imageFromASCII(i)):show()

local e = hs.drawing.image({x = 600, y = 100, h = 500, w = 500},
              hs.image.imageFromASCII(i, c)):show()

local esc = function() d:delete() ; e:delete() end

xyzzy = hs.hotkey.bind({},"escape",
    function() esc() end,
    function() xyzzy:disable() end
)
