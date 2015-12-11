local timer   = require("hs.timer")
local wifi    = require("hs.wifi")
local drawing = require("hs.drawing")
local screen  = require("hs.screen")

local hotkey  = require("hs.hotkey")
local mods    = require("hs._asm.extras").mods

local noiseColor  = { green = 1, alpha = .5 }
local signalColor = { blue = 1, alpha = .5 }
local sampleSize  = 100
local sampleRate  = 2

 -- actual range is 0 - -120db, but anything below about -85 or so is unusable, so
 -- adjust if you want a more symmetrical or smaller display
local maxDB = 100 -- absolute value of min db to display

local lastBaseY = nil

local module = {}

local drawings = {}

module.sampleTimer = timer.new(sampleRate, function()
    local screenFrame = screen.primaryScreen():fullFrame()
    local baseX = screenFrame.x + screenFrame.w - (sampleSize + 5)
    local baseY = screenFrame.y + screenFrame.h - (maxDB + 5 + 22) -- put it above my clock

    if not lastBaseY then lastBaseY = baseY end

    drawing.disableScreenUpdates()

    drawings[#drawings]:setFrame{
        x = baseX - 5, y = baseY - 5, h = maxDB + 10, w = sampleSize + 10
    }
    if #drawings == (sampleSize * 2 + 1) then
        drawings[1]:delete() ; table.remove(drawings, 1)
        drawings[1]:delete() ; table.remove(drawings, 1)
    end
    local numSamples = (#drawings - 1) / 2
    for i = 1, #drawings - 1, 2 do
        local newX = baseX + sampleSize + math.ceil(i/2) - numSamples
        local signalFrame = drawings[i]:frame()
        signalFrame.x = newX
        local noiseFrame = drawings[i+1]:frame()
        noiseFrame.x = newX
        if lastBaseY ~= baseY then
            signalFrame.y = signalFrame.y - lastBaseY + baseY
            noiseFrame.y = noiseFrame.y - lastBaseY + baseY
        end
        drawings[i]:setFrame(signalFrame):orderAbove(drawings[#drawings])
        drawings[i+1]:setTopLeft(noiseFrame):orderAbove(drawings[i])
    end
    local wifiDetails = wifi.interfaceDetails()
    local signal = maxDB + wifiDetails.rssi
    if signal < 0 then signal = 0 end
    local noise = maxDB + wifiDetails.noise
    if noise < 0 then noise = 0 end
    table.insert(drawings, #drawings, drawing.rectangle{
            x = baseX + sampleSize,
            y = baseY + maxDB - signal,
            w = 1,
            h = signal,
        }:setStroke(false)
         :setFill(true)
         :setFillColor(signalColor)
         :orderAbove(drawings[#drawings])
         :setBehaviorByLabels{"canJoinAllSpaces"}
         :show()
    )
    table.insert(drawings, #drawings, drawing.rectangle{
            x = baseX + sampleSize,
            y = baseY + maxDB - noise,
            w = 1,
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
            drawing.rectangle{}:setFill(true)
                               :setStroke(true)
                               :setFillColor{white = .75, alpha = .5}
                               :setStrokeColor{alpha = .75}
                               :setBehaviorByLabels{"canJoinAllSpaces"}
                               :setRoundedRectRadii(5,5)
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

hotkey.bind(mods.CASC, "w", function()
    if module.sampleTimer:running() then
        module.stop()
    else
        module.start()
    end
end)

return module
