local noises      = require("hs.noises")
local watchable   = require("hs._asm.watchable")
local window      = require("hs.window")
local application = require("hs.application")

local module = {}
module.watchables = watchable.new("popConsole", true)
module.watchables.enabled = true
local prevValue = true

local prevWindowHolder
module.callback = function(w)
    if w == 1 then     -- start "sssss" sound
    elseif w == 2 then -- end "sssss" sound
    elseif w == 3 then -- mouth popping sound
--         hs.toggleConsole()
-- this attempts to keep track of the previously focused window and return us to it
      local conswin = window.get("Hammerspoon Console")
      if conswin and application.get("Hammerspoon"):isFrontmost() then
          conswin:close()
          if prevWindowHolder and #prevWindowHolder:role() ~= 0 then
              prevWindowHolder:becomeMain():focus()
              prevWindowHolder = nil
          end
      else
          prevWindowHolder = window.frontmostWindow()
          hs.openConsole()
      end
    end
end

module._noiseWatcher = noises.new(module.callback):start()

module.toggleForWatchablesEnabled = watchable.watch("popConsole.enabled", function(w, p, i, oldValue, value)
    if value then
        module._noiseWatcher:start()
    else
        module._noiseWatcher:stop()
    end
end)

-- the listener can prevent or delay system sleep, so disable as appropriate
module.watchCaffeinatedState = watchable.watch("generalStatus.caffeinatedState", function(w, p, i, old, new)
    if new == 1 or new == 7 then -- systemWillSleep or screensaverDidStart
        prevValue = module.watchables.enabled
        module.watchables.enabled = false
    elseif new == 0 or new == 9 then -- systemDidWake or screensaverDidStop
        module.watchables.enabled = prevValue
    end
end)

return setmetatable(module, { __tostring = function(self)
    return "Adjust with `self`.watchables.enabled or using hs._asm.watchables with path 'popConsole.enabled'"
end })
