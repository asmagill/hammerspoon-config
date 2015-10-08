local module = {}
local serial = require("hs._asm.serial")

local begin = string.char(0xff)..string.char(0x55)

local timeout = 5

local M1Dev,  M1port  = 0x0A, 0x90
local M2Dev,  M2port  = 0x0A, 0xA0
local USDev,  USport  = 0x01, 0x30
local PIRDev, PIRport = 0x0F, 0x80

local cmdGet, cmdRun = 0x01, 0x02

local distance = -1
local pir      = -1
local rotation =  0

local defaultPort = "/dev/cu.Makeblock-ELETSPP"
local port

local updateTimer
updateTimer = hs.timer.new(1, function()
    updateTimer:stop()
    local input
    local timeStamp

    port:flushBuffer()
    port:write(begin ..
               string.char(cmdGet) ..
               string.char(3) ..      -- data length
               string.char(USDev) ..
               string.char(USport) ..
               string.char(0x1f))     -- id for response data... we're ignoring it for now
    timeStamp = os.time()
    while (port:bufferSize() < 9 and (os.time() - timeStamp) < timeout) do end
    if port:bufferSize() < 9 then
        print("-- timeout reading UltraSonic sensor")
    else
        input = port:readBuffer()
        distance = string.unpack("f", input:sub(4, 7))
    end

    port:flushBuffer()
    port:write(begin ..
               string.char(cmdGet) ..
               string.char(3) ..      -- data length
               string.char(PIRDev) ..
               string.char(PIRport) ..
               string.char(0x1f))     -- id for response data... we're ignoring it for now

    timeStamp = os.time()
    while (port:bufferSize() < 9 and (os.time() - timeStamp) < timeout) do end
    if port:bufferSize() < 9 then
        print("-- timeout reading PIR sensor")
    else
        input = port:readBuffer()
        pir = string.unpack("f", input:sub(4, 7))
    end

    module.updateDisplay()
    updateTimer:start()
end)

local sensorDisplay = hs.drawing.rectangle{}
                                  :setStroke(true)
                                  :setStrokeColor{alpha = .75}
                                  :setFill(true)
                                  :setFillColor{red = .75, blue = .75, green = .75, alpha = .95}
                                  :setRoundedRectRadii(5, 5)

local distanceLabel = hs.drawing.text({}, "Distance:")
                                  :setTextFont("Menlo")
                                  :setTextSize(18)
                                  :setTextColor{alpha = 1}

local pirLabel      = hs.drawing.text({}, "PIR Sensor:")
                                  :setTextFont("Menlo")
                                  :setTextSize(18)
                                  :setTextColor{alpha = 1}

local rotationLabel = hs.drawing.text({}, "Rotation:")
                                  :setTextFont("Menlo")
                                  :setTextSize(18)
                                  :setTextColor{alpha = 1}

local distanceValue = hs.drawing.text({}, "Distance:")
                                  :setTextFont("Menlo")
                                  :setTextSize(18)
                                  :setTextColor{red = .75, blue = .75, alpha = 1}

local pirValue      = hs.drawing.text({}, "PIR Sensor:")
                                  :setTextFont("Menlo")
                                  :setTextSize(18)
                                  :setTextColor{red = .75, blue = .75, alpha = 1}

local rotationValue = hs.drawing.text({}, "Rotation:")
                                  :setTextFont("Menlo")
                                  :setTextSize(18)
                                  :setTextColor{red = .75, blue = .75, alpha = 1}

local tank          = hs.drawing.image({}, hs.image.imageFromPath("robots/1.png"))
                                  :imageScaling("none")
                                  :imageAlignment("center")

local upperLeft = { x= 100, y = 100 }

local motoFunction = function(left, right)
    port:write(begin ..
               string.char(cmdRun) ..
               string.char(6) ..      -- data length
               string.char(M1Dev) ..
               string.char(M1port) ..
               string.pack("f", left))
    port:write(begin ..
               string.char(cmdRun) ..
               string.char(6) ..      -- data length
               string.char(M2Dev) ..
               string.char(M2port) ..
               string.pack("f", right))

    port:flushBuffer() -- we're not checking for the Call OK signal at present...
end

local keys = {
    up = hs.hotkey.new({"cmd","alt"}, "up",
            function() motoFunction(-150, -150) end,
            function() motoFunction(0, 0) end, nil
    ),
    down = hs.hotkey.new({"cmd","alt"}, "down",
            function() motoFunction(150, 150) end,
            function() motoFunction(0, 0) end, nil
    ),
    left = hs.hotkey.new({"cmd","alt"}, "left",
            function() motoFunction(150, -150) ; rotation = rotation - 1 end,
            function() motoFunction(0, 0) end, function() rotation = rotation - 1 end
    ),
    right = hs.hotkey.new({"cmd","alt"}, "right",
            function() motoFunction(-150, 150) ; rotation = rotation + 1  end,
            function() motoFunction(0, 0) end, function() rotation = rotation + 1 end
    ),
}

module._keys = keys
module._images = {
    sensorDisplay = sensorDisplay,
    distanceLabel = distanceLabel,
    pirLabel      = pirLabel,
    rotationLabel = rotationLabel,
    distanceValue = distanceValue,
    pirValue      = pirValue,
    rotationValue = rotationValue,
    tank          = tank,
}

module.upperLeft = upperLeft

module.showDisplay = function()
    sensorDisplay:setFrame{ x = upperLeft.x,
                            y = upperLeft.y,
                            h = 80,
                            w = 420
                          }:show()

    distanceLabel:setFrame{ x = upperLeft.x + 10,
                            y = upperLeft.y + 10,
                            h = 26,
                            w = 130
                          }:orderAbove(sensorDisplay):show()
         pirLabel:setFrame{ x = upperLeft.x + 210,
                            y = upperLeft.y + 10,
                            h = 26,
                            w = 130
                          }:orderAbove(sensorDisplay):show()
    rotationLabel:setFrame{ x = upperLeft.x + 10,
                            y = upperLeft.y + 36,
                            h = 26,
                            w = 130
                          }:orderAbove(sensorDisplay):show()

    distanceValue:setFrame{ x = upperLeft.x + 140,
                            y = upperLeft.y + 10,
                            h = 26,
                            w = 70
                          }:orderAbove(sensorDisplay):show()
         pirValue:setFrame{ x = upperLeft.x + 340,
                            y = upperLeft.y + 10,
                            h = 26,
                            w = 70
                          }:orderAbove(sensorDisplay):show()
    rotationValue:setFrame{ x = upperLeft.x + 140,
                            y = upperLeft.y + 36,
                            h = 26,
                            w = 70
                          }:orderAbove(sensorDisplay):show()

             tank:setFrame{ x = upperLeft.x + 430,
                            y = upperLeft.y - 80,
                            h = 250,
                            w = 250
                          }:rotateImage(rotation):show()

    module.updateDisplay()
end

module.hideDisplay = function()
    sensorDisplay:hide()

    distanceLabel:hide()
         pirLabel:hide()
    rotationLabel:hide()

    distanceValue:hide()
         pirValue:hide()
    rotationValue:hide()
             tank:hide()
end

module.updateDisplay = function()
    distanceValue:setText(tostring(distance).." cm")
         pirValue:setText((pir == 1) and "true" or ((pir == -1) and tostring(pir) or "false"))
    rotationValue:setText(tostring(rotation))
             tank:rotateImage(rotation)
end

module.engage = function(serialPort)
    serialPort = serialPort or defaultPort
    if port and port:isOpen() then
        error("serial port already in use. disengage first.", 2)
    end

    port = serial.port(serialPort):baud(115200):open()
    module.port = port
    rotation = 0
    module.showDisplay()
    updateTimer:start()
    for k, v in pairs(keys) do v:enable() end
end

module.disengage = function()
    if port and port:isOpen() then
        for k, v in pairs(keys) do v:disable() end
        updateTimer:stop()
        port:close()
        module.hideDisplay()
        distance = -1
        pir = -1
        rotation = 0
    end
end

return setmetatable(module, { __gc = function(_)
    module.disengage()
end})
