--- === SlidingPanel ===
---
--- Create sliding panels which can emerge from the sides of your monitor to display canvas and guitk element objects
---
--- Also requires [hs._asm.guitk](https://github.com/asmagill/hammerspoon_asm/tree/master/guitk) to be installed.  GUITK is a candidate for future inclusion in the Hammerspoon core modules, so hopefully this requirement is temporary
---
--- TODO:
---   * Document, including docs.json file and slidingPanelObject.lua version
---   * Add methods to add/remove canvas and guitk element objects, including slidingPanelObject.lua version
---
--- Download: `svn export https://github.com/asmagill/hammerspoon-config/trunk/_Spoons/SlidingPanel.spoon`
---
--- Example:
--- ~~~lua
--- sp = hs.loadSpoon("SlidingPanel")
--- sp:newPanel{ enabled = true }
--- sp:newPanel{ persistent = true, size = .60, modifiers = { "cmd", "alt" }, side = "left", color = { red = 1 }, enabled = true }
--- sp:newPanel{ persistent = true, modifiers = { "fn" }, side = "top", color = { green = 1 }, enabled = true }
--- sp:newPanel{ side = "top", size = 250, color = { green = 1, blue = 1 }, enabled = true }
--- sp:newPanel{ animationDuration = 0, size = .25, side = "right", color = { blue = 1 }, enabled = true }
--- ~~~

local obj={}
obj.__index = obj

-- Metadata
obj.name = "SlidingPanel"
obj.version = "0.1"
obj.author = "A-Ron"
obj.homepage = "https://github.com/asmagill/hammerspoon-config/tree/master/_Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

--- SlidingPanel.logger
--- Variable
--- Logger object used within the Spoon. Can be accessed to set the default log level for the messages coming from the Spoon.
obj.logger = require("hs.logger").new(obj.name)
obj.spoonPath = debug.getinfo(1, "S").source:sub(2, -9)

-- trick to allow require to work on our support files and use package.loaded to get at the support files directly later
local pp = package.path
package.path = obj.spoonPath .. "?.lua;" .. package.path
local _object = require("slidingPanelObject")
package.path = pp

obj.panels = {}

-- Call me old fashioned, but I don't like the `function obj:newPanel(propertyTable)` shorthand because it hides the
-- fact that there is an implicit `self` variable created.
obj.newPanel = function(self, ...)
-- work properly even if this isn't called as a method
    local args = table.pack(...)
    if self ~= obj then
        table.insert(args, 1, self)
        self = obj
    end
    local propertyTable = table.unpack(args)

    propertyTable = propertyTable or {}
    local panel = _object.new()
    local s, r = pcall(panel.properties, panel, propertyTable)
    if not s then
        obj.logger.ef("newPanel error: %s", r)
        return nil
    else
        table.insert(obj.panels, panel)
        return #obj.panels
    end
end

obj.removePanel = function(self, ...)
-- work properly even if this isn't called as a method
    local args = table.pack(...)
    if self ~= obj then
        table.insert(args, 1, self)
        self = obj
    end
    local idx = table.unpack(args)

    if math.type(idx) ~= "integer" then
        obj.logger.e("removePanel error: expected integer index")
        return nil
    elseif not obj.panels[idx] then
        obj.logger.ef("removePanel error: index %d does not refer to an existing panel", idx)
        return nil
    else
        obj.panels[idx]:enabled(false)
        -- keeps the array pos filled so treating obj.panels as array will work without running into an issue with it
        -- being sparse -- sometimes lua copes, other times not so well
        obj.panels[idx] = false
        return true
    end
end

obj.panelProperties = function(self, ...)
-- work properly even if this isn't called as a method
    local args = table.pack(...)
    if self ~= obj then
        table.insert(args, 1, self)
        self = obj
    end
    local idx, propertyTable = table.unpack(args)

    if math.type(idx) ~= "integer" then
        obj.logger.e("panelProperties error: expected integer index")
        return nil
    elseif not obj.panels[idx] then
        obj.logger.ef("panelProperties error: index %d does not refer to an existing panel", idx)
        return nil
    elseif propertyTable then
        local panel = obj.panels[idx]
        local s, r = pcall(panel.properties, panel, propertyTable)
        if not s then
            obj.logger.ef("panelProperties error: %s", r)
            return nil
        else
            return idx
        end
    else
        return obj.panels[idx]:properties()
    end
end

obj.enablePanel = function(self, ...)
-- work properly even if this isn't called as a method
    local args = table.pack(...)
    if self ~= obj then
        table.insert(args, 1, self)
        self = obj
    end
    local idx = table.unpack(args)

    if math.type(idx) ~= "integer" then
        obj.logger.e("enablePanel error: expected integer index")
        return nil
    elseif not obj.panels[idx] then
        obj.logger.ef("enablePanel error: index %d does not refer to an existing panel", idx)
        return nil
    else
        local panel = obj.panels[idx]
        local s, r = pcall(panel.enabled, panel, true)
        if not s then
            obj.logger.ef("enablePanel error: %s", r)
            return nil
        else
            return idx
        end
    end
end

obj.disablePanel = function(self, ...)
-- work properly even if this isn't called as a method
    local args = table.pack(...)
    if self ~= obj then
        table.insert(args, 1, self)
        self = obj
    end
    local idx = table.unpack(args)

    if math.type(idx) ~= "integer" then
        obj.logger.e("disablePanel error: expected integer index")
        return nil
    elseif not obj.panels[idx] then
        obj.logger.ef("disablePanel error: index %d does not refer to an existing panel", idx)
        return nil
    else
        obj.panels[idx]:enabled(false)
        return idx
    end
end

obj.hidePanel = function(self, ...)
-- work properly even if this isn't called as a method
    local args = table.pack(...)
    if self ~= obj then
        table.insert(args, 1, self)
        self = obj
    end
    local idx = table.unpack(args)

    if math.type(idx) ~= "integer" then
        obj.logger.e("hidePanel error: expected integer index")
        return nil
    elseif not obj.panels[idx] then
        obj.logger.ef("hidePanel error: index %d does not refer to an existing panel", idx)
        return nil
    else
        obj.panels[idx]:hide()
        return idx
    end
end

obj.showPanel = function(self, ...)
-- work properly even if this isn't called as a method
    local args = table.pack(...)
    if self ~= obj then
        table.insert(args, 1, self)
        self = obj
    end
    local idx = table.unpack(args)

    if math.type(idx) ~= "integer" then
        obj.logger.e("showPanel error: expected integer index")
        return nil
    elseif not obj.panels[idx] then
        obj.logger.ef("showPanel error: index %d does not refer to an existing panel", idx)
        return nil
    else
        obj.panels[idx]:show()
        return idx
    end
end

obj.hideAllPanels = function(self)
    for i, v in ipairs(obj.panels) do if v then v:hide() end end
    return true
end

obj.disableAllPanels = function(self)
    for i, v in ipairs(obj.panels) do if v then v:enabled(false) end end
    return true
end

return obj
