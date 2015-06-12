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

local mods       = require("hs._asm.extras").mods
local hotkey     = hs.hotkey
local fontTables = require("utils.fontTables")

local fontList = hotkey.modal.new(mods.CAsC, "f")
    fontList.pageNumber = 0

    function fontList:entered()
        fontList.pageNumber = fontTables.displayFontList(fontList.pageNumber)
    end
        fontList:bind(mods.casc, "left",      function()
            fontList.pageNumber = fontTables.displayFontList(fontList.pageNumber - 1)
        end)
        fontList:bind(mods.casc, "right",     function()
            fontList.pageNumber = fontTables.displayFontList(fontList.pageNumber + 1)
        end)
        fontList:bind(mods.casc, "escape",    function() fontList:exit() end)
    function fontList:exited() fontTables.depopulateFontList() end

-- CharSet Display Keys

local fontCharSet = hotkey.modal.new(mods.CAsC, "c")
    fontCharSet.fontNumber = 0
    fontCharSet.fontPage = 0

    function fontCharSet:entered()
        fontCharSet.fontNumber, fontCharSet.fontPage =
                fontTables.displayCharacterSet(fontCharSet.fontNumber, fontCharSet.fontPage)
    end
        fontCharSet:bind(mods.casc, "left",   function()
            fontCharSet.fontNumber, fontCharSet.fontPage =
                    fontTables.displayCharacterSet(fontCharSet.fontNumber, fontCharSet.fontPage - 1)
        end)
        fontCharSet:bind(mods.casc, "right",  function()
            fontCharSet.fontNumber, fontCharSet.fontPage =
                    fontTables.displayCharacterSet(fontCharSet.fontNumber, fontCharSet.fontPage + 1)
        end)
        fontCharSet:bind(mods.casc, "up",     function()
            fontCharSet.fontNumber, fontCharSet.fontPage =
                    fontTables.displayCharacterSet(fontCharSet.fontNumber - 1, fontCharSet.fontPage)
        end)
        fontCharSet:bind(mods.casc, "down",   function()
            fontCharSet.fontNumber, fontCharSet.fontPage =
                    fontTables.displayCharacterSet(fontCharSet.fontNumber + 1, fontCharSet.fontPage)
        end)
        fontCharSet:bind(mods.casc, "escape", function() fontCharSet:exit() end)
    function fontCharSet:exited() fontTables.depopulateCharacterSet() end

return module
