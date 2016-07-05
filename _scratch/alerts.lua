local module = {}

local drawing = require("hs.drawing")
local timer   = require("hs.timer")
local screen  = require("hs.screen")
local uuid    = require"hs.host".uuid

module._visibleAlerts = {}

local purgeAlert = function(UUID, duration)
    duration = math.max(duration, 0.0) or 0.15
    local indexToRemove
    for i,v in ipairs(module._visibleAlerts) do
        if v.UUID == UUID then
            if v.timer then v.timer:stop() end
            for i2,v2 in ipairs(v.drawings) do
                v2:hide(duration)
                if duration > 0.0 then
                    timer.doAfter(duration, function() v2:delete() end)
                end
                v.drawings[i2] = nil
            end
            indexToRemove = i
            break
        end
    end
    if indexToRemove then
        table.remove(module._visibleAlerts, indexToRemove)
    end
end

local showAlert = function(message, duration)
    local screenFrame = screen.mainScreen():fullFrame()

    local absoluteTop = screenFrame.h * (1 - 1 / 1.55) + 55 -- mimic module behavior for inverted rect
    if #module._visibleAlerts > 0 then
        absoluteTop = module._visibleAlerts[#module._visibleAlerts].frame.y + module._visibleAlerts[#module._visibleAlerts].frame.h + 3
    end

    if absoluteTop > screenFrame.h then
        absoluteTop = screen.mainScreen():frame().y
    end

    local alertEntry = {
        drawings = {},
    }
    local UUID = uuid()
    alertEntry.UUID = UUID

    local textFrame = drawing.getTextDrawingSize(message)
    textFrame.w = textFrame.w + 4 -- known fudge factor, see hs.drawing.getTextDrawingSize docs
    local drawingFrame = {
        x = screenFrame.x + (screenFrame.w - (textFrame.w + 26)) / 2,
        y = absoluteTop,
        h = textFrame.h + 24,
        w = textFrame.w + 26,
    }
    textFrame.x = drawingFrame.x + 13
    textFrame.y = drawingFrame.y + 12

    table.insert(alertEntry.drawings, drawing.rectangle(drawingFrame)
                                            :setStroke(true)
                                            :setStrokeWidth(2)
                                            :setStrokeColor{white = 1, alpha = 1}
                                            :setFill(true)
                                            :setFillColor{white = 0, alpha = 0.75}
                                            :setRoundedRectRadii(27, 27)
                                            :show(0.15)
    )
    table.insert(alertEntry.drawings, drawing.text(textFrame, message)
                                            :orderAbove(alertEntry.drawings[1])
                                            :show(0.15)
    )
    alertEntry.frame = drawingFrame

    table.insert(module._visibleAlerts, alertEntry)
    if type(duration) == "number" then
        alertEntry.timer = timer.doAfter(duration, function()
            purgeAlert(UUID, 0.15)
        end)
    end
    return UUID
end

module.show = function(message, duration)
    message = tostring(message)
    duration = duration or 2.0
    return showAlert(message, duration)
end

module.closeAll = function(duration)
    duration = duration and math.max(duration, 0.0) or 0.15
    while (#module._visibleAlerts > 0) do
        purgeAlert(module._visibleAlerts[#module._visibleAlerts].UUID, duration)
    end
end

module.closeSpecific = function(UUID, duration)
    duration = duration and math.max(duration, 0.0) or 0.15
    purgeAlert(UUID, duration)
end

return setmetatable(module, { __call = function(_, ...) return module.show(...) end })
