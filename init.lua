local minimal = false
local oldPrint = print
print = function(...)
    oldPrint(os.date("%H:%M:%S: "), ...)
end

-- I do too much with developmental versions of HS -- I don't need
-- extraneous info in the Console application for every require; very
-- few of my crashes  make it into Crashlytics anyways...
--
-- I don't recommend this unless you like doing your own troubleshooting
-- since it defeats some of the data captured for crash reports.
--

hs.require = require
require = rawrequire
require("hs.crash").crashLogToNSLog = true
require("hs.crash").crashLog("Disabled require logging to make log file sane")

-- turn off hotkey logging... it's too damn much.
require("hs.hotkey").setLogLevel("nothing")

-- -- Testing eventtap replacement for hotkey
--
--local R, M = pcall(require,"hs._asm.hotkey")
--if R then
--    print()
--    print("**** Replacing internal hs.hotkey with experimental module.")
--    print()
--    hs.hotkey = M
--    package.loaded["hs.hotkey"] = M   -- make sure require("hs.hotkey") returns us
--    package.loaded["hs/hotkey"] = M   -- make sure require("hs/hotkey") returns us
--else
--    print()
--    print("**** Error with experimental hs.hotkey: "..tostring(M))
--    print()
--end

local requirePlus = require("utils.require")
local settings    = require("hs.settings")
local ipc         = require("hs.ipc")
local hints       = require("hs.hints")
local utf8        = require("hs.utf8")
local image       = require("hs.image")
local window      = require("hs.window")
local timer       = require("hs.timer")

-- Set to True or False indicating if you want a crash report when lua is invoked on  threads other than main (0) -- this should not happen, as lua is only supposed to execute in the main thread (unsupported and scary things can happen otherwise).  There is a performance hit, though, since the debug hook will be invoked for every call to a lua function, so usually this should be enabled only when testing in-development modules.

settings.set("_asm.crashIfNotMain", false)

requirePlus.updatePaths("In Home", {
    os.getenv("HOME").."/.hammerspoon/?.lua;"..
    os.getenv("HOME").."/.hammerspoon/?/init.lua",
    os.getenv("HOME").."/.hammerspoon/?.so"}, false)
requirePlus.updatePaths("Luarocks", "luarocks-5.3 path", true)

inspect = require("hs.inspect")
inspect1 = function(what) return inspect(what, {depth=1}) end
inspect2 = function(what) return inspect(what, {depth=2}) end
inspectnm = function(what) return inspect(what ,{process=function(item,path) if path[#path] == inspect.METATABLE then return nil else return item end end}) end
inspectnm1 = function(what) return inspect(what ,{process=function(item,path) if path[#path] == inspect.METATABLE then return nil else return item end end, depth=1}) end

-- may include locally added json files in docs versus built in help
doc = require("utils.docs")

tobits = function(num, bits)
    bits = bits or (math.floor(math.log(num,2) / 8) + 1) * 8
    if bits == -(1/0) then bits = 8 end
    local value = ""
    for i = (bits - 1), 0, -1 do
        value = value..tostring((num >> i) & 0x1)
    end
    return value
end

if not minimal then -- normal init continues...

-- For my convenience while testing and screwing around...
-- If something grows into usefulness, I'll modularize it.
_xtras = require("hs._asm.extras")
_xtras.console = require("hs._asm.console")

_asm = {
    _keys       = requirePlus.requirePath("utils._keys", true),
    _actions    = requirePlus.requirePath("utils._actions", true),
    _menus      = requirePlus.requirePath("utils._menus", true),
    _CMI        = require("utils.consolidateMenus"),
    relaunch    = function()
        os.execute([[ (while ps -p ]]..hs.processInfo.processID..[[ > /dev/null ; do sleep 1 ; done ; open -a "]]..hs.processInfo.bundlePath..[[" ) & ]])
        hs._exit(true, true)
    end,
}

table.insert(_asm._actions.closeWhenLoseFocus.closeList, "nvALT")

_asm._CMI.addMenu(_asm._menus.applicationMenu.menuUserdata, "icon",      true)
_asm._CMI.addMenu(_asm._menus.developerMenu.menuUserdata,   "icon",  -1, true)
_asm._CMI.addMenu(_asm._menus.clipboard,                    "title", -1, true)
_asm._CMI.addMenu(_asm._menus.battery.menuUserdata,         "title", -1, true)
_asm._CMI.addMenu(_asm._menus.autoCloseHS.menuUserdata,     "icon" , -1, true)
_asm._CMI.addMenu(_asm._menus.dateMenu.menuUserdata,        "title", -2, true)
_asm._CMI.panelShow()

hints.style = "vimperator"
window.animationDuration = 0 -- I'm a philistine, sue me
ipc.cliInstall("/opt/amagill")

-- terminal shell equivalencies...
edit = function(where)
    where = where or "."
    os.execute("/usr/local/bin/edit "..where)
end
m = function(which)
    os.execute("open x-man-page://"..tostring(which))
end

-- _asm._actions.timestamp.status()

timer.waitUntil(
    load([[ return require("hs.window").get("Hammerspoon Console") ]]),
    function(timerObject)
        local win = window.get("Hammerspoon Console")
        local screen = win:screen()
        win:setTopLeft({
            x = screen:frame().x + screen:frame().w - win:size().w,
            y = screen:frame().y + screen:frame().h - win:size().h
        })
    end
)

-- hs.drawing.windowBehaviors.moveToActiveSpace
_xtras.console.asHSDrawing():setBehavior(2)
_xtras.console.smartInsertDeleteEnabled(false)
_xtras.console.windowBackgroundColor({red=.6,blue=.7,green=.7})
_xtras.console.outputBackgroundColor({red=.8,blue=.8,green=.8})
_xtras.console.asHSDrawing():setAlpha(.9)

-- testing for side effects
--
-- -- this is the 2nd side effect noticed
-- -- not as bad as I once thought... properly take into consideration the menubar (or its absence in
-- -- 10.11) seems to have mitigated it pretty well.
-- local _fullUndoer = setmetatable({"This is in place to undo a full screen console during a reload, as it throws off some drawing elements otherwise"},{
--     __gc = function(_)
--         local win = window.get("Hammerspoon Console")
--         if win:isFullScreen() then win:toggleFullScreen() end
--     end,
--     __call = function(_, ...) print(_[1]) end,
--     __tostring = function(_) return(_[1]) end,
-- })

full = function(yesnomaybeso)
-- --     touch _fullUndoer to keep it from garbage collection...
--     _fullUndoer[1] = _fullUndoer[1]
    local win = window.get("Hammerspoon Console")
    if type(yesnomaybeso) == "nil" then yesnomaybeso = not win:isFullScreen() end

    if yesnomaybeso then
        _xtras.console.asHSDrawing():setBehavior(_xtras.console.asHSDrawing():behavior() | 128)
        if not win:isFullScreen() then win:toggleFullScreen() end
-- 1st side effect noticed
        if not hs.dockIcon() then
            print("You will have to reuse this function or quit Hammerspoon to leave full screen mode -- there is no window decoration at the top.")
        end
    else
        if win:isFullScreen() then win:toggleFullScreen() end
    end
end

else
    print("++ Running minimal configuration")
end

print("++ Running: "..hs.processInfo.bundlePath)
print("++ Accessibility: "..tostring(hs.accessibilityState()))


