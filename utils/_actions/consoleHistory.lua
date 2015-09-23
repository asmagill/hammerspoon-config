local checkInteral = 1                    -- how often to check for changes to the console history
local saveLabel    = "_ASMConsoleHistory" -- label for saved history

local module   = {}
local console  = require("hs._asm.console")
local settings = require("hs.settings")
local timer    = require("hs.timer")

module.clearHistory = function() return console.setHistory({}) end

module.saveHistory = function()
    settings.set(saveLabel, console.getHistory())
end

module.retrieveHistory = function()
    local history = settings.get(saveLabel)
    if (history) then
        console.setHistory(history)
    end
end


module.retrieveHistory()
local currentHistory = console.getHistory()
module.autosaveHistory = timer.new(checkInteral, function()
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

-- if pasting directly into init.lua, save this somewhere global like:
-- console = module

-- if using as a separate file:
return module
-- and make sure to save the returned value somewhere global in your init.lua file like:
-- console = require("thisfile.lua")
