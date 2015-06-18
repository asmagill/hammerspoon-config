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
local alert       = require("hs.alert").show
local bluetooth   = require("hs._asm.undocumented.bluetooth")
local hints       = require("hs.hints")
local window      = require("hs.window")

local AppName   = (mjolnir and "mjolnir") or (hs and "hammerspoon") or "hellifino"

hotkey.bind(mods.CAsC, "d", function() application.launchOrFocus("Dash") end, nil)
hotkey.bind(mods.CAsC, "n", function() application.launchOrFocus("Notational Velocity") end, nil)
hotkey.bind(mods.CASC, "b", function()
    alert("Bluetooth is power is now: "..
        (bluetooth.power(not bluetooth.power()) and "On" or "Off"))
    end, nil)

hotkey.bind(mods.CASC, "e", nil, function()
        os.execute("/usr/local/bin/edit ~/."..AppName.." /opt/amagill/src/hammerspoon")
    end)
hotkey.bind(mods.CASC, "3", function() application.launchOrFocus("Calculator") end, nil)

hotkey.bind(mods.CAsC, "r", function() hs.openConsole() end, nil)
hotkey.bind(mods.CASC, "r", function() require("hs._asm.extras").restart() end, nil)

hotkey.bind(mods.CAsC, "space", function() hints.windowHints() end, nil)
hotkey.bind(mods.CASC, "space", function()
    hints.windowHints(window.focusedWindow():application():allWindows())
end)

-- Public interface ------------------------------------------------------
-- Return Module Object --------------------------------------------------

return module
