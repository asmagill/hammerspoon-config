-- TODO:
--   * need a better name
--   * make more spoon like (hotkeys, metadata, etc.)
--   * honor changes to checkInterval without having to stop first and then show
--   * document
--   * make appropriate for use outside of panel (behavior, level, etc)
--   * check memory usage; can we differentiate between truly in use vs disk caching to get a better idea of true "Free" memory?

local canvas  = require("hs.canvas")
local battery = require("hs.battery")
local timer   = require("hs.timer")
local stext   = require("hs.styledtext")
local host    = require("hs.host")
local obj     = {}

local newFullBarGuage = function(barWidth)
    barWidth = barWidth or obj.barWidth
    return stext.new({ string.rep("|", barWidth),
        {
            starts = 1,
            ends   = barWidth / 2,
            attributes = {
                font = obj.baseFont,
                color = { list = "ansiTerminalColors", name = "fgGreen" },
            }
        }, {
            starts = barWidth / 2 + 1,
            ends   = 3 * barWidth / 4,
            attributes = {
                font = obj.baseFont,
                color = { list = "ansiTerminalColors", name = "fgYellow" },
            }
        }, {
            starts = 3 * barWidth / 4 + 1,
            ends   = barWidth,
            attributes = {
                font = obj.baseFont,
                color = { list = "ansiTerminalColors", name = "fgRed" },
            }
        }
    })
end

obj.updateDisplay = function(cpuUsage)
    obj._cpuPoll = nil

-- CPU Usage

    local cpuGuage  = newFullBarGuage()
    local cpuActive = math.floor(cpuUsage.overall.active + .5)
    if cpuActive < 100 then
        cpuGuage = cpuGuage:setStyle({ color = obj.emptyBar }, math.ceil(obj.barWidth * cpuActive / 100), #cpuGuage)
    end

    cpuGuage = stext.new("CPU ", {
            font  = obj.baseFont,
            color = {
                list = "ansiTerminalColors",
                name = "fgBlack"
            },
        }) .. cpuGuage .. stext.new(string.format(" %3d%% utilization", cpuActive), {
            font  = obj.baseFont,
            color = {
                list = "ansiTerminalColors",
                name = (cpuActive > 75) and "fgRed" or ((cpuActive > 50) and "fgYellow" or "fgGreen"),
            },
        })

-- RAM Usage

    local ramGuage = newFullBarGuage()

    -- from top-107 source at http://opensource.apple.com/release/os-x-10116/
    local vm        = host.vmStat()
    local totalFree = (vm.pagesFree + vm.pagesSpeculative) * vm.pageSize
    local totalUsed = (vm.pagesWiredDown + vm.pagesInactive + vm.pagesActive + vm.pagesUsedByVMCompressor) * vm.pageSize
    totalFree = totalFree / (1024 * 1024 * 1024) -- convert to GB
    totalUsed = totalUsed / (1024 * 1024 * 1024) -- convert to GB

    local totalRam     = totalFree + totalUsed
    local percentInUse = totalUsed / totalRam

    ramGuage = ramGuage:setStyle({ color = obj.emptyBar }, math.ceil(obj.barWidth * percentInUse), #ramGuage)

    ramGuage = stext.new("RAM ", {
            font  = obj.baseFont,
            color = {
                list = "ansiTerminalColors",
                name = "fgBlack"
            },
        }) .. ramGuage

    local active = math.floor(100 * percentInUse)
    ramGuage = ramGuage .. stext.new(string.format(" %3d%% used, %.2fGB free", active, totalFree), {
            font  = obj.baseFont,
            color = {
                list = "ansiTerminalColors",
                name = (active > 75) and "fgRed" or ((active > 50) and "fgYellow" or "fgGreen"),
            },
        })

-- Battery Usage

    local batteryGuage = newFullBarGuage()

    local max_charge = battery.maxCapacity()
    local cur_charge = battery.capacity()

    percentInUse = max_charge and cur_charge and (cur_charge / max_charge) or 0
    batteryGuage = batteryGuage:setStyle({ color = obj.emptyBar }, 1, math.ceil(obj.barWidth * (1 - percentInUse)))

    batteryGuage = stext.new("Bat ", {
            font  = obj.baseFont,
            color = {
                list = "ansiTerminalColors",
                name = "fgBlack"
            },
        }) .. batteryGuage

    if max_charge and cur_charge then
        local avail = math.floor(100 * percentInUse)
        batteryGuage = batteryGuage .. stext.new(string.format(" %3d%% charged, %d mAh", avail, cur_charge), {
                font = obj.baseFont,
                color = {
                    list = "ansiTerminalColors",
                    name = (avail > 50) and "fgGreen" or ((avail > 25) and "fgYellow" or "fgRed"),
                },
            })
    else
        batteryGuage = batteryGuage .. stext.new(" n/a", {
                font  = stext.convertFont(obj.baseFont, stext.fontTraits.italicFont),
                color = {
                    list = "ansiTerminalColors",
                    name = "fgBlack"
                },
            })
    end

-- Build Output

    -- styledtext concatenation isn't honoring the style settings for the text *after* the line break... until I can
    -- determine if this is a bug or a limitation, this workaround does the trick
    local lineBreak = stext.new("\n", { font = obj.baseFont })

    local final = cpuGuage .. lineBreak .. ramGuage .. lineBreak .. batteryGuage

    if obj.includeTime then
        final = final .. lineBreak .. stext.new("Last check: " .. os.date("%c"), {
                font  = stext.convertFont({
                        name = obj.baseFont.name,
                        size = obj.baseFont.size - 2,
                    }, stext.fontTraits.italicFont),
                color = {
                    list = "ansiTerminalColors",
                    name = "fgBlack"
                },
                paragraphStyle = { alignment = "right" },
            })
    end

    local outputSize = obj.canvas:minimumTextSize(final)

    obj.canvas.output.text = final
    obj.canvas.output.frame = {
        x = obj.padding,
        y = obj.padding,
        h = outputSize.h,
        w = outputSize.w,
    }
    obj.canvas:frame{
        x = obj.location.x,
        y = obj.location.y,
        h = outputSize.h + obj.padding * 2,
        w = outputSize.w + obj.padding * 2,
    }

    -- in case they changed
    obj.canvas.background.roundedRectRadii = { xRadius = obj.cornerRadius, yRadius = obj.cornerRadius }
    obj.canvas.background.fillColor        = obj.backgroundColor
    obj.canvas.background.strokeColor      = obj.backgroundBorder

    -- override default repeat interval with the actual desired value because it may change between calls
    -- wrapped in if just in case :hide is called after triggered but before HS actually runs this callback
    -- (unlikely, but I've seen weirder)
    if obj._timer then obj._timer:setNextTrigger(obj.checkInterval) end
end

obj.baseFont         = { name = "Menlo", size = 12 }
obj.barWidth         = 20
obj.emptyBar         = { white = 0.5 }
obj.padding          = 10
obj.location         = { x = 100, y = 100 }
obj.checkInterval    = 30
obj.timeSlice        = 1
obj.includeTime      = true
obj.cornerRadius     = 5
obj.backgroundColor  = { alpha = .7, white = .5 }
obj.backgroundBorder = { alpha = .5 }

-- a typical height and width for this output on my machine; it will change as soon as there is data, so accuracy isn't important
local defaultSize = { h = 88, w = 360 }
obj.canvas = canvas.new{ x = obj.location.x, y = obj.location.y, h = defaultSize.h, w = defaultSize.w, }

local initialMsg = stext.new("awaiting data collection", {
    font = stext.convertFont(obj.baseFont, stext.fontTraits.italicFont),
    color = {
        list = "ansiTerminalColors",
        name = "fgBlack"
    },
    paragraphStyle = { alignment = "center" },
})
local msgSize = obj.canvas:minimumTextSize(initialMsg)

obj.canvas[#obj.canvas + 1] = {
    id               = "background",
    type             = "rectangle",
    fillColor        = obj.backgroundColor,
    strokeColor      = obj.backgroundBorder,
    roundedRectRadii = { xRadius = obj.cornerRadius, yRadius = obj.cornerRadius },
    clipToPath       = true, -- makes for sharper edges
}
obj.canvas[#obj.canvas + 1] = {
    id      = "output",
    type    = "text",
    text    = initialMsg,
    frame   = {
        x = (defaultSize.w - msgSize.w) / 2,
        y = (defaultSize.h - msgSize.h) / 2,
        h = msgSize.h,
        w = msgSize.w,
    },
}

obj.show = function(self)
    self = self or obj -- correct for calling this as a function
    if not obj._timer then
        -- we use setNextTrigger to start and maintain the timer, so the actual interval here is irrelevant
        obj._timer = timer.doEvery(300, function()
            obj._cpuPoll = host.cpuUsage(obj.timeSlice, obj.updateDisplay)
        end)
    end
    obj.canvas:show()
    obj._timer:setNextTrigger(0)
    return self
end

obj.hide = function(self)
    self = self or obj -- correct for calling this as a function
    if obj._timer then
        obj._timer:stop()
        obj._timer = nil
    end
    obj.canvas:hide()
    return self
end

return obj
