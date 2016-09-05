local minimal = false
-- local oldPrint = print
-- print = function(...)
--     oldPrint(os.date("%H:%M:%S: "), ...)
-- end

-- I do too much with developmental versions of HS -- I don't need
-- extraneous info in the Console application for every require; very
-- few of my crashes  make it into Crashlytics anyways...
--
-- I don't recommend this unless you like doing your own troubleshooting
-- since it defeats some of the data captured for crash reports.
--

hs.require = require

-- due to the way dSYM libraries are loaded, this can only work for actual lua files, but it's still
-- better then constantly restarting Hammerspoon to clear or ignore package.path during development
weakrequire = function(what)
    local path, err = package.searchpath(what, package.path)

    if path then
        return dofile(path)
    else
        error("no module " .. what .. " found" .. err, 2)
    end
end

require = rawrequire
require("hs.crash").crashLogToNSLog = true
require("hs.crash").crashLog("Disabled require logging to make log file sane")
local logger = require("hs.logger")
logger.historySize(1000)
logger.truncateID = "head"
logger.truncateIDWithEllipsis = true

-- -- Testing lua/hs.drawing based replacement for alert

if require"hs.settings".get("_asm.test.canvas.drawing") then
    local R, M = pcall(require,"hs._asm.canvas.drawing")
    if R then
       print()
       print("**** Replacing internal hs.drawing with experimental wrapper.")
       print()
       hs.drawing = M
       package.loaded["hs.drawing"] = M   -- make sure require("hs.drawing") returns us
       package.loaded["hs/drawing"] = M   -- make sure require("hs/drawing") returns us
       debug.getregistry()["hs.drawing"] = hs.getObjectMetatable("hs._asm.canvas.drawing")
    else
       print()
       print("**** Error with experimental hs.drawing wrapper: "..tostring(M))
       print()
    end
end

-- -- copy into _coresetup/init.lua
-- local R, M = pcall(require,"hs._asm.canvas.toolbar")
-- if R then
--    print()
--    print("**** Replacing internal hs.webview.toolbar with experimental module.")
--    print()
-- --    hs.webview.toolbar = M
--    package.loaded["hs.webview.toolbar"] = M   -- make sure require("hs.webview.toolbar") returns us
--    package.loaded["hs/webview/toolbar"] = M   -- make sure require("hs/webview/toolbar") returns us
-- else
--    print()
--    print("**** Error with experimental hs.webview.toolbar: "..tostring(M))
--    print()
-- end

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


-- adjust hotkey logging... info as the default is too much.
require("hs.hotkey").setLogLevel("warning")

local requirePlus = require("utils.require")
local settings    = require("hs.settings")
local ipc         = require("hs.ipc")
local hints       = require("hs.hints")
local utf8        = require("hs.utf8")
local image       = require("hs.image")
local window      = require("hs.window")
local timer       = require("hs.timer")
local drawing     = require("hs.drawing")
local screen      = require("hs.screen")
local console     = require("hs.console")
local stext       = require("hs.styledtext")
local fnutils     = require("hs.fnutils")


-- Set to True or False indicating if you want a crash report when lua is invoked on  threads other than main (0) -- this should not happen, as lua is only supposed to execute in the main thread (unsupported and scary things can happen otherwise).  There is a performance hit, though, since the debug hook will be invoked for every call to a lua function, so usually this should be enabled only when testing in-development modules.

settings.set("_asm.crashIfNotMain", false)

requirePlus.updatePaths("In Home", {
    hs.configdir.."/?.lua;"..
    hs.configdir.."/?/init.lua",
    hs.configdir.."/?.so"}, false)
requirePlus.updatePaths("Luarocks", "luarocks-5.3 path", true)

inspect = require("hs.inspect")
inspectm = function (what, how)
    if how then return inspect(what, how) else return inspect(what, { metatables = 1 }) end
end
inspect1 = function(what) return inspect(what, {depth=1}) end
inspect2 = function(what) return inspect(what, {depth=2}) end
inspecta = function(what) return inspect(what, {
    process = function(i,p) if p[#p] ~= "n" then return i end end
}) end

-- need to make third-party docs possible; this is totally out of date
-- -- may include locally added json files in docs versus built in help
-- doc = require("utils.docs")
doc = hs.hsdocs

if not minimal then -- normal init continues...

-- For my convenience while testing and screwing around...
-- If something grows into usefulness, I'll modularize it.
_xtras = require("hs._asm.extras")
-- _xtras.docmaker = require("utils.docmaker")

-- _xtras.console = require("hs.console")

_asm = {}
_asm.gc = require("utils.gc")
_asm.gc.patch("hs.timer")
_asm.gc.patch("hs._asm.canvas")

_asm.relaunch = function()
    os.execute([[ (while ps -p ]]..hs.processInfo.processID..[[ > /dev/null ; do sleep 1 ; done ; open -a "]]..hs.processInfo.bundlePath..[[" ) & ]])
    hs._exit(true, true)
end

_asm.watchables = require("utils.watchables")

_asm._keys    = requirePlus.requirePath("utils._keys", true)
_asm._actions = requirePlus.requirePath("utils._actions", true)
_asm._menus   = requirePlus.requirePath("utils._menus", true)
-- need to rethink requirePlus so that it can handle folders with name/init.lua
_asm._menus.XProtectStatus = require"utils._menus.XprotectStatus"

_asm._CMI     = require("utils.consolidateMenus")

table.insert(_asm._actions.closeWhenLoseFocus.closeList, "nvALT")
_asm._actions.closeWhenLoseFocus.disable()

_asm._CMI.addMenu(_asm._menus.applicationMenu.menuUserdata, "icon",      true)
_asm._CMI.addMenu(_asm._menus.developerMenu.menuUserdata,   "icon",  -1, true)
_asm._CMI.addMenu(_asm._menus.newClipper.menu,              "title", -1, true)
_asm._CMI.addMenu(_asm._menus.volumes.menu,                 "icon",  -1, true)
-- _asm._CMI.addMenu(_asm._menus.battery.menuUserdata,         "title", -1, true)
-- going to have to revisit CMI... it doesn't do arbitrary sized icons well, plus I think I want a dark mode
-- time to consider image filters for hs.image?
_asm._CMI.addMenu(_asm._menus.dateMenu.menuUserdata,        "title", -1, true)
_asm._CMI.addMenu(_asm._menus.amphetamine.menu,             "icon",  -1, true)
_asm._CMI.addMenu(_asm._menus.XProtectStatus.fullMenu,      "icon",  -1, true)
_asm._CMI.panelShow()

dofile("geekery.lua")

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
console.behavior(2)
console.smartInsertDeleteEnabled(false)
console.windowBackgroundColor({red=.6,blue=.7,green=.7})
console.outputBackgroundColor({red=.8,blue=.8,green=.8})
console.alpha(.9)

_asm.consoleToolbar = require"utils.consoleToolbar"

-- override print so that it can render styled text objects directly in the console
_asm.hs_default_print = print
print = function(...)
    hs.rawprint(...)
    console.printStyledtext(...)
end

resetSpaces = function()
    local s = require("hs._asm.undocumented.spaces")
    -- bypass check for raw function access
    local si = require("hs._asm.undocumented.spaces.internal")
    for k,v in pairs(s.spacesByScreenUUID()) do
        local first = true
        for a,b in ipairs(v) do
            if first and si.spaceType(b) == s.types.user then
                si.showSpaces(b)
                si._changeToSpace(b)
                first = false
            else
                si.hideSpaces(b)
            end
            si.spaceTransform(b, nil)
        end
        si.setScreenUUIDisAnimating(k, false)
    end
    hs.execute("killall Dock")
end

mb = function(url, extras)
    local webview     = require("hs.webview")
    url = url or "https://www.google.com"

    local options = {
            developerExtrasEnabled = true,
    }
    if type(extras) == "table" then
        for k,v in pairs(extras) do options[k] = v end
    end

    if not _asm.mb then
        _asm.mblog = {}
        _asm.mb = webview.newBrowser({
            x = 100, y = 100,
            h = 500, w = 500
        }, options):closeOnEscape(true)
                   :navigationCallback(function(a, w, n, e)
                      table.insert(_asm.mblog, { os.date("%D %T"), a, n, e })
                   end)
                   :policyCallback(function(a, w, d1, d2)
                      table.insert(_asm.mblog, { os.date("%D %T"), a, d1, d2 })
                      return true
                   end)
                   :sslCallback(function(w, p)
                      table.insert(_asm.mblog, { os.date("%D %T"), "sslServerTrust", p })
                      return true
                   end)
    end
    return _asm.mb:url(url):show()
end

history = _asm._actions.consoleHistory.history
local previousParser = hs._consoleInputPreparser
hs._consoleInputPreparser = function(s)
    if previousParser then s = previousParser(s) end

    -- allow !# like bash to redo a command from the history
    local historyNumber = s:match("^!(-?%d+)$")
    if historyNumber then s = "history(" .. historyNumber .. ")" end

    -- allow `history what`
    if s:match("^history%s+[^\"]") then s = s:gsub("^history ", "history \"") .. "\"" end

    if s:match("^help") and not s:match("^help%.") then
        -- allow help(what) without quotes
        local helpParen = s:match("^help%s*%(([^\"]*)%)%s*$")
        if helpParen then
            if helpParen == "" then
                s = "help"
            else
                s = "help." .. helpParen
            end
        end

        -- allow `help what`
        if s:match("^help%s+[^\"]") then s = s:gsub("^help%s+", "help.") end
    end

    return s
end

print([[

    CLEAN UP INIT.LUA -- MOVE MINOR STUFF TO _asm.extras!!

]])

else
    print("++ Running minimal configuration")
end

print("++ Running: "..hs.processInfo.bundlePath)
print("++ Accessibility: "..tostring(hs.accessibilityState()))

