nc = require("hs._asm.notificationcenter")

output = function(name, obj, info)
    print("name:"..name.."\n obj:"..inspect(obj):gsub("%s+"," ").."\ninfo:"..inspect(info):gsub("%s+"," "))
end

appActivateWatcher = nc.workspaceObserver(output,
                     nc.notificationNames.NSWorkspaceDidActivateApplication):start()

-- returns nil for info
spacesWatcher = nc.workspaceObserver(output,
                nc.notificationNames.NSWorkspaceActiveSpaceDidChange):start()

-- returns NSRunningApplication in info dict
appActivateWatcher = nc.workspaceObserver(output,
                nc.notificationNames.NSWorkspaceDidActivateApplication):start()

-- returns nil for info
screenWatcher = nc.internalObserver(output,
                nc.notificationNames.NSApplicationDidChangeScreenParameters):start()

-- returns nil for info
keyboardWatcher = nc.internalObserver(output,
                  nc.notificationNames.NSTextInputContextKeyboardSelectionDidChange):start()

-- requires a retained reference to the Wifi Interface to work... can't do this yet.
-- wifiWatcher = nc.internalObserver(output,
--               nc.deprecatedNotificationNames.CWSSIDDidChange):start()

dwn  = nc.workspaceObserver(output,
       nc.notificationNames.NSWorkspaceDidWake):start()
wsn  = nc.workspaceObserver(output,
       nc.notificationNames.NSWorkspaceWillSleep):start()
wpon = nc.workspaceObserver(output,
       nc.notificationNames.NSWorkspaceWillPowerOff):start()
sdsn = nc.workspaceObserver(output,
       nc.notificationNames.NSWorkspaceScreensDidSleep):start()
sdwn = nc.workspaceObserver(output,
       nc.notificationNames.NSWorkspaceScreensDidWake):start()


-- Need parser for:
--    ? NSWorkspace as obj
--      NSRunningApplication as info  --> hs.application?
--

--
-- w = wrong notification type
-- - = requires retention of object we can't support yet
--
-- * application/watcher.m
-- * screen/watcher.m
-- - wifi/watcher.m
-- w battery/watcher.m
-- * spaces/watcher.m
-- * caffeinate/watcher.m
-- w usb/watcher.m
--   uielement.m