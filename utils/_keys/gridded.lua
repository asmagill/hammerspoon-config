local module = {
--[=[
    _NAME        = '_keys.gridded',
    _VERSION     = 'the 1st digit of Pi/0',
    _URL         = 'https://github.com/asmagill/hammerspoon-config',
    _LICENSE     = [[ See README.md ]]
    _DESCRIPTION = [[]],
    _TODO        = [[

          Get rid of hs.alert and do something more like the visual aid does

    ]]
--]=]
}

-- private variables and methods -----------------------------------------

local grid        = require("hs.grid")
local settings    = require("hs.settings")
local mods        = require("hs._asm.extras").mods
local hotkey      = require("hs.hotkey")
local window      = require("hs.window")
local application = require("hs.application")
local alert       = require("hs.alert")
local fnutils     = require("hs.fnutils")
local mouse       = require("hs.mouse")

grid.GRIDHEIGHT = settings.get("_asm.gridHeight")  or 2
grid.GRIDWIDTH  = settings.get("_asm.gridWidth")   or 3
grid.MARGINX    = settings.get("_asm.gridMarginX") or 5
grid.MARGINY    = settings.get("_asm.gridMarginY") or 5

grid.GRIDHEIGHT = math.floor(grid.GRIDHEIGHT)
grid.GRIDWIDTH  = math.floor(grid.GRIDWIDTH)
grid.MARGINX    = math.floor(grid.MARGINX)
grid.MARGINY    = math.floor(grid.MARGINY)

local point_in_rect = function(rect, point)
    return  point.x >= rect.x and
            point.y >= rect.y and
            point.x <= rect.x + rect.w and
            point.y <= rect.y + rect.h
end

--grid.ui.fontName = "Papyrus"
grid.ui.textSize = 32

local change = function(command, direction, win)
    if type(direction) == "userdata" then
        win = direction
        direction = nil
    end
    win = win or window.focusedWindow()
--    if not win then
--    -- no window returned by focusedWindow, so check for window under mouse
--        local pos = mouse.get()
--        win = fnutils.find(window.orderedWindows(), function(window)
--            return point_in_rect(window:frame(), pos)
--        end)
--    -- if we got one, make sure it's in the active app
--        if win then print(win:application():title(),application.frontmostApplication():title()) end
--        if win and win:application():title() ~= application.frontmostApplication():title() then
--            win = nil
--        end
--    end

    if win then
        local oldWinAnimationDuration = window.animationDuration
        local doAction = true
        window.animationDuration = 0

        local action = [[ alert.show("Invalid command: ]]..command..[[") ]]

        if command == "push" or command == "resize"   then action = "grid."..command.."Window"..direction:gsub("^([durltsw])",string.upper).."(win)"
        elseif command == "next" or command == "prev" then action = "grid.pushWindow"..command:gsub("^([np])",string.upper).."Screen(win)"
        elseif command == "max"                       then action = "grid.maximizeWindow(win)"
        elseif command == "snap"                      then action = "grid.snap(win)"
        elseif command == "visual"                    then action = "grid.show()"

        elseif command == "tall" or command == "wide" then
        -- modifying the result of get and supplying it back to set the way this function does
        -- resulted in a `Cannot create geometry object, wrong arguments` error
            local tmp = grid.get(win)
            local state = { x = tmp.x, y = tmp.y, h = tmp.h, w = tmp.w }
            if command == "tall" then
                state.y = 0
                state.h = grid.GRIDHEIGHT
            else
                state.x = 0
                state.w = grid.GRIDWIDTH
            end
            action = "grid.set(win,{"
            for i,v in pairs(state) do action = action..i.."="..tostring(v).."," end
            action = action.."})"

        elseif command == "center" or command == "scale" then
            doAction = false -- this one is special and outside of grid's prevue

            local percentage = (type(direction) == "number") and direction or 1.0
            -- this allows for increasing size, but assumes anything above 10x means they forgot
            -- to provide a decimal percentage
            if percentage > 10.0 then percentage = percentage / 100 end

            local wFrame = win:frame()
            local sFrame = win:screen():frame()

            wFrame.h = wFrame.h * percentage
            wFrame.w = wFrame.w * percentage
            if command == "center" then
                wFrame.x = sFrame.x + (sFrame.w - wFrame.w) / 2
                wFrame.y = sFrame.y + (sFrame.h - wFrame.h) / 2
            end
            win:setFrame(wFrame)
        end
--         print(inspectnm(action))
        if doAction then -- otherwise, it was handled in the above checks
            load(action,"gridded change","t",{grid=grid, win=win, alert=alert})()
        end

        window.animationDuration = oldWinAnimationDuration
    else
        alert.show("No window currently focused")
    end
end

local settingsShow = function()
        alert.show("  Grid Size: "..grid.GRIDWIDTH.."x"..grid.GRIDHEIGHT.."\n"
                 .."Margin Size: "..grid.MARGINX.."x"..grid.MARGINY
        )
end

local adjustGrid = function(rows, columns)
    return function()
        grid.setGrid({
            w = math.max(grid.GRIDWIDTH  + columns, 1),
            h = math.max(grid.GRIDHEIGHT + rows,    1)
        })
        settingsShow()
    end
end

local adjustMargins = function(rows, columns)
    return function()
        grid.setMargins({
            w = math.max(grid.MARGINX + columns, 0),
            h = math.max(grid.MARGINY + rows,    0)
        })
        settingsShow()
    end
end

local gridAction = function(...)
    local tmp = table.pack(...)
    return function() change(table.unpack(tmp)) end
end

-- Public interface ------------------------------------------------------

-- slide/stretch window
    hotkey.bind(mods.CAsC, 'h', gridAction("push",   "left"),    nil, gridAction("push",   "left"))
    hotkey.bind(mods.CAsC, 'k', gridAction("push",   "up"),      nil, gridAction("push",   "up"))
    hotkey.bind(mods.CAsC, 'j', gridAction("push",   "down"),    nil, gridAction("push",   "down"))
    hotkey.bind(mods.CAsC, 'l', gridAction("push",   "right"),   nil, gridAction("push",   "right"))

    hotkey.bind(mods.CASC, 'h', gridAction("resize", "thinner"), nil, gridAction("resize", "thinner"))
    hotkey.bind(mods.CASC, 'k', gridAction("resize", "taller"),  nil, gridAction("resize", "taller"))
    hotkey.bind(mods.CASC, 'j', gridAction("resize", "shorter"), nil, gridAction("resize", "shorter"))
    hotkey.bind(mods.CASC, 'l', gridAction("resize", "wider"),   nil, gridAction("resize", "wider"))

-- snap in place
    hotkey.bind(mods.CAsC, '.', gridAction("snap"))
    hotkey.bind(mods.CAsC, ',', function() fnutils.map(window.visibleWindows(), grid.snap) end)

-- push window to different screen
    hotkey.bind(mods.CAsC, '[', gridAction("prev"))
    hotkey.bind(mods.CAsC, ']', gridAction("next"))

-- full-height window, full-width window, and a maximize
    hotkey.bind(mods.CAsC, 'm', gridAction("max"))
    hotkey.bind(mods.CAsC, 't', gridAction("tall"))
    hotkey.bind(mods.CAsC, 'w', gridAction("wide"))

-- adjust grid settings
    hotkey.bind(mods.CAsC, "up",    adjustGrid( 1,  0), nil, adjustGrid( 1,  0))
    hotkey.bind(mods.CAsC, "down",  adjustGrid(-1,  0), nil, adjustGrid(-1,  0))
    hotkey.bind(mods.CAsC, "left",  adjustGrid( 0, -1), nil, adjustGrid( 0, -1))
    hotkey.bind(mods.CAsC, "right", adjustGrid( 0,  1), nil, adjustGrid( 0,  1))
    hotkey.bind(mods.CAsC, "/",     adjustGrid( 0,  0)) -- show current

    hotkey.bind(mods.CASC, "up",    adjustMargins( 1,  0), nil, adjustMargins( 1,  0))
    hotkey.bind(mods.CASC, "down",  adjustMargins(-1,  0), nil, adjustMargins(-1,  0))
    hotkey.bind(mods.CASC, "left",  adjustMargins( 0, -1), nil, adjustMargins( 0, -1))
    hotkey.bind(mods.CASC, "right", adjustMargins( 0,  1), nil, adjustMargins( 0,  1))

-- visual aid
    hotkey.bind(mods.CAsC, "v", gridAction("visual"))

-- center window
hotkey.bind(mods.CASC, 'c', gridAction("center"))
local centerKey = hotkey.modal.new(mods.CAsC, "c")
    fnutils.each({
        { key = "1", size = 0.1 }, { key = "2", size =  0.2 },
        { key = "3", size = 0.3 }, { key = "4", size =  0.4 },
        { key = "5", size = 0.5 }, { key = "6", size =  0.6 },
        { key = "7", size = 0.7 }, { key = "8", size =  0.8 },
        { key = "9", size = 0.9 }, { key = "0", size =  1.0 },
        { key = "q", size = 1.0 }, { key = "w", size =  2.0 },
        { key = "e", size = 3.0 }, { key = "r", size =  4.0 },
        { key = "t", size = 5.0 }, { key = "y", size =  6.0 },
        { key = "u", size = 7.0 }, { key = "i", size =  8.0 },
        { key = "o", size = 9.0 }, { key = "p", size = 10.0 },
    },
        function(object)
            centerKey:bind(mods.casc, object.key,
                function() change("center", object.size) end,
                function() centerKey:exit() end
            )
        end
    )

    function centerKey:entered() alert("Select % for Center")         end
    function centerKey:exited() alert("Thank you, please come again") end
centerKey:bind(mods.casc, "ESCAPE", function() centerKey:exit()       end)

-- scale window
local resizeKey = hotkey.modal.new(mods.CAsC, "s")
    fnutils.each({
        { key = "1", size = 0.1 }, { key = "2", size =  0.2 },
        { key = "3", size = 0.3 }, { key = "4", size =  0.4 },
        { key = "5", size = 0.5 }, { key = "6", size =  0.6 },
        { key = "7", size = 0.7 }, { key = "8", size =  0.8 },
        { key = "9", size = 0.9 }, { key = "0", size =  1.0 },
        { key = "q", size = 1.0 }, { key = "w", size =  2.0 },
        { key = "e", size = 3.0 }, { key = "r", size =  4.0 },
        { key = "t", size = 5.0 }, { key = "y", size =  6.0 },
        { key = "u", size = 7.0 }, { key = "i", size =  8.0 },
        { key = "o", size = 9.0 }, { key = "p", size = 10.0 },
    },
        function(object)
            resizeKey:bind(mods.casc, object.key,
                function() change("scale", object.size) end,
                function() resizeKey:exit() end
            )
        end
    )

    function resizeKey:entered() alert("Select % for Resize")         end
    function resizeKey:exited() alert("Thank you, please come again") end
resizeKey:bind(mods.casc, "ESCAPE", function() resizeKey:exit()       end)

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
