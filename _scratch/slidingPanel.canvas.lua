local timer  = require("hs.timer")
local canvas = require("hs.canvas")
local screen = require("hs.screen")

local MAXSTEPS = 10 -- how many steps should the panel take to go from full close to full open or vice-versa

local module = {}
local _canvas, _sensor
local _frame
local resetOnCurrentScreen = function()
    _frame = screen.mainScreen():fullFrame()
    _canvas:frame{ x = _frame.x, y = _frame.y + _frame.h,     h = _frame.h / 2, w = _frame.w }
    _sensor:frame{ x = _frame.x, y = _frame.y + _frame.h - 1, h = 1,            w = _frame.w }
    _sensor:orderAbove(_canvas)
end

local _targetCount, _count, _dir
local startPanelTimer = function()
    return timer.doEvery(0.5 / MAXSTEPS, function()
        if _count == 0 and _targetCount == MAXSTEPS then _canvas:show() end
        _count = _count + _dir
        _canvas:topLeft{ x = _frame.x, y = _frame.y + _frame.h * ( 1 - _count / (2 * MAXSTEPS) ) }
        if _count == 0 and _targetCount == 0 then _canvas:hide() end
        if _count == _targetCount then
            module._panelMoveTimer:stop()
            module._panelMoveTimer = nil
        end
    end)
end
_canvas = canvas.new{}:level("status")
_sensor = canvas.new{}:level("status"):behavior("canJoinAllSpaces"):orderAbove(_canvas)
                      :canvasMouseEvents(false, false, true, false)
                      :mouseCallback(function(c, m, i, x, y)
                          if m == "mouseEnter" then
                              _targetCount, _dir = MAXSTEPS, 1
                              if not module._panelMoveTimer then
                                  _count = 0
                                  module._panelMoveTimer = startPanelTimer()
                              end
                          elseif m == "mouseExit" then
                              _targetCount, _dir = 0, -1
                              if not module._panelMoveTimer then
                                  _count = MAXSTEPS
                                  module._panelMoveTimer = startPanelTimer()
                              end
                          end
                      end):show()
resetOnCurrentScreen()

_canvas[#_canvas + 1] = {
    type             = "rectangle",
    id               = "backPanel",
    strokeWidth      = 10,
    fillColor        = { alpha = .5 },
    strokeColor      = { alpha = .7 },
    roundedRectRadii = {xRadius = 10, yRadius = 10},
    clipToPath       = true,
}

module._canvas = _canvas
module._sensor = _sensor

return module
