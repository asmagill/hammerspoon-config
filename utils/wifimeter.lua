local screen     = require"hs.screen"
local drawing    = require"hs.drawing"
local wifi       = require"hs.wifi"
local fnutils    = require"hs.fnutils"
local styledtext = require"hs.styledtext"
local timer      = require"hs.timer"

-- pretty basic, undocumented, and likely buggy wifi network detector...
--
-- e.g.
--
-- wm = require("utils.wifimeter")
-- wm.startObserving()
-- twoG = wm.new("2GHz"):start():setFrame({x = 10, y = 40, w = 1420, h = 300}):show()
-- fiveG = wm.new("5GHz"):start():setFrame({x = 10, y = 345, w = 1420, h = 300}):show()
--
-- Known bugs: start must occur before a frame is set or background doesn't appear
--             haven't decided how to show noise levels yet
--             update is sporadic, using backgroundScan so minimizes impact, but not sure what, if anything we can do about it.
--             undocumented... does what I want for now, but I may wrap it up nicer later and document then


local module     = {}

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

-- observers to notify when wifi information is updated
local observers = {}

-- function which notifies watching observers
local notifyObservers
notifyObservers = function(results)
    module.lastScanTime = timer.secondsSinceEpoch()
    if module.backgroundScanner then
        -- we're supposed to be running, so notify observers and renew scan
        for i,v in ipairs(observers) do
            if v.isWatching then v:updateWifiData(results) end
        end
        if module.delayTimer and module.delayTimer > 0 then
            module.scanDelayTimer = timer.doAfter(module.delayTimer, function()
                if module.backgroundScanner then
                    module.backgroundScanner = wifi.backgroundScan(notifyObservers)
                end
                module.scanDelayTimer = nil
            end)
        else
            module.backgroundScanner = wifi.backgroundScan(notifyObservers)
        end
    end
end

local calculateXOffsets = function(self)
    local results = {}
    local availableWidth = self.frame.w - self.padding * 2
--     print(availableWidth)
    local minFreq, maxFreq = math.huge, 0
    for i, v in pairs(self.channelList) do
        local f = module.wifiFrequencies[self.band][v]
        if f < minFreq then minFreq = f end
        if f > maxFreq then maxFreq = f end
    end
    local multiplier = availableWidth / (maxFreq - minFreq)
    results["multiplier"] = multiplier

    for i, v in ipairs(self.channelList) do
        local f = module.wifiFrequencies[self.band][v]
        results[v] = (f - minFreq) * multiplier
    end

    return results
end

local variablesThatCauseUpdates = {
    frame              = { x = 100, y = 100, h = 700, w = 1240 },
    frameAlpha         = 0.75,
    padding            = 20,
    colorList          = {
        { red = 1.0, green = 1.0, blue = 1.0 },
        { red = 1.0, green = 1.0, blue = 0.5 },
        { red = 1.0, green = 1.0, blue = 0.0 },
        { red = 1.0, green = 0.5, blue = 1.0 },
        { red = 1.0, green = 0.5, blue = 0.5 },
        { red = 1.0, green = 0.5, blue = 0.0 },
        { red = 1.0, green = 0.0, blue = 1.0 },
        { red = 1.0, green = 0.0, blue = 0.5 },
        { red = 1.0, green = 0.0, blue = 0.0 },
        { red = 0.5, green = 1.0, blue = 1.0 },
        { red = 0.5, green = 1.0, blue = 0.5 },
        { red = 0.5, green = 1.0, blue = 0.0 },
        { red = 0.5, green = 0.5, blue = 1.0 },
        { red = 0.5, green = 0.5, blue = 0.5 },
        { red = 0.5, green = 0.5, blue = 0.0 },
        { red = 0.5, green = 0.0, blue = 1.0 },
        { red = 0.5, green = 0.0, blue = 0.5 },
        { red = 0.5, green = 0.0, blue = 0.0 },
        { red = 0.0, green = 1.0, blue = 1.0 },
        { red = 0.0, green = 1.0, blue = 0.5 },
        { red = 0.0, green = 1.0, blue = 0.0 },
        { red = 0.0, green = 0.5, blue = 1.0 },
        { red = 0.0, green = 0.5, blue = 0.5 },
        { red = 0.0, green = 0.5, blue = 0.0 },
        { red = 0.0, green = 0.0, blue = 1.0 },
        { red = 0.0, green = 0.0, blue = 0.5 },
        { red = 0.0, green = 0.0, blue = 0.0 },
    },
    showNames          = true,
    highlightJoined    = true,
    showNoiseLevels    = false,
    networkPersistence = 2,
}

local tableCopy -- assumes no looping, good enough for our purposes
tableCopy = function(inTable)
    local outTable = {}
    for k, v in pairs(inTable) do
        outTable[k] = (type(v) == "table") and tableCopy(v) or v
    end
    return outTable
end

local objectMT
objectMT = {
    __methodIndex = {},
    __internalData = setmetatable({}, { __mode = "k" }),
    __publicData   = setmetatable({}, { __mode = "k" }),

    __newindex = function(self, k, v)
        if variablesThatCauseUpdates[k] == nil then
            rawset(self, k, v)
        else
            objectMT.__publicData[self][k] = v
            if k == "frame" or k == "padding" then
                objectMT.__internalData[self].channelXoffsets = calculateXOffsets(self)
            end
            self:updateDrawings()
        end
    end,
    __pairs = function(self)
        local keys, k, v = {}, nil, nil
        repeat
            k, v = next(self, k)
            if k then keys[k] = true end
        until not k
        for k, v in pairs(objectMT.__publicData[self]) do
            keys[k] = true
        end
        return function(_, k)
                local v
                k, v = next(keys, k)
                if k then v = _[k] end
                return k, v
            end, self, nil
    end,
    __gc = function(self)
        self:delete()
    end,
}

objectMT.__index = function(_, k)
    if objectMT.__methodIndex[k] then return objectMT.__methodIndex[k] end
    if objectMT.__publicData[_][k] then return objectMT.__publicData[_][k] end
    for k2, v in pairs(objectMT.__publicData[_]) do
        if type(k2) ~= "function" then
            if k == "set" .. k2:sub(1,1):upper() .. k2:sub(2) then
                return function(self, v)
                    self[k2] = v
                    return self
                end
            end
        end
    end
    return nil
end


objectMT.__methodIndex.updateWifiData = function(self, latestScan)
    local iface = wifi.interfaceDetails()
    for k, v in pairs(objectMT.__internalData[self].seenNetworks) do
        v.lastSeen = v.lastSeen + 1
    end
    for i, v in ipairs(latestScan) do
        if v.wlanChannel.band == self.band then
            local label = v.bssid .. "_" .. v.ssid .. "-" .. tostring(v.wlanChannel.number)
            if objectMT.__internalData[self].seenNetworks[label] then
                objectMT.__internalData[self].seenNetworks[label].signal   = v.rssi
                objectMT.__internalData[self].seenNetworks[label].noise    = v.noise
                objectMT.__internalData[self].seenNetworks[label].lastSeen = 0
            else
                local colorNumber = objectMT.__internalData[self].colorNumberForLabels[label]
                if not colorNumber then
                    colorNumber = objectMT.__internalData[self].lastColorAssigned + 1
                    objectMT.__internalData[self].lastColorAssigned = colorNumber
                    objectMT.__internalData[self].colorNumberForLabels[label] = colorNumber
                end
                objectMT.__internalData[self].seenNetworks[label] = {
                    name        = v.ssid,
                    channel     = v.wlanChannel.number,
                    width       = tonumber(v.wlanChannel.width:match("^(%d+)MHz")),
                    signal      = v.rssi,
                    noise       = v.noise,
                    lastSeen    = 0,
                    colorNumber = colorNumber,
                }
            end
            if (iface.wlanChannel.band   == v.wlanChannel.band) and
               (iface.wlanChannel.number == v.wlanChannel.number) and
               (iface.wlanChannel.width  == v.wlanChannel.width) and
               (iface.bssid              == v.bssid) then
                  objectMT.__internalData[self].seenNetworks[label].joined = true
            end
        end
    end
    if type(self.networkPersistence) == "number" then
        for k, v in pairs(objectMT.__internalData[self].seenNetworks) do
            if v.lastSeen > self.networkPersistence then
                objectMT.__internalData[self].seenNetworks[k] = nil
            end
        end
    end
    self.lastScanTime = module.lastScanTime
    self:updateDrawings()
    return self
end

objectMT.__methodIndex.updateDrawings = function(self)
    local oldDrawings = self.drawings
    self.drawings = {}
    table.insert(self.drawings, table.remove(oldDrawings, 1))
    for i = 1, #self.channelList, 1 do
        table.insert(self.drawings, table.remove(oldDrawings, 1))
    end
    for i, v in ipairs(oldDrawings) do v:delete() end

    for i, v in ipairs(self.drawings) do
        if i == 1 then
            v:setFrame(self.frame)
        else
            local oldFrame = v:frame()
            local xOffset = objectMT.__internalData[self].channelXoffsets[tonumber(v:getStyledText():getString())]
--             print("xOffset: ", xOffset, " for: ", v:getStyledText():getString())
            v:setTopLeft{
                x = self.frame.x + self.padding + xOffset - oldFrame.w / 2,
                y = self.frame.y + self.frame.h - self.padding - oldFrame.h / 2,
            }
        end
    end
    local textLabel = styledtext.new("Last Updated: " .. os.date("%T %x", math.floor(self.lastScanTime or 0)), {
        font = {
                name = "Menlo-Italic",
                size = 10
            },
            color = { white = 1.0 },
        })

    local textLabelBox = drawing.getTextDrawingSize(textLabel)
    textLabelBox.w = textLabelBox.w + 4
    table.insert(self.drawings, drawing.text({
        x = self.frame.x + self.frame.w - textLabelBox.w,
        y = self.frame.y + self.frame.h - textLabelBox.h,
        h = textLabelBox.h,
        w = textLabelBox.w,
    }, textLabel))

    -- now draw arcs and labels (and noise?)
    for k, v in pairs(objectMT.__internalData[self].seenNetworks) do
        local bssid, ssid, channel = k:match("^([0-9a-fA-F:]+)_(.*)-(%d+)$")
        local strokeWidth = (v.lastSeen == 0) and 3 or 1
        local width = v.width * objectMT.__internalData[self].channelXoffsets["multiplier"]
        local color = self.colorList[1 + (v.colorNumber - 1) % #self.colorList]
        local signal = (120 + v.signal) * (self.frame.h - self.padding * 2) / 120
        table.insert(self.drawings, drawing.ellipticalArc({
                x = self.frame.x + self.padding + objectMT.__internalData[self].channelXoffsets[v.channel] - width / 2,
                y = self.frame.y + self.frame.h - (signal + self.padding * 2),
                h = signal * 2,
                w = width,
            }, -90, 90):setStrokeWidth(strokeWidth)
                       :setStrokeColor(color)
                       :setFill(v.joined)
                       :setStroke(true)
                       :clippingRectangle(self.frame)
                       :setFillColor{ white = 1.0, alpha = .2 }
        )
        if self.showNames then
            local labelString = styledtext.new(ssid, {
                font = {
                        name = "Menlo",
                        size = 10
                    },
                    color = color,
                })
            local labelBox = drawing.getTextDrawingSize(labelString)
            labelBox.w = labelBox.w + 4
            table.insert(self.drawings, drawing.text({
                x = self.frame.x + self.padding + objectMT.__internalData[self].channelXoffsets[v.channel] - labelBox.w / 2,
                y = self.frame.y + self.frame.h - (self.padding * 2 + (signal + labelBox.h) / 2),
                h = labelBox.h,
                w = labelBox.w,
            }, labelString):clippingRectangle(self.frame))
        end

    end

    if objectMT.__internalData[self].isVisible then
        self.drawings[1]:show()
        for i = 2, #self.drawings, 1 do
            self.drawings[i]:show():orderAbove(self.drawings[i - 1])
        end
    end

    return self
end

objectMT.__methodIndex.stop = function(self)
    self.isWatching = false
    return self
end

objectMT.__methodIndex.start = function(self)
    if not next(self.drawings) then
        table.insert(self.drawings,
              drawing.rectangle(self.frame):setRoundedRectRadii(10, 10)
                                           :setAlpha(self.frameAlpha)
                                           :setFill(true)
                                           :setStroke(true)
                                           :setStrokeWidth(5)
                                           :setFillColor{   white = 0.25 }
                                           :setStrokeColor{ white = 0.10 }
        )

        objectMT.__internalData[self].channelXoffsets = calculateXOffsets(self)

        for k, v in fnutils.sortByKeyValues(objectMT.__internalData[self].channelXoffsets) do
            if type(k) ~= "string" then
                local channelLabel = styledtext.new(tostring(k), {
                    font = {
                        name = "Menlo",
                        size = 10
                    },
                    color = { white = 1.0 },
                })
                local size = drawing.getTextDrawingSize(channelLabel)
                size.w = size.w + 4
                table.insert(self.drawings, drawing.text({
                    x = self.frame.x + self.padding + v - size.w / 2,
                    y = self.frame.y + self.frame.h - self.padding - size.h / 2,
                    h = size.h,
                    w = size.w,
                }, channelLabel))
            end
        end
    end
    self.isWatching = true
    return self
end

objectMT.__methodIndex.show = function(self)
    for i, v in ipairs(self.drawings) do v:show() end
    objectMT.__internalData[self].isVisible = true
    return self
end

objectMT.__methodIndex.hide = function(self)
    for i, v in ipairs(self.drawings) do v:hide() end
    objectMT.__internalData[self].isVisible = nil
    return self
end

objectMT.__methodIndex.delete = function(self)
    local index = 0
    for i, v in ipairs(observers) do
        if self == v then
            index = i
            break
        end
    end
    if index ~= 0 then
        table.remove(observers, index)
    end
    self.isWatching = false
    for i, v in ipairs(self.drawings) do v:delete() end
    self.drawings = {}
    if objectMT.__internalData[self] then
       objectMT.__internalData[self].channelXoffsets = {}
       objectMT.__internalData[self].seenNetworks = {}
    end
    return nil
end

module.new = function(band, channelList)
    assert(module.wifiFrequencies[band], tostring(band).." is not a recognized wifi band")
    if not channelList or not next(channelList) then
        channelList = {}
        local supportedChannels = wifi.interfaceDetails().supportedChannels
        if not supportedChannels then
            wifi.availableNetworks() -- blocking, so only do if necessary
            supportedChannels = wifi.interfaceDetails().supportedChannels
        end
        local seenChannels = {}
        for k, v in ipairs(supportedChannels) do
            if v.band == band and not seenChannels[v.number] then
                table.insert(channelList, v.number)
                seenChannels[v.number] = true
            end
        end
    end
    assert(type(channelList) == "table", "channelList must be a table of integer channel numbers")
    for i, v in ipairs(channelList) do
        assert(module.wifiFrequencies[band][v], "Frequency for channel "..tostring(v).." not found in the "..band.." band")
    end

    local object = setmetatable({
        channelList = channelList,
        band        = band,
        isWatching  = false,
        drawings    = {},
    }, objectMT)

    objectMT.__internalData[object] = {
        channelXoffsets      = {},
        seenNetworks         = {},
        lastColorAssigned    = 0,
        colorNumberForLabels = {},
    }

    objectMT.__publicData[object] = tableCopy(variablesThatCauseUpdates)

    table.insert(observers, object)

    return object
end

module.startObserving = function()
    assert(not module.backgroundScanner, "Scanning already in progress")
    module.backgroundScanner = wifi.backgroundScan(notifyObservers)
end

module.stopObserving = function()
    assert(module.backgroundScanner, "No scanning in progress")
    -- we can't send the backgroundScanner a stop message, but this being nil will keep notifyObservers from respawning another scan
    module.backgroundScanner = nil
end

module.delayTimer = 2

return module
