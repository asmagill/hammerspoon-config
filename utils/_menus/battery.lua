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

       [x] issue warning for low battery?  System doesn't if we hide it's icon...
       [ ] change menu title to icon with color change for battery state?
              awaiting way to composite drawing objects...

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

-- Some "notifications" to apply... need to update battery watcher to do these
module.batteryNotifications = {
    { onBattery = true, percentage = 10, doEvery = false,
        fn = function()
            local audio = require("hs.audiodevice").defaultOutputDevice()
            local volume, muted = audio:volume(), audio:muted()
            -- apparently some devices don't have a volume or mute...
            if volume then audio:setVolume(100) end
            if muted then audio:setMuted(false) end
            os.execute([[ say -v "Zarvox" "LOW BATTERY" ]])
            if volume then audio:setVolume(volume) end
            if muted then audio:setMuted(true) end
        end
    },
    { onBattery = true, percentage = 5, doEvery = 60,
        fn = function()
            local audio = require("hs.audiodevice").defaultOutputDevice()
            local volume, muted = audio:volume(), audio:muted()
            -- apparently some devices don't have a volume or mute...
            if volume then audio:setVolume(100) end
            if muted then audio:setMuted(false) end
            os.execute([[ say -v "Zarvox" "PLUG ME IN NOW" ]])
            if volume then audio:setVolume(volume) end
            if muted then audio:setMuted(true) end
        end
    },
    { onBattery = true, timeRemaining = 30, doEvery = 300,
        fn = function()
            local alert = require("hs.alert")
            local battery = require("hs.battery")
            alert.show("Battery has "..tostring(math.floor(battery.timeRemaining())).." minutes left...", 10)
        end
    },
    { onBattery = false, percentage = 10, doEvery = false,
        fn = function()
        -- I don't care if I miss this one, so... no volume changes
            os.execute([[ say -v "Zarvox" "Feeling returning to my circuits" ]])
        end
    },
    { onBattery = false, percentage = 90, doEvery = false,
        fn = function()
        -- I don't care if I miss this one, so... no volume changes
            os.execute([==[ say -v "Zarvox" "I'm feeling [[inpt PHON; rate 80]]+mUXC[[inpt TEXT; rset 0]] better [[emph +]]now" ]==])
        end
    },
}

local notificationStatus = {}

local powerSourceChangeFN = function(justOn)
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
    if not justOn then
        local test = {
            percentage = battery.percentage(),
            onBattery = battery.powerSource() == "Battery Power",
            timeRemaining = battery.timeRemaining(),
            timeStamp = os.time()
        }

        for i,v in ipairs(module.batteryNotifications) do
            if v.onBattery == test.onBattery then
                local shouldWeDoSomething = false
                if not notificationStatus[i] then
                    if v.percentage then
                        if v.onBattery then
                            shouldWeDoSomething = (test.percentage - v.percentage) < 0
                        else
                            shouldWeDoSomething = (test.percentage - v.percentage) > 0
                        end
                    elseif v.timeRemaining then
                        if v.onBattery then
                            shouldWeDoSomething = (test.timeRemaining - v.timeRemaining) < 0
                        else
                            shouldWeDoSomething = (test.timeRemaining - v.timeRemaining) > 0
                        end
                    else
                        print("++ unknown test for battery notification #"..tostring(i))
                    end
                elseif notificationStatus[i] and doEvery and
                  (test.timeStamp - notificationStatus[i]) > v.doEvery then
                      shouldWeDoSomething = true
                end
--                print("++ "..tostring(i).." -- "..hs.inspect(v))
                if shouldWeDoSomething then
                    notificationStatus[i] = test.timeStamp
                    v.fn()
                end
            else
            -- remove stored status for wrong onBattery types...
                if notificationStatus[i] then notificationStatus[i] = nil end
            end
        end
    end
end

local powerWatcher = battery.watcher.new(powerSourceChangeFN)

local displayBatteryData = function(modifier)
    local menuTable = {}

    local pwrIcon = (battery.powerSource() == "AC Power") and onAC or onBattery
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

    powerSourceChangeFN(true)
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
