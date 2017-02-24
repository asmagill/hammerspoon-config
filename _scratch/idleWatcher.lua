--- CPU Usage compare

local module = {}

local canvas  = require "hs.canvas"
local host    = require "hs.host"
local timer   = require "hs.timer"
local task    = require "hs.task"
local fnutils = require "hs.fnutils"
local screen  = require "hs.screen"
local stext   = require "hs.styledtext"

local timestamp = function(date)
    date = date or timer.secondsSinceEpoch()
    return os.date("%F %T" .. string.format("%-5s", ((tostring(date):match("(%.%d+)$")) or "")), math.floor(date))
end

local logMessage = function(...) print(timestamp(), ...) end

local localSize  = { h = 60, w = 200 }
local localFrame = {
    x = screen.primaryScreen():frame().x +  (screen.primaryScreen():frame().w - localSize.w) / 2,
    y = screen.primaryScreen():frame().y,
    w = localSize.w,
    h = localSize.h,
}

-- trickery to force an auto-update when it changes
module._frame = setmetatable({}, {
    __index = function(self, key)
        return localFrame[key]
    end,
    __newindex = function(self, key, value)
        if localFrame[key] and type(value) == "number" then
            localFrame[key] = value
            -- only force update if the canvas already exists
            if module._display then module._display:frame(localFrame) end
        else
            logMessage("++ invalid field or value type for display frame")
        end
    end,
    __pairs = function(self)
        return function(_, k)
                local v
                k, v = next(_, k)
                return k, v
            end, localFrame, nil
    end
})

module._valueStyle = {
    font = {
        name = "Menlo-Italic",
        size = 12,
    },
    paragraphStyle = {
        alignment = "center",
        linebreak = "clip",
    },
}

module._display = canvas.new(module._frame):appendElements(
    {
        id               = "background",
        type             = "rectangle",
        roundedRectRadii = { xRadius = 5.0, yRadius = 5.0 },
        fillColor        = { white = .50, alpha = .5 },
        strokeColor      = { white = .25, alpha = .5 },
        strokeWidth      = 2,
    }, {
        id               = "topBox",
        type             = "rectangle",
        frame            = { x = "5%", y = "5%", w = "40%", h = "70%" },
        roundedRectRadii = { xRadius = 5.0, yRadius = 5.0 },
        fillColor        = { white = .50, alpha = .5 },
        strokeColor      = { white = .25, alpha = .5 },
        strokeWidth      = 1,
    }, {
        id               = "hostBox",
        type             = "rectangle",
        frame            = { x = "55%", y = "5%", w = "40%", h = "70%" },
        roundedRectRadii = { xRadius = 5.0, yRadius = 5.0 },
        fillColor        = { white = .50, alpha = .5 },
        strokeColor      = { white = .25, alpha = .5 },
        strokeWidth      = 1,
    }, {
        id               = "topLabel",
        type             = "text",
        text             = "/usr/bin/top",
        textColor        = { white = 0 },
        textAlignment    = "center",
        textLineBreak    = "clip",
        textFont         = "Menlo",
        textSize         = 8,
        frame            = { x = "5%", y = "5%", w = "40%", h = "20%" }
    }, {
        id               = "hostLabel",
        type             = "text",
        textColor        = { white = 0 },
        text             = "hs.host.cpuUsage",
        textAlignment    = "center",
        textLineBreak    = "clip",
        textFont         = "Menlo",
        textSize         = 8,
        frame            = { x = "55%", y = "5%", w = "40%", h = "20%" }
    }, {
        id               = "topValue",
        type             = "text",
        frame            = { x = "5%", y = "25%", w = "40%", h = "40%" }
    }, {
        id               = "hostValue",
        type             = "text",
        frame            = { x = "55%", y = "25%", w = "40%", h = "40%" }
    }, {
        id               = "timeLabel",
        type             = "text",
        textColor        = { white = 0 },
        text             = timestamp(),
        textAlignment    = "right",
        textLineBreak    = "clip",
        textFont         = "Menlo",
        textSize         = 8,
        frame            = { x = "5%", y = "75%", w = "90%", h = "20%" }
    }
)

module._timer = timer.new(5, function()
    if module._topTask and module._topTask:isRunning() then
        logMessage("+++ top task taking too long; killing it!")
        module._topTask:terminate()
    end
    module._topTask = task.new("/usr/bin/top", function(c, o, e)
        local cpuStat = nil
        if c == 0 then
            -- we want the second line because top's first CPU data is not valid since it
            -- calculates based on deltas
            local count = 0
            for i, v in ipairs(fnutils.split(o, "\n")) do
                if v:match("CPU usage") then
                    count = count + 1
                    if count == 2 then
                        cpuStat = v:match(" ([%d%.]+%%) idle ")
                        break
                    end
                end
            end
            if not cpuStat then
                logMessage("+++ unable to get CPU usage number from top!")
            end
        else
            logMessage("+++ unexpected return code for top!")
        end
        module._display.topValue.text  = stext.new(cpuStat or "XXX", module._valueStyle)
        module._display.hostValue.text = stext.new(string.format("%.2f%%", host.cpuUsage().overall.idle), module._valueStyle)
        module._display.timeLabel.text = timestamp()
--        module._display.hostValue.text = stext.new(string.format("%.2f%%", host.cpuUsage()[1].idle), module._valueStyle)
    end, {"-l", "2", "-n", "0"}):start()
end)

module.show = function()
    module._display:show()
    if not module._timer:running() then module._timer:start() end
end

module.hide = function()
    module._display:hide()
    if module._timer:running() then module._timer:stop() end
end

module.toggle = function()
    if module._display:isShowing() then
        module.hide()
    else
        module.show()
    end
end

module.show()

return module
