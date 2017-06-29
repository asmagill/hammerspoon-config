-- testing functions for use in arduino for hsb2rgb and rgb2hsb conversion against mac's built in conversion
-- adapted from https://github.com/ratkins/RGBConverter/blob/master/RGBConverter.cpp
--    converted to ranges used by Philips Hue bridge
--    converted to lua for these tests

local rgb2hsb = function(red, green, blue)
    local rd = red   / 255
    local gd = green / 255
    local bd = blue  / 255
    local mx = math.max(rd, gd, bd)
    local mn = math.min(rd, gd, bd)
    local h, s
    local v = mx

    local d = mx - mn
    s = (mx == 0) and 0 or (d / mx)

    if (mx == mn) then
        h = 0 -- achromatic
    else
        if (mx == rd) then
            h = (gd - bd) / d + ((gd < bd) and 6 or 0)
        elseif (mx == gd) then
            h = (bd - rd) / d + 2
        elseif (mx == bd) then
            h = (rd - gd) / d + 4
        end
        h = h / 6
    end

    return math.floor(h * 65535), math.floor(s * 255), math.floor(v * 255)
end

local hsb2rgb = function(hue, sat, bri)
    hue, sat, bri = hue / 65535, sat / 255, bri / 255
    local r, g, b

    local i = math.floor(hue * 6)
    local f = hue * 6 - i
    local p = bri * (1 - sat)
    local q = bri * (1 - f * sat)
    local t = bri * (1 - (1 - f) * sat)

    if (i % 6) == 0 then
        r, g, b = bri, t, p
    elseif (i % 6) == 1 then
        r, g, b = q, bri, p
    elseif (i % 6) == 2 then
        r, g, b = p, bri, t
    elseif (i % 6) == 3 then
        r, g, b = p, q, bri
    elseif (i % 6) == 4 then
        r, g, b = t, p, bri
    elseif (i % 6) == 5 then
        r, g, b = bri, p, q
    end

    return math.floor(r * 255), math.floor(g * 255), math.floor(b * 255)
end

-- now mac conversion functions

local mac_rgb2hsb = function(red, green, blue)
    local color = require("hs.drawing").color
    local temp = color.asHSB{ red = red / 255, green = green / 255, blue = blue / 255 }
    return math.floor(temp.hue * 65535), math.floor(temp.saturation * 255), math.floor(temp.brightness * 255)
end

local mac_hsb2rgb = function(hue, sat, bri)
    local color = require("hs.drawing").color
    local temp = color.asRGB{ hue = hue / 65535, saturation = sat / 255, brightness = bri / 255 }
    return math.floor(temp.red * 255), math.floor(temp.green * 255), math.floor(temp.blue * 255)
end



require("hs.console").clearConsole()

-- we'll accept conversions that are within a margin of error
local closeEnough = function(a, b) return math.abs(a - b) <= 1 end

local count, good = 0, 0
for r = 0, 1, .01 do for g = 0, 1, .01 do for b = 0, 1, .01 do -- for final test, do 1,000,000 comparisons
    count = count + 1
    local r1, g1, b1 = math.floor(r * 255), math.floor(g * 255), math.floor(b * 255)
    local h2, s2, b2 = rgb2hsb(r1, g1, b1)
    local h3, s3, b3 = mac_rgb2hsb(r1, g1, b1)
    -- hue of 65535 == hue of 0, so catch both
    local st = (closeEnough(h2,h3) or ((h2 == 0) and (h3 == 65535)) or ((h2 == 65535) and (h3 == 0))) and (s2 == s3) and (b2 == b3)
    if st then
        good = good + 1
    else
        hs.printf("%3d, %3d, %3d rgb2hsb == %5d, %3d, %3d mac_rgb2hsb == %5d, %3d, %3d %s", r1, g1, b1, h2, s2, b2, h3, s3, b3, st)
    end
end end end

hs.printf("rgb2hsb total %d, passed %d\n", count, good)

local count, good = 0, 0
for h = 0, 1, .01 do for s = 0, 1, .01 do for b = 0, 1, .01 do
    count = count + 1
    local h1, s1, b1 = math.floor(h * 65535), math.floor(s * 255), math.floor(b * 255)
    local r2, g2, b2 = hsb2rgb(h1, s1, b1)
    local r3, g3, b3 = mac_hsb2rgb(h1, s1, b1)
    local st = (r2 == r3) and (g2 == g3) and (b2 == b3)
    if st then
        good = good + 1
    else
        hs.printf("%5d, %3d, %3d hsb2rgb == %3d, %3d, %3d mac_hsb2rgb == %3d, %3d, %3d %s", h1, s1, b1, r2, g2, b2, r3, g3, b3, st)
    end
end end end

hs.printf("hsb2rgb total %d, passed %d\n", count, good)
