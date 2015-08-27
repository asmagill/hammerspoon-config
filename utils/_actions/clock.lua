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
local clock = drawing.text({}, ""):setTextStyle(clockStyle):setBehaviorByLabels{"canJoinAllSpaces"}
_xtras.drawingLevel(clock, _xtras.windowLevels.NSMainMenuWindowLevel)

local drawClock = function()
    local screenFrame = screen.mainScreen():fullFrame()
    local clockTime = os.date("%I:%M:%S %p")
    local clockPos = drawing.getTextDrawingSize(clockTime, clockStyle)
    clockPos.w = clockPos.w + 4
    clockPos.x = screenFrame.x + screenFrame.w - (clockPos.w + 4)
    clockPos.y = screenFrame.y + screenFrame.h - (clockPos.h + 4)
    clock:setText(clockTime):setFrame(clockPos)
end

local clockTimer = timer.new(1, drawClock)

module.showClock = function()
    drawClock()
    clock:show()
    clockTimer:start()
end

module.hideClock = function()
    clock:hide()
    clockTimer:stop()
end

module.toggleClock = function()
    if clockTimer:isRunning() then
        hideClock()
    else
        showClock()
    end
end

module.showClock()

return module
