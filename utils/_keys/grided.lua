local module = {
--[=[
    _NAME        = '_keys.gridded',
    _VERSION     = 'the 1st digit of Pi/0',
    _URL         = 'https://github.com/asmagill/hammerspoon-config',
    _LICENSE     = [[ See README.md ]]
    _DESCRIPTION = [[]],
--]=]
}

-- private variables and methods -----------------------------------------

local grid     = require("hs.grid")
local settings = require("hs.settings")
local mods     = require("hs.extras").mods
local hotkey   = require("hs.hotkey")
local window   = require("hs.window")

grid.GRIDHEIGHT = settings.get("_asm.gridHeight")  or 2
grid.GRIDWIDTH  = settings.get("_asm.gridWidth")   or 3
grid.MARGINX    = settings.get("_asm.gridMarginX") or 2
grid.MARGINY    = settings.get("_asm.gridMarginY") or 2

function slide(direction)
    direction = tostring(direction)
    return function()
        local win = window.focusedWindow()
        if win then
            local oldWinAnimationDuration
            local doSlide = true
            local destScreen = win:screen()
            local state = grid.get(win)

            oldWinAnimationDuration, hs.window.animationDuration = hs.window.animationDuration, 0

            if direction == "left" then
                if state.x == 0 then
                    state.w = state.w > 1 and state.w - 1 or 1
                else
                    state.x = state.x - 1
                    state.w = state.w < grid.GRIDWIDTH and state.w + 1 or grid.GRIDWIDTH
                end
            elseif direction == "right" then
                if state.x + state.w == grid.GRIDWIDTH then
                    state.x = state.x < grid.GRIDWIDTH - 1 and state.x + 1 or grid.GRIDWIDTH - 1
                    state.w = state.w > 1 and state.w - 1 or 1
                else
                    state.w = state.w < grid.GRIDWIDTH and state.w + 1 or grid.GRIDWIDTH
                end
            elseif direction == "up" then
                if state.y == 0 then
                    state.h = state.h > 1 and state.h - 1 or 1
                else
                    state.y = state.y - 1
                    state.h = state.h < grid.GRIDHEIGHT and state.h + 1 or grid.GRIDHEIGHT
                end
            elseif direction == "down" then
                if state.y + state.h == grid.GRIDHEIGHT then
                    state.y = state.y < grid.GRIDHEIGHT - 1 and state.y + 1 or grid.GRIDHEIGHT - 1
                    state.h = state.h > 1 and state.h - 1 or 1
                else
                    state.h = state.h < grid.GRIDHEIGHT and state.h + 1 or grid.GRIDHEIGHT
                end
            elseif direction == "next" then destScreen = destScreen:next()
            elseif direction == "prev" then destScreen = destScreen:previous()
            elseif direction ~= "here" then
                hs.alert.show("Invalid direction: "..direction)
                doSlide = false
            end
            if doSlide then grid.set(win, state, destScreen end
            --print((string.gsub(inspect({ destScreen:frame(), win:frame(), state }),"[\r\n ]+"," ")))
        else
            hs.alert.show("No window currently focused")
        end
        hs.window.animationDuration = oldWinAnimationDuration
    end
end

-- Public interface ------------------------------------------------------

-- slide window
hotkey.bind(mods.CAsC, 'h', slide("left"),  nil)
hotkey.bind(mods.CAsC, 'k', slide("up"),    nil)
hotkey.bind(mods.CAsC, 'j', slide("down"),  nil)
hotkey.bind(mods.CAsC, 'l', slide("right"), nil)

---- snap in place
hotkey.bind(mods.CAsC, '.', slide("here"),  nil)

---- push window to different screen
hotkey.bind(mods.CAsC, '[', slide("prev"),  nil)
hotkey.bind(mods.CAsC, ']', slide("next"),  nil)

--
---- center window
--hotkey.bind(mods.CAsC, 'c', function()actualWindow(winter:focused():vcenter():hcenter():place()))
--
---- full-height window, full-width window, and a maximize
--hotkey.bind(mods.CAsC, 't', actualWindow(winter:focused():tallest():resize()))
--hotkey.bind(mods.CAsC, 'w', actualWindow(winter:focused():widest():resize()))
--hotkey.bind(mods.CAsC, 'm', actualWindow(winter:focused():widest():tallest():resize()))
--hotkey.bind(mods.CASC, 'm', actualWindow(function()
--        window.focusedWindow():setFullScreen(not window.focusedWindow():isFullScreen())
--    end)
--)
--

-- Return Module Object --------------------------------------------------

setmetatable(module, {
    __gc = function(me)
        settings.set("_asm.gridHeight",  grid.GRIDHEIGHT)
        settings.set("_asm.gridWidth",   grid.GRIDWIDTH)
        settings.set("_asm.gridMarginX", grid.MARGINX)
        settings.set("_asm.gridMarginY", grid.MARGINY)
    end
})

return module
