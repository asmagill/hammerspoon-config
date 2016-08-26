local module = {
--[=[
    _NAME        = 'key_bindings.lua',
    _VERSION     = '0.1',
    _URL         = 'https://github.com/asmagill/hammerspoon-config',
    _DESCRIPTION = [[ personal keybindings for hammerspoon ]],
    _TODO        = [[]],
    _LICENSE     = [[ See README.md ]]
--]=]
}

-- private variables and methods -----------------------------------------

local mods        = require("hs._asm.extras").mods
local hotkey      = require("hs.hotkey")
local fnutils     = require("hs.fnutils")
local application = require("hs.application")
local alert       = require("hs.alert")

local app = hotkey.modal.new(mods.CAsC, "a")

    fnutils.each({
        { key = "a", app = "Arduino" },
        { key = "p", app = "Activity Monitor" },
        { key = "t", app = "Terminal" },
        { key = "e", app = "TextWrangler" },
        { key = "f", app = "Finder" },
        { key = "m", app = "Mail" },
        { key = "s", app = "Safari" },
        { key = "c", app = "Console" },
    },
        function(object)
            app:bind(mods.casc, object.key,
                function() application.launchOrFocus(object.app) end,
                function() app:exit() end
            )
        end
    )

    function app:entered()
-- app is the modal hotkey we created, and since it's a table, its as good a place as any to store something, as long as we don't overwrite any of its required internals (see `hs.inspect(hs.hotkey.modal.new({"ctrl","shift"}, "a"), {metatables = true})` if you want to see what these are)
        app.alertUUID = alert("Application Selection Mode", true)
    end
    function app:exited()
        if app.alertUUID then
            alert.closeSpecific(app.alertUUID)
        else
            alert.closeAll() -- just in case
        end
    end
app:bind(mods.casc, "ESCAPE", function() app:exit() end)

-- Public interface ------------------------------------------------------
-- Return Module Object --------------------------------------------------

return module
