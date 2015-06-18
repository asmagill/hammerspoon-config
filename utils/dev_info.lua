local module = {
--[=[
    _NAME        = '',
    _VERSION     = '',
    _URL         = 'https://github.com/asmagill/hydra_config',
    _DESCRIPTION = [[]],
    _TODO        = [[]],
    _LICENSE     = [[ See README.md ]]
--]=]
}

-- private variables and methods -----------------------------------------

local window        = require("hs.window")
local application   = require("hs.application")
local screen        = require("hs.screen")
local battery       = require("hs.battery")
local mouse         = require("hs.mouse")
local audiodevice   = require("hs.audiodevice")
local brightness    = require("hs.brightness")

local clipboard     = require("hs.pasteboard")

local clipBufferIfRequested = function(buf, clip)
    buf = string.gsub(buf, "\n", " ")
    if clip then clipboard.setContents(buf) end
    return buf
end

-- Public interface ------------------------------------------------------

module.wininfo = function(win,clip)
    clip = clip or false
    if not win then return end
    local buf = ""
    buf = buf.."name = "..tostring(win:title()).."\r"
    buf = buf.."id = "..tostring(win:id()).."\r"
    buf = buf.."pid = "..tostring(win:pid()).."\r"
    buf = buf.."frame = "..tostring(inspect(win:frame())).."\r"
    buf = buf.."role = "..tostring(win:role()).."\r"
    buf = buf.."subrole = "..tostring(win:subrole()).."\r"
    buf = buf.."isStandard = "..tostring(win:isStandard()).."\r"
    buf = buf.."isFullScreen = "..tostring(win:isFullScreen()).."\r"
    buf = buf.."isVisible = "..tostring(win:isVisible()).."\r"
    buf = buf.."isMinimized = "..tostring(win:isMinimized()).."\r"
    buf = buf.."isFocused = "
    local fwin = window.focusedWindow()
    if fwin == win then
        buf = buf.."true\r"
    else
        buf = buf.."false\r"
    end
    return clipBufferIfRequested(buf, clip)
end

module.appinfo = function(app,clip)
    clip = clip or false
    if not app then return end
    local buf = ""
    buf = buf.."name = "..tostring(app:title()).."\r"
    buf = buf.."bundleID = "..tostring(app:bundleID()).."\r"
    buf = buf.."pid = "..tostring(app:pid()).."\r"
    buf = buf.."kind = "..tostring(app:kind()).."\r"
    buf = buf.."isUnresponsive = "..tostring(app:isUnresponsive()).."\r"
    buf = buf.."isHidden = "..tostring(app:isHidden()).."\r"
    buf = buf.."totalWindows = "..tostring(#app:allWindows()).."\r"
    buf = buf.."visibleWindows = "..tostring(#app:visibleWindows()).."\r"
    return clipBufferIfRequested(buf, clip)
end

module.screeninfo = function(screen,clip)
    clip = clip or false
    if not screen then return end
    local buf = ""
    buf = buf.."name = "..tostring(screen:name()).."\r"
    buf = buf.."id = "..tostring(screen:id()).."\r"
    buf = buf.."_frame = "..tostring(inspect(screen:_frame())).."\r"
    buf = buf.."_visibleframe = "..tostring(inspect(screen:_visibleframe())).."\r"
    buf = buf.."frame = "..tostring(inspect(screen:frame(screen))).."\r"
    buf = buf.."fullFrame = "..tostring(inspect(screen:fullFrame())).."\r"
    return clipBufferIfRequested(buf, clip)
end

--module.spaceinfo = function(clip)
--    clip = clip or false
--    local buf = ""
--    buf = buf.."currentSpace = "..tostring(spaces.currentSpace()).."\r"
--    buf = buf.."count = "..tostring(spaces.count()).."\r"
--    return clipBufferIfRequested(buf, clip)
--end

module.batteryinfo = function(clip)
    clip = clip or false
    local buf = ""
    for i,v in pairs(battery.getAll()) do
        buf = buf..i.." = "..tostring(v).."\r"
    end
    return clipBufferIfRequested(buf, clip)
end

module.mouseinfo = function(clip)
    clip = clip or false
    local buf = ""
    buf = buf.."mouse = "..tostring(inspect(mouse.get())).."\r"
    return clipBufferIfRequested(buf, clip)
end

module.audioinfo = function(clip)
    clip = clip or false
    local buf = ""
    for i,v in pairs(audiodevice.current()) do
        if i ~= "device" then buf = buf..i.." = "..tostring(v).."\r" end
    end
    return clipBufferIfRequested(buf, clip)
end

module.brightnessinfo = function(clip)
    clip = clip or false
    local buf = ""
    buf = buf.."brightness = "..tostring(brightness.get()).."\r"
    return clipBufferIfRequested(buf, clip)
end

-- Return Module Object --------------------------------------------------

return module
