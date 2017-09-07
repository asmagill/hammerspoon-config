--
-- An example of creating an image from the touch bar even if the virtual touchbar is not currently visible/running
--
-- This should work on Mac's that actually have a touchbar as well, but since I can't test it myself, I'll have to
-- wait until publicly announcing the latest round of updates to confirm.
--

local tb = require("hs._asm.undocumented.touchbar")

local mb = tb.new():streaming(true)

-- we need to wait until streaming can begin and a full context can be generated, maybe
-- a second or two...
local zz
hs.timer.waitUntil(function()
    zz = mb:image()
    return zz
end, function()
    local sz = zz:size()
    local fr = { x = 100, y = 100, h = sz.h + 20, w = sz.w + 20 }

    nd = hs.canvas.new(fr):show()
    nd[#nd + 1] = {
        type = "rectangle"
    }
    nd[#nd + 1] = {
        type = "image",
        image = zz,
        frame = { x = 10, y = 10, h = sz.h, w = sz.w }
    }

    ndt = hs.timer.doEvery(1, function()
        nd[2].image = mb:image()
    end)
end)
