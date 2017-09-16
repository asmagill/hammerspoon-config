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

local menubar    = require("hs.menubar")
local utf8       = require("hs.utf8")
local battery    = require("hs.battery")
local fnutils    = require("hs.fnutils")
local settings   = require("hs.settings")
local speech     = require("hs.speech")
local styledtext = require("hs.styledtext")
local timer      = require("hs.timer")

local onAC       = utf8.codepointToUTF8(0x1F50C) -- plug
local onBattery  = utf8.codepointToUTF8(0x1F50B) -- battery

local suppressAudioKey = "_asm.battery.suppressAudio"
local suppressAudio = settings.get(suppressAudioKey) or false

local menuUserData = nil
local currentPowerSource = ""

-- Some "notifications" to apply... need to update battery watcher to do these
module.batteryNotifications = {
    { onBattery = true, percentage = 10, doEvery = false,
        fn = function()
            local alert = require("hs.alert")
            if not suppressAudio then
                local audio = require("hs.audiodevice").defaultOutputDevice()
                local volume, muted = audio:volume(), audio:muted()
                -- apparently some devices don't have a volume or mute...
                if volume then audio:setVolume(100) end
                if muted then audio:setMuted(false) end
                local sp = speech.new("Zarvox"):setCallback(function(s, why, ...)
                    if why == "didFinish" then
                        if volume then audio:setVolume(volume) end
                        if muted then audio:setMuted(true) end
                    end
                end):speak("LOW BATTERY")
            end
            alert.show("LOW BATTERY")
        end
    },
    { onBattery = true, percentage = 5, doEvery = 60,
        fn = function()
            local alert = require("hs.alert")
            if not suppressAudio then
                local audio = require("hs.audiodevice").defaultOutputDevice()
                local volume, muted = audio:volume(), audio:muted()
                -- apparently some devices don't have a volume or mute...
                if volume then audio:setVolume(100) end
                if muted then audio:setMuted(false) end
                local sp = speech.new("Zarvox"):setCallback(function(s, why, ...)
                    if why == "didFinish" then
                        if volume then audio:setVolume(volume) end
                        if muted then audio:setMuted(true) end
                    end
                end):speak("PLUG ME IN NOW")
            end
            alert.show("PLUG ME IN NOW")
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
            if not suppressAudio then
        -- I don't care if I miss this one, so... no volume changes
                local sp = speech.new("Zarvox"):speak("Feeling returning to my circuits")
            end
        end
    },
    { onBattery = false, percentage = 90, doEvery = false,
        fn = function()
            if not suppressAudio then
        -- I don't care if I miss this one, so... no volume changes
                local sp = speech.new("Zarvox"):speak("I'm feeling [[inpt PHON; rate 80]]+mUXC[[inpt TEXT; rset 0]] better [[emph +]]now")
            end
        end
    },
}

local notificationStatus = {}

local updateMenuTitle = function()
    if menuUserData then
        local text = string.format("%+d\n", battery.amperage())

        local timeValue = -999
        if battery.powerSource() == "AC Power" then
            timeValue = battery.timeToFullCharge()
        else
            timeValue = battery.timeRemaining()
        end
-- print(timeValue)
        text = text ..((timeValue < 0) and "???" or
                string.format("%d:%02d", math.floor(timeValue/60), timeValue%60))

        local titleColor = (require"hs.host".interfaceStyle() == "Dark") and { white = 1 } or { white = 0 }

        menuUserData:setTitle(styledtext.new(text,  {
                                                        font = {
                                                            name = "Menlo",
                                                            size = 9
                                                        },
                                                        color = titleColor,
                                                        paragraphStyle = {
                                                            alignment = "center",
                                                        },
                                                    }))
    end
end

local powerSourceChangeFN = function(justOn)
    local newPowerSource = battery.powerSource()
    local test = {
        percentage = battery.percentage(),
        onBattery = battery.powerSource() == "Battery Power",
        timeRemaining = battery.timeRemaining(),
        timeStamp = os.time()
    }
    if menuUserData then updateMenuTitle() end

    if currentPowerSource ~= newPowerSource then
        currentPowerSource = newPowerSource
        for i,v in ipairs(module.batteryNotifications) do
            if newPowerSource == "AC Power" then
                if not v.onBattery then
                    if v.percentage and test.percentage > v.percentage then notificationStatus[i] = test.timeStamp end
                end
            else
                if v.onBattery then
                    if v.percentage and test.percentage < v.percentage then notificationStatus[i] = test.timeStamp end
                    if v.timeRemaining and test.timeRemaining < v.timeRemaining then notificationStatus[i] = test.timeStamp end
                end
            end
        end
--         if menuUserData then
--             if currentPowerSource == "AC Power" then
--                 menuUserData:setTitle(onAC)
--             else
--                 menuUserData:setTitle(onBattery)
--             end
--         end
    end
    if not justOn then
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
                        if v.onBattery and test.timeRemaining > 0 then
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
    else
        for i,v in ipairs(module.batteryNotifications) do
            if v.onBattery == test.onBattery then
                local shouldWeDoSomething = false
                if v.percentage then
                    if v.onBattery then
                        shouldWeDoSomething = (test.percentage - v.percentage) < 0
                    else
                        shouldWeDoSomething = (test.percentage - v.percentage) > 0
                    end
                elseif v.timeRemaining then
                    if v.onBattery and test.timeRemaining > 0 then
                        shouldWeDoSomething = (test.timeRemaining - v.timeRemaining) < 0
                    else
                        shouldWeDoSomething = (test.timeRemaining - v.timeRemaining) > 0
                    end
                else
                    print("++ unknown test for battery notification #"..tostring(i))
                end

                if shouldWeDoSomething then notificationStatus[i] = test.timeStamp end
            end
        end
    end
end

-- local powerWatcher = battery.watcher.new(powerSourceChangeFN)

local rawBatteryData
rawBatteryData = function(tbl)
    local data = {}
    for i,v in fnutils.sortByKeys(tbl) do
        if type(v) ~= "table" then
            table.insert(data, {
                title = styledtext.new(i.." = "..tostring(v), { font = { name ="Menlo", size = 10 } }),
                disabled = true,
            })
        else
            table.insert(data, {
                title = styledtext.new(i, { font = { name ="Menlo", size = 10 } }),
                menu = rawBatteryData(v),
                disabled = not next(v),
            })
        end
    end

    return data
end

local displayBatteryData = function(modifier)
    local menuTable = {}
    updateMenuTitle()
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

    table.insert(menuTable, { title = "Raw Battery Data...", menu = rawBatteryData(battery.getAll()) })

    table.insert(menuTable, { title = "-" })

    table.insert(menuTable, { title = "Suppress Audio", checked = suppressAudio, fn = function()
        suppressAudio = not suppressAudio
        settings.set(suppressAudioKey, suppressAudio)
    end })

    return menuTable
end

--module.menuUserdata = menuUserData -- for debugging, may remove in the future

module.start = function()
--     menuUserData, currentPowerSource = menubar.new(), ""
    menuUserData, currentPowerSource = menubar.newWithPriority(999), ""

    powerSourceChangeFN(true)
--     powerWatcher:start()

    menuUserData:setMenu(displayBatteryData)

--     module.menuTitleChanger = timer.doEvery(5, updateMenuTitle)
    module.menuTitleChanger = timer.doEvery(5, powerSourceChangeFN)
    module.menuUserdata = menuUserData -- for debugging, may remove in the future
    return module
end

module.stop = function()
--     powerWatcher:stop()
    module.menuTitleChanger:stop()
    module.menuTitleChanger = nil
    menuUserData = menuUserData:delete()
    return module
end

module = setmetatable(module, {
    __gc = function(self)
--         if powerWatcher then powerWatcher:stop() end
        if module.menuTitleChanger then module.menuTitleChanger:stop() end
    end,
})

-- module.powerWatcher = powerWatcher

return module.start()
