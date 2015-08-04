local module = {}

-- time stamp information to test some of my modules in active use... and cause I'm
-- funny that way.

local settings  = require("hs.settings")
local timer     = require("hs.timer")
local appFinder = require("hs.appFinder")
local inspect   = require("hs.inspect")
local appfinder = require("hs.appFinder")

settings.setDate("_asm.last_loaded",os.time())

setmetatable(module,
    {__gc = function(obj)
            settings.setDate("_asm.last_clean_shutdown",os.time())
        end
    }
)

module.heartbeat = timer.new(timer.minutes(1), function()
        settings.setDate("_asm.last_heartbeat",os.time())
        if appfinder.windowFromWindowTitle("Hammerspoon Console") then
            settings.set("_asm.open_console_at_start", true)
        else
            settings.set("_asm.open_console_at_start", false)
        end
    end
) -- :start()

module.status = function()
    print("-------------------------------------------------")
    print("      Last Heartbeat:", os.date("%c", settings.get("_asm.last_heartbeat") or 0))
    print(" Last Clean Shutdown:", os.date("%c", settings.get("_asm.last_clean_shutdown") or 0))
    print("Configuration loaded:", os.date("%c", settings.get("_asm.last_loaded") or 0))
    print("-------------------------------------------------")
end

return module
