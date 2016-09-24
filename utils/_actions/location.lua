local module   = {}
local settings = require("hs.settings")

local location = require("hs._asm.location")

module.manager = location.manager():callbackFunction(function(self, message, ...)
    print(string.format("~~ %s:%s", os.date(), message))
    if message == "didEnterRegion" or message == "didExitRegion" then
        print(string.format("~~ %s", inspect(table.pack(...))))
    end
end)

-- _asm.monitoredLocations should be an array of the format:
-- {
--     {
--         identifier = "Home",  -- an arbitrary label of our own choosing
--         latitude = xx.xx,
--         longitude =  yy.yy,
--         radius = 50,          -- in meters
--         notifyOnEntry = true, -- if you want a callback when we enter the region
--         notifyOnExit = true   -- if you want a callback when we leave the region
--     }, {
--         identifier = "Library",
--         latitude = xx.xx,
--         longitude = yy.yy,
--         radius = 50,
--         notifyOnEntry = true,
--         notifyOnExit = true
--     }, etc.
-- }

local regions = settings.get("_asm.monitoredLocations") or {}
if #regions == 0 then
    print("~~ No regions specified in _asm.monitoredLocations, use hs.settings.set to specify them") ;
end

for i,v in ipairs(regions) do
    module.manager:addMonitoredRegion(v)
end

return module
