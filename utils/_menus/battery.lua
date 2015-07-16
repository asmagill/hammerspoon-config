local module = {
--[=[
    _NAME        = 'battery',
    _VERSION     = '',
    _URL         = 'https://github.com/asmagill/hammerspoon_config',
    _DESCRIPTION = [[

          Battery Status

          I already had a plan in mind, but the visual design is influenced by code found at
          http://applehelpwriter.com/2014/08/25/applescript-make-your-own-battery-health-meter/
    ]],
    _TODO        = [[

          Possible additions -- issue warning for low battery?  System already does this, so...
                                change menu title to icon with color change for battery state?

    ]],
    _LICENSE     = [[ See README.md ]]
--]=]
}

local menubar = require("hs.menubar")
local utf8    = require("hs.utf8")
local battery = require("hs.battery")
local fnutils = require("hs.fnutils")

local onAC      = utf8.codepointToUTF8(0x1F50C) -- plug
local onBattery = utf8.codepointToUTF8(0x1F50B) -- battery

local menuUserData = nil
local currentPowerSource = ""

local powerSourceChangeFN = function()
    local newPowerSource = battery.powerSource()

    if currentPowerSource ~= newPowerSource then
        currentPowerSource = newPowerSource
        if menuUserData then
            if currentPowerSource == "AC Power" then
                menuUserData:setTitle(onAC)
            else
                menuUserData:setTitle(onBattery)
            end
        end
    end
end

local powerWatcher = battery.watcher.new(powerSourceChangeFN)

local displayBatteryData = function(modifier)
    local menuTable = {}

    local pwrIcon = (battery.powerSource() == "AC Power") and onAC or onBattery
--    table.insert(menuTable, { title = pwrIcon.."  "..battery.powerSource() })
--
--    table.insert(menuTable, {
--        title = utf8.codepointToUTF8(0x1F6A6).."  "..(
    table.insert(menuTable, { title = pwrIcon.."  "..(
            (battery.isCharged()  and "Fully Charged") or
            (battery.isCharging() and (battery.isFinishingCharge() and "Finishing Charge" or "Charging")) or
            "On Battery"
        )
    })

    table.insert(menuTable, { title = "-" })

    table.insert(menuTable, {
        title = utf8.codepointToUTF8(0x26A1).."  Current Charge: "..
            string.format("%.2f%%", battery.percentage())
    })

    local timeTitle, timeValue = utf8.codepointToUTF8(0x1F552).."  ", nil
    if battery.powerSource() == "AC Power" then
        timeTitle = timeTitle.."Time to Full: "
        timeValue = battery.timeToFullCharge()
    else
        timeTitle = timeTitle.."Time Remaining: "
        timeValue = battery.timeRemaining()
    end

    table.insert(menuTable, { title = timeTitle..
        ((timeValue < 0) and "...calculating..." or
        string.format("%2d:%02d", math.floor(timeValue/60), timeValue%60))
    })

    table.insert(menuTable, {
        title = utf8.codepointToUTF8(0x1F340).."  Battery Health: "..
            string.format("%.2f%%", 100 * battery.maxCapacity()/battery.designCapacity())
    })

    table.insert(menuTable, {
        title = utf8.codepointToUTF8(0x1F300).."  Cycles: "..battery.cycles()
    })

    if battery.healthCondition() then
        table.insert(menuTable, {
            title = utf8.codepointToUTF8(0x26A0).."  "..battery.healthCondition()
        })
    end

    table.insert(menuTable, { title = "-" })
    local rawBatteryData = {}
    for i,v in fnutils.sortByKeys(battery.getAll()) do
        table.insert(rawBatteryData, { title = i.." = "..tostring(v), disabled = true })
    end
    table.insert(menuTable, { title = "Raw Battery Data...", menu = rawBatteryData })

    return menuTable
end

module.menuUserdata = menuUserdata -- for debugging, may remove in the future

module.start = function()
    menuUserData, currentPowerSource = menubar.new(), ""

    powerSourceChangeFN()
    powerWatcher:start()

    menuUserData:setMenu(displayBatteryData)
    return module
end

module.stop = function()
    powerWatcher:stop()
    menuUserData = menuUserData:delete()
    return module
end

module = setmetatable(module, {
  __gc = function(self)
      if powerWatcher then powerWatcher:stop() end
  end,
})

return module.start()
