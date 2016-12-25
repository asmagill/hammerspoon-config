local module = {}

local eventtap = require("hs.eventtap")
local timer    = require("hs.timer")

local timestamp = function(date)
    date = date or timer.secondsSinceEpoch()
    return os.date("%F %T" .. string.format("%-5s", ((tostring(date):match("(%.%d+)$")) or "")), math.floor(date))
end

local tobits = function(num, bits)
    bits = bits or (math.floor(math.log(num,2) / 8) + 1) * 8
    if bits == -(1/0) then bits = 8 end
    local value = ""
    for i = (bits - 1), 0, -1 do
        value = value..tostring((num >> i) & 0x1)
    end
    return value
end

module.log = {}
module.eventsSeen = 0

module.et = eventtap.new({"all"}, function(e)
    module.eventsSeen = module.eventsSeen + 1
    local ud = e:getProperty(eventtap.event.properties.eventSourceUserData)
    if ud ~= 0 then
        table.insert(module.log, {
            timestamp = timestamp(),
            event     = eventtap.event.types[e:getType()] or ("?? " .. tostring(e:getType()) .. " ??"),
            userdata  = ud,
        })
    end
end):start()

module.report = function()
    print(string.format("Total events seen: %d; events with anomolous userdata: %d", module.eventsSeen, #module.log))
    for i, v in ipairs(module.log) do
        print(string.format("%s %23s %s %d", v.timestamp, v.event, tobits(v.userdata, 64), v.userdata))
    end
end

return module
