local module = {
--[=[
    _NAME        = 'key_bindings.lua',
    _VERSION     = '0.1',
    _URL         = 'https://github.com/asmagill/mjolnir-config',
    _DESCRIPTION = [[ personal keybindings for mjolnir ]],
    _TODO        = [[]],
    _LICENSE     = [[ See README.md ]]
--]=]
}

-- private variables and methods -----------------------------------------

local mods = require("hs.extras").mods
local hotkey = require("hs.hotkey")
local fnutils = require("hs.fnutils")
local application = require("hs.application")
local alert = require("hs.alert").show


hotkey.bind(mods.CAsC, "d", function() application.launchorfocus("Dash") end, nil)
hotkey.bind(mods.CAsC, "n", function() application.launchorfocus("Notational Velocity") end, nil)
hotkey.bind(mods.CASC, "b", function()
    os.execute("/opt/amagill/bin/blueutil power $((1 - `/opt/amagill/bin/blueutil power`))")
    alert("Toggle Bluetooth")
end, nil)

hotkey.bind(mods.CASC, "e", function() os.execute("/usr/local/bin/edit ~/.hammerspoon /opt/amagill/src/hammerspoon/_asm") end, nil)
hotkey.bind(mods.CASC, "3", function() application.launchorfocus("Calculator") end, nil)
hotkey.bind(mods.CAsC, "r", hs.openconsole, nil)

-- Public interface ------------------------------------------------------
-- Return Module Object --------------------------------------------------

return module
