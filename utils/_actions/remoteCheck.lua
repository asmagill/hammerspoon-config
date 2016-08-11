local module = {}

local task          = require("hs.task")
local stext         = require("hs.styledtext")
local timer         = require("hs.timer")
local settings      = require("hs.settings")
local configuration = require("hs.network.configuration")

local vpnQueryKey = "State:/Network/Interface/utun[0-9]+/IPv4"

local hosts = {
    "cousteau.private",
    "marconi.private",
    "hedylamarr.private",
}

local style = {
    font = { name = "Menlo", size = 10 },
    color = { alpha = 1.0 },
    paragraphStyle = { lineBreak = "clip" },
}

local myTasks  = {}
local myOutput = {}

local ourVPNisUp = function()
    local status = false
    if module.vpnStatus then
        for k, v in pairs(module.vpnStatus:contents(vpnQueryKey, true)) do
            for i2, v2 in ipairs(v["Addresses"]) do
                if v2:match("^10%.161%.81%.") then
                    status = true
                    break
                end
            end
            if status then break end
        end
    end
    return status
end

module.updateTasks = function()
    for i, v in ipairs(hosts) do
        if myTasks[v] and myTasks[v]:isRunning() then
            -- print("-- "..v.." still running")
        else
            if ourVPNisUp() then
                myOutput[v] = stext.new(v.." is polling...\n", style):setStyle{
                    color = { list = "Crayons", name = "Sea Foam" },
                    font  = stext.convertFont(style.font, stext.fontTraits.italicFont),
                }
                myTasks[v] = task.new("/sbin/ping", function(c, o, e)
                    local output  = o:gsub("^PING.+[\r\n][\r\n]", "")
                    local soutput = stext.new(output, style)
                    if c == 2 then
                        soutput = soutput:setStyle{
                            color = { red = 1.0 },
                            paragraphStyle = { lineBreak = "wordWrap" },
                        }
                    else
                        local _, e1 = output:find("^[^\r\n]+[\r\n]")
                        local s2, e2, loss = output:find("(%d+%.%d+)%% packet loss")
                        loss = tonumber(loss)
                        local pStyle = (loss < 5.0)  and { color = { list = "Apple", name = "Green" } } or
                                      ((loss < 10.0) and { color = { list = "Apple", name = "Yellow" } } or
                                                         { color = { list = "Apple", name = "Red" } })
                        soutput = soutput:setStyle({
                            color = { list = "x11", name = "mediumvioletred" },
                            font  = stext.convertFont(style.font, stext.fontTraits.italicFont),
                        }, 5, e1 - 5):setStyle(pStyle, s2, e2)
                    end
                    myOutput[v] = soutput
                    _asm._actions.geeklets.geeklets.remoteCheck.lastRun = os.time() - _asm._actions.geeklets.geeklets.remoteCheck.period
                    myOutput[v] = myOutput[v]..stext.new("Last Check: "..os.date(), style):setStyle{
                        color = { list = "x11", name = "royalblue" },
                        font  = stext.convertFont(style.font, stext.fontTraits.italicFont),
                        paragraphStyle = {
                            alignment = "right"
                        },
                    }
                end, { "-c10", "-q", v }):start()
            else
                myOutput[v] = stext.new(v..": VPN is Down\n", style):setStyle{
                    color = { list = "Crayons", name = "Sea Foam" },
                    font  = stext.convertFont(style.font, stext.fontTraits.italicFont),
                }
                _asm._actions.geeklets.geeklets.remoteCheck.lastRun = os.time() - _asm._actions.geeklets.geeklets.remoteCheck.period
            end
        end
    end
end

-- force a recheck when the status changes
module.vpnStatus = configuration.open():setCallback(module.updateTasks)
                                       :monitorKeys(vpnQueryKey, true)
                                       :start()

module.output = myOutput
module.tasks  = myTasks
module.timer  = timer.new(300, module.updateTasks):start()

timer.doAfter(1, module.updateTasks) -- ensure this is triggered after we load, so _asm._actions exists

return module
