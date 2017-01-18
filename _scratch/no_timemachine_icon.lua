a = hs.canvas.new{ x = 100, y = 100, h = 500, w = 500 }:show()
a[1] = {
    type = "image",
    image = hs.image.imageFromName("NSFolder")
}
a[2] = {
    type = "image",
    image = hs.image.imageFromPath("/System/Library/PreferencePanes/TimeMachine.prefPane/Contents/Resources/TimeMachine_128x128.png"),
    frame = { x = 100, y = 115, h = 300, w = 300 },
}
a[3] = {
    action = "stroke",
    closed = false,
    coordinates = {{ x = 125, y = 140 }, { x = 375, y = 390 }},
    strokeColor = { red = 1 },
    strokeWidth = 20,
    type = "segments"
}
a[4] = {
    action = "stroke",
    closed = false,
    coordinates = {{ x = 375, y = 140 }, { x = 125, y = 390 }},
    strokeColor = { red = 1 },
    strokeWidth = 20,
    type = "segments"
}
hs.pasteboard.writeObjects(a:imageFromCanvas())
