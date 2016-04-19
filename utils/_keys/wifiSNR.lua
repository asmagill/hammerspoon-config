local timer   = require("hs.timer")
local wifi    = require("hs.wifi")
local drawing = require("hs.drawing")
local screen  = require("hs.screen")

local hotkey  = require("hs.hotkey")
local mods    = require("hs._asm.extras").mods

local wifimeter = require("utils.wifimeter")

local noiseColor    = { green = 1, alpha = .5 }
local signalColor   = { blue = 1,  alpha = .5 }

-- not counting background box, height = scaleToHeight, width = sampleSize * sampleRate
local sampleSize    = 50
local scaleToHeight = 100
local sampleRate    = 2

local padding       = 5
local offsetFromLLx = 1
local offsetFromLLy = 23  -- put it above my clock in the LL corner

local lastBaseY  = nil

-- some pre-calculations that don't change over time or with screen changes
local scaleRatio = scaleToHeight / 120
local screenOffsetFromLLx = sampleSize * sampleRate + padding + offsetFromLLx
local screenOffsetFromLLy = scaleToHeight + padding + offsetFromLLy
local boxWidth = sampleSize * sampleRate + padding * 2
local boxHeight = scaleToHeight + padding * 2
local module = {}

local drawings = {}

module.sampleTimer = timer.new(sampleRate, function()
    local screenFrame = screen.primaryScreen():fullFrame()
    local baseX = screenFrame.x + screenFrame.w - screenOffsetFromLLx
    local baseY = screenFrame.y + screenFrame.h - screenOffsetFromLLy

    if not lastBaseY then lastBaseY = baseY end

    drawing.disableScreenUpdates()

    drawings[#drawings]:setTopLeft{ x = baseX - padding, y = baseY - padding }
    if #drawings == (sampleSize * 2 + 1) then
        drawings[1]:delete() ; table.remove(drawings, 1)
        drawings[1]:delete() ; table.remove(drawings, 1)
    end
    local numSamples = (#drawings - 1) / 2
    for i = 1, #drawings - 1, 2 do
        local newX = baseX + ((sampleSize - 1) + (math.ceil(i/2) - 1) - numSamples) * sampleRate
        local signalFrame = drawings[i]:frame()
        local noiseFrame = drawings[i+1]:frame()
        signalFrame.x = newX
        noiseFrame.x = newX
        if lastBaseY ~= baseY then
            signalFrame.y = signalFrame.y - lastBaseY + baseY
            noiseFrame.y = noiseFrame.y - lastBaseY + baseY
        end
        drawings[i]:setTopLeft(signalFrame):orderAbove(drawings[#drawings])
        drawings[i+1]:setTopLeft(noiseFrame):orderAbove(drawings[i])
    end
    local wifiDetails = wifi.interfaceDetails()
    -- Signal and Noise are measured between 0 and -120. Signal closer to 0 is good.
    -- Noise closer to -120 is good.
    local signal = (120 + wifiDetails.rssi) * scaleRatio
    local noise = (120 + wifiDetails.noise) * scaleRatio
    table.insert(drawings, #drawings, drawing.rectangle{
            x = baseX + (sampleSize - 1) * sampleRate,
            y = baseY + scaleToHeight - signal,
            w = sampleRate,
            h = signal,
        }:setStroke(false)
         :setFill(true)
         :setFillColor(signalColor)
         :orderAbove(drawings[#drawings])
         :setBehaviorByLabels{"canJoinAllSpaces"}
         :show()
    )
    table.insert(drawings, #drawings, drawing.rectangle{
            x = baseX + (sampleSize - 1) * sampleRate,
            y = baseY + scaleToHeight - noise,
            w = sampleRate,
            h = noise
        }:setStroke(false)
         :setFill(true)
         :setFillColor(noiseColor)
         :orderAbove(drawings[#drawings - 1])
         :setBehaviorByLabels{"canJoinAllSpaces"}
         :show()
    )

    drawing.enableScreenUpdates()

    lastBaseY = baseY
end)

module.start = function()
    if #drawings == 0 then
        drawings = {
            drawing.rectangle{ x = 0, y = 0, h = boxHeight, w = boxWidth }
                              :setFill(true)
                              :setStroke(true)
                              :setFillColor{white = .75, alpha = .5}
                              :setStrokeColor{alpha = .75}
                              :setBehaviorByLabels{"canJoinAllSpaces"}
                              :setRoundedRectRadii(padding,padding)
                              :show()
        }
    else
        for i = #drawings, 1, -1 do
            drawings[i]:show()
        end
    end
    module.sampleTimer:start()
end

module.stop = function()
    module.sampleTimer:stop()
    for i = #drawings, 1, -1 do
        drawings[i]:hide()
    end
end

module.delete = function()
    module.stop()
    for i,v in ipairs(drawings) do v:delete() end
    drawings = {}
end

module.wifimeter = wifimeter
wifimeter.delayTimer = 1

hotkey.bind(mods.CASC, "w", function()
    if module.sampleTimer:running() then
        module.stop()
        wifimeter.stopObserving()
        module["2GHz"] = module["2GHz"]:hide()
        module["5GHz"] = module["5GHz"]:hide()
    else
        module.start()
        wifimeter.startObserving()
        if not module["2GHz"] then
            module["2GHz"] = wifimeter.new("2GHz"):start():setFrame({x = 10, y = 40, w = 1420, h = 300}):setNetworkPersistence(0):show()
        else
            module["2GHz"]:show()
        end
        if not module["5GHz"] then
            module["5GHz"] = wifimeter.new("5GHz"):start():setFrame({x = 10, y = 345, w = 1420, h = 300}):setNetworkPersistence(0):show()
        else
            module["5GHz"]:show()
        end
    end
end)

return module
