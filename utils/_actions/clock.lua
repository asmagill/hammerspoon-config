local module = {}

local drawing = require("hs.drawing")
local timer   = require("hs.timer")
local screen  = require("hs.screen")
local _xtras  = require("hs._asm.extras")

local clockStyle = {
    font = "Menlo-Italic",
    size = 12,
    color = { red=.75, blue=.75, green=.75, alpha=.75},
    alignment = "center",
    lineBreak = "clip",
}
local clockBox = drawing.rectangle{}:setStroke(true)
                                    :setStrokeColor(clockStyle.color)
                                    :setFill(true)
                                    :setFillColor({alpha=.75})
                                    :setRoundedRectRadii(5,5)
                                    :setBehaviorByLabels{"canJoinAllSpaces"}
                                    :setLevel("mainMenu")

local clock = drawing.text({}, ""):setTextStyle(clockStyle)
                                  :setBehaviorByLabels{"canJoinAllSpaces"}
                                  :setLevel("mainMenu")
                                  :orderAbove(clockBox)

local drawClock = function()
    local screenFrame = screen.mainScreen():fullFrame()
    local clockTime = os.date("%I:%M:%S %p")
    local clockPos = drawing.getTextDrawingSize(clockTime, clockStyle)
    clockPos.w = clockPos.w + 4
    clockPos.x = screenFrame.x + screenFrame.w - (clockPos.w + 4)
    clockPos.y = screenFrame.y + screenFrame.h - (clockPos.h + 4)
    local clockBlockPos = {
        x = clockPos.x - 3,
        y = clockPos.y,
        h = clockPos.h + 3,
        w = clockPos.w + 6,
    }
    clockBox:setFrame(clockBlockPos)
    clock:setText(clockTime):setFrame(clockPos)
end

local clockTimer = timer.new(1, drawClock)

module.showClock = function()
    drawClock()
    clockBox:show()
    clock:show()
    clockTimer:start()
end

module.hideClock = function()
    clock:hide()
    clockBox:hide()
    clockTimer:stop()
end

module.toggleClock = function()
    if clockTimer:running() then
        module.hideClock()
    else
        module.showClock()
    end
end

module.showClock()

module.clockTimer = clockTimer
module.clockDrawing = clock
module.clockBox = clockBox

return module
