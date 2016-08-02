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

local nc                       = require("hs._asm.notificationcenter")
local distributednotifications = require"hs.distributednotifications"

module.workspaceObserver = nc.workspaceObserver(function(n,o,i)
    if not ignoreInWorkspaceObserver[n] then
        local f = io.open("__workspaceobserver.txt","a") ;
        f:write(os.date().."\t".."name:"..inspect(n).."\tobj:"..inspect(o):gsub("%s+"," ").."\tinfo:"..inspect(i):gsub("%s+"," ").."\n")
        f:close()
    end
end):start()

-- module.distributedObserver = nc.distributedObserver(function(n,o,i)
--     local f = io.open("__distributedobserver.txt","a") ;
--     f:write(os.date().."\t".."name:"..n.."\tobj:"..inspect(o):gsub("%s+"," ").."\tinfo:"..inspect(i):gsub("%s+"," ").."\n")
--     f:close()
-- end):start()

module.distributedObserver_core = distributednotifications.new(function(n,o,i)
    local f = io.open("__distributedobserver_core.txt","a") ;
    f:write(os.date().."\t".."name:"..inspect(n).."\tobj:"..inspect(o):gsub("%s+"," ").."\tinfo:"..inspect(i):gsub("%s+"," ").."\n")
    f:close()
end):start()

return module