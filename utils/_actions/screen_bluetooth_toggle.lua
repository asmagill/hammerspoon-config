-- For my setup, when the number of monitors == 1, it's likely that I'm either
-- using the battery and not my external mouse, or that I'm using the computer
-- just far enough from my desk (watching TV, most likely) that the mouse is
-- barely in range and drains it's battery trying to stay connected... so...
-- we turn it off when I drop to one monitor.  I can always toggle it back (see
-- _keys).

return hs.screen.watcher.new(function()
    local btooth = require("hs.undocumented.bluetooth")
    if #hs.screen.allscreens() == 1 then
        if btooth.available() and btooth.power() then
            hs.alert.show("Turning bluetooth off to conserve mouse battery.",5)
            btooth.power(false)
        end
    else
        if btooth.available() and not btooth.power() then
            hs.alert.show("Turning bluetooth on.",5)
            btooth.power(true)
        end
    end
end):start()
