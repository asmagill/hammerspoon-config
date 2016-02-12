local module   = {}
local console  = require("hs.console")
local settings = require("hs.settings")
local timer    = require("hs.timer")

local hashFN   = require("hs.hash").MD5 -- can use other hash fn if this proves insufficient

local saveLabel     = "_ASMConsoleHistory" -- label for saved history
local checkInterval = settings.get(saveLabel.."_interval") or 1 -- how often to check for changes
local maxLength     = settings.get(saveLabel.."_max") or 100    -- maximum history to save

local uniqueHistory = function(raw)
    local hashed, history = {}, {}
    for i = #raw, 1, -1 do
        local key = hashFN(#raw[i])
        if not hashed[key] then
            table.insert(history, 1, raw[i])
            hashed[key] = true
        end
    end
    return history
end

local reverseTable = function(t)
    local r = {}
    for i, v in ipairs(t) do table.insert(r, 1, v) end
    return r
end

module.clearHistory = function() return console.setHistory({}) end

module.saveHistory = function()
    local hist, save = console.getHistory(), {}
    if #hist > maxLength then
        table.move(hist, #hist - maxLength, #hist, 1, save)
    else
        save = hist
    end
    -- save only the unique lines
    settings.set(saveLabel, uniqueHistory(save))
end

module.retrieveHistory = function()
    local history = settings.get(saveLabel)
    if (history) then
        console.setHistory(history)
    end
end

module.retrieveHistory()
local currentHistoryCount = #console.getHistory()

module.autosaveHistory = timer.new(checkInterval, function()
    local historyNow = console.getHistory()
    if #historyNow ~= currentHistoryCount then
        currentHistoryCount = #historyNow
        module.saveHistory()
    end
end):start()

module.pruneHistory = function()
    console.setHistory(uniqueHistory(console.getHistory()))
    currentHistoryCount = #console.getHistory()
    return currentHistoryCount
end

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
