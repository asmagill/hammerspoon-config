
--- === SlidingPanels ===
---
--- Create sliding panels which can emerge from the sides of your monitor to display canvas and guitk element objects
---
--- Also requires [hs._asm.guitk](https://github.com/asmagill/hammerspoon_asm/tree/master/guitk) version 0.1.4alpha or newer to be installed.  GUITK is a candidate for future inclusion in the Hammerspoon core modules, so hopefully this requirement is temporary
---
--- TODO:
---   * Document, including docs.json file and slidingPanelObject.lua version
---   * Add methods to add/remove canvas and guitk element objects, including slidingPanelObject.lua version
---
--- Download: `svn export https://github.com/asmagill/hammerspoon-config/trunk/_Spoons/SlidingPanels.spoon`
---
--- Example:
--- ~~~lua
--- sp = hs.loadSpoon("SlidingPanels")
--- sp:addPanel{ enabled = true }
--- sp:addPanel{ persistent = true, size = .60, modifiers = { "cmd", "alt" }, side = "left", color = { red = 1 }, enabled = true }
--- sp:addPanel{ persistent = true, modifiers = { "fn" }, side = "top", color = { green = 1 }, enabled = true }
--- sp:addPanel{ side = "top", size = 250, color = { green = 1, blue = 1 }, enabled = true }
--- sp:addPanel{ animationDuration = 0, size = .25, side = "right", color = { blue = 1 }, enabled = true }
--- ~~~

local logger  = require("hs.logger")
local fnutils = require("hs.fnutils")

local obj    = {
-- Metadata
    name      = "SlidingPanels",
    version   = "0.1",
    author    = "A-Ron",
    homepage  = "https://github.com/asmagill/hammerspoon-config/tree/master/_Spoons/SlidingPanels.spoon",
    license   = "MIT - https://opensource.org/licenses/MIT",
    spoonPath = debug.getinfo(1, "S").source:match("^@(.+/).+%.lua$"),
}
local metadataKeys = {} ; for k, v in fnutils.sortByKeys(obj) do table.insert(metadataKeys, k) end

obj.__index  = obj


--- SlidingPanels.logger
--- Variable
--- Logger object used within the Spoon. Can be accessed to set the default log level for the messages coming from the Spoon.
obj.logger = logger.new(obj.name)

-- trick to allow require to work on our support files and use package.loaded to get at the support files directly later
local pp = package.path
package.path = obj.spoonPath .. "?.lua;" .. package.path
local _object = require("slidingPanelObject")
package.path = pp

obj.panels = {}

-- Call me old fashioned, but I don't like the `function obj:addPanel(propertyTable)` shorthand because it hides the
-- fact that there is an implicit `self` variable created.
obj.addPanel = function(self, ...)
-- work properly even if this isn't called as a method
    local args = table.pack(...)
    if self ~= obj then
        table.insert(args, 1, self)
        self = obj
    end
    local id, propertyTable = table.unpack(args)

    if type(id) ~= "string" then error("a string id for the panel is required")
    elseif obj.panels[id] then   error(string.format("id %s is already in use", id))
    end

    local panel = _object.new():properties(propertyTable)
    obj.panels[id] = panel
    return panel
end

obj.removePanel = function(self, ...)
-- work properly even if this isn't called as a method
    local args = table.pack(...)
    if self ~= obj then
        table.insert(args, 1, self)
        self = obj
    end
    local id = table.unpack(args)

    if type(id) ~= "string" then   error("a string id for the panel is required")
    elseif not obj.panels[id] then error(string.format("id %s is not currently in use", id))
    end

    obj.panels[id]:enabled(false)
    obj.panels[id] = nil
    return nil
end

obj.hideAllPanels = function(self)
    for i, v in ipairs(obj.panels) do if v then v.panel:hide() end end
    return true
end

obj.disableAllPanels = function(self)
    for i, v in ipairs(obj.panels) do if v then v.panel:enabled(false) end end
    return true
end

obj.panel = function(self, ...)
-- work properly even if this isn't called as a method
    local args = table.pack(...)
    if self ~= obj then
        table.insert(args, 1, self)
        self = obj
    end
    local id = table.unpack(args)

    if type(id) ~= "string" then error("a string id for the panel is required") end
    return obj.panels[id]
end

return setmetatable(obj, {
    __tostring = function(self)
        local result, fieldSize = "", 0
        for i, v in ipairs(metadataKeys) do fieldSize = math.max(fieldSize, #v) end
        for i, v in ipairs(metadataKeys) do
            result = result .. string.format("%-"..tostring(fieldSize) .. "s %s\n", v, self[v])
        end
        return result
    end,
})
