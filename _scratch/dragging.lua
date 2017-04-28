local module = {}
local canvas     = require "hs.canvas"
local pasteboard = require "hs.pasteboard"
local screen     = require "hs.screen"
local image      = require "hs.image"
local inspect    = require "hs.inspect"
local timer      = require "hs.timer"
local console    = require "hs.console"
local canvas     = require "hs.canvas"

local screenFrame = screen.primaryScreen():fullFrame()

local timestamp = function(date)
    date = date or timer.secondsSinceEpoch()
    return os.date("%F %T" .. string.format("%-5s", ((tostring(date):match("(%.%d+)$")) or "")), math.floor(date))
end

local receiver = canvas.new{
    x = screenFrame.x + screenFrame.w - 100,
    y = screenFrame.y + (screenFrame.h - 100) / 2,
    h = 100,
    w = 100,
}:behavior("canJoinAllSpaces"):level("dragging"):mouseCallback(function() end):show()
module.receiver = receiver

receiver[#receiver + 1] = {
    id = "background",
    type = "rectangle",
    roundedRectRadii = { xRadius = 5, yRadius = 5 },
    action = "fill",
    fillColor = { white = 0.3, alpha = .5 },
}
receiver[#receiver + 1] = {
    id = "icon",
    type = "image",
    image = image.imageFromName("NSFolder"),
    frame = { x = "25%", y = "25%", h = "50%", w = "50%" },
}
receiver[#receiver + 1] = {
    id = "waiting1",
    action = "skip",
    type = "image",
    image = image.imageFromName("NSExitFullScreenTemplate"),
    frame = { x = "10%", y = "10%", h = "80%", w = "80%" },
}
receiver[#receiver + 1] = {
    id = "waiting2",
    action = "skip",
    type = "image",
    image = image.imageFromName("NSExitFullScreenTemplate"),
    frame = { x = "10%", y = "10%", h = "80%", w = "80%" },
    transformation = canvas.matrix.translate(50, 50):rotate(90):translate(-50, -50),
}

receiver:draggingCallback(function(cv, msg, details)
    hs.printf("%s:%s - %s", timestamp(), msg, (inspect(details):gsub("%s+", " ")))

-- the drag entered our view frame
    if msg == "enter" then
        cv.waiting1.action = "fill"
        cv.waiting2.action = "fill"
        -- could inspect details and reject with `return false`
        -- but we're going with the default of true

-- the drag exited our view domain without a release (or we returned false for "enter")
    elseif msg == "exit" or msg == "exited" then
        -- return type ignored
        cv.waiting1.action = "skip"
        cv.waiting2.action = "skip"

-- the drag finished -- it was released on us!
    elseif msg == "receive" then
        cv.waiting1.action = "skip"
        cv.waiting2.action = "skip"

        local name = details.pasteboard
        local types = pasteboard.typesAvailable(name)
        hs.printf("\n\t%s\n%s\n%s\n", name, (inspect(types):gsub("%s+", " ")), inspect(pasteboard.allContentTypes()))

        if types.string then
            local stuffs = pasteboard.readString(name, true) or {} -- sometimes they lie
            hs.printf("strings: %d", #stuffs)
            for i, v in ipairs(stuffs) do
                print(i, v)
            end
        end

        if types.styledText then
            local stuffs = pasteboard.readStyledText(name, true) or {} -- sometimes they lie
            hs.printf("styledText: %d", #stuffs)
            for i, v in ipairs(stuffs) do
                console.printStyledtext(i, v)
            end
        end

        if types.URL then
            local stuffs = pasteboard.readURL(name, true) or {} -- sometimes they lie
            hs.printf("URL: %d", #stuffs)
            for i, v in ipairs(stuffs) do
                print(i, (inspect(v):gsub("%s+", " ")))
            end
        end

        -- try dragging an image from Safari
        if types.image then
            local stuffs = pasteboard.readImage(name, true) or {} -- sometimes they lie
            hs.printf("image: %d", #stuffs)
            module.imageHolder = {}
            for i, v in ipairs(stuffs) do
                local holder = canvas.new{ x = 100 * i, y = 100, h = 100, w = 100 }:show()
                holder[#holder + 1] = {
                    type = "image",
                    image = v,
                }
                table.insert(module.imageHolder, holder)
            end
            module.clear = timer.doAfter(5, function()
                for k,v in ipairs(module.imageHolder) do
                    v:delete()
                end
                module.clear = nil
            end)
        end

        print("")
        -- could inspect details and reject with `return false`
        -- but we're going with the default of true
    end
end)

return module
