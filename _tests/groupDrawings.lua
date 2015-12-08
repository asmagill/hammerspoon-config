-- Group hs.drawing objects in a table and add metatable so that they can be
-- manipulated as a group. Assumes lower indexed drawings should appear on top
-- of higher indexed ones.

local module     = {}

-- private functions ---------------------------------------------------------------------

local drawing    = require("hs.drawing")
local mt_drawing = hs.getObjectMetatable("hs.drawing")

-- create metatabe for grouped drawings

local mt_group = {}
-- some of the methods change the order of images; this maintains the order as they were presented
-- to the group command
local maintainOrder = function(_) for i = #_, 2, -1 do _[i]:orderBelow(_[1]) end end

-- default for most methods will be to just apply them to each individual drawing and return
-- grouped object as the result
for k, v in pairs(mt_drawing) do
    mt_group[k] = function(_, ...) for i = #_, 1, -1 do v(_[i], ...) end maintainOrder(_) return _ end
end

-- alpha checks alpha of all drawings in group.  If they are the same, returns the value,
-- if not all the same, returns nil
mt_group.alpha = function(_, ...)
    local theSame, baseValue = true, _[1]:alpha(...)
    for i = #_, 2, -1 do
        if _[i]:alpha(...) ~= baseValue then
            theSame = false
            break
        end
    end
    if theSame then
        return baseValue
    else
        return nil
    end
end

-- behavior checks behavior of all drawings in group.  If they are the same, returns the value,
-- if not all the same, returns nil
mt_group.behavior = function(_, ...)
    local theSame, baseValue = true, _[1]:behavior(...)
    for i = #_, 2, -1 do
        if _[i]:behavior(...) ~= baseValue then
            theSame = false
            break
        end
    end
    if theSame then
        return baseValue
    else
        return nil
    end
end

-- behaviorAsLabels checks behavior of all drawings in group.  If they are the same, returns the value,
-- if not all the same, returns nil
mt_group.behaviorAsLabels = function(_, ...)
    if mt_group.behavior(_, ...) then
        return _[1]:behaviorAsLabels(...)
    else
        return nil
    end
end

-- delete passes delete along and clears the table metatable as well
mt_group.delete = function(_, ...)
    for i = 1, #_, 1 do _[i]:delete(...) end
    setmetatable(_, nil)
    return _
end

mt_group.clickCallbackActivating = function(_, v)
    if v ~= nil then
        for i = #_, 1, -1 do _[i]:clickCallbackActivating(v) end
        maintainOrder(_)
        return _
    else
        local theSame, baseValue = true, _[1]:clickCallbackActivating()
        for i = #_, 2, -1 do
            if _[i]:clickCallbackActivating() ~= baseValue then
                theSame = false
                break
            end
        end
        if theSame then
            return baseValue
        else
            return nil
        end
    end
end

mt_group.wantsLayer = function(_, v)
    if v ~= nil then
        for i = #_, 1, -1 do _[i]:wantsLayer(v) end
        maintainOrder(_)
        return _
    else
        local theSame, baseValue = true, _[1]:wantsLayer()
        for i = #_, 2, -1 do
            if _[i]:wantsLayer() ~= baseValue then
                theSame = false
                break
            end
        end
        if theSame then
            return baseValue
        else
            return nil
        end
    end
end

-- frame returns the frame of the group -- the smallest x and y with h and w reaching to the
-- largest x+w and y+h
mt_group.frame = function(_)
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

-- setTopLeft adjusts all of the drawings relative to the group's frame topLeft
mt_group.setTopLeft = function(_, t)
    local full = mt_group.frame(_)
    local delta = { x = t.x - full.x, y = t.y - full.y }
    for i,v in ipairs(_) do
        local r = v:frame()
        v:setTopLeft{ x = r.x + delta.x, y = r.y + delta.y }
    end
    maintainOrder(_)
    return _
end

mt_group.setSize = function(_, t)
    local o = mt_group.frame(_)
    local factor = { x = t.w / o.w, y = t.h / o.h }
    for i,v in ipairs(_) do
        local r = v:frame()
        v:setFrame{
            x = (r.x - o.x) * factor.x + o.x,
            y = (r.y - o.y) * factor.y + o.y,
            h = r.h * factor.y,
            w = r.w * factor.x,
        }
    end
    maintainOrder(_)
    return _
end

mt_group.setFrame = function(_, t)
    mt_group.setSize(_, t)
    mt_group.setTopLeft(_, t)
    return _
end

-- remove because they make no sense on a grouped object
mt_group.setRoundedRectRadii = nil
mt_group.imageAlignment      = nil
mt_group.imageAnimates       = nil
mt_group.imageFrame          = nil
mt_group.imageScaling        = nil
mt_group.setFill             = nil
mt_group.setFillColor        = nil
mt_group.setFillGradient     = nil
mt_group.setImage            = nil
mt_group.setImageFromASCII   = nil
mt_group.setImageFromPath    = nil
mt_group.setImagePath        = nil
mt_group.setStyledText       = nil
mt_group.setStroke           = nil
mt_group.setStrokeColor      = nil
mt_group.setStrokeWidth      = nil
mt_group.setText             = nil
mt_group.setTextColor        = nil
mt_group.setTextFont         = nil
mt_group.setTextSize         = nil
mt_group.setTextStyle        = nil
mt_group.getStyledText       = nil
mt_group.rotateImage         = nil
mt_group.setArcAngles        = nil

-- public functions ----------------------------------------------------------------------

module.group = function(...)
    local inputGroup, drawingGroup = table.pack(...), {}
    if inputGroup.n == 1 and type(inputGroup[1]) == "table" then
        inputGroup = inputGroup[1]
    end
    for i,e in ipairs(inputGroup) do
        if getmetatable(e) == mt_drawing then table.insert(drawingGroup, e) end
    end
    return setmetatable(drawingGroup, { __index = mt_group })
end

module.ungroup = function(_)
    setmetatable(_, nil)
    return table.unpack(_)
end

-- testing objects
module.test = {
    hs.drawing.arc({x=150,y=150},50,0,45):setFillColor{green=1}:setFill(true),
    hs.drawing.circle{x=100,y=100,h=100,w=100}:setFillColor{red=1}:setFill(true):setStrokeColor{red=1},
    hs.drawing.rectangle{x=90, y=90, h=120, w=120}:setFillColor{white=0}:setFill(true),
}

module.testGroup = module.group(module.test)

return module