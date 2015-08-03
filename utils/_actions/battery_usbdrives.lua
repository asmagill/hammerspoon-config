-- Try to unmount USB drives if we switch to battery, cause we're probably
-- yanking the USB cable next...

local battery = require("hs.battery")
local alert   = require("hs.alert")

local PreviousPowerSource = battery.powerSource()

return battery.watcher.new(function()
    local total, count = 0, 0
    local CurrentPowerSource  = battery.powerSource()
    if CurrentPowerSource ~= PreviousPowerSource then
        if CurrentPowerSource ~= "AC Power" then
            for volume in require("hs.fs").dir("/Volumes") do
                if not volume:match("^%.") and volume ~= "Yose" and volume ~= "DeepChaos" then
                    local _,_,_,rc = hs.execute("diskutil umount '"..volume.."'")
                    total = total + 1
                    if tonumber(rc) == 0 then count = count + 1 end
                end
            end
            if total > 0 then
                alert.show("Auto dismount: "..tostring(count).." of "..tostring(total).." dismounted.")
            end
        end
        PreviousPowerSource = CurrentPowerSource
    end
end) --:start()
