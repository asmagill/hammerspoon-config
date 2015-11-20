local module = {
--[=[
    _NAME        = 'GeekTool Replacement',
    _VERSION     = 'the 3rd digit of Pi/0',
    _URL         = 'https://github.com/asmagill/hammerspoon-config',
    _LICENSE     = [[ See README.md ]]
    _DESCRIPTION = [[]],
--]=]
}

local fnutils = require("hs.fnutils")
local drawing = require("hs.drawing")
local stext   = require("hs.styledtext")
local task    = require("hs.task")
local timer   = require("hs.timer")
local log     = require("hs.logger").new("objc","warning")
module.log    = log

-- private variables and methods -----------------------------------------

local registeredGeeklets = {}

local GeekTimer = timer.new(1, function()
    for i,v in pairs(registeredGeeklets) do
        if (v.lastRun + v.period) < os.time() then
            if v.enabled and v.task then -- and v.task:isRunning() then
                log.wf("%s: is still running -- either period is too short or it has hung", v.name)
            elseif v.enabled then
                v.task = task.new(v.path, function(c, o, e)
                    if c ~= 0 then
                        log.wf("%s: status: %d error:%s output:%s", v.name, c, e, o)
                    end
                    v.drawings[1]:setStyledText(stext.ansi(o, v.textStyle))
                    v.task = nil
                end)
                v.lastRun = os.time()
                v.task:start()
            end
        end
    end
end)

-- Public interface ------------------------------------------------------

-- Change the defaults in here if you don't like mine!

module.registerGeeklet = function(name, period, path, frame, textStyle, otherDrawings)
    assert(type(name)   == "string", "Argument 1, Name, must be specified as a string")
    assert(type(period) == "number", "Argument 2, Period, must be specified as a number")
    assert(type(path)   == "string", "Argument 3, Path, must be specified as a string")
    assert(type(frame)  == "table",  "Argument 4, Frame, must be specified as a table")
    local theStyle, theDrawings = textStyle, otherDrawings

    -- take advantage of the fact that textStyle is a table while otherDrawings is an array
    if type(textStyle) == "table" and #textStyle ~= 0 then
        theDrawings = textStyle
        theStyle    = {}
    end
    if not theStyle.font then theStyle.font = { name = "Menlo", size = 12 } end

    if not registeredGeeklets[name] then
        registeredGeeklets[name] = setmetatable({
                name          = name,
                period        = period,
                path          = path,
                frame         = frame,
                textStyle     = theStyle,
                isVisible     = true,
                enabled       = false,
                lastRun       = -1,
                shouldHover   = false,
                isOnAllSpaces = true,
                layer         = true,
                drawings      = theDrawings,
            }, {
            __index = {
                start       = module.start,
                stop        = module.stop,
                delete      = module.delete,
                visible     = module.visible,
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
        for j,k in ipairs(registeredGeeklets[name].drawings) do
            k:delete()
        end
        registeredGeeklets[name].drawings = nil
        registeredGeeklets[name] = nil
    end
end

module.visible = function(name, state)
    local iReturn = name
    if state == nil then return registeredGeeklets[name].isVisible end
    if type(name) == "table" then name = name.name end
    if not registeredGeeklets[name] then
        error(name.." is not registered", 2)
    else
        for j,k in ipairs(registeredGeeklets[name].drawings) do
            if state then k:show() else k:hide() end
        end
        for i = 2, #registeredGeeklets[name].drawings, 1 do
            registeredGeeklets[name].drawings[1]:orderAbove(registeredGeeklets[name].drawings[i])
        end

        registeredGeeklets[name].isVisible = state
    end
    return iReturn
end

module.hover = function(name, state)
    local iReturn = name
    if state == nil then return registeredGeeklets[name].shouldHover end
    if type(name) == "table" then name = name.name end
    if not registeredGeeklets[name] then
        error(name.." is not registered", 2)
    else
        for j,k in ipairs(registeredGeeklets[name].drawings) do
            if state then k:bringToFront() else k:sendToBack() end
        end
        registeredGeeklets[name].shouldHover = state
    end
    return iReturn
end

module.wantsLayer = function(name, state)
    local iReturn = name
    if state == nil then return registeredGeeklets[name].layer end
    if type(name) == "table" then name = name.name end
    if not registeredGeeklets[name] then
        error(name.." is not registered", 2)
    else
        registeredGeeklets[name].drawings[1]:wantsLayer(state)
        registeredGeeklets[name].layer = state
    end
    return iReturn
end

module.onAllSpaces = function(name, state)
    local iReturn = name
    if state == nil then return registeredGeeklets[name].isOnAllSpaces end
    if type(name) == "table" then name = name.name end
    if not registeredGeeklets[name] then
        error(name.." is not registered", 2)
    else
        for j,k in ipairs(registeredGeeklets[name].drawings) do
            if state then k:setBehaviorByLabels{"canJoinAllSpaces"} else k:setBehaviorByLabels{"default"} end
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
            for j, k in ipairs(v.drawings) do k:hide() end
        end
    end
end

module.showAll = function()
    for i,v in pairs(registeredGeeklets) do
        if v.visible then
            for j, k in ipairs(v.drawings) do k:show() end
        end
    end
end

module.timer = GeekTimer
module.geeklets = registeredGeeklets

-- Return Module Object --------------------------------------------------

return setmetatable(module, {
    __gc = function(obj)
        if GeekTimer:running() then GeekTimer:stop() end
    end
})
