local module = {}

local menubar  = require("hs.menubar")
local timer    = require("hs.timer")
local canvas   = require("hs._asm.canvas")
local stext    = require("hs.styledtext")
local screen   = require("hs.screen")
local mouse    = require("hs.mouse")
local settings = require("hs.settings")
local eventtap = require("hs.eventtap")

local USERDATA_TAG = "calendarMenu"
local log  = require"hs.logger".new(USERDATA_TAG, settings.get(USERDATA_TAG .. ".logLevel") or "warning")
module.log = log

local visible = false

local cal = function(month, day, year, style, todayStyle)
    local highlightToday = day and true or false
    day = day or 1
    style = style or {
        font  = { name = "Menlo", size = 12 },
        color = { white = 0 },
    }
    todayStyle = todayStyle or { color = { red = 1 } }

    local dayLabels = { "Su", "Mo", "Tu", "We", "Th", "Fr", "Sa" }
    local monthLabels = {
        "January", "February", "March",     "April",   "May",      "June",
        "July",    "August",   "September", "October", "November", "December",
    }
    local date = os.date("*t", os.time({ year = year, month = month, day = day }))
    local monthStartsOn = os.date("*t", os.time({
        year  = date.year,
        month = date.month,
        day   = 1,
    })).wday - 1
    local daysInMonth = os.date("*t", os.time({
        year  = date.year + (date.month == 12 and 1 or 0),
        month = date.month == 12 and 1 or date.month + 1,
        day   = 1,
        hour  = 0, -- for some reason, lua defaults this to 12 if not set
    }) - 1).day

    local offSet = math.floor(10 - (string.len(monthLabels[date.month]) + 1 + string.len(tostring(date.year))) / 2)
    local result = string.rep(" ", offSet) .. monthLabels[date.month] .. " " .. tostring(date.year) .. "\n"
    result = result .. table.concat(dayLabels, " ") .. "\n"
    result = result .. string.rep("   ", monthStartsOn)

    local whereIsToday
    for day = 1, daysInMonth, 1 do
        if day == date.day then whereIsToday = #result end
        result = result .. string.format("%2d", day)
        monthStartsOn = (monthStartsOn + 1) % 7
        if day ~= daysInMonth then
            if monthStartsOn > 0 then
                result = result .. " "
            else
                result = result .. "\n"
            end
        end
    end

    result = stext.new(result, style)
    if highlightToday then
        result = result:setStyle(todayStyle, whereIsToday + 1, whereIsToday + 2)
    end
    return result
end

local setMenuTitle = function()
    local x = tonumber(os.date("%d"))
    --  U+2460-2473 = 1 - 20, U+3251-325F = 21 - 35
    module.menuUserdata:setTitle(utf8.char((x < 21 and 0x245F or 0x323C) + x))
end

local calendar = canvas.new{}
calendar[1] = {
    action           = "fill",
    type             = "rectangle",
    roundedRectRadii = { xRadius = 15, yRadius = 15 },
    fillColor        = { alpha = .8 },
}
calendar[2] = {
    id            = "calendar",
    type          = "text",
    trackMouseUp  = true,
}
calendar[3] = {
    id            = "previous",
    type          = "text",
    text          = utf8.char(0x2190),
    textFont      = "Menlo",
    textSize      = 14,
    textAlignment = "center",
    textColor     = { white = 1 },
    frame         = { x = 10, y = 8, h = 15, w = 15 },
    trackMouseUp  = true,
}
calendar[4] = {
    id            = "next",
    type          = "text",
    text          = utf8.char(0x2192),
    textFont      = "Menlo",
    textSize      = 14,
    textAlignment = "center",
    textColor     = { white = 1 },
    frame         = { x = 10, y = 8, h = 15, w = 15 },
    trackMouseUp  = true,
}

local visDay, visMonth, visYear

local drawAt = function(visMonth, visDay, visYear)
    local text = cal(visMonth, visDay, visYear, { font = { name = "Menlo", size = 11 }, color = { white = 1 } },
        { backgroundColor = { red = 1, blue = 1, green = 0, alpha = .6 } })
    local size = calendar:minimumTextSize(text)
    calendar:size{ w = size.w + 30, h = size.h + 30 }
    calendar[2].frame = { x = 15, y = 10, w = size.w, h = size.h }
    calendar[2].text  = text
    calendar[4].frame.x = 5 + size.w
end

local loadCalendar = function()
    if visible then module.hideCalendar() end
    require"hs.application".launchOrFocusByBundleID("com.apple.iCal")
end

calendar:mouseCallback(function(c, m, id, x, y)
    if id == "previous" then
        visDay = nil
        visMonth = visMonth - 1
        if visMonth < 1 then
            visMonth = 12
            visYear = visYear - 1
        end
    elseif id == "next" then
        visDay = nil
        visMonth = visMonth + 1
        if visMonth > 12 then
            visMonth = 1
            visYear = visYear + 1
        end
    elseif id == "calendar" then
--         module.hideCalendar()
        if eventtap.checkKeyboardModifiers().alt then
            loadCalendar()
        end
    end
    local t = os.date("*t")
    if t.month == visMonth and t.year == visYear then
        visDay = t.day
    end
    drawAt(visMonth, visDay, visYear)
end)

module.showCalendarAt = function(x, y)
    visible = true
    local t = os.date("*t")
    visMonth, visDay, visYear = t.month, t.day, t.year
    calendar:topLeft{ x = x, y = y }
    drawAt(visMonth, visDay, visYear)
    local frame       = calendar:frame()
    local screenFrame = screen.mainScreen():frame()
    local offset      = math.max(0, (frame.x + frame.w) - (screenFrame.x + screenFrame.w))
    calendar:topLeft{ x = frame.x - offset, y = frame.y }
    calendar:show()
end

module.hideCalendar = function()
    calendar:hide()
    visible = false
end

module.startCalendarMenu = function()
    if not module.menuUserdata then
        module.menuUserdata = menubar.new()
        setMenuTitle()
        module.menuUserdata:setClickCallback(function(mods)
            setMenuTitle() -- just in case timer is off for some reason
            if mods.alt then
                loadCalendar()
            else
                if visible then
                    module.hideCalendar()
                else
                    local mousePoint = mouse.getAbsolutePosition()
                    local x, y = mousePoint.x - 10, mousePoint.y
                    if module.menuUserdata:isInMenubar() then
                        y = screen.mainScreen():frame().y + 2
                    else
                        y = mousePoint.y + 12
                    end
                    module.showCalendarAt(x, y)
                end
            end
        end)
        -- it's low impact and trying to calculate midnight and running only then seemed prone
        -- to random timer stoppage... should figure out someday, but not right now
        module._timer = timer.doEvery(300, function()
            if module.menuUserdata then
                setMenuTitle()
            else
                module._timer:stop()
                module._timer = nil
                log.ef("rogue timer detected; timer stopped")
            end
        end)
    else
        log.wf("menu already instantiated")
    end
end

module.stopCalendarMenu = function()
    if module.menuUserdata then
        calendar:hide()
        module._timer:stop()
        module._timer = nil
        module.menuUserdata:delete()
        module.menuUserdata = nil
    else
        log.wf("menu has not been instantiated")
    end
end

if settings.get(USERDATA_TAG .. ".autoMenu") then
    module.startCalendarMenu()
end
return module
