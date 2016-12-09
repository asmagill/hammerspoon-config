
-- add easy way for lua code to be the text source for a geeklet

local module = {
--[=[
    _NAME        = 'GeekTool Replacement',
    _VERSION     = 'the 3rd digit of Pi/0',
    _URL         = 'https://github.com/asmagill/hammerspoon-config',
    _LICENSE     = [[ See README.md ]]
    _DESCRIPTION = [[]],
--]=]
}

local fnutils    = require("hs.fnutils")
local drawing    = require("hs.drawing")
local stext      = require("hs.styledtext")
local task       = require("hs.task")
local timer      = require("hs.timer")
-- local caffeinate = require("hs.caffeinate")

local log        = require("hs.logger").new("geeklets","warning")
module.log       = log

-- private variables and methods -----------------------------------------

local registeredGeeklets = {}

local orderDrawings = function(name)
    if registeredGeeklets[name].isVisible then
        for i = #registeredGeeklets[name].drawings, 2, -1 do
            registeredGeeklets[name].drawings[i]:orderBelow(registeredGeeklets[name].drawings[1])
        end
    end
end

local GeekTimer = timer.new(1, function()
    for i,v in pairs(registeredGeeklets) do
        if (v.lastRun + v.period) <= os.time() then
            if v.enabled then
                if v.kind == "task" then
                    if v.task and v.task:isRunning() then
                        if (v.lastNotified + 60) < os.time() then
                            log.wf("%s: is still running -- either period is too short or it has hung", v.name)
                            v.lastNotified = os.time()
                        end
                    else
                        v.task = task.new(v.path, function(c, o, e)
                            if c ~= 0 then
                                log.wf("%s: status: %d error:%s output:%s", v.name, c, e, o)
                            end
                            v.drawings[1]:setStyledText(stext.ansi(o, v.textStyle))
                            v.lastNotified = 0
                            v.task = nil
                        end)
                        v.lastRun = os.time()
                        v.task:start()
                    end
                elseif v.kind == "lua" then
                    local state, result = nil, ""
                    if type(v.code) == "function" then
                        state, result = pcall(v.code)
                    else
                        state, result = pcall(dofile, v.code)
                    end
                    if state then
                        if result then
                            if v.isAlreadyStyled then
                                v.drawings[1]:setStyledText(result)
                            else
                                v.drawings[1]:setStyledText(stext.ansi(result, v.textStyle))
                            end
                        else
                            v.drawings[1]:hide()
                        end
                        v.lastRun = os.time()
                        v.lastNotified = 0
                    else
                        if (v.lastNotified + 60) < os.time() then
                            log.wf("%s: error %s", v.name, tostring(result))
                            local errorStyle = {}
                            for i,v in pairs(v.textStyle) do errorStyle[i] = v end
                            errorStyle.color = {red=1}
                            errorStyle.font = stext.convertFont(v.textStyle.font, stext.fontTraits.italicFont)
                            v.drawings[1]:setStyledText(stext.ansi(tostring(result), errorStyle))
                            v.lastNotified = os.time()
                        end
                    end
                end
                orderDrawings(v.name)
            end
        end
    end
end)

-- local geekletSleepWatcher = caffeinate.watcher.new(function(event)
--     if event == caffeinate.watcher.systemDidWake then
--         for i,v in pairs(registeredGeeklets) do
--             v.lastNotified = 0
--         end
--     elseif event == caffeinate.watcher.systemWillSleep then
--         for i,v in pairs(registeredGeeklets) do
--             if v.task and v.task:isRunning() then
--                 v.task:setCallback(nil):terminate()
--             end
--         end
--     end
-- end):start()

local watchable = require("hs.watchable")
module.watchCaffeinatedState = watchable.watch("generalStatus.caffeinatedState", function(w, p, i, old, new)
    if new == 1 then -- systemWillSleep
        for i,v in pairs(registeredGeeklets) do
            if v.task and v.task:isRunning() then
                v.task:setCallback(nil):terminate()
            end
        end
    elseif new == 0 then -- systemDidWake
        for i,v in pairs(registeredGeeklets) do
            v.lastNotified = 0
        end
    end
end)

-- Change the defaults in here if you don't like mine!

local registerGeeklet = function(kind, name, period, path, frame, textStyle, otherDrawings)
    assert(kind == "lua" or kind == "task", "Unknown geeklet type: "..tostring(kind))
    local code = nil
    if kind == "lua" then code, path = path, nil end

    local theStyle, theDrawings = textStyle, otherDrawings

    -- take advantage of the fact that textStyle is a table while otherDrawings is an array
    if type(textStyle) == "table" and #textStyle ~= 0 then
        theDrawings = textStyle
        theStyle    = {}
    end
    if not theStyle.font then theStyle.font = { name = "Menlo", size = 12 } end

    if not registeredGeeklets[name] then
        registeredGeeklets[name] = setmetatable({
                kind            = kind,
                name            = name,
                period          = period,
                path            = path,
                code            = code,
                frame           = frame,
                textStyle       = theStyle,
                isAlreadyStyled = theStyle.skip,
                isVisible       = true,
                enabled         = false,
                lastRun         = -1,
                lastNotified    = -1,
                shouldHover     = false,
                isOnAllSpaces   = true,
                layer           = true,
                drawings        = theDrawings,
            }, {
            __index = {
                start       = module.start,
                stop        = module.stop,
                delete      = module.delete,
                visible     = module.visible,
                toggle      = module.toggle,
                hover       = module.hover,
                onAllSpaces = module.onAllSpaces,
                wantsLayer  = module.wantsLayer,
            }
        })

        table.insert(registeredGeeklets[name].drawings, 1, drawing.text(frame, " "))
    else
        error(name.." is already registered", 2)
    end
    return registeredGeeklets[name]:hover(registeredGeeklets[name].shouldHover)
                                   :visible(registeredGeeklets[name].isVisible)
                                   :wantsLayer(registeredGeeklets[name].layer)
                                   :onAllSpaces(registeredGeeklets[name].isOnAllSpaces)
end

-- Public interface ------------------------------------------------------

module.registerLuaGeeklet = function(name, period, code, frame, textStyle, otherDrawings)
    assert(type(name)   == "string", "Argument 1, Name, must be specified as a string")
    assert(type(period) == "number", "Argument 2, Period, must be specified as a number")
    assert(type(code)   == "string" or type(code) == "function", "Argument 3, Path, must be specified as a string or a function")
    assert(type(frame)  == "table",  "Argument 4, Frame, must be specified as a table")
    return registerGeeklet("lua", name, period, code, frame, textStyle, otherDrawings)
end

module.registerShellGeeklet = function(name, period, path, frame, textStyle, otherDrawings)
    assert(type(name)   == "string", "Argument 1, Name, must be specified as a string")
    assert(type(period) == "number", "Argument 2, Period, must be specified as a number")
    assert(type(path)   == "string", "Argument 3, Path, must be specified as a string")
    assert(type(frame)  == "table",  "Argument 4, Frame, must be specified as a table")
    return registerGeeklet("task", name, period, path, frame, textStyle, otherDrawings)
end

module.start = function(name)
    local iReturn = name
    if type(name) == "table" then name = name.name end
    if not registeredGeeklets[name] then
        error(name.." is not registered", 2)
    else
        registeredGeeklets[name].enabled = true
    end
    return iReturn
end

module.stop = function(name)
    local iReturn = name
    if type(name) == "table" then name = name.name end
    if not registeredGeeklets[name] then
        error(name.." is not registered", 2)
    else
        registeredGeeklets[name].enabled = false
    end
    return iReturn
end

module.delete = function(name)
    local iReturn = name
    if type(name) == "table" then name = name.name end
    if not registeredGeeklets[name] then
        error(name.." is not registered", 2)
    else
        registeredGeeklets[name]:stop()
--         for j,k in ipairs(registeredGeeklets[name].drawings) do
--             k:delete()
        for k = #registeredGeeklets[name].drawings, 1, -1 do
            registeredGeeklets[name].drawings[k]:delete()
        end
        registeredGeeklets[name].drawings = nil
        registeredGeeklets[name] = nil
    end
end

module.visible = function(name, state)
    local iReturn = name
    if type(name) == "table" then name = name.name end
    if not registeredGeeklets[name] then
        error(name.." is not registered", 2)
    else
        if state == nil then return registeredGeeklets[name].isVisible end
--         for i,v in ipairs(registeredGeeklets[name].drawings) do
--             if state then v:show() else v:hide() end
        for v = #registeredGeeklets[name].drawings, 1, -1 do
            if state then
                registeredGeeklets[name].drawings[v]:show()
            else
                registeredGeeklets[name].drawings[v]:hide()
            end
        end
        registeredGeeklets[name].isVisible = state
        orderDrawings(name)
    end
    return iReturn
end

module.hover = function(name, state)
    local iReturn = name
    if type(name) == "table" then name = name.name end
    if not registeredGeeklets[name] then
        error(name.." is not registered", 2)
    else
        if state == nil then return registeredGeeklets[name].shouldHover end
--         for i,v in ipairs(registeredGeeklets[name].drawings) do
        for v = #registeredGeeklets[name].drawings, 1, -1 do
            if state then
--                 v:setLevel(drawing.windowLevels.popUpMenu)
                registeredGeeklets[name].drawings[v]:setLevel(drawing.windowLevels.popUpMenu)
            else
--                 v:setLevel(drawing.windowLevels.desktopIcon)
                registeredGeeklets[name].drawings[v]:setLevel(drawing.windowLevels.desktopIcon)
            end
        end
        registeredGeeklets[name].shouldHover = state
        orderDrawings(name)
    end
    return iReturn
end

module.toggle = function(name)
    if type(name) == "table" then name = name.name end
    return module.visible(name, not registeredGeeklets[name].isVisible)
end

module.wantsLayer = function(name, state)
    local iReturn = name
    if type(name) == "table" then name = name.name end
    if not registeredGeeklets[name] then
        error(name.." is not registered", 2)
    else
        if state == nil then return registeredGeeklets[name].layer end
        registeredGeeklets[name].drawings[1]:wantsLayer(state)
        registeredGeeklets[name].layer = state
    end
    return iReturn
end

module.onAllSpaces = function(name, state)
    local iReturn = name
    if type(name) == "table" then name = name.name end
    if not registeredGeeklets[name] then
        error(name.." is not registered", 2)
    else
        if state == nil then return registeredGeeklets[name].isOnAllSpaces end
--         for j,k in ipairs(registeredGeeklets[name].drawings) do
        for k = #registeredGeeklets[name].drawings, 1, -1 do
            if state then
--                 k:setBehaviorByLabels{"canJoinAllSpaces"}
                registeredGeeklets[name].drawings[k]:setBehaviorByLabels{"canJoinAllSpaces"}
            else
--                 k:setBehaviorByLabels{"default"}
                registeredGeeklets[name].drawings[k]:setBehaviorByLabels{"default"}
            end
        end
        registeredGeeklets[name].onAllSpaces = state
    end
    return iReturn
end

module.status = function()
    print("GeekLet timer status: "..(GeekTimer:running() and "running" or "stopped"))
    print(string.format("%-20s %-8s %1s %1s %s","Name", "Period", "E", "V", "Last Run"))
    print(string.rep("-",60))
    for i,v in fnutils.sortByKeys(registeredGeeklets) do
        print(string.format("%-20s %6d   %1s %1s %s",
            i,
            v.period,
            (v.enabled and "T" or "F"),
            (v.isVisible and "T" or "F"),
            ((v.lastRun == -1) and "not yet" or os.date("%c", v.lastRun))
        ))
    end
end

module.stopUpdates = function()
    return GeekTimer:stop()
end

module.startUpdates = function()
    return GeekTimer:start()
end

module.hideAll = function()
    for i,v in pairs(registeredGeeklets) do
        if v.visible then
--             for j, k in ipairs(v.drawings) do k:hide() end
            for k = #v.drawings, 1, -1 do
                v.drawings[k]:hide()
            end
        end
    end
end

module.showAll = function()
    for i,v in pairs(registeredGeeklets) do
        if v.visible then
--             for j, k in ipairs(v.drawings) do k:show() end
            for k = #v.drawings, 1, -1 do
                v.drawings[k]:show()
            end
        end
    end
end

module.timer = GeekTimer
module.sleepWatcher = geekletSleepWatcher

module.geeklets = registeredGeeklets

-- Return Module Object --------------------------------------------------

-- return setmetatable(module, {
--     __gc = function(obj)
--         if GeekTimer:running() then GeekTimer:stop() end
--     end
-- })

return module
