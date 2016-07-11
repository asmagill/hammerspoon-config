local battery    = require("hs.battery")
local menu       = require("hs.menubar")
local styledtext = require("hs.styledtext")

local module = {}

local adjustTitle = function()
    if module.menu then
        local text = tostring(battery.amperage()) .. "\n"
        if battery.isCharging() then
            text = text .. tostring(battery.timeToFullCharge())
        else
            text = text .. tostring(battery.timeRemaining())
        end
        module.menu:setTitle(styledtext.new(text, {
                                                      font = {
                                                          name = "Menlo",
                                                          size = 9
                                                      },
                                                      paragraphStyle = {
                                                          alignment = "center",
                                                      },
                                                  }))
    else
        if module.watcher then
            module.watcher:stop()
            module.watcher = nil
        end
    end
end

module.menu = menu.newWithPriority(999)
module.watcher = battery.watcher.new(adjustTitle):start()
adjustTitle()
return module
