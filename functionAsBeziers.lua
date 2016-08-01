local module = {}
local canvas = require("hs._asm.canvas")
local matrix = canvas.matrix

local calculateControlPoints = function(xy0, xy1, xy2, t)
    -- see http://scaledinnovation.com/analytics/splines/aboutSplines.html
    --
    -- x0,y0,x1,y1 are the coordinates of the end (knot) pts of this segment
    -- x2,y2 is the next knot -- not connected here but needed to calculate p2
    -- p1 is the control point calculated here, from x1 back toward x0.
    -- p2 is the next control point, calculated here and returned to become the
    -- next segment's p1.
    -- t is the 'tension' which controls how far the control points spread.

    -- Scaling factors: distances from this knot to the previous and following knots.
    local d01 = math.sqrt((xy1.x - xy0.x) ^ 2 + (xy1.y - xy0.y) ^ 2)
    local d12 = math.sqrt((xy2.x - xy1.x) ^ 2 + (xy2.y - xy1.y) ^ 2)

    local fa = t * d01 / (d01 + d12)
    local fb = t - fa

    local p1 = {
        x = xy1.x + fa * (xy0.x - xy2.x),
        y = xy1.y + fa * (xy0.y - xy2.y)
    }

    local p2 = {
        x = xy1.x - fb * (xy0.x - xy2.x),
        y = xy1.y - fb * (xy0.y - xy2.y)
    }

    return p1, p2
end

local scaleCoordinates = function(coords, frame)
    coords = coords or {}

    local maxX, maxY = math.mininteger, math.mininteger
    local minX, minY = math.maxinteger, math.maxinteger
    for c, v in ipairs(coords) do
        maxX, maxY = math.max(v.x or 0.0, maxX), math.max(v.y or 0.0, maxY)
        minX, minY = math.min(v.x or 0.0, minX), math.min(v.y or 0.0, minY)
    end

    local xSpan, ySpan = maxX - minX, maxY - minY
    local results = {}
    for c, v in ipairs(coords) do
        local newPoint = {}
        for l, n in pairs(v) do
            if l:match("x$") then
                newPoint[l] = n * frame.w / xSpan
            elseif l:match("y$") then
                newPoint[l] = n * frame.h / ySpan
            end
        end
        table.insert(results, newPoint)
    end
    return results
end

module.coordinateSet = function(fn, start, stop, inc)
    fn    = fn    or math.sin
    start = start or 0.0
    stop  = stop  or 2 * math.pi
    inc   = inc   or .1

    local coords = {}
    for i = start, stop, inc do table.insert(coords, { x = i, y = fn(i) }) end
    if (stop - start) % inc ~= 0.0 then
        table.insert(coords, { x = stop, y = fn(stop) })
    end
    return coords
end

module.addControlPointsToCoordinates = function(coords, t)
    t = t or .5
    local cp = {}
    for i = 1, #coords - 2, 1 do
        local p1, p2 = calculateControlPoints(coords[i], coords[i + 1], coords[i + 2], t)
        table.insert(cp, p1)
        table.insert(cp, p2)
    end
    local results = { coords[1] }
    for i = 2, #coords - 1, 1 do
        table.insert(results, {
            x = coords[i].x,
            y = coords[i].y,
            c1x = cp[(i - 2) * 2 + 1].x,
            c1y = cp[(i - 2) * 2 + 1].y,
            c2x = cp[(i - 2) * 2 + 2].x,
            c2y = cp[(i - 2) * 2 + 2].y,
        })
    end
    table.insert(results, {
        x = coords[#coords].x,
        y = coords[#coords].y,
        c1x = cp[#cp].x,
        c1y = cp[#cp].y,
        c2x = cp[#cp].x,
        c2y = cp[#cp].y,
    })
    return results
end

module.coordinatesForCanvasElementForFofX = function(frame, fn, start, stop, inc, tension)
    local coords = module.coordinateSet(fn, start, stop, inc)
    coords = module.addControlPointsToCoordinates(coords, tension)
    return scaleCoordinates(coords, frame)
end

module.canvasElementForFofX = function(frame, fn, start, stop, inc, tension)
    local coordinates = module.coordinatesForCanvasElementForFofX(frame, fn, start, stop, inc, tension)
    return canvas.new(frame):insertElement{
        type = "segments",
        action = "stroke",
        transformation = matrix.translate(-1 * coordinates[1].x, frame.h / 2):scale(1, -1),
        coordinates = coordinates,
    }
end

return module