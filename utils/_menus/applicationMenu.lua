local module = {
--[=[
    _NAME        = 'applicationMenu.lua',
    _VERSION     = '0.1',
    _URL         = 'https://github.com/asmagill/hammerspoon-config',
    _DESCRIPTION = [[ applicationMenu to replace XMenu and the like ]],
    _TODO        = [[]],
    _LICENSE     = [[ See README.md ]]
--]=]
}

local fileListMenu = require("utils.fileListMenu")

local appMenu = fileListMenu.new("Apps") ;
--
-- the commented out lines are actually in the defaults, included here just for completness
-- in case change desired:
--
--appMenu:showForMenu("icon")
--appMenu:menuCriteria("^([^/]+)%.app$")    -- allow function/table for matches?
--appMenu:actionFunction(function(x) hs.application.launchOrFocus(x) end)
--appMenu:rootDirectory("/Applications")
appMenu:menuIcon("ASCII:....................\n"..
                       "....1...4...........\n"..
                       "....................\n"..
                       "....................\n"..
                       "....................\n"..
                       "....................\n"..
                       "....................\n"..
                       "....................\n"..
                       "....................\n"..
                       "....................\n"..
                       "....................\n"..
                       "B..................A\n"..
                       "...8............9...\n"..
                       "....................\n"..
                       "....................\n"..
                       "....................\n"..
                       "....2...........5...\n"..
                       "....................\n"..
                       "......3.........6...\n"..
                       "....................")
appMenu:subFolders("before")
appMenu:activate()

return appMenu