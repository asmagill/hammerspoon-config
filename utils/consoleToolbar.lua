local toolbar     = require"hs.webview.toolbar"
local console     = require"hs.console"
local image       = require"hs.image"
local fnutils     = require"hs.fnutils"
local listener    = require"utils.speech"
local application = require"hs.application"
local styledtext  = require"hs.styledtext"
local doc         = require"hs.doc"
local watchable   = require"hs.watchable"
local canvas      = require"hs.canvas"

local module = {}

local imageBasePath = hs.configdir .. "/_localAssets/images/"

local autoHideImage = function()
    return imageBasePath .. (module.watchConsoleAutoClose:value() and "unpinned.png" or "pinned.png")
end

local listenerImage = function()
    return imageBasePath .. (module.watchListenerStatus:value() and "microphone_on.png" or "microphone_off.png")
end

module.watchConsoleAutoClose = watchable.watch("hammerspoonMenu.status", function(...)
    module.toolbar:modifyItem{ id = "autoHide", image = image.imageFromPath(autoHideImage()) }
end)

module.watchListenerStatus = watchable.watch("utils.speech.isListening", function(...)
    module.toolbar:modifyItem{ id = "listener", image = image.imageFromPath(listenerImage()) }
end)

module.watchInternetStatus = watchable.watch("generalStatus.internet", function(w, p, i, oldValue, value)
    module.toolbar:modifyItem{ id = "internet", image = image.imageFromName(value and "NSToolbarBookmarks" or "NSStopProgressFreestandingTemplate") }
end)

module.watchVPNStatus = watchable.watch("generalStatus.privateVPN", function(w, p, i, oldValue, value)
    module.toolbar:modifyItem{ id = "privateVPN", image = image.imageFromName(value and "NSLockLockedTemplate" or "NSLockUnlockedTemplate") }
end)

local imageHolder = canvas.new{x = 10, y = 10, h = 50, w = 50}
imageHolder[1] = {
    frame = { h = 50, w = 50, x = 0, y = -6 },
    text = styledtext.new("⌘", {
        font = { name = ".AppleSystemUIFont", size = 50 },
        paragraphStyle = { alignment = "center" }
    }),
    type = "text",
}
local cheatSheetOn = imageHolder:imageFromCanvas()
imageHolder[2] = {
    action = "stroke",
    closed = false,
    coordinates = { { x = 0, y = 0 }, { x = 50, y = 50 } },
    strokeColor = { red = 1.0 },
    strokeWidth = 3,
    type = "segments",
}
imageHolder[3] = {
    action = "stroke",
    closed = false,
    coordinates = { { x = 50, y = 0 }, { x = 0, y = 50 } },
    strokeColor = { red = 1.0 },
    strokeWidth = 3,
    type = "segments",
}
local cheatSheetOff = imageHolder:imageFromCanvas()
imageHolder = imageHolder:delete()

module.watchCheatSheetStatus = watchable.watch("cheatsheet.enabled", function(w, p, i, oldValue, value)
    module.toolbar:modifyItem{ id = "cheatsheet", image = value and cheatSheetOn or cheatSheetOff }
end)

imageHolder = canvas.new{x = 10, y = 10, h = 50, w = 50}
imageHolder[1] = {
    frame = { h = 50, w = 50, x = 0, y = 0 },
    text = styledtext.new("🖥", {
        font = { name = ".AppleSystemUIFont", size = 50 },
        paragraphStyle = { alignment = "center" }
    }),
    type = "text",
}
local popConsoleOn = imageHolder:imageFromCanvas()
imageHolder[2] = {
    action = "stroke",
    closed = false,
    coordinates = { { x = 0, y = 0 }, { x = 50, y = 50 } },
    strokeColor = { red = 1.0 },
    strokeWidth = 3,
    type = "segments",
}
imageHolder[3] = {
    action = "stroke",
    closed = false,
    coordinates = { { x = 50, y = 0 }, { x = 0, y = 50 } },
    strokeColor = { red = 1.0 },
    strokeWidth = 3,
    type = "segments",
}
local popConsoleOff = imageHolder:imageFromCanvas()
imageHolder = imageHolder:delete()

module.watchPopConsoleStatus = watchable.watch("popConsole.enabled", function(w, p, i, oldValue, value)
    module.toolbar:modifyItem{ id = "popConsole", image = value and popConsoleOn or popConsoleOff }
end)

imageHolder = canvas.new{x = 10, y = 10, h = 50, w = 50}
imageHolder[1] = {
    frame = { h = 50, w = 50, x = 0, y = -6 },
    text = styledtext.new("ⅵ", {
        font = { name = ".AppleSystemUIFont", size = 50 },
        paragraphStyle = { alignment = "center" }
    }),
    type = "text",
}
local viKeysOn = imageHolder:imageFromCanvas()
imageHolder[2] = {
    action = "stroke",
    closed = false,
    coordinates = { { x = 0, y = 0 }, { x = 50, y = 50 } },
    strokeColor = { red = 1.0 },
    strokeWidth = 3,
    type = "segments",
}
imageHolder[3] = {
    action = "stroke",
    closed = false,
    coordinates = { { x = 50, y = 0 }, { x = 0, y = 50 } },
    strokeColor = { red = 1.0 },
    strokeWidth = 3,
    type = "segments",
}
local viKeysOff = imageHolder:imageFromCanvas()
imageHolder = imageHolder:delete()

module.watchViKeysStatus = watchable.watch("viKeys.enabled", function(w, p, i, oldValue, value)
    module.toolbar:modifyItem{ id = "viKeys", image = value and viKeysOn or viKeysOff }
end)


local consoleToolbar = {
    {
        id = "autoHide",
        label = "Auto Hide Console",
        image = image.imageFromPath(autoHideImage()),
        tooltip = "Hide the Hammerspoon Console when focus changes?",
        fn = function(bar, attachedTo, item)
            module.watchConsoleAutoClose:change(not module.watchConsoleAutoClose:value())
        end,
    },
    {
        id = "listener",
        label = "HS Listener",
        image = image.imageFromPath(listenerImage()),
        tooltip = "Toggle the Hammerspoon Speech Recognition Listener",
        fn = function(bar, attachedTo, item)
            if listener.recognizer then
                if listener:isListening() then
                    listener:disableCompletely()
                else
                    listener:start()
                end
            else
                listener.init():start()
            end
        end,
    },
    { id = "NSToolbarFlexibleSpaceItem" },
    {
        id = "cust",
        label = "customize",
        tooltip = "Modify Toolbar",
        fn = function(t, w, i)
            t:customizePanel()
        end,
        image = image.imageFromName("NSToolbarCustomizeToolbarItemImage")
    }
}

fnutils.each({
    { "SmartGit",         "com.syntevo.smartgit", },
    { "XCode",            "com.apple.dt.Xcode" },
    { "Console",          "com.apple.Console", },
    { "Terminal",         "com.apple.Terminal" },
    { "BBEdit",           "com.barebones.bbedit" },
    { "Safari",           "com.apple.Safari" },
    { "Activity Monitor", "com.apple.ActivityMonitor"},
    { "AXUI Inspector",   "com.apple.AccessibilityInspector"},
}, function(entry)
    local app, bundleID = table.unpack(entry)
    table.insert(consoleToolbar, {
        id = bundleID,
        label = app,
        tooltip = app,
        image = image.imageFromAppBundle(bundleID),
        fn = function(bar, attachedTo, item)
            application.launchOrFocusByBundleID(bundleID)
        end,
        default = false,
    })
end)

table.insert(consoleToolbar, {
    id = "internet",
    label = "Internet",
    tooltip = "Internet Status",
    image = image.imageFromName(module.watchInternetStatus:value() and "NSToolbarBookmarks" or "NSStopProgressFreestandingTemplate"),
    fn = function(bar, attachedTo, item)
    end,
    default = false,
})

table.insert(consoleToolbar, {
    id = "privateVPN",
    label = "Private VPN",
    tooltip = "Private VPN State",
    image = image.imageFromName(module.watchVPNStatus:value() and "NSLockLockedTemplate" or "NSLockUnlockedTemplate"),
    fn = function(bar, attachedTo, item)
    end,
    default = false,
})

table.insert(consoleToolbar, {
    id = "hammerspoonDocumentation",
    label = "HS Documentation",
    tooltip = "Show HS Documentation Browser",
    image = image.imageFromName("NXHelpIndex"),
    fn = function(bar, attachedTo, item)
        local base = require"hs.doc.hsdocs"
        if not base._browser then
            base.help()
        else
            base._browser:show()
        end
    end,
    default = false,
})

table.insert(consoleToolbar, {
    id = "cheatsheet",
    label = "CheatSheet Status",
    tooltip = "Toggle CheatSheet Functionality",
    image = module.watchCheatSheetStatus:value() and cheatSheetOn or cheatSheetOff,
    fn = function(t, a, i)
        module.watchCheatSheetStatus:change(not module.watchCheatSheetStatus:value())
    end,
    default = false,
})

table.insert(consoleToolbar, {
    id = "popConsole",
    label = "popConsole Status",
    tooltip = "Toggle popConsole Functionality",
    image = module.watchPopConsoleStatus:value() and popConsoleOn or popConsoleOff,
    fn = function(t, a, i)
        module.watchPopConsoleStatus:change(not module.watchPopConsoleStatus:value())
    end,
    default = false,
})

table.insert(consoleToolbar, {
    id = "viKeys",
    label = "viKeys Status",
    tooltip = "Toggle viKeys Functionality",
    image = module.watchViKeysStatus:value() and viKeysOn or viKeysOff,
    fn = function(t, a, i)
        module.watchViKeysStatus:change(not module.watchViKeysStatus:value())
    end,
    default = false,
})

-- get list of hammerspoon modules and spoons
local list = {}
for i,v in ipairs(doc._jsonForModules) do
    table.insert(list, v.name)
end
for i,v in ipairs(doc._jsonForSpoons) do
    table.insert(list, "spoon." .. v.name)
end
table.sort(list)

table.insert(consoleToolbar, {
    id = "searchID",
    label = "HS Doc Search",
    tooltip = "Search for a HS function or method",
    fn = function(t, w, i, text)
        if text ~= "" then require"hs.doc.hsdocs".help(text) end
    end,
    default = false,

    searchfield               = true,
    searchPredefinedMenuTitle = false,
    searchPredefinedSearches  = list,
    searchWidth               = 250,
})

module.toolbar = toolbar.new("_asmConsole_001")
      :addItems(consoleToolbar)
      :canCustomize(true)
      :autosaves(true)
      :setCallback(function(...)
                        print("+++ Oops! You better assign me something to do!")
                   end)

console.toolbar(module.toolbar)
-- not in core yet
if console.titleVisibility then console.titleVisibility("hidden") end

return module
