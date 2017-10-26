--- === SlidingPanel ===
---
--- Create sliding panels which can emerge from the sides of your monitor to display canvas and guitk element objects
---
--- Also requires [hs._asm.guitk](https://github.com/asmagill/hammerspoon_asm/tree/master/guitk) to be installed.  GUITK is a candidate for future inclusion in the Hammerspoon core modules, so hopefully this requirement is temporary
---
--- TODO:
---   * Document, including docs.json file and slidingPanelObject.lua version
---   * Additional functions for spoon (see comments below)
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

-- trick to allow require to work on our support objects
local pp = package.path
package.path = obj.spoonPath .. "?.lua;" .. package.path
local _object = require("slidingPanelObject")
package.path = pp

obj.panels = {}

local applyPanelPropertyTable = function(panel, propertyTable)
    local s, r
    for k, v in pairs(propertyTable) do
        if k ~= "enabled" then
            if panel[k] and type(panel[k]) == "function" then
                s, r = pcall(panel[k], panel, v)
            else
                s, r = nil, tostring(k) .. " is not a sliding panel property"
            end
            if not s then break end
        end
    end
    -- do this last because pairs doesn't guarantee order and you can have only one enabled panel for a given side and modifiers
    -- so we want them to have a chance to be set above first
    if type(propertyTable.enabled) ~= "nil" then
        s, r = pcall(panel.enabled, panel, propertyTable.enabled)
    end
    return s, r
end

obj.newPanel = function(self, propertyTable)
-- Call me old fashioned, but I don't like the `function obj:newPanel(propertyTable)` shorthand because it hides the
-- fact that there is an implicit `self` variable created.
    propertyTable = propertyTable or {}
    local panel = _object.new()
    local s, r = applyPanelPropertyTable(panel, propertyTable)
    if not s then
        obj.logger:ef("newPanel error: %s", r)
        return nil
    else
        table.insert(obj.panels, panel)
        return #obj.panels
    end
end

obj.removePanel = function(self, idx)
    if math.type(idx) ~= "integer" then
        obj.logger:e("removePanel error: expected integer index")
        return nil
    elseif not obj.panels[idx] then
        obj.logger:ef("removePanel error: index %d does not refer to an existing panel", idx)
        return nil
    else
        obj.panels[idx]:enabled(false)
        obj.panels[idx] = nil
        return true
    end
end

obj.panelProperties = function(self, idx, propertyTable)
    if math.type(idx) ~= "integer" then
        obj.logger:e("panelProperties error: expected integer index")
        return nil
    elseif not obj.panels[idx] then
        obj.logger:ef("panelProperties error: index %d does not refer to an existing panel", idx)
        return nil
    elseif propertyTable then
        local s, r = applyPanelPropertyTable(obj.panels[idx], propertyTable)
        if not s then
            obj.logger:ef("panelProperties error: %s", r)
            return nil
        else
            return true
        end
    else
        local panel = obj.panels[idx]
        return {
            color             = panel:color(),
            modifiers         = panel:modifiers(),
            enabled           = panel:enabled(),
            side              = panel:side(),
            size              = panel:size(),
            persistent        = panel:persistent(),
            animationSteps    = panel:animationSteps(),
            animationDuration = panel:animationDuration(),
            hoverDelay        = panel:hoverDelay(),
            padding           = panel:padding(),
            strokeAlpha       = panel:strokeAlpha(),
            fillAlpha         = panel:fillAlpha(),
        }
    end
end

-- obj.hidePanel = function(self, idx)
-- end
--
-- obj.showPanel = function(self, idx)
-- end
--
-- obj.hideAllPanels = function(self)
-- end
--
-- obj.disableAllPanels = function(self)
-- end

return obj
