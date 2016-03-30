local chooser = require("hs.chooser")
local console = require("hs.console")
local inspect = require("hs.inspect")
local hotkey  = require("hs.hotkey")

local mods    = require("hs._asm.extras").mods

local module = {}

local gotAnAnswer = function(what)
    if what then
        print(inspect(what))
    end
end

local generateChoices = function()
    local results = {}
    for i,v in ipairs(console.getHistory()) do
        table.insert(results, {
            text = v,
            subText="",
            index = i
        })
    end
    return results
end

module.chooser = chooser.new(gotAnAnswer):choices(generateChoices)

module.hotkey = hotkey.bind(mods.CAsc, "return", function()
    module.chooser:refreshChoicesCallback():show()
end)

return module
