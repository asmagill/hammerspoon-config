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

hotkey.bind(mods.CAsC, "return", function()
    _asm._menus.applicationMenu.menuUserdata:popupMenu(require("hs.mouse").getAbsolutePosition())
end)
hotkey.bind(mods.casc, "f12", function() _asm._CMI.minToggle() end)
hotkey.bind(mods.caSc, "f12", function() _asm._CMI.panelToggle() ; _asm._actions.geeklets.geeklets.clock:toggle() end)
hotkey.bind(mods.Casc, "f12", function()
    for i, v in pairs(_asm._actions.geeklets.geeklets) do
        if not v.hoverlock then v:hover(not v.shouldHover) end
    end
end)
hotkey.bind(mods.CaSc, "f12", function()
    for i, v in pairs(_asm._actions.geeklets.geeklets) do
        if not v.hoverlock then v:visible(not v.isVisible) end
    end
end)
hotkey.bind(mods.CAsC, "f12", function()
    local listener = require("utils.speech")
    if listener.recognizer then
        if listener:isListening() then
            listener:disableCompletely()
        else
            listener:start()
        end
    else
        listener = listener.init():start()
    end
end)


-- launchOrFocus of Dash with menu and dock icons off causes preferences pane to appear...
-- better for my habits to assign hotkey within Dash itself...
--hotkey.bind(mods.CAsC, "d", function() application.launchOrFocus("Dash") end, nil)
-- hotkey.bind(mods.CAsC, "n", function() application.launchOrFocus("Notational Velocity") end, nil)
hotkey.bind(mods.CAsC, "n", function() application.launchOrFocus("nvALT") end, nil)
hotkey.bind(mods.CASC, "b", function()
    alert("Bluetooth is power is now: "..
        (bluetooth.power(not bluetooth.power()) and "On" or "Off"))
    end, nil)

hotkey.bind(mods.CASC, "e", nil, function()
        os.execute("/usr/local/bin/edit ~/."..AppName.." /opt/amagill/src/hammerspoon")
    end)
hotkey.bind(mods.CASC, "3", function() application.launchOrFocus("Calculator") end, nil)

hotkey.bind(mods.CAsC, "r", function()
          local conswin = window.get("Hammerspoon Console")
          if conswin and application.get("Hammerspoon"):isFrontmost() then
              conswin:close()
          else
              hs.openConsole()
          end
      end, nil)
hotkey.bind(mods.CASC, "r", function() _asm.relaunch() end, nil)

hotkey.bind(mods.CAsC, "space", function() hints.windowHints() end, nil)
hotkey.bind(mods.CASC, "space", function()
    hints.windowHints(window.focusedWindow():application():allWindows())
end)

-- Public interface ------------------------------------------------------
-- Return Module Object --------------------------------------------------

return module
