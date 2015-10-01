local module   = {}
local console  = require("hs._asm.console")
local settings = require("hs.settings")
local timer    = require("hs.timer")

local saveLabel     = "_ASMConsoleHistory" -- label for saved history
local checkInterval = settings.get(saveLabel.."_interval") or 1 -- how often to check for changes
local maxLength     = settings.get(saveLabel.."_max") or 100    -- maximum history to save

module.clearHistory = function() return console.setHistory({}) end

module.saveHistory = function()
    local hist, save = console.getHistory(), {}
    if #hist > maxLength then
        table.move(hist, #hist - maxLength, #hist, 1, save)
    else
        save = hist
    end
    settings.set(saveLabel, save)
end

module.retrieveHistory = function()
    local history = settings.get(saveLabel)
    if (history) then
        console.setHistory(history)
    end
end


module.retrieveHistory()
local currentHistory = console.getHistory()
module.autosaveHistory = timer.new(checkInterval, function()
    local historyNow = console.getHistory()
    if #historyNow ~= #currentHistory then
        currentHistory = historyNow
        module.saveHistory()
    end
end):start()

module = setmetatable(module, { __gc =  function(_)
                                    _.saveHistory()
                                end,
})

module.findInHistory = function(toFind)
    toFind = toFind or ""
    for i,v in ipairs(console.getHistory()) do
        if v:match(toFind) then print(i, v) end
    end
end

-- if pasting directly into init.lua, save this somewhere global like:
-- console = module

-- if using as a separate file:
return module
-- and make sure to save the returned value somewhere global in your init.lua file like:
-- console = require("thisfile.lua")
