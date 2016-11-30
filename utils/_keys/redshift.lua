local redshift   = require("hs.redshift")
local hotkey     = require("hs.hotkey")
local mods       = require("hs._asm.extras").mods
local alert      = require("hs.alert")
local settings   = require("hs.settings")
-- local caffeinate = require("hs.caffeinate")

local module = {
    help = "⌘-F11 and ⌘⌥-F11"
}

-- settings.clear("hs.redshift.inverted.override")
-- settings.clear("hs.redshift.disabled.override")

redshift.start(2800,'21:00','7:00','4h')

hotkey.bind(mods.Casc, "F11", function()
    alert("Toggle Invert")
    redshift.toggleInvert()
end)

hotkey.bind(mods.CAsc, "F11", function()
    alert("Toggle Redshift")
    redshift.toggle()
end)

-- module._loopSleepWatcher = caffeinate.watcher.new(function(event)
--     local cw = caffeinate.watcher
--     if ({ [cw.systemDidWake] = 1, [cw.screensaverDidStop] = 1, })[event] then
--         redshift.start(2800,'21:00','7:00','4h')
--     elseif ({ [cw.systemWillSleep] = 1, [cw.screensaverDidStart] = 1, })[event] then
--         redshift.stop()
--     end
-- end):start()

local watchable = require("hs._asm.watchable")
module.watchCaffeinatedState = watchable.watch("generalStatus.caffeinatedState", function(w, p, i, old, new)
    if new == 0 or new == 9 then -- systemDidWake or screensaverDidStop
        redshift.start(2800,'21:00','7:00','4h')
    elseif new == 1 or new == 7 then -- systemWillSleep or screensaverDidStart
        redshift.stop()
    end
end)

return module
