local module = {
--[=[
    _NAME        = 'consolidateMenus.lua',
    _VERSION     = 'the 1st digit of Pi/0',
    _URL         = 'https://github.com/asmagill/hammerspoon-config',
    _LICENSE     = [[ See README.md ]]
    _DESCRIPTION = [[

        Auto close Hammerspoon console and provide a menu with options
        about that...

    ]],
    _TODO        = [[

    ]]
--]=]
}

local menubar   = require("hs.menubar")
local appwatch  = require("hs.application").watcher
local appfinder = require("hs.appfinder")
local image     = require("hs.image")

-- private variables and methods -----------------------------------------

local hsWatcherIsOn   = false

local hsConsoleWatcherFN = function(name,event,hsapp)
    if name:match("Hammerspoon") and event == appwatch.deactivated then
        local test = appfinder.windowFromWindowTitle("Hammerspoon Console")
        if test then test:close() end
    end
end

local hsConsoleWatcher = appwatch.new(hsConsoleWatcherFN) -- damn lack of chaining

local toggleWatcher = function(setItTo)
    if type(setItTo) == "boolean" then hsWatcherIsOn = not setItTo end

    if hsWatcherIsOn then
        hsWatcherIsOn = false
        hsConsoleWatcher:stop()
    else
        hsWatcherIsOn = true
        hsConsoleWatcher:start()
    end
end

local watcherMenu = menubar.new():setIcon(image.imageFromName("statusicon")) -- it's in the app bundle, so we can refer to it by name
-- hs.image.imageFromAppBundle("org.hammerspoon.Hammerspoon"))  -- not pretty as a "template" icon
-- image.imageFromName(image.systemImageNames.ApplicationIcon)) -- the same...
      :setMenu(function(_) return
          {
              { title = "Open Console", fn = function() hs.openConsole() end },
              { title = "Close Console", fn = function()
                                appfinder.windowFromWindowTitle("Hammerspoon Console"):close()
                            end,
                  disabled = not appfinder.windowFromWindowTitle("Hammerspoon Console")
              },
              { title = "-" },
              { title = "Auto-Hide Console", fn = toggleWatcher, checked = hsWatcherIsOn },
          }
      end
)

-- Public interface ------------------------------------------------------

toggleWatcher(true)

module.watcher = hsConsoleWatcher
module.menuUserdata = watcherMenu
module.toggleWatcher = toggleWatcher
module.staus = hsWatcherIsOn

-- Return Module Object --------------------------------------------------

return module