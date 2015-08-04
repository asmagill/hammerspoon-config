
local openI = [[
1 # # # # # # # # 2
# . . . . . . . . #
# . 6 . . . . 9 . #
# . . # . . # . . #
# . . . # # . . . #
# . . . # # . . . #
# . . # . . # . . #
# . A . . . . 7 . #
# . . . . . . . . #
# e # # # # # # f #
# . . . . . . . . #
# . . . . . . a . #
# . . . . # # . . #
# . . # # . . . . #
# . b . . . . . . #
# . . # # . . . . #
# . . . . # # . . #
# . . . . . . c . #
# . . . . . . . . #
4 # # # # # # # # 3
]]

local openC = {
    { fillColor   = { alpha = 0 } },
    { strokeColor = { red = .5 } },
    { strokeColor = { red = .5 } },
    {
        strokeColor = { green = .75 },
        fillColor   = { green = .5 }, -- alpha = 0 },
        shouldClose = false
    }, {
        fillColor = {},
        strokeColor = {},
        antialias   = true,
        shouldClose = true
    }
}

local closeI = [[
1 # # # # # # # # 2
# . . . . . . . . #
# . 6 . . . . 9 . #
# . . # . . # . . #
# . . . # # . . . #
# . . . # # . . . #
# . . # . . # . . #
# . A . . . . 7 . #
# . . . . . . . . #
# e # # # # # # f #
# . . . . . . . . #
# . a . . . . . . #
# . . # # . . . . #
# . . . . # # . . #
# . . . . . . b . #
# . . . . # # . . #
# . . # # . . . . #
# . c . . . . . . #
# . . . . . . . . #
4 # # # # # # # # 3
]]

local closeC = {
    { fillColor   = { alpha = 0 } },
    { strokeColor = { red = .5 } },
    { strokeColor = { red = .5 } },
    {
        strokeColor = { red = .75, green = .75 },
        fillColor   = { red = .5, green = .5 }, -- alpha = 0 },
        shouldClose = false
    }, {
        fillColor = {},
        strokeColor = {},
        antialias   = true,
        shouldClose = true
    }
}

local a = {}

a[1] = hs.drawing.image({x=100,y=100,h=200,w=100},
    hs.image.imageFromASCII(openI, openC)):show()

a[2] = hs.drawing.image({x=300,y=100,h=200,w=100},
    hs.image.imageFromASCII(closeI, closeC)):show()

-- cleanup so I don't have to reload everything

local esc = function()
    -- do whatever to cleanup
    hs.fnutils.map(a, function(_) _:delete() end)
end

xyzzy = hs.hotkey.bind({},"escape",
    function() esc() end,
    function() xyzzy:disable() end
)
