tb = require("hs._asm.undocumented.touchbar")

c = hs.canvas.new{x = 0, y = 0, h = 90, w = 90}:canvasMouseEvents(true,true,true,true)
                                               :mouseCallback(function(o,m,i,x,y) print(timestamp(),m,i,x,y) end)
c[#c + 1] = {
    type = "circle",
    radius = tostring(1/3),
    center = { x =tostring(1/2), y = tostring(2/3 - math.sin(math.rad(60)) * 1/3) },
    fillColor = { red = 1, alpha = .5 },
}
c[#c + 1] = {
    type = "circle",
    radius = tostring(1/3),
    center = { x = tostring(1/3), y = tostring(2/3) },
    fillColor = { green = 1, alpha = .5 },
}
c[#c + 1] = {
    type = "circle",
    radius = tostring(1/3),
    center = { x = tostring(2/3), y = tostring(2/3) },
    fillColor = { blue = 1, alpha = .5 },
}

idle = hs.canvas.new{h = 100, w = 100}
idle[#idle + 1] = {
    type = "rectangle",
    action = "fill",
    fillColor = { green = 1 },
    frame = { x = "0%", y = "0%", h = "100%", w = "33%" },
    id = "idle",
}
idle[#idle + 1] = {
    type = "rectangle",
    action = "fill",
    fillColor = { red = 1 },
    frame = { x = "33%", y = "0%", h = "100%", w = "33%" },
    id = "user",
}
idle[#idle + 1] = {
    type = "rectangle",
    action = "fill",
    fillColor = { green = 1, red = 1 },
    frame = { x = "66%", y = "0%", h = "100%", w = "33%" },
    id = "system",
}
idle[#idle + 1] = {
    type = "rectangle",
    action = "stroke",
    strokeColor = { white = 1 },
}

local state = true
idleCallback = function(o)
    state = not state
    if state then
        idle:transformation(nil)
    else
        local w = o:canvasWidth() / 2
        local h = 15 -- we know that the touchbar gives us a hight of 30 to work with, since we need half for rotation, use 15 here
        idle:transformation(hs.canvas.matrix.translate(w, h):rotate(90):translate(-w, -h))
    end
end

idleTimer = hs.timer.doEvery(1, function()
    local cpu = hs.host.cpuUsage().overall
    idle["idle"].frame.y,   idle["idle"].frame.h   = tostring(100 - cpu.idle) .. "%", tostring(cpu.idle) .. "%"
    idle["user"].frame.y,   idle["user"].frame.h   = tostring(100 - cpu.user) .. "%", tostring(cpu.user) .. "%"
    idle["system"].frame.y, idle["system"].frame.h = tostring(100 - cpu.system) .. "%", tostring(cpu.system) .. "%"
end)

callbackFN = function(o, ...) print(timestamp(), o:identifier(), finspect(table.pack(...))) end
sliderFN = function(o, v)
    callbackFN(o, v)
    if v == "minimum" then o:sliderValue(-100) ; v = o:sliderValue() end
    if v == "maximum" then o:sliderValue(100)  ; v = o:sliderValue() end
end
visibilityCallbackFN = function(o, state) print("touchbar goes " .. (state and "on" or "off")) end
b = tb.bar.new():visibilityCallback(visibilityCallbackFN)
i = {
-- minimizing (i.e. hitting the built in close button) a touchbar doesn't trigger visible change... maybe once they're attached to webviews, etc.
    tb.item.newButton(hs.image.imageFromName("NSStopProgressFreestandingTemplate"), "stop"):callback(function(o, ...) b:dismissModalBar() end),
    tb.item.newButton("text", "textButtonItem"):callback(callbackFN),
    tb.item.newCanvas(c, "canvasItem"), --:callback(callbackFN),
    tb.item.newGroup("groupItem"):groupItems{
        tb.item.newButton(hs.image.imageFromName("NSStatusAvailable"), "available"):callback(callbackFN),
        tb.item.newButton(hs.image.imageFromName("NSStatusPartiallyAvailable"), "partiallyAvailable"):callback(callbackFN),
        tb.item.newButton(hs.image.imageFromName("NSStatusUnavailable"), "unavailable"):callback(callbackFN),
    },
    tb.item.newCanvas(idle, "idle"):callback(idleCallback):canvasClickColor{ alpha = 0 },
    tb.item.newSlider("sliderItem"):callback(sliderFN) -- :sliderMin(-100):sliderMax(100):sliderValue(0)
                                   :sliderMinImage(hs.image.imageFromName("NSExitFullScreenTemplate"))
                                   :sliderMaxImage(hs.image.imageFromName("NSEnterFullScreenTemplate")),
}
b:templateItems(i):defaultIdentifiers(hs.fnutils.imap(i, function(o) return o:identifier() end))

b:presentModalBar(false)

-- for poking around at the objective-c objects more directly, not needed for the module or demonstrations
if package.searchpath("hs._asm.objc", package.path) then
    o = require("hs._asm.objc")
    j = hs.fnutils.imap(i, function(x) return o.object.fromLuaObject(x) end)
end
