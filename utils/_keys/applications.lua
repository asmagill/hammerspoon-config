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

local mods = require("hs._asm.extras").mods
local hotkey = hs.hotkey
local fnutils = hs.fnutils
local application = hs.application
local alert = hs.alert.show

local app = hotkey.modal.new(mods.CAsC, "a")

    fnutils.each({
        { key = "a", app = "Activity Monitor" },
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
        alert("Entering Application Mode")
    end
    function app:exited()
        alert("Leaving Application Mode")
    end
app:bind(mods.casc, "ESCAPE", function() app:exit() end)

-- Public interface ------------------------------------------------------
-- Return Module Object --------------------------------------------------

return module
