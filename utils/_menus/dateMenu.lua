local module = {}

local menubar  = require("hs.menubar")
local timer    = require("hs.timer")
local stext    = require("hs.styledtext")
local settings = require("hs.settings")
local calendar = require("hs._asm.calendar")

local USERDATA_TAG = "calendarMenu"
local log  = require"hs.logger".new(USERDATA_TAG, settings.get(USERDATA_TAG .. ".logLevel") or "warning")
module.log = log


local _eventCal = calendar.events()

module.upcomingEventSummary = function(days, whichCalendars)
    days = days or 7

    local events = _eventCal:events(calendar.startOfDay(os.time()), calendar.endOfDay(os.time() + 86400 * (days - 1)), whichCalendars)

    local results = {}
    for i, v in ipairs(events) do
        local text = os.date("%m/%d ", v.startDate):gsub("0(%d)", " %1")
        if v.allDay then
            text = text .. "* All Day    "
        else
            text = text .. os.date("%H:%M - ", v.startDate) .. os.date("%H:%M", v.endDate)
        end
        text = text .. ": " .. v.title
        local textColor = _eventCal:calendarDetails(v.calendarIdentifier).color or { white = 0 }
        table.insert(results, {
            title = stext.new(text, { font = { name = "Menlo", size = 10 }, color = textColor }),
            fn = function() if v.URL then os.execute("open " .. v.URL) else require"hs.application".launchOrFocusByBundleID("com.apple.iCal") end end,
        })
    end
    table.sort(results, function(a, b) return a.title < b.title end)
    return results
end

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

--     local offSet = math.floor(10 - (string.len(monthLabels[date.month]) + 1 + string.len(tostring(date.year))) / 2)
--     local result = string.rep(" ", offSet) .. monthLabels[date.month] .. " " .. tostring(date.year) .. "\n"
    local result = monthLabels[date.month] .. " " .. tostring(date.year) .. "\n"
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
        else
            result = result .. string.rep(utf8.char(0x00A0), 3 * (7 - monthStartsOn))
        end
    end

    result = stext.new(result, style)
    if highlightToday then
        result = result:setStyle(todayStyle, whereIsToday + 1, whereIsToday + 2)
    end
    return result
end

local makeMenu = function(mods)
    local results = {}
    local t = os.date("*t", os.time())
    table.insert(results, {
        title = cal(t.month, t.day, t.year,
        { font = { name = "Menlo", size = 12 }, color = { white = .5 }, paragraphStyle = { alignment = "center" } },
        { color = { white = 0 }, backgroundColor = { red = 1, blue = 1, green = 0 } }),
        disabled = true,
        fn = function() require"hs.application".launchOrFocusByBundleID("com.apple.iCal") end,
    })
    table.insert(results, { title = "-" })
    for i,v in ipairs(module.upcomingEventSummary(14)) do
        table.insert(results, v)
    end
    return results
end

local setMenuTitle = function()
    local x = tonumber(os.date("%d"))
    --  U+2460-2473 = 1 - 20, U+3251-325F = 21 - 35
    module.menuUserdata:setTitle(utf8.char((x < 21 and 0x245F or 0x323C) + x))
end

module.startCalendarMenu = function()
    if not module.menuUserdata then
        module.menuUserdata = menubar.new():setMenu(makeMenu)
        setMenuTitle()
        module._timer = timer.doAt(0, 86400, function()
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

