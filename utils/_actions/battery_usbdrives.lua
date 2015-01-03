-- Try to unmount USB drives if we switch to battery, cause we're probably
-- yanking the USB cable next...

local PreviousPowerSource = hs.battery.powerSource()
local extras = require("hs._asm.extras")

return hs.battery.watcher.new(function()
    local total, count = 0, 0
    local CurrentPowerSource  = hs.battery.powerSource()
    if CurrentPowerSource ~= PreviousPowerSource then
        if CurrentPowerSource ~= "AC Power" then
            for volume in string.gmatch(extras.exec("system_profiler SPUSBDataType | grep Mount\\ Point | sed 's/Mount Point: //'"),"%s+(/Volumes/[^\n\r]+)") do
                local _,_,_,rc = extras.exec("diskutil umount '"..volume.."'")
                total = total + 1
                if tonumber(rc) == 0 then count = count + 1 end
            end
            if total > 0 then
                hs.alert.show("Auto dismount: "..tostring(count).." of "..tostring(total).." dismounted.")
            end
        end
        PreviousPowerSource = CurrentPowerSource
    end
end):start()
