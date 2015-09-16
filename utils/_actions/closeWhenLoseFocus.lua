local module = {}

local timer       = require("hs.timer")
local application = require("hs.application")
local appwatcher  = application.watcher
local window      = require("hs.window")
local fnutils     = require("hs.fnutils")

local __tostring_for_tables = function(self)
    local result = ""
    local width = 0
    for i,v in fnutils.sortByKeys(self) do
        if type(i) == "string" and width < i:len() then width = i:len() end
    end
    for i,v in fnutils.sortByKeys(self) do
        if type(i) == "string" then
            result = result..string.format("%-"..tostring(width).."s %s\n", i, tostring(v))
        end
    end
    return result
end

local __tostring_for_arrays = function(self)
    local result = ""
    local width = 0
    for i,v in fnutils.sortByKeyValues(self) do result = result..tostring(v).."\n" end
    return result
end

-- private variables and methods -----------------------------------------

-- Applications for which one window and no longer activated means - close window
local closeList   = setmetatable({}, { __tostring = __tostring_for_arrays })

-- Applications for which one window and no longer activated means - quit application
local quitList   = setmetatable({}, { __tostring = __tostring_for_arrays })

local closeQuitWatcher = appwatcher.new(function(name, event, hsapp)
    if event == appwatcher.deactivated then
        for i,v in ipairs(closeList) do
            if name and v == name then
                if #hsapp:allWindows() == 1 then hsapp:allWindows()[1]:close() end
                break
            end
        end
        for i,v in ipairs(quitList) do
            if name and v == name then
                hsapp:kill()
                break
            end
        end
    end
end)

-- Public interface ------------------------------------------------------

module.closeList = closeList
module.quitList  = quitList
module.watcher   = closeQuitWatcher

module.enable = function()
    return closeQuitWatcher:start()
end

module.disable = function()
    return closeQuitWatcher:stop()
end

-- Return Module Object --------------------------------------------------

module.enable()

return module
