local module = {}
local caffeinate = require("hs.caffeinate") -- still needed for lookups
local settings   = require("hs.settings")
local crash      = require("hs.crash")
local fnutils    = require("hs.fnutils")

local logFile = "__sleepState.log"

local f, err = io.open(logFile, "r")
if f then
    local logData = f:read("a")
    f:close()
    local asArray = fnutils.split(logData, "[\r\n]")
    if #asArray > 1000 then
        local newArray = {}
        table.move(asArray, #asArray - 1000, #asArray, 1, newArray)
        f, err = io.open(logFile, "w")
        if f then
            f:write(table.concat(newArray, "\n"))
            f:close()
        else
            crash.crashLog("unable to create truncated " .. logFile .. " (" .. err ..")")
        end
    end
else
    crash.crashLog("unable to read " .. logFile .. " to check length (" .. err ..")")
end

local watchable = require("hs._asm.watchable")
module.watchCaffeinatedState = watchable.watch("generalStatus.caffeinatedState", function(w, p, i, old, state)
    local stateLabel = timestamp() .. " : Power State Change: " .. (caffeinate.watcher[state] or ("unknown state " .. tostring(state)))
    local f, err = io.open(logFile, "a")
    if f then
        f:write(stateLabel .. "\n") ;
        f:close()
    else
        crash.crashLog("unable to append '" .. stateLabel .. "' to " .. logFile .. " (" .. err ..")")
    end
end)

return module
