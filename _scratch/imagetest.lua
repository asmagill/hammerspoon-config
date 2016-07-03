local path = "https://avatars1.githubusercontent.com/u/%d?v=3&s=96"
local start = math.random(8139480 * 2)
local max  = 5

local drawing = require("hs.drawing")
local image   = require("hs.image")

drawMeth1 = {}

table.insert(drawMeth1, os.time())
for i = 0, max, 1 do
    table.insert(drawMeth1, drawing.image({x = 100 + 100 * i, y = 200, h = 100, w = 100}, image.imageFromURL(string.format(path, start + i))):show())
    table.insert(drawMeth1, os.time())
end

for i = 1, #drawMeth1, 2 do print(os.date("%c", drawMeth1[i])) end

print()

-- start = math.random(8139480 * 2)
--
-- drawMeth2 = {}
--
-- table.insert(drawMeth2, os.time())
-- for i = 0, max, 1 do
--     table.insert(drawMeth2, drawing.image({x = 100 + 100 * i, y = 400, h = 100, w = 100}, image.imageFromURL2(string.format(path, start + i))):show())
--     table.insert(drawMeth2, os.time())
-- end
--
-- for i = 1, #drawMeth2, 2 do print(os.date("%c", drawMeth2[i])) end

dd = function()
    if drawMeth1 then
        for i = 2, #drawMeth1, 2 do drawMeth1[i]:delete() end
        drawMeth1 = nil
    end
    if drawMeth2 then
        for i = 2, #drawMeth2, 2 do drawMeth2[i]:delete() end
        drawMeth2 = nil
    end
    dd = nil
end