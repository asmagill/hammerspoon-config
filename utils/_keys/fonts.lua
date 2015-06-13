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
local typees     = require("utils.typee")


-- When font list is being displayed, type in a number to see the char set for
-- that font.  Hit enter to display charset and esc to return to the font list.

local fontList = hotkey.modal.new(mods.CAsC, "f")
    fontList.pageNumber = 0

local fontCharSet = hotkey.modal.new(nil, nil)
    fontCharSet.fontNumber = 0
    fontCharSet.fontPage = 0

local fontListInput = function(data)
    for _,v in ipairs(fontList.keys) do v:disable() end

    local typedInput  = typees.new()

    typedInput.exitHook = function(status)
        if status then
            fontCharSet.fontNumber = tonumber(typedInput.input)
            fontCharSet:enter()
        else
            for _,v in ipairs(fontList.keys) do v:enable() end
        end
    end

    typedInput:beginCapture(data)
end

-- When char set is being displayed, type in a hex number to jump to the page
-- displaying that UTF-8 character

local charListInput = function(data)
    for _,v in ipairs(fontCharSet.keys) do v:disable() end

    local typedInput  = typees.new()

    typedInput.exitHook = function(status)
        for _,v in ipairs(fontCharSet.keys) do v:enable() end
        if status then
            local charCode = tonumber("0x"..typedInput.input)
            if charCode ~= nil then
                fontCharSet.fontPage = math.floor(charCode / 128)
                fontCharSet.fontNumber, fontCharSet.fontPage =
                    fontTables.displayCharacterSet(fontCharSet.fontNumber, fontCharSet.fontPage)
            end
        end
    end

    typedInput:beginCapture(data)
end

-- Font List Display Keys

    function fontList:entered()
        fontList.pageNumber = fontTables.displayFontList(fontList.pageNumber)
    end
        fontList:bind(mods.casc, "left",      function()
            fontList.pageNumber = fontTables.displayFontList(fontList.pageNumber - 1)
        end)
        fontList:bind(mods.casc, "right",     function()
            fontList.pageNumber = fontTables.displayFontList(fontList.pageNumber + 1)
        end)

        for i = 0, 9 do
            fontList:bind(mods.casc, tostring(i), function() fontListInput(i) end)
        end

        fontList:bind(mods.casc, "escape",    function() fontList:exit() end)
    function fontList:exited() fontTables.depopulateFontList() end

-- CharSet Display Keys

    function fontCharSet:entered()
        fontTables.lightenFontList(true)

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

        for _, i in ipairs({0, 1, 2, 3, 4, 5, 6, 7, 8, 9, "a", "b", "c", "d", "e", "f"}) do
            fontCharSet:bind(mods.casc, tostring(i), function() charListInput(i) end)
        end

        fontCharSet:bind(mods.casc, "escape", function() fontCharSet:exit() end)
    function fontCharSet:exited()
        fontTables.depopulateCharacterSet()

        for _,v in ipairs(fontList.keys) do v:enable() end
        fontTables.lightenFontList(false)
    end

return module
