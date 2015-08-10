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
local settings  = require("hs.settings")

-- private variables and methods -----------------------------------------

local hsWatcherIsOn = true
if settings.getKeys()["_asm.autohide.console"] ~= nil then
    hsWatcherIsOn = settings.get("_asm.autohide.console")
end

local hsConsoleWatcherFN = function(name,event,hsapp)
    if name then
        if name:match("Hammerspoon") and event == appwatch.deactivated then
            local test = appfinder.windowFromWindowTitle("Hammerspoon Console")
            if test then test:close() end
        end
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
              { title = "Reload Config", fn = hs.reload },
              { title = "Open Config", fn = function() os.execute("open ~/.hammerspoon/init.lua") end },
              { title = "-" },
              { title = "Console...", menu = {
                      { title = "Open", fn = function() hs.openConsole() end },
                      { title = "-" },
                      { title = "Reveal", fn = function() hs.openConsole(false) end },
                      { title = "Close", fn = function()
                              appfinder.windowFromWindowTitle("Hammerspoon Console"):close()
                          end,
                          disabled = not (
                              appfinder.windowFromWindowTitle("Hammerspoon Console") and
                              appfinder.windowFromWindowTitle("Hammerspoon Console"):isVisible()
                          )
                      },
                      { title = "-" },
                      { title = "Auto-Close Console", fn = toggleWatcher,
                          checked = hsWatcherIsOn
                      },
                  },
              },
              { title = "Preferences...", menu = {
                      { title = "Open", fn = hs.openPreferences },
                      { title = "-" },
                      { title = "Dock Icon", checked = hs.dockIcon(), fn = function()
                              hs.dockIcon(not hs.dockIcon())
                          end
                      },
                      { title = "Menu Icon", checked = hs.menuIcon(), fn = function()
                              hs.menuIcon(not hs.menuIcon())
                          end
                      },
                  },
              },
              { title = "-" },
              { title = "About Hammerspoon", fn = hs.openAbout },
              { title = "Check For Updates", disabled = true },
              { title = "-" },
              { title = "Relaunch Hammerspoon", fn = function()
                      os.execute([[ (while ps -p ]]..hs.processInfo.processID..[[ > /dev/null ; do sleep 1 ; done ; open -a "]]..hs.processInfo.bundlePath..[[" ) & ]])
                      hs._exit(true, true)
                  end,
              },
              { title = "Quit Hammerspoon", fn = function() hs._exit(true, true) end },
          }
      end
)

-- Public interface ------------------------------------------------------

toggleWatcher(hsWatcherIsOn)

module.watcher = hsConsoleWatcher
module.menuUserdata = watcherMenu
module.toggleWatcher = toggleWatcher
module.staus = hsWatcherIsOn

-- Return Module Object --------------------------------------------------

return setmetatable(module, {
    __gc = function(_)
        settings.set("_asm.autohide.console", hsWatcherIsOn)
    end,
})