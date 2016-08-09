local battery    = require("hs.battery")
local styledtext = require("hs.styledtext")
local host       = require("hs.host")

local baseFont = { name = "Menlo", size = 12 }
local barWidth = 20
local emptyBar = { white = 0.75 }

-- CPU Usage

local cpuGuage = styledtext.new({
    string.rep("|", barWidth),  {
                              starts = 1,
                              ends   = barWidth / 2,
                              attributes = {
                                  font = baseFont,
                                  color = { list = "ansiTerminalColors", name = "fgGreen" },
                              }
                          }, {
                              starts = barWidth / 2 + 1,
                              ends   = 3 * barWidth / 4,
                              attributes = {
                                  font = baseFont,
                                  color = { list = "ansiTerminalColors", name = "fgYellow" },
                              }
                          }, {
                              starts = 3 * barWidth / 4 + 1,
                              ends   = barWidth,
                              attributes = {
                                  font = baseFont,
                                  color = { list = "ansiTerminalColors", name = "fgRed" },
                              }
                          }
})

local cpuActive = host.cpuUsage().overall.active

local avail = barWidth * cpuActive / 100
cpuGuage = cpuGuage:setStyle({ color = emptyBar }, math.ceil(avail), #cpuGuage)

cpuGuage = styledtext.new("CPU ", {
    font = baseFont,
    color = { list = "ansiTerminalColors", name = "fgBlack"   },
}) .. cpuGuage

avail = math.floor(cpuActive)
local tailColor = { list = "ansiTerminalColors", name = "fgRed" }
if avail < 50 then
    tailColor = { list = "ansiTerminalColors", name = "fgGreen" }
elseif avail < 75 then
    tailColor = { list = "ansiTerminalColors", name = "fgYellow" }
end
cpuGuage = cpuGuage .. styledtext.new(" " .. tostring(avail) .. "% utilization\n", { font = baseFont, color = tailColor })

-- RAM Usage

local ramGuage = styledtext.new({
    string.rep("|", barWidth),  {
                              starts = 1,
                              ends   = barWidth / 2,
                              attributes = {
                                  font = baseFont,
                                  color = { list = "ansiTerminalColors", name = "fgGreen" },
                              }
                          }, {
                              starts = barWidth / 2 + 1,
                              ends   = 3 * barWidth / 4,
                              attributes = {
                                  font = baseFont,
                                  color = { list = "ansiTerminalColors", name = "fgYellow" },
                              }
                          }, {
                              starts = 3 * barWidth / 4 + 1,
                              ends   = barWidth,
                              attributes = {
                                  font = baseFont,
                                  color = { list = "ansiTerminalColors", name = "fgRed" },
                              }
                          }
})

-- from top-107 source at http://opensource.apple.com/release/os-x-10116/
local vm = host.vmStat()
local totalFree = (vm.pagesFree + vm.pagesSpeculative) * vm.pageSize
local totalUsed = (vm.pagesWiredDown + vm.pagesInactive + vm.pagesActive + vm.pagesUsedByVMCompressor) * vm.pageSize

totalFree = totalFree / (1024 * 1024 * 1024) -- convert to GB
totalUsed = totalUsed / (1024 * 1024 * 1024) -- convert to GB
local totalRam = totalFree + totalUsed

local avail = barWidth * totalUsed / totalRam
ramGuage = ramGuage:setStyle({ color = emptyBar }, math.ceil(avail), #ramGuage)

ramGuage = styledtext.new("RAM ", {
    font = baseFont,
    color = { list = "ansiTerminalColors", name = "fgBlack" },
}) .. ramGuage

avail = math.floor(100 * totalUsed / totalRam)
local tailColor = { list = "ansiTerminalColors", name = "fgRed" }
if avail < 50 then
    tailColor = { list = "ansiTerminalColors", name = "fgGreen" }
elseif avail < 75 then
    tailColor = { list = "ansiTerminalColors", name = "fgYellow" }
end
ramGuage = ramGuage .. styledtext.new(" " .. tostring(avail) .. "% Used, " .. string.format("%.2fGB Free\n", totalFree), { font = baseFont, color = tailColor })

-- Battery Usage

local batteryGuage = styledtext.new({
    string.rep("|", barWidth),  {
                              starts = 1,
                              ends   = barWidth / 2,
                              attributes = {
                                  font = baseFont,
                                  color = { list = "ansiTerminalColors", name = "fgGreen" },
                              }
                          }, {
                              starts = barWidth / 2 + 1,
                              ends   = 3 * barWidth / 4,
                              attributes = {
                                  font = baseFont,
                                  color = { list = "ansiTerminalColors", name = "fgYellow" },
                              }
                          }, {
                              starts = 3 * barWidth / 4 + 1,
                              ends   = barWidth,
                              attributes = {
                                  font = baseFont,
                                  color = { list = "ansiTerminalColors", name = "fgRed" },
                              }
                          }
})

local max_charge = battery.maxCapacity()
local cur_charge = battery.capacity()

local avail = barWidth * cur_charge / max_charge
batteryGuage = batteryGuage:setStyle({ color = emptyBar }, 1, math.ceil(barWidth - avail))

batteryGuage = styledtext.new("Bat ", {
    font = baseFont,
    color = { list = "ansiTerminalColors", name = "fgBlack"   },
}) .. batteryGuage

avail = math.floor(100 * cur_charge / max_charge)
local tailColor = { list = "ansiTerminalColors", name = "fgGreen" }
if avail < 25 then
    tailColor = { list = "ansiTerminalColors", name = "fgRed" }
elseif avail < 50 then
    tailColor = { list = "ansiTerminalColors", name = "fgYellow" }
end
batteryGuage = batteryGuage .. styledtext.new(" " .. tostring(avail) .. "% charged, " .. tostring(cur_charge) .. "(mAh) Remain\n", { font = baseFont, color = tailColor })

 -- remove trailing \n -- I may add to this or rearrange them, so this lets my cut/pasting
 -- be lazy
return (cpuGuage .. ramGuage .. batteryGuage):sub(1, -2)