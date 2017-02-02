-- Time Machine widget
--
-- Patterned in large part after Übersicht Widget
--    https://github.com/ttscoff/ubersicht-widgets/tree/master/timemachine
--
-- Not sure how to replicate the shadow effect... its more pronounced then I seem to be
-- able to replicate with hs.canvas for lines that thin
--
-- added distributednotification watcher so tmutil isn't invoked every 5 seconds except
-- when we know an actual backup is occuring
--
-- And I added a percentage readout and tweaked the animation some...
--
-- this requires some tweaks to canvas that haven't made it into core yet... check the pulls or
-- my hammerspoon configuration repo for utils/canvasTweaks.lua

local canvas   = require "utils.canvasTweaks"
--local canvas   = require "hs.canvas"

-- I have a timestamp function globally defined, but in a pinch, this will do something similar:
if not timestamp then
    timestamp = function(date)
        date = date or timer.secondsSinceEpoch()
        return os.date("%F %T" .. string.format("%-5s", ((tostring(date):match("(%.%d+)$")) or "")), math.floor(date))
    end
end

local settings = require "hs.settings"
local timer    = require "hs.timer"
local screen   = require "hs.screen"
local distnot  = require "hs.distributednotifications"

local stext    = require("hs.styledtext").new

local USERDATA_TAG = "timemachine.widget"

local module = {}
module.timers = {}
module._currentState = "idle"

local screenFrame = screen.primaryScreen():fullFrame()
local defaults = {
    widgetFrame = {
        x = screenFrame.x + screenFrame.w - 110,
        y = screenFrame.y + screenFrame.h - 130,
        h = 105,
        w = 105,
    },
    widgetLevel        = "mainMenu",
    interval           = 5,
    autoStart          = true,
    textStyle     = {
        font           = { name = "Menlo-Italic", size = 10 },
        color          = { blue = .75, green = .75, alpha = .75 },
        paragraphStyle = {
            alignment = "center",
            lineBreak = "clip",
        }
    },

    ringAnimationCycle = 3,
    ringPulseDelta     = 10,

    idleColor          = { red = 1, green = 1, blue = 1, alpha = .2 },
    activeBGColor      = { red = 0x14/255, green = 0x1f/255, blue = 0x33/255, alpha = .5 },
    progressColor      = { red = 1, green = 1, blue = 1, alpha = .1 },
    preppingRingColor  = { red = 0xc3/255, green = 0x3b/255, blue = 0x3b/255, alpha = .5 },
    startingRingColor  = { red = 0xce/255, green = 0x9a/255, blue = 0x54/255, alpha = .5 },
    runningRingColor   = { red = 96/255, green = 210/255, blue = 255/255, alpha = .5 },
    finishingRingColor = { red = 96/255, green = 255/255, blue = 137/255, alpha = .5 },
}

local command = "/usr/bin/tmutil status"

local widgetFrame        = settings.get(USERDATA_TAG .. ".frame")              or defaults.widgetFrame
local widgetLevel        = settings.get(USERDATA_TAG .. ".level")              or defaults.widgetLevel
local interval           = settings.get(USERDATA_TAG .. ".interval")           or defaults.interval
local textStyle          = settings.get(USERDATA_TAG .. ".textStyle")          or defaults.textStyle

local ringAnimationCycle = settings.get(USERDATA_TAG .. ".ringAnimationCycle") or defaults.ringAnimationCycle
local ringPulseDelta     = settings.get(USERDATA_TAG .. ".ringPulseDelta")     or defaults.ringPulseDelta

module.colors = {}
for k,v in pairs(defaults) do
    if k:match("Color$") then
        module.colors[k] = settings.get(USERDATA_TAG .. "." .. k) or v
    end
end

-- because false is a valid value, we can't use the above shortcuts
local autoStart     = settings.get(USERDATA_TAG .. ".autoStart")
if autoStart == nil then autoStart = defaults.autoStart end

local dial = canvas.new(widgetFrame):level(widgetLevel):behavior("canJoinAllSpaces")

local setDialElements = function()
    -- outer ring
    dial[1] = {
        id          = "ring",
        type        = "circle",
        action      = "stroke",
        strokeColor = module.colors.idleColor,
        strokeWidth = .7,
        padding     = 2,
        shadow      = {
            blurRadius = 4.5,
            color      = module.colors.idleColor,
            offset     = { h = 0, w = 0 },
        },
        withShadow  = true,
    }
    -- clip so background and progress leave hole in center
    dial[2] = {
        type   = "rectangle",
        action = "build",
    }
    dial[3] = {
        id          = "progressClip",
        type        = "circle",
        action      = "clip",
        absolutePosition = false ;
        radius      = .2 * widgetFrame.w,
        reversePath = true,
    }
    -- background circle
    dial[4] = {
        id          = "background",
        type        = "circle",
        action      = "fill",
        absolutePosition = false ;
        radius      = .4 * widgetFrame.w,
        fillColor   = module.colors.idleColor,
    }
    -- progress circle
    dial[5] = {
        id          = "progress",
        type        = "arc",
        action      = "skip",       -- starts out hidden
        absolutePosition = false ;
        radius      = .4 * widgetFrame.w,
--        fillColor   = module.colors.progressColor,
        fillColor   = module.colors.activeBGColor
    }
    -- clear center hole clip region
    dial[6] = {
        type = "resetClip"
    }
    -- text box for readout
    dial[7] = {
        id     = "text",
        type   = "text",
        action = "skip",            -- starts out hidden
        absolutePosition = false ;
        radius      = .4 * widgetFrame.w,
        frame  = {
            x = .3 * widgetFrame.w,
            y = .3 * widgetFrame.h,
            h = .4 * widgetFrame.h,
            w = .4 * widgetFrame.w
        },
        text   = stext(" ", textStyle), -- need a space placeholder so we can hold an active style even when we're not printing a value; using "" would lose the style info because it has an internal (0,0) range
    }
end

setDialElements()

local angle = 90

local spinWedge = function()
    return function()
        dial.progress.startAngle = angle
        angle = (angle + 10) % 360
        dial.progress.endAngle   = angle
    end
end

local animateRing = function()
    dial.ring.shadow.color       = dial.ring.strokeColor
    dial.ring.shadow.color.alpha = 1.0
    dial.ring.withShadow         = true

    local startAlpha = 1
    local endAlpha   = .2
    local delta      = (startAlpha - endAlpha) / ((ringAnimationCycle / 2) / .1)

    local current = startAlpha
    return function()
        current = current - delta
        if current < endAlpha   then current, delta = endAlpha, -delta end
        if current > startAlpha then current, delta = startAlpha, -delta end
        dial.ring.strokeColor.alpha  = current
    end
end

local pulseRing = function()
    local frame = dial:frame()

    local current, delta = 0, 1
    return function()
        current = current + delta
        if current < 0              then current, delta = 0, -delta end
        if current > ringPulseDelta then current, delta = ringPulseDelta, -delta end
        dial:frame{
            x = frame.x - current,
            y = frame.y - current,
            h = frame.h + math.abs(current) * 2,
            w = frame.w + math.abs(current) * 2,
        }
    end
end

local setDial
setDial = function(state)
    local stateChanged = state ~= module._currentState
    if stateChanged then
--        print(timestamp() .. ":" .. USERDATA_TAG .. ": state change from " .. module._currentState .. " to " .. state)
        for k, v in pairs(module.timers) do v:stop() end
        module.timers = {}
        -- reset dial to stable known state
        dial:frame(widgetFrame)
        dial.background.action, dial.progress.action, dial.text.action = "fill", "skip", "skip"
        dial.ring.withShadow = false
    end
    if     state == "idle" then
        dial.ring.strokeColor     = module.colors.idleColor
        dial.ring.shadow.color    = module.colors.idleColor
        dial.background.fillColor = module.colors.idleColor
    elseif state == "prepping" then
        dial.background.action, dial.progress.action = "skip", "fill"
        dial.ring.strokeColor = module.colors.startingRingColor
        if stateChanged then
--            module.timers.dialTimer  = timer.doEvery(.1, animateRing())
            module.timers.pulseTimer = timer.doEvery(.1, pulseRing())
            -- we set it here so it always starts at the same place; prepping and finishing will continue
            -- where this leaves off
            angle = 90
            module.timers.spinTimer = timer.doEvery(.1, spinWedge())
        end
    elseif state == "starting" then
        dial.ring.strokeColor = module.colors.preppingRingColor
        dial.background.action, dial.progress.action = "skip", "fill"
        if stateChanged then
--            module.timers.dialTimer = timer.doEvery(.1, animateRing())
            module.timers.pulseTimer = timer.doEvery(.1, pulseRing())
            module.timers.spinTimer = timer.doEvery(.1, spinWedge())
        end
    elseif state == "running" then
        dial.ring.strokeColor = module.colors.runningRingColor
--        dial.background.fillColor = module.colors.activeBGColor
        dial.progress.action = "fill"
        dial.text.action = "stroke"
        if stateChanged then
            module.timers.dialTimer = timer.doEvery(.1, animateRing())
        end
    elseif state == "finishing" then
        dial.ring.strokeColor = module.colors.finishingRingColor
        dial.background.action, dial.progress.action = "skip", "fill"
        if stateChanged then
            module.timers.dialTimer = timer.doEvery(.1, animateRing())
            module.timers.spinTimer = timer.doEvery(.1, spinWedge())
        end
    else
        print(timestamp() .. ":" .. USERDATA_TAG .. ": invalid state: " .. tostring(state))
        setDial("idle")
    end
    module._currentState = state
end

local secsToTime = function(secs)
    local h = math.floor(secs / 360)
    local m = math.floor((secs - h * 360) / 60)
    local s = secs - h * 360 - m * 60
    local result = ""
    if h > 0 then result = result .. tostring(h) .. ":" .. (m < 10 and "0" or "") end
    result = result .. tostring(m) .. ":" .. (s < 10 and "0" or "") .. tostring(s)
    return result
end

local invokeTMUtil = function()
    local isRunning = false
    local o, s, t, r = hs.execute("/usr/bin/tmutil status")
    if s then
        isRunning = o:match("Running = 1;") and true or false
        local backup_phase = o:match("BackupPhase = ([^;]*);")
        if isRunning then
            if backup_phase == "Copying" then
                setDial("running")
                local rpercent = o:match([[%s+"_raw_Percent" = "?(%d?%.?%d*)"?;]])
--                local percent  = o:match([[%s+Percent = "?(%d?%.?%d*)"?;]])
                local timeLeft = o:match([[%s+TimeRemaining = (%d?%.?%d*);]])
                dial.progress.startAngle = 90
                if not rpercent then
                    rpercent = "0"
                    print(timestamp() .. ":" .. USERDATA_TAG .. ": bad percentage value: " .. " -> " .. o)
                end
                if tonumber(rpercent) == 100 then
                    dial.progress.endAngle = 360
                else
                    dial.progress.endAngle = (90 + (360 * tonumber(rpercent))) % 360
                end
                local text = (rpercent and tostring(math.floor(10000 * tonumber(rpercent) + .5) / 100) .. "%" or "???")
                text = text .. "\n" .. (timeLeft and secsToTime(tonumber(timeLeft)) or "???")
                text = stext("\n", { font = { name = textStyle.font.name, size = textStyle.font.size / 2 } }) .. stext(text, textStyle)
                dial.text.text = text
            elseif backup_phase == "Starting" or backup_phase == "ThinningPreBackup" then
                setDial("starting")
            elseif backup_phase == "MountingBackupVol" then
                setDial("prepping")
            elseif backup_phase == "Finishing" or backup_phase == "ThinningPostBackup" then
                setDial("finishing")
            else
                print(timestamp() .. ":" .. USERDATA_TAG .. ": unhandled phase: " .. tostring(backup_phase) .. " -> " .. o)
                setDial("idle")
            end
        else
            setDial("idle")
        end
    end
    return isRunning
end

local checkAndStartIfNeeded = function ()
    if not module.tmutilTimer then
        local state = invokeTMUtil()
        if state then -- update display and start timer if we're in the middle of a backup
            module.tmutilTimer = timer.doEvery(interval, function()
                local state = invokeTMUtil()
                if not state then
                    module.tmutilTimer:stop()
                    module.tmutilTimer = nil
                end
            end)
        end
        return state
    end
    return false
end

local startWatcher = function()
    if not module._watcher then
        module._watcher = distnot.new(function(n, o, i)
            checkAndStartIfNeeded()
--        end, "com.apple.backupd.DestinationMountNotification"):start()
       end, "com.apple.backup.DiscoverHookClientsNotification", "com.apple.backup.BackupObject"):start()

    end
    checkAndStartIfNeeded() -- update display and start timer if we're in the middle of a backup
    return module._watcher
end

-- distributed notifications are not guaranteed to be delivered if the system is busy, so let's
-- check every so often... still better then the every 5 seconds that the original widget did even when
-- no backup was occurring...
module._longWatcher = timer.doEvery(60, function()
    if checkAndStartIfNeeded() then
        print(timestamp() .. ":" .. USERDATA_TAG .. ": missed notification, but backup timer caught it at " .. module._currentState)
    end
end)

local stopWatcher = function()
    setDial("idle")
    if module._watcher then module._watcher:stop() end
    if module.tmutilTimer then module.tmutilTimer:stop() ; module.tmutilTimer = nil end
    for k,v in pairs(module.timers) do v:stop() end
    module.timers = {}
    return nil
end

module.dial = dial

module.setDial = setDial

module.frame = function(frame)
    local currentFrame, changeMade = dial:frame(), false
    if type(frame) == "table" then
        if type(frame.x) == "number" then currentFrame.x, changeMade = frame.x, true end
        if type(frame.y) == "number" then currentFrame.y, changeMade = frame.y, true end
        if type(frame.h) == "number" then currentFrame.h, changeMade = frame.h, true end
        if type(frame.w) == "number" then currentFrame.w, changeMade = frame.w, true end
    elseif type(frame) == "boolean" and not frame then
        currentFrame, changeMade = defaults.widgetFrame, true
    end
    if changeMade then
        dial:frame(currentFrame)
        settings.set(USERDATA_TAG .. ".frame", (frame and currentFrame or nil))
        setDialElements()
        setDial(module._currentState)
    elseif frame ~= nil then
        error("frame must be false (to reset) or a table with one or more of the following keys: x, y, w, h", 2)
    end
    return dial:frame()
end

module.level = function(level)
    local levelChanged = false
    if level ~= nil or (type(level) == "boolean" and not level) then
        levelChanged = true
    end
    if levelChanged then
        dial:level(level or defaults.widgetLevel)
        widgetLevel = canvas.windowLevels[dial:level()] or dial:level() -- get text label if we can
        settings.set(USERDATA_TAG .. ".level", (level and widgetLevel or nil))
        setDial(module._currentState)
    end
    return widgetLevel
end

module.interval = function(secs)
    local intervalChanged = false
    if type(secs) == "number" or (type(secs) == "boolean" and not secs) then
        intervalChanged = true
    elseif secs ~= nil then
        error("interval must be false (to reset) or a number", 2)
    end
    if intervalChanged then
        interval = secs or defaults.interval
        if module._watcher then
            module._watcher = stopWatcher()
            module._watcher = startWatcher()
        end
        settings.set(USERDATA_TAG .. ".interval", secs or nil)
        setDial(module._currentState)
    end
    return interval
end

module.autoStart = function(state)
    if type(state) == "boolean" then
        if state ~= defaults.autoStart then
            settings.set(USERDATA_TAG .. ".autoStart", state)
        else
            settings.set(USERDATA_TAG .. ".autoStart", nil)
        end
    elseif type(state) ~= "nil" then
        error("autoStart must be a boolean", 2)
    end
    autoStart = settings.get(USERDATA_TAG .. ".autoStart")
    if autoStart == nil then autoStart = defaults.autoStart end
    return autoStart
end

module.textStyle = function(style)
    local currentStyle, changeMade = dial.text.text:asTable()[2].attributes, false
    if type(style) == "table" and type(style.font) == "table" and style.font.name and style.font.size then
        currentStyle, changeMade = style, true
    elseif type(style) == "boolean" and not style then
        currentStyle, changeMade = defaults.textStyle, true
    end
    if changeMade then
        dial.text.text:setStyle(currentStyle, 1, #dial.text, true)
        settings.set(USERDATA_TAG .. ".textStyle", (style and currentStyle or nil))
        setDial(module._currentState)
    elseif style ~= nil then
        error("style must be false (to reset) or a table as defined in hs.styled text with at least a font sub-table specified", 2)
    end
    return dial.text.text:asTable()[2].attributes
end

for k,v in pairs(defaults) do
    if k:match("Color$") then
        module[k] = function(color)
            local colorChanged = false
            if type(color) == "table" or (type(color) == "boolean" and not color) then
                colorChanged = true
            elseif type(color) ~= nil then
                error("color must be false (to reset) or a color table as defined in hs.drawing.color", 2)
            end
            if colorChanged then
                module.colors[k] = color or defaults[k]
-- how to force refresh since they differ depending?
                settings.set(USERDATA_TAG .. "." .. k, color or nil)
                setDial(module._currentState)
            end
            return module.colors[k]
        end
    end
end

module.show = function()
    dial:show()
    if not module._watcher then module._watcher = startWatcher() end
end

module.hide = function()
    dial:hide()
    if module._watcher then module._watcher = stopWatcher() end
end

module.toggle = function()
    if dial:isShowing() then module.hide() else module.show() end
end

if autoStart then module.show() end

return module
