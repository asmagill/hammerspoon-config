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
local mods     = require("hs._asm.extras").mods
local hotkey   = require("hs.hotkey")
local window   = require("hs.window")

grid.GRIDHEIGHT = settings.get("_asm.gridHeight")  or 2
grid.GRIDWIDTH  = settings.get("_asm.gridWidth")   or 3
grid.MARGINX    = settings.get("_asm.gridMarginX") or 1
grid.MARGINY    = settings.get("_asm.gridMarginY") or 1

local change = function(command, direction)
    command = tostring(command)
    direction = tostring(direction)
    local win = window.focusedWindow()

    if win then
        local oldWinAnimationDuration
        local doChange = true
        local destScreen = win:screen()
        local state = grid.get(win)
        oldWinAnimationDuration, hs.window.animationDuration = hs.window.animationDuration, 0

        if command == "move" then
            if direction     == "left"  then
                state.x = state.x > 0 and state.x - 1 or state.x
            elseif direction == "right" then
                state.x = state.x + state.w < grid.GRIDWIDTH and state.x + 1 or state.x
            elseif direction == "up"    then
                state.y = state.y > 0 and state.y - 1 or state.y
            elseif direction == "down"  then
                state.y = state.y + state.h < grid.GRIDHEIGHT  and state.y + 1 or state.y
            else
                hs.alert.show("Invalid direction: "..direction)
            end
        elseif command == "stretch" then
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
            else
                hs.alert.show("Invalid direction: "..direction)
            end
        elseif command == "tall" then state.y = 0 ; state.h = grid.GRIDHEIGHT
        elseif command == "wide" then state.x = 0 ; state.w = grid.GRIDWIDTH
        elseif command == "max"  then state = { x = 0, y = 0, w = grid.GRIDWIDTH, h = grid.GRIDHEIGHT }
        elseif command == "next" then destScreen = destScreen:next()
        elseif command == "prev" then destScreen = destScreen:previous()
        elseif command ~= "snap" then
            hs.alert.show("Invalid command: "..command)
            doChange = false
        end

        if doChange then grid.set(win, state, destScreen) end
        --print((string.gsub(inspect({ destScreen:frame(), win:frame(), state }),"[\r\n ]+"," ")))
    else
        hs.alert.show("No window currently focused")
    end
    hs.window.animationDuration = oldWinAnimationDuration
end

local adjust = function(rows, columns)
        local new_height = grid.GRIDHEIGHT + rows
        local new_width  = grid.GRIDWIDTH  + columns

        if new_height == 0 then new_height = 1 end
        if new_width  == 0 then new_width  = 1 end

        grid.GRIDHEIGHT, grid.GRIDWIDTH = new_height, new_width
        hs.alert.show("Grid Size: "..grid.GRIDWIDTH.."x"..grid.GRIDHEIGHT)
end

-- Public interface ------------------------------------------------------

-- slide window
    hotkey.bind(mods.CASC, 'h', function() change("stretch", "left")  end, nil)
    hotkey.bind(mods.CASC, 'k', function() change("stretch", "up")    end, nil)
    hotkey.bind(mods.CASC, 'j', function() change("stretch", "down")  end, nil)
    hotkey.bind(mods.CASC, 'l', function() change("stretch", "right") end, nil)
    hotkey.bind(mods.CAsC, 'h', function() change("move",    "left")  end, nil)
    hotkey.bind(mods.CAsC, 'k', function() change("move",    "up")    end, nil)
    hotkey.bind(mods.CAsC, 'j', function() change("move",    "down")  end, nil)
    hotkey.bind(mods.CAsC, 'l', function() change("move",    "right") end, nil)
-- snap in place
    hotkey.bind(mods.CAsC, '.', function() change("snap") end, nil)
-- push window to different screen
    hotkey.bind(mods.CAsC, '[', function() change("prev") end, nil)
    hotkey.bind(mods.CAsC, ']', function() change("next") end, nil)
-- full-height window, full-width window, and a maximize
    hotkey.bind(mods.CAsC, 'm', function() change("max")  end, nil)
    hotkey.bind(mods.CAsC, 't', function() change("tall") end, nil)
    hotkey.bind(mods.CAsC, 'w', function() change("wide") end, nil)

-- adjust grid settings
    hotkey.bind(mods.CAsC, "up",    function() adjust( 1,  0) end, nil)
    hotkey.bind(mods.CAsC, "down",  function() adjust(-1,  0) end, nil)
    hotkey.bind(mods.CAsC, "left",  function() adjust( 0, -1) end, nil)
    hotkey.bind(mods.CAsC, "right", function() adjust( 0,  1) end, nil)
    hotkey.bind(mods.CAsC, "/",     function() adjust( 0,  0) end, nil) -- show current

-- center window
--hotkey.bind(mods.CAsC, 'c', function()actualWindow(winter:focused():vcenter():hcenter():place()), nil)
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
