local host    = require("hs.host")
local fnutils = require("hs.fnutils")
local drawing = require("hs.drawing")
local stext   = require("hs.styledtext")
local screen  = require("hs.screen")
local disks   = require("hs._asm.disks")

local volumesToIgnore = {}
local bytesToGB = 1024 * 1024 * 1024

local module = {}

module.textStyle = {
    font = { name = "Menlo", size = 10 },
    color = { alpha = 1.0 },
    paragraphStyle = { alignment = "center" },
}
module.capacityColor  = { list = "x11", name = "orangered" }
module.availableColor = { list = "x11", name = "mediumspringgreen" }

local round = function(number, scale)
    scale = scale or 2
    return math.floor(number * (10^scale) + .5) / (10^scale)
end

local mt = {}
for k, v in pairs(hs.getObjectMetatable("hs.drawing")) do
    mt[k] = function(_, ...) for i = #_, 1, -1 do v(_[i], ...) end return _ end
end
mt.frame = function(_)
    local rect = { x = math.huge, y = math.huge, ex = 0, ey = 0 }
    for i,v in ipairs(_) do
        local r = v:frame()
        rect.x = math.min(rect.x, r.x)
        rect.y = math.min(rect.y, r.y)
        rect.ex = math.max(rect.ex, r.x + r.w)
        rect.ey = math.max(rect.ey, r.y + r.h)
    end
    return { x = rect.x, y = rect.y, h = rect.ey - rect.y, w = rect.ex - rect.x }
end
mt.setTopLeft = function(_, t)
    local full = mt.frame(_)
    local delta = { x = t.x - full.x, y = t.y - full.y }
    for i,v in ipairs(_) do
        local r = v:frame()
        v:setTopLeft{ x = r.x + delta.x, y = r.y + delta.y }
    end
    return _
end

module.ignore = function(host, state)
    if not host then
        local results = {}
        for i,v in funutils.sortByKeys(volumesToIgnore) do table.insert(results, v) end
        return results
    else
        if state then
            volumesToIgnore[host] = true
        else
            volumesToIgnore[host] = nil
        end
    end
end

module.getStats = function()
    local results = {}
    for i,v in fnutils.sortByKeys(host.volumeInformation()) do
        table.insert(results, {
            v.NSURLVolumeNameKey,
            round(v.NSURLVolumeTotalCapacityKey     / bytesToGB),
            round(v.NSURLVolumeAvailableCapacityKey / bytesToGB),
        })
    end
    return results
end

module.drawAt = function(x,y)
    local results = {}
    local height, width, count = 0, 0, 0

    local texts = {}

    for i,v in ipairs(module.getStats()) do
--         table.insert(texts, v[1].."\nCapacity: "..v[2].." GB\nAvailable: "..v[3].." GB")
        table.insert(texts, v[1].."\n"..v[3].." of "..v[2].." GB\nAvailable")
        local tmp = drawing.getTextDrawingSize(texts[#texts], module.textStyle)
        height, width = math.max(tmp.h, height), math.max(tmp.w, width)
    end
    width = width + 10

    for i,v in ipairs(module.getStats()) do
        table.insert(results, drawing.arc({
                x = x + 10 + height / 2,
                y = y + (height + 10) * count + 10 + height / 2,
            }, height / 2, 0, 360 * (v[3] / v[2]))
            :setFillColor(module.availableColor)
            :setFill(true)
            :setStroke(false)
            :setAlpha(.7)
        )
        table.insert(results, drawing.circle{
                x = x + 10,
                y = y + (height + 10) * count + 10,
                h = height,
                w = height,
            }:setFillColor(module.capacityColor)
            :setFill(true)
            :setStroke(false)
            :setAlpha(.7)
        )
        table.insert(results, drawing.text({
                x = x + height + 20,
                y = y + (height + 10) * count + 10,
                h = height,
                w = width,
            }, stext.new(texts[count + 1], module.textStyle))
            :wantsLayer(true)
        )
        count = count + 1
    end

    table.insert(results, drawing.rectangle{
            x = x, y = y, h = (height + 10) * count + 20, w = width + height + 30,
        }:setFillColor{ alpha=.7, white = .5 }
        :setStrokeColor{ alpha=.5 }
        :setFill(true)
        :setRoundedRectRadii(5,5)
    )
    return setmetatable(results, { __index = mt })
end

module.drawings = nil

module.updateDisplay = function()
    local output = module.drawAt(22,100)
    local frame  = output:frame()
    local screenFrame = screen.primaryScreen():frame()
    frame.y = (screenFrame.y + screenFrame.h) - (frame.h + 22)
    output:setTopLeft(frame)
          :setLevel(module.geekletInterface.level)
--           :wantsLayer(module.geekletInterface.layer)
          :setBehaviorByLabels(module.geekletInterface.behavior)
    if module.drawings then module.drawings:delete() end
    module.drawings = output
    if module.geekletInterface.visible then module.drawings:show() end
end

module.diskWatcher = disks.new(function(t, v)
    -- we don't care about the type... it triggers an update either way
    module.updateDisplay()
end):start()

module.geekletInterface = setmetatable({
    visible  = true,
    level    = drawing.windowLevels.desktopIcon,
    behavior = {"default"},
}, {
    __index = {
        show                = function(_)
                                  module.geekletInterface.visible = true
                                  module.drawings:show()
                                  return _
                              end,
        hide                = function(_)
                                  module.geekletInterface.visible = false
                                  module.drawings:hide()
                                  return _
                              end,
        delete              = function(_)
                                  module.diskWatcher:stop()
                                  module.drawings:delete()
                                  return _
                              end,
        setLevel            = function(_, x)
                                  module.geekletInterface.level = x
                                  module.drawings:setLevel(x)
                                  return _
                              end,
        setBehaviorByLabels = function(_, x)
                                  module.geekletInterface.behavior = x
                                  module.drawings:setBehaviorByLabels(x)
                                  return _
                              end,
        orderBelow          = function(_, x)
                                  for i = #module.drawings, 2, -1 do
                                      module.drawings[i]:orderBelow(module.drawings[1])
                                  end
                                  return _
                              end,
    }
})

module.updateDisplay()

return setmetatable(module, {
    __gc = function(_)
        _.geekletInterface:delete()
    end
})