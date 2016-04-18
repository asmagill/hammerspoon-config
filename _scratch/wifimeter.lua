
-- exceedingly poor proof of concept, but it does work, sorta

-- center text, setting height and width appropriate to text, not a "acceptable guess"
-- different colors for each network ellipse
-- when a network hasn't been seen in a bit, drop it
-- clip so ellipse stays in bounds when at edge channels
-- allow altering backgroundFrame x,y,h,w so it moves rather than just centers (or at least offer both)

-- don't do this timer example:
--     m = dofile("_scratch/wifimeter.lua") ; m.createDrawings():drawChannelLabels(m.frequencyTableFromMy("5GHz")):overlayAvailableNetworks("5GHz"):show()
--     t = hs.timer.new(2, function() hs.wifi.backgroundScan(function() m:overlayAvailableNetworks("5GHz"):show() end) end):start()
--
--     t:stop()
--     m.removeDrawings()

-- next scan should start after previous completes, rather than as timer event

-- refactor entire file...
--    module manipulation of backgroundFrame looks like possible addition to grouped drawings project I ponder sometimes
--    some code written as if constructor based with methods, some written as straight functions... pick one!
--      probably constructor based, if backgroundFrame x,y,h,w get's done, so can have both 2GHZ and 5GHz on at the same time
--      if multiple, should share backgroundScan... perhaps the module does repetitive scans with start/stop and notifies its children when a scan completes?



local module  = {}
local screen  = require"hs.screen"
local drawing = require"hs.drawing"
local wifi    = require"hs.wifi"
local fnutils = require"hs.fnutils"

local _kMetaTable = {}
_kMetaTable._k = setmetatable({}, {__mode = "k"})
_kMetaTable._t = setmetatable({}, {__mode = "k"})
_kMetaTable.__index = function(obj, key)
        if _kMetaTable._k[obj] then
            if _kMetaTable._k[obj][key] then
                return _kMetaTable._k[obj][key]
            else
                for k,v in pairs(_kMetaTable._k[obj]) do
                    if v == key then return k end
                end
            end
        end
        return nil
    end
_kMetaTable.__newindex = function(obj, key, value)
        error("attempt to modify a table of constants",2)
        return nil
    end
_kMetaTable.__pairs = function(obj) return pairs(_kMetaTable._k[obj]) end
_kMetaTable.__len = function(obj) return #_kMetaTable._k[obj] end
_kMetaTable.__tostring = function(obj)
        local result = ""
        if _kMetaTable._k[obj] then
            local width = 0
            for k,v in pairs(_kMetaTable._k[obj]) do width = width < #tostring(k) and #tostring(k) or width end
            for k,v in require("hs.fnutils").sortByKeys(_kMetaTable._k[obj]) do
                if _kMetaTable._t[obj] == "table" then
                    result = result..string.format("%-"..tostring(width).."s %s\n", tostring(k),
                        ((type(v) == "table") and "{ table }" or tostring(v)))
                else
                    result = result..((type(v) == "table") and "{ table }" or tostring(v)).."\n"
                end
            end
        else
            result = "constants table missing"
        end
        return result
    end
_kMetaTable.__metatable = _kMetaTable -- go ahead and look, but don't unset this

local _makeConstantsTable
_makeConstantsTable = function(theTable)
    if type(theTable) ~= "table" then
        local dbg = debug.getinfo(2)
        local msg = dbg.short_src..":"..dbg.currentline..": attempting to make a '"..type(theTable).."' into a constant table"
        if module.log then module.log.ef(msg) else print(msg) end
        return theTable
    end
    for k,v in pairs(theTable) do
        if type(v) == "table" then
            local count = 0
            for a,b in pairs(v) do count = count + 1 end
            local results = _makeConstantsTable(v)
            if #v > 0 and #v == count then
                _kMetaTable._t[results] = "array"
            else
                _kMetaTable._t[results] = "table"
            end
            theTable[k] = results
        end
    end
    local results = setmetatable({}, _kMetaTable)
    _kMetaTable._k[results] = theTable
    local count = 0
    for a,b in pairs(theTable) do count = count + 1 end
    if #theTable > 0 and #theTable == count then
        _kMetaTable._t[results] = "array"
    else
        _kMetaTable._t[results] = "table"
    end
    return results
end

local mt_table
mt_table = {
    __storage = {
        framePadding = 20,
        frameAlpha   = 0.75,
        labelPadding = 20,
        backgroundFrame = setmetatable({}, {
            __index = function(_, key)
                if     key == "x"             then return screen.mainScreen():frame().x + module.framePadding
                elseif key == "y"             then return screen.mainScreen():frame().y + module.framePadding
                elseif key == "h"             then return screen.mainScreen():frame().h - module.framePadding * 2
                elseif key == "w"             then return screen.mainScreen():frame().w - module.framePadding * 2
                elseif key == "__luaSkinType" then return "NSRect"
                else                               return nil
                end
            end,
            __newindex = function(_, key, value)
                error("backgroundFrame is dynamically generated and cannot be set directly")
            end,
            __pairs = function(_)
                local keys = { x = true, y = true, h = true, w = true, __luaSkinType = true }
                return function(_, k)
                    local v
                    k, v = next(keys, k)
                    if k then v = _[k] end
                    return k, v
                end, _, nil
            end,
        })
    },
    __constraints = {
        framePadding = function(v)
            assert(screen.mainScreen():frame().h - v * 2 > 1, "invalid frame padding; results in 0 height background")
            assert(screen.mainScreen():frame().w - v * 2 > 1, "invalid frame padding; results in 0 width background")
        end,
        frameAlpha = function(v)
            assert((v >= 0.0) and (v <= 1.0), "invalid alpha; must be between 0.0 and 1.0 inclusive")
        end,
    },
    __index = function(_, k)
        if mt_table.__storage[k] then return mt_table.__storage[k] end
        rawget(_, k) -- shouldn't really ever matter, since a found index means we're not called, but CYA
    end,
    __newindex = function(_, k, v)
        if k == "backgroundFrame" then
            error("backgroundFrame is dynamically generated and cannot be set directly")
        elseif mt_table.__storage[k] then
            if mt_table.__constraints[k] then mt_table.__constraints[k](v) end
            mt_table.__storage[k] = v
            module.updateDrawings()
        else
            rawset(_, k, v)
        end
    end,
    __pairs = function(_)
        local keys = {}
        -- get module contents
        local k, v
        repeat
            k, v = next(_, k)
            if k then keys[k] = true end
        until k == nil
        -- get "special" vars
        for k,v in pairs(mt_table.__storage) do
            keys[k] = true
        end
        return function(_, k)
            local v
            k, v = next(keys, k)
            if k then v = _[k] end
            return k, v
        end, _, nil
    end,
    __gc = function(_)
--         print("** doing __gc cleanup for drawings")
        module.removeDrawings()
    end,
}

module = setmetatable(module, mt_table)
local previousBackgroundFrame = {
    x = module.backgroundFrame.x,
    y = module.backgroundFrame.y,
    h = module.backgroundFrame.h,
    w = module.backgroundFrame.w,
}

module.drawings = {}

local wifiFrequencyXPosition = {}
local seenNetworks = {}
local drawingsVisible = false

module.removeDrawings = function()
    for i, v in ipairs(module.drawings) do v:delete() end
    module.drawings = {}
    wifiFrequencyXPosition = {}
    seenNetworks = {}
    drawingsVisible = false
    return module
end

module.show = function()
    if #module.drawings > 0 then
        module.drawings[1]:show()
        for i = 2, #module.drawings, 1 do
            module.drawings[i]:show():orderAbove(module.drawings[i - 1])
        end
    end
    drawingsVisible = true
    return module
end

module.hide = function()
    for i, v in ipairs(module.drawings) do v:hide() end
    drawingsVisible = false
    return module
end

module.updateDrawings = function()
    local hRatio  = module.backgroundFrame.h / previousBackgroundFrame.h
    local wRatio  = module.backgroundFrame.w / previousBackgroundFrame.w

    if wifiFrequencyXPosition.multiplier then
        wifiFrequencyXPosition.multiplier = wifiFrequencyXPosition.multiplier * wRatio
    end

    for i, v in ipairs(module.drawings) do
        local prevDrawingFrame = v:frame()
        v:setFrame({
            x = module.backgroundFrame.x + (prevDrawingFrame.x - previousBackgroundFrame.x) * wRatio,
            y = module.backgroundFrame.y + (prevDrawingFrame.y - previousBackgroundFrame.y) * hRatio,
            h = prevDrawingFrame.h * hRatio,
            w = prevDrawingFrame.w * wRatio,
        }):setAlpha( (i == 1) and module.frameAlpha or 1.0 )
          :clippingRectangle(module.backgroundFrame or nil )
        if drawingsVisible then v:show() end
    end

    previousBackgroundFrame = {
        x = module.backgroundFrame.x,
        y = module.backgroundFrame.y,
        h = module.backgroundFrame.h,
        w = module.backgroundFrame.w,
    }
    return module
end

module.createDrawings = function()
    if #module.drawings ~= 0 then error("drawings already created") end

    table.insert(module.drawings,
          drawing.rectangle(module.backgroundFrame):setRoundedRectRadii(10, 10)
                                                   :setAlpha(module.frameAlpha)
                                                   :setFill(true)
                                                   :setStroke(true)
                                                   :setStrokeWidth(5)
                                                   :setFillColor{   white = 0.25 }
                                                   :setStrokeColor{ white = 0.10 }
    )
    return module
end

-- https://en.wikipedia.org/wiki/List_of_WLAN_channels
module.wifiFrequencies = _makeConstantsTable{
    ["2GHz"] = {
         [1] = 2412,           [2] = 2417,          [3] = 2422,
         [4] = 2427,           [5] = 2432,          [6] = 2437,
         [7] = 2442,           [8] = 2447,          [9] = 2452,
        [10] = 2457,          [11] = 2462,         [12] = 2467,
        [13] = 2472,          [14] = 2484,
    },
    ["5GHz"] = {
          [7] = 5035,          [8] = 5040,          [9] = 5045,
         [11] = 5055,         [12] = 5060,         [16] = 5080,
         [34] = 5170,         [36] = 5180,         [38] = 5190,
         [40] = 5200,         [42] = 5210,         [44] = 5220,
         [46] = 5230,         [48] = 5240,         [50] = 5250,
         [52] = 5260,         [54] = 5270,         [56] = 5280,
         [58] = 5290,         [60] = 5300,         [62] = 5310,
         [64] = 5320,        [100] = 5500,        [102] = 5510,
        [104] = 5520,        [106] = 5530,        [108] = 5540,
        [110] = 5550,        [112] = 5560,        [114] = 5570,
        [116] = 5580,        [118] = 5590,        [120] = 5600,
        [122] = 5610,        [124] = 5620,        [126] = 5630,
        [128] = 5640,        [132] = 5660,        [134] = 5670,
        [136] = 5680,        [138] = 5690,        [140] = 5700,
        [142] = 5710,        [144] = 5720,        [149] = 5745,
        [151] = 5755,        [153] = 5765,        [155] = 5775,
        [157] = 5785,        [159] = 5795,        [161] = 5805,
        [165] = 5825,        [183] = 4915,        [184] = 4920,
        [185] = 4925,        [187] = 4935,        [188] = 4940,
        [189] = 4945,        [192] = 4960,        [196] = 4980,
    },
}

module.drawChannelLabels = function(...)
    local frequencyTable = table.pack(...)[#table.pack(...)]
    if next(wifiFrequencyXPosition) then error("labels already generated") end
    local availableWidth = module.backgroundFrame.w - module.labelPadding * 4
    local minFreq, maxFreq = math.huge, 0
    for k, v in pairs(frequencyTable) do
        if v < minFreq then minFreq = v end
        if v > maxFreq then maxFreq = v end
    end

    local multiplier = availableWidth / (maxFreq - minFreq)
    for k, v in fnutils.sortByKeyValues(frequencyTable) do
        local xPos =  module.backgroundFrame.x + module.labelPadding * 2 + (v - minFreq) * multiplier
        wifiFrequencyXPosition[k] = xPos
        table.insert(module.drawings, drawing.text({
                x = xPos,
                y = module.backgroundFrame.y + module.backgroundFrame.h - module.labelPadding * 2,
                h = module.labelPadding,
                w = 50,
            }, tostring(k)):setTextFont("Menlo")
                           :setTextSize(12)
        )
    end
    wifiFrequencyXPosition.multiplier = multiplier
    return module
end

module.frequencyTableFromMy = function(base, interface)
    interface = interface or "en0"
    assert(module.wifiFrequencies[base], "no frequency data for " .. base)
    local supportedChannels = wifi.interfaceDetails(interface).supportedChannels
    if not supportedChannels then
        wifi.availableNetworks() -- blocking, so only do if necessary
        supportedChannels = wifi.interfaceDetails(interface).supportedChannels
    end
    local results = {}
    for k, v in ipairs(supportedChannels) do
        if v.band == base then
            results[v.number] = module.wifiFrequencies[base][v.number]
        end
    end
    return results
end

module.overlayAvailableNetworks = function(self, base, interface)
    interface = interface or "en0"
    assert(module.wifiFrequencies[base], "no frequency data for " .. base)
    local cachedScanResults = wifi.interfaceDetails(interface).cachedScanResults
    if not cachedScanResults then
        wifi.availableNetworks() -- blocking, so only do if necessary
        cachedScanResults = wifi.interfaceDetails(interface).cachedScanResults
    end
    for i, v in ipairs(cachedScanResults) do
        if v.wlanChannel.band == base then
            local keyName = string.format("%s-%d", tostring(v.ssid), tostring(v.wlanChannel.number))
            local wifiDrawingIndex = seenNetworks[keyName]
            if not wifiDrawingIndex then
                local width = wifiFrequencyXPosition.multiplier * tonumber(v.wlanChannel.width:match("^(%d+)MHz"))
                local wifiDrawing = drawing.ellipticalArc({
                        x = wifiFrequencyXPosition[v.wlanChannel.number] - width / 2,
                        y = 10, -- filler
                        h = 10, -- filler
                        w = width
                    }, -90, 90):setStrokeWidth(3)
                               :setStrokeColor{green = 1} -- will change
                               :setFill(false):setFillColor{red=1}
                               :setStroke(true)
                local wifiDrawingLabel = drawing.text({
                        x = wifiFrequencyXPosition[v.wlanChannel.number],
                        y = 10, -- filler
                        h = module.labelPadding,
                        w = 200,
                    }, keyName:match("^(.*)-%d+$")):setTextColor{green = 1}
                                                   :setTextFont("Menlo")
                                                   :setTextSize(12)
                table.insert(module.drawings, wifiDrawing)
                table.insert(module.drawings, wifiDrawingLabel)
                wifiDrawingIndex = #module.drawings - 1
                seenNetworks[keyName] = wifiDrawingIndex
            end

--             local signal = (v.rssi - v.noise) * (module.backgroundFrame.h - module.labelPadding * 2) / 120
            local signal = math.abs(v.rssi) * (module.backgroundFrame.h - module.labelPadding * 2) / 120
            local wifiDrawing, wifiDrawingLabel = module.drawings[wifiDrawingIndex], module.drawings[wifiDrawingIndex + 1]

            local wifiDrawingFrame, labelFrame = wifiDrawing:frame(), wifiDrawingLabel:frame()
            wifiDrawingFrame.y = module.backgroundFrame.y + module.backgroundFrame.h - (signal + module.labelPadding * 4)
            wifiDrawingFrame.h = signal * 2
            labelFrame.y = module.backgroundFrame.y + module.backgroundFrame.h - (signal / 2 + module.labelPadding * 4)

            wifiDrawing:setFrame(wifiDrawingFrame)
            wifiDrawingLabel:setFrame(labelFrame)
        end
        module.updateDrawings()
    end
    return module
end

return module