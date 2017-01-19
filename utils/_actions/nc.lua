local module = {}

local ignoreInWorkspaceObserver = {
    NSWorkspaceActiveSpaceDidChangeNotification = true,
    NSWorkspaceDidActivateApplicationNotification = true,
    NSWorkspaceDidDeactivateApplicationNotification = true,
    NSWorkspaceDidHideApplicationNotification = true,
    NSWorkspaceDidLaunchApplicationNotification = true,
    NSWorkspaceDidMountNotification = true,
    NSWorkspaceDidRenameVolumeNotification = true,
    NSWorkspaceDidTerminateApplicationNotification = true,
    NSWorkspaceDidUnhideApplicationNotification = true,
    NSWorkspaceDidUnmountNotification = true,
    NSWorkspaceDidWakeNotification = true,
    NSWorkspaceScreensDidSleepNotification = true,
    NSWorkspaceScreensDidWakeNotification = true,
    NSWorkspaceSessionDidBecomeActiveNotification = true,
    NSWorkspaceSessionDidResignActiveNotification = true,
    NSWorkspaceWillLaunchApplicationNotification = true,
    NSWorkspaceWillPowerOffNotification = true,
    NSWorkspaceWillSleepNotification = true,
    NSWorkspaceWillUnmountNotification = true,
    NSWorkspaceActiveDisplayDidChangeNotification = true,
}

local nc                       = require "hs._asm.notificationcenter"
local distributednotifications = require "hs.distributednotifications"
local fnutils                  = require "hs.fnutils"

module.workspaceObserver = nc.workspaceObserver(function(n,o,i)
    if not ignoreInWorkspaceObserver[n] then
        local f = io.open("__workspaceobserver.txt","a") ;
        f:write(os.date().."\t".."name:"..inspect(n).."\tobj:"..inspect(o):gsub("%s+"," ").."\tinfo:"..inspect(i):gsub("%s+"," ").."\n")
        f:close()
    end
end):start()

local do_logFile = "__distributedobserver_core.log"

local f, err = io.open(do_logFile, "r")
if f then
    local logData = f:read("a")
    f:close()
    local asArray = fnutils.split(logData, "[\r\n]")
    if #asArray > 1000 then
        local newArray = {}
        table.move(asArray, #asArray - 1000, #asArray, 1, newArray)
        f, err = io.open(do_logFile, "w")
        if f then
            f:write(table.concat(newArray, "\n"))
            f:close()
        else
            print("unable to create truncated " .. do_logFile .. " (" .. err ..")")
        end
    end
else
    print("unable to read " .. do_logFile .. " to check length (" .. err ..")")
end

module.distributedObserver_core = distributednotifications.new(function(n,o,i)
    local f = io.open(do_logFile,"a") ;
    f:write(timestamp().."\t".."name:"..inspect(n).."\tobj:"..inspect(o):gsub("%s+"," ").."\tinfo:"..inspect(i):gsub("%s+"," ").."\n")
    f:close()
end):start() -- gets big fast, so let me turn it on when I want to explore

return module
