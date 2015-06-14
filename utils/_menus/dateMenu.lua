local module = {
--[=[
    _NAME        = 'dateMenu',
    _VERSION     = '',
    _URL         = 'https://github.com/asmagill/hydra_config',
    _DESCRIPTION = [[

          Starting to replace itsyCal

    ]],
    _TODO        = [[]],
    _LICENSE     = [[ See README.md ]]
--]=]
}

local menubar    = require("hs.menubar")
local fontTables = require("utils.fontTables")
local alert      = require("hs.alert")
local timer      = require("hs.timer")
local drawing    = require("hs.drawing")
local screen     = require("hs.screen")
local mouse      = require("hs.mouse")

local dayInUTF8 = function(x)    --  U+2460-2473 = 1 - 20, U+3251-325F = 21 - 35
    if x < 21 then
        return fontTables.generateUTF8Character(0x245F + x)
    else
        return fontTables.generateUTF8Character(0x323C + x)
    end
end

local function secsToMidnight(z)
    local t = os.date("*t",z)
    t.hour=0    ; t.min=0    ; t.sec=0
    t.isdst=nil ; t.wday=nil ; t.yday=nil
    return os.time(t) + 86400 - os.time(os.date("*t",z))
end

local changeDay, changeDayFunction
changeDayFunction = function()
    menu:setTitle(tostring(dayInUTF8(os.date("*t").day)))
    changeDay = timer.doAfter(secsToMidnight(), changeDayFunction)
end

local visible = false

local textFont   = "Menlo"
local textSize   = 12
local blockSizeH = textSize * (4/3)
local blockSizeW = textSize * (2/3)

local edgeBuffer = 15

local calWidth   = 19
local calHeight  = 9
local textWidth  = blockSizeW * calWidth
local textHeight = blockSizeH * calHeight
local rectWidth  = textWidth  + 2 * edgeBuffer
local rectHeight = textHeight + 2 * edgeBuffer

local HLWidth    = blockSizeW  * 2
local HLHeight   = blockSizeH
local HLEdge     = 4

local HL         = drawing.rectangle{
                      x = 0,
                      y = 0,
                      h = HLHeight + 2,
                      w = HLWidth + 2
                  }:setFill(true):setStroke(false):setFillColor{
                      red = 1, blue = 1, green = 0, alpha = .6
                  }:setRoundedRectRadii(HLEdge, HLEdge)--:setStrokeWidth(4)

local rect       = drawing.rectangle{
                      x = 0,
                      y = 0,
                      h = rectHeight,
                      w = rectWidth
                  }:setFill(true):setStroke(false):setFillColor{
                      red = 0, blue = 0, green = 0, alpha = .8
                  }:setRoundedRectRadii(edgeBuffer, edgeBuffer)
local textRect   = drawing.text({
                      x = 0,
                      y = 0,
                      h = textHeight,
                      w = textWidth
                  },""):setTextFont(textFont):setTextSize(textSize):setTextColor{
                      red = 1, blue = 1, green = 1, alpha = 1
                  }

local menu

module.start = function()
    menu = menubar.new()
    menu:setTitle(tostring(dayInUTF8(os.date("*t").day)))
    menu:setClickCallback(function()
        menu:setTitle(tostring(dayInUTF8(os.date("*t").day))) -- just in case timing off

        if visible then
            HL:hide()
            textRect:hide()
            rect:hide()
        else
            local text    = _asm.extras.exec("cal")
            local frame   = screen.mainScreen():frame()
            local clickAt = mouse.getRelativePosition()

            rect:setTopLeft{
                x = frame.x + clickAt.x - rectWidth * .5,
                y = frame.y
            }:show()

            local t = os.date("*t")
            t.day=1 ; t.wday=nil ; t.yday=nil

            local wom = (os.date("*t").day -
                        (os.date("*t").wday - os.date("*t",os.time(t)).wday) - 1) /
                        7

-- I really need to dig into how NSTextView goes into NSView and figure out why lining things
-- up is so damn picky...
            local dayOffset  = (os.date("*t").wday - 1) * 3 * (blockSizeW - .75)
            local weekOffset = (2 + wom) * (blockSizeH + 2.5)
--                  dayOffset  = (1 - 1) * 3 * (blockSizeW - .75)
--                  weekOffset = (2 + 2) * (blockSizeH + 2.5)
            HL:setTopLeft{
                x = frame.x + clickAt.x - textWidth * .5 + dayOffset,
                y = frame.y + edgeBuffer + weekOffset
            }:show()

            textRect:setTopLeft{
                x = frame.x + clickAt.x - textWidth * .5,
                y = frame.y + edgeBuffer
            }:setText(text):show()

        end
        visible = not visible
    end)

    changeDay = timer.doAfter(secsToMidnight(), changeDayFunction)
    return module
end

module.stop = function()
    changeDay:stop()
    changeDay = nil

    visible = false
    HL:hide()
    textRect:hide()
    rect:hide()
    menu:delete()
    menu = nil
    return module
end

module = setmetatable(module, {
  __gc = function(self)
      if HL then HL:delete() ; HL = nil end
      if textRect then textRect:delete() ; textRect = nil end
      if rect then rect:delete() ; rect = nil end
  end,
})

return module.start()
