local toolbar     = require"hs._asm.toolbar"
local console     = require"hs.console"
local image       = require"hs.image"
local fnutils     = require"hs.fnutils"
local listener    = require"utils.speech"
local watchable   = require"hs._asm.watchable"
local application = require"hs.application"

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
    module.toolbar:modifyItem{ id = "internet", image = image.imageFromName(image.systemImageNames[value and "StatusAvailable" or "StatusUnavailable"]) }
end)

local consoleToolbar = {
    {
        id = "autoHide",
        label = "Auto Hide Console",
        image = image.imageFromPath(autoHideImage()),
        tooltip = "Hide the Hammerspoon Console when focus changes?",
        fn = function(bar, attachedTo, item)
            _asm._menus.hammerspoonMenu.toggleWatcher()
--                 module.toolbar:modifyItem{ id = item, image = image.imageFromPath(autoHideImage()) }
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
--                 module.toolbar:modifyItem{ id = item, image = image.imageFromPath(listenerImage()) }
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
        image = hs.image.imageFromName("NSAdvanced")
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
}, function(entry)
    local app, bundleID = table.unpack(entry)
    table.insert(consoleToolbar, {
        id = bundleID,
        label = app,
        tooltip = app,
        image = image.imageFromAppBundle(bundleID),
        fn = function(bar, attachedTo, item)
            application.launchOrFocus(app)
        end,
        default = false,
    })
end)

table.insert(consoleToolbar, {
    id = "internet",
    label = "Internet",
    tooltip = "Internet Status",
    image = image.imageFromName(image.systemImageNames[module.watchInternetStatus:value() and "StatusAvailable" or "StatusUnavailable"]),
    fn = function(bar, attachedTo, item)
    end,
    default = false,
})

module.toolbar = toolbar.new("_asmConsole_001", consoleToolbar)
      :canCustomize(true)
      :autosaves(true)
      :setCallback(function(...)
                        print("+++ Oops! You better assign me something to do!")
                   end)

toolbar.attachToolbar(module.toolbar)

-- -- really need a way to register/un-register for watching a variable in another module...
-- -- like Objective-C's KVO, but maybe a little easier to understand...
-- -- Must ponder...  worth resurrecting inter-application listener/poster?
-- timer.doEvery(1, function()
--     if module.toolbar then
--         module.toolbar:modifyItem{ id = "autoHide", image = image.imageFromPath(autoHideImage()) }
--         module.toolbar:modifyItem{ id = "listener", image = image.imageFromPath(listenerImage()) }
--     end
-- end)

return module
