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
local image     = require("hs.image")
local settings  = require("hs.settings")
local window    = require("hs.window")
local watchable = require"hs.watchable"

local listener  = require("utils.speech")

-- private variables and methods -----------------------------------------

module.watchables = watchable.new("hammerspoonMenu", true)
module.watchables.status = true

-- module.status = true
if settings.getKeys()["_asm.autohide.console"] ~= nil then
    module.watchables.status = settings.get("_asm.autohide.console")
end

local hsConsoleWatcherFN = function(name,event,hsapp)
    if name then
        if name == "Hammerspoon" and event == appwatch.deactivated then
            local test = window.get("Hammerspoon Console")
            if test then
--                 print("~~ auto-closing Hammerspoon console")
                test:close()
            end
        end
    end
end

local hsConsoleWatcher = appwatch.new(hsConsoleWatcherFN)

local toggleWatcher = function(setItTo)
    -- take advantage of local watcher defined below
    if type(setItTo) == "boolean" then
        module.watchables.status = setItTo
    else
        module.watchables.status = not module.watchables.status
    end
    return module.watchables.status
end


local watcherMenu = menubar.newWithPriority and menubar.newWithPriority(menubar.priorities.notificationCenter - 1) or menubar.new()

watcherMenu:setIcon(image.imageFromName("statusicon"))

-- hs.image.imageFromAppBundle("org.hammerspoon.Hammerspoon"))  -- not pretty as a "template" icon
-- image.imageFromName(image.systemImageNames.ApplicationIcon)) -- the same...
      :setMenu(function(_) return
          {
              { title = "Reload Config", fn = hs.reload },
              { title = "Open Config", fn = function() os.execute("open ~/.hammerspoon/init.lua") end },
              { title = "-" },
              { title = "Console...", fn = hs.openConsole, menu = {
                      { title = "Open", fn = hs.openConsole },
                      { title = "-" },
                      { title = "Reveal", fn = function() hs.openConsole(false) end },
                      { title = "Close", fn = function()
                              window.get("Hammerspoon Console"):close()
                          end,
                          disabled = not (
                              window.get("Hammerspoon Console") and
                              window.get("Hammerspoon Console"):isVisible()
                          )
                      },
                      { title = "-" },
                      { title = "Auto-Close Console", fn = toggleWatcher,
                          checked = module.watchables.status
                      },
                  },
              },
              { title = "Preferences...", fn = hs.openPreferences, menu = {
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
                      { title = "-" },
                      { title = "Hammerspoon Listener",
                          checked = listener.recognizer and listener:isListening(),
                          fn = function()
                              if listener.recognizer then
                                  if listener:isListening() then
                                      listener:stop()
                                  else
                                      listener:start()
                                  end
                              else
                                  listener.init():start()
                              end
                          end
                      },
                  },
              },
              { title = "-" },
              { title = "About Hammerspoon", fn = hs.openAbout },
              { title = "Check For Updates",
                  disabled = not hs.canCheckForUpdates(),
                  fn = hs.checkForUpdates,
              },
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

module.watcher = hsConsoleWatcher
module.menuUserdata = watcherMenu
module.toggleWatcher = toggleWatcher
if not hs.autoCloseConsole then hs.autoCloseConsole = toggleWatcher end

module.toggleForWatchablesEnabled = watchable.watch("hammerspoonMenu.status", function(w, p, i, oldValue, value)
    if value then
        hsConsoleWatcher:start()
    else
        hsConsoleWatcher:stop()
    end
    settings.set("_asm.autohide.console", value)
end)

if module.watchables.status then
    hsConsoleWatcher:start()
else
    hsConsoleWatcher:stop()
end

-- Return Module Object --------------------------------------------------

return module
