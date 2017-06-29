local UUIDperipheralCurieBLE   = "E924FF90-D5FD-41EB-A8BF-C0C928DE014F"
local UUIDserviceCommand       = "EA833120-DBE3-4035-B8EC-006AAD46BB07"
local UUIDcharacteristicAction = "EA833121-DBE3-4035-B8EC-006AAD46BB07"

local UUIDserviceIMU                  = "831BA4C0-4F24-4E46-85D9-1F04852731AA"
local UUIDcharacteristicAccelerometer = "831BA4C1-4F24-4E46-85D9-1F04852731AA"
local UUIDcharacteristicGyroscope     = "831BA4C2-4F24-4E46-85D9-1F04852731AA"

local module = {}

local ble    = require("hs._asm.btle")
local timer  = require("hs.timer")
local hotkey = require("hs.hotkey")
local mods   = require("hs._asm.extras").mods

local sendChar = function(char)
    local service = ble.discovered[UUIDperipheralCurieBLE].services[UUIDserviceCommand]
    if service then
        local characteristic = service.characteristics[UUIDcharacteristicAction]
        if characteristic then
            characteristic.characteristic:writeValue(((type(char) == "string") and char:sub(1,1) or "\0"))
        else
            hs.printf("missing characteristic %s for service %s", UUIDcharacteristicAction, UUIDserviceCommand)
        end
    else
        hs.printf("missing service %s", UUIDserviceCommand)
    end
--     ble.discovered[UUIDperipheralCurieBLE].
--         services[UUIDserviceCommand].
--         characteristics[UUIDcharacteristicAction].characteristic:writeValue(((type(char) == "string") and char:sub(1,1) or "\0"))
end

ble.create()

module._modalKeys = hotkey.modal.new()
function module._modalKeys:entered() end
    module._modalKeys:bind(mods.cAsc, "w",     function() sendChar("1") end, function() sendChar("\0") end)
    module._modalKeys:bind(mods.cAsc, "a",     function() sendChar("2") end, function() sendChar("\0") end)
    module._modalKeys:bind(mods.cAsc, "s",     function() sendChar("3") end, function() sendChar("\0") end)
    module._modalKeys:bind(mods.cAsc, "d",     function() sendChar("4") end, function() sendChar("\0") end)
    module._modalKeys:bind(mods.cAsc, "f",     function() sendChar("5") end, function() sendChar("\0") end)
--     module._modalKeys:bind(mods.cAsc, "",     function() sendChar("6") end, function() sendChar("\0") end)
    module._modalKeys:bind(mods.cAsc, "e",     function() sendChar("7") end, function() sendChar("\0") end)
    module._modalKeys:bind(mods.cAsc, "r",     function() sendChar("8") end, function() sendChar("\0") end)
    module._modalKeys:bind(mods.cAsc, "up",    function() sendChar("a") end, function() sendChar("\0") end)
    module._modalKeys:bind(mods.cAsc, "down",  function() sendChar("b") end, function() sendChar("\0") end)
    module._modalKeys:bind(mods.cAsc, "left",  function() sendChar("c") end, function() sendChar("\0") end)
    module._modalKeys:bind(mods.cAsc, "right", function() sendChar("d") end, function() sendChar("\0") end)
function module._modalKeys:exited() sendChar("\0") end

module._setupTimer = timer.doEvery(1, function()
    if ble._manager then
        module._setupTimer:stop()
        module._setupTimer = timer.doEvery(1, function()
            if ble._manager:state() == "poweredOn" then
                module._setupTimer:stop()
                ble.startScanning()
                module._setupTimer = timer.doEvery(1, function()
                    if ble.discovered[UUIDperipheralCurieBLE] then
                        module._setupTimer:stop()
                        module._setupTimer = nil
                        print("Curie BLE discovered")
                    end
                end)
            end
        end)
    end
end)

module.connect = function()
    if ble.discovered[UUIDperipheralCurieBLE].peripheral:state() == "disconnected" then
        ble._manager:connectPeripheral(ble.discovered[UUIDperipheralCurieBLE].peripheral)
        module._modalKeys:enter()
    else
        print("already connected or in progress")
    end
end

module.watch = function(watchUpdate)
    local service = ble.discovered[UUIDperipheralCurieBLE].services[UUIDserviceIMU]
    if service then
        local characteristic = service.characteristics[UUIDcharacteristicAccelerometer]
        if characteristic then
            characteristic.characteristic:watch(watchUpdate)
        else
            hs.printf("missing characteristic %s for service %s", UUIDcharacteristicAccelerometer, UUIDserviceIMU)
        end
        local characteristic = service.characteristics[UUIDcharacteristicGyroscope]
        if characteristic then
            characteristic.characteristic:watch(watchUpdate)
        else
            hs.printf("missing characteristic %s for service %s", UUIDcharacteristicGyroscope, UUIDserviceIMU)
        end
        ble.discovered[UUIDperipheralCurieBLE].fn = function(peripheral, message, ...)
            if message == "didUpdateValueForCharacteristic" then
                local characteristic, errMsg = ...
                local cUUID = characteristic:UUID()
                if errMsg then
                    print("error with update to " .. cUUID .. ": " .. errMsg)
                else
                    local label = ""
                    if cUUID == UUIDcharacteristicAccelerometer then
                        label = "Accelerometer"
                    elseif cUUID == UUIDcharacteristicGyroscope then
                        label = "Gyroscope"
                    else
                        print("not watching characteristic " .. cUUID)
                        return
                    end
                    local value = characteristic:value()
                    if #value == 12 then
                        local x, y, z = string.unpack("fff", value)
                        hs.printf("%-13s: X:%7.3f Y:%7.3f Z:%7.3f", label, x, y, z)
                    else
                        print("unexpected value length for " .. cUUID)
                    end
                end
            end
        end
    else
        hs.printf("missing service %s", UUIDserviceIMU)
    end
end


module.disconnect = function()
    if ble.discovered[UUIDperipheralCurieBLE].peripheral:state() ~= "disconnected" then
        ble.discovered[UUIDperipheralCurieBLE].fn = nil
        module._modalKeys:exit()
        ble._manager:disconnectPeripheral(ble.discovered[UUIDperipheralCurieBLE].peripheral)
    else
        print("not connected")
    end
end

return module
