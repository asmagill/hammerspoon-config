local mouse    = require("hs.mouse")
local eventtap = require("hs.eventtap")
local event    = eventtap.event
local window   = require("hs.window")
local timer    = require("hs.timer")
local spacesX  = require("hs._asm.undocumented.spaces")
local mods           = require("hs._asm.extras").mods
local hotkey         = require("hs.hotkey")
local fnutils        = require("hs.fnutils")
local geometry       = require("hs.geometry")
local spacesModifier = {"ctrl"}


local function spacesKeySequence(space, win)
  local clickPoint = win:zoomButtonRect()
  local sleepTime = 10000
  local mousePosition = mouse.getAbsolutePosition()

  clickPoint.x = clickPoint.x + clickPoint.w + 5
  clickPoint.y = clickPoint.y + clickPoint.h / 2

  event.newMouseEvent(event.types.leftMouseDown, clickPoint):post()
  timer.usleep(sleepTime)
  eventtap.keyStroke(spacesModifier, space)
  timer.usleep(sleepTime)
  while (spacesX.isAnimating()) do end
  timer.usleep(sleepTime)
  event.newMouseEvent(event.types.leftMouseUp, clickPoint):post()
  timer.usleep(sleepTime)
  mouse.setAbsolutePosition(mousePosition)
end

local pickWindow = function()
    return fnutils.find(window.orderedWindows(), function(_)
        return geometry.isPointInRect(mouse.getAbsolutePosition(), _:frame()) and _:isStandard()
    end)
end

-- having key modifiers down when doing the spacesKeySequence doesn't work without the mouse clicks, so
-- this doesn't work so well for window = nil and changing the space without moving anything...
--
-- probably a bug in eventtap which doesn't fully clear the keyboard modifiers before setting the new
-- ones... see http://ianyh.com/blog/2013/06/05/accessibility/.
--
-- oh well, this works well enough and that's a problem for another day.

hotkey.bind(mods.cAsC, "1", nil, function() spacesKeySequence("1", pickWindow()) end)
hotkey.bind(mods.cAsC, "2", nil, function() spacesKeySequence("2", pickWindow()) end)
hotkey.bind(mods.cAsC, "3", nil, function() spacesKeySequence("3", pickWindow()) end)
hotkey.bind(mods.cAsC, "4", nil, function() spacesKeySequence("4", pickWindow()) end)
hotkey.bind(mods.cAsC, "5", nil, function() spacesKeySequence("5", pickWindow()) end)
hotkey.bind(mods.cAsC, "6", nil, function() spacesKeySequence("6", pickWindow()) end)
hotkey.bind(mods.cAsC, "7", nil, function() spacesKeySequence("7", pickWindow()) end)
hotkey.bind(mods.cAsC, "8", nil, function() spacesKeySequence("8", pickWindow()) end)
hotkey.bind(mods.cAsC, "9", nil, function() spacesKeySequence("9", pickWindow()) end)

hotkey.bind(mods.cAsC, "right", nil, function() spacesKeySequence("right", pickWindow()) end)
hotkey.bind(mods.cAsC, "left",  nil, function() spacesKeySequence("left",  pickWindow()) end)
