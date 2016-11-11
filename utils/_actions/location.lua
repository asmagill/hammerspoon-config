local module   = {}
local location = require("hs.location")
local settings = require("hs.settings")
local canvas   = require("hs._asm.canvas")
local screen   = require("hs.screen")
local stext    = require("hs.styledtext")

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

local label = canvas.new{}:behavior("canJoinAllSpaces"):level("popUpMenu"):show()
label[1] = {
    type             = "rectangle",
    action           = "strokeAndFill",
    strokeColor      = { red = .75, blue = .75, green = .75, alpha = .75 },
    fillColor        = { alpha = .75 },
    roundedRectRadii = { xRadius = 5, yRadius = 5 },
    clipToPath       = true,
}
label[2] = {
    type = "text",
}

local updateLabel = function(err)
    local sf   = screen.primaryScreen():fullFrame()
    local text = stext.new(err or module.labelWatcher:currentRegion() or "Unknown", {
        font = { name = "Menlo-Italic", size = 12, },
        color = ( err and { red = .75, blue = .75, green = .25, alpha = .75 } ) or
                (
                    module.labelWatcher:currentRegion() and
                        { red = .25, blue = .75, green = .75, alpha = .75 } or
                        { red = .75, blue = .25, green = .75, alpha = .75 }
                ),
        paragraphStyle = { alignment = "center", lineBreak = "clip" }
    })
    local textSz = label:minimumTextSize(2, text)
    label:frame{
        x = sf.x + sf.w - (100 + textSz.w),
        y = sf.y + sf.h - (4 + textSz.h),
        h = textSz.h + 3,
        w = textSz.w + 6,
    }
    label[2].frame = { x = 3, y = 0, h = textSz.h, w = textSz.w }
    label[2].text = text
end

local geocoderRequest = function()
    if module._geocoder then module._geocoder = module._geocoder:cancel() end
    module._geocoder = location.geocoder.lookupLocation(location.get(), function(state, result)
        module.addressInfo = result
        module._geocoder = nil
    end)
end

module.label = label
module.labelWatcher = location.new():callback(function(self, message, ...)
    if message:match("Region$") then updateLabel(table.pack(...)[2]) end -- will be nil unless error
    if message == "didEnterRegion" or message == "didExitRegion" then geocoderRequest() end
end)
for i,v in ipairs(regions) do module.labelWatcher:addMonitoredRegion(v) end
geocoderRequest()

-- secondary watcher for testing -- not a great example since the whole point of adding an object/method
-- interface to hs.location was to allow different code to monitor for different region changes, but as a
-- proof-of-concept, it'll do for now...

-- i have a date/time format for logging that I like, but others copying this may not
local timestamp = timestamp
if not timestamp then timestamp = os.date end

module.manager = location.new():callback(function(self, message, ...)
    print(string.format("~~ %s:%s\n   %s", timestamp(), message, (inspecta(table.pack(...)):gsub("%s+", " "))))
end)

-- just so they have at least some differences
local doit = true
for i,v in ipairs(regions) do
    if doit then
        module.manager:addMonitoredRegion(v)
    end
    doit = not doit
end

return module
