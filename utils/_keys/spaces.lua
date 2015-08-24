local mouse    = require("hs.mouse")
local event    = require("hs.eventtap").event
local window   = require("hs.window")
local timer    = require("hs.timer")

--
-- if you're perusing this and want to see an Objective-C version, check https://github.com/asmagill/hammerspoon_asm/commit/f97def364003b0a7e96b8fa340b7b8bc48859238#diff-feb9be9f18e8db07162fbca403313598R191.
--
-- I'm still not sure which I'll be sticking with...

--- spacesKeySequence([key],[win],[mod]) -> None
--- Function
--- Preforms Mission Control key sequences (and clicks, when a window or point is provided) for spaces.
---
--- Parameters:
---  * key - the string representing the keyboard character which is to be "pressed" -- defaults to the right arrow ("right") -- see hs.keycodes.map for other keys.
---  * win - a hs.window object or point table indicating where the mouse pointer and mouse click should occur for the trigger. Defaults to no window.
---  * mod - a table containing the keyboard modifiers to be "pressed".  Defaults to { "ctrl" }. The following values are allowed in this table:
---   * cmd
---   * alt
---   * shift
---   * ctrl
---   * fn
---
--- Notes:
---  * The only semi-reliable way to move windows around in Spaces is to take advantage of the fact that we can simulate the keypresses which are defined for Mission Control and Spaces in the Keyboard Shortcuts System Preferences Panel.  That is what this function is intended for.  It will have no effect if you disabled these shortcuts.  By default they are defined as:
---    * Ctrl-# - jump to a specific space, or if a window title bar is being clicked on when pressed, move the window to the specific space.
---    * Ctrl-Right Arrow - move (or move a window) one space to the right.
---    * Ctrl-Left Arrow - move (or move a window) one space to the left.
---    * Ctrl-Up Arrow - show the Mission Control panel (has no effect if a window is clicked on during this keypress)
---    * Ctrl-Down Arror - show the Application Windows screen (has no effect if a window is clicked on during this keypress)
---  * Technically this could probably replicate almost any Keyboard Shortcut from the System Preferences Panel, but only Spaces has been tested.
---  * For window movement, if a window is provided, it will be brought into focus and the mouse moved for the click and keypress.
---  * If a point table ({ x = #, y= # }) is provided instead of a window, no window focus is performed -- it is assumed that you have already done so or that you know what you are doing.  This is supported in case some window is found to have a different acceptable click region for inclusion in Space moves, or in case this function turns out to be useful in other contexts.
---  * This function performs the following steps (unfortunately I couldn't seem to get the timing right using hs.eventtap.events, though I may try again at another date since it should be possible.) -- edit: maybe I just did... hmm... keep this for reference/legacy?
---    * If a window is provided, focus it and get it's topLeft corner.  Set the targetMouseLocation to just between the Close Circle and the Minimize Circle in its title bar.
---    * If a point table is provided, set the targetMouseLocation to the provided point.
---    * If a targetMouseLocation is set, move the mouse to it and perform a leftClickDown event
---    * perform a keyDown event with the provided key and modifiers (or default Ctrl-Right Arrow, if none are provided)
---    * perform a keyUp event with the same key and modifiers
---    * If a targetMouseLocation is set, perform a leftClickUp event.

spacesKeySequence = function(key, win, mods)
--     print(tostring(win))
    local originalMousePosition = mouse.getAbsolutePosition()
    local doingWindow = false

    key  = key  or "right"
    mods = mods or {"ctrl"}

    local moveMouseTo = originalMousePosition
    if type(win) == "userdata" then
        doingWindow = true
        win:focus()
        timer.usleep(200000)
        moveMouseTo = { x=win:frame().x + 24, y = win:frame().y + 4 }
    elseif type(win) == "table" then
        doingWindow = true
        moveMouseTo = win
    else
        win = nil
    end

    local mouseDown, mouseUp, keyDown, keyUp
    if doingWindow then
        mouseDown = event.newMouseEvent(event.types.leftMouseDown, moveMouseTo, {})
        mouseUp   = event.newMouseEvent(event.types.leftMouseUp,   moveMouseTo, {})
    end
    keyDown   = event.newKeyEvent(mods, key, true)
    keyUp     = event.newKeyEvent({}, key, false)

    mouse.setAbsolutePosition(moveMouseTo)
    if doingWindow then
        mouseDown:post()
        timer.usleep(125000)
    end
    keyDown:post()
    timer.usleep(125000)
    keyUp:post()
    if doingWindow then
        mouseUp:post()
        timer.usleep(125000)
        mouse.setAbsolutePosition(originalMousePosition)
    end
end

local mods     = require("hs._asm.extras").mods
local hotkey   = require("hs.hotkey")
local fnutils  = require("hs.fnutils")
local geometry = require("hs.geometry")
local myMCmod  = {"ctrl"}

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

hotkey.bind(mods.cAsC, "1", nil, function() spacesKeySequence("1", pickWindow(), myMCmod) end)
hotkey.bind(mods.cAsC, "2", nil, function() spacesKeySequence("2", pickWindow(), myMCmod) end)
hotkey.bind(mods.cAsC, "3", nil, function() spacesKeySequence("3", pickWindow(), myMCmod) end)
hotkey.bind(mods.cAsC, "4", nil, function() spacesKeySequence("4", pickWindow(), myMCmod) end)
hotkey.bind(mods.cAsC, "5", nil, function() spacesKeySequence("5", pickWindow(), myMCmod) end)
hotkey.bind(mods.cAsC, "6", nil, function() spacesKeySequence("6", pickWindow(), myMCmod) end)
hotkey.bind(mods.cAsC, "7", nil, function() spacesKeySequence("7", pickWindow(), myMCmod) end)
hotkey.bind(mods.cAsC, "8", nil, function() spacesKeySequence("8", pickWindow(), myMCmod) end)
hotkey.bind(mods.cAsC, "9", nil, function() spacesKeySequence("9", pickWindow(), myMCmod) end)

hotkey.bind(mods.cAsC, "right", nil, function() spacesKeySequence("right", pickWindow(), myMCmod) end)
hotkey.bind(mods.cAsC, "left",  nil, function() spacesKeySequence("left",  pickWindow(), myMCmod) end)
