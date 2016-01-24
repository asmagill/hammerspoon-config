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
}

local nc = require("hs._asm.notificationcenter")
module.workspaceObserver = nc.workspaceObserver(function(n,o,i)
    if not ignoreInWorkspaceObserver[n] then
        local f = io.open("__workspaceobserver.txt","a") ;
        f:write(os.date().."\t".."name:"..n.."\tobj:"..inspect(o):gsub("%s+"," ").."\tinfo:"..inspect(i):gsub("%s+"," ").."\n")
        f:close()
    end
end):start()

module.distributedObserver = nc.distributedObserver(function(n,o,i)
    local f = io.open("__distributedobserver.txt","a") ;
    f:write(os.date().."\t".."name:"..n.."\tobj:"..inspect(o):gsub("%s+"," ").."\tinfo:"..inspect(i):gsub("%s+"," ").."\n")
    f:close()
end):start()

return module